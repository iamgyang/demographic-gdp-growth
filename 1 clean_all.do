**********************************************************************
// UN population estimates -------------------------------------------
**********************************************************************
import delimited "$input/un_WPP2019_PopulationByAgeSex_Medium.csv", clear
keep if variant == "Medium"
keep location time agegrp agegrpstart agegrpspan poptotal

replace poptotal = poptotal * 1000   // Convert from thousands
rename (location time) (country year)

preserve
	keep if agegrpstart < 65 & agegrpstart >= 15
	gcollapse (sum) poptotal, by(country year)
	rename poptotal popwork
	isid country year
	tempfile un_working_pop
	save `un_working_pop'
restore

gcollapse (sum) poptotal, by(country year)

mmerge country year using `un_working_pop', type(1:1)
isid country year
assert _merge == 3
drop _merge

// convert country names to ISO3c codes
conv_ccode "country"

// UN-specific convert code
conv_ccode_un "country"

if ("$check" == "yes") {
	pause on
	preserve
	keep country iso3c
	duplicates drop
	br
	pause "does everything look okay?"
	restore
	pause off
}

// drop country

sort iso3c year
save "$input/un_pop_estimates_cleaned.dta", replace

**********************************************************************
// PWT GDP (growth rates) -----------------------------------------------------
**********************************************************************

use "$input/pwt100.dta", clear

keep rgdpna countrycode year
drop if missing(rgdpna)
rename (rgdpna countrycode) (rgdp_pwt iso3c)

sort iso3c year
save "$input/pwt_cleaned.dta", replace

// use WB real GDP PPP growth rates to expand PWT GDP to 2020 -------------------

// get WDI data (GDP PPP)
wbopendata, language(en – English) indicator(NY.GDP.MKTP.PP.KD) long clear
keep countrycode year ny_gdp_mktp_pp_kd
drop if ny_gdp_mktp_pp_kd ==.
rename (countrycode ny_gdp_mktp_pp_kd) (iso3c rgdp_wdi)
sort iso3c year

// get WDI growth rate
bys iso3c: gen rgdp_wdi_gr = rgdp_wdi / rgdp_wdi[_n-1]
save "$input/wdi_gdp_cleaned.dta", replace

// merge with PWT
use "$input/pwt_cleaned.dta", clear
mmerge iso3c year using "$input/wdi_gdp_cleaned.dta"
sort iso3c year
gen temp_check_var = 1 if missing(rgdp_pwt)

// extrapolate based on WDI
bys iso3c (year): replace rgdp_pwt = rgdp_pwt[_n - 1] * rgdp_wdi_gr 	if missing(rgdp_pwt) & iso3c == iso3c[_n - 1]

// checks:
sort iso3c year
assert rgdp_wdi/rgdp_wdi[_n-1] == rgdp_wdi_gr if iso3c == iso3c[_n-1]
sort iso3c year
assert abs(rgdp_wdi/rgdp_wdi[_n-1] - rgdp_pwt/rgdp_pwt[_n-1])<0.0001 if year == 2020 & temp_check_var == 1 & !mi(rgdp_pwt)

save "$input/pwt_cleaned.dta", replace


// Gov't revenue and deficit levels -----------------------------------------
// https://stats.oecd.org/Index.aspx?DataSetCode=RS_AFR

