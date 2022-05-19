use "$input/final_raw_labor_growth.dta", clear
keep iso3c year poptotal popwork rgdp_pwt rgdppc_pwt fm_gov_exp rev_inc_sc cpi yield_10yr index_inf_adj flp lp 
label variable rgdppc_pwt "GDP per capita, PPP (PWT)"
save "$input/temp_final_raw_labor_growth.dta", replace

// ----------------------------- vars of interest -----------------------------
// variable
// variable label
// year start
// year end
// number of countries
// number of observations
// source
// ----------------------------------------------------------------------------

// for each variable except iso3c and year, find out & store into this table:

// set a dataset that will "contain" the end results
tempfile summ_stats_tbl
clear
capture log close
set obs 1 
g variable = ""
// g variable_label = ""
// g year_start = 99999999999
// g year_end = 99999999999
// g number_of_countries = 99999999999
// g number_of_observations = 99999999999
// g source = ""
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
    gen check_n = _N
    assert check_n == 1
    drop check_n

    append using `summ_stats_tbl'
    save `summ_stats_tbl', replace   
}

clear
use `summ_stats_tbl'
naomit
drop variable
erase "$input/temp_final_raw_labor_growth.dta"
order variable_label year_start year_end number_of_countries number_of_observations mean sd
sort variable_label
save "$input/summary_statistics_table.dta", replace
.