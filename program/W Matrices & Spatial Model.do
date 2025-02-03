********************************************************************************
*----------------           W Matrices & Spatial model         ----------------* 
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
*drop if total_plot_size==.
export delimited using "$input/MALAWI_panel.csv", replace
*INDEX
*==============================================================================*
*0) Spatial W matrices 
*1) Moran's I and LM tests -> Spatial Model 
*2) Create Wy variable 


*==============================================================================*


* 0) Spatial W matrices 
*==============================================================================*

* 5 KNN neighbours 

use "$input/MWI_wide.dta", clear

spwmatrix gecon latitud longitud, wn(W5bin) knn(5) xport(W5bin,txt) replace
insheet using "W5bin.txt", delim(" ") clear
drop in 1
rename v1 _ID
save "W5bin.dta", replace


insheet using "W5bin.txt", delim(" ") clear
drop in 1
drop v1
mkmat v2-v96, mat(W5nn_bin)
save W5nn_bin.dta, replace

spmat dta W62_st v2-v96, norm(row)
drop v2-v96

set matsize 656
mat TMAT=I(4)
mat W5xt_bin=TMAT#W5nn_bin
svmat W5xt_bin
save "W5xt_bin.dta", replace

* Inverse Arc-Distance (100km)

use "$input/MWI_wide.dta", clear

spwmatrix gecon latitud longitud, wn(W10bin) wtype(inv) dband(0 100) xport(W10bin,txt) replace
insheet using "W10bin.txt", delim(" ") clear
drop in 1
rename v1 _ID
save "W10bin.dta", replace


insheet using "W10bin.txt", delim(" ") clear
drop in 1
drop v1
mkmat v2-v96, mat(W10nn_bin)
save W10nn_bin.dta, replace

spmat dta W10_st v2-v96, norm(row)
drop v2-v96

set matsize 656
mat TMAT=I(4)
mat W10xt_bin=TMAT#W10nn_bin
svmat W10xt_bin
save "W10xt_bin.dta", replace


* rook contiguity (1G)

import delimited "$input/W_rook_contiguity_g1.csv", clear
save "W11bin.dta", replace


mkmat v1-v95, mat(W11nn_bin)
save W11bin.dta, replace

spmat dta W11_st v1-v95, norm(row)
drop v1-v95

set matsize 656
mat TMAT=I(4)
mat W11xt_bin=TMAT#W11nn_bin
svmat W11xt_bin
save "W11xt_bin.dta", replace

* rook contiguity (2G)

import delimited "$input/W_rook_contiguity_g2.csv", clear
save "W12bin.dta", replace


mkmat v1-v95, mat(W12nn_bin)
save W12bin.dta, replace

spmat dta W12_st v1-v95, norm(row)
drop v1-v95

set matsize 656
mat TMAT=I(4)
mat W12xt_bin=TMAT#W12nn_bin
svmat W12xt_bin
save "W12xt_bin.dta", replace


* 1) Moran's I and LM tests -> Spatial Model  
*==============================================================================*

* 5 KNN neighbours 

use "$input/MALAWI_panel.dta", clear

xtset ea_id round

*I do a logistic transformation to prop_imp so to have a log-likelihood function
*I convert a proportion (which is bounded between 0 and 1) into an unbounded continuous
*variable that can be modeled using standard regression techniques like Maximum Likelihood Estimation (MLE)
replace prop_imp=0.999 if prop_imp==1
replace prop_imp = 0.001 if prop_imp == 0
gen log_prop_imp= log(prop_imp/(1-prop_imp))


spwmatrix import using W5xt_bin.dta, wname(W5xt_st) row dta conn

*OLS regresion 
reg log_prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 

estimates store OLS

* Moran's I and LM tests
spatdiag, weights(W5xt_st)


/*
Test                           |  Statistic    df   p-value
-------------------------------+----------------------------
Spatial error:                 |
  Moran's I                    |     2.009      1    0.045
  Lagrange multiplier          |     3.388      1    0.066
  Robust Lagrange multiplier   |     2.288      1    0.130
                               |
Spatial lag:                   |
  Lagrange multiplier          |     5.881      1    0.015
  Robust Lagrange multiplier   |     4.781      1    0.029
------------------------------------------------------------
*/

*Mejor modelo SLM  : Y = \rho W Y + X \beta + \varepsilon




* Inverse Arc-Distance (100km)


use "$input/MALAWI_panel.dta", clear

xtset ea_id round

*I do a logistic transformation to prop_imp so to have a log-likelihood function
*I convert a proportion (which is bounded between 0 and 1) into an unbounded continuous
*variable that can be modeled using standard regression techniques like Maximum Likelihood Estimation (MLE)
replace prop_imp=0.999 if prop_imp==1
replace prop_imp = 0.001 if prop_imp == 0
gen log_prop_imp= log(prop_imp/(1-prop_imp))


spwmatrix import using W10xt_bin.dta, wname(W10xt_st) row dta conn

*OLS regresion 
reg log_prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 

estimates store OLS

* Moran's I and LM tests
spatdiag, weights(W10xt_st)


/*
------------------------------------------------------------
Test                           |  Statistic    df   p-value
-------------------------------+----------------------------
Spatial error:                 |
  Moran's I                    |     2.937      1    0.003
  Lagrange multiplier          |     7.375      1    0.007
  Robust Lagrange multiplier   |     1.044      1    0.307
                               |
Spatial lag:                   |
  Lagrange multiplier          |     9.796      1    0.002
  Robust Lagrange multiplier   |     3.465      1    0.063
------------------------------------------------------------
*/

