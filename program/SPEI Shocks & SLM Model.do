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

*0) No Spatial Model

*1) SLM -no shock- Model

*2) SLM Shock Interraction Model 

*==============================================================================*

* 0) No Spatial Model
*==============================================================================*
use "$input/MALAWI_panel_Wy_2.dta", clear

*set Panel
xtset ea_id round

*no fixed effects
reg prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, robust
estat ic 
*w/ fixed effects
reghdfe prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, absorb(round ea_id) 
estat ic 



* 1) SLM -no shock- Model
*==============================================================================*
spwmatrix import using W5xt_bin.dta, wname(W5xt_st) row dta conn

*To make this run go to W Matrices & Spatial Model do file and run again the W matrix with another name 
xsmle prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe type(both) wmat(WKK5N_st) mod(sar) r effects

estimates store SLM



spwmatrix import using W10xt_bin.dta, wname(W10xt_st) row dta conn

xsmle prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe type(both) wmat(WARC_st) mod(sar) r effects

estimates store SLM_2




*2) SLM Shock Interraction Model 
*==============================================================================*


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
xsmle prop_imp sev_shock prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe type(both) wmat(WKK5N_st) mod(sar)  vce(cluster grid_id) 

estimates store SLM_sev_shock


*more severe shock 
xsmle prop_imp Sev_shock prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe type(both) wmat(WKK5N_st) mod(sar)  vce(cluster grid_id) 

estimates store SLM_Sev_shock

*Interaction effect shock and WY

gen sev_wy = sev_shock * Wy_prop
gen Sev_wy = Sev_shock * Wy_prop


xsmle prop_imp sev_wy prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe type(both) wmat(WKK5N_st) mod(sar) vce(cluster grid_id) 

estimates store SLM_sev_wy


xsmle prop_imp Sev_wy prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe type(both) wmat(WKK5N_st) mod(sar) vce(cluster grid_id) 

estimates store SLM_Sev_wy


estimates table SLM SLM_sev_shock SLM_sev_wy SLM_Sev_shock SLM_Sev_wy, b(%7.3f) se p stats(N ll aic) stf(%9.0f) drop(t*)


*Inverse Arc_distance (100km)

* severe shock
xsmle prop_imp sev_shock prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 prop_coupon prop_credit prop_left_seeds, fe type(both) wmat(WARC_st) mod(sar) vce(cluster grid_id)

estimates store SLM_sev_shock_2



*more severe shock
xsmle prop_imp Sev_shock prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7  prop_coupon prop_credit prop_left_seeds, fe type(both) wmat(WARC_st) mod(sar) vce(cluster grid_id)

estimates store SLM_Sev_shock_2


*Interaction effect shock and WY

gen sev_wy_2 = sev_shock * Wy_2
gen Sev_wy_2 = Sev_shock * Wy_2


xsmle log_prop_imp sev_wy_2 prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe type(both) wmat(WAAA_st) mod(sar) vce(cluster grid_id)

estimates store SLM_sev_wy_2


xsmle log_prop_imp Sev_wy_2 prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe type(both) wmat(WAAA_st) mod(sar) vce(cluster grid_id)
*Sign al 5%
estimates store SLM_Sev_wy_2


estimates table SLM_2 SLM_sev_shock_2 SLM_sev_wy_2 SLM_Sev_shock_2 SLM_Sev_wy_2, b(%7.3f) se p stats(N ll aic) stf(%9.0f) drop(t*)

*==============================================================================*

*Pensar como estructurar la tabla
*Preguntar si poner ese interraction effect no hay problema con multicolinealidad perf con rho. 




