/* This is a file that extracts MRIP data needed to explore the joint catch of two species


Required input datasets:
 trip_yyyyw
 catch_yyyyw

yyyy = year
w    = wave


*/

version 12.1

/* General strategy 
COMPUTE totals and std deviations for cod catch

 */

mata: mata clear
tempfile tl1 cl1
clear

foreach yr of numlist 2022 {
	global working_year `yr'


global wavelist 1 2 3 4 5 6
global species1 "atlanticcod"
global species2 "haddock"
/*this is dumb, but I'm too lazy to replace everything that referred to these local/globals */


}
/*catchlist -- this assembles then names of files that are needed in the catchlist */
/*Check to see if the file exists */	/* If the file exists, add the filename to the list if there are observations */


global catchlist: dir "${data_raw}" files "catch_$working_year*.dta" 
global triplist: dir "${data_raw}" files "trip_$working_year*.dta" 
global b2list: dir "${data_raw}" files "size_b2_$working_year*.dta" 
global sizelist: dir "${data_raw}" files "size_$working_year*.dta" 




foreach sp in atlanticcod haddock{
	global my_common `sp'
	
	if "$my_common"=="atlanticcod"{
	   global drop_conditional `"if id_code=="1757420210428005"  "'
	}
	else {
    global drop_conditional 
	}

}










foreach file in $triplist{
	append using ${data_raw}/`file'
}
cap drop $drop_conditional

sort year strat_id psu_id id_code
/*  Deal with new variable names in the transition period  

  */

	capture confirm variable wp_int_chts
	if _rc==0{
		drop wp_int
		rename wp_int_chts wp_int
		else{
		}
}
	capture confirm variable wp_size_chts
	if _rc==0{
		drop wp_size
		rename wp_size_chts wp_size
		else{
		}
}
save `tl1'
clear

foreach file in $catchlist{
	append using ${data_raw}/`file'
}
cap drop $drop_conditional
replace var_id=strat_id if strmatch(var_id,"")
replace wp_catch=wp_int if wp_catch==.
/*  Deal with new variable names in the transition period    */

	capture confirm variable wp_int_chts
	if _rc==0{
		drop wp_int
		rename wp_int_chts wp_int
		else{
		}
}
	capture confirm variable wp_size_chts
	if _rc==0{
		drop wp_size
		rename wp_size_chts wp_size
		else{
		}

}

	capture confirm variable wp_catch_chts
	if _rc==0{
		drop wp_catch
		rename wp_catch_chts wp_catch
		else{
		}

}
sort year strat_id psu_id id_code
replace common=subinstr(lower(common)," ","",.)
save `cl1'

use `tl1'
merge 1:m year strat_id psu_id id_code using `cl1', keep(1 3) nogenerate


keep if year==$working_year
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


merge m:1 site_id using "${data_raw}/ma_site_allocation.dta", keepusing(stock_region_calc)
rename  site_id intsite
drop if _merge==2
drop _merge

/*classify into GOM or GBS */
gen str3 area_s="OTH"

replace area_s="GOM" if st==23 | st==33
replace area_s="GOM" if st==25 & strmatch(stock_region_calc,"NORTH")
replace area_s="GBS" if st==25 & strmatch(stock_region_calc,"SOUTH")

 /* classify trips that I care about into the things I care about (caught or targeted cod/haddock) and things I don't care about "ZZZZZZZZ" */
replace prim1_common=subinstr(lower(prim1_common)," ","",.)
replace prim2_common=subinstr(lower(prim1_common)," ","",.)

 
 gen common_dom="zzzzzz"
 replace common_dom="BOTH" if strmatch(common, "atlanticcod") 
  replace common_dom="BOTH"  if strmatch(common, "haddock") 

  replace common_dom="BOTH"  if strmatch(prim1_common, "atlanticcod") 
  replace common_dom="BOTH"  if strmatch(prim1_common, "haddock") 
tostring wave, gen(w2)

destring month, gen(mymo)
drop month
tostring mymo, gen(month)
drop mymo
gen my_dom_id_string=area_s +"_"+ month+"_"+common_dom


/* we need to retain 1 observation for each strat_id, psu_id, and id_code. for anything with common_dom=="BOTH" */
/* A.  Trip (Targeted or Caught) (Cod or Haddock) then it should be marked in the domain "BOTH" */

*catch frequency adjustments for grouped catch (multiple angler catches reported on a single record);

replace claim=claim/cntrbtrs if cntrbtrs>0 
  foreach var of varlist tot_cat landing claim harvest release{
	replace `var'=round(`var')
 }
replace wp_catch=0 if wp_catch<=0

keep if area_s=="GOM"

keep year strat_id psu_id id_code my_dom_id_string common tot_cat wp_catch month var_id
rename tot_cat tot_cat_
keep if inlist(common,"atlanticcod","haddock")

reshape wide tot_cat, i(year strat_id psu_id id_code my_dom_id_string wp_catch month var_id) j(common) string

foreach var of varlist tot_cat_*{
	replace `var'=0 if `var'==.
}


scatter tot_cat_atlantic tot_cat_haddock [aweight=wp_catch]
preserve
gen tc=wp_catch*tot_cat_atlantic
gen th=wp_catch*tot_cat_haddock

collapse (sum) tc th, by(year month)
list 

restore


format tot_cat_atlantic tot_cat_haddock %02.0f
tostring tot_cat_atlantic tot_cat_haddock, replace usedisplayformat
gen str6 joint_catch=tot_cat_atlantic + "_" + tot_cat_haddock

svyset psu_id [pweight= wp_catch], strata(var_id) singleunit(certainty)

local myv joint_catch


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
	svmat2 eR, rnames(rows)
	order eR
	rename rows `myv'
	
	keep `myv' GOM*

	gen year=$working_year

	foreach var of varlist GOM*{
	tokenize `var', parse("_")
	rename `var' `1'`3'
	}
	
	
	reshape long GOM, i(`myv') j(month)
	rename GOM count
	sort year month `myv'
	order year month `myv'
	
	/* parse the joint_catch column -- before is cod, after is haddock */
	
	split `myv', gen(c) parse("_")
	destring c1 c2, replace
	rename c1 tot_cat_atlanticcod
	rename c2 tot_cat_haddock
	
 	save "$data_main/MRIP_${vintage_string}/monthly/cod_haddock_joint_densities.dta", replace

	
	collapse (sum) count, by(joint_catch tot_cat_atlanticcod tot_cat_haddock)
	
	 	save "$data_main/MRIP_${vintage_string}/annual/cod_haddock_joint_densities.dta", replace

	
	twoway (kdensity tot_cat_haddock if tot_cat_atlanticcod==0)  (kdensity tot_cat_haddock if tot_cat_atlanticcod>=1 &tot_cat_atlanticcod<=4 ) (kdensity tot_cat_haddock if tot_cat_atlanticcod>=5 &tot_cat_atlanticcod<=9) (kdensity tot_cat_haddock if tot_cat_atlanticcod>=10), legend(order( 1 "0 cod" 2 "1-4 cod" 3 "5-9 cod" 4 "10+ cod") rows(1)) xtitle("Number of Haddock") ytitle("kdensity")
	
	graph export "${my_images}/cod_haddock_joint_densities.png", as(png) width(2000) replace
/*

local myv tot_cat




 note -- if I just do:

gen tc=wp_catch*tot_cat_atlantic
gen th=wp_catch*tot_cat_haddock

collapse (sum) tc th, by(year month)

I don't quite get the monthly tot_cat that is produced by svyset. It's slightly off for haddock in April 2022 and June. But it's a small difference
 */ 
