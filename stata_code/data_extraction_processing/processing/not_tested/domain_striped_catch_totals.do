/* This is a file that produces data on a, b1, b2, and other top-level catch statistics by wave

This is a port of Scott's sas code

*/
version 12.1

/* General strategy 
COMPUTE totals and std deviations for cod catch

 */
 mata: mata clear

cd "/home/mlee/Documents/Workspace/MRIP_working/source files"
local my_common $species1


tempfile tl1 cl1
dsconcat $triplist

sort year strat_id psu_id id_code
save `tl1'
clear

dsconcat $catchlist

replace var_id=strat_id if strmatch(var_id,"")
replace wp_catch=wp_int if wp_catch==.


sort year strat_id psu_id id_code
replace common=subinstr(lower(common)," ","",.)

save `cl1'

use `tl1'

merge 1:m year strat_id psu_id id_code using `cl1', keep(3)
drop _merge
/*ONLY keep trips for which there was catch>0 */


/* THIS IS THE END OF THE DATA MERGING CODE */


 /* ensure that domain is sub_reg=4 (New England), relevant states (MA, NH, ME), mode_fx =123, 457
 keep if sub_reg==4
 keep if st==23 | st==33 |st==25 */

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
gen str3 area_s="ALL"

/*
replace area_s="GOM" if st==23 | st==33
replace area_s="GOM" if st==25 & strmatch(stock_region_calc,"NORTH")
replace area_s="GBS" if st==25 & strmatch(stock_region_calc,"SOUTH")
*/
 /* classify catch into the things I care about (common==$mycommon) and things I don't care about "ZZZZZZZZ" */
 gen common_dom="zzzzzz"
 replace common_dom=common if strmatch(common, "`my_common'") 
 
 
tostring wave, gen(w2)
tostring year, gen(year2)
gen my_dom_id_string=year2+area_s+"_"+w2+"_"+common_dom

replace my_dom_id_string=ltrim(rtrim(my_dom_id_string))
encode my_dom_id_string, gen(my_dom_id)
replace wp_catch=0 if wp_catch<=0
sort year my_dom_id


/*svyset psu_id [pweight= wp_int], strata(strat_id) singleunit(certainty) */


svyset psu_id [pweight= wp_catch], strata(var_id) singleunit(certainty)



levelsof year, local(myloc)

foreach myy of local myloc	{
timer on 99
	tempfile new
	local NEWfiles `"`NEWfiles'"`new'" "'  
	

preserve
keep if year==`myy'
svyset psu_id [pweight= wp_catch], strata(var_id) singleunit(certainty)


 
local myvariables tot_cat claim harvest release
local i=1
/* total with over(<overvar>) requires a numeric variable
 */

	foreach var of local myvariables{
		svy: total `var', over(my_dom_id)
		
		mat b`i'=e(b)'
		mat colnames b`i'=`var'
		mat V=e(V)

		local ++i 
	}
	
	local --i
	sort year my_dom_id
	dups my_dom_id, drop terse
	keep my_dom_id year area_s w2 common_dom

	foreach j of numlist 1/`i'{
		svmat b`j', names(col)
	}

drop if strmatch(common_dom,"zzzzzz")
sort year area_s w2 common_dom
rename w2 wave
destring wave, replace
sort year wave area

save `new'
restore
timer off 99
}
dsconcat `NEWfiles'
	renvarlab, lower
	destring, replace
	compress



save "/home/mlee/Documents/Workspace/MRIP_working/`my_common'_catch.dta", replace



