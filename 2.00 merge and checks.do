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

foreach dtafile in `datasets' {
	di "`dtafile'"
	mmerge iso3c year using "$input/`dtafile'"
	drop _merge
}

isid iso3c year
fillin iso3c year  // I'll assume this is necessary for something later, but if not it doesn't make much sense to do--dataset goes from 11mb to 73mb.
drop _fillin // country  // I'm going to leave country as the full names are sometimes useful. 

// GDP per capita:
gen rgdppc_pwt = rgdp_pwt / poptotal
label variable rgdppc_pwt "GDP per capita"

// Generate CPI and Stock Index *growth rates* instead of raw values, for summary table
/* Ideal is to xtset and use time series operators, but I don't want to risk breaking later code:
encode(iso3c), generate(country_code)
xtset country_code year, yearly */
bys iso3c (year): 	gen cpi_growth ///
						= 100 * ((cpi / cpi[_n - 1]) - 1) 						if (_n != 1) & (!missing(cpi)) & (year[_n] == (year[_n-1] + 1))
bys iso3c (year): 	gen stock_index_growth ///
						= 100 * ((index_inf_adj / index_inf_adj[_n - 1]) - 1) 	if (_n != 1) & (!missing(index_inf_adj)) & (year[_n] == (year[_n-1] + 1))
					
label variable cpi_growth  "Consumer Price Index YoY Growth Rate (%)" 
label variable stock_index_growth "Stock Price Index YoY Growth Rate (%)"

// TO DO: is the GRD database / OECD database about CENTRAL gov't or about local / STATE govt's??
label variable caution_GRD "Caution notes from Global Revenue Database data"
label variable gov_deficit_pc_gdp "Govt deficit  (% GDP)"
label variable gov_rev_pc_gdp "Total govt revenue (% GDP)"
label variable gov_tax_rev_pc_gdp "Total govt tax revenue (% GDP)"
label variable income "Historical WB income classificaiton"
label variable iso3c "ISO3c country code"
label variable rgdp_pwt "GDP"

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
label variable rev_inc_sc "Govt revenue, incl. Social Contributions (% GDP) (UN GRD)"
label variable tax_inc_sc "Taxes including social contributions (UN GRD)"
label variable tot_res_rev "Govt Total Resource Revenue (UN GRD)"

// // War
label variable est_deaths "Estimated battle deaths in country (geographical location) from war (UCDP)"
// label variable war "Country in war (COW)"
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
label variable fm_gov_exp "Govt expenditures (% of GDP) (IMF Fiscal Monitor)"
label variable fm_gov_rev "Govt revenue (% of GDP) (IMF Fiscal Monitor)"
label variable gfs_gov_exp "General budgetary govt expense (% of GDP) (IMF GFS)"
label variable gfs_gov_rev "General budgetary govt revenue (% of GDP) (IMF GFS)"

// Stock market and interest rate data from GFD
label variable yield_10yr "10 year bond yields"
label variable yield_3mo "3 month bond yields"
label variable cpi "Consumer Price Index"
label variable index_inf_adj "Stock Index, inflation adjusted"

// Checks --------------------------------------------------------------------

// no duplicates
isid iso3c year

// US population should be what I expect it to be
*preserve
*keep if iso3c == "USA" & year == 2019
assert poptotal < 340*(10^6) 	if iso3c == "USA" & year == 2019
assert poptotal > 320*(10^6) 	if iso3c == "USA" & year == 2019

// US GDP should be around what I expect it to be (if it's in millions):
assert rgdp_pwt > 20*(10^6) 	if iso3c == "USA" & year == 2019
assert rgdp_pwt < 22*(10^6) 	if iso3c == "USA" & year == 2019
*restore

// countrycode and iso3c should be the same:
preserve
	keep iso3c countrycode
	duplicates drop
	drop if missing(iso3c) | missing(countrycode)
	isid iso3c
	isid countrycode
restore

// Kosovo shouldn't be messed up
assert iso3c != "KSV"

// Drop cpi_growth outliers, if desired
if ($DROP_CPI_OUTLIERS == 1) {
	drop if (cpi_growth > 100) & !missing(cpi_growth)
}

// We only have population data after 1950, so ignore before.
keep if year >= 1950

save "$input/final_raw_labor_growth.dta", replace


// Derived variables -------------------------------------------------------

use "$input/final_raw_labor_growth.dta", clear

// Restrict population to 1 year chunks
keep if mod(year, 1) == 0   // Note ZG: I'm not sure in what scenario there would be years with decimals, maybe deprecated?

