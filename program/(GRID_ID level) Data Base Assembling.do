********************************************************************************
*----------------     Data Base Assembling (GRID_ID level)     ----------------* 
*----------------                                              ----------------*
*----------------	         Juan Segundo Zapiola              ----------------* 
*----------------				                               ----------------* 
*----------------          Universidad de San Andrés           ----------------* 
*----------------             Tesis Maestría Econ              ----------------* 
*----------------				    2025                       ----------------* 
********************************************************************************

*SAME AS DATA ASSEMBLING BUT AGGREGATED AT GRID_ID LEVEL

*clean 
clear all

*Directory 							
gl main "/Users/juansegundozapiola/Documents/Maestria/TesisMAE"
gl input "$main/input"
gl output "$main/output"
 
 

use "$input/MWI_panel_key_R1234.dta", clear

merge m:m ea_id latitude longitude using "$input/grid_id_key"
drop _merge

merge 1:m case_id using "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/ag_mod_h_10.dta"

*remove those households that are not in the balanced panel and dont own plots.

drop if y2_hhid==""
drop if HHID==. 
drop if ag_h0b==. 
drop _merge

merge m:m y2_hhid using "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/ag_mod_h_13.dta", force


drop if case_id==""
drop if ag_h0b==. //those in R2 and not in R1
drop if ag_h0c_R2==. //those in R1 but not in R1


merge m:m y3_hhid using "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/ag_mod_h_16.dta", generate(_R3) force

drop if case_id==""
drop if crop_code_R3==.

merge m:m y4_hhid using "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/ag_mod_h_19.dta", generate(_R4) force

drop if case_id==""
drop if crop_code_R4==.


*pruebo 
keep case_id y2_hhid y3_hhid y4_hhid ea_id grid_id latitude longitude ag_h0b ag_h01a ag_h01b ag_h0c_R2 ag_h01a_R2 ag_h01b_R2 crop_code_R3 ag_h01a_R3 ag_h01b_R3 crop_code_R4 ag_h01a_R4 ag_h01b_R4

*drop missings 

mdesc ag_h01b
drop if ag_h01b==.
drop if ag_h01b==9

mdesc ag_h01b_R2
drop if ag_h01b_R2==. 
drop if ag_h01b_R2==9

mdesc ag_h01b_R3
drop if ag_h01b_R3==. 

mdesc ag_h01b_R4
drop if ag_h01b_R4==.

forvalues round = 1/4 {
    local var_a = "ag_h01a"  // Base variable
    local var_b = "ag_h01b"  // Condition variable

    // Adjust variable names for rounds 2, 3, and 4
    if `round' > 1 {
        local var_a = "ag_h01a_R`round'"
        local var_b = "ag_h01b_R`round'"
    }

    replace `var_a' = `var_a' / 1000 if `var_b' == 1
    replace `var_a' = `var_a' * 2 if `var_b' == 3
    replace `var_a' = `var_a' * 3 if `var_b' == 4
    replace `var_a' = `var_a' * 3.7 if `var_b' == 5
    replace `var_a' = `var_a' * 5 if `var_b' == 6
    replace `var_a' = `var_a' * 10 if `var_b' == 7
    replace `var_a' = `var_a' * 50 if `var_b' == 8
}
*Now everything is in kg, so lets drop unit variables

drop ag_h01b ag_h01b_R2 ag_h01b_R3 ag_h01b_R4


rename ag_h0b seed_R1
rename ag_h0c_R2 seed_R2
rename crop_code_R3 seed_R3
rename crop_code_R4 seed_R4

*We have the seed names, each classified to a specific number:

codebook seed_R1
label list AG_H0B

codebook seed_R2
label list AG_H0C

codebook seed_R3
label list crop_complete

codebook seed_R4
label list ag_H_seed_roster__id


forvalues round = 1/4 {
    // Generate the new variable for each round
    gen improved_R`round' = .
    
    // Replace the variable based on the values in seed_R
    replace improved_R`round' = 1 if inlist(seed_R`round', 3, 4, 12, 13, 14, 15, 18, 19, 20, 21, 24)
	replace improved_R`round' = 0 if improved_R`round'==.
}

bysort grid_id: gen n = _n

* Total semillas compradas por ronda y grid_id
bysort grid_id: egen total_kg_R1 = total(ag_h01a)
bysort grid_id: egen total_kg_R2 = total(ag_h01a_R2)
bysort grid_id: egen total_kg_R3 = total(ag_h01a_R3)
bysort grid_id: egen total_kg_R4 = total(ag_h01a_R4)

