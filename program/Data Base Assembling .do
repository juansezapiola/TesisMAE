********************************************************************************
*----------------            Data Base Assembling              ----------------* 
*----------------                                              ----------------*
*----------------	         Juan Segundo Zapiola              ----------------* 
*----------------				                               ----------------* 
*----------------          Universidad de San Andrés           ----------------* 
*----------------             Tesis Maestría Econ              ----------------* 
*----------------				    2024                       ----------------* 
********************************************************************************

*clean 
clear all

*Directory 							
gl main "/Users/juansegundozapiola/Documents/Maestria/TesisMAE"
gl input "$main/input"
gl output "$main/output"
 
*INDEX
*==============================================================================*
*0) Key Panel ID for the 4 Rounds: 2010 - 2013 - 2016 - 2019 + Geo Coordinates
*1) Merging Seed datasets from the Rounds together (balanced panel - plots)
*2) Identification of Improved seeds 
*3) Aggregation to ea_id level
   * 3.1) Aggregation - Proportion of Improved seed cultivated at EA_ID level
   * 3.2) Aggregation - EA's and HH characteristics
   * 3.3) Final Aggregation - Proportion of Improved seeds, SPEI, EA's and HH characteristics
*==============================================================================*



* 0) Key Panel ID for the 4 Rounds: 2010 - 2013 - 2016 - 2019 + Geo Coordinates
*==============================================================================*
****Round keys:
use "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/hh_mod_a_filt_10.dta", clear


merge 1:m case_id using "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/hh_mod_a_filt_13.dta", generate(_R2) force

merge m:m y2_hhid using "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/hh_mod_a_filt_16.dta", generate(_R3) force

merge m:m y3_hhid using "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/hh_mod_a_filt_19.dta", generate(_R4) force

*there are repeated households, so we need  to delete those and keep the unqie amount of hh 

bysort case_id: gen n=_n
keep if n==1

order case_id y2_hhid y3_hhid y4_hhid ea_id_R1  ea_id_R2  ea_id_R3 ea_id_R4

rename ea_id_R1 ea_id 

tab ea_id // 102 EA's

keep case_id y2_hhid y3_hhid y4_hhid ea_id


tab case_id if y4_hhid==""

drop if y4_hhid==""
drop if y3_hhid==""
drop if y2_hhid==""


*Lets add EA_IS's georeferenced coordinates:

merge m:m ea_id using "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/HouseholdGeovariables_IHS3_Rerelease_10.dta", generate(_lat) 

rename lat_modified latitude 
rename lon_modified longitude 

bysort case_id: gen n=_n
keep if n==1

keep case_id y2_hhid y3_hhid y4_hhid ea_id latitude longitude

save "$input/MWI_panel_key_R1234.dta"


* 1) Merging Seed datasets from the Rounds together (balanced panel - plots)
*==============================================================================*


use "$input/MWI_panel_key_R1234.dta", clear


merge 1:m case_id using "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/ag_mod_h_10.dta"

*remove those households that are not in the balanced panel and dont own plots.

drop if y2_hhid==""
drop if HHID==. 
drop if ag_h0b==. 

merge m:m y2_hhid using "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/ag_mod_h_13.dta", generate(_R2) force


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
keep case_id y2_hhid y3_hhid y4_hhid ea_id latitude longitude ag_h0b ag_h01a ag_h01b ag_h0c_R2 ag_h01a_R2 ag_h01b_R2 crop_code_R3 ag_h01a_R3 ag_h01b_R3 crop_code_R4 ag_h01a_R4 ag_h01b_R4

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

*All units to one (KG)
/* R1, R2, R3 & R4 
CODES FOR
UNIT:
GRAM........1
KILOGRAM....2
2 KG BAG....3
3 KG BAG....4
3.7 KG BAG..5
5 KG BAG....6
10 KG BAG...7
50 KG BAG...8
OTHER
(SPECIFY)...9
*/

*gram to kg:

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

*Create Panel Key for HHs with plots for the 4 Rs:

/*
bysort case_id: gen n=_n
keep if n==1
drop ag_h0b ag_h01a ag_h0c_R2 ag_h01a_R2 crop_code_R3 ag_h01a_R3 crop_code_R4 ag_h01a_R4 n
save "$input/MWI_panel_HHs_key_R1234.dta", replace
*/


