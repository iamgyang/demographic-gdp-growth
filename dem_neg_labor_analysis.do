// Analysis -------------------
use "final_labor_growth.dta", clear

// Restrict population to 5 year chunks
gen year_mod = mod(year, 5)
keep if year_mod == 0
drop year_mod

// Take a lag of that sum & find the percent change in population.
fillin iso3c year
sort iso3c year
drop _f
foreach i in rgdp_pwt poptotal rev_inc_sc gov_deficit_pc_gdp gov_exp_TOT {
	loc lab: variable label `i'
	foreach num of numlist 1/2 {
		local yr = cond(`num' == 1 , 5, 10)
		// lag population and real GDP
			gen L`num'_`i' = `i'[_n-`num'] if iso3c == iso3c[_n-`num']
			label variable L`num'_`i' "Lag `yr'yr `lab'"
		// percent change in population & real GDP by 5-yr and 10-yr periods
			gen P`num'_`i' = (`i' / L`num'_`i') - 1
			label variable P`num'_`i' "`yr'yr % Change in `lab'"
		// average percent change in population & real GDP by 5-yr and 10-yr periods
			gen aveP`num'_`i' = (`i' / L`num'_`i')^(1/`yr') - 1
			label variable aveP`num'_`i' "Average Annual `yr'yr % Change in `lab'"
	}
}

// Tag whether the average percent change in real GDP growth is negative.
foreach i in rgdp_pwt poptotal rev_inc_sc gov_deficit_pc_gdp gov_exp_TOT {
	loc lab: variable label `i'
	gen NEG_`i' = "Negative" if aveP1_`i' < 0
	replace NEG_`i' = "Positive" if aveP1_`i' >= 0 & aveP1_`i'!=.
	label variable NEG_`i' "Is the average 5yr % change in `lab' negative?"
}

// Create a histogram with x axis being the 5 year period
drop if year >= 2020 | year <= 1950
histogram year, bin(20) percent ytitle(Percent) by(NEG_rgdp_pwt)
graph export "hist_negative_pop_years_5yr_periods.png", replace
graph close

// What were economic growth rates during those five year periods with negative
// population growth rates compared to the (last) (ten year?) period before
// labor force growth was negative?
//
// This generates a new variable that is equal to the average 10-year growth
// rate if the average 10-year growth rate was positive. Then,
// it fills downwards this variable and LAGs it. Next, we want this variable
// (the average 10-year growth rate) ONLY if the average five year growth rate
// within the past five years was negative. So, finally, it replaces the
// average lag 10-year growth rate by a missing value if the average five-year
// growth rate is positive or absent (not negative).
foreach i in rgdp_pwt rev_inc_sc gov_deficit_pc_gdp gov_exp_TOT {
	gen aveP2_`i'_bef = aveP2_`i' if aveP2_poptotal >= 0
	sort iso3c year
	by iso3c: fillmissing aveP2_`i'_bef, with(previous)
	gen aveP2_`i'_bef2 = aveP2_`i'_bef[_n-1] if iso3c == iso3c[_n-1]
	drop aveP2_`i'_bef
	rename aveP2_`i'_bef2 aveP2_`i'_bef
	replace aveP2_`i'_bef = . if NEG_poptotal != "Negative"
}

// Median size of pop growth decline:
preserve
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
restore

// Compare 5-yr period of growth NEGATIVE growth rates to the PREVIOUS 10-yr
// growth rates (annualized). Create a bar graph that has the average GDP growth
// rate during a period of 5-years of labor force decline compared to the
// most recent 10-years where the average labor force did not decline.
quietly capture program drop bar_graph_ave_gdp_growth_rate
program bar_graph_ave_gdp_growth_rate
args title
#delimit ;
		graph bar (asis) ave_gdp_growth, over(period) blabel(bar, size
		(medium) color(black)) ytitle(GDP Growth Rate) 
		ytitle(, size(medium)) title("`title'", size(medlarge)) 
		scheme(s2color) graphregion(margin(medium) fcolor(white) 
		ifcolor(white) ilcolor(none)) plotregion(margin(medium) fcolor(white) 
		lcolor(none) ifcolor(white) ilcolor(none))
		;
#delimit cr
end

preserve
	keep if NEG_poptotal == "Negative"
	keep iso3c year aveP2_rgdp_pwt_bef aveP1_rgdp_pwt
	naomit
	reshape long ave, i(iso3c year) j(period, string)
	rename ave ave_gdp_growth
	replace period = "5 yr negative" if period == "P1_rgdp_pwt"
	replace period = "10 yr positive" if period == "P2_rgdp_pwt_bef"
	collapse (mean) ave_gdp_growth, by(period)
	replace ave_gdp_growth=round(ave_gdp_growth, 0.001)
	bar_graph_ave_gdp_growth_rate `"GDP growth rate during periods of" "positive or negative labor force growth"'
	graph export "bar_GDP_growth_pos_neg_labor_growth.png", replace
	graph close
restore

// What were economic growth rates during those five year periods compared to 
// the global (and country income group) average growth?
bysort income year: egen income_aveP1_rgdp_pwt=mean(aveP1_rgdp_pwt)
bysort        year: egen global_aveP1_rgdp_pwt=mean(aveP1_rgdp_pwt)
preserve
	keep if NEG_poptotal == "Negative"
	keep iso3c year income aveP1_rgdp_pwt income_aveP1_rgdp_pwt global_aveP1_rgdp_pwt
	naomit
	rename (aveP1_rgdp_pwt income_aveP1_rgdp_pwt global_aveP1_rgdp_pwt) (aveP1_rgdp_pwt ave_income_aveP1_rgdp_pwt ave_global_aveP1_rgdp_pwt)
	drop income
	reshape long ave, i(iso3c year) j(period, string)
	replace period = "5 yr negative" if period == "P1_rgdp_pwt"
	replace period = "Global" if period == "_global_aveP1_rgdp_pwt"
	replace period = "Income-group" if period == "_income_aveP1_rgdp_pwt"
	rename ave ave_gdp_growth
	collapse (mean) ave_gdp_growth, by(period)
	replace ave_gdp_growth=round(ave_gdp_growth, 0.001)
	bar_graph_ave_gdp_growth_rate `"GDP growth rate during periods of" "negative labor force growth" "(vs. global and income-group average)"'
	graph export "bar_GDP_growth_neg_labor_growth_income_world.png", replace
	graph close
restore


//TODO :: replace INCOME with historical income

// What happened to government revenues and deficits during those periods 
// compared to prior?


















