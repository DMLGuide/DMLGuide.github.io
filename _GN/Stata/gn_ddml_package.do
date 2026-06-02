// =========================
// GN full replication in Stata
//  Using the ddml package (with pystacked + nnls1 short-stacking)
//
// Each `// @snippet:NAME ... // @end` block is extracted by
// `_GN/build_snippets.py` into `_includes/GN/NAME_stata.txt`
// and imported by `examples/GN.md` via Liquid.

clear all
set more off
set seed 42


// =============================================================
// (1) OLS replication — Table 1, column (4)
// =============================================================

// @snippet:ols_code
clear all
set more off
set seed 42

// Load data
use "https://dmlguide.github.io/assets/dta/GN2021.dta", clear

// Shorten the name of the causal variable of interest to sd_EE
gen sd_EE = sd_of_gen_mean_temp_anom_EE

// Replicate Table 1, column (4): OLS with the 4 controls, HC1 robust SE.
// One country has loggdp missing; reg drops it automatically (N = 74).
display "###BEGIN_OUT:ols_out###"
reg A198new sd_EE v104_ee settlement_ee polhierarchies_ee loggdp, robust
display "###END_OUT:ols_out###"
// @end


// =============================================================
// (2) Figure 5 — bivariate scatter (column 3)
// =============================================================

// @snippet:fig5_code
// Figure 5 visualises the bivariate (no-controls) relationship — column (3).
reg A198new sd_EE, robust
predict hat
twoway (scatter A198new sd_EE, msymbol(circle) msize(medium)) ///
       (line hat sd_EE, sort lwidth(medium)), ///
       xlabel(0(0.25)0.5) ylabel(3(1)6) ///
       xtitle("Climatic instability") ytitle("Importance of tradition") ///
       legend(off) ///
       text(2.85 0 "(coef = -1.92, t = -3.68)", placement(east))

drop hat
// @end


// =============================================================
// (3) DML robustness check — single 10-fold split with short-stacking
// =============================================================

// @snippet:dml_code
// In the GN estimations, GDP is missing for one country.
// For simplicity, we just drop this one country so that it is never used.
drop if missing(loggdp)

// To make the code more readable, define locals for Y, D and X:
local Y_var "A198new"
local D_var "sd_EE"
local X_vars "v104_ee settlement_ee polhierarchies_ee loggdp"

// In Stata, we now use ddml with pystacked for OLS, cross-validated lasso,
// and random forest learners combined via short-stacking (nnls1).

// Step 1: Initialize ddml for partially linear model
ddml init partial, kfolds(10)

// Step 2: Specify the model components
// Outcome equation
ddml E[Y|X]: pystacked `Y_var' `X_vars', ///
    type(reg) methods(ols lassocv rf)

// Treatment equation
ddml E[D|X]: pystacked `D_var' `X_vars', ///
    type(reg) methods(ols lassocv rf)

// Step 3: Cross-fit with short-stacking
// Set seed for this single split
set seed 12345
ddml crossfit, shortstack nostdstack

// Step 4: Estimate the partially linear model
display "###BEGIN_OUT:dml_out###"
ddml estimate, robust
display "###END_OUT:dml_out###"
// @end


// =============================================================
// (4) Short-stack weights from the single-split fit
// =============================================================

// @snippet:ssw_code
// Display the short-stack weights.
display "###BEGIN_OUT:ssw_out###"
ddml extract, show(ssweights)
display "###END_OUT:ssw_out###"
// @end


// =============================================================
// (5) Results by learner — per-learner residual regression + scatter
// =============================================================

// @snippet:rbl_est_code
// ddml creates conditional expectations for each learner.
// With pystacked, the learners are numbered.
// The final "_1" identifies the resample (the single cross-fit split).
// Globals used by the residual-construction lines below.
global Y A198new
global D sd_EE

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

// Per-learner residual regressions; store for the comparison table.
qui reg Y_L1_r D_L1_r, robust
est store ddml_L1_L1, title("OLS learners")
qui reg Y_L2_r D_L2_r, robust
est store ddml_L2_L2, title("Lasso learners")
qui reg Y_L3_r D_L3_r, robust
est store ddml_L3_L3, title("RF learners")
qui reg Y_ss_r D_ss_r, robust
est store ddml_SS_SS, title("SS learners")

// Compare DML estimations for learner combinations:
// nb: Code uses estout by Ben Jann; install from SSC Archives.
set linesize 200
display "###BEGIN_OUT:rbl_est_out###"
estout ddml_L1_L1 ddml_L2_L2 ddml_L3_L3 ddml_SS_SS,					///
	label modelwidth(15) collabels(none)							///
	rename (D_L1_r D_r D_L2_r D_r D_L3_r D_r D_ss_r D_r)			///
	cells(b(fmt(3)) se(par fmt(3)))									///
	varlabels(_cons Constant)