quietly capture program drop clean_oecd
program clean_oecd
	args indicator_ measure_ tempfilename_ variable_
	keep if indicator == "`indicator_'"
	keep if measure == "`measure_'"
	keep location time value
	rename (location time value) (iso3c year `variable_')
	save "`tempfilename_'", replace
	end

// revenue
import delimited "$input/oecd_DP_LIVE_11082021203447392.csv", encoding(UTF-8) clear 
clean_oecd GGREV PC_GDP "$input/oecd_govt_rev.dta" gov_rev_pc_gdp
check_dup_id "iso3c year"

// deficit
import delimited "$input/oecd_DP_LIVE_11082021203534767.csv", encoding(UTF-8) clear 
clean_oecd GGNLEND PC_GDP "$input/oecd_govt_deficit.dta" gov_deficit_pc_gdp
check_dup_id "iso3c year"

// expenditrure
import delimited "$input/oecd_DP_LIVE_11082021203550955.csv", encoding(UTF-8) clear 
keep if indicator == "GGEXP"
keep if measure == "PC_GDP"
keep location time value subject
reshape wide value, i(location time) j(subject) string
rename value* gov_exp_*
rename (location time) (iso3c year)
check_dup_id "iso3c year"
save "$input/oecd_govt_expend.dta", replace

// tax revenue
import delimited "$input/oecd_RS_GBL_11082021204025971.csv", encoding(UTF-8) clear 
keep if indicator == "Tax revenue as % of GDP"
keep if levelofgovernment == "Total"
keep if taxrevenue == "Total tax revenue"
keep cou year value
rename (cou value) (iso3c gov_tax_rev_pc_gdp)
check_dup_id "iso3c year"
drop if inlist(iso3c, "419", "AFRIC", "OAVG")

sort iso3c year
save "$input/oecd_tax_revenue.dta", replace

// Govt revenues ------------------------------------------------------------

use "$input/government_revenue_dataset/grd_Merged.dta", clear
egen caution_GRD = rowtotal(caution1accuracyqualityorco caution2resourcerevenuestax caution3unexcludedresourcere caution4inconsistencieswiths)
keep iso country year caution_GRD rev_inc_sc tot_res_rev tax_inc_sc
rename iso iso3c
replace iso3c = "XKX" if country == "Kosovo"
replace iso3c = "PSE" if country == "West Bank and Gaza"

// make sure iso3c codes are the same:
preserve
keep iso3c country
rename iso3c iso3c_2
duplicates drop
conv_ccode "country"
naomit
assert iso3c == iso3c_2
restore

sort iso3c year
save "$input/clean_grd.dta", replace

// Govt deficits ------------------------------------------------------------

// From IMF fiscal monitor (FM) ---------------------------------------------
import delimited "$input/IMF_fiscal_monitor.csv", clear
keep countryname countrycode timeperiod expenditureofgdpg_x_g01_gdp_pt revenueofgdpggr_g01_gdp_pt
rename countryname country
conv_ccode country
replace iso3c = "HKG" if country =="China, P.R.: Hong Kong"
replace iso3c = "CHN" if country =="China, P.R.: Mainland"
replace iso3c = "YEM" if country =="Yemen, Republic of"
replace iso3c = "VEN" if country =="Venezuela, Republica Bolivariana de"
replace iso3c = "AZE" if country =="Azerbaijan, Republic of"
replace iso3c = "CPV" if country =="Cabo Verde"
replace iso3c = "MKD" if country =="North Macedonia"
replace iso3c = "BHR" if country =="Bahrain, Kingdom of"
replace iso3c = "ARM" if country =="Armenia, Republic of"
replace iso3c = "TLS" if country =="Timor-Leste, Dem. Rep. of"
replace iso3c = "STP" if country =="SÃ£o TomÃ© and PrÃ­ncipe"
replace iso3c = "XKX" if country =="Kosovo"
replace iso3c = "MAC" if country =="Macao SAR"
replace iso3c = "SWZ" if country =="Eswatini"
drop if iso3c == ""
rename timeperiod year
check_dup_id "iso3c countrycode year"
check_dup_id "iso3c year"
check_dup_id "countrycode year"
rename (expenditureofgdpg_x_g01_gdp_pt revenueofgdpggr_g01_gdp_pt) (fm_gov_exp fm_gov_rev)
sort iso3c year
save "$input/IMF_FM.dta", replace

// cleans the files from IMF timseries of GFS ------------------------------
capture quietly program drop imf_clean_timeseries_GFS
program imf_clean_timeseries_GFS
	args path unitname attribute classificationname NAME

	import delimited "`path'", clear
	keep if unitname == "`unitname'" & attribute == "`attribute'" & classificationname == "`classificationname'"
	foreach i of varlist v* {
		loc lab: variable label `i'
		loc lab = "x" + "`lab'"
		rename `i' `lab'
		destring `lab', replace
	}
	keep countryname countrycode sectorname x*
	capture quietly drop x
	reshape long x, i(countryname countrycode sectorname) j(year, string)
	keep if sectorname == "Budgetary central government"
	check_dup_id "countrycode year"
	destring year, replace
	rename x `NAME'
	drop if `NAME' == .
	drop sectorname

	rename countryname country
	conv_ccode country
	if (1==1) {
		replace iso3c = "AFG" if country == "Afghanistan, Islamic Rep. of"
		replace iso3c = "ARM" if country == "Armenia, Rep. of"
		replace iso3c = "AZE" if country == "Azerbaijan, Rep. of"
		replace iso3c = "BHR" if country == "Bahrain, Kingdom of"
		replace iso3c = "BLR" if country == "Belarus, Rep. of"
		replace iso3c = "CPV" if country == "Cabo Verde"
		replace iso3c = "CAF" if country == "Central African Rep."
		replace iso3c = "MAC" if country == "China, P.R.: Macao"
		replace iso3c = "CHN" if country == "China, P.R.: Mainland"
		replace iso3c = "CHN" if country == "China, P.R.: Hong Kong"
		replace iso3c = "COD" if country == "Congo, Dem. Rep. of the"
		replace iso3c = "HRV" if country == "Croatia, Rep. of"
		replace iso3c = "CIV" if country == "CÃ´te d'Ivoire"
		replace iso3c = "CIV" if country == "Côte d'Ivoire"
		replace iso3c = "EGY" if country == "Egypt, Arab Rep. of"
		replace iso3c = "GNQ" if country == "Equatorial Guinea, Rep. of"
		replace iso3c = "EST" if country == "Estonia, Rep. of"
		replace iso3c = "SWZ" if country == "Eswatini, Kingdom of"
		replace iso3c = "ETH" if country == "Ethiopia, The Federal Dem. Rep. of"
		replace iso3c = "FJI" if country == "Fiji, Rep. of"
		replace iso3c = "IRN" if country == "Iran, Islamic Rep. of"
		replace iso3c = "KAZ" if country == "Kazakhstan, Rep. of"
		replace iso3c = "XKX" if country == "Kosovo, Rep. of"
		replace iso3c = "LAO" if country == "Lao People's Dem. Rep."
		replace iso3c = "LSO" if country == "Lesotho, Kingdom of"
		replace iso3c = "MDG" if country == "Madagascar, Rep. of"
		replace iso3c = "MHL" if country == "Marshall Islands, Rep. of the"
		replace iso3c = "MDA" if country == "Moldova, Rep. of"
		replace iso3c = "MOZ" if country == "Mozambique, Rep. of"
		replace iso3c = "NRU" if country == "Nauru, Rep. of"
		replace iso3c = "MKD" if country == "North Macedonia, Republic of"
		replace iso3c = "PLW" if country == "Palau, Rep. of"
		replace iso3c = "POL" if country == "Poland, Rep. of"
		replace iso3c = "SMR" if country == "San Marino, Rep. of"
		replace iso3c = "SRB" if country == "Serbia, Rep. of"
		replace iso3c = "SVN" if country == "Slovenia, Rep. of"
		replace iso3c = "STP" if country == "SÃ£o TomÃ© and PrÃ­ncipe, Dem. Rep. of"
		replace iso3c = "STP" if country == "São Tomé and Príncipe, Dem. Rep. of"
		replace iso3c = "SVK" if country == "Slovak Rep."
		replace iso3c = "TJK" if country == "Tajikistan, Rep. of"
		replace iso3c = "TZA" if country == "Tanzania, United Rep. of"
		replace iso3c = "TLS" if country == "Timor-Leste, Dem. Rep. of"
		replace iso3c = "UZB" if country == "Uzbekistan, Rep. of"
		replace iso3c = "YEM" if country == "Yemen, Rep. of"
	}

	isid iso3c countrycode year
	isid iso3c year
	isid countrycode year
	
	sort iso3c year
	
end

/* ======= temp: ======
import delimited "$input/imf_govt_finance_statistics/GFSE_09-11-2021 22-01-15-19_timeSeries.csv", clear
rename countryname country
conv_ccode country
if (1==1) {
		replace iso3c = "AFG" if country == "Afghanistan, Islamic Rep. of"
		replace iso3c = "ARM" if country == "Armenia, Rep. of"
		replace iso3c = "AZE" if country == "Azerbaijan, Rep. of"
		replace iso3c = "BHR" if country == "Bahrain, Kingdom of"
		replace iso3c = "BLR" if country == "Belarus, Rep. of"
		replace iso3c = "CPV" if country == "Cabo Verde"
		replace iso3c = "CAF" if country == "Central African Rep."
		replace iso3c = "MAC" if country == "China, P.R.: Macao"
		replace iso3c = "CHN" if country == "China, P.R.: Mainland"
		replace iso3c = "CHN" if country == "China, P.R.: Hong Kong"
		replace iso3c = "COD" if country == "Congo, Dem. Rep. of the"
		replace iso3c = "HRV" if country == "Croatia, Rep. of"
		replace iso3c = "CIV" if country == "CÃ´te d'Ivoire"
		replace iso3c = "CIV" if country == "Côte d'Ivoire"
		replace iso3c = "EGY" if country == "Egypt, Arab Rep. of"
		replace iso3c = "GNQ" if country == "Equatorial Guinea, Rep. of"
		replace iso3c = "EST" if country == "Estonia, Rep. of"
		replace iso3c = "SWZ" if country == "Eswatini, Kingdom of"
		replace iso3c = "ETH" if country == "Ethiopia, The Federal Dem. Rep. of"
		replace iso3c = "FJI" if country == "Fiji, Rep. of"
		replace iso3c = "IRN" if country == "Iran, Islamic Rep. of"
		replace iso3c = "KAZ" if country == "Kazakhstan, Rep. of"
		replace iso3c = "XKX" if country == "Kosovo, Rep. of"
		replace iso3c = "LAO" if country == "Lao People's Dem. Rep."
		replace iso3c = "LSO" if country == "Lesotho, Kingdom of"
		replace iso3c = "MDG" if country == "Madagascar, Rep. of"
		replace iso3c = "MHL" if country == "Marshall Islands, Rep. of the"
		replace iso3c = "MDA" if country == "Moldova, Rep. of"
		replace iso3c = "MOZ" if country == "Mozambique, Rep. of"
		replace iso3c = "NRU" if country == "Nauru, Rep. of"
		replace iso3c = "MKD" if country == "North Macedonia, Republic of"
		replace iso3c = "PLW" if country == "Palau, Rep. of"
		replace iso3c = "POL" if country == "Poland, Rep. of"
		replace iso3c = "SMR" if country == "San Marino, Rep. of"
		replace iso3c = "SRB" if country == "Serbia, Rep. of"
		replace iso3c = "SVN" if country == "Slovenia, Rep. of"
		replace iso3c = "STP" if country == "SÃ£o TomÃ© and PrÃ­ncipe, Dem. Rep. of"
		replace iso3c = "STP" if country == "São Tomé and Príncipe, Dem. Rep. of"
		replace iso3c = "SVK" if country == "Slovak Rep."
		replace iso3c = "TJK" if country == "Tajikistan, Rep. of"
		replace iso3c = "TZA" if country == "Tanzania, United Rep. of"
		replace iso3c = "TLS" if country == "Timor-Leste, Dem. Rep. of"
		replace iso3c = "UZB" if country == "Uzbekistan, Rep. of"
		replace iso3c = "YEM" if country == "Yemen, Rep. of"
	}
	
br if missing( iso3c)
* ======= temp ^^^ ====== */


// IMF Global Finance Statistics - Revenue & Expense -----------------------
imf_clean_timeseries_GFS "$input/imf_govt_finance_statistics/GFSE_09-11-2021 22-01-15-19_timeSeries.csv" "Percent of GDP" "Value" "Expense" "gfs_gov_exp"
drop countrycode country
save "$input/IMF_GFS_expenses.dta", replace

imf_clean_timeseries_GFS "$input/imf_govt_finance_statistics/GFSR_09-11-2021 22-01-01-95_timeSeries.csv" "Percent of GDP" "Value" "Revenue" "gfs_gov_rev"
drop countrycode country
save "$input/IMF_GFS_revenue.dta", replace

// FTSE, NIKKEI, and S&P (Baker, Bloom, & Terry) ----------------------------
// https://sites.google.com/site/srbaker/academic-work
// Importantly, Baker, Bloom, & Terry data is normalized to have SD = 1

use "$input/baker_bloom_terry_panel_data.dta", clear
keep country yq l1lavgvol l1avgret
sort country yq
gen keep_indic = mod(yq, 1)
keep if keep_indic == 0
drop keep_indic
rename (country yq) (iso3c year)	
sort iso3c year
save "$input/cleaned_baker_bloom_terry_panel_data.dta", replace

// Fertility -----------------------------------------------------------------

import delimited "$input/un_wpp/WPP2019_Period_Indicators_Medium.csv", clear
keep if variant == "Medium"
keep location midperiod tfr
gen year = 5 * floor(midperiod/5) 
drop midperiod

// convert ISO codes
conv_ccode "location"

conv_ccode_un "location"
drop location
check_dup_id "iso3c year"
naomit

save "$input/UN_fertility.dta", replace

// Stock Market Data (Baker Bloom Terry) -----------------------------------

// GDP deflator data: 
wbopendata, language(en – English) indicator(NY.GDP.DEFL.ZS) long clear
keep countrycode year ny_gdp_defl_zs countryname
drop if ny_gdp_defl_zs ==.
rename (countrycode ny_gdp_defl_zs) (iso3c deflator)
gen denom = deflator if year == 2007
bysort iso3c: fillmissing denom
gen defl = deflator / denom
tempfile defl
save `defl'

// get stock market data:
use "$input/baker_bloom_terry_packet/daily_stock_data/daily_stock_data.dta", clear

// we only have stock market data until March for 2020, which is right when the
// market crashes from COVID, so we exclude 2020.
drop if year == 2020

// First take a monthly average of the index price. Then take an annual average
// of the index price. Then take the returns of that.
gcollapse (mean) Close, by(year month country)
gcollapse (mean) Close, by(year country)

//returns:
fillin year country
sort country year
gen ret = Close / Close[_n-1] if country == country[_n-1]
rename country iso3c

// merge
mmerge iso3c year using `defl'

// Stock Market Data --------------------------------------------------------

// get all the file names from stocks and interest rates:
filelist , dir("$input/stocks and interest rates/") pattern(*.csv)
keep filename
levelsof filename, local(dirs_toloop)
clear

tempfile full_append
g temp = 1
save `full_append', replace

// make loop through these files:
foreach filename in `dirs_toloop' {
	import delimited "$input/stocks and interest rates/`filename'", varnames(1) encoding(UTF-8) rowrange(1:51) clear
	keep ticker name seriestype currency country units
	save "$input/id_interest_stocks.dta", replace

	import delimited "$input/stocks and interest rates/`filename'", varnames(1) encoding(UTF-8) rowrange(52:1000000) clear

	// replace variable name with the first row
	ds
	local a = r(varlist)
	foreach var in `a' {
		local try = strtoname(`var'[1]) 
		capture rename `var'  `try'
	}
	drop in 1

	// clean + reshape
	rename *_Close Close*
	quietly capture rename _*_Close Close_*
	
	// We drop the Norway Oslo SE OBX-25 Total Return Index in favor of the more
	// broad Oslo SE All-Share Index. the former includes the largst 25
	// companies, while the latter contains all.
	quietly capture drop Close_OBXD
	
	reshape long Close, i(Date) j(ticker, string)
	naomit
	rename (Date Close) (date value)
	mmerge ticker using "$input/id_interest_stocks.dta"
	destring value, replace
	g year = substr(date, 1, 4)
	g month = substr(date, 6, 2)
	g day = substr(date, 9, 2)
	drop _merge
	destring year month day, replace
	keep value country year month day seriestype
	drop if missing(value)
	
	// iso3c codes
	conv_ccode country
	drop if inlist(country, "Europe", "World")
	assert !missing(iso3c)

	gcollapse (mean) value, by(iso3c year seriestype)
	sort iso3c year
	local filename = subinstr("`filename'", "_csv.csv", "", .)

	save "$input/clean_`filename'.dta", replace
	append using `full_append', force
	save `full_append', replace
	clear
}
use `full_append'
save "$input/full_append_stock_interest.dta", replace

use "$input/full_append_stock_interest.dta", clear

// make new variables: (convert to wide manually)
drop temp
sort seriestype iso3c year
qui levelsof seriestype, local(levels)
foreach l of local levels {
	local var_label = subinstr("`l'", "-", "",.)
	local var_label = subinstr("`var_label'", "  ", " ",.)
	local var_label = subinstr("`var_label'", "  ", " ",.)
	local var_label = subinstr("`var_label'", " ", "_",.)
	local var_label = subinstr("`var_label'", " ", "",.)
	local var_label = lower("`var_label'")
	
	g `var_label' = value if seriestype == "`l'"
}
bys seriestype year iso3c: gen dup = _n
check_dup_id "seriestype year iso3c"

