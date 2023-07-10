

/* in order to get the right distribution of lengths, you have to multiply the B2 length proportions by the number of B2's in each year.  You have to multiply the A+B1 length proportions by the number of A+B1's in a year.

Then you have to add these up. 
*/


/* process the b2 cod */
use  "$my_outputdir/atlanticcod_landings_annual_$working_year.dta", clear
gen ab1=landings
keep year ab1
tempfile claim_harvest
sort year 
save `claim_harvest'

use "$my_outputdir/atlanticcod_landings_annual_$working_year.dta", clear
rename b2 release
keep year release
tempfile cm
sort year 
save `cm'



use "$my_outputdir/cod_b2_annual_$working_year.dta", clear

sort year 
merge m:1 year using `cm'
replace release=0 if release==.
drop _merge


tempvar tt
bysort year: egen `tt'=total(count)
gen prob=count/`tt'

gen b2_count=prob*release

keep year l_in_bin b2_count

sort year l_in_bin
/* save */
save "$my_outputdir/atlanticcod_b2_counts_annual_$working_year.dta", replace




use "$my_outputdir/cod_ab1_annual_$working_year.dta", clear


sort year 

cap drop _merge
merge m:1 year using `claim_harvest'


tempvar ttt
bysort year : egen `ttt'=total(count)
gen prob=count/`ttt'

gen ab1_count=prob*ab1

keep year  l_in_bin ab1_count

sort year  l_in_bin

merge 1:1 year l_in_bin using  "$my_outputdir/atlanticcod_b2_counts_annual_$working_year.dta"
replace ab1_count=0 if ab1_count==.
replace b2_count=0 if b2_count==.
gen countnumbersoffish=round(ab1_count+b2_count)

tempfile tt1
save `tt1'

keep year  l_in_bin countnumbersoffish 

rename l_in_bin lngcatinches
sort year  lngcatinches

label var lngcatinches "length in inches"


expand 12
drop year
sort lngcatinches
bysort lngcatinches: gen month=_n
sort month lngcat
order month lngcat count

save "$my_outputdir/cod_size_class_annual_$working_year.dta", replace

/* compute the numbers of sub-legal fish retained
use `tt1', clear
keep year  l_in_bin ab1_count countnumbers

save "$my_outputdir/cod_sublegals_annual_$working_year.dta", replace */



