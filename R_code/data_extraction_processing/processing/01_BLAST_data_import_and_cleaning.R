# This is a port of original BLAST code to clean and prep data. 
library("here")
library("tidyverse")
library("haven")
library("survey")
library("srvyr")
library("DBI")
library("dbplyr")
library("ROracle")

options(scipen=999)

#Handle single PSUs
options(survey.lonely.psu = "certainty")


# Pull in the MRIP_MA_SITE_LIST 
star_dbi_ROracle <- DBI::dbConnect(dbDriver("Oracle"),id, password=novapw, dbname=nefscusers.connect.string)


ma_site_allocation_query<-paste0("select site_id, stock_region_calc from recdbs.mrip_ma_site_list")
ma_site_allocation<-dplyr::tbl(star_dbi_ROracle,sql(ma_site_allocation_query)) %>%
  collect()

names(ma_site_allocation) <- tolower(names(ma_site_allocation))

dbDisconnect(star_dbi_ROracle)


# Pull in the list of catch, size, sizeb2, and trip names

rawpath<-here("data_folder","raw")

catch_names<-list.files(rawpath,pattern=glob2rx("catch_202*.dta"), full.names=TRUE, recursive=FALSE)
size_names<-list.files(rawpath,pattern=glob2rx("size_202*.dta"), full.names=TRUE, recursive=FALSE)
size_b2_names<-list.files(rawpath,pattern=glob2rx("size_b2_202*.dta"), full.names=TRUE, recursive=FALSE)
trip_names<-list.files(rawpath,pattern=glob2rx("trip_202*.dta"), full.names=TRUE, recursive=FALSE)


catch_dataset<-lapply(catch_names, read_dta)
size_dataset<-lapply(size_names, read_dta)
size_b2_dataset<-lapply(size_b2_names, read_dta)
trip_dataset<-lapply(trip_names, read_dta)


catch_dataset<-do.call("bind_rows", catch_dataset)
size_dataset<-do.call("bind_rows", size_dataset)
size_b2_dataset<-do.call("bind_rows", size_b2_dataset)
trip_dataset<-do.call("bind_rows", trip_dataset)

############################## TRIP dataset cleanup ##############################


# Classify trips as "For-Hire" if mode_fx=4, 5. And Private for all other modes.
trip_dataset<-trip_dataset %>%
  mutate(mode=ifelse(mode_fx==4,"FH",ifelse(mode_fx==5,"FH","PR"))
)

# Rename intsite to siteid
trip_dataset<-trip_dataset %>%
  rename(site_id=intsite)

# Left join to ma_site_allocation
trip_dataset<-trip_dataset %>%
  left_join(ma_site_allocation, join_by(site_id==site_id))


#Add the dtrip variable to trips
trip_dataset$dtrip<-1

# Trips in ME or NH are GOM
trip_dataset<-trip_dataset %>%
  mutate(area_s=ifelse(st==23|st==33,"GOM","OTH")
)

#North trips in MA are GOM
trip_dataset<-trip_dataset %>%
  mutate(area_s=ifelse(st==25 & stock_region_calc=="NORTH","GOM", area_s)
         )
#South Trips in MA are GBS  
trip_dataset<-trip_dataset %>%
  mutate(area_s=ifelse(st==25 & stock_region_calc=="SOUTH","GBS", area_s)
)

#South Trips in MA are GBS  
trip_dataset<-trip_dataset %>%
  mutate(prim1_common=str_replace_all(tolower(prim1_common)," ",""),
         prim2_common=str_replace_all(tolower(prim2_common)," ","")
  )



############################## Coalesce some missing or updated column ##############################




#trip_dataset<-trip_dataset %>%
#  mutate(wp_int = coalesce(wp_int, wp_int_chts),
#         wp_size=coalesce(wp_size,wp_size_chts))

catch_dataset<-catch_dataset %>%
  mutate(#wp_catch = coalesce(wp_catch, wp_int),
         var_id=coalesce(var_id,strat_id),
         #wp_int=coalesce(wp_int,wp_int_chts),
         #wp_size=coalesce(wp_size,wp_size_chts),
         #wp_catch=coalesce(wp_catch,wp_catch_chts),
         common=str_replace_all(tolower(common)," ","")
)


size_b2_dataset<-size_b2_dataset %>%
  mutate(#var_id=coalesce(var_id,strat_id),
         #wp_int=coalesce(wp_int,wp_int_chts),
         #wp_size=coalesce(wp_size,wp_size_chts),
         #wp_catch=coalesce(wp_catch,wp_catch_chts)
         common=str_replace_all(tolower(common)," ","")
     
)

size_dataset<-size_dataset %>%
  mutate(var_id=coalesce(var_id,strat_id),
         #wp_int=coalesce(wp_int,wp_int_chts),
         #wp_size=coalesce(wp_size,wp_size_chts),
         #wp_catch=coalesce(wp_catch,wp_catch_chts),
         common=str_replace_all(tolower(common)," ","")
)


# Geographic Filtering
# For GOM COD I need to filter this: 

# keep if sub_reg==4
# keep if st==23 | st==33 |st==25





########################################## Directed Trips ############################
# Directed Trips requires joining trips to catch
# Filter for geography 
# Filter for species 


catch_dataset2<-catch_dataset %>%
  select(year, strat_id, psu_id, common, id_code, tot_cat, claim)














########################################## Catch Frequencies ############################
# Directed Trips requires joining trips to catch
# Filter for geography 
# Filter for species 

trip_catch<-trip_dataset %>%
  dplyr::filter(sub_reg==4 &( st==23 | st==33 |st==25)) %>%
  dplyr::left_join(catch_dataset2, join_by(year==year, strat_id==strat_id, psu_id==psu_id, id_code==id_code), keep=FALSE) %>%
  mutate(claim=ifelse(is.na(claim),0, claim),
         dom_id=2)

