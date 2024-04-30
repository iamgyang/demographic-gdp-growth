// set a dataset that will "contain" the end results (number of 
// countries, average growth, etc.)
tempfile avg_growth
clear
capture log close
set obs 1 
gen ave_growth = 99999999
gen income_var = "NA"
gen war_var = "NA"
gen num_country_years = 99999999
gen var = "NA"
gen within_country_var = "NA"
save `avg_growth', replace
clear


foreach within_country_var in "Within" "Between" {
foreach income_var in "LIC_LMIC" "UMIC" "HIC" {
foreach war_var in "Including" "Excluding" {
foreach var in rgdp_pwt rgdppc_pwt fm_gov_exp rev_inc_sc cpi yield_10yr index_inf_adj flp lp {
	if ($test_run == 1) {
		local war_var "Including"
		local income_var "LIC_LMIC"
		local var lp
		local within_country_var "Within"
	}

	di "`within_country_var' `income_var' `war_var' `var'"
	
	// just to be safe, drop all the local macros here:
	foreach i in lab income_var war_var within_country_var num_countries num_obs {
		quietly capture macro drop `i'
	}
	
	use "$input/final_derived_labor_growth.dta", clear
	
	if ("`var'" == "cpi") {
	    drop if iso3c == "VEN"
	}
	
	/* DELETE:
	use "$input/final_derived_labor_growth.dta", clear
	sort iso3c year
	keep iso3c year aveP1_rgdp_pwt*
	keep if !missing(aveP1_rgdp_pwt) & !missing(aveP1_rgdp_pwt_bef)
	reshape long ave, i(iso3c year) j(period, string)
	replace period = cond(regexm(period, "_bef$"), "Negative", "Positive")
	gcollapse (mean) ave, by(iso3c period year)
	sort iso3c year period
	
	use "$input/final_derived_labor_growth.dta", clear
		
	count if !missing(aveD1_yield_10yr) & NEG_popwork == "Negative"
	count if (!missing(aveD1_yield_10yr)) & (NEG_popwork == "Negative") & (income == "LIC" | income == "LMIC")
	count if (!missing(aveD1_yield_10yr)) & (NEG_popwork == "Negative") & (income == "LIC" | income == "LMIC") & (!missing(income)) & (!missing(est_deaths))  
	replace aveP1_yield_10yr = .
	replace aveP1_yield_10yr = aveD1_yield_10yr
	
	drop if missing(income)
	keep if income == "HIC"
		
	bys iso3c (year): egen country_total_negpapg = max(sum((NEG_popwork == "Negative")))
	keep if country_total_negpapg > 0
	
	keep iso3c year NEG_popwork aveP1_yield_10yr 
	sort iso3c year
	
	keep if !missing(aveP1_yield_10yr) 
	*reshape long ave, i(iso3c year) j(period, string)
	*replace period = cond(regexm(period, "_bef$"), "Negative", "Positive")
	rename aveP1_yield_10yr ave
	rename NEG_popwork period
	
	gcollapse (mean) ave, by(iso3c period) // year
	sort iso3c year period
	
	*------
	
	use "$input/final_derived_labor_growth.dta", clear
	sort iso3c year
	keep iso3c year aveP1_rgdp_pwt NEG_popwork
	keep if !missing(aveP1_rgdp_pwt) & !missing(NEG_popwork)
	rename (aveP1_rgdp_pwt NEG_popwork) (ave_growth period)
	
	count if period == "Negative"
	local neg_countries `r(N)'
	di "`neg_countries'"
	summ iso3c year if period == "Positive"
	local pos_countries `r(N)'
		
	
	
	*/

	// if the variables come in percentage format and are typically interpreted
	// in basis point increases (as opposed to percent increases), then we're
	// going to use a difference here. (i.e. the yield on the 10 year bond
	// increased by X percentage points, rather than Y percent, as the latter
	// would be a percent of a percent value.). 
	if ("`var'" == "flp" | "`var'" == "yield_10yr" | "`var'" == "lp") {
		replace aveP1_`var' = .
		replace aveP1_`var' = aveD1_`var'
	}

	// conditions to narrow the dataset:
	if ("`war_var'" == "Excluding") {
		drop if missing(est_deaths)  // why drop missing war deaths data if 'excluding'? presumably missing ususally means not much war going on?
		drop if est_deaths >= 10000
	}
	if ("`income_var'" == "LIC_LMIC") {
		drop if missing(income)
		keep if income == "LIC" | income == "LMIC"
	}
	else if ("`income_var'" != "LIC_LMIC") {
		drop if missing(income)
		keep if income == "`income_var'"
	}
	loc lab: variable label `var'
	
	// Between compares years with negative and positive working-age population 
	// growth across every country. Within compares years with negative and
	// positive working-age population growth within the same country. Within
	// uses  the earliest prior period of positive working-age population growth.
	// ILO estimates are non-modeled national reports.
	
	if ("`within_country_var'" == "Within") {
		* Want to stop using the period of Pos PAPG immediately before the period of negative, and use the *entire* period of pos PAPG before the negative
		* (Note: this variable generation should be moved outside the loop for efficiency if convenient)
		bys iso3c (year): egen country_total_negpapg = max(sum((NEG_popwork == "Negative")))
		keep if country_total_negpapg > 0
		
		keep iso3c year NEG_popwork aveP1_`var' //aveP1_`var'_bef
		*pause 6K62V "`within_country_var'" "`income_var'" "`war_var'" "`var'"
		keep if !missing(aveP1_`var') //& !missing(aveP1_`var'_bef)    // Keeps only rows (country-years) with *both* aveP1_`var' and aveP1_`var'_bef !missing (i.e. Negative popwork growth country-years)
		
		/*
		ds
		local varlist `r(varlist)'
		local excluded iso3c year NEG_popwork
		local to_gather: list varlist - excluded
		foreach i in `to_gather' {
			rename `i' ave`i'
		}
		pause 8Kmon "`within_country_var'" "`income_var'" "`war_var'" "`var'"
		*/
		count
		local num_obs `r(N)'
		di "obs: `num_obs'"
		if (`num_obs' > 0) {
			*reshape long ave, i(iso3c year) j(negpapg_indicator, string)
			*replace period = "Negative" if period == "aveP1_`var'"
			*replace period = "Positive" if period == "aveP1_`var'_bef"
			*rename ave ave_growth
			rename (aveP1_`var') (ave_growth)
			rename (NEG_popwork) (period)
			
		// make sure we're equal-weighting each country when we're doing 
		// "within" aggregation
		// ZG Note: Wouldn't this only equal-weight countries if we did by(iso3c period) (w/o year)?
		//          Because as is, countries will have different weights depending on how many years are included
		//          which is determined by how many periods of negative PAPG they have
		//          Perhaps I'm misunderstanding
		gcollapse (mean) ave_growth, by(iso3c period) // year
		}
		
	}
	else if ("`within_country_var'" == "Between") {
		keep iso3c year aveP1_`var' NEG_popwork
		pause P60ec 
		naomit
		pause l9YtQ "`within_country_var'" "`income_var'" "`war_var'" "`var'"
		rename (aveP1_`var' NEG_popwork) (ave_growth period)
		drop year
	}
	
	// only create output numbers if there are enough observations.
	count
	local num_obs `r(N)'
	if (`num_obs' > 0) {
		pause l4FOo "`within_country_var'" "`income_var'" "`war_var'" "`var'"
		
		// get country-years
		count if period == "Negative"
		local neg_countries `r(N)'
		count if period == "Positive"
		local pos_countries `r(N)'
		
		gcollapse (mean) ave_growth, by(period)
		// round to 2 sig figs
		replace ave_growth = round(ave_growth,10^(floor(log10(abs(ave_growth)))-1))
		
		// convert to %, but ONLY for the ones where we took the average % difference
		if (!("`var'" == "flp" | "`var'" == "yield_10yr" | "`var'" == "lp")) {
			replace ave_growth = ave_growth * 100
		}
		
		// append this to our table:
		gen label = "`lab'"
		gen income_var = "`income_var'"
		gen war_var = "`war_var'"
		gen num_country_years = `pos_countries' if period == "Positive"
		replace num_country_years = `neg_countries' if period == "Negative"
		gen within_country_var = "`within_country_var'"
		gen var = "`var'"
		append using `avg_growth'
		save `avg_growth', replace
	}
}
}
}
}

