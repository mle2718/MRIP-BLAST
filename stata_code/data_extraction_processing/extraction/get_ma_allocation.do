
/* read in and store the MRIP location stuff.  Put it in the file ma_site_allocation.dta */
clear
#delimit;
odbc load,  exec("select site_id, stock_region_calc from recdbs.mrip_ma_site_list;") $mysole_conn;

/* will need to switch the connection string to $myNEFSC_USERS_conn soon */


/* patch in the extra site_id */

qui count;
local newobs=`r(N)'+1;
set obs `newobs';

replace site_id=4434 if site_id==.;
replace stock_region_calc="NORTH" if site_id==4434;

save "${data_raw}/ma_site_allocation.dta", replace;