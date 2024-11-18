********************************************************************************
*----------------        Limpieza y Orden: Base de Datos       ----------------* 
*----------------                                              ----------------*
*----------------	         Juan Segundo Zapiola              ----------------* 
*----------------				                               ----------------* 
*----------------           Universidad de San Andrés          ----------------* 
*----------------              Tesis Maestría Econ             ----------------* 
*----------------				     2024                      ----------------* 
********************************************************************************

*clean 
clear all

*Directory 							
gl main "/Users/juansegundozapiola/Documents/Maestria/TesisMAE"
gl input "$main/input"
gl output "$main/output"


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












