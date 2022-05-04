// HIC EVENT STUDY GRAPH ------------------------------------------------------

// keep if were high income in 1989
use "$input/final_derived_labor_growth.dta", clear
quietly capture drop income_1989
gen income_1989 = income if year == 1989
bys iso3c: fillmissing income_1989
save "$input/final_derived_labor_growth.dta", replace

// get a list of countries with negative population growth for at least 10 yrs
use "$input/final_derived_labor_growth.dta", clear
keep if year <= 2020 & (income_1989 == "HIC" | income_1989 == "UMIC") //| income == "HIC")
keep iso3c year NEG_popwork
fillin iso3c year
drop _fillin
gen run = 1 if NEG_popwork == "Negative"
sort iso3c year

/* 
generate a ton of lag variables, and then see if they sum up to 10--this
basically accomplishes the same thing as a cumulative sum, EXCEPT that if we
see a sum that equals 10, we know that it was achieved through a consecutive
sum of 10 negative years of working population growth (as opposed to for a sum
of 8, it might be through a non-consecutive sum of 8 negative working
population growth years) 
*/

foreach i of numlist 1/9 {
	bys iso3c: gen run_L`i' = run[_n-`i']
}
egen sum = rowtotal(run*)
keep if sum == 10
drop run_L*

/*
now, we've identified the countries and years where there was a consecutive 10 years of negative growth
*/
sort iso3c year
by iso3c: egen minyr = min(year)
keep if year == minyr
keep iso3c year
gen year_st = year - 20
levelsof(iso3c), local(aging_isos)
tempfile a
save `a'

/* 
Basic strategy is to merge in the start and end dates of the prior dataset
on the aging countries with a dataset of the global HIC means.

Get a dataset of all HICs excluding that country, and keep only the  variable
of interest, the years of interest
*/
use "$input/final_derived_labor_growth.dta", clear
keep if income_1989 == "HIC" | income_1989 == "UMIC"
foreach i in `aging_isos' {
	drop if iso3c == "`i'"
}

gen count = 1
bys year: egen count2 = sum(count)

// make sure that Japan (definitely on our list of aging countries), is not in this list
assert iso3c!="JPN"

// list of variables:
loc vars rgdp_pwt rgdppc_pwt fm_gov_exp rev_inc_sc cpi yield_10yr index_inf_adj flp lp

// This gives us the variables of interest as a mean for all HICs, 
// excluding the countries of interest
keep iso3c year `vars'

// for each variable, I need a fixed sample:
foreach i in `vars' {
    rename `i' stub_`i'
}
reshape long stub_, i(iso3c year) j(var, string)
naomit
sort var iso3c year

// the sample be fixed across all years within each variable
loc fixed_sample_comp "yes"
keep if year <= 2020 //& year >= 1980

tempfile sample_hic_comparator
save `sample_hic_comparator'

bys var: egen minyr = min(year)
if ("`fixed_sample_comp'" == "yes") {
    
	foreach var in `vars' {
		use `sample_hic_comparator', clear
		
		/*
		for female labor force participation and labor force participation, 
		IF we set the first time for the restricted sample to be 1960, then
		we end up only getting 1 country (USA), so I've set it here manually
		to 1980
		*/
		if ("`var'" == "flp" | "`var'" == "lp") {
		    keep if year >= 1980
		}
		
		// for each variable, pivot wider, and na.omit the years to get a fixed sample
		keep if var == "`var'"
		reshape wide stub_, i(iso3c var) j(year)
		naomit
		
		// pivot longer
		reshape long
		
		// save as tempfile
		tempfile tf__`var'
		save `tf__`var''    
	}
	
	// append all together
	clear 
	foreach var in `vars' {
		append using `tf__`var''
	}
	
	// make sure that we have the same number of countries for each sample
	gen count = 1
	bys var year: egen count2 = sum(count)
	bys var: egen count3 = max(count2)
	assert count2 == count3
}

save "$input/fixed_sample_comparator.dta", replace
use "$input/fixed_sample_comparator.dta", clear

// pivot wider
drop count*
reshape wide stub_, i(iso3c year) j(var, string)
rename stub_* *
recast double year
label drop i

// collapse by taking a mean
collapse (mean) `vars', by(year)
mmerge year using `a'
drop _merge
fillin iso3c year
drop _fillin

// because we did a multiple-multiple merge, we have to now fill down the
// missing values for each of the variables of interest--we know that the HIC
// averages should be the SAME every year for real GDP for example, so we
// group by year and fill in missing values.
foreach x in rgdp_pwt rgdppc_pwt fm_gov_exp rev_inc_sc cpi yield_10yr index_inf_adj flp lp {
    bys year: fillmissing `x'
    rename `x' `x'_hic
}
sort iso3c year

// Now we want to restrict our attention to the years that were 10 years prior
// to the negative population event.
bys iso3c: fillmissing year_st, with(next)
keep if year >= year_st & !mi(year_st)

// pivot longer for future merge:
foreach i in rgdp_pwt rgdppc_pwt fm_gov_exp rev_inc_sc cpi yield_10yr index_inf_adj flp lp {
    rename `i'_hic stub_`i'
}
reshape long stub_, i(iso3c year) j(var, string)
sort var iso3c year
rename stub_ value_hic

// save this as a temporary file
tempfile b
save `b'

// now merge in the actual country-level data: (e.g. the data on interest
// rates for Japan)
use "$input/final_derived_labor_growth.dta", clear
keep iso3c year poptotal rgdp_pwt rgdppc_pwt fm_gov_exp rev_inc_sc cpi yield_10yr index_inf_adj flp lp

// pivot longer for merge:
foreach i in rgdp_pwt rgdppc_pwt fm_gov_exp rev_inc_sc cpi yield_10yr index_inf_adj flp lp {
    rename `i' stub_`i'
}
reshape long stub_, i(iso3c year) j(var, string)
sort var iso3c year
rename stub_ value

// and merge...
mmerge iso3c year var using `b'
keep if _merge == 3
drop _merge

// divide by HICs
replace value = value / value_hic

// now, re-order the year variable so that we can compare the start and end
// years: (e.g. if Germany first had a negative population growth at 1969, and
// Japan did at 1989, then make 1969 == 1 for Germany and 1989 == 0 for Japan).
replace year = year - year_st - 10

// index by the year where population is first negative:
gen value1 = value if year == 1
bys var iso3c: fillmissing value1
replace value = value/value1*100
assert value == 100 | mi(value) if year == 1

// get a mean across countries for each year:
bys year var: egen value_mean = mean(value)

keep iso3c year var poptotal value value_mean
order iso3c year var poptotal value value_mean
sort var iso3c year

// export to R for graphing.
save "$input/hic_10yr_event_study.dta", replace


















