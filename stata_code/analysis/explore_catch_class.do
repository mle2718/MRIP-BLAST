/* Code to graph the catch-per-trip distribution of cod and haddock caught on recreational trips, by month . Panel graphs made by fishing year */


global stacked_dir "${data_main}/MRIP_$vintage_string/stacked_monthly"
capture mkdir "$stacked_dir"


global fishing_years "${data_main}/MRIP_$vintage_string/fishing_years"
capture mkdir "$fishing_years"


/* Storage of images*/

global my_imagedir "${my_images}/MRIP_$vintage_string/monthly"
capture mkdir "$my_imagedir"




use ${stacked_dir}/monthly_haddock_catch_class.dta, clear
destring, replace

foreach var of varlist * {
capture confirm string variable `var'
	if !_rc{
	egen `var'2 = sieve(`var'), keep(n)
	destring `var'2, replace
	drop `var'
	rename `var'2 `var'
	}
}

gen monthly=ym(year, month)
tsset monthly tot_cat
tsfill, full

replace count=0 if count==.
replace count=count/1000

/* graph everything except the first year, which will probably be a partial year */
levelsof fishing_year, local(working_years) 
qui summ fishing_year
local drop=r(min)
local working_years: list working_years - drop
drop year

foreach fy of local working_years{
	preserve
	keep if fishing_year==`fy'
	tsset month tot_cat
	xtline count if tot_cat<=50, ytitle("Trips ('000s)") ttitle("haddock catch per trip") tmtick(##5) tlabel(0(10)50) 
	graph export "${my_imagedir}/haddock_catch_class_monthly_`fy'.tif", as(tif) replace
	restore
}


use ${stacked_dir}/monthly_cod_catch_class.dta, clear

destring, replace

foreach var of varlist * {
capture confirm string variable `var'
if !_rc{
egen `var'2 = sieve(`var'), keep(n)
destring `var'2, replace
drop `var'
rename `var'2 `var'
}
}
gen monthly=ym(year, month)
tsset monthly tot_cat
tsfill, full


replace count=0 if count==.
replace count=count/1000

/* graph everything except the first year, which will probably be a partial year */
levelsof fishing_year, local(working_years) 
qui summ fishing_year
local drop=r(min)
local working_years: list working_years - drop
drop year

foreach fy of local working_years{
	preserve
	keep if fishing_year==`fy'
	tsset month tot_cat
	xtline count if tot_cat<=50, ytitle("Trips ('000s)") ttitle("cod catch per trip") tmtick(##5) tlabel(0(10)50) 
	graph export "${my_imagedir}/cod_catch_class_monthly_`fy'.tif", as(tif) replace
	restore
}
