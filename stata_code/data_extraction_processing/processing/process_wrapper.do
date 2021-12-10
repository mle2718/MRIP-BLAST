
/*this computes calendar year estimates, which you don't really use */
do "$processing_code\batch_file_to_process_annual_mrip_data.do"

/*this computes monthly estimates*/
do "$processing_code\batch_file_to_process_monthly_mrip_data.do"

/*this stacks the month-by-month data and constructs some fishing year estimates */
do "$processing_code\stack_together_monthly_mrip.do"


/* this subsets the mrip data to the relevant months, fills in missing entries, and copies the data over to the working blast folder */

do "$processing_code\subset_monthly_mrip.do"