* Total semilla mejorada para cada grid_id en cada ronda
bysort grid_id: egen imp_kg_R1 = total(ag_h01a * (improved_R1 == 1))
bysort grid_id: egen imp_kg_R2 = total(ag_h01a_R2 * (improved_R2 == 1))
bysort grid_id: egen imp_kg_R3 = total(ag_h01a_R3 * (improved_R3 == 1))
bysort grid_id: egen imp_kg_R4 = total(ag_h01a_R4 * (improved_R4 == 1))

* Proportion of improved seeds used in each round 
gen prop_imp_R1 = imp_kg_R1 / total_kg_R1
gen prop_imp_R2 = imp_kg_R2 / total_kg_R2
gen prop_imp_R3 = imp_kg_R3 / total_kg_R3
gen prop_imp_R4 = imp_kg_R4 / total_kg_R4

* Keep only one observation per grid_id
keep if n == 1

* Drop unnecessary variables
drop seed_R1 ag_h01a seed_R2 ag_h01a_R2 seed_R3 ag_h01a_R3 seed_R4 ag_h01a_R4 ///
     improved_R1 improved_R2 improved_R3 improved_R4 n total_kg_R1 total_kg_R2 ///
     total_kg_R3 total_kg_R4 imp_kg_R1 imp_kg_R2 imp_kg_R3 imp_kg_R4 case_id ///
     y2_hhid y3_hhid y4_hhid
     
save "$input/prop_improved_grid_id.dta", replace



***********************3.2.1) Household Characteristics:

*****ROUND 1:


use "$input/MWI_panel_key_R1234.dta", clear
merge m:m ea_id latitude longitude using "$input/grid_id_key"
drop _merge


*Module B

use "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/hh_mod_b_10.dta", clear
merge m:m ea_id using "$input/grid_id_key"
drop _merge

egen HH_head_fem = max(hh_b03 == 2 & hh_b04 == 1), by(case_id)
egen HH_head_age = max(hh_b05a * (hh_b04 == 1)), by(case_id)
replace HH_head_age=. if HH_head_age<1
replace HH_head_fem=. if HH_head_age==.


keep case_id ea_id id_code HH_head_fem HH_head_age hh_b04


*Module C

merge 1:1 case_id id_code ea_id using "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/hh_mod_c_10.dta"

egen HH_head_edu= max(hh_c09 * (hh_b04 == 1)), by(case_id) 
replace HH_head_edu=. if HH_head_edu==0


keep case_id ea_id id_code hh_b04 HH_head_fem HH_head_age  HH_head_edu

*Module E

merge 1:1 case_id id_code ea_id using "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/hh_mod_e_10.dta"

egen HH_head_salaried_emp = max(hh_e18 * (hh_b04 == 1)), by(case_id)
*2=no 1=yes
replace HH_head_salaried_emp=. if HH_head_salaried_emp==0
replace HH_head_salaried_emp=0 if HH_head_salaried_emp==2

keep case_id ea_id id_code HH_head_fem HH_head_age HH_head_edu HH_head_salaried_emp
bysort case_id: gen n=_n
keep if n==1
drop n id_code


*Merge with those HH that cultivate.
merge 1:1 case_id  ea_id using "$input/MWI_panel_HHs_key_R1234.dta"
drop if _merge==1


*we aggregate it to grid_id level:


egen total_females = total(HH_head_fem), by(grid_id)   // Count total female-headed households per ea_id
egen total_households = count(HH_head_fem), by(grid_id) // Count total households per ea_id
gen prop_female_head = total_females / total_households // Calculate the proportion

egen mean_age_head = mean(HH_head_age), by(grid_id) //mean age of head 

egen total_emp = total(HH_head_salaried_emp), by(grid_id)   // Count total employed per ea_id
gen prop_salaried_head = total_emp / total_households // Calculate the proportion

tab HH_head_edu, gen(education_)
forval i = 1/7 {
    egen total_edu_`i' = total(education_`i'), by(grid_id)
    gen prop_head_edu_`i' = total_edu_`i' / total_households
}


keep case_id ea_id grid_id prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 prop_head_edu_7

bysort grid_id: gen n=_n
keep if n==1
drop n case_id 

ds
foreach var of varlist `r(varlist)' {
    rename `var' `var'_R1
}

rename grid_id_R1 grid_id


save "$input/HH_CHAR_R1_grid_id.dta", replace


*****ROUND 2:



*Module B

use "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/hh_mod_b_13.dta", clear

