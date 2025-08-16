################################################################################
####                      Regressions, W & Spatial Model                    ####
####                          Thesis MEcon - UdeSA                          ####
####                                 2025                                   ####
####                          Juan Segundo Zapiola                          ####
################################################################################


#--- Index ---#

# 0) Directory and Libraries. 
# 1) Prepare Data set for Panel
# 2) MCO Regressions
# 3) Spatial Weight matrix (W) and dependency 

#-------------#

#------------------------------------------------------------------------------#
# 0) Directory and Libraries. 

rm(list=ls())

#set directory
setwd("/Users/juansegundozapiola/Documents/Maestria/TesisMAE")

#Libraries
library(haven)
library(stargazer) 
library(plm) 
library(Formula) 
library(dplyr)
library(spdep)
library(geosphere)
library(sf)


#------------------------------------------------------------------------------#

#------------------------------------------------------------------------------#
# 1) Prepare Dataset for Panel 

#Open dataset 
MWI <- read_dta("input/MALAWI_panel.dta")

#chequeo missings
colSums(is.na(MWI[, c("prop_female_head", "mean_age_head", "prop_salaried_head", 
                      "prop_head_edu_1", "prop_head_edu_2", "prop_head_edu_3", 
                      "prop_head_edu_4", "prop_head_edu_5", "prop_head_edu_6", 
                      "prop_head_edu_7", "total_plot_size", "prop_coupon", 
                      "prop_credit", "prop_left_seeds", "prop_advice", "members_agri_coop",
                      "agri_coop", "maize_hybrid_sellers", "assistant_ag_officer")]))

'''
Results: (na obs | percentage of na from total obs)
total_plot_size, prop_coupon, prop_credit, prop_left_seeds, prop_advice:	4 |	1.05%
members_agri_coop:	6	| 1.58%
agri_coop:	7	| 1.84%
maize_hybrid_sellers, assistant_ag_officer:	34	| 8.95%
Since maize_hybrid_sellers, assistant_ag_officer makes me drop 34 obs I prefere removing those variables.
'''

MWI <- MWI %>% dplyr::select(-maize_hybrid_sellers, -assistant_ag_officer)

'''
I have the proportion of improved seeds, but I need an unbounded continuous log likelihood function.
Logit transformation: I convert a proportion (which is bounded between 0 and 1) 
into an unbounded continuous variable that can be modeled using Maximum Likelihood Estimation (MLE).
'''
# So first I replace values in prop_imp
MWI$prop_imp[MWI$prop_imp == 1] <- 0.999
MWI$prop_imp[MWI$prop_imp == 0] <- 0.001

# And then I generate the logit transformation (log-odds) of prop_imp
MWI$log_prop_imp <- log(MWI$prop_imp / (1 - MWI$prop_imp))
summary(MWI$log_prop_imp)

#density plot to visualize
ggplot(MWI, aes(x = log_prop_imp)) +
  geom_density(fill = "blue", alpha = 0.5) +
  labs(title = "Density Plot of Log Prop Imp",
       x = "log_prop_imp") +
  theme_minimal()

#Im going to save this dataset.
write.csv(MWI, file = "input/MALAWI_panel_2.csv", row.names = FALSE)

#Set panel
MWI <- read.csv("input/MALAWI_panel_2.csv")
MWI <- pdata.frame(MWI, index = c("ea_id","round"))
pdim(MWI)

#------------------------------------------------------------------------------#

#------------------------------------------------------------------------------#
# 2) MCO Regresions

model <- formula(log_prop_imp ~ prop_female_head + mean_age_head + prop_salaried_head + prop_head_edu_1 + 
                    prop_head_edu_2 + prop_head_edu_3 + prop_head_edu_4 + prop_head_edu_5 + prop_head_edu_6 +
                    prop_head_edu_7 + total_plot_size + prop_coupon + prop_credit + prop_left_seeds + prop_advice +
                    members_agri_coop + agri_coop) 
                    #+ maize_hybrid_sellers + assistant_ag_officer)
#MCO
MCO <- plm(model, data = MWI, model = "between") 

#MCO con fe
MCO_fe_ea <- plm(model, data = MWI, model = "within")  
MCO_fe_time <- plm(model, data = MWI, model = "within", effect = "time")  
MCO_fe_ea_time <- plm(model, data = MWI, model = "within", effect = "twoways")  

stargazer(MCO, MCO_fe_ea, MCO_fe_time, MCO_fe_ea_time,  
          add.lines=list(c("FE", " ", "EA", "Time", "EA and Time")),
          type="text",
          dep.var.labels=c("Improved Seeds"), 
          out="summary.txt")


#MCO is biased and unconsistent due to spatial dependency

