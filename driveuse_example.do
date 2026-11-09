* driveuse_example.do -- typical calls (the file names are placeholders;
* point them at files that exist on your shared drive before running).

* Set $driveuse and $sf only
driveuse
display "`r(path)'"

* Basic load
driveuse "test.dta", clear
driveuse "test.dta" if rep78 == 2, clear

* With subdirectory
driveuse "project/data/survey.dta", clear

* Load specific variables only
driveuse id age income using "survey.dta", clear

* With if condition and without value labels
driveuse "survey.dta" if year == 2024, clear nolabel

* The globals work with any command
use `"${sf}/test.dta"', clear
use `"${driveuse}/_datarepository/test.dta"', clear