* 1-A) Merging Other databases 
*==============================================================================*






* 2) Identification of Improved seeds 
*==============================================================================*


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

/* R1, R2, R3 & R4 seeds

           1 MAIZE LOCAL
           2 CMAIZE OMPOSITE/OPV
3 MAIZE HYBRID
4 MAIZE HYBRID RECYCLED
           5 TOBACCO BURLEY
		   6 TOBACCO FLUE CURED
           7 TOBACCO NNDF
           8 TOBACCO SDF
           9 TOBACCO ORIENTAL
          10 OTHER TOBACCO (SPECIFY)
          11 GROUNDNUT CHALIMBANA
12 GROUNDNUT CG7
13 GROUNDNUT MANIPINTA
14 GROUNDNUT MAWANGA
15 GROUNDNUT JL24
          16 OTHER GROUNDNUT (SPECIFY)
          17 RICE LOCAL
18 RICE FAYA
19 RICE PUSSA
20 RICE TCG10
21 RICE IET4094 (SENGA)
          22 RICE WAMBONE
          23 RICE KILOMBERO
24 RICE ITA
          25 RICE MTUPATUPA
          26 OTHER RICE (SPECIFY)
          27 GROUND BEAN(NZAMA)
          28 SWEET POTATO
          29 IRISH [MALAWI] POTATO
          30 WHEAT
          31 FINGER MILLET(MAWERE)
          32 SORGHUM
          33 PEARL MILLET(MCHEWERE)
          34 BEANS
          35 SOYABEAN
          36 PIGEONPEA(NANDOLO)
          37 COTTON
          38 SUNFLOWER
          39 SUGAR CANE
          40 CABBAGE
          41 TANAPOSI
          42 NKHWANI
          43 THERERE/OKRA
          44 TOMATO
          45 ONION
          46 PEA
          47 PAPRIKA
          48 OTHER (SPECIFY)

		  Malawi Integrated Household Panel Survey 2013, Agriculture and Fishery Enumerator Manual (ANNEX 3)
*/

*We need to identify the seeds that are improved:

forvalues round = 1/4 {
    // Generate the new variable for each round
    gen improved_R`round' = .
    
    // Replace the variable based on the values in seed_R
    replace improved_R`round' = 1 if inlist(seed_R`round', 3, 4, 12, 13, 14, 15, 18, 19, 20, 21, 24)
	replace improved_R`round' = 0 if improved_R`round'==.
}



* 3) Aggregation
*==============================================================================*

* 3.1) Aggregation - Proportion of Improved seeds in each ea_id
*==============================================================================*

bysort ea_id: gen n=_n

*Total semillas compradas por ronda y ea_id

bysort ea_id: egen total_kg_R1 = total(ag_h01a)
bysort ea_id: egen total_kg_R2 = total(ag_h01a_R2)
bysort ea_id: egen total_kg_R3 = total(ag_h01a_R3)
bysort ea_id: egen total_kg_R4 = total(ag_h01a_R4)


*total semilla mejorada para cada ea_id en cada ronda 
bysort ea_id: egen imp_kg_R1= total(ag_h01a * (improved_R1 == 1))
bysort ea_id: egen imp_kg_R2= total(ag_h01a_R2 * (improved_R2 == 1))
bysort ea_id: egen imp_kg_R3= total(ag_h01a_R3 * (improved_R3 == 1))
bysort ea_id: egen imp_kg_R4= total(ag_h01a_R4 * (improved_R4 == 1))


*Proportion of improved seeds used in each round 
gen prop_imp_R1 = imp_kg_R1 / total_kg_R1
gen prop_imp_R2 = imp_kg_R2 / total_kg_R2
gen prop_imp_R3 = imp_kg_R3 / total_kg_R3
gen prop_imp_R4 = imp_kg_R4 / total_kg_R4


keep if n== 1


drop seed_R1 ag_h01a seed_R2 ag_h01a_R2 seed_R3 ag_h01a_R3 seed_R4 ag_h01a_R4 improved_R1 improved_R2 improved_R3 improved_R4 n total_kg_R1 total_kg_R2 total_kg_R3 total_kg_R4 imp_kg_R1 imp_kg_R2 imp_kg_R3 imp_kg_R4 case_id y2_hhid y3_hhid y4_hhid

*save "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/prop_improved.dta" 



