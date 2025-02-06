********************************************************************************
*----------------           SPEI Shocks & SLM Model            ----------------* 
*----------------                                              ----------------*
*----------------	         Juan Segundo Zapiola              ----------------* 
*----------------				                               ----------------* 
*----------------          Universidad de San Andrés           ----------------* 
*----------------             Tesis Maestría Econ              ----------------* 
*----------------				    2025                       ----------------* 
********************************************************************************

*clean 
clear all

*Directory 	
cd "/Users/juansegundozapiola/Documents/Maestria/TesisMAE"						
gl main "/Users/juansegundozapiola/Documents/Maestria/TesisMAE"
gl input "$main/input"
gl output "$main/output"


*INDEX
*==============================================================================*

*1) SLM -no shock- Model

*2) SLM Shock Interraction Model 

*==============================================================================*


* 1) SLM -no shock- Model
*==============================================================================*

use "$input/MALAWI_panel_Wy.dta", clear

*set Panel
xtset ea_id round


spwmatrix import using W5xt_bin.dta, wname(W5xt_st) row dta conn


xsmle log_prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe type(both) wmat(WKKK_st) mod(sar) r

estimates store SLM



spwmatrix import using W10xt_bin.dta, wname(W10xt_st) row dta conn

xsmle log_prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe type(both) wmat(WAA_st) mod(sar) r

estimates store SLM_2




*2) SLM Shock Interraction Model 
*==============================================================================*


use "$input/MALAWI_panel_Wy.dta", clear

*set Panel

xtset ea_id round


gen sev_shock=1 if SPEI<-1.49 
replace sev_shock=0 if sev_shock==.


sum SPEI if SPEI <-1.49 //mean: -1.60


gen Sev_shock=1 if SPEI<-1.602  
replace Sev_shock=0 if Sev_shock==.



tab sev_shock round

/*
sev_ext_sh |                    round
           |         1          2          3          4 |     Total
-----------+--------------------------------------------+----------
         0 |        73         95         94         73 |       335 
         1 |        22          0          1         22 |        45 
-----------+--------------------------------------------+----------
     Total |        95         95         95         95 |       380 

	 
Most shocks occur during the year before Round 1 and Round 4. 
(remember the shock is the year before of the round)	 
*/

tab Sev_shock round

/*
           |                    round
 Sev_shock |         1          2          3          4 |     Total
-----------+--------------------------------------------+----------
         0 |        81         95         95         87 |       358 
         1 |        14          0          0          8 |        22 
-----------+--------------------------------------------+----------
     Total |        95         95         95         95 |       380 

*/

*5KNN

* severe shock 
xsmle log_prop_imp sev_shock prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe type(both) wmat(WKKK_st) mod(sar)  vce(cluster grid_id) 

*more severe shock 
xsmle log_prop_imp Sev_shock prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe type(both) wmat(WKKK_st) mod(sar)  vce(cluster grid_id) 


gen sev_wy = sev_shock * Wy_1
gen Sev_wy = Sev_shock * Wy_1


xsmle log_prop_imp sev_shock sev_wy prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe type(both) wmat(WKKK_st) mod(sar) vce(cluster grid_id) 

xsmle log_prop_imp Sev_shock Sev_wy prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe type(both) wmat(WKKK_st) mod(sar) vce(cluster grid_id) 



*Inverse Arc_distance (100km)

* severe shock
xsmle log_prop_imp sev_shock prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe type(both) wmat(WAAA_st) mod(sar) vce(cluster grid_id)

*more severe shock
xsmle log_prop_imp Sev_shock prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe type(both) wmat(WAAA_st) mod(sar) vce(cluster grid_id)


gen sev_wy_2 = sev_shock * Wy_2
gen Sev_wy_2 = Sev_shock * Wy_2


xsmle log_prop_imp sev_shock sev_wy_2 prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe type(both) wmat(WAAA_st) mod(sar) vce(cluster grid_id)

xsmle log_prop_imp Sev_shock Sev_wy_2 prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe type(both) wmat(WAAA_st) mod(sar) vce(cluster grid_id)


*==============================================================================*