egen HH_head_fem = max(hh_b03 == 2 & hh_b04 == 1), by(y2_hhid)
egen HH_head_age = max(hh_b05a * (hh_b04 == 1)), by(y2_hhid)
replace HH_head_age=. if HH_head_age<1
replace HH_head_fem=. if HH_head_age==.


keep y2_hhid PID hh_b01 HH_head_fem HH_head_age hh_b04


*Module C

merge 1:1 y2_hhid PID using "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/hh_mod_c_13.dta"

egen HH_head_edu= max(hh_c09 * (hh_b04 == 1)), by(y2_hhid) 
replace HH_head_edu=. if HH_head_edu==0

keep y2_hhid PID hh_b04 HH_head_fem HH_head_age  HH_head_edu



*Module E

merge 1:1 y2_hhid PID using "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/hh_mod_e_13.dta"

egen HH_head_salaried_emp = max(hh_e18 * (hh_b04 == 1)), by(y2_hhid)
*2=no 1=yes
replace HH_head_salaried_emp=. if HH_head_salaried_emp==0
replace HH_head_salaried_emp=0 if HH_head_salaried_emp==2

keep y2_hhid PID HH_head_fem HH_head_age HH_head_edu HH_head_salaried_emp
bysort y2_hhid: gen n=_n
keep if n==1
drop n PID



*Merge with those HH that cultivate.
merge 1:1 y2_hhid using "$input/MWI_panel_HHs_key_R1234.dta"
drop if _merge==1



*we aggregate it to grid_id level:

egen total_females = total(HH_head_fem), by(grid_id)   // Count total female-headed households per ea_id
egen total_households = count(HH_head_fem), by(grid_id) // Count total households per ea_id
gen prop_female_head = total_females / total_households // Calculate the proportion

egen mean_age_head = mean(HH_head_age), by(grid_id) //mean age of head 

egen total_emp = total(HH_head_salaried_emp), by(grid_id)   // Count total employed per ea_id
gen prop_salaried_head = total_emp / total_households // Calculate the proportion

tab HH_head_edu, gen(education_)
forval i = 1/6 {
    egen total_edu_`i' = total(education_`i'), by(grid_id)
    gen prop_head_edu_`i' = total_edu_`i' / total_households
}


keep y2_hhid ea_id grid_id prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 

bysort grid_id: gen n=_n
keep if n==1
drop n 

ds
foreach var of varlist `r(varlist)' {
    rename `var' `var'_R2
}
rename y2_hhid_R2 y2_hhid
rename grid_id_R2 grid_id

save "$input/HH_CHAR_R2_grid_id.dta", replace



*****ROUND 3:


*Module B

use "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/hh_mod_b_16.dta", clear
sort y3_hhid id_code

egen HH_head_fem = max(hh_b03 == 2 & hh_b04 == 1), by(y3_hhid)
egen HH_head_age = max(hh_b05a * (hh_b04 == 1)), by(y3_hhid)
replace HH_head_age=. if HH_head_age<1
replace HH_head_fem=. if HH_head_age==.

keep y3_hhid PID HH_head_fem HH_head_age hh_b04


*Module C

merge 1:1 y3_hhid PID using "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/hh_mod_c_16.dta"

egen HH_head_edu= max(hh_c09 * (hh_b04 == 1)), by(y3_hhid) 
replace HH_head_edu=. if HH_head_edu==0

keep y3_hhid PID hh_b04 HH_head_fem HH_head_age  HH_head_edu


*Module E

merge 1:1 y3_hhid PID using "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/hh_mod_e_16.dta"

egen HH_head_salaried_emp = max(hh_e06_4 * (hh_b04 == 1)), by(y3_hhid) //hh_e06_4 es hh_e18
*2=no 1=yes
replace HH_head_salaried_emp=. if HH_head_salaried_emp==0
replace HH_head_salaried_emp=0 if HH_head_salaried_emp==2

keep y3_hhid PID HH_head_fem HH_head_age HH_head_edu HH_head_salaried_emp
bysort y3_hhid: gen n=_n
keep if n==1
drop n PID

*Merge with those HH that cultivate.
merge 1:1 y3_hhid using "$input/MWI_panel_HHs_key_R1234.dta"
drop if _merge==1


*we aggregate it to grid_id level:

egen total_females = total(HH_head_fem), by(grid_id)   // Count total female-headed households per ea_id
egen total_households = count(HH_head_fem), by(grid_id) // Count total households per ea_id
gen prop_female_head = total_females / total_households // Calculate the proportion

egen mean_age_head = mean(HH_head_age), by(grid_id) //mean age of head 

egen total_emp = total(HH_head_salaried_emp), by(grid_id)   // Count total employed per ea_id
gen prop_salaried_head = total_emp / total_households // Calculate the proportion

