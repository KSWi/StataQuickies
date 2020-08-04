

version 16
clear all
capture cd "$GoogleDriveWork"
capture cd "$GoogleDriveLaptop"
capture cd "$LinuxDriveWork"
capture cd "$Presentations"
cd ".\Talks\AllTalks\25_IntroToProgramming\examples\"

global Width16x9 = 1920*2
global Height16x9 = 1080*2
global Width4x3 = 1440*2
global Height4x3 = 1080*2

use nhanes


// Super Simple Program
// =============================================================================
capture program drop hello
program hello
	display "Hello world, why so blue?"
end
hello

capture program drop hello
program hello
	display "Hello world."
	display "Why so blue?"
end

hello



// version
capture program drop hello
program hello
	version 16
	display "Hello world."
	display "Why so blue?"
end

hello


// args
capture program drop hello
program hello
	version 16
	args fname lname
	display "Hello `fname' `lname'."
end

hello Chuck Huber


// Calculate BMI using simple arguments
// =============================================================================

// Calculate BMI: Display something
capture program drop calcbmi
program calcbmi
    display "BMI = ?"
end

calcbmi

// Calculate BMI: Add the version
capture program drop calcbmi
program calcbmi
	version 16
    display "BMI = ?"
end

calcbmi


// Calculate BMI: Pass arguments into the program with -args-
capture program drop calcbmi
program calcbmi
	version 16
	args height weight
    display "BMI = ?"
end

calcbmi 68 180

// Calculate BMI: Display the local macros `height' and `weight'
capture program drop calcbmi
program calcbmi
	version 16
	args height weight
    display "Height = " `height'
    display "Weight = " `weight'
end

calcbmi 68 180

// Calculate BMI: Calculate BMI using scalars
capture program drop calcbmi
program calcbmi
	version 16
	args height weight
    // Convert height from inches to meters
    scalar height_m = `height'*0.0254
    // Convert weight from pounds to kilograms
    scalar weight_kg = `weight'*0.453592
    // Calculate BMI
    scalar bmi = weight_kg / height_m^2
    display "BMI = " bmi
end

calcbmi 68 180


// Calculate BMI: Return results with -rclass- and -return scalar-
capture program drop calcbmi
program calcbmi, rclass
	version 16
	args height weight

    scalar height_m = `height'*0.0254
    scalar weight_kg = `weight'*0.453592
    scalar bmi = weight_kg / height_m^2

    display "BMI = " bmi
    return scalar bmi = bmi
end

calcbmi 68 180
return list


// Calculate BMI using variables
// =============================================================================
// Calculate BMI: Pass arguments into the program with -syntax-
capture program drop genbmi
program genbmi
	version 16
	syntax varlist
    display "varlist = `varlist'"
end

genbmi height weight


// Calculate BMI: Require two numeric variables
capture program drop genbmi
program genbmi
	version 16
	syntax varlist(min=2 max=2 numeric)
    display "varlist = `varlist'"
end

genbmi height weight


// Calculate BMI: Refer to the two variables separately
capture program drop genbmi
program genbmi
	version 16
	syntax varlist(min=2 max=2 numeric)
    tokenize `varlist'
    display "variable 1 = `1'"
    display "variable 2 = `2'"
end

genbmi height weight


// Calculate BMI: Refer to the two variables as local macros
capture program drop genbmi
program genbmi
	version 16
	syntax varlist(min=2 max=2 numeric)
    tokenize `varlist'
    local height = `1'
    local weight = `2'
end

genbmi height weight


// Calculate BMI: Generate a new variable for BMI
capture drop bmi_new
capture program drop genbmi
program genbmi
	version 16
	syntax varlist(min=2 max=2 numeric)
    tokenize `varlist'
    local height = "`1'"
    local weight = "`2'"
    generate bmi_new = `weight' / (`height'/100)^2
end

genbmi height weight
describe bmi_new
summarize bmi_new

// Calculate BMI: Allow the user to specify the new variable name
capture drop bmi_user
capture program drop genbmi
program genbmi
	version 16
	syntax varlist(min=2 max=2 numeric), GENerate(string)
    tokenize `varlist'
    local height = "`1'"
    local weight = "`2'"
    generate `generate' = `weight' / (`height'/100)^2
