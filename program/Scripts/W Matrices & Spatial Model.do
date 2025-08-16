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
*export delimited using "$input/MALAWI_panel.csv", replace


*INDEX
*==============================================================================*
*1) Spatial W matrices 
*2) Moran's I and LM tests -> Spatial Model 

*==============================================================================*


* 1) Spatial W matrices 
*==============================================================================*

******* 5 KNN neighbours 

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

spmat dta Wk5N_st v2-v96, norm(row)
drop v2-v96

set matsize 656
mat TMAT=I(4)
mat W5xt_bin=TMAT#W5nn_bin
svmat W5xt_bin
save "W5xt_bin.dta", replace

******* Inverse Arc-Distance (100km)

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

spmat dta W100arc_st v2-v96, norm(row)
drop v2-v96

set matsize 656
mat TMAT=I(4)
mat W10xt_bin=TMAT#W10nn_bin
svmat W10xt_bin
save "W10xt_bin.dta", replace

******* Inverse Arc-Distance (80km)

use "$input/MWI_wide.dta", clear

spwmatrix gecon latitud longitud, wn(W80bin) wtype(inv) dband(0 80) xport(W80bin,txt) replace
insheet using "W80bin.txt", delim(" ") clear
drop in 1
rename v1 _ID
save "W80bin.dta", replace


insheet using "W80bin.txt", delim(" ") clear
drop in 1
drop v1
mkmat v2-v96, mat(W80nn_bin)
save W80nn_bin.dta, replace

spmat dta W80arc80_st v2-v96, norm(row)
drop v2-v96

set matsize 656
mat TMAT=I(4)
mat W80xt_bin=TMAT#W80nn_bin
svmat W80xt_bin
save "W80xt_bin.dta", replace



******* Inverse Arc-Distance (120km)]

use "$input/MWI_wide.dta", clear

spwmatrix gecon latitud longitud, wn(W120bin) wtype(inv) dband(0 120) xport(W120bin,txt) replace
insheet using "W120bin.txt", delim(" ") clear
drop in 1
rename v1 _ID
save "W120bin.dta", replace


insheet using "W120bin.txt", delim(" ") clear
drop in 1
drop v1
mkmat v2-v96, mat(W120nn_bin)
save W120nn_bin.dta, replace

spmat dta W120arc_st v2-v96, norm(row)
drop v2-v96

set matsize 656
mat TMAT=I(4)
mat W120xt_bin=TMAT#W120nn_bin
svmat W120xt_bin
save "W120xt_bin.dta", replace




******* rook contiguity (1G)

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

******** rook contiguity (2G)

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


* 2) Moran's I and LM tests -> Spatial Model  
*==============================================================================*



* 5 KNN neighbours
* Inverse Arc-Distance (100km)

* Rook Contiguity - (No relevant for this work)



*------------------------------ 5 KNN neighbours ------------------------------*
use "$input/MALAWI_panel.dta", clear

xtset ea_id round

*I do a logistic transformation to prop_imp so to have a log-likelihood function
*I convert a proportion (which is bounded between 0 and 1) into an unbounded continuous
*variable that can be modeled using standard regression techniques like Maximum Likelihood Estimation (MLE)
replace prop_imp=0.999 if prop_imp==1
replace prop_imp = 0.001 if prop_imp == 0
gen log_prop_imp= log(prop_imp/(1-prop_imp))


spwmatrix import using W5xt_bin.dta, wname(WKKK5N_st) row dta conn

*OLS regresion 
reg log_prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7

reg prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7


estimates store OLS

* Moran's I and LM tests
spatdiag, weights(W5xt_st)




*OLS w/ Fixed Effects
quietly tab ea_id, gen(nut)
quietly tab round, ge(t)
recast float nut*, force
recast float t*, force

quietly reg log_prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 t2-t4 
estimates store OLS_fe

quietly reg prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 t2-t4 
estimates store OLS_fe

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
------------------------------------------------------------
Test                           |  Statistic    df   p-value
-------------------------------+----------------------------
Spatial error:                 |
  Moran's I                    |     3.348      1    0.001
  Lagrange multiplier          |     9.989      1    0.002
  Robust Lagrange multiplier   |     3.601      1    0.058
                               |
Spatial lag:                   |
  Lagrange multiplier          |    16.159      1    0.000
  Robust Lagrange multiplier   |     9.772      1    0.002
------------------------------------------------------------



con FE
------------------------------------------------------------
Test                           |  Statistic    df   p-value
-------------------------------+----------------------------
Spatial error:                 |
  Moran's I                    |     2.038      1    0.042
  Lagrange multiplier          |     3.527      1    0.060
  Robust Lagrange multiplier   |     1.613      1    0.204
                               |
