*cd "C:/Users/`c(username)'/Dropbox/CGD/Projects/dem_neg_labor/labor-growth"
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
global scripts "${root}/labor-growth"

pause off
do "${scripts}/0 master.do"
do "${scripts}/0 programs and functions.do"
do "${scripts}/1 clean_all.do"
do "${scripts}/2.00 merge and checks.do"
do "${scripts}/2.01 summary table.do"
e
do "${scripts}/3.02 analysis - HIC event.do"
do "${scripts}/3.03 analysis - table.do"

// run like so:
// cd "C:\Users\gyang\Dropbox\CGD GlobalSat\HF_measures\input"
// "C:\Program Files\Stata16\StataMP-64.exe"  /e do "C:\Users\gyang\Dropbox\CGD GlobalSat\HF_measures\code\00 batch run scratch file.do"
