

/* in order to get the right distribution of lengths, you have to multiply the B2 length proportions by the number of B2's in each year.  You have to multiply the A+B1 length proportions by the number of A+B1's in a year.

Then you have to add these up. 
*/


/* process the b2 cod */

use  "$my_outputdir/atlanticcod_landings_$working_year.dta", clear
destring month, replace
gen ab1=landings
keep year month ab1
tempfile claim_harvest
sort year month
save `claim_harvest'


use "$my_outputdir/atlanticcod_landings_$working_year.dta", clear
destring month, replace
rename b2 release
keep year month release
tempfile cm
sort year month
save `cm'

use "$my_outputdir/cod_b2_$working_year.dta", clear

/* fill in month 6 from 2013 that is missing with month 5 data

expand 2 if month==5 & year==2013
drop if month==6 & year==2013

bysort year month l_in_bin: gen mark=_n
replace month=6 if mark==2 & year==2013 & month==5

drop mark
*/
sort year month
merge m:1 year month using `cm'
replace release=0 if release==.
drop _merge


tempvar tt
bysort year month: egen `tt'=total(count)
gen prob=count/`tt'

gen b2_count=prob*release

keep year month l_in_bin b2_count

sort year month l_in_bin
/* save */
save "$my_outputdir/atlanticcod_b2_counts_$working_year.dta", replace




use "$my_outputdir/cod_ab1_$working_year.dta", clear

/*
expand 2 if month==5 & year==2013
drop if month==6 & year==2013

bysort year month l_in_bin: gen mark=_n
replace month=6 if mark==2 & year==2013 & month==5

drop mark
*/

sort year month

cap drop _merge
merge m:1 year month using `claim_harvest'


tempvar ttt
bysort year month: egen `ttt'=total(count)
gen prob=count/`ttt'

gen ab1_count=prob*ab1

keep year month l_in_bin ab1_count

sort year month l_in_bin

save "$my_outputdir/atlanticcod_ab1_counts_$working_year.dta", replace


merge 1:1 year month l_in_bin using  "$my_outputdir/atlanticcod_b2_counts_$working_year.dta"
replace ab1_count=0 if ab1_count==.
replace b2_count=0 if b2_count==.
gen countnumbersoffish=round(ab1_count+b2_count)

tempfile tt1
save `tt1'

keep year month l_in_bin countnumbersoffish 

rename l_in_bin lngcatinches
sort year month lngcatinches

label var lngcatinches "length in inches"

save "$my_outputdir/cod_size_class_$working_year.dta", replace

/* compute the numbers of sub-legal fish retained */
use `tt1', clear
keep year month l_in_bin ab1_count countnumbers
gen fy=year
replace fy=fy-1 if month<=4

export excel year month fy l_in_bin ab1_count count using "$my_outputdir/cod_sublegal_retention_$working_year.xls", firstrow(variables) replace
save "$my_outputdir/cod_sublegals_$working_year.dta", replace



