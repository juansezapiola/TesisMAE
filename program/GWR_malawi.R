################################################################################
####                 GWR: Spatial heterogeneity in Malawi                   ####
####                          Thesis MEcon - UdeSA                          ####
####                                 2024                                   ####
####                          Juan Segundo Zapiola                          ####
################################################################################

rm(list=ls())

#set directory
setwd("/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019")

#Import libraries
library(GISTools)
library(sf)
library(ggplot2)
library(GWmodel)
library(RColorBrewer)
library(terra)
library(spdep)
library(spatialreg)
library(haven)


#Read .dta
data <- read_dta("prop_improved.dta")
data_sf <- st_as_sf(data, coords = c("longitude", "latitude"), crs = 4326)

# Define Coordinates of Malawi
latitud <- c(-9.367308, -17.129398)
longitud <- c(32.673950, 35.918573) 
  


register_stadiamaps(key = "365c36b1-f465-47d0-899c-71cb68f800ab")
# Define the bounding box for Malawi
malawi_map <- get_stadiamap(
  bbox = c(left = 32.673950, bottom = -17.129398, right = 35.918573, top = -9.367308),
  zoom = 7,
  maptype = "stamen_terrain")
# Plot the map
ggmap(malawi_map)

# Plot the reprojected map
malawi_raster <- rast(as.raster(malawi_map))
ext(malawi_raster) <- c(32.673950, 35.918573, -17.129398, -9.367308)
target_crs <- "+proj=utm +zone=36 +south +datum=WGS84 +units=km +no_defs"
malawi_proj <- project(malawi_raster, target_crs)

# Plot the reprojected raster
data_sf <- st_transform(data_sf, crs = st_crs(malawi_proj))

plot(malawi_proj, main = "Reprojected Map of Malawi")
plot(st_geometry(data_sf), col = "red", pch = 16, cex = 0.7, add = TRUE)

#histogram of proportion of improved seeds in R1
histogram <- ggplot(data_sf,aes(x=prop_imp_R1)) +
  geom_histogram(bins=50,aes(y=..density..)) +
  geom_density(fill="#FF6666", alpha=0.5, colour="#FF6666")
histogram

###################################

#Im doing GWR with only one constant 

# lineal regression:
mod.lin <- lm(prop_imp_R1 ~ 1, data = data_sf)
summary(mod.lin)

# Test spatial effects if present (5 nearest neighbors) 
coords <- st_coordinates(data_sf)
kn5 <- knn2nb(knearneigh(coords, k = 5))
dist <- unlist(nbdists(kn5, coords))
summary(dist)  # max distance 226.4677 kms
max_k5 <- max(dist)
# creamos la lista de la matriz W usando distancia de 0 a 1/2*226.4677
neig.dist <- dnearneigh(coords, d1 = 0, d2 = 0.5 * max_k5)
neig.dist
nb.neig.dist <- nb2listw(neig.dist, zero.policy = T)
# calculamos el tes I de Moran 
moran.test(mod.lin$residuals, listw = nb.neig.dist, zero.policy = T)

# Test spatial effects if present (100 km range)
data_sf <- st_transform(data_sf, crs = 4326)
coords <- st_coordinates(data_sf)
neig.dist <- dnearneigh(coords, d1 = 0, d2 = 100, longlat = TRUE)
nb.neig.dist <- nb2listw(neig.dist, zero.policy = TRUE)
summary(neig.dist)
moran.test(mod.lin$residuals, listw = nb.neig.dist, zero.policy = TRUE)



#plot 
res_z <- mod.lin$residuals - mean(mod.lin$residuals)
lag_res <- lag.listw(nb.neig.dist, res_z)
valor.moran <- lm(lag_res ~ res_z)
summary(valor.moran)
moran.diag <- ggplot() + aes(res_z, lag_res) +
  geom_point(shape = 19, size = 3, show.legend = T) +
  geom_point(color='darkblue') +
  geom_smooth(method = "lm", se = FALSE) +
  geom_hline(yintercept=0, linetype="dashed", color = "black") +
  geom_vline(xintercept=0, linetype="dashed", color = "black") +
  labs(title = "Diagrama I de Moran", x = "residuos", y = "W.residuos")
