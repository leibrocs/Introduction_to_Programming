# Classification and Change Detection of Cropland in Paraguay

## Background
Agricultural expansion contributes greatly to greenhouse gas emission due to losses of abundant carbon stored by natural vegetation and soils. Satellite imagery shows a significant expansion of croplands during the past two decades. While most regions saw modest increases in the area dedictaed to agriculture, South America stood out. The cultivated land of the continent nearly doubled between 2000 and 2019, which is the largest relative increase in cropland in the world. One of the major contributors to this rise is the rapid expansion of soybean plantations in savannas and dry forest regions in Brazil, Argentina, Paraguay, and Bolivia. In Paraguay, soybeans are replacing more and more pastureland in the northeastern departments of the country. Earth observation and satellite imagery play and important role in mapping and monitoring the expansion of cropland from a regional to a global scale and can be a great tool for finding a balance between increasing agricultural production and the maintenance of ecosystem services. In this project, the goal was to classify and map the cropland in a study region located in the northeast part of Paraguay and to detect as well as quantify changes in the extnet of the cultivated area.

## Data
For this analysis, two Sentinel-2A scenes recoreded during the winter months were used. This was important to ensure, that most fields were not vegetated and clearly distinguishable from natural vegetation. The first scene was acquired in October 2019, the second one in December 2022 with a time interval of roughly three years between them. Both images were recorded on a descending orbit (relative orbit number 110) and had a cloud coverage of below 10 % to prevent classification errors due to clouds.

***Table 1** Sentinel-2A scenes downloaded from the ESA Copernicus Open Access Hub and used for the land cover change analysis.*
| Image Nr. | Acquisition Date | Processing Level | Image ID                                                     |
| --------- | ---------------- | ---------------- | ------------------------------------------------------------ |
| 1         | 2019-10-27       | MSIL2A           | S2A_MSIL2A_20191027T141051_N0213_R110_T20KQB_20191027T163011 |
| 2         | 2022-12-20       | MSIL2A           | S2A_MSIL2A_20221210T140711_N0509_R110_T20KQB_20221210T200157 |

## R Scripts
### SentinelDataDownload
Script to enable the direct download of Sentinel-2 scenes for December 2022 from the ESA Copernicus Open Access Hub. The data for October 2019 is no longer available for direct download from Copernicus and therefore provided in the folder 'SentinelData'. The images for December 2022 are saved in this folder as well, and are advised to be used for the further analysis to ensure a complication-free run of the script 'SupervisedClassification.R'.

### SupervisedClassification
This script was used for to perform a supervised classification of the two Sentinel-2 scenes using a random forest model as well as a change detection. The satellite imagery used for the classification is located in the folder 'SentinelData/' and can be loaded directly into the script. Moreover, it was not possible to used the packages 'raster' and 'RStoolbox' to create training areas directly within RStudio. The reasons for this is, that 'RStoolbox' relies on some functions of the 'raster' package which are depracated and do not work properly with the newest version of R. Therefore, the training samples were previously created in QGIS, stored in the folder 'TrainingData' and can be loaded directly into the script. There are only two classes, namely agriculture and natural vegetation, because the main objective was to map the expansion of cropland in the study region.

### DeforestationAnalysis
Besides the actual analysis, I found an interesting dataset containing various information about the percentage of global forest area and net forest conversion, as well as causes for deforestation in Brazil. I used it to practice my data visualization skills using ggplot2 and included it here as a nice addition of information. Additionally, the data set also stores infromation about the global use of soybeans, which was filtered for Paraguay and serves as a nice addition to the main analysis.

## Results
First, a false color images was used for a quick visualization of the land cover change. The methodical approach is a combination of Image Differencing and Multi Temporal Stacking using NDVI. This way the change is coded by color and the color depends on NDVI intensity in both time stamps (Figure 1).

| ![falseColorNDVI](https://user-images.githubusercontent.com/116877154/232325367-0825ddb0-d269-4f53-b3b8-cc790ff1133e.png) |
|:--:|
| ***Figure1** False color image used for a first visualization of the land cover change in the study region. Reddish colors indicate vegetation loss, yellowish colors vegetation gain. Blue refers to no change.* 

Next, a trained random forest model was used to classify agriculture as well as natural vegetation in the two Sentinel-2 scenes. Performance analysis for both classifications yielded and overall accuracy of 100%. The two classification results can be seen in the Figure below:

| ![LC_19-22](https://user-images.githubusercontent.com/116877154/232326113-5b348110-c2b3-4257-a798-b8e3ac44290f.png) |
|:--:|
| ***Figure 2** Land cover classification results for the study region in Paraguay for October 2019 and December 2022.* |

For further visualization the area occupied by each land cover class was plotted for the two years in a pie chart:

| ![pieChart](https://user-images.githubusercontent.com/116877154/232326333-eb74b313-3dbb-46d0-b622-46d624d14f40.png) |
|:--:|
| ***Figure 3** Area of each land cover class in ha for the years 2019 and 2022.* |

The last step was to map and quatify the land cover change in the study region between the two time stamps. The results of the analysis suggest, that the study region experienced significant expansion of of cropland and therefore a loss of natural vegetation (Figure 4). Due to this change detection the area of natural vegetation lost to agriculture is around 115 km2.

| ![lcChange](https://user-images.githubusercontent.com/116877154/232326656-653f3e0c-21dc-4143-9e3b-8ce9574f1757.png) |
|:--:|
| ***Figure 4** Map of the land cover change in the study region, which directly refers to increases in cultivated land (red).* |