/* Going to xtset, as manual lag/difference creation is in the next chunk
But will commit a version before putting it in in case it breaks stuff.
encode(iso3c), generate(country_code)
xtset country_code year
local t = 1
gen test1 = L`t'.year */

// making % changes in variables
fillin iso3c year
drop _fillin
foreach var in rgdp_pwt rgdppc_pwt popwork rev_inc_sc fm_gov_exp cpi yield_10yr yield_3mo index_inf_adj flp lp gov_deficit_pc_gdp gov_exp_TOT {
	sort iso3c year
	loc lab: variable label `var'
	foreach num of numlist 1/2 {
		local yr = cond(`num' == 1 , 1, 2)   // This is identical to yr = `num'--maybe before it wasn't?
		// lag variable
			gen L`num'_`var' = `var'[_n-`num'] if iso3c == iso3c[_n-`num']
			label variable L`num'_`var' "Lag `yr'yr `lab'"
		// percent change in variable by X-yr periods
			gen P`num'_`var' = (`var' / L`num'_`var') - 1
			label variable P`num'_`var' "`yr'yr % Change in `lab'"
		// average percent change in variable by X-yr periods
			gen aveP`num'_`var' = (`var' / L`num'_`var')^(1/`yr') - 1
			label variable aveP`num'_`var' "Average Annual `yr'yr Change in `lab' (geometric mean)"
		// average DIFFERENCE in variable by X-yr periods
			gen aveD`num'_`var' = (`var' - L`num'_`var') / `yr'
			label variable aveD`num'_`var' "Average Annual `yr'yr Change in `lab'"
	}
}

// Tag whether the average percent change in real GDP growth is negative.
foreach var in rgdp_pwt popwork rev_inc_sc fm_gov_exp cpi yield_10yr yield_3mo index_inf_adj flp lp gov_deficit_pc_gdp gov_exp_TOT {
	sort iso3c year
	loc lab: variable label `var'
	gen NEG_`var' = "Negative" if aveP1_`var' < 0
	replace NEG_`var' = "Positive" if aveP1_`var' >= 0 & aveP1_`var'!=.
	label variable NEG_`var' "Is the average 1yr % change in `lab' negative?"
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
foreach var in rgdp_pwt rgdppc_pwt rev_inc_sc fm_gov_exp cpi yield_10yr yield_3mo index_inf_adj flp lp gov_deficit_pc_gdp gov_exp_TOT {
	sort iso3c year
	loc lab: variable label `var'
	foreach num of numlist 1/2 {
		local yr = cond(`num' == 1 , 1, 2)
		gen aveP`num'_`var'_bef = aveP`num'_`var' if aveP`num'_popwork >= 0
		sort iso3c year
		by iso3c: fillmissing aveP`num'_`var'_bef, with(previous)
		gen aveP`num'_`var'_bef2 = aveP`num'_`var'_bef[_n-1] if iso3c == iso3c[_n-1]
		drop aveP`num'_`var'_bef
		rename aveP`num'_`var'_bef2 aveP`num'_`var'_bef
		replace aveP`num'_`var'_bef = . if NEG_popwork != "Negative"
		label variable aveP`num'_`var'_bef "Avg ann % gr, `lab', `yr'yr priod b/f neg labor gr"
	}
	// do the same for the differences:
	foreach num of numlist 1/2 {
		local yr = cond(`num' == 1 , 1, 2)
		gen aveD`num'_`var'_bef = aveD`num'_`var' if aveD`num'_popwork >= 0
		sort iso3c year
		by iso3c: fillmissing aveD`num'_`var'_bef, with(previous)
		gen aveD`num'_`var'_bef2 = aveD`num'_`var'_bef[_n-1] if iso3c == iso3c[_n-1]
		drop aveD`num'_`var'_bef
		rename aveD`num'_`var'_bef2 aveD`num'_`var'_bef
		replace aveD`num'_`var'_bef = . if NEG_popwork != "Negative"
		label variable aveD`num'_`var'_bef "Avg ann gr, `lab', `yr'yr priod b/f neg labor gr"
	}
}



// What were economic growth rates during those 1 year periods compared to 
// the global (and country income group) average growth?
bysort income year: egen income_aveP1_rgdp_pwt = mean(aveP1_rgdp_pwt)
bysort        year: egen global_aveP1_rgdp_pwt = mean(aveP1_rgdp_pwt)

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