moran.diag

#######################################################
# GWR adaptativa

data_sp <- as(data_sf, "Spatial")
gwr.fix <- gwr.basic(prop_imp_R1 ~ 1, data=data_sp, 
                     bw = 225, kernel = "tricube", adaptive = TRUE)
print(gwr.fix)
data1 <- as.data.frame(gwr.fix$SDF)
histo.beta_prop <- ggplot(data1,aes(x=Intercept)) +
  geom_density(fill="#FF6666", alpha=0.5, colour="#FF6666")
histo.beta_prop

# Bandwidth elegido por CV
bw.1 <- bw.gwr(prop_imp_R1 ~ 1, data=data_sp,
               approach = "CV",kernel = "tricube", adaptive = TRUE)
bw.1
gwr.cv <- gwr.basic(prop_imp_R1 ~ 1, data=data_sp,
                    bw = bw.1, kernel = "tricube", adaptive = TRUE)
print(gwr.cv)
data2 <- as.data.frame(gwr.cv$SDF)
histo.beta_prop2 <- ggplot(data2,aes(x=Intercept)) +
  geom_density(fill="#FF6666", alpha=0.5, colour="#FF6666")
histo.beta_prop2



# Mapeamos los coeficientes de ambas alternativas
# Create the grid based on the extent
bbox_malawi <- c(left = 32.673950, bottom = -17.129398, right = 35.918573, top = -9.367308)
origin <- c(bbox_malawi[1], bbox_malawi[2])
cell_size <- c(0.05, 0.05)  # Adjust cell size if needed (in degrees, since CRS is 4326)
cells_dim <- c(ceiling((bbox_malawi["right"] - bbox_malawi["left"]) / cell_size[1]),
               ceiling((bbox_malawi["top"] - bbox_malawi["bottom"]) / cell_size[2]))

# Create the Spatial Grid
grid <- SpatialGrid(GridTopology(origin, cell_size, cells_dim))

# Plot the grid to verify
plot(grid, main = "Spatial Grid Over Malawi")

grid_points <- as(grid, "SpatialPoints")


gwr.fix1 <- gwr.basic(prop_imp_R1 ~ 1, data=data_sp, regression.points=grid, 
                      bw = 225, kernel = "tricube", adaptive = TRUE)
gwr.cv1 <- gwr.basic(prop_imp_R1 ~ 1, data=data_sp, regression.points=grid, 
                     bw = bw.1, kernel = "tricube", adaptive = TRUE)

cols <- brewer.pal(9, "BuPu")
pal <- colorRampPalette(cols)

par(mfrow=c(1,2))

plot(malawi_proj)
image(gwr.fix1$SDF,'Intercept',col=adjustcolor(pal(20),alpha.f=0.8), add=TRUE, legend=TRUE)
contour(gwr.fix1$SDF,'Intercept',lwd=3,add=TRUE,labcex = 1.1, col='gray10')

malawi_shapefile <- st_read("/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/mw.shp")
malawi_boundary <- st_boundary(malawi_shapefile)



#Plot R1
par(mar = c(5, 4, 4, 8)) 
plot(malawi_proj)
image(gwr.cv1$SDF,'Intercept',col=adjustcolor(pal(20),alpha.f=0.7), add=TRUE, legend=TRUE)
contour(gwr.cv1$SDF,'Intercept',lwd=1,add=TRUE,labcex = 0.8, col='black')
plot(malawi_boundary, add = TRUE, col = "darkred", lwd = 2)
legend(x = "bottomright", inset = c(0, 0.1),  # Place legend slightly outside the plot area
       legend = round(seq(min(gwr.cv1$SDF$Intercept, na.rm = TRUE),
                          max(gwr.cv1$SDF$Intercept, na.rm = TRUE),
                          length.out = 6), 2),
       fill = adjustcolor(pal(6), alpha.f = 0.5),
       title = "Intercept Coefficients", cex = 0.8, xpd = TRUE)



############## R2

#histogram of proportion of improved seeds in R2
histogram_R2 <- ggplot(data_sf,aes(x=prop_imp_R2)) +
  geom_histogram(bins=50,aes(y=..density..)) +
  geom_density(fill="#FF6666", alpha=0.5, colour="#FF6666")
