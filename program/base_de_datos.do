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


* 0) Merging
*==============================================================================*
****Round keys:
use "$input/TZA R1-R5/TZA_R3/NPSY3.PANEL.KEY.dta", clear

*I keep all those households that stay in the 3 rounds 
drop if UPI3>16709
keep if indidy1==1
drop if indidy2==.
drop if indidy3==.

save "$input/TZA R1-R5/Round123_clean_key.dta"


*****TZA R1 - R2 - R3:

use "$input/TZA R1-R5/Round123_clean_key.dta", clear
merge 1:m y1_hhid using "$input/TZA R1-R5/TZA_R1/SEC_4A.dta"

*drop all hh that dont follow in R2 and R3
drop if indidy1==.
drop if zaocode==. 

merge m:m y2_hhid using "$input/TZA R1-R5/TZA_R2/AG_SEC4A.dta", generate(_R2)

drop if indidy1==.
drop if zaocode_R2==. 

merge m:m y3_hhid using "$input/TZA R1-R5/TZA_R3/AG_SEC_4A.dta", generate(_R3)

drop if indidy1==.
drop if zaocode_R3==. 

save "$input/TZA R1-R5/Round123_merged.dta", replace



use  "$input/TZA R1-R5/Round123_merged.dta", clear


* 1) Cleaning data
*==============================================================================*
* Visualizing data
browse

*keep y1_hhid y2_hhid y3_hhid zaocode s4aq19 s4aq20 s4aq21_1 s4aq21_2 s4aq22 zaocode_R2 ag4a_19_R2 ag4a_20_R2 ag4a_21_R2 ag4a_22_1_R2 ag4a_22_2_R2 ag4a_23_R2 zaocode_R3 ag4a_08_R3 ag4a_09_R3 ag4a_11_R3 ag4a_12_R3 ag4a_13_1_R3 ag4a_13_2_R3


*Add EA_ID to base
gen EA_ID = substr(y1_hhid, 1, 10)  

* Order dataset
order hhid EA_ID plotnum zaocode s4aq19 s4aq20 s4aq21_1 s4aq21_2 s4aq22 s4aq23 // order columns
sort EA_ID //order based on ea_id

*Info from ea_id 
tab EA_ID 
describe EA_ID //str10
mdesc EA_ID // no missings
tab zaocode s4aq19

* Check missings
	*ssc install mdesc // help mdesc
mdesc s4aq19 //Bought seeds? Y/N (31/5704 missings)
mdesc s4aq22 // no missings
drop if s4aq19==. //drop those observations that did not respond 

*I check if there is no missing value for those "YES" responses in s4aq19
count if missing(s4aq20) & s4aq19 == 1

*For those observations that did not purchase seeds, 
replace s4aq20=0 if s4aq20==.



* 2) Aggregate at EA_ID level
*==============================================================================*

bysort EA_ID: gen n=_n
 
*Total of improved seeds purchased in each EA_ID
bysort EA_ID: egen exp_imp = total(s4aq20 * (s4aq22 == 2))
bysort EA_ID: egen exp_imp_R2 = total(ag4a_21_R2 * (ag4a_23_R2 == 2))
bysort EA_ID: egen exp_imp_R3 = total(ag4a_12_R3 * (ag4a_08_R3 == 1 & 3))



keep if n== 1
keep EA_ID exp_imp exp_imp_R2 exp_imp_R3

summarize exp_imp exp_imp_R2 exp_imp_R3




















