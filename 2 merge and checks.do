// Merge all together --------------------------------------------------------

clear
input str40 datasets
	"historical_wb_income_classifications.dta"
	"oecd_govt_expend.dta"
	"oecd_tax_revenue.dta"
	"oecd_govt_rev.dta"
	"oecd_govt_deficit.dta"
	"IMF_FM.dta"
	"IMF_GFS_expenses.dta"
	"IMF_GFS_revenue.dta"
	"clean_grd.dta"
	"un_pop_estimates_cleaned.dta"
	"UCDP_geography_deaths.dta"
	"UN_fertility.dta"
	"flp.dta"
	"clean_stock_interest.dta"
end
levelsof datasets, local(datasets)

use "$input/pwt_cleaned.dta", clear

foreach i in `datasets' {
	di "`i'"
	mmerge iso3c year using `i'
	drop _merge
}

check_dup_id "iso3c year"
fillin iso3c year
drop _fillin country

// GDP per capita:
gen rgdppc_pwt = rgdp_pwt / poptotal

// TO DO: is the GRD database / OECD database about CENTRAL gov't or about local / STATE govt's??
label variable caution_GRD "Caution notes from Global Revenue Database data"
label variable gov_deficit_pc_gdp "Government deficit  (% GDP)"
label variable gov_rev_pc_gdp "Total government revenue (% GDP)"
label variable gov_tax_rev_pc_gdp "Total government tax revenue (% GDP)"
label variable income "Historical WB income classificaiton"
label variable iso3c "ISO3c country code"
label variable rgdp_pwt "GDP, PPP (PWT)"

// Baker Bloom Terry
// label variable l1avgret "Stock returns (normalized & CPI inflation adjusted); cumul. return in prior 4 quarters"
// label variable l1lavgvol "Stock volatility; average quarterly standard deviations of daily stock returns over previous four quarters"

// Demographics
label variable poptotal "Total Population"
label variable popwork "Total Working-Age Population"
label variable tfr "Total Fertility Rate"
label variable lp "Total Labor Force Participation (%)"
label variable flp "Female Labor Force Participation (%)"

// UN GRD
label variable rev_inc_sc "Government revenue including Social Contributions (UN GRD)"
label variable tax_inc_sc "Taxes including social contributions (UN GRD)"
label variable tot_res_rev "Government Total Resource Revenue (UN GRD)"

// War
label variable est_deaths "Estimated battle deaths in country (geographical location) from war (UCDP)"
label variable war "Country in war (COW)"
label variable year "Year"

// OECD government expenditure variables
label variable gov_exp_DEF "Gov exp: defence"
label variable gov_exp_ECOAFF "Gov exp: economic affairs"
label variable gov_exp_EDU "Gov exp: education"
label variable gov_exp_ENVPROT "Gov exp: environmental protection"
label variable gov_exp_GRALPUBSER "Gov exp: general public services"
label variable gov_exp_HEALTH "Gov exp: health"
label variable gov_exp_HOUCOMM "Gov exp: housing and community amenities"
label variable gov_exp_PUBORD "Gov exp: public order and safety"
label variable gov_exp_RECULTREL "Gov exp: recreation, culture and religion"
label variable gov_exp_SOCPROT "Gov exp: social protection"
label variable gov_exp_TOT "Gov exp: TOTAL"

// IMF government expenditure variables:
label variable fm_gov_exp "Government expenditures (% of GDP) (IMF Fiscal Monitor)"
label variable fm_gov_rev "Government revenue (% of GDP) (IMF Fiscal Monitor)"
label variable gfs_gov_exp "General budgetary government expense (% of GDP) (IMF GFS)"
label variable gfs_gov_rev "General budgetary government revenue (% of GDP) (IMF GFS)"

// Stock market and interest rate data from GFD
label variable yield_10yr "10 year bond yields"
label variable yield_3mo "3 month bond yields"
label variable cpi "Consumer Price Index"
label variable index_inf_adj "Stock Index, inflation adjusted"

// Checks --------------------------------------------------------------------

// no duplicates
check_dup_id "iso3c year"

// US population should be what I expect it to be
preserve
keep if iso3c == "USA" & year == 2019
assert poptotal < 340*(10^6)
assert poptotal > 320*(10^6)

// US GDP should be around what I expect it to be (if it's in billions):
assert rgdp_pwt > 20*(10^6)
assert rgdp_pwt < 22*(10^6)
restore

// countrycode and iso3c should be the same:
preserve
keep iso3c countrycode
duplicates drop
naomit
check_dup_id "iso3c"
check_dup_id "countrycode"
restore

// Kosovo shouldn't be messed up
assert iso3c != "KSV"

save "$input/final_raw_labor_growth.dta", replace

// Derived variables -------------------------------------------------------

use "$input/final_raw_labor_growth.dta", clear

// Restrict population to 1 year chunks
gen year_mod = mod(year, 1)
keep if year_mod == 0
drop year_mod

// Take a lag of that sum & find the percent change in population.
fillin iso3c year
drop _fillin
foreach i in rgdp_pwt popwork rev_inc_sc fm_gov_exp cpi yield_10yr yield_3mo index_inf_adj flp lp gov_deficit_pc_gdp gov_exp_TOT {
	sort iso3c year
	loc lab: variable label `i'
	foreach num of numlist 1/2 {
		local yr = cond(`num' == 1 , 1, 2)
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
foreach i in rgdp_pwt popwork rev_inc_sc fm_gov_exp cpi yield_10yr yield_3mo index_inf_adj flp lp gov_deficit_pc_gdp gov_exp_TOT {
	sort iso3c year
	loc lab: variable label `i'
	gen NEG_`i' = "Negative" if aveP1_`i' < 0
	replace NEG_`i' = "Positive" if aveP1_`i' >= 0 & aveP1_`i'!=.
	label variable NEG_`i' "Is the average 1yr % change in `lab' negative?"
}

// Tag whether there was a 10 year consistent negative growth.
foreach var in popwork {
	sort iso3c year
	loc lab: variable label `var'
	
	local var popwork
	// create differences
		gen `var'_diff = `var' - `var'[_n-1] if iso3c == iso3c[_n-1]
			
	// create lagged differences
		forval count = 1/10 {
			sort iso3c year
				gen `var'_diff_L`count' = `var'_diff[_n-`count'] if iso3c == iso3c[_n-`count']
				replace `var'_diff_L`count' = 0 if `var'_diff_L`count'>=0 & !missing(`var'_diff_L`count')
				replace `var'_diff_L`count' = 1 if `var'_diff_L`count'<0 & !missing(`var'_diff_L`count')
		}
		
	// get whether there was 2 years of negative first-differences:
		egen NEG10_`var' = rowtotal(`var'_diff_L*)
		replace NEG10_`var' = NEG10_`var'>0
		forval count = 1/10 {
			replace NEG10_`var' = . if missing(`var'_diff_L`count')
		}
	// drop the variables used to create this:
		drop `var'_diff*
	
	label variable NEG10_`var' "Has `lab' declined for 10 consecutive years?"
}

