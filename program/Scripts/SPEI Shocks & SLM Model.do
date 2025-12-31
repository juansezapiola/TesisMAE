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

*0.1) Matrices

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



* 0.1) Matrices



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





* 1) SLM -no shock- Model
*==============================================================================*
use "$input/MALAWI_panel_Wy_2.dta", clear

*set Panel
xtset ea_id round

*W_k
spwmatrix import using W5xt_bin.dta, wname(W5xt_st) row dta conn

*To make this run go to W Matrices & Spatial Model do file and run again the W matrix with another name 
xsmle prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe type(both) wmat(Wk5N_st) mod(sar) r effects

estimates store SLM


*W_d_100
spwmatrix import using W10xt_bin.dta, wname(W10xt_st) row dta conn

xsmle prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe type(both) wmat(W100arc_st) mod(sar) r effects

estimates store SLM_2


*W_d_80
spwmatrix import using W80xt_bin.dta, wname(W80xt_st) row dta conn

xsmle prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe type(both) wmat(W80arc80_st) mod(sar) r effects


*W_d_120

spwmatrix import using W120xt_bin.dta, wname(W120xt_st) row dta conn

xsmle prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds, fe type(both) wmat(W120ARC_st) mod(sar) r effects





*2) Shock Interraction Model - IV 
*==============================================================================*


gen sev_shock=1 if SPEI<-1.49 
replace sev_shock=0 if sev_shock==.


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


* Creo WY

splagvar, wname(W80xt_st) ind(prop_imp) wfrom(Stata) order(1)
rename wx_prop_imp wy1


*Genero wy2

gen wy2 = wy1 * sev_shock

* Creo WX y W2X (orden 1, 2 y 3)

splagvar, wname(W80xt_st) ind(prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 prop_head_edu_7 ///
total_plot_size prop_coupon prop_credit prop_left_seeds) wfrom(Stata) order(3)


*IV regress ->    ivregress 2sls y (wy1 wy2 = wx wx2 ) x


ivregress 2sls prop_imp ///
(wy1 wy2 = ///
wx_prop_female_head w2x_prop_female_head wx_mean_age_head w2x_mean_age_head ///
wx_prop_salaried_head w2x_prop_salaried_head wx_prop_head_edu_1 w2x_prop_head_edu_1 ///
wx_prop_head_edu_2 w2x_prop_head_edu_2 wx_prop_head_edu_3 w2x_prop_head_edu_3 ///
wx_prop_head_edu_4 w2x_prop_head_edu_4 wx_prop_head_edu_5 w2x_prop_head_edu_5 ///
wx_prop_head_edu_6 w2x_prop_head_edu_6 wx_prop_head_edu_7 w2x_prop_head_edu_7 ///
wx_total_plot_size w2x_total_plot_size wx_prop_coupon w2x_prop_coupon ///
wx_prop_credit w2x_prop_credit wx_prop_left_seeds w2x_prop_left_seeds ) ///
prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 prop_head_edu_2 ///
prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 prop_head_edu_7 ///
total_plot_size prop_coupon prop_credit prop_left_seeds, ///
vce(cluster grid_id)


ivregress 2sls prop_imp ///
(wy1 wy2 = ///
wx_prop_female_head w2x_prop_female_head w3x_prop_female_head wx_mean_age_head ///
w2x_mean_age_head w3x_mean_age_head wx_prop_salaried_head w2x_prop_salaried_head ///
w3x_prop_salaried_head wx_prop_head_edu_1 w2x_prop_head_edu_1 w3x_prop_head_edu_1 ///
wx_prop_head_edu_2 w2x_prop_head_edu_2 w3x_prop_head_edu_2 wx_prop_head_edu_3 ///
w2x_prop_head_edu_3 w3x_prop_head_edu_3 wx_prop_head_edu_4 w2x_prop_head_edu_4 ///
w3x_prop_head_edu_4 wx_prop_head_edu_5 w2x_prop_head_edu_5 w3x_prop_head_edu_5 ///
wx_prop_head_edu_6 w2x_prop_head_edu_6 w3x_prop_head_edu_6 wx_prop_head_edu_7 ///
w2x_prop_head_edu_7 w3x_prop_head_edu_7 wx_total_plot_size w2x_total_plot_size ///
w3x_total_plot_size wx_prop_coupon w2x_prop_coupon w3x_prop_coupon wx_prop_credit ///
w2x_prop_credit w3x_prop_credit wx_prop_left_seeds w2x_prop_left_seeds w3x_prop_left_seeds) ///
prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 prop_head_edu_2 ///
prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 prop_head_edu_7 ///
total_plot_size prop_coupon prop_credit prop_left_seeds, ///
vce(cluster grid_id)