gcollapse (mean) consumer_price_indices government_bond_yields stock_indices_composites total_return_indices_stocks treasury_bill_yields, by(iso3c year)

// calculate inflation-adjusted returns and growth in inflation variables: 
// (base year 2000)
g cpi_base = consumer_price_indices if year == 2000
bysort iso3c: fillmissing cpi_base
g cpi_adj = consumer_price_indices/cpi_base
g index_inf_adj = total_return_indices_stocks / cpi_adj
br if !missing(index_inf_adj)
fillin iso3c year
sort iso3c year
// bys iso3c: g ret_iadj = index_inf_adj / index_inf_adj[_n-1] - 1
// bys iso3c: g g_cpi = consumer_price_indices / consumer_price_indices[_n-1] - 1

rename (consumer_price_indices government_bond_yields treasury_bill_yields) (cpi yield_10yr yield_3mo)
keep iso3c year cpi yield_10yr yield_3mo index_inf_adj
drop if ///
	missing(cpi) & ///
	missing(yield_10yr) & ///
	missing(yield_3mo) & ///
	missing(index_inf_adj)

save "$input/clean_stock_interest.dta", replace

// Female labor force participation rate ------------------------------------

// ILO Female and total labor force participation rate:
clear
wbopendata, clear nometadata long indicator(SL.TLF.CACT.FE.NE.ZS; SL.TLF.CACT.NE.ZS) year(1950:2021)
drop if regionname == "Aggregates"
keep countrycode year sl_tlf_cact_fe_ne_zs sl_tlf_cact_ne_zs
rename (countrycode sl_tlf_cact_fe_ne_zs sl_tlf_cact_ne_zs) (iso3c flp lp)
fillin iso3c year
drop _fillin
sort iso3c year
naomit
sort iso3c year
tempfile flp_ilo
save `flp_ilo'
save "$input/flp.dta", replace

