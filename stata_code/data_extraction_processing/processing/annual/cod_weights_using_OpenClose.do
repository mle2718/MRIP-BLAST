

global cod_lwa 0.000005132
global cod_lwb 3.1625
global had_lwa 0.000009298
global had_lwe 3.0205
global lngcat_offset_cod 0.5
global lngcat_offset_haddock 0.5
global mt_to_kilo=1000
global kilo_to_lbs=2.20462262
global cm_to_inch=0.39370787
global mortality_release=0.15





use "$annual/cod_size_class_OpenClose_$this_working_year.dta" if open=="OPEN", clear
expand 2 , gen(mark)
gen month=9
replace month=10 if mark==1

drop mark
tempfile open
save `open'


use "$annual/cod_size_class_OpenClose_$this_working_year.dta" if open=="CLOSED", clear
expand 12
bysort year open lngcat: gen month=_n
drop if inlist(month,9,10)

append using `open'

drop count
bysort year month open: egen tab1=total(ab1_count)
bysort year month open: egen tb2=total(b2_count)

gen prob_ab1=ab1_count/tab1
gen prob_b2=b2_count/tb2


keep year month open lngcat prob*

tempfile lengths
save `lengths', replace


use "${monthlydir}\atlanticcod_catch_$this_working_year.dta", clear
gen ab1=claim+harvest
rename release b2

gen str6 open="OPEN" if inlist(month,"09","10")
replace open="CLOSED" if open==""
destring month, replace
keep year month ab1 b2 open
merge 1:m year month open using `lengths', keep(1 3)
gen ab1_count=ab1*prob_ab1
gen b2_count=b2*prob_b2
keep year month lngcat open ab1_count b2_count
sort year month open lngcat


gen weight_per_fish= $kilo_to_lbs*$cod_lwa*((lngcat+.5)/$cm_to_inch)^$cod_lwb
gen ab1mt=weight_per_fish*ab1_count/($mt_to_kilo*$kilo_to_lbs)
gen b2mt=weight_per_fish*b2_count/($mt_to_kilo*$kilo_to_lbs)



collapse (sum) ab1_count b2_count ab1mt b2mt ,  by(year month)

gen b2dead_mt=b2mt*$mortality_release

format ab1_count b2_count %10.0fc

format b2mt ab1mt b2dead_mt %6.2fc

save "$annual\atlanticcod_weights_OpenClose_${this_working_year}.dta", replace