# set dom_id=1 if caught or targeted atlanticcod
trip_catch <- trip_catch %>%
  mutate(dom_id=ifelse(common=="atlanticcod",1,dom_id))

trip_catch <- trip_catch %>%
  mutate(dom_id=ifelse(prim1_common=="atlanticcod",1,dom_id))


#Deal with Group Catch -- this bit of code generates a flag for each year-strat_id psu_id leader. (equal to the lowest of the dom_id)
#Then it generates a flag for claim equal to the largest claim.  
#Then it re-classifies the trip into dom_id=1 if that trip had catch of species in dom_id1  
  
# replace dom_id="1" if strmatch(dom_id,"2") & claim_flag>0 & claim_flag!=. & strmatch(gc_flag,"1")

trip_catch <- trip_catch %>%
  group_by(strat_id,psu_id, leader) %>%
  arrange(strat_id,psu_id, leader, dom_id) %>%
  mutate(gc_flag=dplyr::first(dom_id)) %>%
  arrange(strat_id,psu_id, leader, claim) %>%
  mutate(claim_flag=dplyr::last(claim)) 

trip_catch <- trip_catch %>%
  mutate(ifelse(dom_id==2 & claim_flag>0 & is.na(claim_flag)==FALSE & gc_flag==1,1,dom_id) )


tidy_trip_catch_in<-trip_catch %>%
  as_survey_design(id=psu_id, weights=wp_int, strata=var_id, fpc=NULL)


targeted_trips<-tidy_size_in %>%
  filter(area_s=="GOM") %>%
  group_by(year, month, area_s) %>%
  summarise(count=survey_total(dtrip)
)

targeted_trips_by_mode<-tidy_size_in %>%
  filter(area_s=="GOM") %>%
  group_by(year, month, area_s, mode) %>%
  summarise(count=survey_total(dtrip)
  )



########################################## LENGTHS ############################
# Length data requires joining trips to size
# Filter for geography 


########################################## B2 LENGTHS ############################
# Length data requires joining trips to size_b2
# Filter for geography 


size_dataset2<-size_dataset %>%
  select(year, strat_id, psu_id, id_code, common, sp_code, wp_size, l_in_bin)

size_b2_dataset2<-size_b2_dataset %>%
  select(year, strat_id, psu_id, id_code, common, sp_code, wp_size, l_in_bin)


trip_size<-trip_dataset %>%
  dplyr::filter(sub_reg==4 &( st==23 | st==33 |st==25)) %>%
  dplyr::left_join(size_dataset2, join_by(year==year, strat_id==strat_id, psu_id==psu_id, id_code==id_code), keep=FALSE)

trip_b2_size<-trip_dataset %>%
  dplyr::filter(sub_reg==4 &( st==23 | st==33 |st==25)) %>%
  left_join(size_b2_dataset2, join_by(year==year, strat_id==strat_id, psu_id==psu_id, id_code==id_code))




#srvyr data prep
tidy_b2_size_in<-trip_b2_size %>%
  dplyr::filter(common=="atlanticcod") %>%
  as_survey_design(id=psu_id, weights=wp_size, strata=var_id,  nest=TRUE, fpc=NULL)

tidy_size_in<-trip_size %>%
  dplyr::filter(common=="atlanticcod") %>%
  as_survey_design(id=psu_id, weights=wp_size, strata=var_id,  nest=TRUE, fpc=NULL)



# Retained at Length

catch_at_length<-tidy_size_in %>%
  group_by(year, month, area_s, mode) %>%
  summarise(count=survey_total(l_in_bin)
  )
# B2 at length

b2_at_length<-tidy_b2_size_in %>%
  group_by(year, month, area_s, mode) %>%
  summarise(count=survey_total(l_in_bin)
  )






# 
# 
# 
# 
# 
# 
# #srvyr data prep
# tidy_catch_in<-catch_dataset %>%
#   as_survey_design(id=psu_id, weights=wp_int, strata=strat_id,  nest=TRUE, fpc=NULL)
# 
# 
# catch_totals_filtered<-tidy_catch_in %>%
#   group_by(year, month,common_dom ) %>%
#   dplyr::filter(common_dom=="BSB") %>%
#   summarise(tot_cat=survey_total(tot_cat),
#             claim=survey_total(claim),
#             harvest=survey_total(harvest),
#             release=survey_total(release)
#   )
# 
# catch_totals_filtered_stco<-tidy_catch_in %>%
#   group_by(year, month,stco,common_dom ) %>%
#   dplyr::filter(common_dom=="BSB") %>%
#   summarise(tot_cat=survey_total(tot_cat),
#             claim=survey_total(claim),
#             harvest=survey_total(harvest),
#             release=survey_total(release)
#   )
# 
# 
# 
# # Targeting 
# # srvyr data prep
# 
# 
# 
# tidy_trips_in<-trips_dataset %>%
#   as_survey_design(id=psu_id, weights=wp_int, strata=strat_id, fpc=NULL)
# 
# 
# target_totals_by_mode<-tidy_trips_in %>%
#   dplyr::filter(dom_id==1) %>%
#   group_by(year, month,mode ) %>%
#   summarise(dtrip=survey_total(dtrip)
#   )
# 
# target_totals<-tidy_trips_in %>%
#   dplyr::filter(dom_id==1) %>%
#   group_by(year, month ) %>%
#   summarise(dtrip=survey_total(dtrip)
#   )
# 
# 
# target_totals_stco<-tidy_trips_in %>%
#   dplyr::filter(dom_id==1) %>%
#   group_by(year, month,stco ) %>%
#   summarise(dtrip=survey_total(dtrip)
# )
# 
