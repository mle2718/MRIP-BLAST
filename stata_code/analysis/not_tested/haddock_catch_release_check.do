/* This is a file that produces a dataset that contains #of fish encountered per trip.
This is a port of Scott's "domain_catch_frequencies_gom_cod_wave_2013.sas"



This is a template program for estimating catch frequecies
using the MRIP public-use datasets.

The program is setup to use information in the trip_yyyyw
dataset to define custom domains.  The catch frequencies are
estimated within the domains by merging the trip information
onto the catch_yyyyw datasets.

Required input datasets:
 trip_yyyyw
 catch_yyyyw

yyyy = year
w    = wave


*/

version 12.1

do "/home/mlee/Documents/Workspace/technical folder/do file scraps/odbc_connection_macros.do"
pause on
set matsize 10000
/* Use these to control the years for which the MRIP data is polled/queried*/

global yearlist 2014
global wavelist 1 2 3 4 5 6
global species1 "atlanticcod"
global species2 "haddock"
global first_year 2012 
global final_year 2014 
	global my_common "haddock"

local yr1 2012 
local yre 2014


global myyear 2014


/* read in and store the MRIP location stuff.  Put it in the file ma_site_allocation.dta */
clear
#delimit;
odbc load,  exec("select site_id, stock_region_calc from mpalmer.mrip_ma_site_list;") conn("$mysole_conn") lower;
#delimit cr
save "/home/mlee/Documents/Workspace/MRIP_working/source files/ma_site_allocation.dta", replace


/*Set up the catchlist, triplist, and b2list global macros. These hold the filenames that are needed to figure out the catch, length-frequency, trips, and other things.*/
cd "/home/mlee/Documents/Workspace/MRIP_working/source files"


/*


  local all_list: dir . files "*.dta"
clear
quietly foreach l of local all_list {
	use `l'
	renvars, lower
	save `l', replace
}

*/

/*catchlist -- this assembles then names of files that are needed in the catchlist */
/*Check to see if the file exists */	/* If the file exists, add the filename to the list if there are observations */
global catchlist
foreach year of global yearlist{
	foreach wave of global wavelist{
	capture confirm file "catch_`year'`wave'.dta"
	if _rc==0{
		use "catch_`year'`wave'.dta", clear
		quietly count
		scalar tt=r(N)
		if scalar(tt)>0{
			global catchlist "$catchlist "catch_`year'`wave'.dta" " 
		}
		else{
		}
	}
	else{
	}
	
}
}

/*Triplist -- this assembles then names of files that are needed in the Triplist */
/*Check to see if the file exists */	/* If the file exists, add the filename to the list if there are observations */
global triplist
foreach year of global yearlist{
	foreach wave of global wavelist{
	capture confirm file "trip_`year'`wave'.dta"
	if _rc==0{
		use "trip_`year'`wave'.dta", clear
		quietly count
		scalar tt=r(N)
		if scalar(tt)>0{
			global triplist "$triplist "trip_`year'`wave'.dta" " 
		}
		else{
		}
	}
	else{
	}
	
}
}

/*B2 Files*/
global b2list
foreach year of global yearlist{
	foreach wave of global wavelist{
	capture confirm file "size_b2_`year'`wave'.dta"
	if _rc==0{
		use "size_b2_`year'`wave'.dta", clear
		quietly count
		scalar tt=r(N)
		if scalar(tt)>0{
			global b2list "$b2list "size_b2_`year'`wave'.dta" " 
		}
		else{
		}
	}
	else{
	}
	
}
}



/*SIZE_LIST */
global sizelist
foreach year of global yearlist{
	foreach wave of global wavelist{
	capture confirm file "size_`year'`wave'.dta"
	if _rc==0{
	use "size_`year'`wave'.dta", clear
	quietly count
	scalar tt=r(N)
	if scalar(tt)>0{
		global sizelist "$sizelist "size_`year'`wave'.dta" " 
		}
		else{
		}
	}
	else{
	}
	
}
}

/* General strategy 
COMPUTE totals and std deviations for cod catch

 */

 mata: mata clear
cd "/home/mlee/Documents/Workspace/MRIP_working/source files"
local years_used=$myyear

tempfile tl1 cl1
dsconcat $triplist

sort year strat_id psu_id id_code
save `tl1'
clear

dsconcat $catchlist
sort year strat_id psu_id id_code
replace common=subinstr(lower(common)," ","",.)
save `cl1'

use `tl1'
merge 1:m year strat_id psu_id id_code using `cl1', keep(1 3) nogenerate


keep if year==`years_used'
/* THIS IS THE END OF THE DATA MERGING CODE */


 /* ensure that domain is sub_reg=4 (New England), relevant states (MA, NH, ME), mode_fx =123, 457 */
 keep if sub_reg==4
 keep if st==23 | st==33 |st==25

/*This is the "full" mrip data */
tempfile tc1
save `tc1'

/*classify as GOM or GB based on the ma_site_allocation.dta file */
rename intsite site_id
sort site_id



merge m:1 site_id using "ma_site_allocation.dta", keepusing(stock_region_calc) 
rename  site_id intsite
drop if _merge==2
drop _merge

