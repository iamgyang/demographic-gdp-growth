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

// set macro: whether we're testing or now
global test_run 0

// set a dataset that will "contain" the end results (number of 
// countries, average growth, etc.)
tempfile avg_growth
clear
capture log close
set obs 1 
gen ave_growth = 99999999
gen LMIC_var = "NA"
gen war_var = "NA"
gen num_country_years = 99999999
gen var = "NA"
gen within_country_var = "NA"
save `avg_growth', replace
clear

if ($test_run == 1) {
	pause on
}
else if ($test_run == 0) {
	pause off
}

foreach within_country_var in "Within" "Between" {
foreach LMIC_var in "Excluding" "Including" {
foreach war_var in "Including" "Excluding" {
foreach var in rgdp_pwt fm_gov_exp rev_inc_sc l1avgret flp lp {
if ($test_run == 1) {
	local war_var "Including"
	local LMIC_var "Including"
	local var l1avgret
	local within_country_var "Between"	
}
	use "final_derived_labor_growth.dta", clear
	if ("`war_var'" == "Excluding") {
		drop if missing(est_deaths) & missing(war)
		drop if est_deaths >= 100 | war == 1
	}
	if ("`LMIC_var'" == "Excluding") {
		drop if missing(income)
		drop if income == "LIC" | income == "LMIC"
	}
	label variable l1avgret "Stock returns (normalized, inflation adjusted)"
	loc lab: variable label `var'
	if ("`within_country_var'" == "Within") {
		keep if NEG_popwork == "Negative"
		
		keep iso3c year aveP1_`var' aveP1_`var'_bef
		naomit
		summ iso3c year
		pause 1
		local num_countries "`r(N)'"
		ds
		local varlist `r(varlist)'
		local excluded iso3c year
		local to_gather: list varlist - excluded
		foreach i in `to_gather' {
			rename `i' ave`i'
		}
		reshape long ave, i(iso3c year) j(period, string)
		pause 2
		replace period = "Negative" if period == "aveP1_`var'"
		replace period = "Positive" if period == "aveP1_`var'_bef"
		rename ave ave_growth
	}
	else if ("`within_country_var'" == "Between") {
		keep iso3c year aveP1_`var' NEG_popwork
		naomit
		rename (aveP1_`var' NEG_popwork) (ave_growth period)
		pause 1
		summ iso3c year
		local num_countries "`r(N)'"
	}
	
	collapse (mean) ave_growth, by(period)
	replace ave_growth = round(ave_growth, 0.0001) * 100
	
	bar_graph_ave_growth_rate `"`lab'" "growth rate (%) during periods of" "negative and positive labor force growth" "(1 year annual average)" "`within_country_var' countries"' ///
	`"`war_var' War" "`LMIC_var' LICs & LMICs"' ///
	`"N = `num_countries' country years"'
	graph export "bar_`var'_growth_neg_labor_growth_war-`war_var'_lmic-`LMIC_var'_within-`within_country_var'.png", width(2600) height(1720) replace
	graph close
	
	// append this to our table:
	gen label = "`lab'"
	gen LMIC_var = "`LMIC_var'"
	gen war_var = "`war_var'"
	gen num_country_years = `num_countries'
	gen var = "`var'"
	gen within_country_var = "`within_country_var'"
	
	append using `avg_growth'
	save `avg_growth', replace
}
}
}
}

use `avg_growth'

save "raw_table_avg_growth.dta", replace

// Output to LATEX -------------------------------------------------------------

// much of the rest of this is aesthetics RE: LATEX

use "raw_table_avg_growth.dta", clear

drop if var == "NA"
drop if num_country_years<10
drop var num_country_years 
replace period = "neg" if period == "Negative"
replace period = "pos" if period == "Positive"
replace within_country_var = "bet" if within_country_var == "Between"
replace within_country_var = "with" if within_country_var == "Within"
foreach i in war_var LMIC_var {
	replace `i' = "exc" if `i' == "Excluding"
	replace `i' = "inc" if `i' == "Including"	
}