tab HH_head_edu, gen(education_)
forval i = 1/7 {
    egen total_edu_`i' = total(education_`i'), by(grid_id)
    gen prop_head_edu_`i' = total_edu_`i' / total_households
}


keep y3_hhid ea_id grid_id prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 prop_head_edu_7

bysort grid_id: gen n=_n
keep if n==1
drop n 

ds
foreach var of varlist `r(varlist)' {
    rename `var' `var'_R3
}
rename y3_hhid_R3 y3_hhid
rename grid_id_R3 grid_id

save "$input/HH_CHAR_R3_grid_id.dta", replace



*****ROUND 4:


*Module B

use "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/hh_mod_b_19.dta", clear

egen HH_head_fem = max(hh_b03 == 2 & hh_b04 == 1), by(y4_hhid)
egen HH_head_age = max(hh_b05a * (hh_b04 == 1)), by(y4_hhid)
replace HH_head_age=. if HH_head_age<1
replace HH_head_fem=. if HH_head_age==.

keep y4_hhid PID HH_head_fem HH_head_age hh_b04



*Module C

merge 1:1 y4_hhid PID using "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/hh_mod_c_19.dta"

egen HH_head_edu= max(hh_c09 * (hh_b04 == 1)), by(y4_hhid) 
replace HH_head_edu=. if HH_head_edu==0

keep y4_hhid PID hh_b04 HH_head_fem HH_head_age  HH_head_edu


*Module E

merge 1:1 y4_hhid PID using "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/hh_mod_e_19.dta"

egen HH_head_salaried_emp = max(hh_e06_4 * (hh_b04 == 1)), by(y4_hhid) //hh_e06_4 es hh_e18
*2=no 1=yes
replace HH_head_salaried_emp=. if HH_head_salaried_emp==0
replace HH_head_salaried_emp=0 if HH_head_salaried_emp==2

keep y4_hhid PID HH_head_fem HH_head_age HH_head_edu HH_head_salaried_emp
bysort y4_hhid: gen n=_n
keep if n==1
drop n PID

*Merge with those HH that cultivate.
merge 1:1 y4_hhid using "$input/MWI_panel_HHs_key_R1234.dta"
drop if _merge==1


*we aggregate it to ea_id level:

egen total_females = total(HH_head_fem), by(grid_id)   // Count total female-headed households per ea_id
egen total_households = count(HH_head_fem), by(grid_id) // Count total households per ea_id
gen prop_female_head = total_females / total_households // Calculate the proportion

egen mean_age_head = mean(HH_head_age), by(grid_id) //mean age of head 

egen total_emp = total(HH_head_salaried_emp), by(grid_id)   // Count total employed per ea_id
gen prop_salaried_head = total_emp / total_households // Calculate the proportion

tab HH_head_edu, gen(education_)
forval i = 1/7 {
    egen total_edu_`i' = total(education_`i'), by(grid_id)
    gen prop_head_edu_`i' = total_edu_`i' / total_households
}


keep y4_hhid ea_id grid_id prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 prop_head_edu_7

bysort grid_id: gen n=_n
keep if n==1
drop n 

ds
foreach var of varlist `r(varlist)' {
    rename `var' `var'_R4
}
rename y4_hhid_R4 y4_hhid
rename grid_id_R4 grid_id

save "$input/HH_CHAR_R4_grid_id.dta", replace




***********************3.2.2) Agriculture Module:

/*
Module H:
H03 coupons/vouchers for seeds -> for improved
H04 credit for seed -> for improved
H41 left over seeds 
Module T:
T01 advice obtained -> agriculture category 
Module C:
C04 plot size
*/

*****ROUND 1:


*Create a tempfile for the module T, to merge it to module H. 
use "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/ag_mod_t1_10.dta", clear

codebook ag_t0a
label list W0A //301 - New Seed Varieties

egen advice = max(ag_t0a == 301 & ag_t01 == 1), by(case_id)

bysort case_id: gen n=_n
keep if n==1
keep case_id ea_id advice

tempfile temp_data
save `temp_data'


use "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/ag_mod_c_10.dta", clear

replace ag_c04c= ag_c04a if ag_c04c==.
bysort case_id: gen id=_n
keep case_id ea_id id ag_c04c

tempfile temp_data_2
save `temp_data_2'

use "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/ag_mod_h_10.dta", clear
*id for each seed cultivated (like plot id)
bysort case_id: gen id=_n

