# load libraries
library(getSpatialData)
library(mapview)
library(terra)
library(sp)
library(utils)

getwd()

# set working directory if necessary
# setwd("path/to/your/wd")

# define output directory
dir_out <- "SentinelData/"


########## Download Data from Sentinel Copernicus Open Access Hub ##########

# login to Copernicus Open Access Hub
login_CopHub("your_username")

# AOI (here, an area in northeastern Paraguay) and define it as search area for the Sentinel-2 scenes
aoi_matrix <- cbind(c(-60.9216, -60.5427, -60.5427, -60.9216), c(-20.7873, -20.7873, -21.1547, -21.1547))
aoi <- set_aoi(aoi_matrix)
view_aoi()

# set time range for the two scenes
# remark: the data for October 2019 in no longer available and provided in the folder 'ClassificationData/SentinelData' 
# time_range2019 <- c("2019-10-01", "2019-10-31") 
time_range2022 <- c("2022-12-01", "2022-12-20")

# search for images per time range
records_2022 <- get_records(time_range2022, products = "Sentinel-2")

# check availability of records
records_2022 <- check_availability(records_2022)

# filter records for cloud coverage, satellite platform, and product type
records_2022 <- records_2022[records_2022$cloudcov <= 10 & 
                               records_2022$platform_serial == "Sentinel-2A" & 
                               records_2022$product_type == "S2MSI2A",]
records_2022 <- records_2022[which(records_2022$cloudcov <= 10 & 
                                     records_2022$platform_serial == "Sentinel-2A" & 
                                     records_2022$product_type == "S2MSI2A"),] # ALTERNATIVE ???

# order images by cloud coverage
records_2022 <- records_2022[order(records_2022$cloudcov),]

# choose image with the least cloud coverage
records_2022 <- records_2022[1,]

# save image in dataframe
records_2022_df <- data.frame(records_2022)

# download previews and plot them
previews_2022 <- data.frame(get_previews(records_2022_df, dir_out = dir_out))

plot_previews(previews_2022)

# download the Sentinel-2 data and save them
records_2022 <- get_data(records_2022, dir_out = dir_out)

# unzip the downloaded files
path_2022 <- paste0(getwd(), "/SentinelData/sentinel-2", sep = "")
zipfile <- list.files(path_2022, pattern = ".zip", full.names = T)
files

# unzip the downloaded files (might not work for all R versions)
# if unzipping files does not work, please do so manually
unzip(files, exdir = path_2022, overwrite = T)