use `avg_growth'

save "$output/raw_table_avg_growth.dta", replace

// Output to LATEX -------------------------------------------------------------

// much of the rest of this is aesthetics RE: LATEX

use "$output/raw_table_avg_growth.dta", clear

drop if var == "NA"
**** Temporarily(?) stop dropping if obs is under 10, because now for Within num_country_years is only counting countries*2
*drop if num_country_years<10
gen ave_growth_str = string(ave_growth)
gen num_country_years_str = string(num_country_years)
replace ave_growth_str = ave_growth_str + " (" + num_country_years_str + ")"
drop var num_country_years* ave_growth
rename ave_growth_str ave_growth
replace period = "+" if period == "Positive"
replace period = "-" if period == "Negative"
foreach i in war_var {
	replace `i' = "exc" if `i' == "Excluding"
	replace `i' = "inc" if `i' == "Including"
}

// this allows us to reshape the variable later
replace income_var = "LL" if income_var == "LIC_LMIC"
replace income_var = income_var + "_w_" + war_var
drop war_var

reshape wide ave_growth, i(period label within_country_var) j(income_var, string)
rename ave_growth* *

order label within_country_var period HIC_w_exc HIC_w_inc UMIC_w_exc UMIC_w_inc //LL_w_exc LL_w_inc
sort label within_country_var period

