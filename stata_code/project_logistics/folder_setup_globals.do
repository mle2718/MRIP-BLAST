/* Set up global macros to point to folders */

version 15.1

#delimit ;


/*One of these
global user minyang; 
global user minyangWin; 
*/

/*minyangWin is setup to connect to oracle yet */
if strmatch("$user","minyangWin"){;
	global my_projdir "V:/READ-SSB-Lee-MRIP-BLAST";
	global BLAST_Data "C:/Users/Min-Yang.Lee/Documents/READ-SSB-Lee-BLAST";
	global oracle_cxn " $mysole_conn";

};


if strmatch("$user","minyangNix"){;
	global my_projdir "${myroot}/BLAST/READ-SSB-Lee-MRIP-BLAST";
	global BLAST_Data "$[myroot}/BLAST/projects/READ-SSB-Lee-BLAST";

};





global my_codedir "${my_projdir}/stata_code";
global extract_process "${my_codedir}/data_extraction_processing";
global extraction_code "${extract_process}/extraction";
global processing_code "${extract_process}/processing";
global analysis_code "${my_codedir}/analysis";
global R_code "${my_projdir}/R_code";
global SAS_code "${my_projdir}/SAS_code";

global my_adopath "${my_codedir}/ado";


/* setup data folder */
global my_datadir "${my_projdir}/data_folder";
global data_raw "${my_datadir}/raw";

global data_internal "${my_datadir}/internal";
global data_external"${my_datadir}/external";

global data_main "${my_datadir}/main";

global data_intermediate "${my_datadir}/intermediate";



/* setup results folders */
global intermediate_results "${my_projdir}/intermediate_results";
global my_results "${my_projdir}/results";

/* setup images folders */

global my_images "${my_projdir}/images";
global exploratory "${my_images}/exploratory";

/* setup table folders */
global my_tables "${my_projdir}/tables" ;

/* add the programs in $my_adopath to the adopath*/
adopath + "$my_adopath";

/* older for location of mrip data */
global mrip_estim_pub_2018 "products/mrip_estim/Public_data_cal2018";


/*set the date field */
local date: display %td_CCYY_NN_DD date(c(current_date), "DMY");
global today_date_string = subinstr(trim("`date'"), " " , "_", .);
global vintage_string $today_date_string;


di "$vintage_string";
folder_vintage_lookup_and_reset;