end

genbmi height weight, gen(bmi_user)
describe bmi_user
summarize bmi_user


// Calculate BMI: Make "GENerate(string)" optional
capture drop bmi_new
capture drop bmi_user
capture drop bmi_default
capture program drop genbmi
program genbmi
	version 16
	syntax varlist(min=2 max=2 numeric) [, GENerate(string)]
    tokenize `varlist'
    local height = `1'
    local weight = `2'
    if "`generate'" != "" {
        generate `generate' = `height' / (`weight'/100)^2
    }
    else {
        generate bmi_default = `height' / (`weight'/100)^2
    }
end

genbmi height weight
genbmi height weight, gen(bmi_user)
describe  bmi_default bmi_user
describe height weight bmi_user



// Calculate standardized (centered-and-scaled) variables
// =============================================================================
summarize age
return list

// Use -foreach- to loop over the variable list
capture drop std*
capture program drop stdize
program stdize
	version 16
	syntax varlist(numeric)
    foreach var in `varlist' {
        display "var = `var'"
    }
end

stdize sbp age bmi


// Use -foreach- to loop over the variable list and generate new variables
capture drop std*
capture drop z_age

summarize age
generate z_age = (age - 31.9) / 24.8

summarize age
return list
display "The mean = " r(mean)
display "The sd =   " r(sd)

drop z_age
summarize age

generate z_age = (age - r(mean)) / r(sd)

summarize z_age




capture drop std*
capture program drop stdize
program stdize
	version 16
	syntax varlist(numeric)
    foreach var in `varlist' {
        quietly summarize `var'
        quietly generate std_`var' = (`var' - r(mean)) / r(sd)
    }
end

stdize sbp age bmi
summ std_sbp std_age std_bmi 

graph hbox std_sbp std_age std_bmi,                        ///
      title("Boxplots for Standardized SBP, Age, and BMI") ///
      legend(rows(1) position(12))
graph export ./graphs/boxplots.png   ///
             , as(png) replace width($Width16x9) height($Height16x9)







// How to create a custom summary command
// =============================================================================

tabstat sbp age bmi,                                               ///
        statistics(count mean median sd skewness kurtosis min max) ///
        columns(statistics)
pwcorr sbp age bmi


capture program drop mysumm
program mysumm
	version 16
	syntax varlist(min=1 numeric) 
	tabstat `varlist',                              ///
	        statistics(count mean median sd         /// 
                       skewness kurtosis min max)   ///
			columns(statistics)
    pwcorr `varlist'
end

mysumm sbp age bmi


// add [if], [in], and -marksample touse-
capture program drop mysumm
program mysumm
	version 16
	syntax varlist(min=1 numeric) [if] [in] 
	marksample touse
	tabstat `varlist' if `touse',                   ///
	        statistics(count mean median sd         ///
                       skewness kurtosis min max )  ///
			columns(statistics)
    pwcorr `varlist' if `touse' 
end
mysumm sbp age bmi if female==1
mysumm sbp age bmi in 1/50


// add -byable(recall) sortpreserve-  (note that byable works with -marksample-)
capture program drop mysumm
program mysumm, byable(recall) sortpreserve
	version 16
	syntax varlist(min=1 numeric) [if] [in] 
	marksample touse
	tabstat `varlist' if `touse',                   ///
	        statistics(count mean median sd         ///
                       skewness kurtosis min max )  ///
			columns(statistics)
    pwcorr `varlist' if `touse'        
end
mysumm sbp age bmi
bysort female: mysumm sbp age bmi





// SIMPLE GRAPHICS WRAPPER COMMANDS
// ===========================================================================
use nhanes, clear

/*
capture program drop ciplot
program ciplot
	version 16
	syntax varlist(min=1 max=1 numeric), BY(varname min=1 numeric) *
    quietly regress `varlist' i.`by', vce(robust)
    margins `by'
    quietly marginsplot, xdimension(healthstat) recast(scatter)            ///
             ytitle("`varlist'") ylabel(, angle(horizontal))               /// 
             title("Means and Confidence Intervals for `varlist' by `by'")
end 

ciplot age, by(healthstat)

graph export ./graphs/ciplot.png   ///
             , as(png) replace width($Width16x9) height($Height16x9)
*/




