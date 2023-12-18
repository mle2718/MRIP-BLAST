

/* in order to get the right distribution of lengths, you have to multiply the B2 length proportions by the number of B2's in each year.  You have to multiply the A+B1 length proportions by the number of A+B1's in a year.

Then you have to add these up. 
*/


/* process the b2 cod */

use  "$my_outputdir/atlanticcod_landings_mode_$working_year.dta", clear
destring month, replace
gen ab1=landings
keep year month ab1 mode 
tempfile claim_harvest
sort year month
replace mode= "ForHire" if mode=="F"
replace mode="Private" if mode=="P"

save `claim_harvest'


use "$my_outputdir/atlanticcod_landings_mode_$working_year.dta", clear
destring month, replace
rename b2 release
keep year month release mode 
tempfile cm
sort year month
replace mode= "ForHire" if mode=="F"
replace mode="Private" if mode=="P"

save `cm'

use "$my_outputdir/cod_b2_mode_$working_year.dta", clear

/* fill in month 4 with months 9+10 from previous year. Fill in month 10 with month 9 of current year.  The april fill-in looks a little crazy it's the best match because of the similar regs.  


if ($working_year==2022){
drop if month==10 | month==4
expand 2 if month==9, gen(mykey)
replace month=10 if mykey==1
drop mykey

preserve
use "$my_outputdir/cod_b2_mode_$previous_year.dta" if inlist(month,9,10), clear
replace month=4 
replace year=$working_year
collapse (sum) count, by(year month l_in_bin)
tempfile stack2
save `stack2', replace
restore 

append using `stack2'

}
*/

sort year month
merge m:1 year month mode using `cm'
replace release=0 if release==.
drop _merge

/*FOR HIRE COUNTS */

tempvar tt
bysort year month: egen `tt'=total(count)
gen prob=count/`tt'

gen b2_count=prob*release

tempvar ttt
bysort year month: egen `ttt'=total(count_UW)
gen probUW=count_UW/`ttt'

gen b2_UWcount=probUW*release









keep year month mode l_in_bin b2*

sort year month l_in_bin
keep if year==$working_year

/* save */
notes: the file atlanticcod_b2_mode_counts_$working_year.dta contains the length distribution corresponding to the population of B2s.  The sum of (b2_count) is the total discards. This is by mode

save "$my_outputdir/atlanticcod_b2_mode_counts_$working_year.dta", replace




use "$my_outputdir/cod_ab1_mode_$working_year.dta", clear
reshape long count_ , i(year month l_in_bin) j(mode) string
rename count count
/*
expand 2 if month==5 & year==2013
drop if month==6 & year==2013

bysort year month l_in_bin: gen mark=_n
replace month=6 if mark==2 & year==2013 & month==5

drop mark
*/

sort year month

cap drop _merge
merge m:1 year month mode using `claim_harvest'


tempvar ttt
bysort year month mode: egen `ttt'=total(count)
gen prob=count/`ttt'

gen ab1_count=prob*ab1

keep year month mode l_in_bin ab1_count

sort year month l_in_bin
keep if year==$working_year

save "$my_outputdir/atlanticcod_ab1_mode_counts_$working_year.dta", replace


merge 1:1 year month mode l_in_bin using  "$my_outputdir/atlanticcod_b2_mode_counts_$working_year.dta"

foreach var of varlist ab1_count b2_UWcount b2_count {
	
replace `var'=0 if `var'==.
}
pause 


gen countnumbersoffish=round(ab1_count+b2_count)
gen UWcountnumbersoffish=round(ab1_count+b2_UWcount)

keep year month mode l_in_bin ab1_count b2_UWcount UWcountnumbersoffish


rename l_in_bin lngcatinches
sort year mode month lngcatinches

label var lngcatinches "length in inches"

save "$my_outputdir/cod_size_mode_class_$working_year.dta", replace



