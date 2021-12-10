/* This do file is the final data prep for the BLAST model */

pause off

global stacked_dir "${data_main}/MRIP_$vintage_string/stacked_monthly"
global BLAST_DIR "${BLAST_root}/cod_haddock_fy2022/source_data/mrip"



/* which fishing year do you want */
local yr1 2021 
local lastyr=`yr1'-1

/***********************************************************************************************/
/***********************************************************************************************/
/***********************************CATCH CLASSSES *********************************************/
/***********************************************************************************************/
/***********************************************************************************************/

/*******************BEGIN COD **************************************/

/*Load in the stacked monthly catch class distributions*/
use ${stacked_dir}/monthly_cod_catch_class.dta, replace

keep if fishing_year==`yr1'

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

save "${BLAST_DIR}/cod_catch_class_ANNUAL_`yr1'.dta", replace
replace count=count/1000
label var count "count 1000s"
xtline count
graph export "${my_images}/cod_catch_class_ANNUAL_`yr1'.tif", as(tif) replace

/*******************END COD **************************************/









/*******************BEGIN HADDOCK **************************************/

/*Load in the stacked monthly catch class distributions*/
use ${stacked_dir}/monthly_haddock_catch_class.dta, replace

keep if fishing_year==`yr1'

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
graph export "${my_images}/haddock_catch_class_ANNUAL_`yr1'.tif", as(tif) replace


/*******************END HADDOCK **************************************/



















/***********************************************************************************************/
/***********************************************************************************************/
/***********************************SIZE CLASSSES *********************************************/
/***********************************************************************************************/
/***********************************************************************************************/




/*******************BEGIN COD **************************************/


/*read in the size class distributions. Keep just the relevant FY. Collapse*/
use ${stacked_dir}/monthly_cod_size_class.dta, replace
keep if fishing_year==`yr1'
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
xtline count
graph export  "${my_images}/cod_size_class_ANNUAL`yr1'.tif", as(tif) replace




/*******************END COD **************************************/



/*******************BEGIN HADDOCK **************************************/


/*read in the size class distributions. Keep just the relevant FY. Collapse*/
use ${stacked_dir}/monthly_haddock_size_class.dta, replace
keep if fishing_year==`yr1'
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
xtline count
graph export  "${my_images}/haddock_size_class_ANNUAL`yr1'.tif", as(tif) replace

label var count "count 1000s"
xtline count
graph export  "${my_images}/haddock_size_class`yr1'.tif", as(tif) replace



