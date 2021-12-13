 /* This is a file that produces a dataset that contains #of fish encountered per trip.
This is a port of Scott's "cod_domain_length_freqs_by_wave_gom_2013.sas"

This is a template program for estimating length frequencies
using the MRIP public-use datasets.

The program is setup to use information in the trip_yyyyw
dataset to define custom domains.  The length frequencies are
estimated within the domains by merging the trip information onto
the size_yyyyw datasets.

Required input datasets:
 trip_yyyyw
 size_yyyyw


It looks like we also need to port cod_domain_length_freqs_b2_by_wave_gom_2013 as well 

There will be one output per variable and year in working directory:
"$my_common`myv'_a1b1$working_year.dta"



*/

/* General strategy 
COMPUTE totals and std deviations for cod catch

 */
 clear

 mata: mata clear

tempfile tl1 sl1

foreach file in $triplist{
	append using ${data_raw}/`file'
}
cap drop $drop_conditional



replace var_id=strat_id if strmatch(var_id,"")
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

 
foreach file in $sizelist{
	append using ${data_raw}/`file'
}
cap drop $drop_conditional
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
replace var_id=strat_id if strmatch(var_id,"")

replace common=subinstr(lower(common)," ","",.)
save `sl1'

use `tl1'
merge 1:m year strat_id psu_id id_code using `sl1', keep(1 3)
drop _merge
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

 /* classify catch into the things I care about (common==$mycommon) and things I don't care about "ZZZZZZZZ" use the id_code*/
 gen common_dom="zzzzzz"
if strmatch("$my_common","atlanticcod")==1{
  replace common_dom="$my_common" if strmatch(sp_code,"8791030402")
 }
 
 if strmatch("$my_common","haddock")==1{
  replace common_dom="$my_common" if strmatch(sp_code,"8791031301")
 }

 
tostring wave, gen(w2)
tostring year, gen(year2)

destring month, gen(mymo)
drop month
tostring mymo, gen(month)
drop mymo

gen my_dom_id_string=area_s+"_"+month+"_"+common_dom

replace my_dom_id_string=subinstr(ltrim(rtrim(my_dom_id_string))," ","",.)
encode my_dom_id_string, gen(my_dom_id)

/* l_in_bin already defined
gen l_in_bin=floor(lngth*0.03937) */

/* this might speed things up if I re-classify all length=0 for the species I don't care about */
replace l_in_bin=0 if strmatch(common_dom, "$my_common")==0












sort year2 area_s w2 strat_id psu_id id_code common_dom
svyset psu_id [pweight= wp_size], strata(var_id) singleunit(certainty)

 
local myv l_in_bin

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
	

	
	keep `myv' GOM*
	drop *_z*
	gen year=$working_year
	
	
	*if there are GOM variables, then do some stuff there will be GOM _species variables if qui desc produces r(k) >=2
	qui desc
	if r(k)>=3{
	foreach var of varlist GOM*{
	tokenize `var', parse("_")
	rename `var' `1'`3'
	}
	
	
	reshape long GOM, i(l_in_bin) j(month)
	rename GOM count
	}
	else{
	keep year
	expand 12
	gen month=_n
	duplicates drop 
	drop _expand
	gen l_in_bin=0
	gen count=0
	}
	
	
	
	
	sort year month l_in_bin
	order year month l_in_bin
	
		
	save "$my_outputdir/$my_common`myv'_a1b1_${working_year}.dta", replace

clear




