
local yr1 2019 
local lasty=`yr1'-1

global BLAST_DIR "/home/mlee/Documents/Workspace/recreational_simulations/cod_haddock_fy2020"
global MRIP_SOURCE "/home/mlee/Documents/Workspace/MRIP_working/outputs/MRIP_2019_12_20"

/*This part looks into the catch-class distributions and retains a subset of them. It puts the files into the "GARFO" folder*/

cd "/home/mlee/Documents/Workspace/MRIP_working"

use "${MRIP_SOURCE}/atlanticcod_catch_class_`yr1'.dta", clear
append using "${MRIP_SOURCE}/atlanticcod_catch_class_`lasty'.dta"

/* The most recent months are not available. Fill them in with the prior year's data*/
bysort year: egen lastm=max(month)

replace lastm=. if year==`lasty'
sort lastm
replace lastm=lastm[_n-1] if lastm==.
drop if year<=`lasty'-1

drop if year<=`lasty' & month<=lastm


/* There are months with no data. They will usually be at the beginning or end (JFM or OND)
These missing data should be filled.*/


drop year lastm
preserve

qui summ month
local first=r(min)
local last=r(max)

local repl=`first'-1
local replh=`last'+1

local nmiss=`first'-1+12-`last'

keep if inlist(month,`first',`last')
collapse (sum) count, by(tot_cat)
replace count=count/2
expand `nmiss'
sort tot_cat
egen month=fill(1/`repl'  `replh'/12 1/`repl'  `replh'/12) 
tempfile tt
save `tt'
restore
append using `tt'
sort month tot_cat count
rename tot_cat num_fish
xtset month num_fish
xtline count
graph export "cod_catch_class_`yr1'.tif", as(tif) replace
save "${BLAST_DIR}/source_data/mrip/cod_catch_class`yr1'.dta", replace



use "${MRIP_SOURCE}/haddock_catch_class_`yr1'.dta", clear
append using "${MRIP_SOURCE}/haddock_catch_class_`lasty'.dta"


/* The most recent months are not available. Fill them in with the prior year's data*/
bysort year: egen lastm=max(month)
replace lastm=. if year==`lasty'
sort lastm
replace lastm=lastm[_n-1] if lastm==.
drop if year<=`lasty'-1

drop if year<=`lasty' & month<=lastm

drop year lastm
preserve

qui summ month
local first=r(min)
local last=r(max)

local repl=`first'-1
local replh=`last'+1

local nmiss=`first'-1+12-`last'

keep if inlist(month,`first',`last')
collapse (sum) count, by(tot_cat)
replace count=count/2
expand `nmiss'
sort tot_cat
egen month=fill(1/`repl'  `replh'/12 1/`repl'  `replh'/12) 
tempfile tt

save `tt'
restore
append using `tt'
rename tot_cat num_fish
xtset month num_fish
xtline count
graph export "haddock_catch_class_`yr1'.tif", as(tif) replace

save "${BLAST_DIR}/source_data/mrip/haddock_catch_class`yr1'.dta", replace


/*This part looks into the size-class distributions and retains a subset of them. It puts the files into the "GARFO" folder*/
use "${MRIP_SOURCE}/cod_size_class_`yr1'.dta", clear
append using "${MRIP_SOURCE}/cod_size_class_`lasty'.dta"
drop if lngcat==0


/* The most recent months are not available. Fill them in with the prior year's data*/
bysort year: egen lastm=max(month)
replace lastm=. if year==`last'
sort lastm
replace lastm=lastm[_n-1] if lastm==.
drop if year<=`lasty'-1

drop if year<=`lasty' & month<=lastm


drop year lastm
preserve

qui summ month
local first=r(min)
local last=r(max)

local repl=`first'-1
local replh=`last'+1

local nmiss=`first'-1+12-`last'

keep if inlist(month,`first',`last')
collapse (sum) count, by(lngcat)
replace count=count/2
expand `nmiss'
sort lngcat
egen month=fill(1/`repl'  `replh'/12 1/`repl'  `replh'/12) 
tempfile tt
save `tt'
restore
append using `tt'

sort month lng
collapse (sum) count, by(month lngcat)

xtset month lng
xtline count
graph export "cod_size_class`yr1'.tif", as(tif) replace


save "${BLAST_DIR}/source_data/mrip/cod_size_class`yr1'.dta", replace






/*This part looks into the size-class distributions and retains a subset of them. It puts the files into the "GARFO" folder*/
use "${MRIP_SOURCE}/haddock_size_class_`yr1'.dta", clear
append using "${MRIP_SOURCE}/haddock_size_class_`lasty'.dta"
drop if lngcat==0


/* The most recent months are not available. Fill them in with the prior year's data*/
bysort year: egen lastm=max(month)
replace lastm=. if year==`last'
sort lastm
replace lastm=lastm[_n-1] if lastm==.
drop if year<=`lasty'-1

drop if year<=`lasty' & month<=lastm


drop year lastm
preserve

qui summ month
local first=r(min)
local last=r(max)

local repl=`first'-1
local replh=`last'+1

local nmiss=`first'-1+12-`last'

keep if inlist(month,`first',`last')
collapse (sum) count, by(lngcat)
replace count=count/2
expand `nmiss'
sort lngcat
egen month=fill(1/`repl'  `replh'/12 1/`repl'  `replh'/12) 
tempfile tt
save `tt'
restore
append using `tt'

sort month lng
collapse (sum) count, by(month lngcat)

xtset month lng
xtline count
graph export "haddock_size_class`yr1'.tif", as(tif) replace


save "${BLAST_DIR}/source_data/mrip/haddock_size_class`yr1'.dta", replace
