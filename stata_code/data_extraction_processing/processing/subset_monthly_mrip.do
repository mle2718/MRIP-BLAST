/* This do file is the final data prep for the BLAST model */

pause off

*global stacked_month "${data_main}/MRIP_$vintage_string/stacked_monthly"

global hmin 17
global cmin 22



/* which fishing year do you want */
local yr1 $this_working_year 

local lastyr=`yr1'-1



/***********************************************************************************************/
/***********************************************************************************************/
/***********************************CATCH CLASSSES *********************************************/
/***********************************************************************************************/
/***********************************************************************************************/

/*******************BEGIN COD **************************************/

/*Load in the stacked monthly catch class distributions*/
use ${stacked_month}/monthly_cod_catch_class.dta, replace

keep if fishing_year==`yr1'



local months 1 2 3 4 5 6 7 8 9 10 11 12
levelsof month, local(existing)
local need: list months-existing
local expand: word count `need'
di "You have months `existing'. If this is not contiguous, this code will break horribly.  You need to fill in months `need'."  
pause


qui summ month
local first =r(min)
local last =r(max)

/* this only works if there are missing months at the beginning or end, not in the middle */
/* we borrow from the previous year if we are missing data */

use ${stacked_month}/monthly_cod_catch_class.dta, replace
keep if fishing_year==`lastyr'
keep if month<`first '| month>`last'
replace fishing_year=`yr1'
tempfile fillin
save `fillin', replace

use ${stacked_month}/monthly_cod_catch_class.dta, replace
append using `fillin'

tempfile partial
save `partial', replace

keep if fishing_year==`yr1'

qui summ month
local first =r(min)
local last =r(max)

/* Sometimes we don't have recent enough data, or no data at all. When this happens, we fill in data from other months
drop older data 
*/

/* how many months do I need to fill in? */
local months 1 2 3 4 5 6 7 8 9 10 11 12
levelsof month, local(existing)
local need: list months-existing
local expand: word count `need'
di "You have months `existing'. If this is not contiguous, this code will break horribly.  You need to fill in months `need'."  
pause

/* use the data at the ends (say months 4 and 11) to fill in for the missing months 1 2 3 and 12 
This will break pretty badly if there are missing months inside */
preserve
keep if inlist(month,`first',`last')
collapse (sum) count, by(tot_cat)
replace count=count/2
expand `expand'
sort tot_cat
egen month=fill(`need' `need')
gen fishing_year=`yr1' 
tempfile tt
save `tt'
restore
append using `tt'
sort month tot_cat count
rename tot_cat num_fish
xtset month num_fish
save "${BLAST_DIR}/cod_catch_class`yr1'.dta", replace
replace count=count/1000
label var count "count 1000s"
xtline count
graph export "${my_images_vintage}/cod_catch_class_`yr1'.tif", as(tif) replace

xtline count if num_fish>0
graph export "${my_images_vintage}/cod_catch_classno0_`yr1'.tif", as(tif) replace



bysort month: egen tc=total(count)
gen prob=count/tc
xtline prob
graph export "${my_images_vintage}/cod_catch_classP_`yr1'.tif", as(tif) replace
xtline prob if num_fish>0
graph export "${my_images_vintage}/cod_catch_classPno0_`yr1'.tif", as(tif) replace


/*******************END COD **************************************/







/*******************BEGIN HADDOCK **************************************/

/*Load in the stacked monthly catch class distributions*/
use ${stacked_month}/monthly_haddock_catch_class.dta, replace

keep if fishing_year==`yr1'



local months 1 2 3 4 5 6 7 8 9 10 11 12
levelsof month, local(existing)
local need: list months-existing
local expand: word count `need'
di "You have months `existing'. If this is not contiguous, this code will break horribly.  You need to fill in months `need'."  
pause





qui summ month
local first =r(min)
local last =r(max)

/* this only works if there are missing months at the beginning or end, not in the middle */
/* we borrow from the previous year if we are missing data */

use ${stacked_month}/monthly_haddock_catch_class.dta, replace
keep if fishing_year==`lastyr'
keep if month<`first '| month>`last'
replace fishing_year=`yr1'
tempfile fillin
save `fillin', replace

use ${stacked_month}/monthly_haddock_catch_class.dta, replace
append using `fillin'

tempfile partial
save `partial', replace

keep if fishing_year==`yr1'

qui summ month
local first =r(min)
local last =r(max)

/* Sometimes we don't have recent enough data, or no data at all. When this happens, we fill in data from other months
drop older data 
*/

/* how many months do I need to fill in? */
local months 1 2 3 4 5 6 7 8 9 10 11 12
levelsof month, local(existing)
local need: list months-existing
local expand: word count `need'
di "You have months `existing'. If this is not contiguous, this code will break horribly.  You need to fill in months `need'."  
pause

/* use the data at the ends (say months 4 and 11) to fill in for the missing months 1 2 3 and 12 
This will break pretty badly if there are missing months inside */
preserve
keep if inlist(month,`first',`last')
collapse (sum) count, by(tot_cat)
replace count=count/2
expand `expand'
sort tot_cat
egen month=fill(`need' `need')
gen fishing_year=`yr1' 
tempfile tt
save `tt'
restore
append using `tt'
sort month tot_cat count
rename tot_cat num_fish
xtset month num_fish
save "${BLAST_DIR}/haddock_catch_class`yr1'.dta", replace
replace count=count/1000
label var count "count 1000s"
xtline count
graph export "${my_images_vintage}/haddock_catch_class_`yr1'.tif", as(tif) replace


xtline count if num_fish>0
graph export "${my_images_vintage}/haddock_catch_classno0_`yr1'.tif", as(tif) replace