gen improved = .    
replace improved = 1 if inlist(ag_h0b, 3, 4, 12, 13, 14, 15, 18, 19, 20, 21, 24)
replace improved = 0 if improved==.

gen coupon_imp = (improved==1 & ag_h03==1)
gen credit_imp = (improved==1 & ag_h04==1)
gen left_over_seeds = (ag_h41==1)

keep case_id ea_id id improved coupon_imp credit_imp left_over_seeds

merge m:1 case_id ea_id using `temp_data'
drop _merge
merge 1:1 case_id id ea_id using `temp_data_2', force
drop if _merge==2
drop _merge


*Merge with those HH that cultivate.
merge m:1 case_id ea_id using "$input/MWI_panel_HHs_key_R1234.dta"
drop if _merge==1


*we aggregate it to ea_id level:

egen total_plot_size= total(ag_c04c), by(grid_id) 
egen total_coupon = total(coupon_imp), by(grid_id)   
egen total_plots = count(coupon_imp), by(grid_id) 
gen prop_coupon = total_coupon / total_plots //I have the proportion of plots that used coupons to purchase improved seeds

egen total_credit = total(credit_imp), by(grid_id)   
gen prop_credit = total_credit / total_plots //I have the proportion of plots that used credit to purchase improved seeds 

egen total_left_seeds = total(left_over_seeds), by(grid_id)   
gen prop_left_seeds = total_left_seeds / total_plots //I have the proportion of plots that used left over seeds 

*I need an unique value in each hh
bysort case_id: gen hh=_n
gen advice_final= (advice==1 & hh==1)
egen total_advice = total(advice_final), by(grid_id)  
egen total_hh = total(hh==1), by(grid_id) 
gen prop_advice = total_advice / total_hh //I have the proportion of plots that used left over seeds 


keep ea_id grid_id prop_coupon prop_credit prop_left_seeds prop_advice total_plot_size

bysort grid_id: gen n=_n
keep if n==1
drop n 

ds
foreach var of varlist `r(varlist)' {
    rename `var' `var'_R1
}

rename grid_id_R1 grid_id

save "$input/AGRO_CHAR_R1_grid_id.dta", replace




*****ROUND 2:


*Create a tempfile for the module T, to merge it to module H. 
use "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/ag_mod_t1_13.dta", clear

codebook ag_t0a
label list AG_W0A //301 - New Seed Varieties

egen advice = max(ag_t0a == 301 & ag_t01 == 1), by(y2_hhid)

bysort y2_hhid: gen n=_n
keep if n==1
keep y2_hhid advice

tempfile temp_data
save `temp_data'


use "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/ag_mod_c_13.dta", clear

replace ag_c04c= ag_c04a if ag_c04c==.
bysort y2_hhid: gen id=_n
keep y2_hhid id ag_c04c

tempfile temp_data_2
save `temp_data_2'


use "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/ag_mod_h_13.dta", clear
*id for each seed cultivated (like plot id)
bysort y2_hhid: gen id=_n

gen improved = .    
replace improved = 1 if inlist(ag_h0c_R2, 3, 4, 12, 13, 14, 15, 18, 19, 20, 21, 24)
replace improved = 0 if improved==.

gen coupon_imp = (improved==1 & ag_h03_R2==1)
gen credit_imp = (improved==1 & ag_h04_R2==1)
gen left_over_seeds = (ag_h41_R2==1)

keep y2_hhid id improved coupon_imp credit_imp left_over_seeds

merge m:1 y2_hhid using `temp_data'
drop _merge
merge 1:1 y2_hhid id using `temp_data_2', force
drop if _merge==2


drop _merge

*Merge with those HH that cultivate.
merge m:1 y2_hhid using "$input/MWI_panel_HHs_key_R1234.dta"
drop if _merge==1


*we aggregate it to ea_id level:

egen total_plot_size= total(ag_c04c), by(grid_id) 
egen total_coupon = total(coupon_imp), by(grid_id)   
egen total_plots = count(coupon_imp), by(grid_id) 
gen prop_coupon = total_coupon / total_plots //I have the proportion of plots that used coupons to purchase improved seeds

egen total_credit = total(credit_imp), by(grid_id)   
gen prop_credit = total_credit / total_plots //I have the proportion of plots that used credit to purchase improved seeds 

egen total_left_seeds = total(left_over_seeds), by(grid_id)   
gen prop_left_seeds = total_left_seeds / total_plots //I have the proportion of plots that used left over seeds 

*I need an unique value in each hh
bysort y2_hhid: gen hh=_n
gen advice_final= (advice==1 & hh==1)
egen total_advice = total(advice_final), by(grid_id)  
egen total_hh = total(hh==1), by(grid_id) 
gen prop_advice = total_advice / total_hh //I have the proportion of plots that used left over seeds 