// being foxy with LATEX: replace percent signs, anything in parenthesis,
// the words "LFP". make sure that every other row is blank, since we have 
// 2 observations per variable:
sort label
gen count = 1
bysort label: egen count2 = sum(count)
assert count2 == 4
drop count*
gen n = mod(_n, 4)
replace label = subinstr(label, "Government", "Govt", .)
replace label = subinstr(label, " including Social Contributions", "", .)
replace label = subinstr(label, "Labor Force Participation", "LFP", .)

// remove all things in parentheses
replace label = trim(regexr(label , "\((.)+\)", ""))

// merge rows when applicable
replace label = "\multirow{2}[0]{3cm}{" + label + "}"
replace label = "" if n != 1
br

gen group_n = floor((_n - 1) / 4)
qui sum group_n
local last_group_n = r(max)
*replace last_row = last_row - 1

// the top and bottom variables should be slightly different
replace label = subinstr(label, "\multirow{2}[0]", "\multirow{2}[1]", .) ///
	if group_n == 1 | (group_n == `last_group_n')

// modify period:
replace within_country_var = "\multirow{2}[0]{*}{" + within_country_var + "}" if mod(n, 2) == 1
replace within_country_var = "" if mod(n, 2) != 1

// draws a horizontal line in between each variable category
replace label = "\midrule\\" + label if _n != 1 & mod(_n, 4) == 1
replace label = subinstr(label, "%", "\%",.)

drop group_n n

// Drop the 'Excluding' war variables, and the LIC+LMIC variables
drop *_exc LL*
order label within_country_var period HIC_w_inc UMIC_w_inc 

// output to latex:

#delimit ;
texsave * using "$output/table1.tex", 
nonames replace frag 
headerlines(
"\multicolumn{1}{l}{Variable} & \multicolumn{1}{p{10em}}{Aggregation Method} & Labor Force Growth & HIC   & UMIC"
) 
size(3) width(1\textwidth)
title ("Growth (\%) during periods of working age population decline" "vs. periods of working age population growth") 
nofix 
marker(results_region) 
footnote("NOTE --- The \textit{between} aggregation simply takes averages of all country-years of data with positive PAPG and compares it to the average of all country-years of data with negative PAPG. The \textit{within} aggregation is limited to countries that have seen negative PAPG during the period covered by our data and also have data on a prior period of positive PAPG.   For those countries we took an average of the positive and an average of the negative periods of growth before averaging the positive and negative PAPG period growth rates across countries. For female labor force participation, labor force participation, and yields, we do not use growth rates, but rather differences, as changes in these variables (which are already in percentage form) are typically quoted in percentage points. ILO estimates are non-modeled national reports. Government revenue includes social contributions. Venezuela CPI data was omitted.")
;
#delimit cr
// Sentence for the note if you're showing 'Excluded' Wars: "Wars were excluded based on whether there were more than 10,000 battle-related deaths in that geography as reported by Uppsala University UCDP data."

// adjust the TXT output file:
// adjustments to the base latex file:
import delimited "$output/table1.tex", clear
// replace v1 = subinstr(v1, "\end{tabularx}","\end{tabularx}\end{adjustbox}",1) 
replace v1 = subinstr(v1, "\begin{tabularx}{1\textwidth}{@{}lCCCC@{}}", "\begin{tabularx}{1\textwidth}{p{3cm}lCCXX}",1) 

replace v1 = subinstr(v1, "{\footnotesize", "{\scriptsize\hfill \textit{Number of country-years (between), or country means (within), are in parentheses.}",1) if ((strmatch(v1, "{\footnotesize")) & (!strmatch(v1, "NOTE")))
				

// replace v1 = subinstr(v1, "\begin{tabularx}","\begin{adjustbox}{angle=90}\begin{tabularx}",1)

// replace that output file once more:
outfile using "$output/table1.tex", noquote replace wide

// Analysis of only HICs ---------------------------------------------------
use "$input/final_derived_labor_growth.dta", clear
keep if income == "HIC"
keep if !missing(NEG_popwork)
gen count = 1
foreach v of varlist _all {
    quietly capture macro drop `v'll
	local `v'll: var label `v'
}
gcollapse (mean) rgdp_pwt rgdppc_pwt fm_gov_exp rev_inc_sc cpi yield_10yr index_inf_adj flp lp (sum) count, by(year NEG_popwork)
foreach v of varlist _all {
	label var `v' `"``v'll'"'
}
drop if count < 10

save "$input/hics_collapsed_final_derived_labor_growth.dta", replace

