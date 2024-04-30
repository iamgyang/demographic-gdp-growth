// Analysis -------------------


// Create a histogram with x axis being the 1 year period
use "$input/final_derived_labor_growth.dta", clear

drop if year >= 2020 | year <= 1950
histogram year if !missing(NEG_popwork), percent ytitle(Percent) by(NEG_popwork) discrete
graph export "$output/hist_negative_pop_years_1yr_periods1.png", width(2600) height(1720) replace
histogram year if !missing(NEG_popwork), frequency ytitle(Frequency) by(NEG_popwork) discrete
graph close

use "$input/final_derived_labor_growth.dta", clear
keep NEG_popwork year iso3c
drop if missing(NEG_popwork)
gen neg = (NEG_popwork == "Negative")
gen pos = 1 - neg
drop NEG_popwork 
*br if year == 1995 & neg == 1
gcollapse (sum) neg pos, by(year)

graph bar (asis) neg pos, over(year, label(angle(45) labsize(1.6))) stack
graph export "$output/hist_negative_pop_years_1yr_periods2.png", width(2600) height(1720) replace

// Median size of pop growth decline:

use "$input/final_derived_labor_growth.dta", clear
keep if NEG_rgdp_pwt == "Negative"
tabstat aveP1_rgdp_pwt, statistics(median) save
ret list
mat B = r(StatTotal)

// This is the median average annual negative growth rate across 1 yr period
// (countries can have duplicate 1 year periods).
capture log close
set logtype text
log using "$output/log_results_labor_growth.txt", replace
display c(current_time)

di "median average annual negative growth rate across 1 yr period: " B[1,1]

display c(current_time)
log close

// Compare 5-yr period of growth NEGATIVE growth rates to the PREVIOUS 10-yr
// growth rates (annualized). Create a bar graph that has the average GDP
// growth rate during a period of 5-years of labor force decline compared to
// the most recent 10-years where the average labor force did not decline.

quietly capture program drop bar_graph_ave_growth_rate
program bar_graph_ave_growth_rate
args title subtitle caption
#delimit ;
		graph bar (asis) ave_growth,
		over(period)
		bar(1, fcolor(cgd_teal) fintensity(inten100) lcolor(none))
		blabel(bar)
		ytitle("")
		//yscale(noline)
		//yline(0, lcolor(none))
		ylabel(, labels labsize(small) labcolor(black) ticks tlcolor(black) nogrid)
		ymtick(, nolabels noticks nogrid)
		title("`title'")
		subtitle("`subtitle'", position(11) size(small))
		caption("`caption'", size(small) position(5) fcolor(none) lcolor(none))
		scheme(s1color)
		//graphregion(fcolor(none) ifcolor(none)) // This doesn't seem to do anything?
		plotregion(style(none)) //fcolor(none) ifcolor(none))
		;
#delimit cr
end

use "$input/final_derived_labor_growth.dta", clear
keep if NEG_popwork == "Negative"
keep iso3c year aveP2_rgdp_pwt_bef aveP1_rgdp_pwt
naomit
summ iso3c year
local num_countries "`r(N)'"
reshape long ave, i(iso3c year) j(period, string)
rename ave ave_growth
replace period = "1 yr negative" if period == "P1_rgdp_pwt"
replace period = "2 yr positive" if period == "P2_rgdp_pwt_bef"
gcollapse (mean) ave_growth, by(period)
replace ave_growth = round(ave_growth, 0.0001) * 100

bar_graph_ave_growth_rate `"GDP growth rate (%) during periods of" "positive or negative labor force growth"' `""' `"N = `num_countries' country years"'
graph export "$output/bar_GDP_growth_pos_neg_labor_growth.png", width(2600) height(1720) replace
graph close

// What were economic growth rates during those five year periods compared to 
// the global (and country income group) average growth?

use "$input/final_derived_labor_growth.dta", clear
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
gcollapse (mean) ave_growth, by(period)
replace ave_growth=round(ave_growth, 0.001)*100
bar_graph_ave_growth_rate `"GDP growth rate (%) during periods of" "negative labor force growth" "(vs. global and income-group average)"' `""' `"N = `num_countries' country years"'
graph export "$output/bar_GDP_growth_neg_labor_growth_income_world.png", width(2600) height(1720) replace
graph close
