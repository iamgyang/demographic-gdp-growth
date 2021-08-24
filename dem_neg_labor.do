// somehow use this as well?
// https://www.qogdata.pol.gu.se/search/

// Macros -------------------------------------------------------------------
foreach user in "`c(username)'" {
	global root "C:/Users/`user'/Dropbox/CGD/Projects/dem_neg_labor"
	global input "$root/input/raw"
	global output "$root/output"
	global paper "$root/paper"
}
cd "$input"

global check "yes"

clear all
set more off 
cls

// --------------------------------------------------------------------------

// UN population estimates -------------------------------------------

import delimited "un_WPP2019_PopulationByAgeSex_Medium.csv", clear
keep if variant == "Medium"
keep location time agegrp agegrpstart agegrpspan poptotal
gen agegrpstart2 = min(agegrpstart, 80)
keep if agegrpstart >= 15 & agegrpstart <= 60
collapse (sum) poptotal, by(location time)
replace poptotal = poptotal * 1000
rename location country

// convert country names to ISO3c codes
kountry country, from(other) stuck
ren(_ISO3N_) (temp)
kountry temp, from(iso3n) to(iso3c)
ren (_ISO3C_) (iso3c)

if (1==1) {
	replace iso3c = "BOL" if country == "Bolivia (Plurinational State of)"
	replace iso3c = "CPV" if country == "Cabo Verde"
	replace iso3c = "HKG" if country == "China, Hong Kong SAR"
	replace iso3c = "MAC" if country == "China, Macao SAR"
	replace iso3c = "TWN" if country == "China, Taiwan Province of China"
	replace iso3c = "CIV" if country == "CÃ´te d'Ivoire"
	replace iso3c = "PRK" if country == "Dem. People's Republic of Korea"
	replace iso3c = "SWZ" if country == "Eswatini"
	replace iso3c = "FSM" if country == "Micronesia (Fed. States of)"
	replace iso3c = "PSE" if country == "State of Palestine"
	replace iso3c = "VEN" if country == "Venezuela (Bolivarian Republic of)"
	replace iso3c = "XKX" if country == "Kosovo"
	replace iso3c = "MKD" if country == "North Macedonia"
	replace iso3c = "CUW" if country == "CuraÃ§ao"
	replace iso3c = "REU" if country == "RÃ©union"
	replace iso3c = "PYF" if country == "Polynesia"

	drop temp
	drop if country == "Africa"
	drop if country == "Channel Islands"
	drop if country == "Oceania"
	drop if country == "Melanesia"
	drop if country == "African Group"
	drop if country == "African Union"
	drop if country == "African Union: Central Africa"
	drop if country == "African Union: Eastern Africa"
	drop if country == "African Union: Northern Africa"
	drop if country == "African Union: Southern Africa"
	drop if country == "African Union: Western Africa"
	drop if country == "African, Caribbean and Pacific (ACP) Group of States"
	drop if country == "Andean Community"
	drop if country == "Asia"
	drop if country == "Asia-Pacific Economic Cooperation (APEC)"
	drop if country == "Asia-Pacific Group"
	drop if country == "Association of Southeast Asian Nations (ASEAN)"
	drop if country == "Australia/New Zealand"
	drop if country == "BRIC"
	drop if country == "BRICS"
	drop if country == "Belt-Road Initiative (BRI)"
	drop if country == "Belt-Road Initiative: Africa"
	drop if country == "Belt-Road Initiative: Asia"
	drop if country == "Belt-Road Initiative: Europe"
	drop if country == "Belt-Road Initiative: Latin America and the Caribbean"
	drop if country == "Belt-Road Initiative: Pacific"
	drop if country == "Black Sea Economic Cooperation (BSEC)"
	drop if country == "Bolivarian Alliance for the Americas (ALBA)"
	drop if country == "Caribbean"
	drop if country == "Caribbean Community and Common Market (CARICOM)"
	drop if country == "Central America"
	drop if country == "Central Asia"
	drop if country == "Central European Free Trade Agreement (CEFTA)"
	drop if country == "Central and Southern Asia"
	drop if country == "China (and dependencies)"
	drop if country == "Commonwealth of Independent States (CIS)"
	drop if country == "Commonwealth of Nations"
	drop if country == "Commonwealth: Africa"
	drop if country == "Commonwealth: Asia"
	drop if country == "Commonwealth: Caribbean and Americas"
	drop if country == "Commonwealth: Europe"
	drop if country == "Commonwealth: Pacific"
	drop if country == "Countries with Access to the Sea"
	drop if country == "Countries with Access to the Sea: Africa"
	drop if country == "Countries with Access to the Sea: Asia"
	drop if country == "Countries with Access to the Sea: Europe"
	drop if country == "Countries with Access to the Sea: Latin America and the Caribbean"
	drop if country == "Countries with Access to the Sea: Northern America"
	drop if country == "Countries with Access to the Sea: Oceania"
	drop if country == "Czechia"
	drop if country == "Denmark (and dependencies)"
	drop if country == "ECE: North America-2"
	drop if country == "ECE: UNECE-52"
	drop if country == "ECLAC: Latin America"
	drop if country == "ECLAC: The Caribbean"
	drop if country == "ESCAP region: East and North-East Asia"
	drop if country == "ESCAP region: North and Central Asia"
	drop if country == "ESCAP region: Pacific"
	drop if country == "ESCAP region: South and South-West Asia"
	drop if country == "ESCAP region: South-East Asia"
	drop if country == "ESCAP: ADB Developing member countries (DMCs)"
	drop if country == "ESCAP: ADB Group A (Concessional assistanceÂ only)"
	drop if country == "ESCAP: ADB Group BÂ (OCR blend)"
	drop if country == "ESCAP: ADB Group C (Regular OCR only)"
	drop if country == "ESCAP: ASEAN"
	drop if country == "ESCAP: Central Asia"
	drop if country == "ESCAP: ECO"
	drop if country == "ESCAP: HDI groups"
	drop if country == "ESCAP: Landlocked countries (LLDCs)"
	drop if country == "ESCAP: Least Developed Countries (LDCs)"
	drop if country == "ESCAP: Pacific island dev. econ."
	drop if country == "ESCAP: SAARC"
	drop if country == "ESCAP: WB High income econ."
	drop if country == "ESCAP: WB Low income econ."
	drop if country == "ESCAP: WB Lower middle income econ."
	drop if country == "ESCAP: WB Upper middle income econ."
	drop if country == "ESCAP: WB income groups"
	drop if country == "ESCAP: high HDI"
	drop if country == "ESCAP: high income"
	drop if country == "ESCAP: income groups"
	drop if country == "ESCAP: low HDI"
	drop if country == "ESCAP: low income"
	drop if country == "ESCAP: lower middle HDI"
	drop if country == "ESCAP: lower middle income"
	drop if country == "ESCAP: other Asia-Pacific countries/areas"
	drop if country == "ESCAP: upper middle HDI"
	drop if country == "ESCAP: upper middle income"
	drop if country == "ESCWA: Arab countries"
	drop if country == "ESCWA: Arab least developed countries"
	drop if country == "ESCWA: Gulf Cooperation Council countries"
	drop if country == "ESCWA: Maghreb countries"
	drop if country == "ESCWA: Mashreq countries"
	drop if country == "ESCWA: member countries"
	drop if country == "East African Community (EAC)"
	drop if country == "Eastern Africa"
	drop if country == "Eastern Asia"
	drop if country == "Eastern Europe"
	drop if country == "Eastern European Group"
	drop if country == "Eastern and South-Eastern Asia"
	drop if country == "Economic Community of Central African States (ECCAS)"
	drop if country == "Economic Community of West African States (ECOWAS)"
	drop if country == "Economic Cooperation Organization (ECO)"
	drop if country == "Eurasian Economic Community (Eurasec)"
	drop if country == "Europe"
	drop if country == "Europe (48)"
	drop if country == "Europe and Northern America"
	drop if country == "European Community (EC: 12)"
	drop if country == "European Free Trade Agreement (EFTA)"
	drop if country == "European Union (EU: 15)"
	drop if country == "European Union (EU: 28)"
	drop if country == "France (and dependencies)"
	drop if country == "Greater Arab Free Trade Area (GAFTA)"
	drop if country == "Group of 77 (G77)"
	drop if country == "Group of Eight (G8)"
	drop if country == "Group of Seven (G7)"
	drop if country == "Group of Twenty (G20) - member states"
	drop if country == "Gulf Cooperation Council (GCC)"
	drop if country == "High-income countries"
	drop if country == "LLDC: Africa"
	drop if country == "LLDC: Asia"
	drop if country == "LLDC: Europe"
	drop if country == "LLDC: Latin America"
	drop if country == "Land-locked Countries"
	drop if country == "Land-locked Countries (Others)"
	drop if country == "Land-locked Developing Countries (LLDC)"
	drop if country == "Latin America and the Caribbean"
	drop if country == "Latin American Integration Association (ALADI)"
	drop if country == "Latin American and Caribbean Group (GRULAC)"
	drop if country == "League of Arab States (LAS, informal name: Arab League)"
	drop if country == "Least developed countries"
	drop if country == "Least developed: Africa"
	drop if country == "Least developed: Asia"
	drop if country == "Least developed: Latin America and the Caribbean"
	drop if country == "Least developed: Oceania"
	drop if country == "Less developed regions"
	drop if country == "Less developed regions, excluding China"
	drop if country == "Less developed regions, excluding least developed countries"
	drop if country == "Less developed: Africa"
	drop if country == "Less developed: Asia"
	drop if country == "Less developed: Latin America and the Caribbean"
	drop if country == "Less developed: Oceania"
	drop if country == "Low-income countries"
	drop if country == "Lower-middle-income countries"
	drop if country == "Middle Africa"
	drop if country == "Middle-income countries"
	drop if country == "More developed regions"
	drop if country == "More developed: Asia"
	drop if country == "More developed: Europe"
	drop if country == "More developed: Northern America"
	drop if country == "More developed: Oceania"
	drop if country == "Netherlands (and dependencies)"
	drop if country == "New EU member states (joined since 2004)"
	drop if country == "New Zealand (and dependencies)"
	drop if country == "No income group available"
	drop if country == "Non-Self-Governing Territories"
	drop if country == "North American Free Trade Agreement (NAFTA)"
	drop if country == "North Atlantic Treaty Organization (NATO)"
	drop if country == "Northern Africa"
	drop if country == "Northern Africa and Western Asia"
	drop if country == "Northern America"
	drop if country == "Northern Europe"
	drop if country == "Oceania (excluding Australia and New Zealand)"
	drop if country == "Organisation for Economic Co-operation and Development (OECD)"
	drop if country == "Organization for Security and Co-operation in Europe (OSCE)"
	drop if country == "Organization of American States (OAS)"
	drop if country == "Organization of Petroleum Exporting countries (OPEC)"
	drop if country == "Organization of the Islamic Conference (OIC)"
	drop if country == "SIDS Atlantic, and Indian Ocean, Mediterranean and South China Sea (AIMS)"
	drop if country == "SIDS Caribbean"
	drop if country == "SIDS Pacific"
	drop if country == "Shanghai Cooperation Organization (SCO)"
	drop if country == "Small Island Developing States (SIDS)"
	drop if country == "South America"
	drop if country == "South Asian Association for Regional Cooperation (SAARC)"
	drop if country == "South-Eastern Asia"
	drop if country == "Southern Africa"
	drop if country == "Southern African Development Community (SADC)"
	drop if country == "Southern Asia"
	drop if country == "Southern Common Market (MERCOSUR)"
	drop if country == "Southern Europe"
	drop if country == "Sub-Saharan Africa"
	drop if country == "UN-ECE: member countries"
	drop if country == "UNFPA Regions"
	drop if country == "UNFPA: Arab States (AS)"
	drop if country == "UNFPA: Asia and the Pacific (AP)"
	drop if country == "UNFPA: East and Southern Africa (ESA)"
	drop if country == "UNFPA: Eastern Europe and Central Asia (EECA)"
	drop if country == "UNFPA: Latin America and the Caribbean (LAC)"
	drop if country == "UNFPA: West and Central Africa (WCA)"
	drop if country == "UNICEF PROGRAMME REGIONS"
	drop if country == "UNICEF Programme Regions: East Asia and Pacific (EAPRO)"
	drop if country == "UNICEF Programme Regions: Eastern Caribbean"
	drop if country == "UNICEF Programme Regions: Eastern and Southern Africa (ESARO)"
	drop if country == "UNICEF Programme Regions: Europe and Central Asia (CEECIS)"
	drop if country == "UNICEF Programme Regions: Latin America"
	drop if country == "UNICEF Programme Regions: Latin America and Caribbean (LACRO)"
	drop if country == "UNICEF Programme Regions: Middle East and North Africa (MENARO)"
	drop if country == "UNICEF Programme Regions: South Asia (ROSA)"
	drop if country == "UNICEF Programme Regions: West and Central Africa (WCARO)"
	drop if country == "UNICEF REGIONS"
	drop if country == "UNICEF Regions: East Asia and Pacific"
	drop if country == "UNICEF Regions: Eastern Europe and Central Asia"
	drop if country == "UNICEF Regions: Eastern and Southern Africa"
	drop if country == "UNICEF Regions: Europe and Central Asia"
	drop if country == "UNICEF Regions: Latin America and Caribbean"
	drop if country == "UNICEF Regions: Middle East and North Africa"
	drop if country == "UNICEF Regions: North America"
	drop if country == "UNICEF Regions: South Asia"
	drop if country == "UNICEF Regions: Sub-Saharan Africa"
	drop if country == "UNICEF Regions: West and Central Africa"
	drop if country == "UNICEF Regions: Western Europe"
	drop if country == "UNITED NATIONS Regional Groups of Member States"
	drop if country == "United Kingdom (and dependencies)"
	drop if country == "United Nations Economic Commission for Africa (UN-ECA)"
	drop if country == "United Nations Economic Commission for Latin America and the Caribbean (UN-ECLAC)"
	drop if country == "United Nations Economic and Social Commission for Asia and the Pacific (UN-ESCAP) Regions"
	drop if country == "United Nations Member States"
	drop if country == "United States of America (and dependencies)"
	drop if country == "Upper-middle-income countries"
	drop if country == "WB region: East Asia and Pacific (excluding high income)"
	drop if country == "WB region: Europe and Central Asia (excluding high income)"
	drop if country == "WB region: Latin America and Caribbean (excluding high income)"
	drop if country == "WB region: Middle East and North Africa (excluding high income)"
	drop if country == "WB region: South Asia (excluding high income)"
	drop if country == "WB region: Sub-Saharan Africa (excluding high income)"
	drop if country == "WHO Regions"
	drop if country == "WHO: African region (AFRO)"
	drop if country == "WHO: Americas (AMRO)"
	drop if country == "WHO: Eastern Mediterranean Region (EMRO)"
	drop if country == "WHO: European Region (EURO)"
	drop if country == "WHO: South-East Asia region (SEARO)"
	drop if country == "WHO: Western Pacific region (WPRO)"
	drop if country == "West African Economic and Monetary Union (UEMOA)"
	drop if country == "Western Africa"
	drop if country == "Western Asia"
	drop if country == "Western Europe"
	drop if country == "Western European and Others Group (WEOG)"
	drop if country == "World"
	drop if country == "World Bank Regional Groups (developing only)"   
}

