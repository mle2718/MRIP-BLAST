/* 
This is code to copy over the sas7bdat files as dta files. It relies on stat transfer.


MRIP data is stored in  
"smb://net/mrfss/products/mrip_estim/Public_data_cal2018"
Windows, just mount \\net.nefsc.noaa.gov\mrfss to A:\

*/
/*Change this local to the YYYYW that you want to get*/



/*minyangWin */
if strmatch("$user","minyangWin"){
	local sourcedir "A:/$mrip_estim_pub_2018"
}



/* this probably isn't necessary
cd "${data_raw}" */

/*copy over sas7bdats. Convert them to stata dta */ 
 foreach year of numlist $yearlist{
	foreach wave of numlist $wavelist{
		foreach type in trip size_b2 size catch{

			
			capture ! "$stattransfer"  "`sourcedir'/`type'_`year'`wave'.sas7bdat" "${data_raw}/`type'_`year'`wave'.dta" -Y

			
		}
	}
}



local mylist: dir "${data_raw}" files "*.dta"
local subtract "ma_site_allocation.dta"
local mylist: list mylist - subtract

foreach file of local mylist{
use ${data_raw}/`file', clear
renvars, lower
save ${data_raw}/`file', replace emptyok
qui count

if r(N)==0{
rm ${data_raw}/`file'
}
}