keep ea_id grid_id prop_coupon prop_credit prop_left_seeds prop_advice total_plot_size

bysort grid_id: gen n=_n
keep if n==1
drop n 

ds
foreach var of varlist `r(varlist)' {
    rename `var' `var'_R2
}

rename grid_id_R2 grid_id

save "$input/AGRO_CHAR_R2_grid_id.dta", replace


*****ROUND 3:


*Create a tempfile for the module T, to merge it to module H. 
use "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/ag_mod_t1_16.dta", clear

codebook ag_t0a
label list ag_t0a //301 - New Seed Varieties

egen advice = max(ag_t0a == 301 & ag_t01 == 1), by(y3_hhid)

bysort y3_hhid: gen n=_n
keep if n==1
keep y3_hhid advice

tempfile temp_data
save `temp_data'

use "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/ag_mod_c_16.dta", clear

replace ag_c04c= ag_c04a if ag_c04c==.
bysort y3_hhid: gen id=_n
keep y3_hhid id ag_c04c

tempfile temp_data_2
save `temp_data_2'


use "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/ag_mod_h_16.dta", clear
*id for each seed cultivated (like plot id)
bysort y3_hhid: gen id=_n

gen improved = .    
replace improved = 1 if inlist(crop_code_R3, 3, 4, 12, 13, 14, 15, 18, 19, 20, 21, 24)
replace improved = 0 if improved==.

gen coupon_imp = (improved==1 & ag_h03_R3==1)
gen credit_imp = (improved==1 & ag_h04_R3==1)
gen left_over_seeds = (ag_h41_R3==1)

keep y3_hhid id improved coupon_imp credit_imp left_over_seeds

merge m:1 y3_hhid using `temp_data'
drop _merge
merge 1:1 y3_hhid id using `temp_data_2', force
drop if _merge==2

drop _merge

*Merge with those HH that cultivate.
merge m:1 y3_hhid using "$input/MWI_panel_HHs_key_R1234.dta"
drop if _merge==1
drop if advice==.


*we aggregate it to ea_id level:

egen total_plot_size= total(ag_c04c), by(grid_id) 
egen total_coupon = total(coupon_imp), by(grid_id)   
egen total_plots = count(coupon_imp), by(grid_id) 
gen prop_coupon = total_coupon / total_plots //I have the proportion of plots that used coupons to purchase improved seeds

egen total_credit = total(credit_imp), by(grid_id)   
gen prop_credit = total_credit / total_plots //I have the proportion of plots that used credit to purchase improved seeds 

egen total_left_seeds = total(left_over_seeds), by(grid_id)   
gen prop_left_seeds = total_left_seeds / total_plots //I have the proportion of plots that used left over seeds 

*I need an unique value in each hh
bysort y3_hhid: gen hh=_n
gen advice_final= (advice==1 & hh==1)
egen total_advice = total(advice_final), by(grid_id)  
egen total_hh = total(hh==1), by(grid_id) 
gen prop_advice = total_advice / total_hh //I have the proportion of plots that used left over seeds 


keep ea_id grid_id prop_coupon prop_credit prop_left_seeds prop_advice total_plot_size

bysort grid_id: gen n=_n
keep if n==1
drop n 

ds
foreach var of varlist `r(varlist)' {
    rename `var' `var'_R3
}

rename grid_id_R3 grid_id

save "$input/AGRO_CHAR_R3_grid_id.dta", replace






*****ROUND 4:


*Create a tempfile for the module T, to merge it to module H. 
use "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/ag_mod_t1_19.dta", clear

codebook ag_t0a
label list ag_t0a //301 - New Seed Varieties

egen advice = max(ag_t0a == 301 & ag_t01 == 1), by(y4_hhid)

bysort y4_hhid: gen n=_n
keep if n==1
keep y4_hhid advice

tempfile temp_data
save `temp_data'

use "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/ag_mod_c_19.dta", clear

replace ag_c04c= ag_c04a if ag_c04c==.
bysort y4_hhid: gen id=_n
keep y4_hhid id ag_c04c

tempfile temp_data_2
save `temp_data_2'


use "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/ag_mod_h_19.dta", clear
*id for each seed cultivated (like plot id)
bysort y4_hhid: gen id=_n

gen improved = .    
replace improved = 1 if inlist(crop_code_R4, 3, 4, 12, 13, 14, 15, 18, 19, 20, 21, 24)
replace improved = 0 if improved==.

