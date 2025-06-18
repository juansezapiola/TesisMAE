********************************************************************************
*----------------             Robustness Checks                ----------------* 
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




* 1) KNN Weight Matrix 
*==============================================================================*

/*

The Inverse Arc-Distance Weight matrix of 80km:

Connectivity Information for the Spatial Weights Matrix
  - Sparseness: 5.529%
  - Neighbors: 
      Min   : 1
      Mean  : 18
      Median: 22
      Max   : 31

	  
The Inverse Arc-Distance Weight matrix of 100km:

Connectivity Information for the Spatial Weights Matrix
  - Sparseness: 7.019%
  - Neighbors: 
      Min   : 2
      Mean  : 27
      Median: 31
      Max   : 38


The Inverse Arc-Distance Weight matrix of 120km:

Connectivity Information for the Spatial Weights Matrix
  - Sparseness: 8.427%
  - Neighbors: 
      Min   : 2
      Mean  : 32
      Median: 35
      Max   : 45

	 	  
*/


use "$input/MWI_wide.dta", clear

*We are going to be based on the 80km Matrix as a reference (best performance), so K=18. 


spwmatrix gecon latitud longitud, wn(W18bin) knn(18) xport(W18bin,txt) replace
insheet using "W18bin.txt", delim(" ") clear
drop in 1
rename v1 _ID
save "W18bin.dta", replace


insheet using "W18bin.txt", delim(" ") clear
drop in 1
drop v1
mkmat v2-v96, mat(W18nn_bin)
save W18nn_bin.dta, replace

spmat dta WK18N_st v2-v96, norm(row)
drop v2-v96

set matsize 656
mat TMAT=I(4)
mat W18xt_bin=TMAT#W18nn_bin
svmat W18xt_bin
save "W18xt_bin.dta", replace



* 2) SLM w/ KNN=18
*==============================================================================*

use "$input/MALAWI_panel_Wy_2.dta", clear

*set Panel
xtset ea_id round

*Upload matrix
spwmatrix import using W18xt_bin.dta, wname(W18xt_st) row dta conn

*SLM
xsmle prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe type(both) wmat(WK18N_st) mod(sar) r effects


import delimited "/Users/juansegundozapiola/Documents/Maestria/TesisMAE/input/21_inv_kkn.txt", delimiter(space, collapse) encoding(ISO-8859-1)clear



spwmatrix import using "$input/K_21_inverse.dta", wname(W21inv_st) dta 


































