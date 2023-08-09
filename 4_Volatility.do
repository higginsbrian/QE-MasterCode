// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// This program generates the time series of Volatility and Higher Order Moments
// First  version January  06, 2019
// This version   March  13, 2023
// Serdar Ozkan and Sergio Salgado
// PLEASE DO NOT MAKE ANY CHANGES IN THE CODE
// IF YOU EXPERIENCE PROBLEMS, PLEASE CONTACT OZKAN OR SALGADO ON THE GRID SLACK CHANNEL
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

// Create folder for output and log-file
global outfolder=c(current_date)
global outfolder="$outfolder Volatility"
capture noisily mkdir "$maindir${sep}out${sep}$outfolder"
capture log close
capture noisily log using "$maindir${sep}log${sep}$outfolder.log", replace

// Cd to the output file, create the program for moments, and load base sample.
cd "$maindir${sep}out${sep}$outfolder"

// Defines the number of points in the Kernel Density Estimator
global kpoints =  400

// Loop over the years
timer clear 1
timer on 1

// global d1yrlist = "2000"	// For debug
// global d5yrlist = "2000"

foreach yr of numlist $d1yrlist{
	disp("---------------------------------")
	disp("Volatility: Working in year `yr'")
	disp("---------------------------------")

	local yrp = `yr' - 1		// Past year
	
	if inlist(`yrp',${perm3yrlist}){
		// If permanent income CAN be calculated (H Sample)
		if inlist(`yr',${d5yrlist}){				// Has 5yr change (LX Sample)
			use  male yob educ logearn1F`yr' logearn5F`yr' researn1F`yr' researn5F`yr' arcearn1F`yr' arcearn5F`yr' permearn`yrp' ///
			using "$maindir${sep}dta${sep}master_sample.dta", clear   
		}
		else{
			use  male yob educ logearn1F`yr' researn1F`yr' arcearn1F`yr' permearn`yrp' ///
			using "$maindir${sep}dta${sep}master_sample.dta", clear   
		}
	}
	else{
		// If permanent income CANNOT be calculated (LX sample)
		if inlist(`yr',${d5yrlist}){  // Has 5yr change (LX Sample)
			use  male yob educ logearn1F`yr' logearn5F`yr' researn1F`yr' researn5F`yr' arcearn1F`yr' arcearn5F`yr'  ///
			using "$maindir${sep}dta${sep}master_sample.dta", clear   
			
		}
		else{
			use  male yob educ logearn1F`yr' researn1F`yr' arcearn1F`yr' ///
			using "$maindir${sep}dta${sep}master_sample.dta", clear   
		}
	}
	
	// Create year
	gen year=`yr'
	
	// Create age 
	gen age = `yr'-yob+1
	qui: drop if age<${begin_age} | age>${end_age}

	// Create age groups 
	qui {
		gen agegp = . 
		replace agegp = 1 if age<= 34 & agegp == .
		replace agegp = 2 if age<= 44 & agegp == .
		replace agegp = 3 if age > 44 & agegp == .
	}
				
	// Calculate cross sectional moments for year `yr'
	foreach meas in log res arc{
		// Moments of 1 year changes		
		// Cross sectional
		bymysum_detail "`meas'earn1F" "L_" "_`yr'" "year"
	
		bymyPCT "`meas'earn1F" "L_" "_`yr'" "year"
		
		// Calculate cross sectional moments for year `yr' within heterogeneity groups
		foreach  vv in $hetgroup{ 
			local suf=subinstr("`vv'"," ","",.)
			
			bymysum_detail "`meas'earn1F" "L_" "_`suf'`yr'" "year `vv'"
		
			bymyPCT "`meas'earn1F" "L_" "_`suf'`yr'" "year `vv'"	
			
		}

		// Moments of 5 year changes
		if inlist(`yr',${d5yrlist}){
			
			bymysum_detail "`meas'earn5F" "L_" "_`yr'" "year"
		
			bymyPCT "`meas'earn5F" "L_" "_`yr'" "year"
									
			foreach  vv in $hetgroup{ 
				local suf=subinstr("`vv'"," ","",.)
			
				bymysum_detail "`meas'earn5F" "L_" "_`suf'`yr'" "year `vv'"
		
				bymyPCT "`meas'earn5F" "L_" "_`suf'`yr'" "year `vv'"	
			}
		}
	}	// type of change
	
	// Calculate Empirical Density of one year and five years changes 
	// Notice we are doing this for years that can be divided by kyear
	if mod(`yr',${kyear}) == 0 {
			bymyKDN "researn1F" "L_" "${kpoints}" "`yr'"
			bymyKDNmale "researn1F" "L_" "${kpoints}" "`yr'"
			
		if inlist(`yr',${d5yrlist}){
			bymyKDN "researn5F" "L_" "${kpoints}" "`yr'"
			bymyKDNmale "researn5F" "L_" "${kpoints}" "`yr'"
		}
	}
		
	// Calculate "kurtosis" moments for one- and five-years changes
	kurpercentiles "researn1F" "PK" "`yr'"
	if inlist(`yr',${d5yrlist}){
		kurpercentiles "researn5F" "PK" "`yr'"	
	}
	
	// Calculate "kurtosis" noments for one- and five-years withn age groups
	levelsof agegp, local(agp) clean	
	foreach aa of local agp{
	
		gen researn1F`aa' = researn1F if agegp == `aa'
		kurpercentiles "researn1F`aa'" "PKage" "`yr'"
		drop researn1F`aa' 
				
		if inlist(`yr',${d5yrlist}){
			gen researn5F`aa' = researn5F if agegp == `aa' 
			kurpercentiles "researn5F`aa'" "PKage" "`yr'"	
			drop researn5F`aa'
		}
	}
	*/
		
	*
	// Moments within percentiles of the permanent income distribution
	// for the years in which permanent income and 5 yr changes can be 
	// calculated (H sample of the guidelines)
	
	if inlist(`yrp',${perm3yrlist}) & inlist(`yr',${d5yrlist}){
			// Individuals must have perm income, 1yr change and 5 yr change to be in the H sample
			// Notice here we will consider growth rate with income above min tresh in t but above 1/3*min tresh in t+1
			// See 1_Gen_Base_Sample.do for more details; 
			foreach meas in log arc res{			
			// Notice, we start with the arc percent since researn is a subset of arc
			drop if `meas'earn1F == . | `meas'earn5F == .	| permearn == . 
				
			// Overall ranking 
			// Ranking created for those individuals that have measure of earnings growth
			gen permrank = .
			bymyxtile permearn permrank "${nquantiles}"	// This puts individuals into nquantiles bins
			
			replace permrank = (100/${nquantiles})*(permrank)
			_pctile permearn, p(97.5 99 99.9)
			
			replace permrank = 99 if permearn > r(r1) & permearn <= r(r2) & permearn !=. 
			replace permrank = 99.9 if permearn > r(r2) & permearn <= r(r3) & permearn !=. 
			replace permrank = 100 if permearn > r(r3) & permearn !=.				
						
			gen permrankT025 = 1 if permearn >= r(r1) & permearn !=. 	// Top 2.5P
			replace permrankT025 = 0 if permrankT025 == . 
			gen permrankT01 =  1 if permearn >= r(r2) & permearn !=. 	// Top 1P. Notice we have the top 0.1 already
			replace permrankT01 = 0 if permrankT01 == . 
									
			bymysum_detail "`meas'earn1F" "L_" "_allrank`yr'" "year permrank"
			bymyPCT "`meas'earn1F" "L_" "_allrank`yr'" "year permrank"	
			
			bymysum_detail "`meas'earn5F" "L_" "_allrank`yr'" "year permrank"
			bymyPCT "`meas'earn5F" "L_" "_allrank`yr'" "year permrank"
			
				foreach uup in T025 T01{					
					bymysum_detail "`meas'earn1F" "L_" "_allrank`uup'`yr'" "year permrank`uup'"
					bymyPCT "`meas'earn1F" "L_" "_allrank`uup'`yr'" "year permrank`uup'"	
			
					bymysum_detail "`meas'earn5F" "L_" "_allrank`uup'`yr'" "year permrank`uup'"
					bymyPCT "`meas'earn5F" "L_" "_allrank`uup'`yr'" "year permrank`uup'"
				}
												
			* Calculate "kurtosis" moments within permrank
			if "`meas'" == "res"{
				gen permrankaux = int(permrank/2.5)
				levelsof permrankaux, local(pgp) clean	
				foreach pp of local pgp{
					gen `meas'earn1Fp`pp' = `meas'earn1F if permrankaux == `pp'
					gen `meas'earn5Fp`pp' = `meas'earn5F if permrankaux == `pp' 
			
					kurpercentiles "`meas'earn1Fp`pp'" "PK" "`yr'"
					kurpercentiles "`meas'earn5Fp`pp'" "PK" "`yr'"
					drop `meas'earn1Fp`pp' `meas'earn5Fp`pp' n`meas'earn1Fp`pp' n`meas'earn5Fp`pp'
				}
				drop permrankaux				
			}
				drop permrank permrankT025 permrankT01
			
			// Within age group rankings
			gen permrank = .
			bys agegp: bymyxtile permearn permrank "${nquantiles}"	
			replace permrank = (100/${nquantiles})*(permrank)
			
			bys agegp: egen aux1 = pctile(permearn), p(97.5)
			bys agegp: egen aux2 = pctile(permearn), p(99)
			bys agegp: egen aux3 = pctile(permearn), p(99.9)
			
			replace permrank = 99   if permearn > aux1 & permearn <= aux2 & permearn !=. 
			replace permrank = 99.9 if permearn > aux2 & permearn <= aux3 & permearn !=. 
			replace permrank = 100  if permearn > aux3 & permearn !=. 
						
			gen permrankT025 = 1 if permearn >= aux1 & permearn !=. 	// Top 2.5P
			replace permrankT025 = 0 if permrankT025 == . 
			gen permrankT01 =  1 if permearn >= aux2 & permearn !=. 	// Top 1P. Notice we have the top 0.1 already
			replace permrankT01 = 0 if permrankT01 == . 
			
			drop aux1 aux2 aux3
			
			bymysum_detail "`meas'earn1F" "L_" "_agerank`yr'" "year agegp permrank"
			bymyPCT "`meas'earn1F" "L_" "_agerank`yr'" "year agegp permrank"
			
			bymysum_detail "`meas'earn5F" "L_" "_agerank`yr'" "year agegp permrank"
			bymyPCT "`meas'earn5F" "L_" "_agerank`yr'" "year agegp permrank"
							
			foreach uup in T025 T01{
				bymysum_detail "`meas'earn1F" "L_" "_agerank`uup'`yr'" "year agegp permrank`uup'"
				bymyPCT "`meas'earn1F" "L_" "_agerank`uup'`yr'" "year agegp permrank`uup'"	
		
				bymysum_detail "`meas'earn5F" "L_" "_agerank`uup'`yr'" "year agegp permrank`uup'"
				bymyPCT "`meas'earn5F" "L_" "_agerank`uup'`yr'" "year agegp permrank`uup'"
			}
						
			// Calculate "kurtosis" moments within permrank/agegp 
			if "`meas'" == "res"{
				gen permrankaux = int(permrank/2.5)
				levelsof permrankaux, local(pgp) clean	
				levelsof agegp, local(agp) clean	
				foreach pp of local pgp{				
					foreach aa of local agp {
						gen `meas'earn1Fp`pp'_`aa' = `meas'earn1F if permrankaux == `pp' & agegp == `aa'
						gen `meas'earn5Fp`pp'_`aa' = `meas'earn5F if permrankaux == `pp' & agegp == `aa' 
				
						kurpercentiles "`meas'earn1Fp`pp'_`aa'" "PK" "`yr'"
						kurpercentiles "`meas'earn5Fp`pp'_`aa'" "PK" "`yr'"
						drop `meas'earn1Fp`pp'_`aa' `meas'earn5Fp`pp'_`aa' n`meas'earn1Fp`pp'_`aa' n`meas'earn5Fp`pp'_`aa'
					}
				}			
				drop permrankaux 
			}
			drop permrank permrankT025 permrankT01
			
			
			// Within gender group rankings			
			gen permrank = .
			bys male: bymyxtile permearn permrank "${nquantiles}"	
			replace permrank = (100/${nquantiles})*(permrank)
			
			bys male: egen aux1 = pctile(permearn), p(97.5)
			bys male: egen aux2 = pctile(permearn), p(99)
			bys male: egen aux3 = pctile(permearn), p(99.9)
			
			replace permrank = 99 if permearn > aux1 & permearn <= aux2 & permearn !=. 
			replace permrank = 99.9 if permearn > aux2 & permearn <= aux3 & permearn !=. 
			replace permrank = 100 if permearn > aux3 & permearn !=. 
			
			gen permrankT025 = 1 if permearn >= aux1 & permearn !=. 	// Top 2.5P
			replace permrankT025 = 0 if permrankT025 == . 
			gen permrankT01 =  1 if permearn >= aux2 & permearn !=. 	// Top 1P. Notice we have the top 0.1 already
			replace permrankT01 = 0 if permrankT01 == . 
			
			drop aux1 aux2 aux3
			
			bymysum_detail "`meas'earn1F" "L_" "_malerank`yr'" "year male permrank"
			bymyPCT "`meas'earn1F" "L_" "_malerank`yr'" "year male permrank"
			
			bymysum_detail "`meas'earn5F" "L_" "_malerank`yr'" "year male permrank"
			bymyPCT "`meas'earn5F" "L_" "_malerank`yr'" "year male permrank"
						
			foreach uup in T025 T01{
				bymysum_detail "`meas'earn1F" "L_" "_malerank`uup'`yr'" "year male permrank`uup'"
				bymyPCT "`meas'earn1F" "L_" "_malerank`uup'`yr'" "year male permrank`uup'"	
		
				bymysum_detail "`meas'earn5F" "L_" "_malerank`uup'`yr'" "year male permrank`uup'"
				bymyPCT "`meas'earn5F" "L_" "_malerank`uup'`yr'" "year male permrank`uup'"
			}						
					
			* Calculate "kurtosis" moments within permrank/agegp 
			if "`meas'" == "res"{	
				gen permrankaux = int(permrank/2.5)
				levelsof permrankaux, local(pgp) clean	
				levelsof agegp, local(agp) clean	
				foreach pp of local pgp{
					foreach aa of local agp {
						gen `meas'earn1Fp`pp'_`aa' = `meas'earn1F if permrankaux == `pp' & agegp == `aa'
						gen `meas'earn5Fp`pp'_`aa' = `meas'earn5F if permrankaux == `pp' & agegp == `aa' 
				
						kurpercentiles "`meas'earn1Fp`pp'_`aa'" "PK" "`yr'"
						kurpercentiles "`meas'earn5Fp`pp'_`aa'" "PK" "`yr'"
						drop `meas'earn1Fp`pp'_`aa' `meas'earn5Fp`pp'_`aa' n`meas'earn1Fp`pp'_`aa' n`meas'earn5Fp`pp'_`aa'
					}
				}
				drop permrankaux 
			}
			drop permrank permrankT025 permrankT01	
			
						
			// Within gender/age group rankings			
			gen permrank = .
			bys male agegp: bymyxtile permearn permrank "${nquantiles}"	
			replace permrank = (100/${nquantiles})*(permrank)
			
			bys male agegp: egen aux1 = pctile(permearn), p(97.5)
			bys male agegp: egen aux2 = pctile(permearn), p(99)
			bys male agegp: egen aux3 = pctile(permearn), p(99.9)
			
			replace permrank = 99 if permearn > aux1 & permearn <= aux2 & permearn !=. 
			replace permrank = 99.9 if permearn > aux2 & permearn <= aux3 & permearn !=. 
			replace permrank = 100 if permearn > aux3 & permearn !=. 
			
			gen permrankT025 = 1 if permearn >= aux1 & permearn !=. 	// Top 2.5P
			replace permrankT025 = 0 if permrankT025 == . 
			gen permrankT01 =  1 if permearn >= aux2 & permearn !=. 	// Top 1P. Notice we have the top 0.1 already
			replace permrankT01 = 0 if permrankT01 == . 
						
			drop aux1 aux2 aux3
			
			bymysum_detail "`meas'earn1F" "L_" "_maleagerank`yr'" "year male agegp permrank"
			bymyPCT "`meas'earn1F" "L_" "_maleagerank`yr'" "year male agegp permrank"
			
			bymysum_detail "`meas'earn5F" "L_" "_maleagerank`yr'" "year male agegp permrank"
			bymyPCT "`meas'earn5F" "L_" "_maleagerank`yr'" "year male agegp permrank"
			
			foreach uup in T025 T01{
				bymysum_detail "`meas'earn1F" "L_" "_maleagerank`uup'`yr'" "year male agegp permrank`uup'"
				bymyPCT "`meas'earn1F" "L_" "_maleagerank`uup'`yr'" "year male agegp permrank`uup'"	
		
				bymysum_detail "`meas'earn5F" "L_" "_maleagerank`uup'`yr'" "year male agegp permrank`uup'"
				bymyPCT "`meas'earn5F" "L_" "_maleagerank`uup'`yr'" "year male agegp permrank`uup'"
			}	
				
			* Calculate "kurtosis" moments within permrank/agegp 
			if "`meas'" == "res"{	
				gen permrankaux = int(permrank/2.5)
				levelsof permrankaux, local(pgp) clean	
				levelsof agegp, local(agp) clean	
				foreach pp of local pgp{
					foreach aa of local agp {
						gen `meas'earn1Fp`pp'_`aa' = `meas'earn1F if permrankaux == `pp' & agegp == `aa'
						gen `meas'earn5Fp`pp'_`aa' = `meas'earn5F if permrankaux == `pp' & agegp == `aa' 
				
						kurpercentiles "`meas'earn1Fp`pp'_`aa'" "PK" "`yr'"
						kurpercentiles "`meas'earn5Fp`pp'_`aa'" "PK" "`yr'"
						drop `meas'earn1Fp`pp'_`aa' `meas'earn5Fp`pp'_`aa' n`meas'earn1Fp`pp'_`aa' n`meas'earn5Fp`pp'_`aa'
					}
				}
				drop permrankaux 		
			}
			drop permrank permrankT025 permrankT01			
			
			} 	// END loop over res and arc
			
	} // END if Per income is available	& END if 5-years available
} // END of loop over years

 
// Collect data across years  for the 1-year change measure
clear
foreach vari in researn1F logearn1F arcearn1F{

foreach yr of numlist $d1yrlist{
	local yrp = `yr' - 1

		*Stats 	
		use "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`yr'.dta", clear
		merge 1:1 year using "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_`yr'.dta", ///
			nogenerate
		erase "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_`yr'.dta"
		
		save "$maindir${sep}out${sep}$outfolder/L_`vari'_`yr'.dta", replace
				 
		if inlist(`yrp',${perm3yrlist}){
		if inlist(`yr',${d5yrlist}){
			
			
		*Stats per rank
		use "$maindir${sep}out${sep}$outfolder/S_L_`vari'_allrank`yr'.dta", clear
		merge 1:1 year permrank using "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_allrank`yr'.dta", ///
			nogenerate
		erase "$maindir${sep}out${sep}$outfolder/S_L_`vari'_allrank`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_allrank`yr'.dta"
		
		save "$maindir${sep}out${sep}$outfolder/L_`vari'_allrank`yr'.dta", replace
						
		*Stats per rank within age gp
		use "$maindir${sep}out${sep}$outfolder/S_L_`vari'_agerank`yr'.dta", clear
		merge 1:1 year age permrank using "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_agerank`yr'.dta", ///
			nogenerate
		erase "$maindir${sep}out${sep}$outfolder/S_L_`vari'_agerank`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_agerank`yr'.dta"
		
		save "$maindir${sep}out${sep}$outfolder/L_`vari'_agerank`yr'.dta", replace
		
		*Stats per rank within gender
		use "$maindir${sep}out${sep}$outfolder/S_L_`vari'_malerank`yr'.dta", clear
		merge 1:1 year male permrank using "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_malerank`yr'.dta", ///
			nogenerate
		erase "$maindir${sep}out${sep}$outfolder/S_L_`vari'_malerank`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_malerank`yr'.dta"
		
		save "$maindir${sep}out${sep}$outfolder/L_`vari'_malerank`yr'.dta", replace
		
		*Stats per rank within gender/age
		use "$maindir${sep}out${sep}$outfolder/S_L_`vari'_maleagerank`yr'.dta", clear
		merge 1:1 year agegp male permrank using "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_maleagerank`yr'.dta", ///
			nogenerate
		erase "$maindir${sep}out${sep}$outfolder/S_L_`vari'_maleagerank`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_maleagerank`yr'.dta"
		
		save "$maindir${sep}out${sep}$outfolder/L_`vari'_maleagerank`yr'.dta", replace
		
		*Extra top 		
			foreach tto in "all" "age" "male" "maleage"{
				
				local wmerge = ""
				if "`tto'" == "age"{
					local wmerge = "agegp"
				}
				else if "`tto'" == "male"{
					local wmerge = "male"
				}
				else if "`tto'" == "maleage"{
					local wmerge = "male agegp"
				}
				
			foreach uup in T025 T01{
			use "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`tto'rank`uup'`yr'.dta", clear
			merge 1:1 year `wmerge' permrank`uup' using "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_`tto'rank`uup'`yr'.dta", ///
				nogenerate
			erase "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`tto'rank`uup'`yr'.dta"
			erase "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_`tto'rank`uup'`yr'.dta"
		
			save "$maindir${sep}out${sep}$outfolder/L_`vari'_`tto'rank`uup'`yr'.dta", replace
			}
			}
				
		}
		}
	
	***
}

