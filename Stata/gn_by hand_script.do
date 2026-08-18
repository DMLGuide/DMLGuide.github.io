// GN full replication in Stata
// "By-hand" DDML approach
// =========================

clear
set more off
set seed 42

version
which pystacked
which nnls2

// PART 1: OLS replication

// Load data
use "https://dmlguide.github.io/assets/dta/GN2021.dta"

// Shorten the name of the causal variable of interest to sd_EE
gen sd_EE = sd_of_gen_mean_temp_anom_EE

// Replicate results with no controls in Table 1, column (3).
// HC1 robust SE
reg A198new sd_EE, robust

di ""
di "PART 1: OLS (A198new ~ sd_EE) with HC1 robust SE"
di ""

// Figure 5
predict hat
twoway (scatter A198new sd_EE, msymbol(circle) msize(medium)) ///
       (line hat sd_EE, sort lwidth(medium)), ///
       xlabel(0(0.25)0.5) ylabel(3(1)6) ///
       xtitle("Climatic instability") ytitle("Importance of tradition") ///
       legend(off) ///
       text(2.85 0 "(coef = -1.92, t = -3.68)", placement(east))

drop hat

// PART 2: DML robustness check (single 10-fold shortstack)

// In the G-N estimations, GDP is missing for one country.
// For simplicity, we just drop this one country so that it is never used.
drop if missing(loggdp)

// To make the code more readable, define locals for Y, D and X:
local Y_var "A198new"
local D_var "sd_EE"
local X_vars "v104_ee settlement_ee polhierarchies_ee loggdp"

qui count
local n = r(N)
local K = 10

// Step 1: Specify the model.
// Partially-linear model with 10-fold cross-fitting, single split.

// Create 10-fold split
set seed 12345
gen fold_id = mod(_n - 1, `K') + 1
gen random_order = runiform()
sort random_order
drop random_order

// Storage for out-of-sample (cross-fitted) predictions
gen Y_hat_ols   = .
gen Y_hat_lasso = .
gen Y_hat_rf    = .

gen D_hat_ols   = .
gen D_hat_lasso = .
gen D_hat_rf    = .

// Step 2: Choose the learners.
// Unregularized OLS, cross-validated lasso, and random forest.

forvalues k = 1/`K' {

    // Learners for E[Y|X]

    qui reg `Y_var' `X_vars' if fold_id != `k'
    qui predict Y_hat_ols_temp if fold_id == `k'
    qui replace Y_hat_ols = Y_hat_ols_temp if fold_id == `k'
    drop Y_hat_ols_temp

    qui pystacked `Y_var' `X_vars' if fold_id != `k', ///
        type(reg) method(lassocv)
    qui predict Y_hat_lasso_temp if fold_id == `k'
    qui replace Y_hat_lasso = Y_hat_lasso_temp if fold_id == `k'
    drop Y_hat_lasso_temp

    qui pystacked `Y_var' `X_vars' if fold_id != `k', ///
        type(reg) method(rf)
    qui predict Y_hat_rf_temp if fold_id == `k'
    qui replace Y_hat_rf = Y_hat_rf_temp if fold_id == `k'
    drop Y_hat_rf_temp

    // Learners for E[D|X]

    qui reg `D_var' `X_vars' if fold_id != `k'
    qui predict D_hat_ols_temp if fold_id == `k'
    qui replace D_hat_ols = D_hat_ols_temp if fold_id == `k'
    drop D_hat_ols_temp

    qui pystacked `D_var' `X_vars' if fold_id != `k', ///
        type(reg) method(lassocv)
    qui predict D_hat_lasso_temp if fold_id == `k'
    qui replace D_hat_lasso = D_hat_lasso_temp if fold_id == `k'
    drop D_hat_lasso_temp

    qui pystacked `D_var' `X_vars' if fold_id != `k', ///
        type(reg) method(rf)
    qui predict D_hat_rf_temp if fold_id == `k'
    qui replace D_hat_rf = D_hat_rf_temp if fold_id == `k'
    drop D_hat_rf_temp
}

// Check that predictions are complete
assert !missing(Y_hat_ols)
assert !missing(Y_hat_lasso)
assert !missing(Y_hat_rf)
assert !missing(D_hat_ols)
assert !missing(D_hat_lasso)
assert !missing(D_hat_rf)