Spatial lag:                   |
  Lagrange multiplier          |     5.936      1    0.015
  Robust Lagrange multiplier   |     4.022      1    0.045
------------------------------------------------------------
------------------------------------------------------------
Test                           |  Statistic    df   p-value
-------------------------------+----------------------------
Spatial error:                 |
  Moran's I                    |     3.413      1    0.001
  Lagrange multiplier          |    10.462      1    0.001
  Robust Lagrange multiplier   |     2.455      1    0.117
                               |
Spatial lag:                   |
  Lagrange multiplier          |    16.272      1    0.000
  Robust Lagrange multiplier   |     8.265      1    0.004
------------------------------------------------------------


*/

*Veo SLX 

splagvar, wname(W5xt_st) ind(prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 prop_head_edu_7 ///
total_plot_size prop_coupon prop_credit prop_left_seeds) wfrom(Stata) order(1)

quietly reg log_prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds ///
wx_prop_female_head wx_mean_age_head wx_prop_salaried_head wx_prop_head_edu_1 ///
wx_prop_head_edu_2 wx_prop_head_edu_3 wx_prop_head_edu_4 wx_prop_head_edu_5 wx_prop_head_edu_6 ///
wx_prop_head_edu_7 wx_total_plot_size wx_prop_coupon wx_prop_credit wx_prop_left_seeds t2-t4

quietly reg prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds ///
wx_prop_female_head wx_mean_age_head wx_prop_salaried_head wx_prop_head_edu_1 ///
wx_prop_head_edu_2 wx_prop_head_edu_3 wx_prop_head_edu_4 wx_prop_head_edu_5 wx_prop_head_edu_6 ///
wx_prop_head_edu_7 wx_total_plot_size wx_prop_coupon wx_prop_credit wx_prop_left_seeds t2-t4


estimates store SLXpooled_fe
spatdiag, weights(W5xt_st)

/*
------------------------------------------------------------
Test                           |  Statistic    df   p-value
-------------------------------+----------------------------
Spatial error:                 |
  Moran's I                    |     2.010      1    0.044
  Lagrange multiplier          |     1.366      1    0.243
  Robust Lagrange multiplier   |     3.077      1    0.079
                               |
Spatial lag:                   |
  Lagrange multiplier          |     2.806      1    0.094
  Robust Lagrange multiplier   |     4.517      1    0.034
------------------------------------------------------------
------------------------------------------------------------
Test                           |  Statistic    df   p-value
-------------------------------+----------------------------
Spatial error:                 |
  Moran's I                    |     3.652      1    0.000
  Lagrange multiplier          |     7.491      1    0.006
  Robust Lagrange multiplier   |     1.831      1    0.176
                               |
Spatial lag:                   |
  Lagrange multiplier          |     8.642      1    0.003
  Robust Lagrange multiplier   |     2.982      1    0.084
------------------------------------------------------------


Puede ser SDM y no SDEM (no es sign al 5%)
*/



*SLM vs SARAR

eststo SLM: xsmle log_prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe type(both) wmat(WKK5N_st) mod(sar) r
estadd  local Time_FE "Yes"
estadd  local EA_FE "Yes"



xsmle log_prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe wmat(WK_st) emat(WKK5 _st) mod(sac) r

estimates store SARAR


eststo SLM: xsmle prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe type(both) wmat(WKKK5N_st) mod(sar) r
estadd  local Time_FE "Yes"
estadd  local EA_FE "Yes"
estat ic 

xsmle prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe wmat(WKKK5N_st) emat(WKKK5N_st) mod(sac) r

estimates store SARAR

lrtest SARAR SLM //SARAR is not statistically better than SLM. p-v=1.0
/*

Likelihood-ratio test                                 LR chi2(1)  =     -3.24
(Assumption: SLM nested in SARAR)                     Prob > chi2 =    1.0000


*/

*SLM vs SDM

xsmle log_prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe wmat(WK_st) mod(sdm) nolog effects r
estimate store SDM

xsmle prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe wmat(WKKK5N_st) mod(sdm) nolog effects r
estimate store SDM


lrtest SLM SDM //SLM is prefered p-v=0.70

/*

Likelihood-ratio test                                 LR chi2(14) =     10.82
(Assumption: SLM nested in SDM)                       Prob > chi2 =    0.7000

*/



*SDEM

