********************************************************************************
*----------------           Descriptive Statistics             ----------------* 
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

*1) Variables mean & sd

*2) Drought Shock

*==============================================================================*



*1) Variables mean & sd
*==============================================================================*

sum prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds 


*comparison of those over and under the mean of adoption. 
gen adopt=0 if prop_imp<=0.34
replace adopt=1 if prop_imp>.34

foreach var in prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds {
    ttest `var', by(adopt)
}




*2) Drought Shock
*==============================================================================*


gen sev_shock=1 if SPEI<-1.49 
replace sev_shock=0 if sev_shock==.


sum SPEI if SPEI <-1.49 //mean: -1.60


gen Sev_shock=1 if SPEI<-1.602  
replace Sev_shock=0 if Sev_shock==.

replace sev

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


*Eventually treated:
bysort ea_id (round): egen ever_treated = max(sev_shock)

keep if round==1

foreach var in prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 ///
prop_head_edu_7 total_plot_size prop_coupon prop_credit prop_left_seeds {
    ttest `var', by(ever_treated)
}















