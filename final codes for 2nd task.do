*First we import all the choosen CSV files into stata and save them in stat .dta format.
import delimited "C:\Users\Shruti Singh\Desktop\shrusti\csv files\Visit1  Level - 01 (Blocks 1 and 2) - Identification of sample household and  particulars of field operations.csv"
save "C:\Users\Shruti Singh\Desktop\shrusti\stata for t2\Visit level 1.dta"
clear
import delimited "C:\Users\Shruti Singh\Desktop\shrusti\csv files\Visit1  Level - 02 (Block 3) - Demographic and other particulars of household members.csv"
save "C:\Users\Shruti Singh\Desktop\shrusti\stata for t2\Visit 1 level 2.dta"
clear
import delimited "C:\Users\Shruti Singh\Desktop\shrusti\csv files\Visit1  Level - 12 (Block 11a) - Financial assets including receivables (other than shares and related instruments) owned by the household..csv"
save "C:\Users\Shruti Singh\Desktop\shrusti\stata for t2\Visit 1 level 12(block 11a).dta"
clear
import delimited "C:\Users\Shruti Singh\Desktop\shrusti\csv files\Visit1  Level - 14 (Block 12) - particulars of cash loans payable by the household to institutional, non-institutional agencies as on the date of survey and transactions of loans.csv"
save "C:\Users\Shruti Singh\Desktop\shrusti\stata for t2\visit 1 level 14.dta"
clear



*Open Demographic file (2.dta)
use "C:\Users\Shruti Singh\Desktop\shrusti\stata for t2\2.dta", clear

* Keep only household heads
keep if b3q3 == 1

* Keep necessary variables
keep hhid b3q5 b3q6 sector b3q3

* Rename for clarity
rename b3q5 age_hhhead
rename b3q6 education_hhhead

* Save collapsed file
save "C:\Users\Shruti Singh\Desktop\shrusti\stata for t2\2_headonly.dta", replace

. clear

. use "C:\Users\Shruti Singh\Desktop\shrusti\stata for t2\12.dta"

br b11aq1


* Keep relevant variables  from level 12 data
keep hhid  b11aq1

* Save
save "C:\Users\Shruti Singh\Desktop\shrusti\stata for t2\12_pensionscheme.dta", replace


* First create a binary variable for retirement scheme participation
gen retirement_participation = 0

replace retirement_participation = 1 if inlist( b11aq1, 10, 11)

tabulate retirement_participation  b11aq1
br retirement_participation  b11aq1

collapse (max) retirement_participation, by(hhid)

save "C:\Users\Shruti Singh\Desktop\shrusti\stata for t2\12_pensionscheme_clean.dta", replace


// now collapse level 14 data as per requirement 
// 1. Keep only loans taken for 'Other household expenditure'
keep if b12q10 == 12

// 2. Keep only variables you need (optional: to make dataset clean)
keep hhid b12q4 b12q14

// 3. If household has multiple such loans, sum the amounts
collapse (sum) b12q4 b12q14, by(hhid)

// 4. Rename variables for clarity (optional)
rename b12q4 total_borrowed_otherexp
rename b12q14 total_outstanding_otherexp

// Now each HHID has total borrowed and total outstanding amounts 
// for Other Household Expenditure loans only

//check for duplicates
duplicates report hhid

//save now file 
save "C:\Users\Shruti Singh\Desktop\shrusti\stata for t2\14 new for merging.dta", replace


// use the level 1 file and merge it with level 2 file that we have collapsed
. use "C:\Users\Shruti Singh\Desktop\shrusti\stata for t2\1.dta"

. merge 1:1 hhid using "C:\Users\Shruti Singh\Desktop\shrusti\stata for t2\2_headonly.dta"
. drop _merge

// now merge it with the new collapsed pension scheme file
 merge 1:1 hhid using "C:\Users\Shruti Singh\Desktop\shrusti\stata for t2\12_pensionscheme_clean.dta"

 drop _merge
 
 //now merge the new loan file too
  merge 1:1 hhid using "C:\Users\Shruti Singh\Desktop\shrusti\stata for t2\14 new for merging.dta"
  
  
. save, replace





* Create binary urban_rural variable
gen urban_rural = .
replace urban_rural = 1 if sector == 2
replace urban_rural = 0 if sector == 1

tabulate sector urban_rural


* Create categorical education variable
gen education_cat = .

* 0 = Illiterate
replace education_cat = 0 if education_hhhead == 1

* 1 = Primary (below primary, primary, upper primary/middle)
replace education_cat = 1 if inlist(education_hhhead, 2, 3, 4)

