/* This is just a little helper file that calls all the monthly files and stacks the data into single datasets 
It also aggregates everything into the proper format for the recreational bioeconomic model 
It's quite awesome.



Running survey commands on multiple years takes a very long time. 

In order to do a data update, you will need to:

1. run the copy_over_raw_mrip.do to copy and convert the sas7bdat files to dta. 

2. Run get_ma_allocation to get Recreation sites for MA (NORTH SOUTH) and 

3. Change the working year to the most recent year.

	CHECK for missing waves in the "ab1_lengths", catch totals, catch frequencies.
	

	Because there are relatively few observations in FY2020, we decided to use the annual length-frequency distribution. 
	However, we will want to do catch per trip at either the wave or month level.
 */

 
global workdir "${data_main}/MRIP_$vintage_string"
capture mkdir "$workdir"
global my_outputdir "${workdir}/monthly"
capture mkdir "$my_outputdir"






/* readin the 2b95 landings  */
clear
input year 	month 	trimmed_landings
2020 	5   63
2020 	6 	2267
2020 	7 	1465
2020 	8 	3912
2020 	9 	7829
2020 	10 	955
2020 	11 	0
2021 	4 	1434
2021 	5 	10
2021 	6 	517
2021 	7 	61
2021 	8 	258
end
save "${my_outputdir}/atlanticcod_landings_2b95.dta", replace



/*  */


/*Set up the catchlist, triplist, and b2list global macros. These hold the filenames that are needed to figure out the catch, length-frequency, trips, and other things.*/




