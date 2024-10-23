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


*****TZA R1:

use "$input/TZA R1-R5/TZA_R1/SEC_4A.dta", clear

* 1) Cleaning data
*==============================================================================*
* Visualizing data
browse

*Add EA_ID to base
gen EA_ID = substr(hhid, 1, 10)  

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
bysort EA_ID: egen expenditure_improved = total(s4aq20 * (s4aq22 == 2))


keep if n== 1
keep EA_ID exp_improved

summarize exp_improved




















