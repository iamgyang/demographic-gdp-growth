// !! to do: find out the other variable labels and definitions of the OECD data.

// somehow use this as well?
// https://www.qogdata.pol.gu.se/search/

// Macros ----------------------------------------------------------------

clear all 
set more off
set varabbrev off
set scheme s1mono
set type double, perm

// CHANGE THIS!! --- Define your own directories:
foreach user in "`c(username)'" {
	global root "C:/Users/`user'/Dropbox/CGD/Projects/dem_neg_labor"
}

global code        "$root/code"
global input       "$root/input"
global output      "$root/output"
cd "$input"
global check "yes"

// CHANGE THIS!! --- Do we want to install user-defined functions?
loc install_user_defined_functions "No"

if ("`install_user_defined_functions'" == "Yes") {
	foreach i in rangestat wbopendata kountry mmerge outreg2 somersd ///
	asgen moss reghdfe ftools fillmissing {
		ssc install `i'
	}
}

// Define programs -----------------------------------------------------------

quietly capture program drop check_dup_id
program check_dup_id
	args id_vars
	preserve
	keep `id_vars'
	sort `id_vars'
    quietly by `id_vars':  gen dup = cond(_N==1,0,_n)
	assert dup == 0
	restore
	end

quietly capture program drop naomit
program naomit
	foreach var of varlist _all {
		drop if missing(`var')
	}
	end

quietly capture program drop conv_ccode
program conv_ccode
args country_var
	kountry `country_var', from(other) stuck
	ren(_ISO3N_) (temp)
	kountry temp, from(iso3n) to(iso3c)
	drop temp
	ren (_ISO3C_) (iso)
end

quietly capture program drop append_all_dta
program append_all_dta
args input_directory output_directory NAME
	clear
	cd "`input_directory'"
	local filepath = "`c(pwd)'" // Save path to current folder in a local
	di "`c(pwd)'" // Display path to current folder
	local files : dir "`filepath'" files "*.dta" // Save name of all files in folder ending with .dta in a local
	di `"`files'"' // Display list of files to import data from
	tempfile master // Generate temporary save file to store data in
	save `master', replace empty
	foreach x of local files {
		di "`x'" // Display file name

		* 2A) Import each file
		qui: use "`x'", clear // Import file
		qui: gen id = subinstr("`x'", ".dta", "", .)	// Generate id variable (same as file name but without .dta)

		* 2B) Append each file to masterfile
		append using `master', force
		save `master', replace
	}
	order id, first
	sort id
	cd "`output_directory'"
	save "`NAME'.dta", replace
end	


quietly capture program drop conv_ccode_un
program conv_ccode_un
args country
	replace iso3c = "BOL" if `country' == "Bolivia (Plurinational State of)"
	replace iso3c = "CPV" if `country' == "Cabo Verde"
	replace iso3c = "HKG" if `country' == "China, Hong Kong SAR"
	replace iso3c = "MAC" if `country' == "China, Macao SAR"
	replace iso3c = "TWN" if `country' == "China, Taiwan Province of China"
	replace iso3c = "CIV" if `country' == "CÃ´te d'Ivoire"
	replace iso3c = "PRK" if `country' == "Dem. People's Republic of Korea"
	replace iso3c = "SWZ" if `country' == "Eswatini"
	replace iso3c = "PSE" if `country' == "State of Palestine"
	replace iso3c = "VEN" if `country' == "Venezuela (Bolivarian Republic of)"
	replace iso3c = "XKX" if `country' == "Kosovo"
	replace iso3c = "MKD" if `country' == "North Macedonia"
	replace iso3c = "CUW" if `country' == "CuraÃ§ao"
	replace iso3c = "REU" if `country' == "RÃ©union"
	replace iso3c = "FSM" if `country' == "Micronesia (Fed. States of)"
	replace iso3c = "PYF" if `country' == "French Polynesia"
	replace iso3c = "BES" if `country' == "Bonaire, Sint Eustatius and Saba"
	replace iso3c = "IMN" if `country' == "Isle of Man"
	replace iso3c = "MNP" if `country' == "Northern Mariana Islands"
	replace iso3c = "MAF" if `country' == "Saint Martin (French part)"
	replace iso3c = "SXM" if `country' == "Sint Maarten (Dutch part)"
	replace iso3c = "TKL" if `country' == "Tokelau"	
	
	drop if `country' == "Polynesia" // Polynesia refers to the REGION, not the COLONY
	drop if `country' == "Micronesia" // we have fed states of micronesia, which is the Country; micronesia is the REGION
	drop if `country' == "Africa"
	drop if `country' == "Channel Islands"
	drop if `country' == "Oceania"
	drop if `country' == "Melanesia"
	drop if `country' == "African Group"
	drop if `country' == "African Union"
	drop if `country' == "African Union: Central Africa"
	drop if `country' == "African Union: Eastern Africa"
	drop if `country' == "African Union: Northern Africa"
	drop if `country' == "African Union: Southern Africa"
	drop if `country' == "African Union: Western Africa"
	drop if `country' == "African, Caribbean and Pacific (ACP) Group of States"
	drop if `country' == "Andean Community"
	drop if `country' == "Asia"
	drop if `country' == "Asia-Pacific Economic Cooperation (APEC)"
	drop if `country' == "Asia-Pacific Group"
	drop if `country' == "Association of Southeast Asian Nations (ASEAN)"
	drop if `country' == "Australia/New Zealand"
	drop if `country' == "BRIC"
	drop if `country' == "BRICS"
	drop if `country' == "Belt-Road Initiative (BRI)"
	drop if `country' == "Belt-Road Initiative: Africa"
	drop if `country' == "Belt-Road Initiative: Asia"
	drop if `country' == "Belt-Road Initiative: Europe"
	drop if `country' == "Belt-Road Initiative: Latin America and the Caribbean"
	drop if `country' == "Belt-Road Initiative: Pacific"
	drop if `country' == "Black Sea Economic Cooperation (BSEC)"
	drop if `country' == "Bolivarian Alliance for the Americas (ALBA)"
	drop if `country' == "Caribbean"
	drop if `country' == "Caribbean Community and Common Market (CARICOM)"
	drop if `country' == "Central America"
	drop if `country' == "Central Asia"
	drop if `country' == "Central European Free Trade Agreement (CEFTA)"
	drop if `country' == "Central and Southern Asia"
	drop if `country' == "China (and dependencies)"
	drop if `country' == "Commonwealth of Independent States (CIS)"
	drop if `country' == "Commonwealth of Nations"
	drop if `country' == "Commonwealth: Africa"
	drop if `country' == "Commonwealth: Asia"
	drop if `country' == "Commonwealth: Caribbean and Americas"
	drop if `country' == "Commonwealth: Europe"
	drop if `country' == "Commonwealth: Pacific"
	drop if `country' == "Countries with Access to the Sea"
	drop if `country' == "Countries with Access to the Sea: Africa"
	drop if `country' == "Countries with Access to the Sea: Asia"
	drop if `country' == "Countries with Access to the Sea: Europe"
	drop if `country' == "Countries with Access to the Sea: Latin America and the Caribbean"
	drop if `country' == "Countries with Access to the Sea: Northern America"
	drop if `country' == "Countries with Access to the Sea: Oceania"
	drop if `country' == "Czechia"
	drop if `country' == "Denmark (and dependencies)"
	drop if `country' == "ECE: North America-2"
	drop if `country' == "ECE: UNECE-52"
	drop if `country' == "ECLAC: Latin America"
	drop if `country' == "ECLAC: The Caribbean"
	drop if `country' == "ESCAP region: East and North-East Asia"
	drop if `country' == "ESCAP region: North and Central Asia"
	drop if `country' == "ESCAP region: Pacific"
	drop if `country' == "ESCAP region: South and South-West Asia"
	drop if `country' == "ESCAP region: South-East Asia"
	drop if `country' == "ESCAP: ADB Developing member countries (DMCs)"
	drop if `country' == "ESCAP: ADB Group A (Concessional assistanceÂ only)"
	drop if `country' == "ESCAP: ADB Group BÂ (OCR blend)"
	drop if `country' == "ESCAP: ADB Group C (Regular OCR only)"
	drop if `country' == "ESCAP: ASEAN"
	drop if `country' == "ESCAP: Central Asia"
	drop if `country' == "ESCAP: ECO"
	drop if `country' == "ESCAP: HDI groups"
	drop if `country' == "ESCAP: Landlocked countries (LLDCs)"
	drop if `country' == "ESCAP: Least Developed Countries (LDCs)"
	drop if `country' == "ESCAP: Pacific island dev. econ."
	drop if `country' == "ESCAP: SAARC"
	drop if `country' == "ESCAP: WB High income econ."
	drop if `country' == "ESCAP: WB Low income econ."
	drop if `country' == "ESCAP: WB Lower middle income econ."
	drop if `country' == "ESCAP: WB Upper middle income econ."
	drop if `country' == "ESCAP: WB income groups"
	drop if `country' == "ESCAP: high HDI"
	drop if `country' == "ESCAP: high income"
	drop if `country' == "ESCAP: income groups"
	drop if `country' == "ESCAP: low HDI"
	drop if `country' == "ESCAP: low income"
	drop if `country' == "ESCAP: lower middle HDI"
	drop if `country' == "ESCAP: lower middle income"
	drop if `country' == "ESCAP: other Asia-Pacific countries/areas"
	drop if `country' == "ESCAP: upper middle HDI"
	drop if `country' == "ESCAP: upper middle income"
	drop if `country' == "ESCWA: Arab countries"
	drop if `country' == "ESCWA: Arab least developed countries"
	drop if `country' == "ESCWA: Gulf Cooperation Council countries"
	drop if `country' == "ESCWA: Maghreb countries"
	drop if `country' == "ESCWA: Mashreq countries"
	drop if `country' == "ESCWA: member countries"
	drop if `country' == "East African Community (EAC)"
	drop if `country' == "Eastern Africa"
	drop if `country' == "Eastern Asia"
	drop if `country' == "Eastern Europe"
	drop if `country' == "Eastern European Group"
	drop if `country' == "Eastern and South-Eastern Asia"
	drop if `country' == "Economic Community of Central African States (ECCAS)"
	drop if `country' == "Economic Community of West African States (ECOWAS)"
	drop if `country' == "Economic Cooperation Organization (ECO)"
	drop if `country' == "Eurasian Economic Community (Eurasec)"
	drop if `country' == "Europe"
	drop if `country' == "Europe (48)"
	drop if `country' == "Europe and Northern America"
	drop if `country' == "European Community (EC: 12)"
	drop if `country' == "European Free Trade Agreement (EFTA)"
	drop if `country' == "European Union (EU: 15)"
	drop if `country' == "European Union (EU: 28)"
	drop if `country' == "France (and dependencies)"
	drop if `country' == "Greater Arab Free Trade Area (GAFTA)"
	drop if `country' == "Group of 77 (G77)"
	drop if `country' == "Group of Eight (G8)"
	drop if `country' == "Group of Seven (G7)"
	drop if `country' == "Group of Twenty (G20) - member states"
	drop if `country' == "Gulf Cooperation Council (GCC)"
	drop if `country' == "High-income countries"
	drop if `country' == "LLDC: Africa"
	drop if `country' == "LLDC: Asia"
	drop if `country' == "LLDC: Europe"
	drop if `country' == "LLDC: Latin America"
	drop if `country' == "Land-locked Countries"
	drop if `country' == "Land-locked Countries (Others)"
	drop if `country' == "Land-locked Developing Countries (LLDC)"
	drop if `country' == "Latin America and the Caribbean"
	drop if `country' == "Latin American Integration Association (ALADI)"
	drop if `country' == "Latin American and Caribbean Group (GRULAC)"
	drop if `country' == "League of Arab States (LAS, informal name: Arab League)"
	drop if `country' == "Least developed countries"
	drop if `country' == "Least developed: Africa"
	drop if `country' == "Least developed: Asia"
	drop if `country' == "Least developed: Latin America and the Caribbean"
	drop if `country' == "Least developed: Oceania"
	drop if `country' == "Less developed regions"
	drop if `country' == "Less developed regions, excluding China"
	drop if `country' == "Less developed regions, excluding least developed countries"
	drop if `country' == "Less developed: Africa"
	drop if `country' == "Less developed: Asia"
	drop if `country' == "Less developed: Latin America and the Caribbean"
	drop if `country' == "Less developed: Oceania"
	drop if `country' == "Low-income countries"
	drop if `country' == "Lower-middle-income countries"
	drop if `country' == "Middle Africa"
	drop if `country' == "Middle-income countries"
	drop if `country' == "More developed regions"
	drop if `country' == "More developed: Asia"
	drop if `country' == "More developed: Europe"
	drop if `country' == "More developed: Northern America"
	drop if `country' == "More developed: Oceania"
	drop if `country' == "Netherlands (and dependencies)"
	drop if `country' == "New EU member states (joined since 2004)"
	drop if `country' == "New Zealand (and dependencies)"
	drop if `country' == "No income group available"
	drop if `country' == "Non-Self-Governing Territories"
	drop if `country' == "North American Free Trade Agreement (NAFTA)"
	drop if `country' == "North Atlantic Treaty Organization (NATO)"
	drop if `country' == "Northern Africa"
	drop if `country' == "Northern Africa and Western Asia"
	drop if `country' == "Northern America"
	drop if `country' == "Northern Europe"
	drop if `country' == "Oceania (excluding Australia and New Zealand)"
	drop if `country' == "Organisation for Economic Co-operation and Development (OECD)"
	drop if `country' == "Organization for Security and Co-operation in Europe (OSCE)"
	drop if `country' == "Organization of American States (OAS)"
	drop if `country' == "Organization of Petroleum Exporting countries (OPEC)"
	drop if `country' == "Organization of the Islamic Conference (OIC)"
	drop if `country' == "SIDS Atlantic, and Indian Ocean, Mediterranean and South China Sea (AIMS)"
	drop if `country' == "SIDS Caribbean"
	drop if `country' == "SIDS Pacific"
	drop if `country' == "Shanghai Cooperation Organization (SCO)"
	drop if `country' == "Small Island Developing States (SIDS)"
	drop if `country' == "South America"
	drop if `country' == "South Asian Association for Regional Cooperation (SAARC)"
	drop if `country' == "South-Eastern Asia"
	drop if `country' == "Southern Africa"
	drop if `country' == "Southern African Development Community (SADC)"
	drop if `country' == "Southern Asia"
	drop if `country' == "Southern Common Market (MERCOSUR)"
	drop if `country' == "Southern Europe"
	drop if `country' == "Sub-Saharan Africa"
	drop if `country' == "UN-ECE: member countries"
	drop if `country' == "UNFPA Regions"
	drop if `country' == "UNFPA: Arab States (AS)"
	drop if `country' == "UNFPA: Asia and the Pacific (AP)"
	drop if `country' == "UNFPA: East and Southern Africa (ESA)"
	drop if `country' == "UNFPA: Eastern Europe and Central Asia (EECA)"
	drop if `country' == "UNFPA: Latin America and the Caribbean (LAC)"
	drop if `country' == "UNFPA: West and Central Africa (WCA)"
	drop if `country' == "UNICEF PROGRAMME REGIONS"
	drop if `country' == "UNICEF Programme Regions: East Asia and Pacific (EAPRO)"
	drop if `country' == "UNICEF Programme Regions: Eastern Caribbean"
	drop if `country' == "UNICEF Programme Regions: Eastern and Southern Africa (ESARO)"
	drop if `country' == "UNICEF Programme Regions: Europe and Central Asia (CEECIS)"
	drop if `country' == "UNICEF Programme Regions: Latin America"
	drop if `country' == "UNICEF Programme Regions: Latin America and Caribbean (LACRO)"
	drop if `country' == "UNICEF Programme Regions: Middle East and North Africa (MENARO)"
	drop if `country' == "UNICEF Programme Regions: South Asia (ROSA)"
	drop if `country' == "UNICEF Programme Regions: West and Central Africa (WCARO)"
	drop if `country' == "UNICEF REGIONS"
	drop if `country' == "UNICEF Regions: East Asia and Pacific"
	drop if `country' == "UNICEF Regions: Eastern Europe and Central Asia"
	drop if `country' == "UNICEF Regions: Eastern and Southern Africa"
	drop if `country' == "UNICEF Regions: Europe and Central Asia"
	drop if `country' == "UNICEF Regions: Latin America and Caribbean"
	drop if `country' == "UNICEF Regions: Middle East and North Africa"
	drop if `country' == "UNICEF Regions: North America"
	drop if `country' == "UNICEF Regions: South Asia"
	drop if `country' == "UNICEF Regions: Sub-Saharan Africa"
	drop if `country' == "UNICEF Regions: West and Central Africa"
	drop if `country' == "UNICEF Regions: Western Europe"
	drop if `country' == "UNITED NATIONS Regional Groups of Member States"
	drop if `country' == "United Kingdom (and dependencies)"
	drop if `country' == "United Nations Economic Commission for Africa (UN-ECA)"
	drop if `country' == "United Nations Economic Commission for Latin America and the Caribbean (UN-ECLAC)"
	drop if `country' == "United Nations Economic and Social Commission for Asia and the Pacific (UN-ESCAP) Regions"
	drop if `country' == "United Nations Member States"
	drop if `country' == "United States of America (and dependencies)"
	drop if `country' == "Upper-middle-income countries"
	drop if `country' == "WB region: East Asia and Pacific (excluding high income)"
	drop if `country' == "WB region: Europe and Central Asia (excluding high income)"
	drop if `country' == "WB region: Latin America and Caribbean (excluding high income)"
	drop if `country' == "WB region: Middle East and North Africa (excluding high income)"
	drop if `country' == "WB region: South Asia (excluding high income)"
	drop if `country' == "WB region: Sub-Saharan Africa (excluding high income)"
	drop if `country' == "WHO Regions"
	drop if `country' == "WHO: African region (AFRO)"
	drop if `country' == "WHO: Americas (AMRO)"
	drop if `country' == "WHO: Eastern Mediterranean Region (EMRO)"
	drop if `country' == "WHO: European Region (EURO)"
	drop if `country' == "WHO: South-East Asia region (SEARO)"
	drop if `country' == "WHO: Western Pacific region (WPRO)"
	drop if `country' == "West African Economic and Monetary Union (UEMOA)"
	drop if `country' == "Western Africa"
	drop if `country' == "Western Asia"
	drop if `country' == "Western Europe"
	drop if `country' == "Western European and Others Group (WEOG)"
	drop if `country' == "World"
	drop if `country' == "World Bank Regional Groups (developing only)"
	drop if `country' == "ESCAP: ADB groups"
	drop if `country' == "ESCAP: Other Regional Groups"
	drop if `country' == "Economic groups"
	drop if `country' == "Geographic regions"
	drop if `country' == "International groups"
	drop if `country' == "Regional political groups: Africa"
	drop if `country' == "Regional political groups: Americas"
	drop if `country' == "Regional political groups: Arab"
	drop if `country' == "Regional political groups: Asia and Oceania"
	drop if `country' == "Regional political groups: Europe"
	drop if `country' == "Regional trade groups: Africa"
	drop if `country' == "Regional trade groups: Americas"
	drop if `country' == "Regional trade groups: Arab"
	drop if `country' == "Regional trade groups: Asia"
	drop if `country' == "Regional trade groups: Europe"
	drop if `country' == "Saint BarthÃ©lemy"
	drop if `country' == "Sustainable Development Goal (SDG) regions"
	drop if `country' == "UN development groups"
	drop if `country' == "United Nations Economic Commission for Europe (UN-ECE)"
	drop if `country' == "United Nations Economic and Social Commission for Western Asia (UN-ESCWA)"
	drop if `country' == "United Nations Regional Commissions"
	drop if `country' == "World Bank income groups"	
end

// UN population estimates -------------------------------------------

import delimited "un_WPP2019_PopulationByAgeSex_Medium.csv", clear
keep if variant == "Medium"
keep location time agegrp agegrpstart agegrpspan poptotal

preserve
	keep if agegrpstart < 65 & agegrpstart >= 15
	collapse (sum) poptotal, by(location time)
	rename poptotal popwork
	replace popwork = popwork * 1000
	rename location country
	check_dup_id "country time"
	tempfile un_working_pop
	save `un_working_pop'
restore

collapse (sum) poptotal, by(location time)
replace poptotal = poptotal * 1000
rename location country

mmerge country time using `un_working_pop'
check_dup_id "country time"
assert _merge == 3
drop _merge

// convert country names to ISO3c codes
conv_ccode "country"
rename iso iso3c

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
rename (time) (year)

sort iso3c year
save "un_pop_estimates_cleaned.dta", replace

// PWT GDP (growth rates) -----------------------------------------------------

use "pwt100.dta", clear
keep rgdpna countrycode year
drop if rgdpna == .
rename (rgdpna countrycode) (rgdp_pwt iso3c)	

sort iso3c year
save "pwt_cleaned.dta", replace

// Gov't revenue and deficit levels -----------------------------------------
// https://stats.oecd.org/Index.aspx?DataSetCode=RS_AFR

program clean_oecd
	args indicator_ measure_ tempfilename_ variable_
	keep if indicator == "`indicator_'"
	keep if measure == "`measure_'"
	keep location time value
	rename (location time value) (iso3c year `variable_')
	save "`tempfilename_'", replace
	end

// revenue
import delimited "oecd_DP_LIVE_11082021203447392.csv", encoding(UTF-8) clear 
clean_oecd GGREV PC_GDP oecd_govt_rev.dta gov_rev_pc_gdp
check_dup_id "iso3c year"

// deficit
import delimited "oecd_DP_LIVE_11082021203534767.csv", encoding(UTF-8) clear 
clean_oecd GGNLEND PC_GDP oecd_govt_deficit.dta gov_deficit_pc_gdp
check_dup_id "iso3c year"

// expenditrure
import delimited "oecd_DP_LIVE_11082021203550955.csv", encoding(UTF-8) clear 
keep if indicator == "GGEXP"
keep if measure == "PC_GDP"
keep location time value subject
reshape wide value, i(location time) j(subject) string
rename value* gov_exp_*
rename (location time) (iso3c year)
check_dup_id "iso3c year"
save "oecd_govt_expend.dta", replace

// tax revenue
import delimited "oecd_RS_GBL_11082021204025971.csv", encoding(UTF-8) clear 
keep if indicator == "Tax revenue as % of GDP"
keep if levelofgovernment == "Total"
keep if taxrevenue == "Total tax revenue"
keep cou year value
rename (cou value) (iso3c gov_tax_rev_pc_gdp)
check_dup_id "iso3c year"
drop if inlist(iso3c, "419", "AFRIC", "OAVG")

sort iso3c year
save "oecd_tax_revenue.dta", replace

// Govt revenues ------------------------------------------------------------

use "government_revenue_dataset/grd_Merged.dta", clear
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
assert iso == iso3c_2
restore

sort iso3c year
save "clean_grd.dta", replace

// Govt deficits ------------------------------------------------------------

// From IMF fiscal monitor (FM) ---------------------------------------------
import delimited "IMF_fiscal_monitor.csv", clear
keep ïcountryname countrycode timeperiod expenditureofgdpg_x_g01_gdp_pt revenueofgdpggr_g01_gdp_pt
rename ïcountryname country
conv_ccode country
replace iso = "HKG" if country =="China, P.R.: Hong Kong"
replace iso = "CHN" if country =="China, P.R.: Mainland"
replace iso = "YEM" if country =="Yemen, Republic of"
replace iso = "VEN" if country =="Venezuela, Republica Bolivariana de"
replace iso = "AZE" if country =="Azerbaijan, Republic of"
replace iso = "CPV" if country =="Cabo Verde"
replace iso = "MKD" if country =="North Macedonia"
replace iso = "BHR" if country =="Bahrain, Kingdom of"
replace iso = "ARM" if country =="Armenia, Republic of"
replace iso = "TLS" if country =="Timor-Leste, Dem. Rep. of"
replace iso = "STP" if country =="SÃ£o TomÃ© and PrÃ­ncipe"
replace iso = "XKX" if country =="Kosovo"
replace iso = "MAC" if country =="Macao SAR"
replace iso = "SWZ" if country =="Eswatini"
drop if iso == ""
rename timeperiod year
check_dup_id "iso countrycode year"
check_dup_id "iso year"
check_dup_id "countrycode year"
rename iso iso3c
rename (expenditureofgdpg_x_g01_gdp_pt revenueofgdpggr_g01_gdp_pt) (fm_gov_exp fm_gov_rev)
sort iso3c year
save "IMF_FM.dta", replace

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
	keep ïcountryname countrycode sectorname x*
	capture quietly drop x
	reshape long x, i(ïcountryname countrycode sectorname) j(year, string)
	keep if sectorname == "Budgetary central government"
	check_dup_id "countrycode year"
	destring year, replace
	rename x `NAME'
	drop if `NAME' == .
	drop sectorname

	rename ïcountryname country
	conv_ccode country
	if (1==1) {
		replace iso = "AFG" if country == "Afghanistan, Islamic Rep. of"
		replace iso = "ARM" if country == "Armenia, Rep. of"
		replace iso = "AZE" if country == "Azerbaijan, Rep. of"
		replace iso = "BHR" if country == "Bahrain, Kingdom of"
		replace iso = "BLR" if country == "Belarus, Rep. of"
		replace iso = "CPV" if country == "Cabo Verde"
		replace iso = "CAF" if country == "Central African Rep."
		replace iso = "MAC" if country == "China, P.R.: Macao"
		replace iso = "CHN" if country == "China, P.R.: Mainland"
		replace iso = "COD" if country == "Congo, Dem. Rep. of the"
		replace iso = "HRV" if country == "Croatia, Rep. of"
		replace iso = "CIV" if country == "CÃ´te d'Ivoire"
		replace iso = "EGY" if country == "Egypt, Arab Rep. of"
		replace iso = "GNQ" if country == "Equatorial Guinea, Rep. of"
		replace iso = "EST" if country == "Estonia, Rep. of"
		replace iso = "SWZ" if country == "Eswatini, Kingdom of"
		replace iso = "ETH" if country == "Ethiopia, The Federal Dem. Rep. of"
		replace iso = "FJI" if country == "Fiji, Rep. of"
		replace iso = "IRN" if country == "Iran, Islamic Rep. of"
		replace iso = "KAZ" if country == "Kazakhstan, Rep. of"
		replace iso = "LAO" if country == "Lao People's Dem. Rep."
		replace iso = "LSO" if country == "Lesotho, Kingdom of"
		replace iso = "MDG" if country == "Madagascar, Rep. of"
		replace iso = "MHL" if country == "Marshall Islands, Rep. of the"
		replace iso = "MDA" if country == "Moldova, Rep. of"
		replace iso = "MOZ" if country == "Mozambique, Rep. of"
		replace iso = "NRU" if country == "Nauru, Rep. of"
		replace iso = "MKD" if country == "North Macedonia, Republic of"
		replace iso = "PLW" if country == "Palau, Rep. of"
		replace iso = "POL" if country == "Poland, Rep. of"
		replace iso = "SMR" if country == "San Marino, Rep. of"
		replace iso = "SRB" if country == "Serbia, Rep. of"
		replace iso = "SVN" if country == "Slovenia, Rep. of"
		replace iso = "STP" if country == "SÃ£o TomÃ© and PrÃ­ncipe, Dem. Rep. of"
		replace iso = "TJK" if country == "Tajikistan, Rep. of"
		replace iso = "TZA" if country == "Tanzania, United Rep. of"
		replace iso = "TLS" if country == "Timor-Leste, Dem. Rep. of"
		replace iso = "UZB" if country == "Uzbekistan, Rep. of"
		replace iso = "YEM" if country == "Yemen, Rep. of"
	}

	check_dup_id "iso countrycode year"
	check_dup_id "iso year"
	check_dup_id "countrycode year"
	
	rename iso iso3c
	sort iso3c year
	
end

// IMF Global Finance Statistics - Revenue & Expense -----------------------
imf_clean_timeseries_GFS "imf_govt_finance_statistics/GFSE_09-11-2021 22-01-15-19_timeSeries.csv" "Percent of GDP" "Value" "Expense" "gfs_gov_exp"
drop countrycode country
save "IMF_GFS_expenses.dta", replace

imf_clean_timeseries_GFS "imf_govt_finance_statistics/GFSR_09-11-2021 22-01-01-95_timeSeries.csv" "Percent of GDP" "Value" "Revenue" "gfs_gov_rev"
drop countrycode country
save "IMF_GFS_revenue.dta", replace

// FTSE, NIKKEI, and S&P (Baker, Bloom, & Terry) ----------------------------
// https://sites.google.com/site/srbaker/academic-work
// Importantly, Baker, Bloom, & Terry data is normalized to have SD = 1

use "baker_bloom_terry_panel_data.dta", clear
keep country yq l1lavgvol l1avgret
sort country yq
gen keep_indic = mod(yq, 1)
keep if keep_indic == 0
drop keep_indic
rename (country yq) (iso3c year)	
sort iso3c year
save "cleaned_baker_bloom_terry_panel_data.dta", replace

// Correllates of War -------------------------------------------------------
// make sure that we have 1 country-year after the merge

// get the country codes ----------
import delimited "system2016.csv", clear
keep stateabb ccode
duplicates drop
sort ccode
gen ccodel1 = ccode[_n-1]
assert ccodel1 != ccode
drop ccodel1
save "cor_war_(cow)_codes.dta", replace

// define program to load each correllates of war dataset:
quietly capture program drop clean_cow
program clean_cow
	args file_name_ vars_keep_
	
	// import file:
	if (regexm("`file_name_'", ".csv$")) {
		import delimited "`file_name_'", clear
	}
	if (regexm("`file_name_'", ".dta$")) {
		use "`file_name_'", clear
	}
	
	// keep certain important variables on start of wa &, country codes
	rename *, lower
	keep `vars_keep_'
	
	// replace missing values
		//  -9 = year unknown
		//  -7 = ongoing
		//  -8 = not applicable

	foreach i of varlist _all {
			replace `i' = . if inlist(`i', -9, -8, -7, -6)
	}