#------------------------------------------------------------------------------#

#------------------------------------------------------------------------------#
# 2) Spatial Weight Matrix (W) and dependency 


'''
The idea is to create 3 weight matrices:
1) Distance-based W (arc-distance)
2) Rook Contiguity G 2 (first included)
3) Nearest Neighbour (5 neighbours) 
'''

#As I have a panel I need unique values of ea_id, longitud and latitud
MWI_unique <- MWI %>%
  dplyr::select(ea_id, longitude, latitude) %>%
  distinct()
coords <- cbind(MWI_unique$longitude, MWI_unique$latitude)
unique_ea <- unique(MWI$ea_id)


# Distance-based W (arc-distance)
distance_matrix <- distm(coords, fun = distHaversine)
nb_arc <- dnearneigh(coords, d1 = 0, d2 = 100, longlat = TRUE)
W_list_nb_arc <- nb2listw(nb_arc, style = "W")  # Row-standardized weights
plot(nb_arc, coords, col = "blue", pch = 20, main = "100km Arc Distance Network")
W_panel_nb_arc <- rep(list(W_list_nb_arc), length(unique(MWI$round)))



#Rook Contiguity G 1 
rook_g1 <- read.gal("input/W_rook_contiguity_g1.gal", region.id = unique_ea)
W_list_rook_g1 <- nb2listw(rook_g1, style = "W")
W_mat <- nb2mat(rook_g1, style = "W")
write.csv(W_mat, "input/W_rook_contiguity_g1.csv", row.names = FALSE)

#Rook Contiguity G 2 (first included)
rook_g2 <- read.gal("input/W_rook_contiguity_g2.gal", region.id = unique_ea)
W_list_rook_g2 <- nb2listw(rook_g2, style = "W")
W_mat_2 <- nb2mat(rook_g2, style = "W")
write.csv(W_mat_2, "input/W_rook_contiguity_g2.csv", row.names = FALSE)

#Nearest Neighbour (5 neighbours) 
nb_5nn <- knn2nb(knearneigh(coords, k = 5, longlat = TRUE))
W_list_5nn <- nb2listw(nb_5nn, style = "W")  # Row-standardized weights

'''
Now that we have the Weight matrices, we need to test spatial dependency and which one is present in our data.
Doing so we can assess the correct model to get our estimates
'''

# Get unique years in the panel dataset
unique_years <- unique(MWI$round)

# Create cross-sectional datasets
MWI_t1 <- filter(MWI, round == unique_years[1])
MWI_t2 <- filter(MWI, round == unique_years[2])
MWI_t3 <- filter(MWI, round == unique_years[3])
MWI_t4 <- filter(MWI, round == unique_years[4])

write.csv(MWI_t1, "input/MWI_t1.csv", row.names = FALSE)
write.csv(MWI_t2, "input/MWI_t2.csv", row.names = FALSE)
write.csv(MWI_t3, "input/MWI_t3.csv", row.names = FALSE)
write.csv(MWI_t4, "input/MWI_t4.csv", row.names = FALSE)


#It was continued in STATA -> see  W Matrices & Spatial model.dta file 



install.packages('reshape2')


# Cargar librerías
library(haven)
library(tidyverse)
library(reshape2)
library(Matrix)
library(spdep)

# Leer archivo .dta
weights_data <- read_dta("/Users/juansegundozapiola/Documents/Maestria/TesisMAE/input/K_21_inverse.dta")

# Inspect the data
head(weights_data)

# Step 2: Rename the columns if needed
# (Assuming your file has columns like origin_id, neighbor_id, weight)
# If not, adapt the names accordingly:
colnames(weights_data) <- c("origin_id", "neighbor_id", "weight")

# Step 3: Ensure diagonal entries are zero
# Add rows for origin_id == neighbor_id with weight = 0 if not present
diagonal_entries <- data.frame(
  origin_id = unique(weights_data$origin_id),
  neighbor_id = unique(weights_data$origin_id)
) %>%
  filter(origin_id == neighbor_id) %>%
  mutate(weight = 0)

# Combine with original weights
full_weights <- bind_rows(weights_data, diagonal_entries)

# Step 4: Pivot to wide format (matrix)
weight_matrix <- full_weights %>%
  pivot_wider(
    names_from = neighbor_id,
    values_from = weight,
    values_fill = list(weight = 0)
  ) %>%
  arrange(origin_id) %>%
  column_to_rownames(var = "origin_id") %>%
  as.matrix()

# Step 5 (optional): Normalize by rows if needed
row_sums <- rowSums(weight_matrix)
weight_matrix_normalized <- sweep(weight_matrix, 1, row_sums, FUN = "/")

# Result
print(weight_matrix[1:5, 1:5])











