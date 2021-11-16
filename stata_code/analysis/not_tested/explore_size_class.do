use haddock_size_class_2015_2016.dta, clear
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
keep if year==2016
tsset month lngcat
tsfill, full
replace count=0 if count==.
replace count=count/1000
drop year
xtline count if lngcat>=10, ytitle("Number of fish ('000s)") ttitle("haddock length(inches)") tmtick(##5) tlabel(10(5)30)
graph export "haddock_size_class_monthly.tif", as(tif) replace


use cod_size_class_2015_2016.dta, clear
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
keep if year==2016
tsset month lngcat
tsfill, full
replace count=0 if count==.
replace count=count/1000
drop year
xtline count  if lngcat>=5, ytitle("Number of fish ('000s)") ttitle("cod length(inches)") tmtick(##5) tlabel(5(5)35)
graph export "cod_size_class_monthly.tif", as(tif) replace