eststo SDEM: xsmle log_prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds ///
wx_prop_female_head wx_mean_age_head wx_prop_salaried_head wx_prop_head_edu_1 ///
wx_prop_head_edu_2 wx_prop_head_edu_3 wx_prop_head_edu_4 wx_prop_head_edu_5 wx_prop_head_edu_6 ///
wx_prop_head_edu_7 wx_total_plot_size wx_prop_coupon wx_prop_credit wx_prop_left_seeds t2-t4 t2-t4, fe ematrix(WK_st) model(sem) nolog r
estadd  local Time_FE "Yes"
estadd  local EA_FE "Yes"

estimate store SDEM




*SLX

xtreg log_prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds ///
wx_prop_female_head wx_mean_age_head wx_prop_salaried_head wx_prop_head_edu_1 ///
wx_prop_head_edu_2 wx_prop_head_edu_3 wx_prop_head_edu_4 wx_prop_head_edu_5 wx_prop_head_edu_6 ///
wx_prop_head_edu_7 wx_total_plot_size wx_prop_coupon wx_prop_credit wx_prop_left_seeds t2-t4, fe

estimates store SLX_fe

*MCO
eststo OLS: reg log_prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds
estadd  local Time_FE "NO"
estadd  local EA_FE "No"


estimates store OLS

*MCO w/fixed effects
eststo OLS_fe: reghdfe log_prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, absorb(round)
estadd  local Time_FE "Yes"
estadd  local EA_FE "No"

estimates store OLS_fe



estimates table SLM, b(%7.3f) se p stats(N ll aic) stf(%9.0f) drop(t*)


*Mejor modelo SLM  : Y = \rho W Y + X \beta + \varepsilon. Dependencia espacial sustantiva

splagvar, wname(W5xt_st) ind(prop_imp) wfrom(Stata) order(1) 

rename wx_prop_imp Wy_prop

*------------------------------------------------------------------------------*


*----------------------- Inverse Arc-Distance (100km) -------------------------*


use "$input/MALAWI_panel.dta", clear

xtset ea_id round
replace prop_imp=0.999 if prop_imp==1
replace prop_imp = 0.001 if prop_imp == 0
gen log_prop_imp= log(prop_imp/(1-prop_imp))


spwmatrix import using W10xt_bin.dta, wname(W10xt_st) row dta conn

*OLS regresion 
reg log_prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 

reg prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 

estimates store OLS

* Moran's I and LM tests
spatdiag, weights(W10xt_st)


*OLS w/ Fixed Effects
quietly tab ea_id, gen(nut)
quietly tab round, ge(t)
recast float nut*, force
recast float t*, force

quietly reg log_prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 prop_head_edu_7 t2-t4 
estimates store OLS_fe

quietly reg prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 prop_head_edu_7 t2-t4 
estimates store OLS_fe


* Moran's I and LM tests
spatdiag, weights(W10xt_st)


/*
OLS
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
------------------------------------------------------------
Test                           |  Statistic    df   p-value
-------------------------------+----------------------------
Spatial error:                 |
  Moran's I                    |     3.784      1    0.000
  Lagrange multiplier          |    12.567      1    0.000
  Robust Lagrange multiplier   |     1.410      1    0.235
                               |
Spatial lag:                   |
  Lagrange multiplier          |    17.258      1    0.000
  Robust Lagrange multiplier   |     6.100      1    0.014
------------------------------------------------------------



OLS w/FE
------------------------------------------------------------
Test                           |  Statistic    df   p-value
-------------------------------+----------------------------
Spatial error:                 |
  Moran's I                    |     2.981      1    0.003
  Lagrange multiplier          |     7.684      1    0.006
  Robust Lagrange multiplier   |     0.602      1    0.438
                               |
Spatial lag:                   |
  Lagrange multiplier          |     9.937      1    0.002
  Robust Lagrange multiplier   |     2.854      1    0.091
------------------------------------------------------------
------------------------------------------------------------
Test                           |  Statistic    df   p-value
-------------------------------+----------------------------
Spatial error:                 |
  Moran's I                    |     3.802      1    0.000
  Lagrange multiplier          |    12.799      1    0.000
  Robust Lagrange multiplier   |     1.063      1    0.302
                               |
Spatial lag:                   |
  Lagrange multiplier          |    17.428      1    0.000
  Robust Lagrange multiplier   |     5.692      1    0.017
------------------------------------------------------------


*/



*Veo SLX 

*(recordar eliminar los wx anteriores)
splagvar, wname(W10xt_st) ind(prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 prop_head_edu_7 ///
total_plot_size prop_coupon prop_credit prop_left_seeds) wfrom(Stata) order(1)

quietly reg log_prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds ///
wx_prop_female_head wx_mean_age_head wx_prop_salaried_head wx_prop_head_edu_1 ///
wx_prop_head_edu_2 wx_prop_head_edu_3 wx_prop_head_edu_4 wx_prop_head_edu_5 wx_prop_head_edu_6 ///
wx_prop_head_edu_7 wx_total_plot_size wx_prop_coupon wx_prop_credit wx_prop_left_seeds t2-t4

