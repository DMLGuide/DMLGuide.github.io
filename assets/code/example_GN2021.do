// Basic DML example for JEL paper/website.
// MS, 21 March 2025
// Comments preceded by // accompany the code.
// Comments in /* */ are for the website text.

cap cd /Users/kahrens/MyProjects/DMLGuide.github.io/assets

*******************************************************************************
set seed 123
***************************

cap log close
log using "logs/example_GN2021.txt", replace text

use "https://dmlguide.github.io/assets/dta/GN2021.dta", clear

// shorten the name of the causal variable of interest to sd_EE
rename sd_of_gen_mean_temp_anom_EE sd_EE

// replicate results with no controls in Table 1, column (3).
eststo m0: ///
reg A198new sd_EE, robust

// replicate Figure 5
reg A198new sd_EE, robust
predict hat
twoway (scatter A198new sd_EE, msymbol(o) mlabel(isocode))			///
	(line hat sd_EE, sort lwidth(thick)),						 	///
	legend(off) xlabel(0 0.25 0.5, nogrid)							///
	ylabel(3 4 5 6, nogrid)											///
	note("(coef = -1.92, t = -3.68)")								///
	ytitle("Importance of tradition")								///
	xtitle("Climatic instability")
drop hat
graph export "logs/GN_Figure5.png", replace

// replicate results with controls in Table 1, column (4).
eststo m1: ///
reg A198new sd_EE v104_ee settlement_ee polhierarchies_ee loggdp, robust

esttab m0 m1
estout m0 m1,														///
	label modelwidth(15) collabels(none)							///
	cells(b(fmt(3)) se(par fmt(3)))									///
	varlabels(_cons Constant)

// In the G-N estimations, GDP is missing for one country.
// For simplicity, we just drop this one country so that it is never used.
drop if loggdp==.

// To make the code more readable, define macros Y, D and X:
global Y A198new
global D sd_EE
global X v104_ee settlement_ee polhierarchies_ee loggdp


// In Stata, we use the ddml package along with the pystacked package.
// pystacked is a front-end to sklearn's stacking regression.
which ddml
which pystacked

// Step 1: Specify the model.
// We use the partially-linear model with 10-fold cross-fitting and a single cross-fit split.
ddml init partial, kfolds(10) reps(1)

// Step 2: Choose the learners.
// We use unregularized OLS, cross-validated lasso and random forest.
// We use the same learners for Y and X for expositional simplicity only.
ddml E[Y|X]: pystacked $Y $X								///
								|| method(ols)				///
								|| method(lassocv)			///
								|| method(rf)				///
								, type(reg)

ddml E[D|X]: pystacked $D $X								///
								|| method(ols)				///
								|| method(lassocv)			///
								|| method(rf)				///
								, type(reg)

// Check that the learners have been entered correctly.
ddml desc, learners

// Step 3: Cross-fit.
// We use short-stacking to combine the conditional expectations
// of the different learners.
// The default behavior of ddml+pystacked is to do standard stacking,
// which is computationally intensive; short-stacking is faster.
// To suppress standard stacking, we use the nostdstack option.
ddml crossfit, shortstack nostdstack

// Step 4: Estimation
// After Step 3, we have 4 sets of residualized Y and 4 of residualized D,
// based on 4 sets of estimated conditional expectations:
// one for each of the 3 learners plus one stacked (ensemble) estimate.
// By default, ddml reports the short-stacked results:
// the residualized dependent variable Y is regressed on the residualized
// causal variable of interest D using OLS.
// Note that if you execute the code your your results will vary
// (usually only slightly) because the seed hasn't been set.
ddml estimate, robust

// Display the short-stack weights.
ddml extract, show(ssweights)

// ddml creates conditional expectations for each learner.
// With pystacked, the learners are numbered.
// The final "_1" identifies the resample (the single cross-fit split).
// Create residualized Y and D for each learner.
cap drop Y_L1_r Y_L2_r Y_L3_r Y_ss_r D_L1_r D_L2_r D_L3_r D_ss_r
gen Y_L1_r = $Y-Y1_pystacked_L1_1
gen Y_L2_r = $Y-Y1_pystacked_L2_1
gen Y_L3_r = $Y-Y1_pystacked_L3_1
gen Y_ss_r = $Y-Y_A198new_ss_1
gen D_L1_r = $D-D1_pystacked_L1_1
gen D_L2_r = $D-D1_pystacked_L2_1
gen D_L3_r = $D-D1_pystacked_L3_1
gen D_ss_r = $D-D_sd_EE_ss_1