*Mejor modelo SLM  : Y = \rho W Y + X \beta + \varepsilon



* Rook contiguity (G1)


use "$input/MALAWI_panel.dta", clear

xtset ea_id round

*I do a logistic transformation to prop_imp so to have a log-likelihood function
*I convert a proportion (which is bounded between 0 and 1) into an unbounded continuous
*variable that can be modeled using standard regression techniques like Maximum Likelihood Estimation (MLE)
replace prop_imp=0.999 if prop_imp==1
replace prop_imp = 0.001 if prop_imp == 0
gen log_prop_imp= log(prop_imp/(1-prop_imp))


spwmatrix import using W11xt_bin.dta, wname(W11xt_st) row dta conn

*OLS regresion 
reg log_prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 

estimates store OLS

* Moran's I and LM tests
spatdiag, weights(W11xt_st)


/* NO ME DA I MORAN SIGN
------------------------------------------------------------
Test                           |  Statistic    df   p-value
-------------------------------+----------------------------
Spatial error:                 |
  Moran's I                    |     1.203      1    0.229
  Lagrange multiplier          |     1.041      1    0.308
  Robust Lagrange multiplier   |     5.003      1    0.025
                               |
Spatial lag:                   |
  Lagrange multiplier          |     3.243      1    0.072
  Robust Lagrange multiplier   |     7.206      1    0.007
------------------------------------------------------------

*/ 



* Rook contiguity (G2)


use "$input/MALAWI_panel.dta", clear

xtset ea_id round

*I do a logistic transformation to prop_imp so to have a log-likelihood function
*I convert a proportion (which is bounded between 0 and 1) into an unbounded continuous
*variable that can be modeled using standard regression techniques like Maximum Likelihood Estimation (MLE)
replace prop_imp=0.999 if prop_imp==1
replace prop_imp = 0.001 if prop_imp == 0
gen log_prop_imp= log(prop_imp/(1-prop_imp))


spwmatrix import using W12xt_bin.dta, wname(W12xt_st) row dta conn

*OLS regresion 
reg log_prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 

estimates store OLS

* Moran's I and LM tests
spatdiag, weights(W12xt_st)


/* NO ME DA I MORAN SIGN
------------------------------------------------------------
Test                           |  Statistic    df   p-value
-------------------------------+----------------------------
Spatial error:                 |
  Moran's I                    |     1.120      1    0.263
  Lagrange multiplier          |     0.699      1    0.403
  Robust Lagrange multiplier   |     2.724      1    0.099
                               |
Spatial lag:                   |
  Lagrange multiplier          |     2.437      1    0.119
  Robust Lagrange multiplier   |     4.462      1    0.035
------------------------------------------------------------

*/



*2) Create Wy variable 
*==============================================================================*





































*MCO w/fixed effects
reghdfe prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds prop_advice ///
members_agri_coop agri_coop maize_hybrid_sellers ///
assistant_ag_officer, absorb(round ea_id)

estimates store ols_fe















/*
*sacando esas obs que la regresion por MCO me elimina

use "$input/MALAWI_panel.dta", clear

drop in 375
drop in 356
drop in 351
drop in 331
drop in 311
drop in 295
drop in 183
drop in 163
drop in 144
drop in 35
drop in 31

spwmatrix gecon latitud longitud, wn(W5bin) knn(5) xport(W5bin,txt) replace
insheet using "W5bin.txt", delim(" ") clear
drop in 1
rename v1 _ID
save "W5bin.dta", replace


insheet using "W5bin.txt", delim(" ") clear
drop in 1
drop v1
mkmat v2-v370, mat(W5nn_bin)
save W5nn_bin.dta, replace

spmat dta W57_st v2-v370, norm(row)
drop v2-v370

set matsize 656
mat TMAT=I(1)
mat W5xt_bin=TMAT#W5nn_bin
svmat W5xt_bin
save W5xt_bin.dta, replace


use "$input/MALAWI_panel.dta", clear

drop in 375
drop in 356
drop in 351
drop in 331
drop in 311
drop in 295
drop in 183
drop in 163
drop in 144
drop in 35
drop in 31

spwmatrix import using W5xt_bin.dta, wname(W5xt_st) row dta conn
reg log_prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds prop_advice ///
members_agri_coop agri_coop 

estimates store OLS
*set matsize 1200
spatdiag, weights(W5xt_st)



use "$input/MALAWI_panel.dta", clear

spwmatrix gecon latitud longitud, wn(W5bin) knn(5) xport(W5bin,txt) replace
insheet using "W5bin.txt", delim(" ") clear
drop in 1
rename v1 _ID
save "W5bin.dta", replace


insheet using "W5bin.txt", delim(" ") clear
drop in 1
drop v1
mkmat v2-v381, mat(W5nn_bin)
save W5nn_bin.dta, replace

spmat dta W58_st v2-v381, norm(row)
drop v2-v381

set matsize 656
mat TMAT=I(1)
mat W5xt_bin=TMAT#W5nn_bin
svmat W5xt_bin
save W5xt_bin.dta, replace


use "$input/MALAWI_panel.dta", clear


spwmatrix import using W5xt_bin.dta, wname(W5xt_st) row dta conn
reg log_prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 

estimates store OLS
*set matsize 1200
spatdiag, weights(W5xt_st)

*/















