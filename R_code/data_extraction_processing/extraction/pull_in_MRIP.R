
# This is code to pull in the sas7bdat and save them as Rds.  
# This code takes a while to run, which is why it's been split apart from the data processing.

##MRIP data is stored in  
#"smb://net/mrfss/products/mrip_estim/Public_data_cal2018"
#Windows, just mount \\net.nefsc.noaa.gov\mrfss to A:\

#A:/products/mrip_estim/Public_data_cal2018


library("here")
library("haven")
library("tidyverse")
library("data.table")
library("ROracle")

here::i_am("R_code/data_extraction_processing/extraction/pull_in_MRIP.R")

# running local 
local_mrip_folder<-file.path("A:","products","mrip_estim","Public_data_cal2018")
network_mrip_folder<-file.path("/home", "mlee","mrfss","products","mrip_estim","Public_data_cal2018")


raw_mrip_folder<-local_mrip_folder


len_dataset<-list()

year<-as.character(2024:2024)
year<-as.data.frame(year)
waves<-as.character(1:6)
waves<-as.data.frame(waves)

yearly<-merge(year,waves, all=TRUE)
readins<-paste0(yearly$year, yearly$waves)

readins<-as.list(readins)  

################################################################################
# Size
################################################################################

#Small function to read in size dataset   

readin_size <- function(waves) {
size_file_in<-file.path(raw_mrip_folder,paste0("size_",waves,".sas7bdat"))
  
  if(file.exists(size_file_in)==TRUE){
    len<-haven::read_sas(size_file_in)
    len<-len %>%
      rename_with(tolower)
    saveRDS(len,file=file.path("data_folder", "raw", paste0("size_",waves,".Rds")))
    haven::write_dta(len,path=file.path("data_folder", "raw", paste0("size_",waves,".dta")), version=14)
    return(len)
    }
}


size_dataset<-lapply(readins,readin_size)
size_dataset2<-rbindlist(size_dataset, fill=TRUE)

################################################################################
# TRIPS
################################################################################
readin_trips <- function(waves) {
  trips_file_in<-file.path(raw_mrip_folder,paste0("trip_",waves,".sas7bdat"))
  
  if(file.exists(trips_file_in)==TRUE){
    trip<-haven::read_sas(trips_file_in)
    trip<-trip %>%
      rename_with(tolower)
    
    saveRDS(trip,file=file.path("data_folder", "raw", paste0("trip_",waves,".Rds")))
    haven::write_dta(trip,path=file.path("data_folder", "raw", paste0("trip_",waves,".dta")), version=14)
    
   return(trip)
  }
}


trips_dataset<-lapply(readins,readin_trips)

trips_dataset2<-rbindlist(trips_dataset, fill=TRUE)




################################################################################
# catch
################################################################################
readin_catch <- function(waves) {
  catch_file_in<-file.path(raw_mrip_folder,paste0("catch_",waves,".sas7bdat"))
  
  if(file.exists(catch_file_in)==TRUE){
    catch<-haven::read_sas(catch_file_in)
    catch<-catch %>%
      rename_with(tolower)
    
    saveRDS(catch,file=file.path("data_folder", "raw", paste0("catch_",waves,".Rds")))
    haven::write_dta(catch,path=file.path("data_folder", "raw", paste0("catch_",waves,".dta")), version=14)
    
    return(catch)
  }
}


catch_dataset<-lapply(readins,readin_catch)

catch_dataset2<-rbindlist(catch_dataset, fill=TRUE)






################################################################################
# SizeB2
################################################################################

#Small function to read in size dataset   

readin_sizeb2 <- function(waves) {
  size_file_in<-file.path(raw_mrip_folder,paste0("size_b2_",waves,".sas7bdat"))
  
  if(file.exists(size_file_in)==TRUE){
    lenb2<-haven::read_sas(size_file_in)
    lenb2<-lenb2 %>%
      rename_with(tolower)
    saveRDS(lenb2,file=file.path("data_folder", "raw", paste0("size_b2_",waves,".Rds")))
    haven::write_dta(lenb2,path=file.path("data_folder", "raw", paste0("size_b2_",waves,".dta")), version=14)
    
    return(lenb2)
  }
}


sizeb2_dataset<-lapply(readins,readin_sizeb2)
sizeb2_dataset2<-rbindlist(sizeb2_dataset, fill=TRUE)



# This shoudl be able to pull in 
# Pull in the MRIP_MA_SITE_LIST 
star_dbi_ROracle <- DBI::dbConnect(dbDriver("Oracle"),id, password=novapw, dbname=nefscusers.connect.string)


ma_site_allocation_query<-paste0("select site_id, stock_region_calc from recdbs.mrip_ma_site_list")
ma_site_allocation<-dplyr::tbl(star_dbi_ROracle,sql(ma_site_allocation_query)) %>%
  collect()

names(ma_site_allocation) <- tolower(names(ma_site_allocation))


dbDisconnect(star_dbi_ROracle)


saveRDS(ma_site_allocation,file=file.path("data_folder", "raw", "ma_site_allocation.Rds"))
haven::write_dta(ma_site_allocation,path=file.path("data_folder", "raw", "ma_site_allocation.dta"), version=14)