// 4 specification and scatterplots
// Y and D learners = OLS
// We suppress the output for the individual OLS regressions to save space.
qui reg Y_L1_r D_L1_r, robust
est store ddml_L1_L1, title("OLS learners")
cap drop hat_1_1
predict hat_1_1
twoway (scatter Y_L1_r D_L1_r, msymbol(o) mlabel(isocode))			///
	(line hat_1_1 D_L1_r, sort lwidth(thick)),					 	///
	legend(off)														///
	xlabel(-0.3 -0.2 -0.1 0 0.1 0.2 0.3, nogrid)					///
	ylabel(-2 -1 0 1 2, nogrid)										///
	title("Y and D: Unregularized OLS")								///
	ytitle("Importance of tradition")								///
	xtitle("Climatic instability")									///
	name(OLS, replace)
// Y and D learners = CV Lasso
qui reg Y_L2_r D_L2_r, robust
est store ddml_L2_L2, title("Lasso learners")
cap drop hat_2_2
predict hat_2_2
twoway (scatter Y_L2_r D_L2_r, msymbol(o) mlabel(isocode))			///
	(line hat_2_2 D_L2_r, sort lwidth(thick)),					 	///
	legend(off)														///
	xlabel(-0.3 -0.2 -0.1 0 0.1 0.2 0.3, nogrid)					///
	ylabel(-2 -1 0 1 2, nogrid)										///
	title("Y and D: Lasso")											///
	ytitle("Importance of tradition")								///
	xtitle("Climatic instability")									///
	name(Lasso, replace)
// Y and D learners = Random Forest
qui reg Y_L3_r D_L3_r, robust
est store ddml_L3_L3, title("RF learners")
cap drop hat_3_3
predict hat_3_3
twoway (scatter Y_L3_r D_L3_r, msymbol(o) mlabel(isocode))			///
	(line hat_3_3 D_L3_r, sort lwidth(thick)),					 	///
	legend(off)														///
	xlabel(-0.3 -0.2 -0.1 0 0.1 0.2 0.3, nogrid)					///
	ylabel(-2 -1 0 1 2, nogrid)										///
	title("Y and D: Random Forest")									///
	ytitle("Importance of tradition")								///
	xtitle("Climatic instability")									///
	name(RF, replace)
// Y and D learners = Short-stacked (ensemble of OLS, Lasso, RF)
qui reg Y_ss_r D_ss_r, robust
est store ddml_SS_SS, title("SS learners")
cap drop hat_ss_ss
predict hat_ss_ss
twoway (scatter Y_ss_r D_ss_r, msymbol(o) mlabel(isocode))			///
	(line hat_ss_ss D_ss_r, sort lwidth(thick)),				 	///
	legend(off)														///
	xlabel(-0.3 -0.2 -0.1 0 0.1 0.2 0.3, nogrid)					///
	ylabel(-2 -1 0 1 2, nogrid)										///
	title("Y and D: Short-stacked")									///
	ytitle("Importance of tradition")								///
	xtitle("Climatic instability")									///
	name(SS, replace)

// Compare DML estimations for learner combinations:
// nb: Code uses estout by Ben Jann; install from SSC Archives.
estout ddml_L1_L1 ddml_L2_L2 ddml_L3_L3 ddml_SS_SS,					///
	label modelwidth(15) collabels(none)							///
	rename (D_L1_r D_r D_L2_r D_r D_L3_r D_r D_ss_r D_r)			///
	cells(b(fmt(3)) se(par fmt(3)))									///
	varlabels(_cons Constant)

// Compare via scatterplot:
graph combine OLS Lasso RF SS
graph export "images/GN_4learners.png", replace

// "Final" results:
// 1. Set seed for replicability.
// 2. Report all 3 stacking methods.
// 3. 11 separate cross-fit splits and median aggregation.

// The choice of 11 separate cross-fit splits is so that the median is well-defined.

// Set the seed.
set seed 42

// Step 1: Specify the model.
// Use 11 separate resample splits.
ddml init partial, kfolds(10) reps(11)

// Step 2: Choose the learners.
// Conditional expections are defined as before.
ddml E[Y|X]: pystacked $Y $X								///
								|| method(ols)				///
								|| method(lassocv)			///
								|| method(rf)				///
								, type(reg)

ddml E[D|X]: pystacked $D $X								///
								|| method(ols)				///
								|| method(lassocv)			///
								|| method(rf)				///
								, type(reg)

// Step 3: Cross-fit.
// Standard stacking is the default behavior of ddml+pystacked.
// Pooled-stacking is requested separately.
ddml crossfit, shortstack nostdstack

// Step 4: Estimation.
// Median-aggregated short-stacked results are reported by default.
// We also ask for the standard and pooled-stacking results.
ddml estimate, robust

// Display the stacking weights.
// As before, unregularized OLS gets a low weight for both Y and D,
// and the random forest learner gets a substantial weight in both.
ddml extract, show(ssweights)

********************************************************************************

cap log close