* 3.2) Aggregation - EA's and HH characteristics
*==============================================================================*

/*
Household Characteristics:

Module B:
B03 sex
B04 relationship to head -> HH head gender
B05 age -> HH head age

Module C:
C09 Highest education

Module E:
E19 main wage job -> salaried employed


Agriculuture Module: 

Module H:
H03 coupons/vouchers for seeds -> for improved
H04 credit for seed -> for improved
H41 left over seeds 
T01 advice obtained -> agriculture category 


Community Characteristics:

Module F:
F07 assist agr ext der officer live?
F17a sellers of hybrid maize
F18 average landholding size
F28 agriculture based project -> F30 main focus 

Module J:
J01 org that exist in community 

*/

*use "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/.dta", clear
*use "$input/prop_improved.dta", clear


***********************3.2.1) Household Characteristics:

*****ROUND 1:


use "$input/MWI_panel_key_R1234.dta", clear

*Module B

use "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/hh_mod_b_10.dta", clear

egen HH_head_fem = max(hh_b03 == 2 & hh_b04 == 1), by(case_id)
egen HH_head_age = max(hh_b05a * (hh_b04 == 1)), by(case_id)
replace HH_head_age=. if HH_head_age<1
replace HH_head_fem=. if HH_head_age==.


keep case_id ea_id id_code HH_head_fem HH_head_age hh_b04


*Module C

merge 1:1 case_id id_code ea_id using "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/hh_mod_c_10.dta"

egen HH_head_edu= max(hh_c09 * (hh_b04 == 1)), by(case_id) 
replace HH_head_edu=. if HH_head_edu==0
/*
NONE. . . 1
PSLC. . . 2
JCE . . . 3
MSCE. . . 4
NON-UNIV.DIPLOMA. 5
UNIVER.DIPLOMA,DEGREE . 6
POST-GRAD.DEGREE . 7
*/

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


*we aggregate it to ea_id level:


egen total_females = total(HH_head_fem), by(ea_id)   // Count total female-headed households per ea_id
egen total_households = count(HH_head_fem), by(ea_id) // Count total households per ea_id
gen prop_female_head = total_females / total_households // Calculate the proportion

egen mean_age_head = mean(HH_head_age), by(ea_id) //mean age of head 

egen total_emp = total(HH_head_salaried_emp), by(ea_id)   // Count total employed per ea_id
gen prop_salaried_head = total_emp / total_households // Calculate the proportion

tab HH_head_edu, gen(education_)
forval i = 1/7 {
    egen total_edu_`i' = total(education_`i'), by(ea_id)
    gen prop_head_edu_`i' = total_edu_`i' / total_households
}


keep case_id ea_id prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 prop_head_edu_7

bysort ea_id: gen n=_n
keep if n==1
drop n case_id 

ds
foreach var of varlist `r(varlist)' {
    rename `var' `var'_R1
}

rename ea_id_R1 ea_id


save "$input/HH_CHAR_R1.dta", replace


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



*we aggregate it to ea_id level:

egen total_females = total(HH_head_fem), by(ea_id)   // Count total female-headed households per ea_id
egen total_households = count(HH_head_fem), by(ea_id) // Count total households per ea_id
gen prop_female_head = total_females / total_households // Calculate the proportion

egen mean_age_head = mean(HH_head_age), by(ea_id) //mean age of head 

egen total_emp = total(HH_head_salaried_emp), by(ea_id)   // Count total employed per ea_id
gen prop_salaried_head = total_emp / total_households // Calculate the proportion

tab HH_head_edu, gen(education_)
forval i = 1/6 {
    egen total_edu_`i' = total(education_`i'), by(ea_id)
    gen prop_head_edu_`i' = total_edu_`i' / total_households
}


keep y2_hhid ea_id prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 

bysort ea_id: gen n=_n
keep if n==1
drop n 

ds
foreach var of varlist `r(varlist)' {
    rename `var' `var'_R2
}
rename y2_hhid_R2 y2_hhid
rename ea_id_R2 ea_id

save "$input/HH_CHAR_R2.dta", replace



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


*we aggregate it to ea_id level:

egen total_females = total(HH_head_fem), by(ea_id)   // Count total female-headed households per ea_id
egen total_households = count(HH_head_fem), by(ea_id) // Count total households per ea_id
gen prop_female_head = total_females / total_households // Calculate the proportion

