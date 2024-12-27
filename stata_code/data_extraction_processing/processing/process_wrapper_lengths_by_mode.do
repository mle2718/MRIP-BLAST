
/* setup dirs */
global workdir "${data_main}/MRIP_$vintage_string"
capture mkdir "$workdir"

global my_images_vintage "${my_images}/MRIP_$vintage_string"
cap mkdir $my_images_vintage


global monthlydir "${workdir}/monthly"
capture mkdir "$monthlydir"
global fishing_years "${workdir}/fishing_years"
capture mkdir "$fishing_years"

global annual "${workdir}/annual"
capture mkdir "$annual"

global stacked_month "${workdir}/stacked_monthly"
capture mkdir "$stacked_month"



global modedir "${workdir}/mode"
capture mkdir "$modedir"


/*this global controls a few other subfiles*/
global this_working_year 2024

global process_list 2024


*global stacked_dir "${workdir}/stacked_monthly"
global BLAST_DIR "${BLAST_root}/cod_haddock_fy2025/source_data/mrip"



/*this computes monthly estimates by mode*/





do "$processing_code/batch_lengths_by_mode.do"


/* hack the landings from the 2b95 method */






