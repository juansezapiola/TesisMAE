################################################################################
####                    SPEI Index & EA's ID Coordinates                    ####
####                          Thesis MEcon - UdeSA                          ####
####                                 2025                                   ####
####                          Juan Segundo Zapiola                          ####
################################################################################


#--- Index ---#

# 0) Directory and Libraries. 
# 1) Create EA's ID Coordinates database. 
# 2) Assign SPEI Index to EA's Coordinates

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


# 2) Assign SPEI Index EA's Coordinates.

#EA's Coordinates 
malawi <- read.csv("input/ea_coordinates.csv")

#SPEI Raster - 3 month SPEI
SPEI_3 <- brick(here::here("/Users/juansegundozapiola/Documents/UdeSA/Thesis/
                           Africa_spei03.nc"), varname= "spei")

#Plot SPEI Index map: Africa
plot(SPEI_3$X1990.06.01)

#Let's crop it to the size of Malawi, using a SHP of Malawi:

malawi_boundary <- st_read("/Users/juansegundozapiola/Documents/UdeSA/Thesis/
                           mwi_adm_nso_hotosm_20230405_shp/mwi_admbnda_adm0_nso_
                           hotosm_20230405.shp")

# Crop and mask the raster using Malawi's boundary
malawi_crop <- crop(SPEI_3, extent(malawi_boundary))
malawi_mask <- mask(malawi_crop, malawi_boundary)

#Plot example.
plot(malawi_mask$X2009.02.01) #
points(malawi$longitude, malawi$latitude, pch = 20, col = "darkred",  cex = 0.5)
# Add the Malawi boundary as a thin border
plot(st_geometry(malawi_boundary), add = TRUE, border = "black", lwd = 0.5)


# Extract SPEI data for the EA's Coordinates
SPEI_data <- extract(SPEI_3, malawi[, c("longitude", "latitude")])

# Convert extracted data to a data.frame
SPEI_ea <- cbind(malawi, SPEI_data)
SPEI_ea <- as.data.frame(SPEI_ea)

#keep only 2009, 2012, 2015, 2019 Feb data
SPEI_ea <- SPEI_ea %>% dplyr::select(ea_id, latitude, longitude, X2009.02.01, 
                                     X2012.02.01, X2015.02.01, X2018.02.01)

# View the result
head(SPEI_ea)

# Rename SPEI variables
SPEI_ea <- SPEI_ea %>% dplyr::rename(SPEI_2009 = X2009.02.01, SPEI_2012 = 
                                       X2012.02.01, SPEI_2015 = X2015.02.01, 
                                     SPEI_2018 = X2018.02.01)

# View the final result
head(SPEI_ea)

#Save as .dta file 
write_dta(SPEI_ea, "input/SPEI_ea.dta")
#write.csv(SPEI_ea, "input/SPEI_ea.csv", row.names = FALSE)

#------------------------------------------------------------------------------#