gen coupon_imp = (improved==1 & ag_h03_R4==1)
gen credit_imp = (improved==1 & ag_h04_R4==1)
gen left_over_seeds = (ag_h41_R4==1)

keep y4_hhid id improved coupon_imp credit_imp left_over_seeds

merge m:1 y4_hhid using `temp_data'
drop _merge
merge 1:1 y4_hhid id using `temp_data_2', force
drop if _merge==2

drop _merge

*Merge with those HH that cultivate.
merge m:1 y4_hhid using "$input/MWI_panel_HHs_key_R1234.dta"
drop if _merge==1
drop if advice==.


*we aggregate it to ea_id level:

egen total_plot_size= total(ag_c04c), by(grid_id) 
egen total_coupon = total(coupon_imp), by(grid_id)   
egen total_plots = count(coupon_imp), by(grid_id) 
gen prop_coupon = total_coupon / total_plots //I have the proportion of plots that used coupons to purchase improved seeds

egen total_credit = total(credit_imp), by(grid_id)   
gen prop_credit = total_credit / total_plots //I have the proportion of plots that used credit to purchase improved seeds 

egen total_left_seeds = total(left_over_seeds), by(grid_id)   
gen prop_left_seeds = total_left_seeds / total_plots //I have the proportion of plots that used left over seeds 

*I need an unique value in each hh
bysort y4_hhid: gen hh=_n
gen advice_final= (advice==1 & hh==1)
egen total_advice = total(advice_final), by(grid_id)  
egen total_hh = total(hh==1), by(grid_id) 
gen prop_advice = total_advice / total_hh //I have the proportion of plots that used left over seeds 


keep ea_id grid_id prop_coupon prop_credit prop_left_seeds prop_advice total_plot_size

bysort grid_id: gen n=_n
keep if n==1
drop n 

ds
foreach var of varlist `r(varlist)' {
    rename `var' `var'_R4
}

rename grid_id_R4 grid_id

save "$input/AGRO_CHAR_R4_grid_id.dta", replace


* 3.3) Final Aggregation - Proportion of Improved seeds, SPEI, EA's and HH characteristics
*==============================================================================*

*We need to aggregate prop_imporved.dta + HH_CHAR_R* + AGRO_CHAR_R* + COMM_CHAR_R* + SPEI_ea


*Let´s start with Round 1:

use "$input/prop_improved_grid_id.dta", clear

merge 1:1 grid_id using "$input/HH_CHAR_R1_grid_id.dta", force
drop _merge

merge 1:1 grid_id using "$input/AGRO_CHAR_R1_grid_id.dta", force
drop _merge



*Round 2:

merge 1:1 grid_id using "$input/HH_CHAR_R2_grid_id.dta", force
drop _merge

merge 1:1 grid_id using "$input/AGRO_CHAR_R2_grid_id.dta", force
drop _merge


drop y2_hhid


*Round 3:

merge 1:1 grid_id using "$input/HH_CHAR_R3_grid_id.dta", force
drop _merge

merge 1:1 grid_id using "$input/AGRO_CHAR_R3_grid_id.dta", force
drop _merge


drop y3_hhid


*Round 4:

merge 1:1 grid_id using "$input/HH_CHAR_R4_grid_id.dta", force
drop _merge

merge 1:1 grid_id using "$input/AGRO_CHAR_R4_grid_id.dta", force
drop _merge


drop y4_hhid


*Let's add SPEI


merge 1:1 ea_id using "$input/SPEI_ea.dta", force
drop _merge
drop if grid_id==.


*Now all the variables are togheter, but we need it as a panel. 

rename SPEI_2009 SPEI_R1
rename SPEI_2012 SPEI_R2
rename SPEI_2015 SPEI_R3
rename SPEI_2018 SPEI_R4

save "$input/MWI_wide_grid_id.dta", replace
use "$input/MWI_wide_grid_id.dta", clear

reshape long prop_imp_R prop_female_head_R mean_age_head_R prop_salaried_head_R prop_head_edu_1_R prop_head_edu_2_R prop_head_edu_3_R prop_head_edu_4_R prop_head_edu_5_R prop_head_edu_6_R prop_head_edu_7_R total_plot_size_R prop_coupon_R prop_credit_R prop_left_seeds_R prop_advice_R SPEI_R, i(grid_id) j(round)


foreach var in prop_imp_R prop_female_head_R mean_age_head_R prop_salaried_head_R prop_head_edu_1_R prop_head_edu_2_R prop_head_edu_3_R prop_head_edu_4_R prop_head_edu_5_R prop_head_edu_6_R prop_head_edu_7_R total_plot_size_R prop_coupon_R prop_credit_R prop_left_seeds_R prop_advice_R SPEI_R {
    local base = substr("`var'", 1, strpos("`var'", "_R") - 1) // Extract the part before "_R"
    rename `var' `base' // Rename the variable
}


