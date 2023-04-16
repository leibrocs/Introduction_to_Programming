# classification and Change Detection of Cropland in Paraguay

## Background
Agricultural expansion contributes greatly to greenhouse gas emission due to losses of abundant carbon stored by natural vegetation and soils. Satellite imagery shows a significant expansion of croplands during the past two decades. While most regions saw modest increases in the area dedictaed to agriculture, South America stood out. The cultivated land of the continent nearly doubled between 2000 and 2019, which is the largest relative increase in cropland in the world. One of the major contributors to this rise is the rapid expansion of soybean plantations in savannas and dry forest regions in Brazil, Argentina, Paraguay, and Bolivia. In Paraguay, soybeans are replacing more and more pastureland in the northeastern departments of the country. Earth observation and satellite imagery play and important role in mapping and monitoring the expansion of cropland from a regional to a global scale and can be a great tool for finding a balance between increasing agricultural production and the maintenance of ecosystem services. In this project, the goal was to classify and map the cropland in a study region located in the northeast part of Paraguay and to detect as well as quantify changes in the extnet of the cultivated area.

## Data
For this analysis, two Sentinel-SA scenes recoreded during the winter months were used. This was important to ensure, that most fields were not vegetated and clearly distinguishable from natural vegetation. The first scene was acquired in October 2019, the second one in December 2022 with a time interval of roughly three years between them. Both images were recorded on a descending orbit (relative orbit number 110) and had a cloud coverage of below 10 % to prevent classification errors due to clouds.

***Table 1** Sentinel-2A scenes downloaded from the ESA Copernicus Open Access Hub and used for the land cover change analysis.*
| Image Nr. | Acquisition Date | Processing Level | Image ID                                                     |
| --------- | ---------------- | ---------------- | ------------------------------------------------------------ |
| 1         | 2019-10-27       | MSIL2A           | S2A_MSIL2A_20191027T141051_N0213_R110_T20KQB_20191027T163011 |
| 2         | 2022-12-20       | MSIL2A           | S2A_MSIL2A_20221210T140711_N0509_R110_T20KQB_20221210T200157 |

## R Scripts
### SentinelDataDownload
Script to enable the direct download of Sentinel-2 scenes for December 2022 from the ESA Copernicus Open Access Hub. The data for October 2019 is no longer available for direct download from Copernicus and therefore provided in the folder 'SentinelData'. The images for December 2022 are stored in this folder as well, and can be used for the further analysis to prevent complications with the script 'SupervisedClassification.R'.

### SupervisedClassification
This script was used for to conduct a supervised classification of the two Sentinel-2 scenes as well as a change detection. The satellite imagery used for the classification is located in the folder 'SentinelData/' and can be loaded directly into the script. Moreover, it was not possible to used the packages 'raster' and 'RStoolbox' to create training areas directly within RStudio. The reasons for this is, that 'RStoolbox' relies on some functions of the 'raster' package which are depracated and do not work properly with the newest version of R. Therefore, the training samples were previously created in QGIS, stored in the folder 'TrainingData' and can be loaded directly into the script. There are only two classes, namely agriculture and natural vegetation, because the main objective was to map the expansion of cropland in the study region.

### DeforestationAnalysis
Besides the actual analysis, I found an interesting dataset containing various information about the percentage of global forest area and net forest conversion, as well as causes for deforestation in Brazil. I used it to practice my data visualization skills using ggplot2 and included it here as a nice addition of information. Additionally, the data set also stores infromation about the global use of soybeans, which was filtered for Paraguay and serves as a nice addition to the main analysis.

## Results

