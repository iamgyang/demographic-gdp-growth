// Macros ----------------------------------------------------------------

clear all 
set more off
set varabbrev off
set scheme s1mono
set type double, perm

// CHANGE THIS!! --- Define your own directories:
foreach user in "`c(username)'" {
	global root "C:/Users/`user'/Dropbox/CGD/Projects/dem_neg_labor"
	global output "C:/Users/`user'/Dropbox/Apps/Overleaf/Demographic Labor"
}

global code        "$root/code"
global input       "$root/input"
global check       "no"
global test_run  	0

// CHANGE THIS!! --- Do we want to install user-defined functions?
loc install_user_defined_functions "No"

if ("`install_user_defined_functions'" == "Yes") {
	foreach i in rangestat wbopendata kountry mmerge outreg2 somersd ///
	asgen moss reghdfe ftools fillmissing gtools {
		capture quietly ssc install `i'
	}
}

