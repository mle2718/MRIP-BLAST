/* This do file is the final data prep for the BLAST model 

Convert the monthly data to fishing-year data. We always substitute "non-available" from the previous year when necessary. This usually means Nov, Dec, Jan, Feb, Mar, April 

*/

pause off

global stacked_dir "${data_main}/MRIP_$vintage_string/stacked_monthly"
global BLAST_DIR "${BLAST_root}/cod_haddock_fy2023/source_data/mrip"

global my_images_vintage "${my_images}/MRIP_$vintage_string"
cap mkdir $my_images_vintage

global hmin 17
global cmin 22


/* which fishing year do you want */
*local yr1 2021 
local yr1 $this_working_year 

local lastyr=`yr1'-1

/***********************************************************************************************/
/***********************************************************************************************/
/***********************************CATCH CLASSSES *********************************************/
/***********************************************************************************************/
/***********************************************************************************************/

/*******************BEGIN COD **************************************/

/*Load in the stacked monthly catch class distributions*/
use ${stacked_dir}/monthly_cod_catch_class.dta, replace



keep if fishing_year==`yr1' | (fishing_year==`lastyr' & inlist(month,1,2,3,4,11,12))
replace fishing_year=`yr1'
/* annual totals */
collapse (sum) count, by(tot_cat fishing_year)
/* expand so there is one set of obs per month */
expand 12
sort fishing_year tot_cat count
bysort fishing_year tot_cat: gen month=_n

sort month tot_cat count
rename tot_cat num_fish
xtset month num_fish
/* save the raw nums to the BLAST source_data directory and then make a graph */

save "${BLAST_DIR}/cod_catch_class_ANNUAL`yr1'.dta", replace
replace count=count/1000
label var count "count 1000s"
xtline count
graph export "${my_images_vintage}/cod_catch_class_ANNUAL`yr1'.tif", as(tif) replace

xtline count if num_fish>0
graph export "${my_images_vintage}/cod_catch_class_no0_ANNUAL`yr1'.tif", as(tif) replace


bysort month: egen tc=total(count)
gen prob=count/tc
xtline prob
graph export "${my_images_vintage}/cod_catch_classP_ANNUAL`yr1'.tif", as(tif) replace
xtline prob if num_fish>0
graph export "${my_images_vintage}/cod_catch_classPno0_ANNUAL`yr1'.tif", as(tif) replace


/*******************END COD **************************************/









/*******************BEGIN HADDOCK **************************************/

/*Load in the stacked monthly catch class distributions*/
use ${stacked_dir}/monthly_haddock_catch_class.dta, replace



keep if fishing_year==`yr1' | (fishing_year==`lastyr' & inlist(month,1,2,3,4,11,12))
replace fishing_year=`yr1'
/* annual totals */
collapse (sum) count, by(tot_cat fishing_year)
/* expand so there is one set of obs per month */
expand 12
sort fishing_year tot_cat count
bysort fishing_year tot_cat: gen month=_n

sort month tot_cat count
rename tot_cat num_fish
xtset month num_fish


/* save the raw nums to the BLAST source_data directory and then make a graph */

save "${BLAST_DIR}/haddock_catch_class_ANNUAL`yr1'.dta", replace
replace count=count/1000
label var count "count 1000s"
xtline count
graph export "${my_images_vintage}/haddock_catch_class_ANNUAL`yr1'.tif", as(tif) replace

xtline count if num_fish>0
graph export "${my_images_vintage}/haddock_catch_class_no0_ANNUAL`yr1'.tif", as(tif) replace


bysort month: egen tc=total(count)
gen prob=count/tc
xtline prob
graph export "${my_images_vintage}/haddock_catch_classP_ANNUAL`yr1'.tif", as(tif) replace

xtline prob if num_fish>0
graph export "${my_images_vintage}/haddock_catch_classPno0_ANNUAL`yr1'.tif", as(tif) replace

/*******************END HADDOCK **************************************/



















/***********************************************************************************************/
/***********************************************************************************************/
/***********************************SIZE CLASSSES *********************************************/
/***********************************************************************************************/
/***********************************************************************************************/




/*******************BEGIN COD **************************************/


/*read in the size class distributions. Keep just the relevant FY. Collapse*/
use ${stacked_dir}/monthly_cod_size_class.dta, replace


keep if fishing_year==`yr1' | (fishing_year==`lastyr' & inlist(month,1,2,3,4,11,12))
replace fishing_year=`yr1'
collapse (sum) count, by(lngcat fishing_year)

/* expand so there is one set of obs per month */
expand 12
sort fishing_year lngcat count
bysort fishing_year lngcat: gen month=_n


xtset month lng

/* save the raw nums to the BLAST source_data directory and then make a graph */

save "${BLAST_DIR}/cod_size_class_ANNUAL`yr1'.dta", replace

replace count=count/1000
label var count "count 1000s"
xtline count, xline($cmin)
graph export  "${my_images_vintage}/cod_size_class_ANNUAL`yr1'.tif", as(tif) replace



bysort month: egen tc=total(count)
gen prob=count/tc
xtline prob, xline($cmin)
graph export "${my_images_vintage}/cod_size_classP_ANNUAL`yr1'.tif", as(tif) replace

/*******************END COD **************************************/



/*******************BEGIN HADDOCK **************************************/


/*read in the size class distributions. Keep just the relevant FY. Collapse*/
use ${stacked_dir}/monthly_haddock_size_class.dta, replace


keep if fishing_year==`yr1' | (fishing_year==`lastyr' & inlist(month,1,2,3,4,11,12))
replace fishing_year=`yr1'

collapse (sum) count, by(lngcat fishing_year)

/* expand so there is one set of obs per month */
expand 12
sort fishing_year lngcat count
bysort fishing_year lngcat: gen month=_n



xtset month lng
/* save the raw nums to the BLAST source_data directory and then make a graph */

save "${BLAST_DIR}/haddock_size_class_ANNUAL`yr1'.dta", replace

replace count=count/1000
label var count "count 1000s"
xtline count, xline($hmin)
graph export  "${my_images_vintage}/haddock_size_class_ANNUAL`yr1'.tif", as(tif) replace



bysort month: egen tc=total(count)
gen prob=count/tc
xtline prob, xline($hmin)
graph export "${my_images_vintage}/haddock_size_classP_ANNUAL`yr1'.tif", as(tif) replace

