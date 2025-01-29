********************************************************************************
*----------------        Regressions, Tables & Graphs          ----------------* 
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


use  "$input/MALAWI_panel.dta", clear 


 
*INDEX
*==============================================================================*
*0) Prepare panel data
*1)


*==============================================================================*



* 0) Prepare panel data 
*==============================================================================*


xtset ea_id round



*Prueba MCO
reghdfe prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds prop_advice ///
members_agri_coop agri_coop maize_hybrid_sellers ///
assistant_ag_officer, absorb(round grid_id) cluster(grid_id) 


*esta mal porque yo tengo que hacer MV no MCO
*Tengo que tomar LOG













