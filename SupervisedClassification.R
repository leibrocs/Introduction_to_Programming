# load required packages
library(terra)
library(sf)
library(caret)
library(ggplot2)
library(tidyterra)
library(tidyverse)
library(gridExtra)

getwd()

# set working directory if necessary
# setwd("path/to/your/wd")


# set seed
set.seed(455351) # for reproducibility



########## Load and explore the Sentinel-2 Data ##########

# load the extent of the AOI
AOI <- vect("Data/AOI_Extent/AOI.shp")

# load the Sentinel-2 raster layers for 2019 and 2022 and stack the bands
# crop to the extent of the AOI
S2_2022_TCI <- rast("Data/SentinelData/S2A_20221210/TCI.tif") %>%
  terra::crop(AOI)
S2_2022 <- rast(c("Data/SentinelData/S2A_20221210/B02.tif", "Data/SentinelData/S2A_20221210/B03.tif", "Data/SentinelData/S2A_20221210/B04.tif", "Data/SentinelData/S2A_20221210/B05.tif")) %>%
  terra::crop(AOI)

S2_2019_TCI <- rast("Data/SentinelData/S2A_20191027/TCI.tif") %>%
  terra::crop(AOI)
S2_2019 <- rast(c("Data/SentinelData/S2A_20191027/B02.tif", "Data/SentinelData/S2A_20191027/B03.tif", "Data/SentinelData/S2A_20191027/B04.tif", "Data/SentinelData/S2A_20191027/B05.tif")) %>%
  terra::crop(AOI)

# show basic information about the image objects
print()
class()   # get class information
str()     # get structure information
names()   # get layer names
nlayers() # get numbers of layers in the image
extend()  # get extent of the image

# rename bands
bands <- c("B02", "B03", "B04", "B05")

names(S2_2019) <- bands
names(S2_2022) <- bands

# take a first look at the different bands
terra::plot(S2_2019)
terra::plot(S2_2019_TCI) # true color image

terra::plot(S2_2022)
terra::plot(S2_2022_TCI) # true color image



########## Use the NDVI for a first Visualization of the Land Cover Change ##########

# function to calculate the NDVI and the difference NDVI (dNDVI)
NDVI_fun <- function(nir, r){
  ndvi <- (nir - r) / (nir + r)
  return(ndvi)
}

dNDVI_fun <- function(ndvi1, ndvi2){
  delta <- ndvi1 - ndvi2
  return(delta)
}

# calculate the NDVI and dNDVI
ndvi_2019 <- NDVI_fun(S2_2019$B05, S2_2019$B04)
ndvi_2022 <- NDVI_fun(S2_2022$B05, S2_2022$B04)

dNDVI <- dNDVI_fun(ndvi_2022, ndvi_2019)

# plot the NDVI and dNDVI (high values indicating green vegetation, low values bare soil)
ggplot() +
  geom_spatraster(data = ndvi_2019, aes(fill = B05)) +
  scale_fill_gradient2(low = "lightyellow", mid = "navajowhite", high = "darkgreen", 
                       limits = c(minmax(ndvi_2019)), midpoint = 0.1) +
  theme_bw() +
  scale_x_continuous(expand = c(0,0)) +
  scale_y_continuous(expand = c(0,0)) +
  ggtitle("Sentinel-2 NDVI 2019") +
  labs(fill = "NDVI")

ggplot() +
  geom_spatraster(data = ndvi_2022, aes(fill = B05)) +
  scale_fill_gradient2(low = "lightyellow", mid = "navajowhite", high = "darkgreen", 
                       limits = c(minmax(ndvi_2022)), midpoint = 0.1) +
  theme_bw() +
  scale_x_continuous(expand = c(0,0)) +
  scale_y_continuous(expand = c(0,0)) +
  ggtitle("Sentinel-2 NDVI 2022") +
  labs(fill = "NDVI") 

ggplot() +
  geom_spatraster(data = dNDVI, aes(fill = B05)) +
  scale_fill_gradient2(low = "darkgreen", mid = "blue", high = "red", # green: +vegetation, blue: no change, red: -vegetation(new agricultural fields or decrease in vegetation)
                       limits = c(minmax(dNDVI)), midpoint = 0) +
  theme_bw() +
  scale_x_continuous(expand = c(0,0)) +
  scale_y_continuous(expand = c(0,0)) +
  ggtitle("Sentinel-2 dNDVI") +
  labs(fill = "Change")  

# apply linear stretch to the values from [-1, 1] to [0, 255]
ndvi_2019_stretch <- floor((ndvi_2019 + 1) * 128)
ndvi_2022_stretch <- floor((ndvi_2022 + 1) * 128)
dNDVI_stretch <- floor((dNDVI + 1) * 128)

