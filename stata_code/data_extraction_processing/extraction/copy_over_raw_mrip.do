/* 
This is code to copy over the sas7bdat files as dta files. It relies on stat transfer.


MRIP data is stored in  
"smb://net/mrfss/products/mrip_estim/Public_data_cal2018"


You made a "mounts" directory for data4
what you need to do is "mount" it in nautilus and then you can run this code.
http://colans.net/blog/how-mount-windows-file-share-ubuntu-1304
/run/user/1000/gvfs/smb-share:server=net,share=mrfss/products/mrip_estim/Public_data_cal2018
ln -s /run/user..... ~/mounts/data4


! cp "`sourcedir'/trip_20182.sas7bdat" "${data_raw}/trip_20182.sas7bdat"


In Windows, you 


*/
/*Change this local to the YYYYW that you want to get*/


local sourcedir "/run/user/1000/gvfs/smb-share:server=net,share=mrfss/$mrip_estim_pub_2018"

local sourcedir "M:/$mrip_estim_pub_2018"


global yearlist 2021(1)2021
global wavelist 1(1)6
cd "${data_raw}"

/*copy over sas7bdats. Convert them to stata dta */ 
 foreach year of numlist $yearlist{
	foreach wave of numlist $wavelist{
		foreach type in trip size_b2 size catch{
			
			capture copy  "`sourcedir'/`type'_`year'`wave'.sas7bdat" "${data_raw}/`type'_`year'`wave'.sas7bdat", replace
			capture ! "$stattransfer" "${data_raw}/`type'_`year'`wave'.sas7bdat" "${data_raw}/`type'_`year'`wave'.dta" -Y
			capture rm  "${data_raw}/`type'_`year'`wave'.sas7bdat"
			
		}
	}
}




/*

capture ! "$stattransfer" "`sourcedir'/trip_`year'`wave'.sas7bdat" "${data_raw}/trip_`year'`wave'.dta" -Y
		capture ! $stattransfer "`sourcedir'/size_b2_`year'`wave'.sas7bdat" "${data_raw}/size_b2_`year'`wave'.dta" -Y
		capture ! $stattransfer "`sourcedir'/size_`year'`wave'.sas7bdat" "${data_raw}/size_`year'`wave'.dta" -Y 
		capture ! $stattransfer "`sourcedir'/catch_`year'`wave'.sas7bdat" "${data_raw}/catch_`year'`wave'.dta" -Y 
		

*/

local mylist: dir "${data_raw}" files "*.dta"


foreach file of local mylist{
use ${data_raw}/`file', clear
renvars, lower
save ${data_raw}/`file', replace emptyok
qui count

if r(N)==0{
rm ${data_raw}/`file'
}
}



*/