// if inlist("`vari'","researn1F","arcearn1F"){
	
	clear 
	foreach yr of numlist $d1yrlist{
		append using "$maindir${sep}out${sep}$outfolder/L_`vari'_`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/L_`vari'_`yr'.dta"	
	}
	outsheet using "$maindir${sep}out${sep}$outfolder/L_`vari'_sumstat.csv", replace comma
		
// }
// else{	
	clear
	foreach yr of numlist $d5yrlist{
		local yrp = `yr' - 1
		if inlist(`yrp',${perm3yrlist}){
		append using "$maindir${sep}out${sep}$outfolder/L_`vari'_allrank`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/L_`vari'_allrank`yr'.dta"
		}
	}
	outsheet using "$maindir${sep}out${sep}$outfolder/L_`vari'_allrank.csv", replace comma

	
	clear
	foreach yr of numlist $d5yrlist{
		local yrp = `yr' - 1
		if inlist(`yrp',${perm3yrlist}){
		append using "$maindir${sep}out${sep}$outfolder/L_`vari'_agerank`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/L_`vari'_agerank`yr'.dta"
		}
	}
	outsheet using "$maindir${sep}out${sep}$outfolder/L_`vari'_agerank.csv", replace comma
	
	
	clear
	foreach yr of numlist $d5yrlist{
		local yrp = `yr' - 1
		if inlist(`yrp',${perm3yrlist}){
		append using "$maindir${sep}out${sep}$outfolder/L_`vari'_malerank`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/L_`vari'_malerank`yr'.dta"
		}
	}
	outsheet using "$maindir${sep}out${sep}$outfolder/L_`vari'_malerank.csv", replace comma

	
	clear
	foreach yr of numlist $d5yrlist{
		local yrp = `yr' - 1
		if inlist(`yrp',${perm3yrlist}){
		append using "$maindir${sep}out${sep}$outfolder/L_`vari'_maleagerank`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/L_`vari'_maleagerank`yr'.dta"
		}
	}
	outsheet using "$maindir${sep}out${sep}$outfolder/L_`vari'_maleagerank.csv", replace comma
	
	
	clear	
	foreach tto in "all" "age" "male" "maleage"{
	foreach uup in T025 T01{
		
		clear 
		foreach yr of numlist $d5yrlist{
		local yrp = `yr' - 1
		if inlist(`yrp',${perm3yrlist}){
		
		append using "$maindir${sep}out${sep}$outfolder/L_`vari'_`tto'rank`uup'`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/L_`vari'_`tto'rank`uup'`yr'.dta"
		
		}
		}
		outsheet using "$maindir${sep}out${sep}$outfolder/L_`vari'_`tto'rank`uup'.csv", replace comma
		
	}
	}
	
		