egen mean_age_head = mean(HH_head_age), by(ea_id) //mean age of head 

egen total_emp = total(HH_head_salaried_emp), by(ea_id)   // Count total employed per ea_id
gen prop_salaried_head = total_emp / total_households // Calculate the proportion

tab HH_head_edu, gen(education_)
forval i = 1/7 {
    egen total_edu_`i' = total(education_`i'), by(ea_id)
    gen prop_head_edu_`i' = total_edu_`i' / total_households
}


keep y3_hhid ea_id prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 prop_head_edu_7

bysort ea_id: gen n=_n
keep if n==1
drop n 

ds
foreach var of varlist `r(varlist)' {
    rename `var' `var'_R3
}
rename y3_hhid_R3 y3_hhid
rename ea_id_R3 ea_id

save "$input/HH_CHAR_R3.dta", replace



*****ROUND 3:


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

egen total_females = total(HH_head_fem), by(ea_id)   // Count total female-headed households per ea_id
egen total_households = count(HH_head_fem), by(ea_id) // Count total households per ea_id
gen prop_female_head = total_females / total_households // Calculate the proportion

egen mean_age_head = mean(HH_head_age), by(ea_id) //mean age of head 

egen total_emp = total(HH_head_salaried_emp), by(ea_id)   // Count total employed per ea_id
gen prop_salaried_head = total_emp / total_households // Calculate the proportion

tab HH_head_edu, gen(education_)
forval i = 1/7 {
    egen total_edu_`i' = total(education_`i'), by(ea_id)
    gen prop_head_edu_`i' = total_edu_`i' / total_households
}


keep y4_hhid ea_id prop_female_head mean_age_head prop_salaried_head prop_head_edu_1 prop_head_edu_2 prop_head_edu_3 prop_head_edu_4 prop_head_edu_5 prop_head_edu_6 prop_head_edu_7

bysort ea_id: gen n=_n
keep if n==1
drop n 

ds
foreach var of varlist `r(varlist)' {
    rename `var' `var'_R4
}
rename y4_hhid_R4 y4_hhid
rename ea_id_R4 ea_id

save "$input/HH_CHAR_R4.dta", replace




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

egen total_plot_size= total(ag_c04c), by(ea_id) 
egen total_coupon = total(coupon_imp), by(ea_id)   
egen total_plots = count(coupon_imp), by(ea_id) 
gen prop_coupon = total_coupon / total_plots //I have the proportion of plots that used coupons to purchase improved seeds

egen total_credit = total(credit_imp), by(ea_id)   
gen prop_credit = total_credit / total_plots //I have the proportion of plots that used credit to purchase improved seeds 

egen total_left_seeds = total(left_over_seeds), by(ea_id)   
gen prop_left_seeds = total_left_seeds / total_plots //I have the proportion of plots that used left over seeds 

*I need an unique value in each hh
bysort case_id: gen hh=_n
gen advice_final= (advice==1 & hh==1)
egen total_advice = total(advice_final), by(ea_id)  
egen total_hh = total(hh==1), by(ea_id) 
gen prop_advice = total_advice / total_hh //I have the proportion of plots that used left over seeds 


keep ea_id prop_coupon prop_credit prop_left_seeds prop_advice total_plot_size

bysort ea_id: gen n=_n
keep if n==1
drop n 

ds
foreach var of varlist `r(varlist)' {
    rename `var' `var'_R1
}

rename ea_id_R1 ea_id

save "$input/AGRO_CHAR_R1.dta", replace




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

egen total_plot_size= total(ag_c04c), by(ea_id) 
egen total_coupon = total(coupon_imp), by(ea_id)   
egen total_plots = count(coupon_imp), by(ea_id) 
gen prop_coupon = total_coupon / total_plots //I have the proportion of plots that used coupons to purchase improved seeds

egen total_credit = total(credit_imp), by(ea_id)   
gen prop_credit = total_credit / total_plots //I have the proportion of plots that used credit to purchase improved seeds 

egen total_left_seeds = total(left_over_seeds), by(ea_id)   
gen prop_left_seeds = total_left_seeds / total_plots //I have the proportion of plots that used left over seeds 

