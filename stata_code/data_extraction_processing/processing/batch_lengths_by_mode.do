/* Compute lengths by grouped_mode

a, b1, b2 by for (ForHire=Party+charter and Private=Private+shore)

*/

 
global workdir "${data_main}/MRIP_$vintage_string"
capture mkdir "$workdir"
global my_outputdir "${workdir}/mode"
capture mkdir "$my_outputdir"






/*  */


/*Set up the catchlist, triplist, and b2list global macros. These hold the filenames that are needed to figure out the catch, length-frequency, trips, and other things.*/




/********************************************************************************/
/********************************************************************************/
/* loop over calendar years */
/********************************************************************************/
/********************************************************************************/
foreach yr of global process_list {
	global working_year `yr'
	global previous_year=$working_year-1

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

	do "${processing_code}/mode/domain_catch_mode_frequencies_gom_month.do"
}

/* catch totals  -- these are done for all 3 years at once*/

global my_common "atlanticcod"
	if "$my_common"=="atlanticcod"{
	   global drop_conditional `"if  id_code=="1757420210428005"  "'
	}
	else {
		global drop_conditional 
	}

do "${processing_code}/mode/domain_cod_mode_monthly_catch_totals.do"




/* this is the place to "hack" using the trimmed landings from scott 

read it in and merge.  rename landings old_landings. and rename trim_landings just landings
*/




use "$my_outputdir/atlanticcod_catch_mode_$working_year.dta", clear
keep year month mode tot_cat claim harvest release
rename claim a
rename harvest b1
rename release b2
rename tot_cat tot_catch
gen landings=a+b1
capture destring month, replace


save "$my_outputdir/atlanticcod_landings_mode_$working_year.dta", replace



global my_common "haddock"

	if "$my_common"=="atlanticcod"{
   global drop_conditional `"if  id_code=="1757420210428005"  "'
}
else {
    global drop_conditional 
	}

	
	
do "${processing_code}/mode/domain_haddock_mode_monthly_catch_totals.do"


use "$my_outputdir/haddock_catch_mode_$working_year.dta", clear
keep year month mode tot_cat claim harvest release
rename claim a
rename harvest b1
rename release b2
rename tot_cat tot_catch
gen landings=a+b1
capture destring month, replace
save "$my_outputdir/haddock_landings_mode_$working_year.dta", replace








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

	do "${processing_code}/mode/length_freqs_by_mode_month_gom.do"
}


/*stack together multiple, cleanup extras and delete */
local cod_wave_ab1: dir "$my_outputdir" files "atlanticcodl_in_bin_mode_a1b1*.dta"

clear
foreach file of local cod_wave_ab1{
	append using ${my_outputdir}/`file'
	! rm ${my_outputdir}/`file'
}
keep if year==$working_year
save "$my_outputdir/cod_ab1_mode_$working_year.dta", replace





/*stack together multiple, cleanup extras and delete */
local haddock_wave_ab1: dir "$my_outputdir" files "haddockl_in_bin_mode_a1b1*.dta"
clear
foreach file of local haddock_wave_ab1{
	append using ${my_outputdir}/`file'
	! rm ${my_outputdir}/`file'
}
keep if year==$working_year

save "$my_outputdir/haddock_ab1_mode_$working_year.dta", replace






/* B2 length frequencies per wave*/
foreach sp in atlanticcod haddock{
	global my_common `sp'
	if "$my_common"=="atlanticcod"{
	   global drop_conditional `"if  id_code=="1757420210428005"  "'
}
	else {
    global drop_conditional 
	}

	do "${processing_code}/mode/b2_length_freqs_by_mode_month_gom.do"
}




/*stack the weighted B2s into a single dataset */
clear
local cod_wave_b2: dir "$my_outputdir" files "atlanticcodl_in_bin_mode_b2*.dta"
local haddock_wave_b2: dir "$my_outputdir" files "haddockl_in_bin_mode_b2*.dta"

	clear

foreach file of local cod_wave_b2{
	append using ${my_outputdir}/`file'
	! rm ${my_outputdir}/`file'
}
keep if year==$working_year

capture destring month, replace
save "$my_outputdir/cod_b2_mode_$working_year.dta", replace
	clear

foreach file of local haddock_wave_b2{
	append using ${my_outputdir}/`file'
	! rm ${my_outputdir}/`file'
}

capture destring month, replace
keep if year==$working_year

save "$my_outputdir/haddock_b2_mode_$working_year.dta", replace


/* this should work up to here */


/* join the b2 length data with the total number of released to get the length distribution for the number of fish released */
do "${processing_code}/mode/process_b2_mode_cod.do"
do "${processing_code}/mode/process_b2_mode_haddock.do"

}