if ("$check" == "yes") {
	pause on
	preserve
	keep country iso3c
	duplicates drop
	br
	pause "does everything look okay?"
	restore
	pause off    
}

drop country
rename (poptotal time) (pop_worker year)

save un_pop_estimates_cleaned.dta, replace


// PWT GDP (growth rates) ------------------------------------------

use pwt100.dta, clear
keep rgdpna countrycode year
drop if rgdpna == .
rename (rgdpna countrycode) (rgdp_pwt iso3c)
save pwt_cleaned.dta, replace

// Income levels -------------------------------------------------

import excel world_bank_classes.xlsx, sheet("List of economies") firstrow clear
keep Code Incomegroup
rename (Code Incomegroup) (iso3c income)
drop if income == ""
save income_cleaned.dta, replace

// Gov't revenue and deficit levels ------------------------------
// https://stats.oecd.org/Index.aspx?DataSetCode=RS_AFR
program drop _all

program clean_oecd
	args indicator_ measure_ tempfilename_ variable_
	keep if indicator == "`indicator_'"
	keep if measure == "`measure_'"
	keep location time value
	rename (location time value) (iso3c year `variable_')
	save "`tempfilename_'", replace
	end
	
program check_dup_id
	args id_vars
	preserve
	keep `id_vars'
	sort `id_vars'
    quietly by `id_vars':  gen dup = cond(_N==1,0,_n)
	assert dup == 0
	restore
	end
	
// revenue
import delimited oecd_DP_LIVE_11082021203447392.csv, encoding(UTF-8) clear 
clean_oecd GGREV PC_GDP oecd_govt_rev.dta gov_rev_pc_gdp
check_dup_id "iso3c year"

// deficit
import delimited oecd_DP_LIVE_11082021203534767.csv, encoding(UTF-8) clear 
clean_oecd GGNLEND PC_GDP oecd_govt_deficit.dta gov_deficit_pc_gdp
check_dup_id "iso3c year"

// expenditrure
import delimited oecd_DP_LIVE_11082021203550955.csv, encoding(UTF-8) clear 
keep if indicator == "GGEXP"
keep if measure == "PC_GDP"
keep location time value subject
reshape wide value, i(location time) j(subject) string
rename value* gov_exp_*
rename (location time) (iso3c year)
check_dup_id "iso3c year"
save "oecd_govt_expend.dta", replace

// tax revenue
import delimited oecd_RS_GBL_11082021204025971.csv, encoding(UTF-8) clear 
keep if indicator == "Tax revenue as % of GDP"
keep if levelofgovernment == "Total"
keep if taxrevenue == "Total tax revenue"
keep cou year value
rename (cou value) (iso3c gov_tax_rev_pc_gdp)
check_dup_id "iso3c year"
save "oecd_tax_revenue.dta", replace

// merge with FTSE, NIKKEI, and S&P (Baker, Bloom, & Terry) -----------------
// https://sites.google.com/site/srbaker/academic-work
// importantly, Baker, Bloom, & Terry data is normalized to have SD = 1
// ask them for their data?
use baker_bloom_terry_panel_data.dta, clear
keep country yq l1lavgvol l1avgret
sort country yq

// merge with Correllates of war --------------------------------------------
// make sure that we have 1 country-year after the merge

// get the country codes ----------
import delimited system2016.csv, clear
keep stateabb ccode
duplicates drop
sort ccode
gen ccodel1 = ccode[_n-1]
assert ccodel1 != ccode
drop ccodel1
save "cor_war_(cow)_codes.dta", replace

// define program to load each correllates of war dataset:
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
	foreach i of varlist _all {
		replace `i' = . if inlist(`i', -9, -8, -7, -6)
	}