// Step 3: Short-stacking via constrained NNLS using nnls2.
// Weights are non-negative and sum to 1.
// Install with: net install nnls2, from(https://raw.githubusercontent.com/markeschaffer/nnls2/main) replace

// Short-stack weights for Y
nnls2 `Y_var' Y_hat_ols Y_hat_lasso Y_hat_rf
mat w_Y = e(b)
matrix rownames w_Y = `Y_var'
mat list w_Y

// Short-stack weights for D
nnls2 `D_var' D_hat_ols D_hat_lasso D_hat_rf
mat w_D = e(b)
matrix rownames w_D = `D_var'
mat list w_D

// Short-stacked conditional expectations
matrix score Y_hat_ss = w_Y
matrix score D_hat_ss = w_D

// Step 4: PLM estimation (residualised Y on residualised D)
gen Y_tilde = `Y_var' - Y_hat_ss
gen D_tilde = `D_var' - D_hat_ss

reg Y_tilde D_tilde, robust

di ""
di "PART 2: DML shortstack (single split), HC1 robust SE"
di ""

di ""
di "short-stacked weights across resamples for A198new"
di ""
di "ols      mean_weight=" %9.6f w_Y[1,1] "  rep_1=" %9.6f w_Y[1,1]
di "lassocv  mean_weight=" %9.6f w_Y[1,2] "  rep_1=" %9.6f w_Y[1,2]
di "rf       mean_weight=" %9.6f w_Y[1,3] "  rep_1=" %9.6f w_Y[1,3]

di ""
di "short-stacked weights across resamples for sd_EE"
di ""
di "ols      mean_weight=" %9.6f w_D[1,1] "  rep_1=" %9.6f w_D[1,1]
di "lassocv  mean_weight=" %9.6f w_D[1,2] "  rep_1=" %9.6f w_D[1,2]
di "rf       mean_weight=" %9.6f w_D[1,3] "  rep_1=" %9.6f w_D[1,3]

// Clean up before Part 3
drop Y_hat_* D_hat_* Y_tilde D_tilde Y_hat_ss D_hat_ss


// PART 3: Final DML model (11 resamples, median aggregation)

set seed 42

local K = 10
local R = 11

tempname coef_mat se_mat weights_Y_mat weights_D_mat
matrix `coef_mat'      = J(`R', 1, .)
matrix `se_mat'        = J(`R', 1, .)
matrix `weights_Y_mat' = J(3, `R', .)
matrix `weights_D_mat' = J(3, `R', .)

forvalues r = 1/`R' {

    di "Processing resample `r' of `R'..."

    drop fold_id
    gen fold_id = mod(_n - 1, `K') + 1
    gen random_order = runiform()
    sort random_order
    drop random_order

    gen Y_hat_ols   = .
    gen Y_hat_lasso = .
    gen Y_hat_rf    = .

    gen D_hat_ols   = .
    gen D_hat_lasso = .
    gen D_hat_rf    = .

    forvalues k = 1/`K' {

        qui reg `Y_var' `X_vars' if fold_id != `k'
        qui predict Y_hat_ols_temp if fold_id == `k'
        qui replace Y_hat_ols = Y_hat_ols_temp if fold_id == `k'
        drop Y_hat_ols_temp

        qui pystacked `Y_var' `X_vars' if fold_id != `k', ///
            type(reg) method(lassocv)
        qui predict Y_hat_lasso_temp if fold_id == `k'
        qui replace Y_hat_lasso = Y_hat_lasso_temp if fold_id == `k'
        drop Y_hat_lasso_temp

        qui pystacked `Y_var' `X_vars' if fold_id != `k', ///
            type(reg) method(rf)
        qui predict Y_hat_rf_temp if fold_id == `k'
        qui replace Y_hat_rf = Y_hat_rf_temp if fold_id == `k'
        drop Y_hat_rf_temp

        qui reg `D_var' `X_vars' if fold_id != `k'
        qui predict D_hat_ols_temp if fold_id == `k'
        qui replace D_hat_ols = D_hat_ols_temp if fold_id == `k'
        drop D_hat_ols_temp

        qui pystacked `D_var' `X_vars' if fold_id != `k', ///
            type(reg) method(lassocv)
        qui predict D_hat_lasso_temp if fold_id == `k'
        qui replace D_hat_lasso = D_hat_lasso_temp if fold_id == `k'
        drop D_hat_lasso_temp

        qui pystacked `D_var' `X_vars' if fold_id != `k', ///
            type(reg) method(rf)
        qui predict D_hat_rf_temp if fold_id == `k'
        qui replace D_hat_rf = D_hat_rf_temp if fold_id == `k'
        drop D_hat_rf_temp
    }

    // Short-stacking via nnls2 for this rep
    nnls2 `Y_var' Y_hat_ols Y_hat_lasso Y_hat_rf
    mat w_Y_`r' = e(b)
    matrix `weights_Y_mat'[1, `r'] = w_Y_`r'[1,1]
    matrix `weights_Y_mat'[2, `r'] = w_Y_`r'[1,2]
    matrix `weights_Y_mat'[3, `r'] = w_Y_`r'[1,3]

    nnls2 `D_var' D_hat_ols D_hat_lasso D_hat_rf
    mat w_D_`r' = e(b)
    matrix `weights_D_mat'[1, `r'] = w_D_`r'[1,1]
    matrix `weights_D_mat'[2, `r'] = w_D_`r'[1,2]
    matrix `weights_D_mat'[3, `r'] = w_D_`r'[1,3]

    matrix score Y_hat_ss = w_Y_`r'
    matrix score D_hat_ss = w_D_`r'

    gen Y_tilde = `Y_var' - Y_hat_ss
    gen D_tilde = `D_var' - D_hat_ss

    qui reg Y_tilde D_tilde, robust

    matrix `coef_mat'[`r', 1] = _b[D_tilde]
    matrix `se_mat'[`r', 1]   = _se[D_tilde]

    drop Y_hat_* D_hat_* Y_tilde D_tilde Y_hat_ss D_hat_ss
}

