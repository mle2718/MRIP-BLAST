/* This is just a little helper file that calls all the yearly files and stacks the wave-level data into single datasets 
It also aggregates everything into the proper format for the recreational bioeconomic model 
It's quite awesome.


Running survey commands on multiple years takes a very long time. 

In order to do a data update, you will need to do a few things

1. Get and convert the .sas7bdat files from scott's directory.  

  The command for batch files is simply copy *.sas7bdat *.dta

   trip_yyyyw.dta
   catch_yyyyw.dta
   size_yyyyw.dta
   size_b2_yyyyw.dta
2. Get the updated classifcation of Recreation sites for MA (NORTH SOUTH) and 


3. do the following data cleaning:  

///******/

///******/


4.  Update the code to include more years and waves.  
AAAAAAAAAAAAAAAA	
	domain_cod_catch_totals   -- add new years and waves to the global at the beginning of the files
	domain_haddock_catch_totals --  add new years and waves to the global

BBBBBBBBBBBBB
	domain_catch_frequencies_gom_cod_wave_YYYY_update  -- make a new file with 2014 and waves at the beginning of the files
	domain_catch_frequencies_gom_haddock_wave_YYYY_update
	
	add this into the dsconcat "stacks"
	
CCCCCCCCCCCCCCCC
	cod_length_freqs_by_wave_gom_YYYY  -- make a new file with 2014 and waves at the beginning of the files
	haddock_length_freqs_by_wave_gom_YYYY

	b2cod_length_freqs_by_wave_gom_YYYY  --  make a new file with 2014 and waves at the beginning of the files
	b2haddock_length_freqs_by_wave_gom_YYYY
	
	add this into the dsconcat "stacks"


	CHECK for missing waves in the "ab1_lengths", catch totals, catch frequencies.
 */
/*Set up the catchlist, triplist, and b2list global macros. These hold the filenames that are needed to figure out the catch, length-frequency, trips, and other things.*/

cd "/home/mlee/Documents/Workspace/MRIP_working/source files"
global my_codedir "/home/mlee/Documents/Workspace/MRIP_working/code"
global my_outputdir "/home/mlee/Documents/Workspace/MRIP_working/outputs"
global my_sourcedir "/home/mlee/Documents/Workspace/MRIP_working/source files"

local date: display %td_CCYY_NN_DD date(c(current_date), "DMY")
global today_date_string = subinstr(trim("`date'"), " " , "_", .)

! mkdir "$my_outputdir/MRIP_$today_date_string"

global my_outputdir "${my_outputdir}/MRIP_$today_date_string"

do "/home/mlee/Documents/Workspace/technical folder/do file scraps/odbc_connection_macros.do"
pause off
set matsize 10000
/* Use these to control the years for which the MRIP data is polled/queried*/

global working_year  2018
local year $working_year
global wavelist 1 2 3 4 5 
global species1 "atlanticcod"
global species2 "haddock"
/*this is dumb, but I'm too lazy to replace everything that referred to these local/globals */



/* read in and store the MRIP location stuff.  Put it in the file ma_site_allocation.dta */
clear
#delimit;
odbc load,  exec("select site_id, stock_region_calc from mpalmer.mrip_ma_site_list;") conn("$mysole_conn") lower;
#delimit cr
save "$my_sourcedir/ma_site_allocation.dta", replace


cd "$my_sourcedir"
/*catchlist -- this assembles then names of files that are needed in the catchlist */
/*Check to see if the file exists */	/* If the file exists, add the filename to the list if there are observations */
global catchlist
	foreach wave of global wavelist{
	capture confirm file "catch_$working_year`wave'.dta"
	if _rc==0{
		use "catch_$working_year`wave'.dta", clear
		quietly count
		scalar tt=r(N)
		if scalar(tt)>0{
			global catchlist "$catchlist "catch_$working_year`wave'.dta" " 
		}
		else{
		}
	}
	else{
	}
	
}


/*Triplist -- this assembles then names of files that are needed in the Triplist */
/*Check to see if the file exists */	/* If the file exists, add the filename to the list if there are observations */
global triplist
	foreach wave of global wavelist{
	capture confirm file "trip_$working_year`wave'.dta"
	if _rc==0{
		use "trip_$working_year`wave'.dta", clear
		quietly count
		scalar tt=r(N)
		if scalar(tt)>0{
			global triplist "$triplist "trip_$working_year`wave'.dta" " 
		}
		else{
		}
	}
	else{
	}
	
}


/*B2 Files*/
global b2list
	foreach wave of global wavelist{
	capture confirm file "size_b2_$working_year`wave'.dta"
	if _rc==0{
		use "size_b2_$working_year`wave'.dta", clear
		quietly count
		scalar tt=r(N)
		if scalar(tt)>0{
			global b2list "$b2list "size_b2_$working_year`wave'.dta" " 
		}
		else{
		}
	}
	else{
	}
	
}




/*SIZE_LIST */
global sizelist
	foreach wave of global wavelist{
	capture confirm file "size_$working_year`wave'.dta"
	if _rc==0{
	use "size_$working_year`wave'.dta", clear
	quietly count
	scalar tt=r(N)
	if scalar(tt)>0{
		global sizelist "$sizelist "size_$working_year`wave'.dta" " 
		}
		else{
		}
	}
	else{
	}
	
}






/* caught/targeted cod or haddock by wave */
do "$my_codedir/cod_haddock_directed_trips_by_month.do"
est replay
est store monthly




cap drop my_dom_id
cap drop my_dom_id_string
cap drop count_obs1

gen my_dom_id_string=year2+area_s+"_"+"_"+dom_id
replace my_dom_id_string=ltrim(rtrim(my_dom_id_string))
/*convert this string to a number */
encode my_dom_id_string, gen(my_dom_id)

/* keep 1 observation per year-strat-psu-id_code. This will have dom_id=1 if it targeted or caught my_common1 or my_common2. Else it will be dom_id=2*/
bysort year strat_id psu_id id_code (dom_id): gen count_obs1=_n

keep if count_obs1==1

replace wp_int=0 if wp_int<=0
svyset psu_id [pweight= wp_int], strata(var_id) singleunit(certainty)





sort  my_dom_id  year strat_id psu_id id_code
local myvariables dtrip
local i=1
/* total with over(<overvar>) requires a numeric variable */

foreach var of local myvariables{
	svy: total `var', over(my_dom_id)
	
	mat b`i'=e(b)'
	mat colnames b`i'=`var'
	mat V=e(V)
	mat sub`i'=vecdiag(V)'
	mat colnames sub`i'=variance

	local ++i 
}
local --i
sort my_dom_id year 
dups my_dom_id, drop terse
keep my_dom_id year area_s month dom_id

foreach j of numlist 1/`i'{
	svmat b`j', names(col)
	svmat sub`j', names(col)

}
keep if strmatch(area_s,"GOM")==1
keep if strmatch(dom_id,"1")==1
format dtrip %10.0fc


	










