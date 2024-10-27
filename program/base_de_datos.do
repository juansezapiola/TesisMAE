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
keep case_id y2_hhid y3_hhid y4_hhid ea_id latitude longitude ag_h0b ag_h0c_R2 crop_code_R3 crop_code_R4 

