*I need an unique value in each hh
bysort y2_hhid: gen hh=_n
gen advice_final= (advice==1 & hh==1)
egen total_advice = total(advice_final), by(ea_id)  
egen total_hh = total(hh==1), by(ea_id) 
gen prop_advice = total_advice / total_hh //I have the proportion of plots that used left over seeds 


keep ea_id prop_coupon prop_credit prop_left_seeds prop_advice total_plot_size

bysort ea_id: gen n=_n
keep if n==1
drop n 

ds
foreach var of varlist `r(varlist)' {
    rename `var' `var'_R2
}

rename ea_id_R2 ea_id

save "$input/AGRO_CHAR_R2.dta", replace


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

egen total_plot_size= total(ag_c04c), by(ea_id) 
egen total_coupon = total(coupon_imp), by(ea_id)   
egen total_plots = count(coupon_imp), by(ea_id) 
gen prop_coupon = total_coupon / total_plots //I have the proportion of plots that used coupons to purchase improved seeds

egen total_credit = total(credit_imp), by(ea_id)   
gen prop_credit = total_credit / total_plots //I have the proportion of plots that used credit to purchase improved seeds 

egen total_left_seeds = total(left_over_seeds), by(ea_id)   
gen prop_left_seeds = total_left_seeds / total_plots //I have the proportion of plots that used left over seeds 

*I need an unique value in each hh
bysort y3_hhid: gen hh=_n
gen advice_final= (advice==1 & hh==1)
egen total_advice = total(advice_final), by(ea_id)  
egen total_hh = total(hh==1), by(ea_id) 
gen prop_advice = total_advice / total_hh //I have the proportion of plots that used left over seeds 


keep ea_id prop_coupon prop_credit prop_left_seeds prop_advice total_plot_size

bysort ea_id: gen n=_n
keep if n==1
drop n 

ds
foreach var of varlist `r(varlist)' {
    rename `var' `var'_R3
}

rename ea_id_R3 ea_id

save "$input/AGRO_CHAR_R3.dta", replace






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

egen total_plot_size= total(ag_c04c), by(ea_id) 
egen total_coupon = total(coupon_imp), by(ea_id)   
egen total_plots = count(coupon_imp), by(ea_id) 
gen prop_coupon = total_coupon / total_plots //I have the proportion of plots that used coupons to purchase improved seeds

egen total_credit = total(credit_imp), by(ea_id)   
gen prop_credit = total_credit / total_plots //I have the proportion of plots that used credit to purchase improved seeds 

egen total_left_seeds = total(left_over_seeds), by(ea_id)   
gen prop_left_seeds = total_left_seeds / total_plots //I have the proportion of plots that used left over seeds 

*I need an unique value in each hh
bysort y4_hhid: gen hh=_n
gen advice_final= (advice==1 & hh==1)
egen total_advice = total(advice_final), by(ea_id)  
egen total_hh = total(hh==1), by(ea_id) 
gen prop_advice = total_advice / total_hh //I have the proportion of plots that used left over seeds 


keep ea_id prop_coupon prop_credit prop_left_seeds prop_advice total_plot_size

bysort ea_id: gen n=_n
keep if n==1
drop n 

ds
foreach var of varlist `r(varlist)' {
    rename `var' `var'_R4
}

rename ea_id_R4 ea_id

save "$input/AGRO_CHAR_R4.dta", replace





***********************3.2.3) Community Characteristics:

/*
Community Characteristics:

Module F:
F07 assist agr ext der officer live?
F12 sellers of hybrid maize
F18 average landholding size (no esta en R1)
F28 agriculture based project -> F30 main focus (no esta en R1)

Module J:
J01 org that exist in community 
*/


****** Ronda 1


use "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/com_cf_10.dta", clear


codebook com_cf07 // Does  an Assistant Ag Extension Development Officer live in this community? 1: Y 2: N

gen assistant_ag_officer = .
replace assistant_ag_officer=1 if com_cf07==1
replace assistant_ag_officer=0 if com_cf07==2

rename com_cf12 maize_hybrid_sellers

keep ea_id assistant_ag_officer maize_hybrid_sellers

ds
foreach var of varlist `r(varlist)' {
    rename `var' `var'_R1
}

rename ea_id_R1 ea_id

