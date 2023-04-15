# Cropland Expansion in Paraguay

## Background
Agricultural expansion contributes greatly to greenhouse gas emission due to losses of abundant carbon stored by natural vegetation and soils. Satellite imagery shows a significant expansion of croplands during the past two decades. While most regions saw modest increases in the area dedictaed to agriculture, one South America stood out. The cultivated land of the continent nearly doubled between 2000 and 2019, which is the largest relative increase in cropland in the world. One of the major contributors to this rise is the rapid expansion of sobean plantations in savannas and dry forest regions in Brazil, Argentina, Paraguay, and Bolivia. In Paraguay, soybeans are replacing more and more pastureland in the northeastern departments of the country. In the North deforestation has virtually reached its conclusion where only about seven percent of the Interior Atlantic Forest remain. Earth observation and satellite imagery plays and important role in mapping and monitoring the expansion of cropland from a regional to a global scale and can be a great tool for balancing increasing agricultural production with maintenance of ecosystem services. In this project, the goal was to classify and map the cropland in a study region located in the northeast of Paraguay and to detect as well as quantify changes in the extnet of the cultivated area.

## Data
For the analysis, two Sentinel-SA scenes recoreded during the winter months were used. This was of importancte to ensure that most fields were not vegetated and clearly distinguishable from natural vegetation. The first scene was acquired in October 2019, the second one in December 2022 with a time interval of roughly three years between them. Both images were recorded on a descending orbit (relative orbit number 110) and had a cloud coverage of below 10 % to prevent classification errors due to clouds.

***Table 1** Sentinel-2A scenes downloaded from Copernicus Open Access Hub and used for the land cover change analysis.*
| Image Nr. | Acquisition Date | Processing Level | Image ID                                                     |
| --------- | ---------------- | ---------------- | ------------------------------------------------------------ |
| 1         | 2019-10-27       | MSIL2A           | S2A_MSIL2A_20191027T141051_N0213_R110_T20KQB_20191027T163011 |
| 2         | 2022-12-20       | MSIL2A           | S2A_MSIL2A_20221210T140711_N0509_R110_T20KQB_20221210T200157 |

## R Scripts
# SentinelDataDownload
Used for direct download of Sentinel-2 scenes for two different time periods from the Copernicus Open Access Hub. It is advised to store the Data in the foler 'SentinelData/sentinel-2/'. 
Remark: The data for October 2019 is no longer available for direct download from Copernicus and therefore provided in the folder 'ClassificationData/SentinelData/' (alongside the data for December 2022 for convinience).

# SupervisedClassification
Script used for a supervised classification of the two Sentinel-2 scenes and a change detection. The data used for classification is located in the folder 'ClassificationData/SentinelData/' and can be loaded directly into the script. Moreover, it was not possible to used tha packages 'raster' and 'RStoolbox' to create training areas directly in R, because they were not working properly with the newest version of R. Therefore, the training samples were previously created in QGIS and then loaded into the script. They are stored in the folder 'ClassificationData/TrainingSamples/'. There are only two classes, namely agriculture and natural vegetation, since the main objective was to map the expansion of cropland in the study region.

# DeforestationAnalysis
Besides the actual analysis, I found an interesting dataset containing various information about the percentage of global forest area and net forest conversion, as well as causes for deforestation in Brazil. I used it to practice my data visualization skills using ggplot2 and included it here as a nice addition of information.
