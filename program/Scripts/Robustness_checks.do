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
      Min   : 2
      Mean  : 8
      Median: 14
      Max   : 32

	  
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


spwmatrix gecon latitud longitud, wn(W18bin) knn(8) xport(W18bin,txt) replace
insheet using "W18bin.txt", delim(" ") clear
drop in 1
rename v1 _ID
save "W18bin.dta", replace


insheet using "W18bin.txt", delim(" ") clear
drop in 1
drop v1
mkmat v2-v96, mat(W18nn_bin)
save W18nn_bin.dta, replace

spmat dta WK8NNN_st v2-v96, norm(row)
drop v2-v96

set matsize 656
mat TMAT=I(4)
mat W18xt_bin=TMAT#W18nn_bin
svmat W18xt_bin
save "W18xt_bin.dta", replace



* 2) SLM w/ KNN=8
*==============================================================================*

use "$input/MALAWI_panel_Wy_2.dta", clear

*set Panel
xtset ea_id round

*Upload matrix
spwmatrix import using W18xt_bin.dta, wname(W18xt_st) row dta conn

*SLM
xsmle prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe type(both) wmat(WK8NNN_st) mod(sar) r effects


import delimited "/Users/juansegundozapiola/Documents/Maestria/TesisMAE/input/21_inv_kkn.txt", delimiter(space, collapse) encoding(ISO-8859-1)clear



spwmatrix import using "$input/K_21_inverse.dta", wname(W21inv_st) dta 












*OLS w/ Fixed Effects
quietly tab ea_id, gen(nut)
quietly tab round, ge(t)
recast float nut*, force
recast float t*, force


quietly reg prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 t2-t4 

* Moran's I and LM tests
spatdiag, weights(W18xt_st)

/*
------------------------------------------------------------
Test                           |  Statistic    df   p-value
-------------------------------+----------------------------
Spatial error:                 |
  Moran's I                    |     3.655      1    0.000
  Lagrange multiplier          |    11.686      1    0.001
  Robust Lagrange multiplier   |     2.247      1    0.134
                               |
Spatial lag:                   |
  Lagrange multiplier          |    18.349      1    0.000
  Robust Lagrange multiplier   |     8.910      1    0.003
------------------------------------------------------------

*/


*Veo SLX 
splagvar, wname(W18xt_st) ind(prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 prop_head_edu_7 ///
total_plot_size prop_coupon prop_credit prop_left_seeds) wfrom(Stata) order(1)

quietly reg prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit  ///
wx_prop_female_head wx_mean_age_head wx_prop_salaried_head wx_prop_head_edu_1 ///
wx_prop_head_edu_2 wx_prop_head_edu_3 wx_prop_head_edu_4 wx_prop_head_edu_5 wx_prop_head_edu_6 ///
wx_prop_head_edu_7 wx_total_plot_size wx_prop_coupon wx_prop_credit  t2-t4


estimates store SLXpooled_fe
spatdiag, weights(W18xt_st)

/*
------------------------------------------------------------
Test                           |  Statistic    df   p-value
-------------------------------+----------------------------
Spatial error:                 |
  Moran's I                    |     3.013      1    0.003
  Lagrange multiplier          |     3.010      1    0.083
  Robust Lagrange multiplier   |     2.773      1    0.096
                               |
Spatial lag:                   |
  Lagrange multiplier          |     4.670      1    0.031
  Robust Lagrange multiplier   |     4.433      1    0.035
------------------------------------------------------------

*/


*SRARA vs SLM
xsmle prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe type(both) wmat(WK8NNN_st) mod(sar) r

estimates store SLM

xsmle prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe wmat(WK8NNN_st) emat(WK8NNN_st) mod(sac) type(both) nolog r 

estimates store SARAR

lrtest SARAR SLM



*SLM vs SDM

xsmle prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe wmat(WK8NNN_st) mod(sdm) nolog effects r
estimate store SDM

xsmle prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe wmat(WK8NNN_st) mod(sdm) nolog effects r
estimate store SDM


lrtest SLM SDM

/*
Likelihood-ratio test                                 LR chi2(14) =     15.59
(Assumption: SLM nested in SDM)                       Prob > chi2 =    0.3387
*/