tempfile temp_data
save `temp_data'

use "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/com_cj_10.dta", clear

codebook com_cj0b
label list  COM_CJ0B // 302 Agricultural Coop

keep if com_cj0b== 302

gen agri_coop = .
replace agri_coop=1 if com_cj01==1
replace agri_coop=0 if com_cj01==2
label variable agri_coop "Do they have an Agricultural Coop in community?"

replace com_cj04=0 if com_cj04==.
rename com_cj04 members_agri_coop
keep ea_id agri_coop members_agri_coop

ds
foreach var of varlist `r(varlist)' {
    rename `var' `var'_R1
}

rename ea_id_R1 ea_id

merge m:1 ea_id using `temp_data'
drop _merge

merge 1:m ea_id using "$input/ea_coordinates.dta"
drop if _merge==1
drop _merge

order ea_id latitude longitude

save "$input/COMM_CHAR_R1.dta", replace




****** Ronda 2


use "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/com_mod_f1_13.dta", clear


codebook com_cf07 // Does  an Assistant Ag Extension Development Officer live in this community? 1: Y 2: N

gen assistant_ag_officer = .
replace assistant_ag_officer=1 if com_cf07==1
replace assistant_ag_officer=0 if com_cf07==2

rename com_cf12 maize_hybrid_sellers

keep ea_id assistant_ag_officer maize_hybrid_sellers

ds
foreach var of varlist `r(varlist)' {
    rename `var' `var'_R2
}

rename ea_id_R2 ea_id

tempfile temp_data
save `temp_data'

use "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/com_mod_j_13.dta", clear

codebook com_cj0b
label list  COM_CJ0B // 302 Agricultural Coop

keep if com_cj0b== 302

gen agri_coop = .
replace agri_coop=1 if com_cj01==1
replace agri_coop=0 if com_cj01==2
label variable agri_coop "Do they have an Agricultural Coop in community?"

replace com_cj04=0 if com_cj04==.
rename com_cj04 members_agri_coop
keep ea_id agri_coop members_agri_coop

ds
foreach var of varlist `r(varlist)' {
    rename `var' `var'_R2
}

rename ea_id_R2 ea_id

merge m:1 ea_id using `temp_data'
drop _merge

merge 1:m ea_id using "$input/ea_coordinates.dta"
drop if _merge==1
drop _merge

order ea_id latitude longitude

save "$input/COMM_CHAR_R2.dta", replace




****** Ronda 3


use "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/com_cf1_16.dta", clear



gen assistant_ag_officer = .
replace assistant_ag_officer=1 if com_cf07==1
replace assistant_ag_officer=0 if com_cf07==2

rename com_cf12 maize_hybrid_sellers

keep ea_id assistant_ag_officer maize_hybrid_sellers
bysort ea_id: gen n=_n
drop if n==2
ds
foreach var of varlist `r(varlist)' {
    rename `var' `var'_R3
}

rename ea_id_R3 ea_id
duplicates list ea_id

tempfile temp_data
save `temp_data'

use "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/com_cj_16.dta", clear


keep if com_cj0b== 302

gen agri_coop = .
replace agri_coop=1 if com_cj01==1
replace agri_coop=0 if com_cj01==2
label variable agri_coop "Do they have an Agricultural Coop in community?"

replace com_cj04=0 if com_cj04==.
rename com_cj04 members_agri_coop
keep ea_id agri_coop members_agri_coop
bysort ea_id: gen n=_n
drop if n==2

ds
foreach var of varlist `r(varlist)' {
    rename `var' `var'_R3
}

rename ea_id_R3 ea_id

merge m:1 ea_id using `temp_data', force
drop _merge

merge 1:m ea_id using "$input/ea_coordinates.dta"
drop if _merge==1
drop _merge

order ea_id latitude longitude
drop n_R3
save "$input/COMM_CHAR_R3.dta", replace



****** Ronda 4


use "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/com_cf1_19.dta", clear



gen assistant_ag_officer = .
replace assistant_ag_officer=1 if com_cf07==1
replace assistant_ag_officer=0 if com_cf07==2

rename com_cf12 maize_hybrid_sellers

keep ea_id assistant_ag_officer maize_hybrid_sellers
bysort ea_id: gen n=_n
drop if n==2
ds
foreach var of varlist `r(varlist)' {
    rename `var' `var'_R4
}

rename ea_id_R4 ea_id
duplicates list ea_id