/********************************************************************************/
/********************************************************************************/
/* loop over calendar years */
/********************************************************************************/
/********************************************************************************/
foreach yr of numlist 2021 2022{
	global working_year `yr'


global wavelist 1 2 3 4 5 6
global species1 "atlanticcod"
global species2 "haddock"
/*this is dumb, but I'm too lazy to replace everything that referred to these local/globals */



/*catchlist -- this assembles then names of files that are needed in the catchlist */
/*Check to see if the file exists */	/* If the file exists, add the filename to the list if there are observations */


global catchlist: dir "${data_raw}" files "catch_$working_year*.dta" 
global triplist: dir "${data_raw}" files "trip_$working_year*.dta" 
global b2list: dir "${data_raw}" files "size_b2_$working_year*.dta" 
global sizelist: dir "${data_raw}" files "size_$working_year*.dta" 


/* catch frequencies per trip*/

/* need to drop 
id_code=="1757420210428005" from the sizelist, triplist, and catchlist. This is a trip that took place inshore in 2020 that caught 2 fish that were probably not cod


id_code="1792820210410001" should be dropped from the triplist catchlist when computing targeted trips. 

no changes to triplist or b2list

The syntax will be to set up a global and then do 
cap drop $drop_conditional after loading in the catchlist or sizelist files

		If we don't need to drop anything, the capture will swallow the error term.
		And if we do, the code will drop the appropriate rows.
*/

global drop_conditional 



foreach sp in atlanticcod haddock{
	global my_common `sp'
	
	if "$my_common"=="atlanticcod"{
	   global drop_conditional `"if id_code=="1757420210428005"  "'
	}
	else {
    global drop_conditional 
	}

	do "${processing_code}/monthly/domain_catch_frequencies_gom_month.do"
}

/* catch totals  -- these are done for all 3 years at once*/

global my_common "atlanticcod"
	if "$my_common"=="atlanticcod"{
	   global drop_conditional `"if  id_code=="1757420210428005"  "'
	}
	else {
		global drop_conditional 
	}

do "${processing_code}/monthly/domain_cod_monthly_catch_totals.do"




/* this is the place to "hack" using the trimmed landings from scott 

read it in and merge.  rename landings old_landings. and rename trim_landings just landings
*/




use "$my_outputdir/atlanticcod_catch_$working_year.dta", clear
keep year month tot_cat claim harvest release
rename claim a
rename harvest b1
rename release b2
rename tot_cat tot_catch
gen landings=a+b1
capture destring month, replace

/*substitute the 2b95 landings for cod in FY 2020 only 
This is May 2020 to April of 2021 only 
*/
if inlist($working_year,2020){
	merge 1:1 year month using  "${my_outputdir}/atlanticcod_landings_2b95.dta", keep(1 3)
replace trimmed_landings=0 if trimmed_landings==. & _merge==1
drop _merge
rename landings landings_old
rename trimmed_landings landings
rename tot_cat tot_cat_old
gen tot_cat=landings+b2
}

/* substitute only for months 1 to 4 */
if inlist($working_year,2021){
	merge 1:1 year month using  "${my_outputdir}/atlanticcod_landings_2b95.dta", keep(1 3)
drop _merge
clonevar landings_old= landings
replace landings= trimmed_landings if inlist(month,1,2,3,4)
rename tot_cat tot_cat_old
gen tot_cat=landings+b2
}


save "$my_outputdir/atlanticcod_landings_$working_year.dta", replace



global my_common "haddock"

	if "$my_common"=="atlanticcod"{
   global drop_conditional `"if  id_code=="1757420210428005"  "'
}
else {
    global drop_conditional 
	}

	
	
do "${processing_code}/monthly/domain_haddock_monthly_catch_totals.do"


use "$my_outputdir/haddock_catch_$working_year.dta", clear
keep year month tot_cat claim harvest release
rename claim a
rename harvest b1
rename release b2
rename tot_cat tot_catch
gen landings=a+b1
capture destring month, replace
save "$my_outputdir/haddock_landings_$working_year.dta", replace










clear

/* length frequencies */



foreach sp in atlanticcod haddock{
	global my_common `sp'
	
	if "$my_common"=="atlanticcod"{
	   global drop_conditional `"if  id_code=="1757420210428005"  "'
}
	else {
    global drop_conditional 
	}

	do "${processing_code}/monthly/length_freqs_by_month_gom.do"
}


/*stack together multiple, cleanup extras and delete */
local cod_wave_ab1: dir "$my_outputdir" files "atlanticcodl_in_bin_a1b1*.dta"

foreach file of local cod_wave_ab1{
	clear
	append using ${my_outputdir}/`file'
	! rm ${my_outputdir}/`file'
}
save "$my_outputdir/cod_ab1_$working_year.dta", replace





/*stack together multiple, cleanup extras and delete */
local haddock_wave_ab1: dir "$my_outputdir" files "haddockl_in_bin_a1b1*.dta"

foreach file of local haddock_wave_ab1{
	clear

	append using ${my_outputdir}/`file'
	! rm ${my_outputdir}/`file'
}
save "$my_outputdir/haddock_ab1_$working_year.dta", replace






/* B2 length frequencies per wave*/
foreach sp in atlanticcod haddock{
	global my_common `sp'
	if "$my_common"=="atlanticcod"{
	   global drop_conditional `"if  id_code=="1757420210428005"  "'
}
	else {
    global drop_conditional 
	}

	do "${processing_code}/monthly/b2_length_freqs_by_month_gom.do"
}




/*stack these into a single dataset */
clear
local cod_wave_b2: dir "$my_outputdir" files "atlanticcodl_in_bin_b2*.dta"
local haddock_wave_b2: dir "$my_outputdir" files "haddockl_in_bin_b2*.dta"

	clear

foreach file of local cod_wave_b2{
	append using ${my_outputdir}/`file'
	! rm ${my_outputdir}/`file'
}
keep if year==$working_year

capture destring month, replace
save "$my_outputdir/cod_b2_$working_year.dta", replace
	clear

foreach file of local haddock_wave_b2{
	append using ${my_outputdir}/`file'
	! rm ${my_outputdir}/`file'
}

capture destring month, replace
keep if year==$working_year

save "$my_outputdir/haddock_b2_$working_year.dta", replace




/* join the b2 length data with the total number of released to get the length distribution for the number of fish released */
do "${processing_code}/monthly/process_b2_cod.do"
do "${processing_code}/monthly/process_b2_haddock.do"




global drop_conditional `"if (id_code=="1792820210410001" | id_code=="1757420210428005")  "'


/* caught/targeted haddock or caught cod by wave */
do "${processing_code}/monthly/haddock_plus_directed_trips_by_month.do"



/* caught/targeted cod or haddock by wave */

do "${processing_code}/monthly/cod_haddock_directed_trips_by_month.do"

/* caught/targeted cod by wave */
do "${processing_code}/monthly/cod_directed_trips_by_month.do"


/* caught/targeted haddock by wave */
do "${processing_code}/monthly/haddock_directed_trips_by_month.do"








/* caught/targeted haddock or caught cod by wave */
do "${processing_code}/monthly/cod_monthly_weight_ab1b2.do"



/* caught/targeted haddock or caught cod by wave */
do "${processing_code}/monthly/haddock_monthly_weight_ab1b2.do"



}