quietly reg prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds ///
wx_prop_female_head wx_mean_age_head wx_prop_salaried_head wx_prop_head_edu_1 ///
wx_prop_head_edu_2 wx_prop_head_edu_3 wx_prop_head_edu_4 wx_prop_head_edu_5 wx_prop_head_edu_6 ///
wx_prop_head_edu_7 wx_total_plot_size wx_prop_coupon wx_prop_credit wx_prop_left_seeds t2-t4


estimates store SLX_fe
spatdiag, weights(W10xt_st)

/*
------------------------------------------------------------
Test                           |  Statistic    df   p-value
-------------------------------+----------------------------
Spatial error:                 |
  Moran's I                    |     1.969      1    0.049
  Lagrange multiplier          |     0.668      1    0.414
  Robust Lagrange multiplier   |     2.352      1    0.125
                               |
Spatial lag:                   |
  Lagrange multiplier          |     1.466      1    0.226
  Robust Lagrange multiplier   |     3.151      1    0.076
------------------------------------------------------------
Puede ser SDM y no SDEM 
*/



*SLM vs SARAR

xsmle log_prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe type(both) wmat(WA_st) mod(sar) r

xsmle prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe type(both) wmat(WARC_st) mod(sar) r 


estat ic 

estimates store SLM


xsmle log_prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe wmat(WA_st) emat(WA_st) mod(sac) r
estimates store SARAR


xsmle prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe type(both) wmat(W100arc_st) mod(sar) r

estimates store SLM

xsmle prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe wmat(W100arc_st) emat(W100arc_st) mod(sac) type(both) nolog r 

estimates store SARAR

lrtest SARAR SLM //SARAR is not statistically better than SLM. p-v=1.0

/*
Likelihood-ratio test                                 LR chi2(1)  =      0.38
(Assumption: SLM nested in SARAR)                     Prob > chi2 =    0.5360
*/

*SLM vs SDM

xsmle log_prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe wmat(WK_st) mod(sdm) nolog effects r
estimate store SDM

xsmle prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit, fe wmat(WARC_st) mod(sdm) nolog effects r
estimate store SDM


lrtest SLM SDM //SLM is prefered p-v=0.287

/*
Likelihood-ratio test                                 LR chi2(12) =     12.31
(Assumption: SLM nested in SDM)                       Prob > chi2 =    0.4210
*/

*SLX

xtreg log_prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds ///
wx_prop_female_head wx_mean_age_head wx_prop_salaried_head wx_prop_head_edu_1 ///
wx_prop_head_edu_2 wx_prop_head_edu_3 wx_prop_head_edu_4 wx_prop_head_edu_5 wx_prop_head_edu_6 ///
wx_prop_head_edu_7 wx_total_plot_size wx_prop_coupon wx_prop_credit wx_prop_left_seeds t2-t4, fe

estimates store SLX_fe


*MCO
reg log_prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds

estimates store OLS

*MCO w/fixed effects
reghdfe log_prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, absorb(round)

estimates store OLS_fe


estimates table SLM, b(%7.3f) se p stats(N ll aic) stf(%9.0f) drop(t*)

estimates table OLS OLS_fe SLX_fe SLM SDM SARAR, b(%7.3f) star(0.1 0.05 0.01) stats(ll aic) stf(%9.0f) drop(t*)


splagvar, wname(W10xt_st) ind(prop_imp) wfrom(Stata) order(1) 



*Mejor modelo SLM  : Y = \rho W Y + X \beta + \varepsilon


*------------------------------------------------------------------------------*



*------------------------- Rook Contiguity (G1 & G2) --------------------------*


*The follwing W matrices show that there is not spacial dependency.

* Rook contiguity (G1)


use "$input/MALAWI_panel.dta", clear

xtset ea_id round
replace prop_imp=0.999 if prop_imp==1
replace prop_imp = 0.001 if prop_imp == 0
gen log_prop_imp= log(prop_imp/(1-prop_imp))


spwmatrix import using "$input/W11xt_bin.dta", wname(W11xt_st) row dta conn

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
replace prop_imp=0.999 if prop_imp==1
replace prop_imp = 0.001 if prop_imp == 0
gen log_prop_imp= log(prop_imp/(1-prop_imp))


spwmatrix import using "$input/W12xt_bin.dta", wname(W12xt_st) row dta conn

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


*I need to run a LM test in a SLX model 


*==============================================================================*
*==============================================================================*