histogram_R2


# lineal regression:
mod.lin_R2 <- lm(prop_imp_R2 ~ 1, data = data_sf)
summary(mod.lin_R2)

# calculamos el tes I de Moran 
moran.test(mod.lin_R2$residuals, listw = nb.neig.dist, zero.policy = T)


#plot 
res_z <- mod.lin_R2$residuals - mean(mod.lin_R2$residuals)
lag_res <- lag.listw(nb.neig.dist, res_z)
valor.moran <- lm(lag_res ~ res_z)
summary(valor.moran)
moran.diag_R2 <- ggplot() + aes(res_z, lag_res) +
  geom_point(shape = 19, size = 3, show.legend = T) +
  geom_point(color='darkblue') +
  geom_smooth(method = "lm", se = FALSE) +
  geom_hline(yintercept=0, linetype="dashed", color = "black") +
  geom_vline(xintercept=0, linetype="dashed", color = "black") +
  labs(title = "Diagrama I de Moran", x = "residuos", y = "W.residuos")
moran.diag_R2

gwr.fix_R2 <- gwr.basic(prop_imp_R2 ~ 1, data=data_sp, 
                     bw = 225, kernel = "tricube", adaptive = TRUE)
print(gwr.fix_R2)
data1_R2 <- as.data.frame(gwr.fix_R2$SDF)
histo.beta_prop_R2 <- ggplot(data1_R2,aes(x=Intercept)) +
  geom_density(fill="#FF6666", alpha=0.5, colour="#FF6666")
histo.beta_prop_R2

# Bandwidth elegido por CV
bw.1_R2 <- bw.gwr(prop_imp_R2 ~ 1, data=data_sp,
               approach = "CV",kernel = "tricube", adaptive = TRUE)
bw.1_R2
gwr.cv_R2 <- gwr.basic(prop_imp_R2 ~ 1, data=data_sp,
                    bw = bw.1, kernel = "tricube", adaptive = TRUE)
print(gwr.cv_R2)
data2_R2 <- as.data.frame(gwr.cv_R2$SDF)
histo.beta_prop2_R2 <- ggplot(data2_R2,aes(x=Intercept)) +
  geom_density(fill="#FF6666", alpha=0.5, colour="#FF6666")
histo.beta_prop2_R2



gwr.fix1_R2 <- gwr.basic(prop_imp_R2 ~ 1, data=data_sp, regression.points=grid, 
                      bw = 225, kernel = "tricube", adaptive = TRUE)
gwr.cv1_R2 <- gwr.basic(prop_imp_R2 ~ 1, data=data_sp, regression.points=grid, 
                     bw = bw.1_R2, kernel = "tricube", adaptive = TRUE)

#plot
par(mar = c(5, 4, 4, 8)) 
plot(malawi_proj)
image(gwr.cv1_R2$SDF,'Intercept',col=adjustcolor(pal(20),alpha.f=0.7), add=TRUE, legend=TRUE)
contour(gwr.cv1_R2$SDF,'Intercept',lwd=1,add=TRUE,labcex = 0.8, col='black')
plot(malawi_boundary, add = TRUE, col = "darkred", lwd = 2)
legend(x = "bottomright", inset = c(0, 0.1),  # Place legend slightly outside the plot area
       legend = round(seq(min(gwr.cv1_R2$SDF$Intercept, na.rm = TRUE),
                          max(gwr.cv1_R2$SDF$Intercept, na.rm = TRUE),
                          length.out = 6), 2),
       fill = adjustcolor(pal(6), alpha.f = 0.5),
       title = "Intercept Coefficients", cex = 0.8, xpd = TRUE)


############## R3

gwr.fix_R3 <- gwr.basic(prop_imp_R3 ~ 1, data=data_sp, 
                        bw = 225, kernel = "tricube", adaptive = TRUE)
print(gwr.fix_R3)
data1_R3 <- as.data.frame(gwr.fix_R3$SDF)
histo.beta_prop_R3 <- ggplot(data1_R3,aes(x=Intercept)) +
  geom_density(fill="#FF6666", alpha=0.5, colour="#FF6666")
histo.beta_prop_R3

