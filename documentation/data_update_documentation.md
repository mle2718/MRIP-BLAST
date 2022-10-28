# How to update the code that prepares MRIP data for the BLAST model.

# Prereqs

## Directories
MRIP data is stored at ``\\net\mrfss.``  The file ``copy_over_raw_mrip.do`` assumes that directory is mounted ``M.``  You will probably have to do this in windows explorer.

## Stat-tranfser
Ensure that your stat-transfer executable can be found. It is set with in profile.do

# Files that need to be changed

1.  ``extraction_wrapper.do``: Adjust the full years and partial years.  Also adjust the wavelist if needed. We always prototype  the model on wave 4 data and then finish running it when the wave 5 data is released.
2.  ``batch_file_to_process_monthly_mrip_data.do``- we always run on the most recent 2 years of data, so the numlist containing years should be updated.  May have to update the 2b95 hack.
3. ``convert_monthly_to_annual.do`` and ``subset_monthly_mrip`` - adjust the BLAST_DIR and yr1 locals. This is a loop-by-hand. If it is 2022, you need to set ``yr1=2021`` and then ``yr1==2022``
4. ``catch_summaries.txt`` - This is a data summary dynamic document in stata. I use it to print out the trips into a nice document.  You should only need to change  the ``vintage_string`` and ``this_year` globals.  You may need to deal with landings_old 

# Files that shouldn't need to be changed
1. ``batch_file_to_process_annual_mrip_data.do`` - not using an annual timestep.
2. ``copy_over_raw_mrip.do``  -- this just copies file.  