di ""
di "DDML shortstack results across 11 resamples (Stata analogue of ss 1..11):"
di ""
di "  rep           b          se"
forvalues r = 1/`R' {
    di %5.0f `r' "  " %10.7f `coef_mat'[`r',1] "  " %10.7f `se_mat'[`r',1]
}

// Step 5: Median aggregation:
// sigma = sqrt( Median( sigma_m^2 + (theta_m - theta_tilde)^2 ) )
mata:
    coef_vec    = st_matrix("`coef_mat'")
    se_vec      = st_matrix("`se_mat'")
    R           = rows(coef_vec)
    coef_sorted = sort(coef_vec, 1)
    if (mod(R,2)==1) {
        b_med = coef_sorted[(R+1)/2, 1]
    }
    else {
        b_med = (coef_sorted[R/2,1] + coef_sorted[R/2+1,1]) / 2
    }
    vals        = se_vec:^2 + (coef_vec :- b_med):^2
    vals_sorted = sort(vals, 1)
    if (mod(R,2)==1) {
        se_med = sqrt(vals_sorted[(R+1)/2, 1])
    }
    else {
        se_med = sqrt((vals_sorted[R/2,1] + vals_sorted[R/2+1,1]) / 2)
    }
    st_numscalar("b_med",  b_med)
    st_numscalar("se_med", se_med)
end

di ""
di "Median aggregated short-stack results:"
di ""
di "                    spec           b          se"
di "   shortstack median  " %10.7f b_med "  " %10.7f se_med

mata:
    wY = st_matrix("`weights_Y_mat'")
    wD = st_matrix("`weights_D_mat'")
    R  = cols(wY)
    learners = ("ols", "lassocv", "rf")
    printf("\nshort-stacked weights across resamples for A198new (11 reps)\n\n")
    printf("%-10s  %10s", "learner", "mean_weight")
    for (r=1; r<=R; r++) printf("  %8s", "rep_"+strofreal(r))
    printf("\n")
    for (i=1; i<=3; i++) {
        printf("%-10s  %10.6f", learners[i], mean(wY[i,.]'))
        for (r=1; r<=R; r++) printf("  %8.6f", wY[i,r])
        printf("\n")
    }
    printf("\nshort-stacked weights across resamples for sd_EE (11 reps)\n\n")
    printf("%-10s  %10s", "learner", "mean_weight")
    for (r=1; r<=R; r++) printf("  %8s", "rep_"+strofreal(r))
    printf("\n")
    for (i=1; i<=3; i++) {
        printf("%-10s  %10.6f", learners[i], mean(wD[i,.]'))
        for (r=1; r<=R; r++) printf("  %8.6f", wD[i,r])
        printf("\n")
    }
end

di ""
di "========================================"
di "GN replication complete!"