tempfile temp_data
save `temp_data'

use "/Users/juansegundozapiola/Documents/UdeSA/Thesis/extras/MWI 2010-2019/com_cj_19.dta", clear


keep if com_cj0b== 302

gen agri_coop = .
replace agri_coop=1 if com_cj01==1
replace agri_coop=0 if com_cj01==2
label variable agri_coop "Do they have an Agricultural Coop in community?"

replace com_cj04=0 if com_cj04==.
rename com_cj04 members_agri_coop
keep ea_id agri_coop members_agri_coop
bysort ea_id: gen n=_n
drop if n==2

ds
foreach var of varlist `r(varlist)' {
    rename `var' `var'_R4
}

rename ea_id_R4 ea_id

merge m:1 ea_id using `temp_data', force
drop _merge

merge 1:m ea_id using "$input/ea_coordinates.dta"
drop if _merge==1
drop _merge

order ea_id latitude longitude
drop n_R4

save "$input/COMM_CHAR_R4.dta", replace




* 3.3) Final Aggregation - Proportion of Improved seeds, SPEI, EA's and HH characteristics
*==============================================================================*

*We need to aggregate prop_imporved.dta + HH_CHAR_R* + AGRO_CHAR_R* + COMM_CHAR_R* + SPEI_ea


*Let´s start with Round 1:

use "$input/prop_improved.dta", clear

merge 1:1 ea_id using "$input/HH_CHAR_R1.dta", force
drop _merge

merge 1:1 ea_id using "$input/AGRO_CHAR_R1.dta", force
drop _merge

merge 1:1 ea_id using "$input/COMM_CHAR_R1.dta", force
drop _merge


*Round 2:

merge 1:1 ea_id using "$input/HH_CHAR_R2.dta", force
drop _merge

merge 1:1 ea_id using "$input/AGRO_CHAR_R2.dta", force
drop _merge

merge 1:1 ea_id using "$input/COMM_CHAR_R2.dta", force
drop _merge
drop y2_hhid


*Round 3:

merge 1:1 ea_id using "$input/HH_CHAR_R3.dta", force
drop _merge

merge 1:1 ea_id using "$input/AGRO_CHAR_R3.dta", force
drop _merge

merge 1:1 ea_id using "$input/COMM_CHAR_R3.dta", force
drop _merge
drop y3_hhid


*Round 4:

merge 1:1 ea_id using "$input/HH_CHAR_R4.dta", force
drop _merge

merge 1:1 ea_id using "$input/AGRO_CHAR_R4.dta", force
drop _merge

merge 1:1 ea_id using "$input/COMM_CHAR_R4.dta", force
drop _merge
drop y4_hhid


*Let's add SPEI

merge 1:1 ea_id using "$input/SPEI_ea.dta", force
drop _merge

*Now all the variables are togheter, but we need it as a panel. 

rename SPEI_2009 SPEI_R1
rename SPEI_2012 SPEI_R2
rename SPEI_2015 SPEI_R3
rename SPEI_2018 SPEI_R4


reshape long prop_imp_R prop_female_head_R mean_age_head_R prop_salaried_head_R prop_head_edu_1_R prop_head_edu_2_R prop_head_edu_3_R prop_head_edu_4_R prop_head_edu_5_R prop_head_edu_6_R prop_head_edu_7_R total_plot_size_R prop_coupon_R prop_credit_R prop_left_seeds_R prop_advice_R members_agri_coop_R agri_coop_R maize_hybrid_sellers_R assistant_ag_officer_R SPEI_R, i(ea_id) j(round)

foreach var in prop_imp_R prop_female_head_R mean_age_head_R prop_salaried_head_R prop_head_edu_1_R prop_head_edu_2_R prop_head_edu_3_R prop_head_edu_4_R prop_head_edu_5_R prop_head_edu_6_R prop_head_edu_7_R total_plot_size_R prop_coupon_R prop_credit_R prop_left_seeds_R prop_advice_R members_agri_coop_R agri_coop_R maize_hybrid_sellers_R assistant_ag_officer_R SPEI_R {
    local base = substr("`var'", 1, strpos("`var'", "_R") - 1) // Extract the part before "_R"
    rename `var' `base' // Rename the variable
}


drop round

bysort ea_id: gen round=_n

order ea_id latitude longitude round prop_imp SPEI

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

save "$input/MALAWI_panel.dta", replace

