// this allows us to reshape the variable later
replace LMIC_var = "l_" + LMIC_var + "_w_" + war_var + "_c_" + within_country_var
drop war_var within_country_var
reshape wide ave_growth, i(period label) j(LMIC_var, string)
rename ave_growth* *

order label period
sort label period 

replace period = "+" if period == "pos"
replace period = "-" if period == "neg"

// being foxy with LATEX: replace percent signs, anything in parenthesis,
// the words "LFP". make sure that every other row is blank, since we have 
// 2 observations per variable:
sort label
gen count = 1
bysort label: egen count2 = sum(count)
assert count2 == 2
drop count*
gen n = mod(_n, 2)
replace label = subinstr(label, "Government", "Gov't",.)
replace label = subinstr(label, " including Social Contributions", "",.)
replace label = subinstr(label, "Labor Force Participation", "LFP",.)

// remove all things in parentheses
replace label = trim(regexr(label , "\((.)+\)", ""))

// merge rows when applicable
replace label = "\multirow{2}[0]{3cm}{" + label + "}"
replace label = "" if n == 0
br

replace n = _n
egen last_row = max(n)
replace last_row = last_row - 1

// the top and bottom variables should be slightly different
replace label = subinstr(label, "\multirow{2}[0]", "\multirow{2}[1]",.) ///
	if n == last_row | n == 1

// draws a horizontal line in between each variable category
replace label = "\midrule\\" + label if n != 1 & mod(n, 2) != 0
replace label = subinstr(label, "%", "\%",.)

drop n last_row

order label period l_exc_w_exc_c_bet l_exc_w_exc_c_with l_exc_w_inc_c_bet l_exc_w_inc_c_with l_inc_w_exc_c_bet l_inc_w_exc_c_with l_inc_w_inc_c_bet l_inc_w_inc_c_with

// output to latex:
#delimit ;
texsave * using "table1.txt", 
nonames replace frag 
headerlines(
"& \multicolumn{1}{r}{} & \multicolumn{4}{c}{LIC/LMIC excluded} & \multicolumn{4}{c}{LIC/LMIC included} \\ \cmidrule{3-10}          & \multicolumn{1}{r}{} & \multicolumn{2}{c}{War Excluded} & \multicolumn{2}{c}{War Included} & \multicolumn{2}{c}{War Excluded} & \multicolumn{2}{c}{War Included} \\ \cmidrule{3-10}    \multicolumn{1}{c}{Variable} & \multicolumn{1}{c}{Labor Force}  & \multicolumn{1}{c}{Between} & \multicolumn{1}{c}{Within} & \multicolumn{1}{c}{Between} & \multicolumn{1}{c}{Within} & \multicolumn{1}{c}{Between} & \multicolumn{1}{c}{Within} & \multicolumn{1}{c}{Between} & \multicolumn{1}{c}{Within} \\"
) 
size(3) width(1\textwidth)
title ("Growth (\%) during periods of working age population decline" "vs. periods of working age population growth") 
nofix 
marker(results_region) 
footnote("\textit{Between} compares years with negative and positive working-age population growth across every country. \textit{Within} compares years with negative and positive working-age population growth within the same country. \textit{Within} uses the earliest prior period of positive working-age population growth. ILO estimates are non-modeled national reports. Wars were excluded based on whether there were more than 10,000 battle-related deaths in that geography as reported by Uppsala University UCDP data. Stock returns are normalized and inflation adjusted. Government revenue includes social contributions.")
;
#delimit cr

// adjust the TXT output file:
// adjustments to the base latex file:
import delimited "table1.txt", clear
// replace v1 = subinstr(v1, "\end{tabularx}","\end{tabularx}\end{adjustbox}",1) 
replace v1 = subinstr(v1, "\begin{tabularx}{1\textwidth}{lCCCCCCCCC}", "\begin{tabularx}{1\textwidth}{p{3cm} c X X X X X X X X }",1) 
// replace v1 = subinstr(v1, "\begin{tabularx}","\begin{adjustbox}{angle=90}\begin{tabularx}",1)

// replace that output file once more:
outfile using "table1.txt", noquote replace wide
