# Bandwidth elegido por CV
bw.1_R3 <- bw.gwr(prop_imp_R3 ~ 1, data=data_sp,
                  approach = "CV",kernel = "tricube", adaptive = TRUE)
bw.1_R3
gwr.cv_R3 <- gwr.basic(prop_imp_R3 ~ 1, data=data_sp,
                       bw = bw.1, kernel = "tricube", adaptive = TRUE)
print(gwr.cv_R3)
data2_R3 <- as.data.frame(gwr.cv_R3$SDF)
histo.beta_prop2_R3 <- ggplot(data2_R3,aes(x=Intercept)) +
  geom_density(fill="#FF6666", alpha=0.5, colour="#FF6666")
histo.beta_prop2_R3



gwr.fix1_R3 <- gwr.basic(prop_imp_R3 ~ 1, data=data_sp, regression.points=grid, 
                         bw = 225, kernel = "tricube", adaptive = TRUE)
gwr.cv1_R3 <- gwr.basic(prop_imp_R3 ~ 1, data=data_sp, regression.points=grid, 
                        bw = bw.1_R3, kernel = "tricube", adaptive = TRUE)

#plot
par(mar = c(5, 4, 4, 8)) 
plot(malawi_proj)
image(gwr.cv1_R3$SDF,'Intercept',col=adjustcolor(pal(20),alpha.f=0.7), add=TRUE, legend=TRUE)
contour(gwr.cv1_R3$SDF,'Intercept',lwd=1,add=TRUE,labcex = 0.8, col='black')
plot(malawi_boundary, add = TRUE, col = "darkred", lwd = 2)
legend(x = "bottomright", inset = c(0, 0.1),  # Place legend slightly outside the plot area
       legend = round(seq(min(gwr.cv1_R3$SDF$Intercept, na.rm = TRUE),
                          max(gwr.cv1_R3$SDF$Intercept, na.rm = TRUE),
                          length.out = 6), 2),
       fill = adjustcolor(pal(6), alpha.f = 0.5),
       title = "Intercept Coefficients", cex = 0.8, xpd = TRUE)

############## R4

gwr.fix_R4 <- gwr.basic(prop_imp_R4 ~ 1, data=data_sp, 
                        bw = 225, kernel = "tricube", adaptive = TRUE)
print(gwr.fix_R4)
data1_R4 <- as.data.frame(gwr.fix_R4$SDF)
histo.beta_prop_R4 <- ggplot(data1_R4,aes(x=Intercept)) +
  geom_density(fill="#FF6666", alpha=0.5, colour="#FF6666")
histo.beta_prop_R4

# Bandwidth elegido por CV
bw.1_R4 <- bw.gwr(prop_imp_R4 ~ 1, data=data_sp,
                  approach = "CV",kernel = "tricube", adaptive = TRUE)
bw.1_R4
gwr.cv_R4 <- gwr.basic(prop_imp_R4 ~ 1, data=data_sp,
                       bw = bw.1, kernel = "tricube", adaptive = TRUE)
print(gwr.cv_R4)
data2_R4 <- as.data.frame(gwr.cv_R4$SDF)
histo.beta_prop2_R4 <- ggplot(data2_R4,aes(x=Intercept)) +
  geom_density(fill="#FF6666", alpha=0.5, colour="#FF6666")
histo.beta_prop2_R4



gwr.fix1_R4 <- gwr.basic(prop_imp_R4 ~ 1, data=data_sp, regression.points=grid, 
                         bw = 225, kernel = "tricube", adaptive = TRUE)
gwr.cv1_R4 <- gwr.basic(prop_imp_R4 ~ 1, data=data_sp, regression.points=grid, 
                        bw = bw.1_R4, kernel = "tricube", adaptive = TRUE)

#plot
par(mar = c(5, 4, 4, 8)) 
plot(malawi_proj)
image(gwr.cv1_R4$SDF,'Intercept',col=adjustcolor(pal(20),alpha.f=0.7), add=TRUE, legend=TRUE)
contour(gwr.cv1_R4$SDF,'Intercept',lwd=1,add=TRUE,labcex = 0.8, col='black')
plot(malawi_boundary, add = TRUE, col = "darkred", lwd = 2)
legend(x = "bottomright", inset = c(0, 0.1),  # Place legend slightly outside the plot area
       legend = round(seq(min(gwr.cv1_R4$SDF$Intercept, na.rm = TRUE),
                          max(gwr.cv1_R4$SDF$Intercept, na.rm = TRUE),
                          length.out = 6), 2),
       fill = adjustcolor(pal(6), alpha.f = 0.5),
       title = "Intercept Coefficients", cex = 0.8, xpd = TRUE)