end

tempfile intra inter nonstate extra

// INTRA -------
clear
clean_cow "INTRA-STATE WARS v5.1.dta" "warnum ccode* starty* endy*"
foreach i of varlist _all {
assert `i' != -9
}
gen filename = "intra"
save `intra'

// INTER --------
clean_cow "directed dyadic war may 2018.dta" "warnum state* warstrtyr warendyr"
foreach i of varlist _all {
assert `i' != -9
}
gen filename = "inter"
assert warstrtyr !=. & warendyr!=.
save `inter'

// NONSTATE ---------
import delimited "cow_Non-StateWarData_v4.0.csv", clear

// EXTRA-STATE ----------
clean_cow "Extra-StateWarData_v4.0.csv" "warnum ccode* starty* endy*"
foreach i of varlist _all {
assert `i' != -9
}
br if startyear1 != . & endyear1 == .

// we can replace ccode2 variable because this is a 1-state w/ a nonstate actor
replace ccode1 = ccode2 if ccode1 == .
assert ccode1 != .
assert ccode1 ==ccode2 if ccode2 != .
drop ccode2
gen filename = "extra"
save `extra'

// append the correllates of war datasets -------
clear 
use `extra'
foreach i in `intra' `inter' {
	append using `i', force
}

duplicates drop

save "temp_appended.dta", replace
use "temp_appended.dta", clear

// coalesce columns
gen ccode = .
foreach i in statea ccode1 ccodea {
	replace ccode = `i' if ccode == .
}
foreach i in statea ccode1 ccodea {
	assert ccode == `i' if `i' != .
}

// Concerns: 
// What to do about non-state wars?
// What to do about regional wars? (e.g. ISIS-al Nusra Front War of 2014; Rada'a War of 2014-present)
// For now, we're dropping them.
drop if ccode == .
drop statea ccode1 ccodea
rename stateb ccodeb

tempfile appended
save `appended'

// merge codes & separate code b --------

// Right now, we have a dataset that has a column with PAIRs of states. 
// Change to be a dataset with just 1 column for the state.
use "cor_war_(cow)_codes.dta", clear
mmerge ccode using `appended'
assert inlist(_merge, 1, 3)
keep if _merge == 3
drop _merge

tempfile part1
save `part1'

replace ccode = ccodeb
drop stateabb ccodeb
drop if ccode == .
mmerge ccode using "cor_war_(cow)_codes.dta"
tempfile part2
save `part2'

append using `part1'
drop _merge ccodeb

// make sure that each Country ISO3c code has a 1-1 match with the numeric codes
preserve
keep ccode stateabb
duplicates drop
check_dup_id "stateabb"
check_dup_id "ccode"
restore

// pivot longer: ---------
drop filename
ds
local varlist `r(varlist)'
di "`varlist'"
gen id = _n
local excluded ccode warnum stateabb id
local varlist : list varlist - excluded
di "`varlist'"
foreach i in `varlist' {
	rename `i' stub`i'
}
reshape long stub, i(`excluded') j(type_variable) string
drop if stub == .
keep stateabb type_variable stub
rename (stateabb type_variable stub) (iso3c type1 year)

// label whether the year is the start of a war or the end of a war
// we only keep annual values because our other datasets are annual
gen type = ""
replace type = "END" if ///
			((strpos(type1, "yr") > 0) | (strpos(type1, "year") > 0)) & ///
			(strpos(type1, "end") > 0)
replace type = "START" if ///
			((strpos(type1, "yr") > 0) | (strpos(type1, "year") > 0)) & ///
			((strpos(type1, "start") > 0)|(strpos(type1, "strt") > 0))

drop type1
keep if type != ""

// if there is a war that starts and ends on the same year, then just label is as
// the end in that year (we'll replace ends with indicator showing that it's in
// a war for that year):
duplicates drop
sort iso3c year type
bysort iso3c year: gen dup = _n
assert type == "START" if dup >= 2
drop if dup >= 2
drop dup

tempfile start_end_of_wars_long
save `start_end_of_wars_long'

// create a grid of all the combinations of iso3c and year from 1800 to 2021
keep iso3c
duplicates drop
set obs 400
gen year = 1800 + _n
fillin iso3c year

// Our EXTRA-STATE war dataset goes to 2007.
// Our INTER-STATE war dataset goes to 2010.
// Our INTRA-STATE war dataset goes to 2014.
// So, we have to take the minimum of these dates 
drop if iso3c == "" | year > 2007
drop _fillin

// merge in our war dataset
mmerge iso3c year using `start_end_of_wars_long'
check_dup_id "iso3c year"
sort iso3c year
bysort iso3c: fillmissing type, with(previous)
gen war = 0
replace war = 1 if type == "START"
replace war = 0 if type == "END"
replace war = 0 if type == ""
replace war = 1 if _merge == 3
drop if year > 2007
keep iso3c year war

sort iso3c year
save "finalized_war.dta", replace

// Fertility -----------------------------------------------------------------

import delimited "un_wpp/WPP2019_Period_Indicators_Medium.csv", clear
keep if variant == "Medium"
keep location midperiod tfr
gen year = 5 * floor(midperiod/5) 
drop midperiod

// convert ISO codes
conv_ccode "location"
rename iso iso3c
conv_ccode_un "location"
drop location
check_dup_id "iso3c year"
naomit

save "UN_fertility.dta", replace

// Female labor force participation rate ------------------------------------

// ILO modeled estimates of Female and total labor force participation rate:
clear
wbopendata, clear nometadata long indicator(SL.TLF.CACT.FE.ZS; SL.TLF.CACT.ZS) year(1950:2021)
drop if regionname == "Aggregates"
keep countrycode year sl_tlf_cact_fe_zs sl_tlf_cact_zs
rename (countrycode sl_tlf_cact_fe_zs sl_tlf_cact_zs) (iso3c flp lp)
fillin iso3c year
drop _fillin
sort iso3c year
naomit
sort iso3c year
tempfile flp_ilo
save `flp_ilo'

// female labor force participation from OECD and Long, downloaded from OWID:
// https://ourworldindata.org/female-labor-supply?preview_id=13372&preview_nonce=6d1f899c93&_thumbnail_id=-1&preview=true#female-participation-in-labor-markets-grew-remarkably-in-the-20th-century
// first chart: Female participation in labor markets grew remarkably in the 20th century

import delimited "female-labor-force-participation-OECD-Long.csv", clear
rename code iso3c
rename femalelaborforceparticipationrat flp2

preserve
conv_ccode "entity"
keep iso3c iso
duplicates drop
naomit
assert iso3c == iso
restore

sort iso3c year
tempfile flp_oecd_long
save `flp_oecd_long'

clear
use `flp_oecd_long'
fillin iso3c year
drop _fillin

// merge both
mmerge iso3c year using `flp_ilo'

// check that entity and iso3c match and are not duplicated
preserve
keep entity iso3c
naomit
duplicates drop
conv_ccode entity
naomit
assert iso3c == iso
check_dup_id "entity"
check_dup_id "iso3c"
check_dup_id "iso"
restore

keep iso3c year *lp flp2
drop if missing(iso3c)

// splice together the female laborforce participation ILO data with the 
// actual estimates by OECD and Long using growth method

// indicator for missing:
gen indic = missing(flp2)
sort iso3c year
by iso3c: egen earliest_present = min(year) if !missing(flp2)
bysort iso3c: fillmissing earliest_present
sort iso3c year
by iso3c: egen latest_present = max(year) if !missing(flp2)
bysort iso3c: fillmissing latest_present
gen indic_to_fill_gr = year < earliest_present | year > latest_present

// loop arbitrarily through 50 times, and fill with growth:
forval i = 0/50 {
sort iso3c year
// cast backwards
gen flp2_new = flp2[_n+1] * flp / flp[_n+1] if iso3c==iso3c[_n+1]
replace flp2 = flp2_new if (missing(flp2) & indic_to_fill_gr == 1)
drop flp2_new*
// cast forward
gen flp2_new = flp2[_n-1] * flp / flp[_n-1] if iso3c==iso3c[_n-1]
replace flp2 = flp2_new if (missing(flp2) & indic_to_fill_gr == 1)
drop flp2_new*
}

// then, if ALL the variables are missing, just replace female labor force 
// participation with the new modeled estimate from ILO
check_dup_id "iso3c year"
sort iso3c year
gen indic_after_gr = missing(flp2)
by iso3c: egen tot_missing = sum(indic_after_gr)
by iso3c: gen tot = _N
gen missing_ratio = tot_missing / tot
replace flp2 = flp if missing_ratio == 1

// make sure for the variables that you DID fill in, that the ratio of the
// reference dataset (modeled ILO values) is the SAME as the ratios of 
// consecutive filled in variables.
sort iso3c year

preserve
gen check_ratio_1 = flp/flp[_n-1] if iso3c == iso3c[_n-1]
gen check_ratio_2 = flp2/flp2[_n-1] if iso3c == iso3c[_n-1]
keep if indic == 1
keep iso3c year check_ratio_1 check_ratio_2
naomit
assert abs(check_ratio_1 - check_ratio_2)<0.0001
restore

drop indic_after_gr tot_missing tot missing_ratio indic earliest_present ///
latest_present indic_to_fill_gr flp
rename flp2 flp

save "flp.dta", replace

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
	"cleaned_baker_bloom_terry_panel_data.dta"
	"finalized_war.dta"
	"UCDP_geography_deaths.dta"
	"UN_fertility.dta"
	"flp.dta"
end
levelsof datasets, local(datasets)

use "pwt_cleaned.dta", clear

foreach i in `datasets' {
	di "`i'"
	mmerge iso3c year using `i'
	drop _merge
}

check_dup_id "iso3c year"
fillin iso3c year
drop _fillin country

// TO DO: is the GRD database / OECD database about CENTRAL gov't or about local / STATE govt's??
label variable caution_GRD "Caution notes from Global Revenue Database data"
label variable gov_deficit_pc_gdp "Government deficit  (% GDP)"
label variable gov_rev_pc_gdp "Total government revenue (% GDP)"
label variable gov_tax_rev_pc_gdp "Total government tax revenue (% GDP)"
label variable income "Historical WB income classificaiton"
label variable iso3c "ISO3c country code"
label variable l1avgret "Stock returns (normalized & CPI inflation adjusted); cumul. return in prior 4 quarters"
label variable l1lavgvol "Stock volatility; average quarterly standard deviations of daily stock returns over previous four quarters"
label variable rgdp_pwt "GDP, PPP (PWT)"

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

save "final_raw_labor_growth.dta", replace

// Derived variables -------------------------------------------------------

use "final_raw_labor_growth.dta", clear

// Restrict population to 5 year chunks
gen year_mod = mod(year, 5)
keep if year_mod == 0
drop year_mod

// Take a lag of that sum & find the percent change in population.
fillin iso3c year
sort iso3c year
drop _fillin
foreach i in rgdp_pwt popwork rev_inc_sc fm_gov_exp l1avgret flp lp gov_deficit_pc_gdp gov_exp_TOT {
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
foreach i in rgdp_pwt popwork rev_inc_sc fm_gov_exp l1avgret flp lp gov_deficit_pc_gdp gov_exp_TOT {
	loc lab: variable label `i'
	gen NEG_`i' = "Negative" if aveP1_`i' < 0
	replace NEG_`i' = "Positive" if aveP1_`i' >= 0 & aveP1_`i'!=.
	label variable NEG_`i' "Is the average 5yr % change in `lab' negative?"
}

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
foreach i in rgdp_pwt rev_inc_sc fm_gov_exp l1avgret flp lp gov_deficit_pc_gdp gov_exp_TOT {
	loc lab: variable label `i'
	foreach num of numlist 1/2 {
		local yr = cond(`num' == 1 , 5, 10)
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

// What were economic growth rates during those five year periods compared to 
// the global (and country income group) average growth?
bysort income year: egen income_aveP1_rgdp_pwt=mean(aveP1_rgdp_pwt)
bysort        year: egen global_aveP1_rgdp_pwt=mean(aveP1_rgdp_pwt)

save "final_derived_labor_growth.dta", replace







// to do --------
// create the dataset BEFORE you start whittling it down for the graphs (do the lag vars for unemployment, govt rev, etc. as well)

// perhaps we want to include some of the shocks in the baker bloom paper?
// add **checks** at the end
// take a look at the labor - growth relationship in the literature?

// one concern about the use of fertility as an IV for number of workers 20-65 is 
// that it doesn't include immigrants *into* a country
// --------------------
// what does the literature say about growth regressions of this sort?

// --------------------
// --------------------
// And adding a bit more:
//
// I’m interested in looking at the impact of negative labor force growth on economies.  Pretty simple stuff at least to begin:
//
// Using the UN population data, find all five-year periods where countries have experienced an absolute decline in their population aged 20-64. (A brief look suggests there are 203 historical cases at the country level).
//
// When did they happen (just a histogram by five year period)? How large the percentage drop in workers (*median* size by five year period)
//
// *median* size by five year period --> what do you mean here? get the median percent worker drop?
//
// What were economic growth rates during those five year periods compared to the (last) (ten year?) period before labor force growth was negative?
//
// What were economic growth rates during those five year periods compared to the global (and country income group) average growth?
// ---------------------------------------------
//
// What happened to government revenues and deficits during those periods compared to prior?
//
// What happened to interest rates and stock market returns?
//
// What happened to the unemployment rate total labor force participation and female labor force participation?
//
// Take out cases which overlap with a country being at war (https://correlatesofwar.org/data-sets) and then take out low and lower middle income countries and see if that makes a difference.
//
// Look forward: according to the UN population forecasts, how many countries in each forthcoming five year period will see declining working age population? How large the percentage drop in workers (*median* size by five year period)
//
// “instrument’ or just use the predicted change in working age population from ten years prior (e.g. us value for population aged 10-54 in 1980 as the value for population aged 20-64 in 1990) and/or try 20 year lag.
//
// Thanks!