bysort month: egen tc=total(count)
gen prob=count/tc
xtline prob
graph export "${my_images_vintage}/haddock_catch_classP_`yr1'.tif", as(tif) replace

xtline prob if num_fish>0
graph export "${my_images_vintage}/haddock_catch_classPno0_`yr1'.tif", as(tif) replace

/*******************END HADDOCK **************************************/



















/***********************************************************************************************/
/***********************************************************************************************/
/***********************************SIZE CLASSSES *********************************************/
/***********************************************************************************************/
/***********************************************************************************************/




/*******************BEGIN COD **************************************/


/*read in the size class distributions. Keep just the relevant FY. */
use ${stacked_month}/monthly_cod_size_class.dta, replace




keep if fishing_year==`yr1'


/* figure out which months can be borrowed from the previous fishing year */
local months 1 2 3 4 5 6 7 8 9 10 11 12
levelsof month, local(existing)
local need: list months-existing
local expand: word count `need'
di "You have months `existing'. If this is not contiguous, this code will break horribly.  You need to fill in months `need'."  
pause


qui summ month
local first =r(min)
local last =r(max)






/* this only works if there are missing months at the beginning or end, not in the middle */
/* we borrow from the previous year if we are missing data */

use ${stacked_month}/monthly_cod_size_class.dta, replace
keep if fishing_year==`lastyr'
keep if month<`first '| month>`last'

bysort fishing_year month: drop if _N<=5

replace fishing_year=`yr1'
tempfile fillin
save `fillin', replace

use ${stacked_month}/monthly_cod_size_class.dta, replace
append using `fillin'

tempfile partial
save `partial', replace

keep if fishing_year==`yr1'

qui summ month
local first =r(min)
local last =r(max)

/* Sometimes we don't have recent enough data, or no data at all. When this happens, we fill in data from other months
drop older data 
*/

/* how many months do I need to fill in? */
local months 1 2 3 4 5 6 7 8 9 10 11 12
levelsof month, local(existing)
local need: list months-existing
local expand: word count `need'

di "You have months `existing'. If this is not contiguous, this code will break horribly.  You need to fill in months `need'."  
pause



/* use the data at the ends (say months 4 and 11) to fill in for the missing months 1 2 3 and 12 
This will break pretty badly if there are missing months inside */
preserve
keep if inlist(month,`first',`last')
collapse (sum) count, by(lngcatinches)
replace count=count/2
expand `expand'
sort lngcatinches
egen month=fill(`need' `need')
gen fishing_year=`yr1' 
tempfile tt
save `tt'
restore
append using `tt'




collapse (sum) count, by(month lngcat fishing_year)
xtset month lng
save "${BLAST_DIR}/cod_size_class`yr1'.dta", replace

replace count=count/1000
label var count "count 1000s"
xtline count, xline($cmin)
graph export  "${my_images_vintage}/cod_size_class`yr1'.tif", as(tif) replace


bysort month: egen tc=total(count)
gen prob=count/tc
xtline prob, xline($cmin)
graph export "${my_images_vintage}/cod_size_classP_`yr1'.tif", as(tif) replace


/*******************END COD **************************************/



/*******************BEGIN HADDOCK **************************************/


/*read in the size class distributions. Keep just the relevant FY. */
use ${stacked_month}/monthly_haddock_size_class.dta, replace




keep if fishing_year==`yr1'

/* figure out which months can be borrowed from the previous fishing year */
local months 1 2 3 4 5 6 7 8 9 10 11 12
levelsof month, local(existing)
local need: list months-existing
local expand: word count `need'
di "You have months `existing'. If this is not contiguous, this code will break horribly.  You need to fill in months `need'."  
pause


qui summ month
local first =r(min)
local last =r(max)






/* this only works if there are missing months at the beginning or end, not in the middle */
/* we borrow from the previous year if we are missing data */

use ${stacked_month}/monthly_haddock_size_class.dta, replace
keep if fishing_year==`lastyr'
keep if month<`first '| month>`last'

bysort fishing_year month: drop if _N<=5

replace fishing_year=`yr1'
tempfile fillin
save `fillin', replace

use ${stacked_month}/monthly_haddock_size_class.dta, replace
append using `fillin'

tempfile partial
save `partial', replace

keep if fishing_year==`yr1'

qui summ month
local first =r(min)
local last =r(max)

/* Sometimes we don't have recent enough data, or no data at all. When this happens, we fill in data from other months
drop older data 
*/

/* how many months do I need to fill in? */
local months 1 2 3 4 5 6 7 8 9 10 11 12
levelsof month, local(existing)
local need: list months-existing
local expand: word count `need'

di "You have months `existing'. If this is not contiguous, this code will break horribly.  You need to fill in months `need'."  
pause



/* use the data at the ends (say months 4 and 11) to fill in for the missing months 1 2 3 and 12 
This will break pretty badly if there are missing months inside */
preserve
keep if inlist(month,`first',`last')
collapse (sum) count, by(lngcatinches)
replace count=count/2
expand `expand'
sort lngcatinches
egen month=fill(`need' `need')
gen fishing_year=`yr1' 
tempfile tt
save `tt'
restore
append using `tt'




collapse (sum) count, by(month lngcat fishing_year)
xtset month lng
save "${BLAST_DIR}/haddock_size_class`yr1'.dta", replace

replace count=count/1000
label var count "count 1000s"
xtline count, xline($hmin)

graph export  "${my_images_vintage}/haddock_size_class`yr1'.tif", as(tif) replace


bysort month: egen tc=total(count)
gen prob=count/tc
xtline prob, xline($hmin)
graph export "${my_images_vintage}/haddock_size_classP_`yr1'.tif", as(tif) replace

