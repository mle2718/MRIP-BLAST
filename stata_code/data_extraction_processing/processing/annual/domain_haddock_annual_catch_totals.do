/* This is a file that produces data on a, b1, b2, and other top-level catch statistics by wave

This is a port of Scott's sas code

*/
version 12.1

/* General strategy 
COMPUTE totals and std deviations for cod catch

 */
 mata: mata clear

local my_common $species2


tempfile tl1 cl1
clear
foreach file in $triplist{
	append using ${data_raw}/`file'
}
capture drop $drop_conditional

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
merge 1:m year wave strat_id psu_id id_code using `cl1', keep(3)
drop _merge
/*ONLY keep trips for which there was catch>0 */


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
gen str3 area_s=" "

replace area_s="GOM" if st==23 | st==33
replace area_s="GOM" if st==25 & strmatch(stock_region_calc,"NORTH")
replace area_s="GBS" if st==25 & strmatch(stock_region_calc,"SOUTH")

 /* classify catch into the things I care about (common==$mycommon) and things I don't care about "ZZZZZZZZ" */
 gen common_dom="zzzzzz"
 replace common_dom=common if strmatch(common, "`my_common'") 
 
 
tostring wave, gen(w2)
tostring year, gen(year2)
*gen my_dom_id_string=year2+area_s+"_"+w2+"_"+common_dom
tostring year, gen(myy)

gen my_dom_id_string=year2+area_s+"_"+myy+"_"+common_dom

replace my_dom_id_string=ltrim(rtrim(my_dom_id_string))
encode my_dom_id_string, gen(my_dom_id)
replace wp_catch=0 if wp_catch<=0
sort year my_dom_id
svyset psu_id [pweight= wp_int], strata(strat_id) singleunit(certainty)
/*svyset psu_id [pweight= wp_int], strata(strat_id) singleunit(certainty) */


svyset psu_id [pweight= wp_catch], strata(var_id) singleunit(certainty)

 
local myvariables tot_cat claim harvest release
local i=0


/* total with over(<overvar>) requires a numeric variable 

*/

foreach var of local myvariables{
	local ++i 
	svy: total `var', over(my_dom_id)
	
	mat b`i'=e(b)'
	mat colnames b`i'=`var'
	mat V=e(V)

}
sort year my_dom_id
duplicates drop my_dom_id, force
keep my_dom_id year area_s month common_dom

foreach j of numlist 1/`i'{
	svmat b`j', names(col)
}

drop if strmatch(common_dom,"zzzzzz")
keep if strmatch(area_s,"GOM")
sort year area_s month common_dom
drop month
	save "$my_outputdir/`my_common'_catch_annual_$working_year.dta", replace