# save the NDVI and dNDVI rasters
writeRaster(ndvi_2019_stretch, filename = "Data/ndvi_2019_stretch.tif", datatype = "FLT4S", overwrite = T)
writeRaster(ndvi_2022_stretch, filename = "Data/ndvi_2022_stretch.tif", datatype = "FLT4S", overwrite = T)
writeRaster(dNDVI_stretch, filename = "Data/dndvi_stretch.tif", datatype = "FLT4S", overwrite = T)

# create a false color image for a first visualization of the land cover change
# reddish colors indicating cropland expansion, blue areas stayed the same, and yellowish areas gained vegetation
falseColor <- rast(c("Data/ndvi_2019_stretch.tif", "Data/ndvi_2022_stretch.tif", "Data/dndvi_stretch.tif"))

terra::plotRGB(falseColor, r = 1, g = 2, b = 3, stretch = 'lin')



########## Training Samples ##########

# download training samples
training_samples <- "Data/TrainingData/TrainingSamples.gpkg"
labeled_poly <- sf::st_read(training_samples)

# remove last two rows with NA values
labeled_poly <- labeled_poly[-48,] %>% labeled_poly[-47,]

# add class names
labeled_poly[1:23, 2] <- "agriculture"
labeled_poly[24:46, 2] <- "natural vegetation"

# load and display labeled training polygons
labeled_poly <- sf::st_transform(labeled_poly, sf::st_crs(S2_2019))

plot(labeled_poly)

# define numeric response variable
labeled_poly$ID
labeled_poly$resp_var <- labeled_poly$ID

# labeled features for training the model:
# features = predictors (e.g. spectra)
# labels = response variable (e.g. classid, but could be continuous as well, e.g. species richness)

# to get labeled features we need points to extract features from
# randomly select some points in the polygon and save their labels to them (get random samples from the image)
labeled_points <- list()

for (i in unique(labeled_poly$resp_var)) {
  message(paste0("Sampling points from polygon with resp_var=", i))
  
  # sample points for polygons of resp_var = i
  labeled_points[[i]] <- sf::st_sample(
    x = labeled_poly[labeled_poly$resp_var == i, ],
    size = 100
  )
  labeled_points[[i]] <- sf::st_as_sf(labeled_points[[i]])
  labeled_points[[i]]$resp_var <- i
}

labeled_points <- do.call(rbind, labeled_points)

# extract features and label them with the response variable
unlabeled_features_2019 <- terra::extract(S2_2019, labeled_points, df = T)
unlabeled_features_2022 <- terra::extract(S2_2022, labeled_points, df = T)
unlabeled_features_2019 <- unlabeled_features_2019[,-1] # no ID column needed
unlabeled_features_2022 <- unlabeled_features_2022[,-1]
labeled_features_2019 <- cbind(resp_var = labeled_points$resp_var, unlabeled_features_2019)
labeled_features_2022 <- cbind(resp_var = labeled_points$resp_var, unlabeled_features_2022)

# remove duplicates (in case multiple points fall into the same pixel)
dupl_2019 <- duplicated(labeled_features_2019) # also length(which(duplicated(labeled_features_2019))) possible ???
dupl_2022 <- duplicated(labeled_features_2022)
length(which(dupl_2019)) # number of duplicates in labeled_features that need to be removed
length(which(dupl_2022))
labeled_features_2019 <- labeled_features_2019[!dupl_2019,]
labeled_features_2022 <- labeled_features_2022[!dupl_2022,]

# x = feature
x_2019 <- labeled_features_2019[,2:ncol(labeled_features_2019)] # removes ID column
x_2022 <- labeled_features_2022[,2:ncol(labeled_features_2022)]
y_2019 <- as.factor(labeled_features_2019$resp_var) # change to factor for caret to treat resp_var as categories
y_2022 <- as.factor(labeled_features_2022$resp_var)
levels(y_2019) <- paste0("class_", levels(y_2019))
levels(y_2022) <- paste0("class_", levels(y_2022))



########## Classification (Random Forest) ##########

# fit the model (Random Forest)
model_2019 <- train(
  x = x_2019,
  y = y_2019,
  trControl = trainControl(
    p = 0.75, # percentage of samples used for training, rest for validation
    method = "cv", # cross-validation
    number = 5, # 5-fold
    verboseIter = TRUE, # progress update per iteration
    classProbs = TRUE, # probabilities for each example
  ),
  preProcess = c("center", "scale"),
  method = "rf"
)

