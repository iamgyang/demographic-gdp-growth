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
	// broad Oslo SE All-Share Index. the former includes the largst 25 companies,
	// while the latter contains all.
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
bys iso3c: g ret_iadj = index_inf_adj / index_inf_adj[_n-1] - 1
bys iso3c: g g_cpi = consumer_price_indices / consumer_price_indices[_n-1] - 1

keep year iso3c g_cpi government_bond_yields treasury_bill_yields ret_iadj
drop if ///
	missing(g_cpi) &  ///
	missing(government_bond_yields) &  ///
	missing(treasury_bill_yields) &  ///
	missing(ret_iadj)

label variable g_cpi "Annual percent inflation (CPI)"
label variable government_bond_yields "10 year bond yields"
label variable treasury_bill_yields "3 month bond yields"
label variable ret_iadj "Annual returns, inflation adjusted"

keep if year >= 1950

save "$input/clean_stock_interest.dta", replace



