// }	// END if statement

// Collect data across all years and heterogeneity groups. saves one database per group 
// if inlist("`vari'","researn1F","arcearn1F"){
	foreach  vv in $hetgroup{

		clear 
		local suf=subinstr("`vv'"," ","",.)
		foreach yr of numlist $d1yrlist{
			
			use "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`suf'`yr'.dta", clear
			merge 1:1 year `vv' using "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_`suf'`yr'.dta", ///
				nogenerate	
				
			erase "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`suf'`yr'.dta"
			erase "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_`suf'`yr'.dta"
			
			save "$maindir${sep}out${sep}$outfolder/L_`vari'_`suf'`yr'.dta", replace
		}	
		clear 
		foreach yr of numlist $d1yrlist{
			append using "$maindir${sep}out${sep}$outfolder/L_`vari'_`suf'`yr'.dta"
			erase "$maindir${sep}out${sep}$outfolder/L_`vari'_`suf'`yr'.dta"
		}
		
		outsheet using "$maindir${sep}out${sep}$outfolder/L_`vari'_`suf'_sumstat.csv", replace comma 		
	} 	// END loop over heterogeneity group
// }	// END if statement
}	// END loop over variables 


// Collect moments for the 5-years change measure
foreach vari in logearn5F researn5F arcearn5F{

foreach yr of numlist $d5yrlist{

	*Stats
	
		use "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`yr'.dta", clear
		merge 1:1 year using "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_`yr'.dta", ///
			nogenerate
		erase "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_`yr'.dta"
		save "$maindir${sep}out${sep}$outfolder/L_`vari'_`yr'.dta", replace

		local yrp = `yr' - 1
		if inlist(`yrp',${perm3yrlist}){
			*Stats per rank
			use "$maindir${sep}out${sep}$outfolder/S_L_`vari'_allrank`yr'.dta", clear
			merge 1:1 year permrank using "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_allrank`yr'.dta", ///
				nogenerate
			erase "$maindir${sep}out${sep}$outfolder/S_L_`vari'_allrank`yr'.dta"
			erase "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_allrank`yr'.dta"
			
			save "$maindir${sep}out${sep}$outfolder/L_`vari'_allrank`yr'.dta", replace
			
			*Stats per rank within age gp
			use "$maindir${sep}out${sep}$outfolder/S_L_`vari'_agerank`yr'.dta", clear
			merge 1:1 year agegp permrank using "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_agerank`yr'.dta", ///
				nogenerate
			erase "$maindir${sep}out${sep}$outfolder/S_L_`vari'_agerank`yr'.dta"
			erase "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_agerank`yr'.dta"
			
			save "$maindir${sep}out${sep}$outfolder/L_`vari'_agerank`yr'.dta", replace
			
			*Stats per rank within male
			use "$maindir${sep}out${sep}$outfolder/S_L_`vari'_malerank`yr'.dta", clear
			merge 1:1 year male permrank using "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_malerank`yr'.dta", ///
				nogenerate
			erase "$maindir${sep}out${sep}$outfolder/S_L_`vari'_malerank`yr'.dta"
			erase "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_malerank`yr'.dta"
			
			save "$maindir${sep}out${sep}$outfolder/L_`vari'_malerank`yr'.dta", replace
			
			*Stats per rank within gender/age
			use "$maindir${sep}out${sep}$outfolder/S_L_`vari'_maleagerank`yr'.dta", clear
			merge 1:1 year agegp male permrank using ///
			"$maindir${sep}out${sep}$outfolder/PC_L_`vari'_maleagerank`yr'.dta", ///
				nogenerate
			erase "$maindir${sep}out${sep}$outfolder/S_L_`vari'_maleagerank`yr'.dta"
			erase "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_maleagerank`yr'.dta"
			
			save "$maindir${sep}out${sep}$outfolder/L_`vari'_maleagerank`yr'.dta", replace
			
			*Extra top 		
			foreach tto in "all" "age" "male" "maleage"{
				
				local wmerge = ""
				if "`tto'" == "age"{
					local wmerge = "agegp"
				}
				else if "`tto'" == "male"{
					local wmerge = "male"
				}
				else if "`tto'" == "maleage"{
					local wmerge = "male agegp"
				}
				
			foreach uup in T025 T01{
			use "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`tto'rank`uup'`yr'.dta", clear
			merge 1:1 year `wmerge' permrank`uup' using "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_`tto'rank`uup'`yr'.dta", ///
				nogenerate
			erase "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`tto'rank`uup'`yr'.dta"
			erase "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_`tto'rank`uup'`yr'.dta"
		
			save "$maindir${sep}out${sep}$outfolder/L_`vari'_`tto'rank`uup'`yr'.dta", replace
			}
			}
					
		
		}
}

	*All stats
	clear 
	foreach yr of numlist $d5yrlist{
		append using "$maindir${sep}out${sep}$outfolder/L_`vari'_`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/L_`vari'_`yr'.dta"	
	}
	outsheet using "$maindir${sep}out${sep}$outfolder/L_`vari'_sumstat.csv", replace comma

	
		clear
		foreach yr of numlist $d5yrlist{
			local yrp = `yr' - 1
			if inlist(`yrp',${perm3yrlist}){
			append using "$maindir${sep}out${sep}$outfolder/L_`vari'_allrank`yr'.dta"
			erase "$maindir${sep}out${sep}$outfolder/L_`vari'_allrank`yr'.dta"
			}
		}
			outsheet using "$maindir${sep}out${sep}$outfolder/L_`vari'_allrank.csv", replace comma

		clear
		foreach yr of numlist $d5yrlist{
			local yrp = `yr' - 1
			if inlist(`yrp',${perm3yrlist}){
			append using "$maindir${sep}out${sep}$outfolder/L_`vari'_agerank`yr'.dta"
			erase "$maindir${sep}out${sep}$outfolder/L_`vari'_agerank`yr'.dta"
			}
		}
		outsheet using "$maindir${sep}out${sep}$outfolder/L_`vari'_agerank.csv", replace comma
		
		clear
		foreach yr of numlist $d5yrlist{
			local yrp = `yr' - 1
			if inlist(`yrp',${perm3yrlist}){
			append using "$maindir${sep}out${sep}$outfolder/L_`vari'_malerank`yr'.dta"
			erase "$maindir${sep}out${sep}$outfolder/L_`vari'_malerank`yr'.dta"
			}
		}
		outsheet using "$maindir${sep}out${sep}$outfolder/L_`vari'_malerank.csv", replace comma
		
	clear
	foreach yr of numlist $d5yrlist{
		local yrp = `yr' - 1
		if inlist(`yrp',${perm3yrlist}){
		append using "$maindir${sep}out${sep}$outfolder/L_`vari'_maleagerank`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/L_`vari'_maleagerank`yr'.dta"
		}
	}
	outsheet using "$maindir${sep}out${sep}$outfolder/L_`vari'_maleagerank.csv", replace comma
	
	clear	
	foreach tto in "all" "age" "male" "maleage"{
	foreach uup in T025 T01{
		
		clear 
		foreach yr of numlist $d5yrlist{
		local yrp = `yr' - 1
		if inlist(`yrp',${perm3yrlist}){
		
		append using "$maindir${sep}out${sep}$outfolder/L_`vari'_`tto'rank`uup'`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/L_`vari'_`tto'rank`uup'`yr'.dta"
		
		}
		}
		outsheet using "$maindir${sep}out${sep}$outfolder/L_`vari'_`tto'rank`uup'.csv", replace comma
		
	}
	}
	

