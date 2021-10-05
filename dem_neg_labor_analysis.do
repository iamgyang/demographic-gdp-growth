// Analysis -------------------

// Create a histogram with x axis being the 1 year period
use "final_derived_labor_growth.dta", clear

drop if year >= 2020 | year <= 1950
histogram year, percent ytitle(Percent) by(NEG_popwork) discrete
graph export "hist_negative_pop_years_1yr_periods.png", width(2600) height(1720) replace
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
graph export "hist_negative_pop_years_1yr_periods.png", width(2600) height(1720) replace

// Median size of pop growth decline:

use "final_derived_labor_growth.dta", clear
keep if NEG_rgdp_pwt == "Negative"
tabstat aveP1_rgdp_pwt, statistics(median) save
ret list
mat B = r(StatTotal)

// This is the median average annual negative growth rate across 1 yr period
// (countries can have duplicate 1 year periods).
capture log close
set logtype text
log using log_results_labor_growth.txt, replace
display c(current_time)

di "median average annual negative growth rate across 1 yr period: " B[1,1]

display c(current_time)
log close

// Compare 5-yr period of growth NEGATIVE growth rates to the PREVIOUS 10-yr
// growth rates (annualized). Create a bar graph that has the average GDP growth
// rate during a period of 5-years of labor force decline compared to the
// most recent 10-years where the average labor force did not decline.
quietly capture program drop bar_graph_ave_growth_rate
program bar_graph_ave_growth_rate
args title subtitle caption
#delimit ;
		graph bar (asis) ave_growth, over(period) bar(1, fcolor(dknavy) 
		fintensity(inten100) lcolor(none)) blabel(bar) ytitle("") yscale(noline) 
		yline(0, lcolor(none)) ylabel(, labels labsize(small) labcolor(black) 
		ticks tlcolor(black) nogrid) ymtick(, nolabels noticks nogrid) 
		title("`title'") subtitle("`subtitle'", position(11) size(small)) 
		caption("`caption'", size(small) position(5) 
		fcolor(none) lcolor(none)) scheme(plotplainblind) 
		graphregion(fcolor(none) ifcolor(none)) 
		plotregion(fcolor(none) ifcolor(none))
		;
#delimit cr
end

use "final_derived_labor_growth.dta", clear
keep if NEG_popwork == "Negative"
keep iso3c year aveP2_rgdp_pwt_bef aveP1_rgdp_pwt
naomit
summ iso3c year
local num_countries "`r(N)'"
reshape long ave, i(iso3c year) j(period, string)
rename ave ave_growth
replace period = "1 yr negative" if period == "P1_rgdp_pwt"
replace period = "2 yr positive" if period == "P2_rgdp_pwt_bef"
collapse (mean) ave_growth, by(period)
replace ave_growth=round(ave_growth, 0.001)*100
bar_graph_ave_growth_rate `"GDP growth rate (%) during periods of" "positive or negative labor force growth"' `""' `"N = `num_countries' country years"'
graph export "bar_GDP_growth_pos_neg_labor_growth.png", width(2600) height(1720) replace
graph close

// What were economic growth rates during those five year periods compared to 
// the global (and country income group) average growth?

use "final_derived_labor_growth.dta", clear
keep if NEG_popwork == "Negative"
keep iso3c year income aveP1_rgdp_pwt income_aveP1_rgdp_pwt global_aveP1_rgdp_pwt
naomit
summ iso3c year
local num_countries "`r(N)'"
rename (aveP1_rgdp_pwt income_aveP1_rgdp_pwt global_aveP1_rgdp_pwt) (aveP1_rgdp_pwt ave_income_aveP1_rgdp_pwt ave_global_aveP1_rgdp_pwt)
drop income
reshape long ave, i(iso3c year) j(period, string)
replace period = "1 yr negative" if period == "P1_rgdp_pwt"
replace period = "Global" if period == "_global_aveP1_rgdp_pwt"
replace period = "Income-group" if period == "_income_aveP1_rgdp_pwt"
rename ave ave_growth
collapse (mean) ave_growth, by(period)
replace ave_growth=round(ave_growth, 0.001)*100
bar_graph_ave_growth_rate `"GDP growth rate (%) during periods of" "negative labor force growth" "(vs. global and income-group average)"' `""' `"N = `num_countries' country years"'
graph export "bar_GDP_growth_neg_labor_growth_income_world.png", width(2600) height(1720) replace
graph close

