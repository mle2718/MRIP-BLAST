
cd "/home/mlee/Documents/Workspace/MRIP_working/source files"
global my_codedir "/home/mlee/Documents/Workspace/MRIP_working/code"
global my_outputdir "/home/mlee/Documents/Workspace/MRIP_working/outputs"
global my_sourcedir "/home/mlee/Documents/Workspace/MRIP_working/source files"

local date: display %td_CCYY_NN_DD date(c(current_date), "DMY")
global date_string = "2018_11_19"

global my_outputdir "/home/mlee/Documents/Workspace/MRIP_working/outputs/MRIP_$date_string"


cd "$my_outputdir"
pause on
global cod_lwa 0.000005132
global cod_lwb 3.1625
global had_lwa 0.000009298
global had_lwe 3.0205
global lngcat_offset_cod 0.5
global lngcat_offset_haddock 0.5

global mt_to_kilo=1000
global kilo_to_lbs=2.20462262
global cm_to_inch=0.39370787

use "$my_outputdir/cod_ab1_2018.dta", clear 


gen cod_fish_weight=$kilo_to_lbs*$cod_lwa*((l_in_bin)/$cm_to_inch)^$cod_lwb
gen cl=count*l_in_bin
gen cw=count*cod_fish_weight

collapse (sum) cl cw count, by(month)
gen length=cl/count
gen weight=cw/count

browse
pause
use "$my_outputdir/atlanticcod_b2_counts_2018.dta", clear 


gen cod_fish_weight=$kilo_to_lbs*$cod_lwa*((l_in_bin)/$cm_to_inch)^$cod_lwb
gen cl=b2_count*l_in_bin
gen cw=b2_count*cod_fish_weight

collapse (sum) cl cw b2_count, by(year month)
gen length=cl/b2_count
gen weight=cw/b2_count
order month cl cw weight length b2_count
browse month cl cw b2_count length weight   if year==2018
browse
pause


use "$my_outputdir/haddock_ab1_2018.dta", clear 


gen haddock_fish_weight=$kilo_to_lbs*$had_lwa*((l_in_bin)/$cm_to_inch)^$had_lwe
gen cl=count*l_in_bin
gen cw=count*haddock_fish_weight

collapse (sum) cl cw count, by(month)
gen length=cl/count
gen weight=cw/count
browse
pause

use "$my_outputdir/haddock_b2_counts_2018.dta", clear 


gen haddock_fish_weight=$kilo_to_lbs*$had_lwa*((l_in_bin)/$cm_to_inch)^$had_lwe
gen cl=b2_count*l_in_bin
gen cw=b2_count*haddock_fish_weight

collapse (sum) cl cw b2_count, by(year month)
gen length=cl/b2_count
gen weight=cw/b2_count
order month weight length b2_count
browse month cl cw b2_count length weight   if year==2018
browse
pause
