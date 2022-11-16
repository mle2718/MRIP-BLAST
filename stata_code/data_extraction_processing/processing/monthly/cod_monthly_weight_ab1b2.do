
use "${data_main}/MRIP_${vintage_string}/monthly/atlanticcod_ab1_counts_${working_year}.dta", clear


*rename count ab1_count

merge 1:1 year month l_in_bin using "${data_main}/MRIP_${vintage_string}/monthly/atlanticcod_b2_counts_${working_year}.dta"
replace ab1_count=0 if ab1_count==.
replace b2_count=0 if b2_count==.
gen countnumbersoffish=round(ab1_count+b2_count)

/*
These are the length-weight relationships for Cod and Haddock
GOM Cod Formula:
Wlive (kg) = 0.000005132·L(fork cm)3.1625 (p < 0.0001, n=4890)


Haddock Weight length formula 
Annual: Wlive (kg) = 0.000009298·L(fork cm)3.0205 (p < 0.0001, n=4890)

Fork length and total length are equivalentfor haddock and cod*/


global coda=0.000005132
global codb=3.1625


global cmtoinch= 0.39370787
global kilotolb=2.20462262

drop if l_in_bin==0
gen weight_per_fish= $kilotolb*$coda*((l_in_bin+.5)/$cmtoinch)^$codb



gen ab1weight=round(ab1_count)*weight_per_fish
gen b2weight=round(b2_count)*weight_per_fish

keep if year==$working_year

drop if l_in_bin==0
collapse (sum) ab1weight b2weight ab1_count b2_count, by(year month)

save "${data_main}/MRIP_${vintage_string}/monthly/cod_weights_${working_year}.dta", replace