// SIMPLE GRAPHICS WRAPPER COMMANDS
// ===========================================================================

use nhanes, clear
ci means age
return list
statsby mean=r(mean) lb=r(lb) ub=r(ub),            ///
        by(healthstat) nodots clear: ci means age
list
format %9.1f mean lb ub
list

// Create the labelled scatterplot
twoway (scatter mean healthstat, mcolor(blue) mlabel(mean))
graph export ./graphs/ciplot1.png   ///
             , as(png) replace width($Width16x9) height($Height16x9) 

// Add the confidence intervals
twoway (scatter mean healthstat, mcolor(blue) mlabel(mean))  ///
	   (rcap lb ub healthstat, lcolor(blue))
graph export ./graphs/ciplot2.png   ///
             , as(png) replace width($Width16x9) height($Height16x9)             

// Label the horizontal axis             
twoway (scatter mean healthstat, mcolor(blue) mlabel(mean))  ///
	   (rcap lb ub healthstat, lcolor(blue)),                ///
       xlabel(, valuelabel)  
graph export ./graphs/ciplot3.png   ///
             , as(png) replace width($Width16x9) height($Height16x9)

// Turn off the legend             
twoway (scatter mean healthstat, mcolor(blue) mlabel(mean))  ///
	   (rcap lb ub healthstat, lcolor(blue)),                ///
       xlabel(, valuelabel) legend(off) 
graph export ./graphs/ciplot4.png   ///
             , as(png) replace width($Width16x9) height($Height16x9)      

// Make the y-labels horizontal             
twoway (scatter mean healthstat, mcolor(blue) mlabel(mean))  ///
	   (rcap lb ub healthstat, lcolor(blue)),                ///
       xlabel(, valuelabel) legend(off)                      ///
       ylabel(, angle(horizontal))       
graph export ./graphs/ciplot5.png   ///
             , as(png) replace width($Width16x9) height($Height16x9)             
       
// Make the y-labels horizontal 
twoway (scatter mean healthstat, mcolor(blue) mlabel(mean))  ///
	   (rcap lb ub healthstat, lcolor(blue)),                ///
       xlabel(, valuelabel) legend(off)                      ///
       ylabel(, angle(horizontal))                           ///
       plotregion(margin(l=10 r=10))
graph export ./graphs/ciplot6.png   ///
             , as(png) replace width($Width16x9) height($Height16x9)     
    

    
// BASIC
use nhanes, clear
capture program drop ciplot
program ciplot
	version 16
	syntax varlist(min=1 max=1 numeric), BY(varname min=1 numeric)
    display "varlist = `varlist'"
    display "by = `by'"
end     

ciplot age, by(healthstat)   