drop round ea_id_R1 ea_id_R2 ea_id_R3 ea_id_R4 

bysort grid_id: gen round=_n

order grid_id ea_id latitude longitude round prop_imp SPEI

*Create Labels for clarity: label variable varname "Label Text"

label variable prop_imp "Proportion of improved seed adoption"
label variable SPEI "SPEI Index"
label variable prop_female_head "Proportion of female head in households"
label variable mean_age_head "Mean age of household head"
label variable prop_salaried_head "Proportion being salaried employed"
label variable prop_head_edu_1 "Proportion of head with no education"
label variable prop_head_edu_2 "Proportion of head with PSLC education"
label variable prop_head_edu_3 "Proportion of head with JCE education"
label variable prop_head_edu_4 "Proportion of head with MSCE education"
label variable prop_head_edu_5 "Proportion of head with NON-UNIV.DIPLOMA education"
label variable prop_head_edu_6 "Proportion of head with UNIVER.DIPLOMA DEGREE education"
label variable prop_head_edu_7 "Proportion of head with POST-GRAD.DIPLOMA DEGREE education"
label variable total_plot_size "Plot size (ACRES)"
label variable prop_coupon "Proportion that used coupons/vouchers for improved seeds"
label variable prop_credit "Proportion of who had credit for improved seeds"
label variable prop_left_seeds "Proportion who used seed left over from a previous season"
label variable prop_advice "Proportion who obtained agriculture advice"
label variable members_agri_coop "Number of members in the Agro Cooperation Group?"
label variable assistant_ag_officer "Does an Assist. Agricultural Extension Development Officer live in this community?"
label variable agri_coop "Does an Agriculture coopoeration exists in the community?"
label variable maize_hybrid_sellers "Number of sellers of hybrid maize seed in the community"

save "$input/MALAWI_panel_grid_id.dta", replace





* 1) Spatial W matrices 
*==============================================================================*


******* 5 KNN neighbours 

use "$input/MWI_wide_grid_id.dta", clear

spwmatrix gecon latitud longitud, wn(W55bin) knn(5) xport(W55bin,txt) replace
insheet using "W55bin.txt", delim(" ") clear
drop in 1
rename v1 _ID
save "W55bin.dta", replace


insheet using "W55bin.txt", delim(" ") clear
drop in 1
drop v1
mkmat v2-v91, mat(W55nn_bin)
save W55nn_bin.dta, replace

spmat dta WKKG_st v2-v91, norm(row)
drop v2-v91

set matsize 656
mat TMAT=I(4)
mat W55xt_bin=TMAT#W55nn_bin
svmat W55xt_bin
save "W55xt_bin.dta", replace

******* Inverse Arc-Distance (100km)

use "$input/MWI_wide_grid_id.dta", clear

spwmatrix gecon latitud longitud, wn(W1010bin) wtype(inv) dband(0 100) xport(W1010bin,txt) replace
insheet using "W1010bin.txt", delim(" ") clear
drop in 1
rename v1 _ID
save "W1010bin.dta", replace


insheet using "W1010bin.txt", delim(" ") clear
drop in 1
drop v1
mkmat v2-v91, mat(W1010nn_bin)
save W1010nn_bin.dta, replace

spmat dta WAAG_st v2-v91, norm(row)
drop v2-v91

set matsize 656
mat TMAT=I(4)
mat W1010xt_bin=TMAT#W1010nn_bin
svmat W1010xt_bin
save "W1010xt_bin.dta", replace




use "$input/MALAWI_panel_grid_id.dta", clear

replace prop_head_edu_7=0 if prop_head_edu_7==.



xtset grid_id round

*I do a logistic transformation to prop_imp so to have a log-likelihood function
*I convert a proportion (which is bounded between 0 and 1) into an unbounded continuous
*variable that can be modeled using standard regression techniques like Maximum Likelihood Estimation (MLE)
replace prop_imp=0.999 if prop_imp==1
replace prop_imp = 0.001 if prop_imp == 0
gen log_prop_imp= log(prop_imp/(1-prop_imp))


spwmatrix import using W55xt_bin.dta, wname(W55xt_st) row dta conn

*OLS regresion 
reg log_prop_imp prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 ///
prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 

estimates store OLS

* Moran's I and LM tests
spatdiag, weights(W55xt_st)
