// What were economic growth rates during those 1 year periods with negative
// population growth rates compared to the (last) (ten year?) period before
// labor force growth was negative?
//
// This generates a new variable that is equal to the average 2 year growth
// rate if the average 2 year growth rate was positive. Then,
// it fills downwards this variable and LAGs it. Next, we want this variable
// (the average 2 year growth rate) ONLY if the average 1 year growth rate
// within the past 1 years was negative. So, finally, it replaces the
// average lag 2 year growth rate by a missing value if the average 1 year
// growth rate is positive or absent (not negative).
foreach i in rgdp_pwt rev_inc_sc fm_gov_exp cpi yield_10yr yield_3mo index_inf_adj flp lp gov_deficit_pc_gdp gov_exp_TOT {
	sort iso3c year
	loc lab: variable label `i'
	foreach num of numlist 1/2 {
		local yr = cond(`num' == 1 , 1, 2)
		gen aveP`num'_`i'_bef = aveP`num'_`i' if aveP`num'_popwork >= 0
		sort iso3c year
		by iso3c: fillmissing aveP`num'_`i'_bef, with(previous)
		gen aveP`num'_`i'_bef2 = aveP`num'_`i'_bef[_n-1] if iso3c == iso3c[_n-1]
		drop aveP`num'_`i'_bef
		rename aveP`num'_`i'_bef2 aveP`num'_`i'_bef
		replace aveP`num'_`i'_bef = . if NEG_popwork != "Negative"
		label variable aveP`num'_`i'_bef "Avg ann gr, `lab', `yr'yr priod b/f neg labor gr"
	}
}

// What were economic growth rates during those 1 year periods compared to 
// the global (and country income group) average growth?
bysort income year: egen income_aveP1_rgdp_pwt=mean(aveP1_rgdp_pwt)
bysort        year: egen global_aveP1_rgdp_pwt=mean(aveP1_rgdp_pwt)

// We only have population data after 1950, so ignore before.
keep if year >= 1950
save "$input/final_derived_labor_growth.dta", replace

// To do ----------------------------------------------------------------
// create the dataset BEFORE you start whittling it down for the graphs (do the
// lag vars for unemployment, govt rev, etc. as well)

// perhaps we want to include some of the shocks in the baker bloom paper? add
// **checks** at the end take a look at the labor - growth relationship in the
// literature?

// one concern about the use of fertility as an IV for number of workers 20-65
// is that it doesn't include immigrants *into* a country
// --------------------
// what does the literature say about growth regressions of this sort?

// --------------------
// --------------------
// And adding a bit more:
//
// I’m interested in looking at the impact of negative labor force growth on
// economies.  Pretty simple stuff at least to begin:
//
// Using the UN population data, find all 1 year periods where countries have
// experienced an absolute decline in their population aged 20-64. (A brief look
// suggests there are 203 historical cases at the country level).
//
// When did they happen (just a histogram by 1 year period)? How large the
// percentage drop in workers (*median* size by 1 year period)
//
// *median* size by 1 year period --> what do you mean here? get the median
// percent worker drop?
//
// What were economic growth rates during those 1 year periods compared to the
// (last) (ten year?) period before labor force growth was negative?
//
// What were economic growth rates during those 1 year periods compared to the
// global (and country income group) average growth?
// ---------------------------------------------
//
// What happened to government revenues and deficits during those periods
// compared to prior?
//
// What happened to interest rates and stock market returns?
//
// What happened to the unemployment rate total labor force participation and
// female labor force participation?
//
// Take out cases which overlap with a country being at war
// (https://correlatesofwar.org/data-sets) and then take out low and lower
// middle income countries and see if that makes a difference.
//
// Look forward: according to the UN population forecasts, how many countries in
// each forthcoming 1 year period will see declining working age population? How
// large the percentage drop in workers (*median* size by 1 year period)
//
// “instrument’ or just use the predicted change in working age population from
// ten years prior (e.g. us value for population aged 10-54 in 1980 as the value
// for population aged 20-64 in 1990) and/or try 20 year lag.
