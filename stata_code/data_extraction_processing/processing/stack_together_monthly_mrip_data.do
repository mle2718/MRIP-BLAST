


/******************************STACK TOGETHER DATA FROM MULTIPLE CALENDAR YEARS. **********************/


global cod_catch_class: dir "${my_outputdir}" files "atlanticcod_catch_class*.dta" 
global haddock_catch_class: dir "${my_outputdir}" files "haddock_catch_class*.dta" 

global cod_size_class: dir "${my_outputdir}" files "cod_size_class*.dta" 
global haddock_size_class: dir "${my_outputdir}" files "haddock_size_class*.dta" 


global targeting: dir "${my_outputdir}" files "atlanticcod_haddock_target*.dta" 


global stacked_dir "${data_main}/MRIP_$vintage_string/stacked_monthly"
capture mkdir "$stacked_dir"


global fishing_years "${data_main}/MRIP_$vintage_string/fishing_years"
capture mkdir "$fishing_years"

clear
foreach file in $cod_catch_class{
	append using ${my_outputdir}/`file'
}
gen fishing_year=year
replace fishing_year=year-1 if month<=4
save ${stacked_dir}/monthly_cod_catch_class.dta, replace

drop if year<2019

collapse (sum) count, by(fishing_year tot_cat)
order fishing_year tot_cat
save ${fishing_years}/FY_cod_catch_class.dta, replace



clear

foreach file in $haddock_catch_class{
	append using ${my_outputdir}/`file'
}
gen fishing_year=year
replace fishing_year=year-1 if month<=4
save ${stacked_dir}/monthly_haddock_catch_class.dta, replace

drop if year<2019

collapse (sum) count, by(fishing_year tot_cat)
order fishing_year tot_cat
save ${fishing_years}/FY_haddock_catch_class.dta, replace



clear

foreach file in $cod_size_class{
	append using ${my_outputdir}/`file'
}
gen fishing_year=year
replace fishing_year=year-1 if month<=4
save ${stacked_dir}/monthly_cod_size_class.dta, replace

drop if year<2019

collapse (sum) count, by(fishing_year lngcatinches)
order fishing_year lngcatinches 
save ${fishing_years}/FY_cod_size_class.dta, replace




clear
foreach file in $haddock_size_class{
	append using ${my_outputdir}/`file'
}
gen fishing_year=year
replace fishing_year=year-1 if month<=4
save ${stacked_dir}/monthly_haddock_size_class.dta, replace

drop if year<2019

collapse (sum) count, by(fishing_year lngcatinches)
order fishing_year lngcatinches 
save ${fishing_years}/FY_haddock_size_class.dta, replace


clear

foreach file in $targeting{
	append using ${my_outputdir}/`file'
}
gen fishing_year=year
destring month, replace
replace fishing_year=year-1 if month<=4
save ${stacked_dir}/monthly_targeting.dta, replace

drop if year<2019

collapse (sum) dtrip, by(fishing_year)
order fishing_year
save ${fishing_years}/FY_targeting.dta, replace
