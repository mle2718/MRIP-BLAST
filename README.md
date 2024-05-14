# MRIP-BLAST

A repository that holds code to process MRIP data to get it ready for BLAST.  

1. Add an "if" statement in /READ-SSB-Lee-MRIP-BLAST/stata_code/project_logistics/folder_setup_globals.do to include your personalized project directory, BLAST folder, and mrfss.

2.  Mount the \\net\mrfss drive 

3. Run folder_setup_globals.do 

3. Run ``\stata_code\data_extraction_processing\extraction_wrapper.do'' copies data from the network share.

4. Run ``\stata_code\data_extraction_processing\processing\process_wrapper.do``

4. Run ``\stata_code\data_extraction_processing\processing\process_wrapper_lengths_by_mode.do``



# NOAA Requirements
This repository is a scientific product and is not official communication of the National Oceanic and Atmospheric Administration, or the United States Department of Commerce. All NOAA GitHub project code is provided on an "as is" basis and the user assumes responsibility for its use. Any claims against the Department of Commerce or Department of Commerce bureaus stemming from the use of this GitHub project will be governed by all applicable Federal law. Any reference to specific commercial products, processes, or services by service mark, trademark, manufacturer, or otherwise, does not constitute or imply their endorsement, recommendation or favoring by the Department of Commerce. The Department of Commerce seal and logo, or the seal and logo of a DOC bureau, shall not be used in any manner to imply endorsement of any commercial product or activity by DOC or the United States Government.


1. who worked on this project:  Min-Yang Lee
1. when this project was created: November, 2021 
1. what the project does:Gets MRIP data ready for BLAST
1. why the project is useful:  Gets MRIP data ready for BLAST
1. how users can get started with the project: Download and follow the readme
1. where users can get help with your project:  email me or open an issue

# License file
See here for the [license file](License.txt)