// BASIC
use nhanes, clear
capture program drop ciplot
program ciplot
	version 16
	syntax varlist(min=1 max=1 numeric), BY(varname min=1 numeric) 
    statsby mean=r(mean) lb=r(lb) ub=r(ub),            ///
            by(`by') nodots clear: ci means `varlist'
end        

ciplot age, by(healthstat)
list
      

 // BASIC
use nhanes, clear
capture program drop ciplot
program ciplot
	version 16
	syntax varlist(min=1 max=1 numeric), BY(varname min=1 numeric) 
    statsby mean=r(mean) lb=r(lb) ub=r(ub),            ///
            by(`by') nodots clear: ci means `varlist'
    format %9.1f mean lb ub 
end        

ciplot age, by(healthstat)
list     
      
      
     
      
      
use nhanes, clear
capture program drop ciplot
program ciplot
	version 16
	syntax varlist(min=1 max=1 numeric), BY(varname min=1 numeric)
    preserve
    statsby mean=r(mean) lb=r(lb) ub=r(ub),            ///
            by(`by') nodots clear: ci means `varlist'
    format %9.1f mean lb ub
end        

ciplot age, by(healthstat)
list age healthstat in 1/5
      

      
use nhanes, clear
capture program drop ciplot
program ciplot
	version 16
	syntax varlist(min=1 max=1 numeric), BY(varname min=1 numeric)
    preserve
    statsby mean=r(mean) lb=r(lb) ub=r(ub),            ///
            by(`by') nodots clear: ci means `varlist'
    format %9.1f mean lb ub        
            
    twoway (scatter mean `by', mcolor(blue) mlabel(mean))  ///
           (rcap lb ub   `by', lcolor(blue)),              ///
           xlabel(, valuelabel) legend(off)                ///
           ylabel(, angle(horizontal))                     ///
           plotregion(margin(l=10 r=10))        
end        

ciplot age, by(healthstat)
     
graph export ./graphs/ciplot7.png   ///
             , as(png) replace width($Width16x9) height($Height16x9) 
             
       
use nhanes, clear
capture program drop ciplot
program ciplot
	version 16
	syntax varlist(min=1 max=1 numeric), BY(varname min=1 numeric) *
    preserve
    statsby mean=r(mean) lb=r(lb) ub=r(ub),                ///
            by(`by') nodots clear: ci means `varlist'
    format %9.1f mean lb ub        
            
    twoway (scatter mean `by', mcolor(blue) mlabel(mean))  ///
           (rcap lb ub   `by', lcolor(blue)),              ///
           xlabel(, valuelabel) legend(off)                ///
           ylabel(, angle(horizontal))                     ///
           plotregion(margin(l=10 r=10)) `options'        
end        

ciplot age, by(healthstat)            ///
       ytitle("Age (years)")          ///
       title("Age by Health Status")
graph export ./graphs/ciplot8.png   ///
             , as(png) replace width($Width16x9) height($Height16x9) 
             
      
use nhanes, clear
capture program drop ciplot
program ciplot
	version 16
	syntax varlist(min=1 max=1 numeric), BY(varname min=1 numeric) *
    quietly {
    preserve
    statsby mean=r(mean) lb=r(lb) ub=r(ub),                ///
            by(`by') nodots clear: ci means `varlist'
    format %9.1f mean lb ub        
  
    twoway (scatter mean `by', mcolor(blue) mlabel(mean))  ///
           (rcap lb ub   `by', lcolor(blue)),              ///
           xlabel(, valuelabel) legend(off)                ///
           ylabel(, angle(horizontal))                     ///
           plotregion(margin(l=10 r=10)) `options'
    }
end         

ciplot age, by(healthstat)            ///
       ytitle("Age (years)")          ///
       title("Age by Health Status")   
       
       

             
// SIMPLE POSTESTIMATION COMMAND
// ===========================================================================
use nhanes, clear
quietly logistic diabetes age bmi
ereturn list

quietly logistic diabetes age bmi
scalar mcfadden = 1-(e(ll)/e(ll_0))
scalar coxsnell = 1 - exp(2*(e(ll_0) - e(ll))/e(N))
display "McFadden's pseudo r-squared  = " mcfadden
display "Cox-Snell pseudo r-squared   = " coxsnell

capture program drop pseudor2             
program pseudor2
    version 16
    scalar mcfadden = 1-(e(ll)/e(ll_0))
    scalar coxsnell = 1 - exp(2*(e(ll_0) - e(ll))/e(N))
    display "McFadden's pseudo r-squared  = " mcfadden
    display "Cox-Snell pseudo r-squared   = " coxsnell
end    

logistic diabetes age bmi
pseudor2





capture program drop pseudor2             
program pseudor2
    version 16
    if "`e(cmd)'" == "logistic" {
        scalar mcfadden = 1-(e(ll)/e(ll_0))
        scalar coxsnell = 1 - exp(2*(e(ll_0) - e(ll))/e(N))
        display "McFadden's pseudo r-squared  = " mcfadden
        display "Cox-Snell pseudo r-squared   = " coxsnell
    }
    else {
     display as error "The preceding command must be -logistic-"
    }
end    

logistic diabetes age bmi
pseudor2








// How To Store Thing In Memory
// =============================================================================

// Scalars
scalar i = 1
display "i = ", i
display "i = ", scalar(i)

// Local macros
local i = 1
display "i = `i'"

local animal = "dog"
display "animal = `animal'"

// Global macros
global i = 1
display "i = $i"

global animal = "dog"
display "animal = $animal"

// Matrices
use nhanes, clear
drop if missing(sbp, age, female)
list sbp in 1/4
mkmat sbp, matrix(y)
matlist y[1..4,.]
matlist y
list age female in 1/4
mkmat age female, matrix(X)
matlist X[1..4,.]
matlist X
matrix bhat = invsym(X'*X)*X'*y
matlist bhat
regress sbp age female, nocons



// Things That Stata Stores In Memory
// =============================================================================

// _n, _N
display "The number of observations in our dataset = ", _N
display "The current observation = ", _n


// c()
creturn list
display "Today's date is `c(current_date)'"
display "Today's time is `c(current_time)'"
display "There are `c(N) observations in my dataset"
display "There are `c(k)' variables in my dataset"

// r()
use nhanes, clear
summarize age
return list
display "The mean age is", r(mean)
display "The standard deviation is `r(mean)'"

// r(table)
use nhanes, clear
regress sbp age female
matlist r(table)

// e()
use nhanes, clear
regress sbp age female
ereturn list
display "The F-statistic for this model = ", e(F)
display "The previous command was", e(cmd)
matlist e(b)
matlist e(V)

// _b[], and _se[]
use nhanes, clear
regress sbp age female
display "The coefficient for female = ", _b[female]
display "The standard error for female = ", _se[female]










// Conditions and Branching
// =============================================================================
local pvalue = 0.0231
local significant = cond(`pvalue'<0.05, "significant", "not significant")
display "The p-value was `significant'."

local pvalue = 0.2310
local significant = cond(`pvalue'<0.05, "significant", "not significant")
display "The p-value was `significant'."

local pvalue = 0.0231
if `pvalue'<0.05 {
    display "The p-value was statistically significant (p = 0`pvalue'))"
}
else {
    display "The p-value was not statistically significant (p = 0`pvalue')"
}



// Loops
// =============================================================================
forvalues i = 1(1)5 {
    display "i = `i'"
}

forvalues i = 2(2)10 {
    display "i = `i'"
}

forvalues i = 1(1)3 {
    forvalues j = 4(1)6 {
	    display "(i,j) = (`i', `j')"
	}
}

use nhanes, clear
list age in 1/5
forvalues obs = 1/5 {
	display "The age of the person in observation `obs' is " age[`obs']
}

local animals "dog cat fish"
foreach pet of local animals {
	display "The pet is `pet'"
}

use nhanes
foreach var of varlist age bmi female {
	regress sbp `var', noheader
}


// How to extract variable labels and value labels
// ===============================================
// Extract variable labels
use nhanes
local VariableLabel: variable label healthstat
display "The variable label for foreign is: `VariableLabel'"

// Extract value label name
local ValueLabel : value label healthstat
display "The value label for foreign is: `ValueLabel'"

local ValueLabel : value label healthstat
label list `ValueLabel'

// Extract the levels and labels of a value label
levelsof healthstat, local(levels)
return list
local ValueLabelLevels = r(levels)

local variable = "healthstat"
local ValueLabel : value label `variable'
levelsof `variable', local(levels)
local ValueLabelLevels = r(levels)
foreach level of local ValueLabelLevels {
		local TempLabel : label `ValueLabel' `level'
		display "Level = `level', Label = `TempLabel'"
}



// preserve and restore
// =============================================================================
use nhanes, clear
list sbp age bmi in 1/5
preserve
collapse (mean) sbp age bmi, by(female)
list
restore
list sbp age bmi in 1/5


// frames
// =============================================================================
clear all
frame create data
frame change data
use nhanes, clear
list sbp age bmi in 1/5
frame create summary
frame change summary
use nhanes, clear
collapse (mean) sbp age bmi, by(female)
list
frame change data
list sbp age bmi in 1/5