*Repito para d_100
use "$input/MALAWI_panel_Wy_2.dta", clear

*set Panel
xtset ea_id round

spwmatrix import using W10xt_bin.dta, wname(W10xt_st) row dta conn

* Creo WY

splagvar, wname(W10xt_st) ind(prop_imp) wfrom(Stata) order(1)
rename wx_prop_imp wy1


*Genero wy2
gen sev_shock=1 if SPEI<-1.49 
replace sev_shock=0 if sev_shock==.
gen wy2 = wy1 * sev_shock

* Creo WX y W2X (orden 1, 2 y 3)

splagvar, wname(W10xt_st) ind(prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 prop_head_edu_7 ///
total_plot_size prop_coupon prop_credit prop_left_seeds) wfrom(Stata) order(3)


*IV regress ->    ivregress 2sls y (wy1 wy2 = wx wx2 ) x


ivregress 2sls prop_imp ///
(wy1 wy2 = ///
wx_prop_female_head w2x_prop_female_head wx_mean_age_head w2x_mean_age_head ///
wx_prop_salaried_head w2x_prop_salaried_head wx_prop_head_edu_1 w2x_prop_head_edu_1 ///
wx_prop_head_edu_2 w2x_prop_head_edu_2 wx_prop_head_edu_3 w2x_prop_head_edu_3 ///
wx_prop_head_edu_4 w2x_prop_head_edu_4 wx_prop_head_edu_5 w2x_prop_head_edu_5 ///
wx_prop_head_edu_6 w2x_prop_head_edu_6 wx_prop_head_edu_7 w2x_prop_head_edu_7 ///
wx_total_plot_size w2x_total_plot_size wx_prop_coupon w2x_prop_coupon ///
wx_prop_credit w2x_prop_credit wx_prop_left_seeds w2x_prop_left_seeds) ///
prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 prop_head_edu_2 ///
prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 prop_head_edu_7 ///
total_plot_size prop_coupon prop_credit prop_left_seeds, ///
vce(cluster grid_id)




*Repito para d_120
use "$input/MALAWI_panel_Wy_2.dta", clear

*set Panel
xtset ea_id round

spwmatrix import using W120xt_bin.dta, wname(W10xt_st) row dta conn

* Creo WY

splagvar, wname(W120xt_st) ind(prop_imp) wfrom(Stata) order(1)
rename wx_prop_imp wy1


*Genero wy2
gen sev_shock=1 if SPEI<-1.49 
replace sev_shock=0 if sev_shock==.
gen wy2 = wy1 * sev_shock

* Creo WX y W2X (orden 1, 2 y 3)

splagvar, wname(W120xt_st) ind(prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 prop_head_edu_7 ///
total_plot_size prop_coupon prop_credit prop_left_seeds) wfrom(Stata) order(3)


*IV regress ->    ivregress 2sls y (wy1 wy2 = wx wx2 ) x


ivregress 2sls prop_imp ///
(wy1 wy2 = ///
wx_prop_female_head w2x_prop_female_head wx_mean_age_head w2x_mean_age_head ///
wx_prop_salaried_head w2x_prop_salaried_head wx_prop_head_edu_1 w2x_prop_head_edu_1 ///
wx_prop_head_edu_2 w2x_prop_head_edu_2 wx_prop_head_edu_3 w2x_prop_head_edu_3 ///
wx_prop_head_edu_4 w2x_prop_head_edu_4 wx_prop_head_edu_5 w2x_prop_head_edu_5 ///
wx_prop_head_edu_6 w2x_prop_head_edu_6 wx_prop_head_edu_7 w2x_prop_head_edu_7 ///
wx_total_plot_size w2x_total_plot_size wx_prop_coupon w2x_prop_coupon ///
wx_prop_credit w2x_prop_credit wx_prop_left_seeds w2x_prop_left_seeds) ///
prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 prop_head_edu_2 ///
prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 prop_head_edu_7 ///
total_plot_size prop_coupon prop_credit prop_left_seeds, ///
vce(cluster grid_id)