// What happened to government revenues and deficits during those periods 
// compared to prior? ---------------------------------------------------------

tempfile avg_growth
clear
capture log close
set obs 1 
gen ave_growth = 99999999
gen LMIC_var = "NA"
gen war_var = "NA"
gen num_country_years = 99999999
gen var = "NA"
save `avg_growth', replace
clear

foreach LMIC_var in "Excluding" "Including" {
foreach war_var in "Including" "Excluding" {
foreach var in rgdp_pwt fm_gov_exp rev_inc_sc l1avgret flp lp {
	
	use "final_derived_labor_growth.dta", clear
	if ("`war_var'" == "Excluding") {
		drop if missing(est_deaths) & missing(war)
		drop if est_deaths >= 30 | war == 1
	}
	if ("`LMIC_var'" == "Excluding") {
		drop if missing(income)
		drop if income == "LIC" | income == "LMIC"
	}
	
	label variable l1avgret "Stock returns (normalized, inflation adjusted)"
	loc lab: variable label `var'
	keep if NEG_popwork == "Negative"
	drop NEG_popwork
	keep iso3c year aveP1_`var' aveP1_`var'_bef
	naomit
	summ iso3c year
	local num_countries "`r(N)'"
	ds
	local varlist `r(varlist)'
	local excluded iso3c year
	local to_gather: list varlist - excluded
	foreach i in `to_gather' {
		rename `i' ave`i'
	}
	reshape long ave, i(iso3c year) j(period, string)
	replace period = "Negative" if period == "aveP1_`var'"
	replace period = "Positive" if period == "aveP1_`var'_bef"
	rename ave ave_growth
	collapse (mean) ave_growth, by(period)
	replace ave_growth = round(ave_growth, 0.0001) * 100
	
	
	bar_graph_ave_growth_rate `"`lab'" "growth rate (%) during periods of" "negative and positive labor force growth" "(5 year annual average)"' ///
	`"`war_var' War" "`LMIC_var' LICs & LMICs"' ///
	`"N = `num_countries' country years"'
	graph export "bar_`var'_growth_neg_labor_growth_war-`war_var'_lmic-`LMIC_var'.png", width(2600) height(1720) replace
	graph close
	
	// append this to our table:
	gen label = "`lab'"
	gen LMIC_var = "`LMIC_var'"
	gen war_var = "`war_var'"
	gen num_country_years = `num_countries'
	gen var = "`var'"
	
	append using `avg_growth'
	save `avg_growth', replace
}
}
}

use `avg_growth'

drop if var == "NA"
// drop if num_country_years<10
drop var num_country_years 
replace period = "neg" if period == "Negative"
replace period = "pos" if period == "Positive"
foreach i in war_var LMIC_var {
	replace `i' = "exc" if `i' == "Excluding"
	replace `i' = "inc" if `i' == "Including"	
}
replace LMIC_var = "lic_" + LMIC_var + "_war_" + war_var
drop war_var
reshape wide ave_growth, i(period label) j(LMIC_var, string)
rename ave_growth* *

order label period
sort label period 
ssc install texsave
texsave * using "table1", nonames replace frag headerlines("& \multicolumn{4}{c}{LIC/LMIC}{War} \\" "\cmidrule(lr){2-6}"" & 1950s & 1960s & 1970s &1980s") size(3) width(1\textwidth) title ("Literacy, share with at least five years of schooling and school quality") nofix marker(results_region)






























