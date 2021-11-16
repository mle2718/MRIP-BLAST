use haddocktot_cat_2016.dta, clear
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
tsset month tot_cat
tsfill, full

replace count=0 if count==.
replace count=count/1000

drop year
xtline count if tot_cat<=50, ytitle("Trips ('000s)") ttitle("haddock catch per trip") tmtick(##5) tlabel(0(10)50)
graph export "haddock_catch_class_monthly.tif", as(tif) replace


use atlanticcodtot_cat_2016.dta, clear
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
tsset month tot_cat
tsfill, full
replace count=0 if count==.
replace count=count/1000

drop year
xtline count if tot_cat<=50, ytitle("Trips ('000s)") ttitle("Cod catch per trip") tmtick(##5) tlabel(0(10)50)
graph export "cod_catch_class_monthly.tif", as(tif) replace
