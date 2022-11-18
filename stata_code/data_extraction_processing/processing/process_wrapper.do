
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

global this_working_year 2022




/*this computes calendar year estimates, which you don't really use
do "$processing_code/batch_file_to_process_annual_mrip_data.do"
 */
 
 
/*this computes monthly estimates*/





do "$processing_code/batch_file_to_process_monthly_mrip_data.do"


/* hack the landings from the 2b95 method */



/*this stacks the month-by-month data and constructs some fishing year estimates */
do "$processing_code/stack_together_monthly_mrip_data.do"


/* this subsets the mrip data to the relevant months, fills in missing entries, and copies the data over to the working blast folder */

do "$processing_code/subset_monthly_mrip.do"

/* this subsets the mrip data to the relevant months, aggregates to the fishing year, expands the data, and copies the data over to the working blast folder */

do "$processing_code/convert_monthly_to_annual.do"




/* Write to a html file.*/
dyndoc "$processing_code/catch_summaries.txt", saving($my_results/catch_summaries_${this_working_year}.html) replace