* 2 = Secondary (secondary, higher secondary, diploma up to higher secondary)
replace education_cat = 2 if inlist(education_hhhead, 5, 6, 7, 8)

* 3 = Graduate+ (diploma above graduation, graduate, postgraduate)
replace education_cat = 3 if inlist(education_hhhead, 10, 11, 12)

tabulate education_hhhead education_cat

gen log_total_outstanding_otherexp = .
replace log_total_outstanding_otherexp = log(total_outstanding_otherexp) if total_outstanding_otherexp > 0

*once u save the data up until here, u can direcly run reg 

* Run the logistic regression
logit retirement_participation log_total_outstanding_otherexp i.education_cat age_hhhead i.urban_rural


* Optionally: get odds ratios for easier interpretation
logit retirement_participation log_total_outstanding_otherexp i.education_cat age_hhhead i.urban_rural, or

logit retirement_participation c.log_total_outstanding_otherexp##i.urban_rural ///
      i.education_cat age_hhhead, vce(robust)

logit retirement_participation c.log_total_outstanding_otherexp##c.age_hhhead ///
      i.education_cat i.urban_rural, vce(robust)

gen treat = (log_total_outstanding_otherexp <= 10)  // define treatment at cutoff
ssc install rdrobust, replace

rdrobust retirement_participation log_total_outstanding_otherexp, c(10)
	  
gen treat1 = (log_total_outstanding_otherexp <= 9)  // define treatment at cutoff

rdrobust retirement_participation log_total_outstanding_otherexp, c(9)

gen treat2 = (log_total_outstanding_otherexp <= 11)  // define treatment at cutoff

rdrobust retirement_participation log_total_outstanding_otherexp, c(11)
	  
// Margins for education
margins education_cat

// Plot margins
marginsplot, ///
    title("Effect of Education Level on Retirement Participation") ///
    ytitle("Predicted Probability") ///
    xlabel(0 "Illiterate" 1 "Primary" 2 "Secondary" 3 "Graduate+") ///
    plotopts(lcolor(blue)) ///
    ciopts(lcolor(blue%50)) ///
    legend(off)
	


// Margins across a range of age
margins, at(age_hhhead=(15(5)80))

// Plot margins
marginsplot, ///
    title("Effect of Age on Retirement Participation") ///
    xlabel(15(5)80) ///
    ytitle("Predicted Probability") ///
    plotopts(lcolor(green)) ///
    ciopts(lcolor(green%50)) ///
    legend(off)


// Margins for urban/rural
margins urban_rural


// Plot margins

marginsplot, ///
    title("Urban vs Rural: Retirement Participation") ///
    ytitle("Predicted Probability") ///
    xlabel(0 "Rural" 1 "Urban") ///
    plotopts(lcolor(red)) ///
    ciopts(lcolor(red%50)) ///
    legend(off) 
	
// extra graphs 

label define educlb 0 "Illiterate" 1 "Primary" 2 "Secondary" 3 "Graduate+"
label values education_cat educlb

graph bar (count), ///
    over(education_cat, label(labsize(medium))) ///
    bar(1, color(blue)) ///
    blabel(bar, size(small)) ///
    title("Education Level of Household Head") ///
    ytitle("Number of Households")
	
graph bar (count), ///
    over(education_cat, label(labsize(medium))) ///
    bar(1, color(blue)) ///
    title("Education Level of Household Head") ///
    ytitle("Number of Households")
	
	
	histogram age_hhhead, ///
    bin(20) ///
    color(orange) ///
    title("Distribution of Household Head Age") ///
    ytitle("Number of Households") ///
    xtitle("Age")
	
	graph bar (count), over(urban_rural, label(labsize(medium))) ///
    bar(1, color(green)) ///
    title("Urban vs Rural Households") ///
    ytitle("Number of Households") ///

   

ssc install grstyle, replace
ssc install palettes, replace
ssc install colrspace, replace

 * Define labels
label define partlb2 0 "Not Participate" 1 "Participate"
label values retirement_participation partlb2

* Initialize grstyle
grstyle init

* Set custom colors for the pie chart slices
grstyle set color #ff0000 #00ff00


* Redraw the pie chart with the new colors
graph pie, over(retirement_participation) ///
    plabel(_all percent, size(medium)) ///
    title("Retirement Scheme Participation")
	
	
// Histogram for log-transformed consumer debt
histogram log_total_outstanding_otherexp, normal ///
    title("Distribution of Log-Transformed Consumer Debt") ///
    xlabel(, grid) ///
    ylabel(, grid)
	