end

tempfile intra inter nonstate extra

// INTRA -------
clear
clean_cow "INTRA-STATE WARS v5.1.dta" "warnum ccode* startmo* starty* endmo* endy*"
save `intra'

// INTER --------
clean_cow "directed dyadic war may 2018.dta" "warnum state* warstrtmnth warstrtday warstrtyr warendmnth warenday warendyr"
save `inter'

// NONSTATE ---------
import delimited "cow_Non-StateWarData_v4.0.csv", clear

// EXTRA-STATE ----------
clean_cow "Extra-StateWarData_v4.0.csv" "warnum ccode* startmo* starty* endmo* endy*"

// we can replace ccode2 variable because this is a 1-state w/ a nonstate actor
replace ccode1 = ccode2 if ccode1 == .
assert ccode1 != .
assert ccode1 ==ccode2 if ccode2 != .
drop ccode2
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
assert inlist(_m, 1, 3)
keep if _m == 3
drop _m

tempfile part1
save `part1'

replace ccode = ccodeb
drop stateabb ccodeb
drop if ccode == .
mmerge ccode using "cor_war_(cow)_codes.dta"
tempfile part2
save `part2'

append using `part1'
drop _m ccodeb

// make sure that each Country ISO3c code has a 1-1 match with the numeric codes
preserve
keep ccode stateabb
duplicates drop
check_dup_id "stateabb"
check_dup_id "ccode"
restore

// pivot longer: ---------
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
drop if iso3c == "" | year > 2021
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
replace war = 1 if _m == 3


































// TODO: finish appending and merging this
// ?????? TODO: ask Charles what to do about NON-state war? --> don't have country codes
// to do: turning each intrastate, interstate war 
// into labeled countrycodes
// --------------------
// confirm that dyadic war can REPLACE interstate war?
// --------------------
// one concern about the use of fertility as an IV for number of workers 20-65 is 
// that it doesn't include immigrants *into* a country
// --------------------
// what does the literature say about growth regressions of this sort?

// --------------------
// restrict population to 5 year chunks (mod 5)
// sum population aged 20-64 for each country
// take a lag of that sum & find the percent change in population
// tag whether that percent difference is negative
// create a histogram with x axis being the 5 year period
// histogram of percentage drop of workers GIVEN negative drop in workers
// get average growth for 10 yr period before labor growth was negative
// create a table of 5 yr growth rates VS. global & income group average growth
// keep fertility rates
// --------------------
// And adding a bit more:
//
// I’m interested in looking at the impact of negative labor force growth on economies.  Pretty simple stuff at least to begin:
//
// Using the UN population data, find all five-year periods where countries have experienced an absolute decline in their population aged 20-64. (A brief look suggests there are 203 historical cases at the country level).
//
// When did they happen (just a histogram by five year period)? How large the percentage drop in workers (*median* size by five year period)
//
// *median* size by five year period --> what do you mean here? get the median percent worker drop?
//
// What were economic growth rates during those five year periods compared to the (last) (ten year?) period before labor force growth was negative?
//
// What were economic growth rates during those five year periods compared to the global (and country income group) average growth?
//
// What happened to government revenues and deficits during those periods compared to prior?
//
// What happened to interest rates and stock market returns?
//
// What happened to the unemployment rate total labor force participation and female labor force participation?
//
// Take out cases which overlap with a country being at war (https://correlatesofwar.org/data-sets) and then take out low and lower middle income countries and see if that makes a difference.
//
// Look forward: according to the UN population forecasts, how many countries in each forthcoming five year period will see declining working age population? How large the percentage drop in workers (*median* size by five year period)
//
// “instrument’ or just use the predicted change in working age population from ten years prior (e.g. us value for population aged 10-54 in 1980 as the value for population aged 20-64 in 1990) and/or try 20 year lag.
//
// Thanks!
