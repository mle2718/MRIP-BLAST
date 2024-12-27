/* 
This probably isn't doing everything we need it to do

Need to read in the 2b95 landings.  Doesn't loop over years

we probably won' use this anymore




This is just a little helper file that calls all the yearly files and stacks the wave-level data into single datasets 
It also aggregates everything into the proper format for the recreational bioeconomic model 
It's quite awesome.


Running survey commands on multiple years takes a very long time. 

In order to do a data update, you will need to:

1. run the copy_over_raw_mrip.do to copy and convert the sas7bdat files to dta. 

2. Run get_ma_allocation to get Recreation sites for MA (NORTH SOUTH) and 

3. Change the working year to the most recent year.

	CHECK for missing waves in the "ab1_lengths", catch totals, catch frequencies.
 */

 
global my_outputdir "${data_main}/MRIP_$vintage_string/annual"
capture mkdir "$my_outputdir"
 
/*Set up the catchlist, triplist, and b2list global macros. These hold the filenames that are needed to figure out the catch, length-frequency, trips, and other things.*/



/********************************************************************************/
/********************************************************************************/
/* Use these to control the years and species for which the MRIP data is polled/queried*/
/********************************************************************************/
/********************************************************************************/
global working_year  2023
global working_year  2024

local year $working_year
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


	do "${processing_code}/annual/domain_catch_frequencies_gom_annual.do"
	clear
}




/* catch totals  -- these are done for all 3 years at once*/

global my_common "atlanticcod"

	
	if "$my_common"=="atlanticcod"{
	   global drop_conditional `"if id_code=="1757420210428005"  "'
	}
	else {
    global drop_conditional 
	}


do "${processing_code}/annual/domain_cod_annual_catch_totals.do"


use "$my_outputdir/atlanticcod_catch_annual_$working_year.dta", clear
keep year tot_cat claim harvest release
rename claim a
rename harvest b1
rename release b2
rename tot_cat tot_catch
gen landings=a+b1
save "$my_outputdir/atlanticcod_landings_annual_$working_year.dta", replace
global my_common "haddock"
	
	if "$my_common"=="atlanticcod"{
	   global drop_conditional `"if id_code=="1757420210428005"  "'
	}
	else {
    global drop_conditional 
	}


do "${processing_code}/annual/domain_haddock_annual_catch_totals.do"





use "$my_outputdir/haddock_catch_annual_$working_year.dta", clear
keep year tot_cat claim harvest release
rename claim a
rename harvest b1
rename release b2
rename tot_cat tot_catch
gen landings=a+b1
save "$my_outputdir/haddock_landings_annual_$working_year.dta", replace









clear

/* length frequencies */



foreach sp in atlanticcod haddock{
	global my_common `sp'
	
		
	if "$my_common"=="atlanticcod"{
	   global drop_conditional `"if id_code=="1757420210428005"  "'
	}
	else {
    global drop_conditional 
	}


	do "${processing_code}/annual/length_freqs_by_year_gom.do"
	clear
}


/*stack together multiple, cleanup extras and delete */
local cod_wave_ab1: dir "$my_outputdir" files "atlanticcodl_in_bin_a1b1_annual*.dta"

foreach file of local cod_wave_ab1{
	clear
	append using ${my_outputdir}/`file'
	! rm ${my_outputdir}/`file'
}
save "$my_outputdir/cod_ab1_annual_$working_year.dta", replace






/*stack together multiple, cleanup extras and delete */
local haddock_wave_ab1: dir "$my_outputdir" files "haddockl_in_bin_a1b1_annual*.dta"

foreach file of local haddock_wave_ab1{
	clear

	append using ${my_outputdir}/`file'
	! rm ${my_outputdir}/`file'
}
save "$my_outputdir/haddock_ab1_annual_$working_year.dta", replace


/* B2 length frequencies per wave*/
foreach sp in atlanticcod haddock{
	global my_common `sp'
	
		
	if "$my_common"=="atlanticcod"{
	   global drop_conditional `"if id_code=="1757420210428005"  "'
	}
	else {
    global drop_conditional 
	}


	do "${processing_code}/annual/b2_length_freqs_by_year_gom.do"
}




/*stack these into a single dataset */
clear
local cod_wave_b2: dir "$my_outputdir" files "atlanticcodl_in_bin_b2_annual*.dta"
local haddock_wave_b2: dir "$my_outputdir" files "haddockl_in_bin_b2_annual_*.dta"

clear
foreach file of local cod_wave_b2{
	
	append using ${my_outputdir}/`file'
	! rm ${my_outputdir}/`file'
}


save "$my_outputdir/cod_b2_annual_$working_year.dta", replace
	clear
foreach file of local haddock_wave_b2{

	append using ${my_outputdir}/`file'
	! rm ${my_outputdir}/`file'
}

save "$my_outputdir/haddock_b2_annual_$working_year.dta", replace



/*need to edit both of these to point to "annual" data files
I think the haddock one wokrs, just need to pull over the changes to the cod one.
*/
/* join the b2 length data with the total number of released to get the length distribution for the number of fish released */
do "${processing_code}/annual/process_b2_haddock_annual.do"



do "${processing_code}/annual/process_b2_cod_annual.do"



do "${processing_code}/annual/cod_haddock_directed_trips_annual.do"




global drop_conditional `"if id_code=="1792820210410001"  "'
