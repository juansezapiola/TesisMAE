################################################################################
####                       EA's ID Coordinates & SPEI                       ####
####                          Thesis MEcon - UdeSA                          ####
####                                 2025                                   ####
####                          Juan Segundo Zapiola                          ####
################################################################################


#--- Index ---#

# 0) Directory and Libraries. 
# 1) Create EA's ID Coordinates database. 
# 2) Assign SPEI Index to Grid Cells.

#-------------#

# 0) Directory and Libraries 
rm(list=ls())

#set directory
setwd("/Users/juansegundozapiola/Documents/Maestria/TesisMAE")

#libraries 
library(haven)
library(dplyr)

library(sf)
library(sp)
library(ncdf4)
library(here)
library(ggplot2)
library(foreign)
library(raster)

#------------------------------------------------------------------------------#

# 1) Create EA's ID Coordinates database.

#open database that contain EA's coordinates
prop_improved <- read_dta("input/prop_improved.dta")

#keep EA's id and coordinates
ea_coordinates <- prop_improved %>% select(-prop_imp_R1, -prop_imp_R2, 
                                           -prop_imp_R3, -prop_imp_R4)

#Save data base in csv file
write.csv(ea_coordinates, file = "input/ea_coordinates.csv", row.names = FALSE)

#------------------------------------------------------------------------------#


# 2) Assign SPEI Index to Grid Cells

#EA's Coordinates 
malawi <- read.csv("input/ea_coordinates.csv")

#SPEI Raster - 3 month SPEI
SPEI_3 <- brick(here::here("/Users/juansegundozapiola/Documents/UdeSA/Thesis/Africa_spei03.nc"), varname= "spei")

#Plot SPEI Index map: Africa
plot(SPEI_3$X1990.06.01)

#Let's crop it to the size of Malawi, using a SHP of Malawi:

malawi_boundary <- st_read("/Users/juansegundozapiola/Documents/UdeSA/Thesis/mwi_adm_nso_hotosm_20230405_shp/mwi_admbnda_adm0_nso_hotosm_20230405.shp")

# Crop and mask the raster using Malawi's boundary
malawi_crop <- crop(SPEI_3, extent(malawi_boundary))
malawi_mask <- mask(malawi_crop, malawi_boundary)

#Plot example.
plot(malawi_mask$X2009.02.01) #
points(malawi$longitude, malawi$latitude, pch = 20, col = "red",  cex = 0.5)
# Add the Malawi boundary as a thin border
plot(st_geometry(malawi_boundary), add = TRUE, border = "black", lwd = 0.5)