// Collect data across all years and heterogeneity groups. saves one database per group 	
		foreach  vv in $hetgroup{

			clear 
			local suf=subinstr("`vv'"," ","",.)
			foreach yr of numlist $d5yrlist{
				
				use "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`suf'`yr'.dta", clear
				merge 1:1 year `vv' using "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_`suf'`yr'.dta", ///
					nogenerate	
					
				erase "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`suf'`yr'.dta"
				erase "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_`suf'`yr'.dta"
				
				save "$maindir${sep}out${sep}$outfolder/L_`vari'_`suf'`yr'.dta", replace
			}	
			clear 
			foreach yr of numlist $d5yrlist{
				append using "$maindir${sep}out${sep}$outfolder/L_`vari'_`suf'`yr'.dta"
				erase "$maindir${sep}out${sep}$outfolder/L_`vari'_`suf'`yr'.dta"
			}
			
			outsheet using "$maindir${sep}out${sep}$outfolder/L_`vari'_`suf'_sumstat.csv", replace comma 		
		} 	// END loop over heterogeneity group
}	// END loop over variables 

set more off
//Collect data for empirical density 
foreach k in 1 5{
	local i=1
	local j=1
	if `k' == 1{
		foreach yr of numlist $d1yrlist{
			
			if mod(`yr',${kyear}) == 0 {

				if(`i'==1){
				use "$maindir${sep}out${sep}$outfolder/L_researn`k'F_`yr'_hist.dta", clear
				erase "$maindir${sep}out${sep}$outfolder/L_researn`k'F_`yr'_hist.dta"
				}
				else{
				merge 1:1 index using "$maindir${sep}out${sep}$outfolder/L_researn`k'F_`yr'_hist.dta", nogen
				erase "$maindir${sep}out${sep}$outfolder/L_researn`k'F_`yr'_hist.dta"
				}
				local i=`i'+1
				
			}
		} 
		outsheet using "$maindir${sep}out${sep}$outfolder/L_researn`k'F_hist.csv", replace comma
		
		
		foreach yr of numlist $d1yrlist{
			if mod(`yr',${kyear}) == 0 {
				if(`j'==1){
				use "$maindir${sep}out${sep}$outfolder/L_researn`k'F_`yr'_hist_male.dta", clear
				erase "$maindir${sep}out${sep}$outfolder/L_researn`k'F_`yr'_hist_male.dta"
				}
				else{
				merge 1:1 index male using "$maindir${sep}out${sep}$outfolder/L_researn`k'F_`yr'_hist_male.dta", nogen
				erase "$maindir${sep}out${sep}$outfolder/L_researn`k'F_`yr'_hist_male.dta"
				}
				local j=`j'+1
			}
		} 
		outsheet using "$maindir${sep}out${sep}$outfolder/L_researn`k'F_hist_male.csv", replace comma
		
		
	}
	else{
		foreach yr of numlist $d5yrlist{
			if mod(`yr',${kyear}) == 0 {
				if(`i'==1){
				use "$maindir${sep}out${sep}$outfolder/L_researn`k'F_`yr'_hist.dta", clear
				erase "$maindir${sep}out${sep}$outfolder/L_researn`k'F_`yr'_hist.dta"
				}
				else{
				merge 1:1 index using "$maindir${sep}out${sep}$outfolder/L_researn`k'F_`yr'_hist.dta", nogen
				erase "$maindir${sep}out${sep}$outfolder/L_researn`k'F_`yr'_hist.dta"
				}
				local i=`i'+1
			}
		} 
		outsheet using "$maindir${sep}out${sep}$outfolder/L_researn`k'F_hist.csv", replace comma
		
		
		foreach yr of numlist $d5yrlist{
			if mod(`yr',${kyear}) == 0 {
				if(`j'==1){
				use "$maindir${sep}out${sep}$outfolder/L_researn`k'F_`yr'_hist_male.dta", clear
				erase "$maindir${sep}out${sep}$outfolder/L_researn`k'F_`yr'_hist_male.dta"
				}
				else{
				merge 1:1 index male using "$maindir${sep}out${sep}$outfolder/L_researn`k'F_`yr'_hist_male.dta", nogen
				erase "$maindir${sep}out${sep}$outfolder/L_researn`k'F_`yr'_hist_male.dta"
				}
				local j=`j'+1
			}
		} 
		outsheet using "$maindir${sep}out${sep}$outfolder/L_researn`k'F_hist_male.csv", replace comma
	}
}

// Collects data from koncentration measure
	// One year measures
	clear 
	foreach yr of numlist $d1yrlist{
		append using "$maindir${sep}out${sep}$outfolder/PK_researn1F_`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/PK_researn1F_`yr'.dta"
	}
		outsheet using "$maindir${sep}out${sep}$outfolder/PK_researn1F.csv", replace comma
	clear 	
	foreach yr of numlist $d1yrlist{
		foreach aa in 1 2 3{
			append using "$maindir${sep}out${sep}$outfolder/PKage_researn1F`aa'_`yr'.dta"
			erase "$maindir${sep}out${sep}$outfolder/PKage_researn1F`aa'_`yr'.dta"
			cap: gen agegp = `aa'
			cap: replace agegp = `aa' if agegp == .
		}
	}	
		order year agegp
		sort year agegp
		outsheet using "$maindir${sep}out${sep}$outfolder/PK_researn1F_age.csv", replace comma
		
	clear 	
	foreach yr of numlist $d1yrlist{
		local yrp = `yr' - 1
		if inlist(`yrp',${perm3yrlist}){
			if inlist(`yr',${d5yrlist}){
			forvalues pp = 1/40{
				append using "$maindir${sep}out${sep}$outfolder/PK_researn1Fp`pp'_`yr'.dta"
				erase "$maindir${sep}out${sep}$outfolder/PK_researn1Fp`pp'_`yr'.dta"
				cap: gen permrank = `pp'
				cap: replace permrank = `pp' if permrank == . 
			}	
				
			}	// IF perminc is possible
		}	// IF 5 years possible
	}	// END loop over years
	order year permrank
	sort year permrank
	outsheet using "$maindir${sep}out${sep}$outfolder/PK_researn1F_permrank.csv", replace comma
	
	clear 	
	foreach yr of numlist $d1yrlist{
		local yrp = `yr' - 1
		if inlist(`yrp',${perm3yrlist}){
			if inlist(`yr',${d5yrlist}){
			forvalues pp = 1/40{
				foreach aa in 1 2 3{
				append using "$maindir${sep}out${sep}$outfolder/PK_researn1Fp`pp'_`aa'_`yr'.dta"
				erase "$maindir${sep}out${sep}$outfolder/PK_researn1Fp`pp'_`aa'_`yr'.dta"
				cap: gen permrank = `pp'
				cap: replace permrank = `pp' if permrank == . 
				cap: gen agegp = `aa'
				cap: replace agegp = `aa' if agegp == .
				}
				}
			}	// IF perminc is possible
		}	// IF 5 years possible
	}	// END loop over years
	order year permrank agegp
	sort year permrank agegp
	outsheet using "$maindir${sep}out${sep}$outfolder/PK_researn1F_permrank_age.csv", replace comma
	
	
	// Five year changes	
	clear 
	foreach yr of numlist $d5yrlist{
		append using "$maindir${sep}out${sep}$outfolder/PK_researn5F_`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/PK_researn5F_`yr'.dta"
	}
		outsheet using "$maindir${sep}out${sep}$outfolder/PK_researn5F.csv", replace comma
		
	clear 	
	foreach yr of numlist $d5yrlist{
		foreach aa in 1 2 3{
			append using "$maindir${sep}out${sep}$outfolder/PKage_researn5F`aa'_`yr'.dta"
			erase "$maindir${sep}out${sep}$outfolder/PKage_researn5F`aa'_`yr'.dta"
			cap: gen agegp = `aa'
			cap: replace agegp = `aa' if agegp == .
		}
	}		
	
	order year agegp
	sort year agegp
	outsheet using "$maindir${sep}out${sep}$outfolder/PK_researn5F_age.csv", replace comma
	
	clear 	
	foreach yr of numlist $d1yrlist{
		local yrp = `yr' - 1
		if inlist(`yrp',${perm3yrlist}){
			if inlist(`yr',${d5yrlist}){
			forvalues pp = 1/40{
				cap: append using "$maindir${sep}out${sep}$outfolder/PK_researn5Fp`pp'_`yr'.dta"
				erase "$maindir${sep}out${sep}$outfolder/PK_researn5Fp`pp'_`yr'.dta"
				cap: gen permrank = `pp'
				cap: replace permrank = `pp' if permrank == . 
			}
			}	// IF perminc is possible
		}	// IF 5 years possible
	}	// END loop over years
	order year permrank
	sort year permrank
	outsheet using "$maindir${sep}out${sep}$outfolder/PK_researn5F_permrank.csv", replace comma
	
	clear 	
	foreach yr of numlist $d1yrlist{
		local yrp = `yr' - 1
		if inlist(`yrp',${perm3yrlist}){
			if inlist(`yr',${d5yrlist}){
			forvalues pp = 1/40{
				foreach aa in 1 2 3{
				append using "$maindir${sep}out${sep}$outfolder/PK_researn5Fp`pp'_`aa'_`yr'.dta"
				erase "$maindir${sep}out${sep}$outfolder/PK_researn5Fp`pp'_`aa'_`yr'.dta"
				cap: gen permrank = `pp'
				cap: replace permrank = `pp' if permrank == . 
				cap: gen agegp = `aa'
				cap: replace agegp = `aa' if agegp == .
				}
				}
			}	// IF perminc is possible
		}	// IF 5 years possible
	}	// END loop over years
	order year permrank agegp
	sort year permrank agegp
	outsheet using "$maindir${sep}out${sep}$outfolder/PK_researn5F_permrank_age.csv", replace comma
	
timer off 1
timer list 1

*END OF THE CODE 