/*classify into GOM or GBS */
gen str3 area_s=" "

replace area_s="GOM" if st==23 | st==33
replace area_s="GOM" if st==25 & strmatch(stock_region_calc,"NORTH")
replace area_s="GBS" if st==25 & strmatch(stock_region_calc,"SOUTH")

 /* classify trips that I care about into the things I care about (caught or targeted cod/haddock) and things I don't care about "ZZZZZZZZ" */
 replace prim1_common=subinstr(lower(prim1_common)," ","",.)
replace prim2_common=subinstr(lower(prim1_common)," ","",.)

 
 gen common_dom="zzzzzz"
 replace common_dom="ATLCO" if strmatch(common, "atlanticcod") 
  replace common_dom="ATLCO"  if strmatch(common, "haddock") 

  replace common_dom="ATLCO"  if strmatch(prim1_common, "atlanticcod") 
  replace common_dom="ATLCO"  if strmatch(prim1_common, "haddock") 
tostring wave, gen(w2)

gen my_dom_id_string=area_s +"_"+ w2+"_"+common_dom


/* we need to retain 1 observation for each strat_id, psu_id, and id_code.  */
/* A.  Trip (Targeted or Caught) (Cod or Haddock) then it should be marked in the domain "_ATLCO"
	1. Caught my_common.  We retain tot_cat
	2. Did not catch my_common.  We set tot_cat=0
   B.  Trip did not (Target or Caught) (Cod or Haddock) then it is marked in the the domain "ZZZZZ"
	1. Caught my_common.  This is impossible.
	2. Did not catch my_common.  We set tot_cat=0
	
To do this:
1.  We set tot_cat, landing, claim, harvest, and release to zero for all instances of common~="my_common"
2.  We set a variable "no_dup"=0 if the record is "my_common" catch and no_dup=1 otherwise.
3.  We sort on year, strat_id, psu_id, id_code, "no_dup", and "my_dom_id_string".
  For records with duplicate year, strat_id, psu_id, and id_codes, the first entry will be "my_common catch" if it exists.  These will all be have sp_dom "ATLCO."  If there is no my_common catch, but the 
  trip targeted (cod or haddock) or caught cod, the secondary sorting on "my_dom_id_string" ensures the trip is properly classified as an (A2 from above).
4. After sorting, we generate a count variable (count_obs1 from 1....n) and we keep only the "first" observations within each "year, strat_id, psu_id, and id_codes" group.
*/


/*
1  Set tot_cat, landing, claim, harvest, and release to zero for all instances of common~="my_common"
2.  We set a variable "no_dup"=0 if the record is "$my_common" catch and no_dup=1 otherwise.*/

 gen no_dup=0
 replace no_dup=1 if strmatch(common, "$my_common")==0
 	replace tot_cat=0 if strmatch(common, "$my_common")==0
	replace landing=0 if strmatch(common, "$my_common")==0
	replace claim=0 if strmatch(common, "$my_common")==0
	replace harvest=0 if strmatch(common, "$my_common")==0
	replace release=0 if strmatch(common, "$my_common")==0

*catch frequency adjustments for grouped catch (multiple angler catches reported on a single record);
replace claim=claim/cntrbtrs if cntrbtrs>0 
  foreach var of varlist tot_cat landing claim harvest release{
	replace `var'=round(`var')
 }
 

/*3.  We sort on year, strat_id, psu_id, id_code, "no_dup", and "my_dom_id_string".
4. After sorting, we generate a count variable (count_obs1 from 1....n) and we keep only the "first" observations within each "year, strat_id, psu_id, and id_codes" group.*/

bysort year strat_id psu_id id_code (no_dup my_dom_id_string): gen count_obs1=_n
keep if count_obs1==1



sort year strat_id psu_id id_code
svyset psu_id [pweight= wp_int], strata(strat_id) singleunit(certainty)
keep if common_dom=="ATLCO"
gen str1 bag="0"
replace bag="1" if strmatch(common, "$my_common")==1 & landing>=3
replace my_dom_id_string=area_s+bag+"_"+ w2+"_"+common_dom

local myvariables tot_cat
foreach myv of local myvariables{
	tempfile new
	local NEWfiles `"`NEWfiles'"`new'" "'  
	svy: tab `myv' my_dom_id_string, count
	/*save some stuff  
	matrix of proportions, row names, column names, estimate of total population size*/
	mat eP=e(Prop)
	mat eR=e(Row)'
	mat eC=e(Col)
	local PopN=e(N_pop)

	local mycolnames: colnames(eC)
	mat colnames eP=`mycolnames'
	
	clear
	/*read the eP into a dataset and convert proportion of population into numbers*/
	svmat eP, names(col)
	foreach var of varlist *{
		replace `var'=`var'*`PopN'
	}
	/*read in the "row" */
	svmat eR
	order eR
	rename eR `myv'
	
	
	keep `myv' GOM*A
	gen year=`years_used'
	
	renvars GOM*, postdrop(1)
	reshape long GOM_, i(`myv') j(wave)
	rename GOM count
	sort year wave `myv'
	order year wave `myv'

	quietly save `new'

}

dsconcat `NEWfiles'



