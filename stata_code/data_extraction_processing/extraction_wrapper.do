/* after running do $BLAST_MRIP */
/* get the mass location data from oracle */

*do ${extraction_code}/get_ma_allocation.do


/* copying over full years of data */
global yearlist 2019(1)2022
global wavelist 1(1)6

do ${extraction_code}/copy_over_raw_mrip.do



/* copying over partial years of data */
global yearlist 2023(1)2023
*global wavelist 1(1)5
global wavelist 1(1)4

do ${extraction_code}/copy_over_raw_mrip.do
