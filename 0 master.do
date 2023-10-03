// Macros ----------------------------------------------------------------

clear all 
set more off
set varabbrev off
set scheme s1mono
set type double, perm

// CHANGE THIS!! --- Define your own directories:
foreach user in "`c(username)'" {
	if "`user'" == "zgehan" {
		global root "C:/Users/zgehan/CGD Education Dropbox/Zachary Gehan/80 Inherited Folders/dem_neg_labor"
		global output "C:/Users/zgehan/CGD Education Dropbox/Zachary Gehan/Apps/Overleaf/Demographic Labor"
	} 
	else {
		global root "C:/Users/`user'/Dropbox/CGD/Projects/dem_neg_labor"
		global output "C:/Users/`user'/Dropbox/Apps/Overleaf/Demographic Labor"
	}
}

global code        "$root/labor-growth"
global input       "$root/input"

global check       "no"
global test_run  	0
global DROP_CPI_OUTLIERS = 0 

// CHANGE THIS!! --- Do we want to install user-defined functions? 1 if yes, 0 if no.
loc install_user_defined_functions = 0

if (`install_user_defined_functions' == 1) {
	foreach i in texsave rangestat wbopendata kountry mmerge outreg2 somersd ///
	asgen moss reghdfe ftools fillmissing gtools filelist {
		capture quietly ssc install `i'
	}
} 


* Temporary ZG: 
* Regress growth = constant + (period start share of working age population) + (dummy for negative population growth)
** gen growth variable, rgdppc_pwt_t / rgdppc_pwt_t-1
** I don't see a variable for share of working age pop, so I'll make one. 
** The dummy for negative population growth is NEG_popwork
use "${root}/input/final_derived_labor_growth.dta"

bys iso3c (year): gen rgdppc_growth = rgdppc_pwt / rgdppc_pwt[_n - 1]
gen rgdppc_growth_pct = 100 * (rgdppc_growth - 1)

gen workage_frac = popwork / poptotal
gen workage_pct = workage_frac * 100

bys iso3c (year): gen popgrowth = poptotal - poptotal[_n - 1]
gen neg_popgrowth_dum = (popgrowth < 0)

reg rgdppc_growth_pct workage_pct neg_popgrowth_dum