model_2022 <- train(
  x = x_2022,
  y = y_2022,
  trControl = trainControl(
    p = 0.75, 
    method = "cv",
    number = 5, 
    verboseIter = TRUE, 
    classProbs = TRUE, 
  ),
  preProcess = c("center", "scale"),
  method = "rf"
)

# examine model performance
model_2019
model_2022

confusionMatrix(model_2019)
confusionMatrix(model_2022)

# predict the land cover/ use classes
lc_class_2019 <- predict(S2_2019, model_2019, type = 'raw')
lc_class_2022 <- predict(S2_2022, model_2022, type = 'raw')

# map the land cover/ use raster
plot(lc_class_2019)
title(main = "Land Cover Paraguay 2019")

ggplot() +
  geom_spatraster(data = lc_class_2019, aes(fill = class)) +
  scale_fill_manual(values = c('navajowhite','#99d594'), labels = c("Agriculture", "Natural Vegetation")) +
  theme_bw() +
  scale_x_continuous(expand = c(0,0)) +
  scale_y_continuous(expand = c(0,0)) +
  ggtitle("Land Cover Paraguay 2019") +
  labs(fill = "Classes") 

plot(lc_class_2022)
title(main = "Land Cover Paraguay 2022")

ggplot() +
  geom_spatraster(data = lc_class_2022, aes(fill = class)) +
  scale_fill_manual(values = c('navajowhite','#99d594'), labels = c("Agriculture", "Natural Vegetation")) +
  theme_bw() +
  scale_x_continuous(expand = c(0,0)) +
  scale_y_continuous(expand = c(0,0)) +
  ggtitle("Land Cover Paraguay 2022") +
  labs(fill = "Classes")

# compare the land cover from 2019 with the one from 2022 with two pie charts
# raster to dataframe
lc_class2019_df <- data.frame(freq(lc_class_2019)) %>%
  mutate(Area = count * 400 / 10000) %>%                # get area in ha
  rename(Classes = value, Pixels = count)
lc_class2019_df[[1, 2]] <- "Agriculture"
lc_class2019_df[[2, 2]] <- "Natural Vegetation"

lc_class2022_df <- data.frame(freq(lc_class_2022)) %>%
  mutate(Area = count * 400 / 10000) %>%
  rename(Classes = value, Pixels = count)
lc_class2022_df[[1, 2]] <- "Agriculture"
lc_class2022_df[[2, 2]] <- "Natural Vegetation"


lc_pie_2019 <- ggplot(lc_class2019_df, aes(x = "", y = Area, fill = Classes)) +
  geom_col(color = "black") +
  geom_text(aes(label = paste0(Area, " ha")), position = position_stack(vjust = 0.5)) +
  coord_polar(theta = "y") +
  scale_fill_brewer() +
  theme_void() +
  ggtitle("Area of Land Cover Classes 2019")

lc_pie_2022 <- ggplot(lc_class2022_df, aes(x = "", y = Area, fill = Classes)) +
  geom_col(color = "black") +
  geom_text(aes(label = paste0(Area, " ha")), position = position_stack(vjust = 0.5)) +
  coord_polar(theta = "y") +
  scale_fill_brewer() +
  theme_void() +
  ggtitle("Area of Land Cover Classes 2022")

grid.arrange(lc_pie_2019, lc_pie_2022, ncol = 2)

# write and save raster with land cover classification results
writeRaster(lc_class_2019, filename = "Data/S2_20191027_AOI_LC.tif", datatype = "INT1U", overwrite = T)
writeRaster(lc_class_2022, filename = "Data/S2_20221210_AOI_LC.tif", datatype = "INT1U", overwrite = T)

# subtract the two classification rasters to get the land cover change
lc_change <- lc_class_2022 - lc_class_2019

# map the change 
plot(lc_change)
title(main = "Land Cover Change Paraguay") # white indicates cropland expansion, yellow areas refer to no change and in green areas natural vegetation increased

ggplot() +
  geom_spatraster(data = lc_change, aes(fill = class)) +
  scale_fill_gradient2(labels = c("Agricultural Expansion", "", "No Change", "", "Agricultural Loss")) +
  theme_bw() +
  scale_x_continuous(expand = c(0,0)) +
  scale_y_continuous(expand = c(0,0)) +
  ggtitle("Land Use Change from 2019 to 2022") +
  labs(fill = "Change")

# calculate the magnitude of agricultural expansion
agri_change <- freq(lc_change$class) # get the number of pixels for each "change class"
agri_expansion <- agri_change[1,3] * 400 / 1000000 # one pixel measures 20 x 20 m. Divide by 1,000,000 to get the area in km2
print(paste0("Area converted to cropland [km2]: ", agri_expansion))