display "###END_OUT:rbl_est_out###"
// @end


// @snippet:rbl_plot_code
// Restore each stored estimate so predict() uses the right regression,
// then plot residualized Y vs residualized D with the fitted line.
estimates restore ddml_L1_L1
cap drop hat_1_1
predict hat_1_1
twoway (scatter Y_L1_r D_L1_r, msymbol(o) mlabel(isocode))			///
	(line hat_1_1 D_L1_r, sort lwidth(thick)),					 	///
	legend(off) xlabel(-0.3 -0.2 -0.1 0 0.1 0.2 0.3, nogrid)		///
	ylabel(-2 -1 0 1 2, nogrid)										///
	title("Y and D: Unregularized OLS")								///
	ytitle("Importance of tradition")								///
	xtitle("Climatic instability") name(OLS, replace)

estimates restore ddml_L2_L2
cap drop hat_2_2
predict hat_2_2
twoway (scatter Y_L2_r D_L2_r, msymbol(o) mlabel(isocode))			///
	(line hat_2_2 D_L2_r, sort lwidth(thick)),					 	///
	legend(off) xlabel(-0.3 -0.2 -0.1 0 0.1 0.2 0.3, nogrid)		///
	ylabel(-2 -1 0 1 2, nogrid)										///
	title("Y and D: Lasso")											///
	ytitle("Importance of tradition")								///
	xtitle("Climatic instability") name(Lasso, replace)

estimates restore ddml_L3_L3
cap drop hat_3_3
predict hat_3_3
twoway (scatter Y_L3_r D_L3_r, msymbol(o) mlabel(isocode))			///
	(line hat_3_3 D_L3_r, sort lwidth(thick)),					 	///
	legend(off) xlabel(-0.3 -0.2 -0.1 0 0.1 0.2 0.3, nogrid)		///
	ylabel(-2 -1 0 1 2, nogrid)										///
	title("Y and D: Random Forest")									///
	ytitle("Importance of tradition")								///
	xtitle("Climatic instability") name(RF, replace)

estimates restore ddml_SS_SS
cap drop hat_ss_ss
predict hat_ss_ss
twoway (scatter Y_ss_r D_ss_r, msymbol(o) mlabel(isocode))			///
	(line hat_ss_ss D_ss_r, sort lwidth(thick)),				 	///
	legend(off) xlabel(-0.3 -0.2 -0.1 0 0.1 0.2 0.3, nogrid)		///
	ylabel(-2 -1 0 1 2, nogrid)										///
	title("Y and D: Short-stacked")									///
	ytitle("Importance of tradition")								///
	xtitle("Climatic instability") name(SS, replace)

graph combine OLS Lasso RF SS
// @end


// =============================================================
// (6) Final DML model — 11 resamples + median aggregation
// =============================================================

// @snippet:final_code
// "Final" results using ddml (multiple resamples, median aggregation)
// 1. Set seed for replicability.
// 2. Use 11 separate cross-fit splits (reps = 11).
// 3. Use 10-fold cross-fitting in each rep.
// 4. Short-stacking via nnls1 in each rep (automatic in ddml).
// 5. Aggregate coefficients (mean and median).
// 6. Report stacking weights across reps.

// Reload data for fresh start
use "https://dmlguide.github.io/assets/dta/GN2021.dta", clear
gen sd_EE = sd_of_gen_mean_temp_anom_EE
drop if missing(loggdp)

// Step 1: Set seed for replicability
set seed 42

// Step 2: Initialize ddml with 10 folds and 11 reps
ddml init partial, kfolds(10) reps(11)

// Specify the model components
ddml E[Y|X]: pystacked `Y_var' `X_vars', ///
    type(reg) methods(ols lassocv rf)

ddml E[D|X]: pystacked `D_var' `X_vars', ///
    type(reg) methods(ols lassocv rf)

// Step 3: Cross-fit with short-stacking across all 11 reps
ddml crossfit, shortstack nostdstack

// Step 4: Estimate with median aggregation
display "###BEGIN_OUT:final_out###"
ddml estimate, robust rep(median)
display "###END_OUT:final_out###"
// @end


// =============================================================
// (7) Final stacking weights — across the 11 resamples
// =============================================================

// @snippet:fsw_code
// Display the stacking weights.
// As before, unregularized OLS gets a low weight for both Y and D,
// and the random forest learner gets a substantial weight in both.
display "###BEGIN_OUT:fsw_out###"
ddml extract, show(ssweights)
display "###END_OUT:fsw_out###"
// @end


di ""
di "========================================"
di "GN replication complete!"
