

/* in order to get the right distribution of lengths, you have to multiply the B2 length proportions by the number of B2's in each year.  You have to multiply the A+B1 length proportions by the number of A+B1's in a year.

Then you have to add these up. 
*/



/* process the b2 haddock */


use  "$my_outputdir/haddock_landings_$working_year.dta", clear
destring month, replace
gen ab1=landings
keep year month ab1
tempfile claim_harvest
sort year month
save `claim_harvest'





use  "$my_outputdir/haddock_landings_$working_year.dta", clear
destring month, replace
rename b2 release

keep year month release
tempfile cm
sort year month
save `cm'
keep if year==$working_year

use "$my_outputdir/haddock_b2_$working_year.dta", clear

/*  In CY 2022, there are no B2 lengths for months 7-10 and month 4. Fix this. 

if ($working_year==2022){

keep if month>=5 & month<=6
preserve
collapse (sum) count, by(l_in_bin year)
expand 5
bysort year l_in_bin: gen month=_n+6
replace month=4 if month==11
tempfile stackon
save `stackon'
restore
append using `stackon'
sort year month l_in_bin
order year month l_in_bin 

}
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
keep if year==$working_year

/* save */
notes: the file haddock_b2_counts_$working_year.dta contains the length distribution corresponding to the population of B2s.  The sum of (b2_count) is the total discards.

save  "$my_outputdir/haddock_b2_counts_$working_year.dta", replace




use  "$my_outputdir/haddock_ab1_$working_year.dta", clear


sort year month

cap drop _merge
merge m:1 year month using `claim_harvest'


tempvar ttt
bysort year month: egen `ttt'=total(count)
gen prob=count/`ttt'

gen ab1_count=prob*ab1

keep year month l_in_bin ab1_count

sort year month l_in_bin

save "$my_outputdir/haddock_ab1_counts_$working_year.dta", replace



merge 1:1 year month l_in_bin using  "$my_outputdir/haddock_b2_counts_$working_year.dta"
replace ab1_count=0 if ab1_count==.
replace b2_count=0 if b2_count==.
gen countnumbersoffish=round(ab1_count+b2_count)
tempfile tth1
save `tth1'

keep year month l_in_bin countnumbersoffish 

rename l_in_bin lngcatinches
sort year month lngcatinches

label var lngcatinches "length in inches"

save  "$my_outputdir/haddock_size_class_$working_year.dta", replace






