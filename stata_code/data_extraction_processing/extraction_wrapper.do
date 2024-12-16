/* after running do $BLAST_MRIP */
/* get the mass location data from oracle */

do ${extraction_code}/get_ma_allocation.do


/* copying over partial years of data */
global yearlist 2024(1)2024
global wavelist 5(1)1
*global wavelist 1(1)4

do ${extraction_code}/copy_over_raw_mrip.do

/* copying over full years of data */
global yearlist 2020(1)2023
global wavelist 1(1)6

do ${extraction_code}/copy_over_raw_mrip.do