################# Plots of each round

#Plot R1
par(mar = c(5, 4, 4, 8)) 
plot(malawi_proj)
image(gwr.cv1$SDF,'Intercept',col=adjustcolor(pal(20),alpha.f=0.7), add=TRUE, legend=TRUE)
contour(gwr.cv1$SDF,'Intercept',lwd=1,add=TRUE,labcex = 0.8, col='black')
plot(malawi_boundary, add = TRUE, col = "darkred", lwd = 2)
legend(x = "bottomright", inset = c(0, 0.1),  # Place legend slightly outside the plot area
       legend = round(seq(min(gwr.cv1$SDF$Intercept, na.rm = TRUE),
                          max(gwr.cv1$SDF$Intercept, na.rm = TRUE),
                          length.out = 6), 2),
       fill = adjustcolor(pal(6), alpha.f = 0.5),
       title = "Intercept Coefficients", cex = 0.8, xpd = TRUE)


#Plot R2
par(mar = c(5, 4, 4, 8)) 
plot(malawi_proj)
image(gwr.cv1_R2$SDF,'Intercept',col=adjustcolor(pal(20),alpha.f=0.7), add=TRUE, legend=TRUE)
contour(gwr.cv1_R2$SDF,'Intercept',lwd=1,add=TRUE,labcex = 0.8, col='black')
plot(malawi_boundary, add = TRUE, col = "darkred", lwd = 2)
legend(x = "bottomright", inset = c(0, 0.1),  # Place legend slightly outside the plot area
       legend = round(seq(min(gwr.cv1_R2$SDF$Intercept, na.rm = TRUE),
                          max(gwr.cv1_R2$SDF$Intercept, na.rm = TRUE),
                          length.out = 6), 2),
       fill = adjustcolor(pal(6), alpha.f = 0.5),
       title = "Intercept Coefficients", cex = 0.8, xpd = TRUE)



#Plot R3
par(mar = c(5, 4, 4, 8)) 
plot(malawi_proj)
image(gwr.cv1_R3$SDF,'Intercept',col=adjustcolor(pal(20),alpha.f=0.7), add=TRUE, legend=TRUE)
contour(gwr.cv1_R3$SDF,'Intercept',lwd=1,add=TRUE,labcex = 0.8, col='black')
plot(malawi_boundary, add = TRUE, col = "darkred", lwd = 2)
legend(x = "bottomright", inset = c(0, 0.1),  # Place legend slightly outside the plot area
       legend = round(seq(min(gwr.cv1_R3$SDF$Intercept, na.rm = TRUE),
                          max(gwr.cv1_R3$SDF$Intercept, na.rm = TRUE),
                          length.out = 6), 2),
       fill = adjustcolor(pal(6), alpha.f = 0.5),
       title = "Intercept Coefficients", cex = 0.8, xpd = TRUE)

#Plot R4
par(mar = c(5, 4, 4, 8)) 
plot(malawi_proj)
image(gwr.cv1_R4$SDF,'Intercept',col=adjustcolor(pal(20),alpha.f=0.7), add=TRUE, legend=TRUE)
contour(gwr.cv1_R4$SDF,'Intercept',lwd=1,add=TRUE,labcex = 0.8, col='black')
plot(malawi_boundary, add = TRUE, col = "darkred", lwd = 2)
legend(x = "bottomright", inset = c(0, 0.1),  # Place legend slightly outside the plot area
       legend = round(seq(min(gwr.cv1_R4$SDF$Intercept, na.rm = TRUE),
                          max(gwr.cv1_R4$SDF$Intercept, na.rm = TRUE),
                          length.out = 6), 2),
       fill = adjustcolor(pal(6), alpha.f = 0.5),
       title = "Intercept Coefficients", cex = 0.8, xpd = TRUE)

