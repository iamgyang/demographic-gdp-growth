
use "$input/final_raw_labor_growth.dta", clear
keep iso3c year poptotal popwork rgdp_pwt rgdppc_pwt fm_gov_exp rev_inc_sc cpi cpi_growth yield_10yr index_inf_adj stock_index_growth flp lp 

replace rgdp_pwt 	= rgdp_pwt * 1000000    // convert from millions
replace rgdppc_pwt 	= rgdppc_pwt * 1000000  // convert from millions

*** Save a .csv of the Govt Expenditures outliers
preserve
	keep iso3c year fm_gov_exp
	keep if fm_gov_exp > 100 & !missing(fm_gov_exp)
	gsort -fm_gov_exp
	kountry iso3c, from(iso3c)
	rename NAMES_STD country_name
	export delimited using "$root/outliers/fm_gov_exp outliers.csv", replace
restore

*** Save a .csv of the cpi_growth outliers
preserve
	keep iso3c year cpi_growth cpi
	keep if cpi_growth > 100 & !missing(cpi_growth)
	gsort -cpi_growth
	kountry iso3c, from(iso3c)
	rename NAMES_STD country_name
	export delimited using "$root/outliers/cpi_growth outliers.csv", replace
restore

drop 	  cpi  index_inf_adj
save "$input/temp_final_raw_labor_growth.dta", replace

// ----------------------------- vars of interest -----------------------------
// variable
// variable label
// year start
// year end
// number of countries
// number of observations
// ----------------------------------------------------------------------------

// for each variable except iso3c and year, find out & store into this table:

// set a dataset that will "contain" the end results
tempfile summ_stats_tbl
clear
capture log close
set obs 1 
g variable = ""
save `summ_stats_tbl', replace
clear

// list all variables except ID variables
use "$input/temp_final_raw_labor_growth.dta", clear
macro drop varlist
ds
local varlist `r(varlist)'
local excluded iso3c year
local varlist : list varlist - excluded 
di "`varlist'"
di "`r(varlist)'"

sum `varlist'

// create my table
foreach var in `varlist' {
	use "$input/temp_final_raw_labor_growth.dta", clear
	di "`var'"

    keep iso3c year `var'
    naomit
    
    g variable = "`var'"

    // variable label:
    loc lab: variable label `var'
    g variable_label = "`lab'"

    // other metrics:
    gegen year_start = min(year)
    gegen year_end = max(year)
    g number_of_observations = _N
	gegen mean = mean(`var')
	gegen sd = sd(`var')
	
    drop `var' year
    gduplicates drop
    g number_of_countries = _N
    
    // keep only this one row where we have the summary stats
    keep variable variable_label year_start year_end number_of_countries ///
    number_of_observations mean sd
    gduplicates drop
    assert _N == 1

    append using `summ_stats_tbl'
    save `summ_stats_tbl', replace
}

clear
use `summ_stats_tbl'
drop if variable == ""
drop variable
erase "$input/temp_final_raw_labor_growth.dta"
order variable_label year_start year_end number_of_countries number_of_observations mean sd 
sort variable_label
save "$input/summary_statistics_table.dta", replace
