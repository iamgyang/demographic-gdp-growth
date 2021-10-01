// Analysis -------------------

// Create a histogram with x axis being the 5 year period
use "final_derived_labor_growth.dta", clear

drop if year >= 2020 | year <= 1950
histogram year, percent ytitle(Percent) by(NEG_popwork) discrete
graph export "hist_negative_pop_years_5yr_periods.png", width(2600) height(1720) replace
graph close

keep NEG_popwork year iso3c
drop if NEG_popwork	== ""
gen neg = 1 if NEG_popwork == "Negative"
replace neg = 0  if NEG_popwork == "Positive"
gen pos = abs(1-neg)
drop NEG_popwork 
br if year == 1995 & neg == 1
collapse (sum) neg pos, by(year)

graph bar (asis) neg pos, over(year, label(angle(vertical))) stack
graph export "hist_negative_pop_years_5yr_periods.png", width(2600) height(1720) replace

// Median size of pop growth decline:

use "final_derived_labor_growth.dta", clear
keep if NEG_rgdp_pwt == "Negative"
tabstat aveP1_rgdp_pwt, statistics(median) save
ret list
mat B = r(StatTotal)

// This is the median average annual negative growth rate across 5 yr period
// (countries can have duplicate 5 year periods).
capture log close
set logtype text
log using log_results_labor_growth.txt, replace
display c(current_time)

di "median average annual negative growth rate across 5 yr period: " B[1,1]

display c(current_time)
log close

// Compare 5-yr period of growth NEGATIVE growth rates to the PREVIOUS 10-yr
// growth rates (annualized). Create a bar graph that has the average GDP growth
// rate during a period of 5-years of labor force decline compared to the
// most recent 10-years where the average labor force did not decline.
quietly capture program drop bar_graph_ave_growth_rate
program bar_graph_ave_growth_rate
args title
#delimit ;
		graph bar (asis) ave_growth, over(period) blabel(bar, size
		(medium) color(black)) ytitle(Growth Rate) 
		ytitle(, size(medium)) title("`title'", size(medlarge)) 
		scheme(s2color) graphregion(margin(medium) fcolor(white) 
		ifcolor(white) ilcolor(none)) plotregion(margin(medium) fcolor(white) 
		lcolor(none) ifcolor(white) ilcolor(none)) yscale(noline) ylabel(, nogrid)
		;
#delimit cr
end

preserve
	keep if NEG_popwork == "Negative"
	keep iso3c year aveP2_rgdp_pwt_bef aveP1_rgdp_pwt
	naomit
	reshape long ave, i(iso3c year) j(period, string)
	rename ave ave_growth
	replace period = "5 yr negative" if period == "P1_rgdp_pwt"
	replace period = "10 yr positive" if period == "P2_rgdp_pwt_bef"
	collapse (mean) ave_growth, by(period)
	replace ave_growth=round(ave_growth, 0.001)
	bar_graph_ave_growth_rate `"GDP growth rate during periods of" "positive or negative labor force growth"'
	graph export "bar_GDP_growth_pos_neg_labor_growth.png", replace
	graph close
restore

// What were economic growth rates during those five year periods compared to 
// the global (and country income group) average growth?
bysort income year: egen income_aveP1_rgdp_pwt=mean(aveP1_rgdp_pwt)
bysort        year: egen global_aveP1_rgdp_pwt=mean(aveP1_rgdp_pwt)
preserve
	keep if NEG_popwork == "Negative"
	keep iso3c year income aveP1_rgdp_pwt income_aveP1_rgdp_pwt global_aveP1_rgdp_pwt
	naomit
	rename (aveP1_rgdp_pwt income_aveP1_rgdp_pwt global_aveP1_rgdp_pwt) (aveP1_rgdp_pwt ave_income_aveP1_rgdp_pwt ave_global_aveP1_rgdp_pwt)
	drop income
	reshape long ave, i(iso3c year) j(period, string)
	replace period = "5 yr negative" if period == "P1_rgdp_pwt"
	replace period = "Global" if period == "_global_aveP1_rgdp_pwt"
	replace period = "Income-group" if period == "_income_aveP1_rgdp_pwt"
	rename ave ave_growth
	collapse (mean) ave_growth, by(period)
	replace ave_growth=round(ave_growth, 0.001)
	bar_graph_ave_growth_rate `"GDP growth rate during periods of" "negative labor force growth" "(vs. global and income-group average)"'
	graph export "bar_GDP_growth_neg_labor_growth_income_world.png", replace
	graph close
restore

// What happened to government revenues and deficits during those periods 
// compared to prior? ---------------------------------------------------------

foreach exp_or_rev in fm_gov_exp rev_inc_sc {
	use "final_labor_growth_w_derived_variables.dta", clear
	
	keep if NEG_popwork == "Negative"
	// !!!!!!!!!!
	// WHY are we missing so much data here?
// 	local exp_or_rev fm_gov_exp
	keep iso3c year aveP1_`exp_or_rev' aveP1_`exp_or_rev'_bef NEG_popwork
	
	naomit

	ds
	local varlist `r(varlist)'
	local excluded iso3c year
	local to_gather: list varlist - excluded
	foreach i in `to_gather' {
		rename `i' ave`i'
	}
	reshape long ave, i(iso3c year) j(period, string)

	replace period = "Negative" if period == "aveP1_`exp_or_rev'"
	replace period = "Positive" if period == "aveP1_`exp_or_rev'_bef"

	rename ave ave_growth
	collapse (mean) ave_growth, by(period)
	replace ave_growth=round(ave_growth, 0.001)

	local rev_exp_label = cond("`exp_or_rev'" == "fm_gov_exp" , "Expenditure", "Revenue")

	bar_graph_ave_growth_rate `"`rev_exp_label' growth rate during periods of" "negative and positive labor force growth" "(5 year annual average)"'
	graph export "bar_`rev_exp_label'_growth_neg_labor_growth.png", replace
	graph close
}















































































