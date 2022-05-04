
// Correllates of War -------------------------------------------------------
// make sure that we have 1 country year after the merge

// get the country codes ----------
import delimited "system2016.csv", clear
keep stateabb ccode
duplicates drop
sort ccode
gen ccodel1 = ccode[_n-1]
assert ccodel1 != ccode
drop ccodel1
save "cor_war_(cow)_codes.dta", replace

// define program to load each correllates of war dataset:
quietly capture program drop clean_cow
program clean_cow
	args file_name_ vars_keep_
	
	// import file:
	if (regexm("`file_name_'", ".csv$")) {
		import delimited "`file_name_'", clear
	}
	if (regexm("`file_name_'", ".dta$")) {
		use "`file_name_'", clear
	}
	
	// keep certain important variables on start of wa &, country codes
	rename *, lower
	keep `vars_keep_'
	
	// replace missing values
		//  -9 = year unknown
		//  -7 = ongoing
		//  -8 = not applicable

	foreach i of varlist _all {
			replace `i' = . if inlist(`i', -9, -8, -7, -6)
	}
end

tempfile intra inter nonstate extra

// INTRA -------
clear
clean_cow "INTRA-STATE WARS v5.1.dta" "warnum ccode* starty* endy*"
foreach i of varlist _all {
assert `i' != -9
}
gen filename = "intra"
save `intra'

// INTER --------
clean_cow "directed dyadic war may 2018.dta" "warnum state* warstrtyr warendyr"
foreach i of varlist _all {
assert `i' != -9
}
gen filename = "inter"
assert warstrtyr !=. & warendyr!=.
save `inter'

// NONSTATE ---------
import delimited "cow_Non-StateWarData_v4.0.csv", clear

// EXTRA-STATE ----------
clean_cow "Extra-StateWarData_v4.0.csv" "warnum ccode* starty* endy*"
foreach i of varlist _all {
assert `i' != -9
}
br if startyear1 != . & endyear1 == .

// we can replace ccode2 variable because this is a 1-state w/ a nonstate actor
replace ccode1 = ccode2 if ccode1 == .
assert ccode1 != .
assert ccode1 ==ccode2 if ccode2 != .
drop ccode2
gen filename = "extra"
save `extra'

// append the correllates of war datasets -------
clear 
use `extra'
foreach i in `intra' `inter' {
	append using `i', force
}

duplicates drop

save "temp_appended.dta", replace
use "temp_appended.dta", clear

// coalesce columns
gen ccode = .
foreach i in statea ccode1 ccodea {
	replace ccode = `i' if ccode == .
}
foreach i in statea ccode1 ccodea {
	assert ccode == `i' if `i' != .
}

// Concerns: 
// What to do about non-state wars?
// What to do about regional wars? (e.g. ISIS-al Nusra Front War of 2014; Rada'a War of 2014-present)
// For now, we're dropping them.
drop if ccode == .
drop statea ccode1 ccodea
rename stateb ccodeb

tempfile appended
save `appended'

// merge codes & separate code b --------

// Right now, we have a dataset that has a column with PAIRs of states. 
// Change to be a dataset with just 1 column for the state.
use "cor_war_(cow)_codes.dta", clear
mmerge ccode using `appended'
assert inlist(_merge, 1, 3)
keep if _merge == 3
drop _merge

tempfile part1
save `part1'

replace ccode = ccodeb
drop stateabb ccodeb
drop if ccode == .
mmerge ccode using "cor_war_(cow)_codes.dta"
tempfile part2
save `part2'

append using `part1'
drop _merge ccodeb

// make sure that each Country ISO3c code has a 1-1 match with the numeric codes
preserve
keep ccode stateabb
duplicates drop
check_dup_id "stateabb"
check_dup_id "ccode"
restore

// pivot longer: ---------
drop filename
ds
local varlist `r(varlist)'
di "`varlist'"
gen id = _n
local excluded ccode warnum stateabb id
local varlist : list varlist - excluded
di "`varlist'"
foreach i in `varlist' {
	rename `i' stub`i'
}
reshape long stub, i(`excluded') j(type_variable) string
drop if stub == .
keep stateabb type_variable stub
rename (stateabb type_variable stub) (iso3c type1 year)

// label whether the year is the start of a war or the end of a war
// we only keep annual values because our other datasets are annual
gen type = ""
replace type = "END" if ///
			((strpos(type1, "yr") > 0) | (strpos(type1, "year") > 0)) & ///
			(strpos(type1, "end") > 0)
replace type = "START" if ///
			((strpos(type1, "yr") > 0) | (strpos(type1, "year") > 0)) & ///
			((strpos(type1, "start") > 0)|(strpos(type1, "strt") > 0))

drop type1
keep if type != ""

// if there is a war that starts and ends on the same year, then just label is as
// the end in that year (we'll replace ends with indicator showing that it's in
// a war for that year):
duplicates drop
sort iso3c year type
bysort iso3c year: gen dup = _n
assert type == "START" if dup >= 2
drop if dup >= 2
drop dup

tempfile start_end_of_wars_long
save `start_end_of_wars_long'

// create a grid of all the combinations of iso3c and year from 1800 to 2021
keep iso3c
duplicates drop
set obs 400
gen year = 1800 + _n
fillin iso3c year

// Our EXTRA-STATE war dataset goes to 2007.
// Our INTER-STATE war dataset goes to 2010.
// Our INTRA-STATE war dataset goes to 2014.
// So, we have to take the minimum of these dates 
drop if iso3c == "" | year > 2007
drop _fillin

// merge in our war dataset
mmerge iso3c year using `start_end_of_wars_long'
check_dup_id "iso3c year"
sort iso3c year
bysort iso3c: fillmissing type, with(previous)
gen war = 0
replace war = 1 if type == "START"
replace war = 0 if type == "END"
replace war = 0 if type == ""
replace war = 1 if _merge == 3
drop if year > 2007
keep iso3c year war

sort iso3c year
save "finalized_war.dta", replace
