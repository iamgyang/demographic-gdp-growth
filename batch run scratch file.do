cd "C:/Users/`c(username)'/Dropbox/CGD/Projects/dem_neg_labor/code"
pause off
do "0 master.do"
do "1 clean_all.do"
do "2 merge and checks.do"
do "3 analysis - HIC event.do"
do "3 analysis - table.do"

// run like so:
// cd "C:\Users\gyang\Dropbox\CGD GlobalSat\HF_measures\input"
// "C:\Program Files\Stata16\StataMP-64.exe"  /e do "C:\Users\gyang\Dropbox\CGD GlobalSat\HF_measures\code\00 batch run scratch file.do"
