---
layout: default
title: Understanding Cultural Persistence and Change 
parent: Examples
nav_order: 4
math: true
description: ""
permalink: /examples/GN
enable_copy_code_button: true
---

# Understanding Cultural Persistence and Change 

## Setting

In this example we illustrate the basic workings of DML using a simple empirical example. The application is drawn from [Giuliano and Nunn (2021)](https://doi.org/10.1093/restud/rdaa074), who look at the relationship between climate instability and cultural persistence using a number of different datasets.

Their first estimation is a cross-country regression where the dependent variable, $Y$, is a measure of the importance of tradition taken from the World Values Survey, and the causal variable of interest, $D$, is a measure of ancestral climatic instability. The dataset is quite small: only 74-75 countries.

Giuliano and Nunn (G-N) are concerned about omitted confounders, and include 4 controls to address the issue.

1. distance from the equator;
2. a proxy for early economic development, proxied by complexity of settlements;
3. a measure of political centralization;
4. real per capital GDP in the survey year.

The example is useful for illustrating how DML works for several reasons: the dataset is small and available online, visualization is easy, reproduction of results is straightforward, and the example shows how DML can be used as a robustness check even in the simplest of settings.

The G-N dataset used for this demonstration is available [here](https://dmlguide.github.io/assets/dta/GN2021.dta). 

The variables used are:

| Variable | Description |
| ----------- | ----------------|
| `A198new`	| The outcome variable of interest: country-level average of the self-reported importance of tradition. Ranges from 1 to 6 (bigger=more important). |
| `sd_EE` | The causal variable of interest: a measure of ancestral climatic instability (standard deviation of temperature anomaly measure across generations; see G-N for details). |
| `v104_ee`	| Control #1: distance from the equator. | 
| `settlement_ee` | Control #2: early economic development (proxied by complexity of settlements). | 
| `polhierarchies_ee` | Control #3: political hierarchies (a measure of political centralization). | 
| `loggdp`| Control #4: log GDP per capita in the country of origin at the time of the survey. |

Their model with controls is one where the controls enter linearly and is estimated using OLS. The effect of climatic instability on the importance of tradition is negative, with a coefficient that is different from zero at conventional significance levels. 

G-N summarize as follows (p. 155):
> Based on the estimates from column 4, a one-standard-deviation increase in cross-generational instability (0.11) is associated with a reduction in the tradition index of 1.824×0.11=0.20, which is 36% of a standard deviation of the tradition variable.

## Replication

We first reproduce, with the help of G-N's replication code, columns (3) and (4) in Table 1 of the published paper. Column (3) is a bivariate linear regression of the outcome $Y$ (importance of tradition) on the causal variable of interest $D$ (ancestral climatic instability). Column (4) has the OLS results when the 4 controls are included. In the DML example below, we show how to use DML to estimate the Column (4) specification.

We also reproduce their replication code for Figure 5, which is a simple scatterplot of the bivariate regression with no controls reported in Column (3).

<details markdown="block">
<summary>Stata code</summary>

```
use "https://dmlguide.github.io/assets/dta/GN2021.dta", clear

// shorten the name of the causal variable of interest to sd_EE
rename sd_of_gen_mean_temp_anom_EE sd_EE

// replicate results with no controls in Table 1, column (3).
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

// replicate results with controls in Table 1, column (4).
reg A198new sd_EE v104_ee settlement_ee polhierarchies_ee loggdp, robust
```

</details>

<details markdown="block">
<summary>Stata output</summary>

```
. 
. // replicate results with no controls in Table 1, column (3).
. reg A198new sd_EE, robust

Linear regression                               Number of obs     =         75
                                                F(1, 73)          =      13.54
                                                Prob > F          =     0.0004
                                                R-squared         =     0.1478
                                                Root MSE          =     .51072

------------------------------------------------------------------------------
             |               Robust
     A198new | Coefficient  std. err.      t    P>|t|     [95% conf. interval]
-------------+----------------------------------------------------------------
       sd_EE |  -1.923264   .5227138    -3.68   0.000    -2.965031   -.8814967
       _cons |   5.006289    .139419    35.91   0.000     4.728428    5.284151
------------------------------------------------------------------------------

```

</details>


## DML as a robustness check

A useful robustness check is to ask whether the results with controls are sensitive to the assumption that the controls enter linearly. DML can help answer this question. Below we estimate the model with controls using DML and the partially-linear model (PLM). The specification is still very simple: we keep the assumption that the controls enter separately, but drop linearity.

The estimation procedure takes the following steps:

1. Specify the DML model: in this case, the PLM.
2. Specify the learners: choose the learners for the conditional expectation functions for the outcome variable and the causal variable of interest.
3. Cross-fitting: obtain cross-fit estimates of the two conditional expectations.
4. Estimation: regress the residualized outcome variable on the residualized causal variable of interest.

We have no strong priors on whether a linear or non-linear learner is more appropriate, or whether regularization is needed at all. Hence we use 3 learners in this example: unregularized OLS, cross-validated Lasso, and a random forest. We also use short-stacking to combine the estimated conditional expectations from these 3 learners. Short-stacking is computationally cheap and fast. Also to make the example run quickly the initial estimation is done just once, i.e., we do not resample (re-cross-fit based on different splits).

The dataset is small, and so we choose 10-fold cross-fitting. This means that learners are trained on about 66-67 observations, and OOS predictions are obtained for the remaining 7-8 observations. (If the dataset were larger, we could e.g. use 5-fold cross-fitting and save some computation time.)

<details markdown="block">
<summary>Stata code</summary>

```
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
// After Step 3, we have 4 sets of residualized Y and 4 of residualized X,
// based on 4 sets of estimated conditional expectations:
// one for each of the 3 learners plus one stacked (ensemble) estimate.
// By default, ddml reports the short-stacked results:
// the residualized dependent variable Y is regressed on the residualized
// causal variable of interest X using OLS.
// Note that if you execute the code your your results will vary
// (usually only slightly) because the seed hasn't been set.
ddml estimate, robust
```

</details>

<details markdown="block">
<summary>Stata output</summary>

```
. // Step 1: Specify the model.
. // We use the partially-linear model with 10-fold cross-fitting and a single cross-fit split.
. ddml init partial, kfolds(10) reps(1)
warning - model m0 already exists
all existing model results and variables will
be dropped and model m0 will be re-initialized

. 
. // Step 2: Choose the learners.
. // We use unregularized OLS, cross-validated lasso and random forest.
. // We use the same learners for Y and X for expositional simplicity only.
. ddml E[Y|X]: pystacked $Y $X                                                            ///
>                                                                 || method(ols)                          ///
>                                                                 || method(lassocv)                      ///
>                                                                 || method(rf)                           ///
>                                                                 , type(reg)
Learner Y1_pystacked added successfully.

. 
. ddml E[D|X]: pystacked $D $X                                                            ///
>                                                                 || method(ols)                          ///
>                                                                 || method(lassocv)                      ///
>                                                                 || method(rf)                           ///
>                                                                 , type(reg)
Learner D1_pystacked added successfully.

. 
. // Check that the learners have been entered correctly.
. ddml desc, learners

Model:                  partial, crossfit folds k=10, resamples r=1
Mata global (mname):    m0
Dependent variable (Y): A198new
 A198new learners:      Y1_pystacked
D equations (1):        sd_EE
 sd_EE learners:        D1_pystacked

Y learners (detail):
 Learner:     Y1_pystacked
              est cmd: pystacked A198new v104_ee settlement_ee polhierarchies_ee loggdp || method(ols) || method(lassocv) || method(rf), type(reg)
D learners (detail):
 Learner:     D1_pystacked
              est cmd: pystacked sd_EE v104_ee settlement_ee polhierarchies_ee loggdp || method(ols) || method(lassocv) || method(rf), type(reg)

. 
. // Step 3: Cross-fit.
. // We use short-stacking to combine the conditional expectations
. // of the different learners.
. // The default behavior of ddml+pystacked is to do standard stacking,
. // which is computationally intensive; short-stacking is faster.
. // To suppress standard stacking, we use the nostdstack option.
. ddml crossfit, shortstack nostdstack
Cross-fitting E[y|X] equation: A198new
Cross-fitting fold 1 2 3 4 5 6 7 8 9 10 ...completed cross-fitting...completed short-stacking
Cross-fitting E[D|X] equation: sd_EE
Cross-fitting fold 1 2 3 4 5 6 7 8 9 10 ...completed cross-fitting...completed short-stacking

. 
. // Step 4: Estimation
. // After Step 3, we have 4 sets of residualized Y and 4 of residualized D,
. // based on 4 sets of estimated conditional expectations:
. // one for each of the 3 learners plus one stacked (ensemble) estimate.
. // By default, ddml reports the short-stacked results:
. // the residualized dependent variable Y is regressed on the residualized
. // causal variable of interest D using OLS.
. // Note that if you execute the code your your results will vary
. // (usually only slightly) because the seed hasn't been set.
. ddml estimate, robust


Model:                  partial, crossfit folds k=10, resamples r=1
Mata global (mname):    m0
Dependent variable (Y): A198new
 A198new learners:      Y1_pystacked
D equations (1):        sd_EE
 sd_EE learners:        D1_pystacked

DDML estimation results:
spec  r     Y learner     D learner         b        SE 
  ss  1  [shortstack]          [ss]    -2.164    (0.741)

Shortstack DDML model
y-E[y|X]  = y-Y_A198new_ss_1                       Number of obs   =        74
D-E[D|X]  = D-D_sd_EE_ss_1 
------------------------------------------------------------------------------
             |               Robust
     A198new | Coefficient  std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
       sd_EE |   -2.16408   .7413585    -2.92   0.004    -3.617116    -.711044
       _cons |   .0000172    .052501     0.00   1.000     -.102883    .1029173
------------------------------------------------------------------------------
Stacking final estimator: nnls1

```

</details>


We haven't set the random number seed,[^bhnote] so the results will vary based on the randomization of the cross-fit split and any randomization used by the learners.
But typically the DML short-stacked results are quite close to the original linear specification use by G-N.
A natural interpretation is that the G-N results still stand in this robustness check.

[^bhnote]: B. Hansen (2022, p. 298) suggests, in the context of the use of the bootstrap, that fixing the seed should be done cautiously and is "an unwise choice for daily calculations" because it leads to the same numerical results and hence a misleading sense of stability. The same argument applies here.

This does not mean, however, that the linear specification was the "right" choice. Depending on the randomization in the cross-fit split and the learners, the short-stacking weights will typically put a low weight on unregularized OLS. The random forest learner will also typically get a substantial weight in both of the conditional expectation estimates. This suggests that some nonlinearity is present, but that the assumption of linearity does not substantially affect the results.

<details markdown="block">
<summary>Stata code</summary>

```
// Display the short-stack weights.
ddml extract, show(ssweights)
```

</details>

<details markdown="block">
<summary>Stata output</summary>

```
. // Display the short-stack weights.
. ddml extract, show(ssweights)

short-stacked weights across resamples for A198new
final stacking estimator: nnls1
             learner  mean_weight        rep_1
    ols            1    5.105e-18    5.105e-18
lassocv            2    .48057564    .48057564
     rf            3    .51942436    .51942436

short-stacked weights across resamples for sd_EE
final stacking estimator: nnls1
             learner  mean_weight        rep_1
    ols            1            0            0
lassocv            2    .41567392    .41567392
     rf            3    .58432608    .58432608

```

</details>


## Results by learner

The residualized Y and D can also be inspected and used in other specifications. The G-N dataset is very small and we can plot the results as in Figure 5 of the original paper. Below we look at scatterplots where the same learner is used for both Y and D. But we could also look at combinations, e.g., unregularized OLS for Y and RF for D. This is related to a version of stacking sometimes called "single-best", where instead of deriving weights using NNLS, all the weight is put on the learner with the best OOS performance (smallest MSPE).

<details markdown="block">
<summary>Stata code</summary>

```
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
graph export "$logfolder/G-N 4 Learners.png", replace
```

</details>

<details markdown="block">
<summary>Stata output</summary>

```
. // Compare DML estimations for learner combinations:
. // nb: Code uses estout by Ben Jann; install from SSC Archives.
. estout ddml_L1_L1 ddml_L2_L2 ddml_L3_L3 ddml_SS_SS,                                     ///
>         label modelwidth(15) collabels(none)                                                    ///
>         rename (D_L1_r D_r D_L2_r D_r D_L3_r D_r D_ss_r D_r)                    ///
>         cells(b(fmt(3)) se(par fmt(3)))                                                                 ///
>         varlabels(_cons Constant)

------------------------------------------------------------------------------------
                        OLS learners  Lasso learners     RF learners     SS learners
------------------------------------------------------------------------------------
D_r                           -1.799          -1.839          -2.147          -2.164
                             (0.665)         (0.668)         (0.680)         (0.741)
Constant                      -0.020          -0.011           0.010           0.000
                             (0.055)         (0.055)         (0.054)         (0.053)
------------------------------------------------------------------------------------

```

</details>



## Final model

The procedure above is suitable for "work-in-progress".
For "final" results (e.g., for publication), a researcher should:

1. Set the random number seed(s) for replicability.
2. Consider using multiple cross-fit splits and aggregate them.
3. Consider using other stacking methods.

Cross-fitting introduces randomness by using a random split into cross-fit folds.
A straightfoward way to reduce the sensitivity of the results to the split is to re-estimate using different cross-fit splits and aggregate the results.
Aggregation can use the median or the mean.

Short-stacking stacking is computationally appealing but there are other options. Standard stacking - stacking separately for each cross-fit estimation - is also a possibility. "Pooled stacking" is similar to standard stacking except that the weights for combining learners are based on the OOS predictions for the entire sample (rather than for each cross-fit fold separately).

The example below illustrates.

<details markdown="block">
<summary>Stata code</summary>

```
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
ddml crossfit, shortstack poolstack

// Step 4: Estimation.
// Median-aggregated short-stacked results are reported by default.
// We also ask for the standard and pooled-stacking results.
ddml estimate, robust
ddml estimate, spec(st) rep(md) notable replay
ddml estimate, spec(ps) rep(md) notable replay

</details>

<details markdown="block">
<summary>Stata output</summary>

```
. // Set the seed.
. set seed 42

. 
. // Step 1: Specify the model.
. // Use 11 separate resample splits.
. ddml init partial, kfolds(10) reps(11)
warning - model m0 already exists
all existing model results and variables will
be dropped and model m0 will be re-initialized

. 
. // Step 2: Choose the learners.
. // Conditional expections are defined as before.
. ddml E[Y|X]: pystacked $Y $X                                                            ///
>                                                                 || method(ols)                          ///
>                                                                 || method(lassocv)                      ///
>                                                                 || method(rf)                           ///
>                                                                 , type(reg)
Learner Y1_pystacked added successfully.

. 
. ddml E[D|X]: pystacked $D $X                                                            ///
>                                                                 || method(ols)                          ///
>                                                                 || method(lassocv)                      ///
>                                                                 || method(rf)                           ///
>                                                                 , type(reg)
Learner D1_pystacked added successfully.

. 
. // Step 3: Cross-fit.
. // Standard stacking is the default behavior of ddml+pystacked.
. // Pooled-stacking is requested separately.
. ddml crossfit, shortstack poolstack
Cross-fitting E[y|X] equation: A198new
Resample 1...
Cross-fitting fold 1 2 3 4 5 6 7 8 9 10 ...completed cross-fitting...completed short-stacking...completed pooled-stacking
Resample 2...
Cross-fitting fold 1 2 3 4 5 6 7 8 9 10 ...completed cross-fitting...completed short-stacking...completed pooled-stacking
...
(remaining output not reported here)

. 
. // Step 4: Estimation.
. // Median-aggregated short-stacked results are reported by default.
. // We also ask for the standard and pooled-stacking results.
. ddml estimate, robust


Model:                  partial, crossfit folds k=10, resamples r=11
Mata global (mname):    m0
Dependent variable (Y): A198new
 A198new learners:      Y1_pystacked
D equations (1):        sd_EE
 sd_EE learners:        D1_pystacked

DDML estimation results:
spec  r     Y learner     D learner         b        SE 
  st  1  Y1_pystacked  D1_pystacked    -2.160    (0.784)
  ss  1  [shortstack]          [ss]    -2.326    (0.802)
  ps  1   [poolstack]          [ps]    -2.366    (0.801)
  st  2  Y1_pystacked  D1_pystacked    -1.801    (0.771)
  ss  2  [shortstack]          [ss]    -1.907    (0.769)
  ps  2   [poolstack]          [ps]    -1.865    (0.780)
  st  3  Y1_pystacked  D1_pystacked    -2.150    (0.737)
  ss  3  [shortstack]          [ss]    -2.141    (0.723)
  ps  3   [poolstack]          [ps]    -2.189    (0.729)
  st  4  Y1_pystacked  D1_pystacked    -2.257    (0.808)
  ss  4  [shortstack]          [ss]    -2.058    (0.790)
  ps  4   [poolstack]          [ps]    -2.094    (0.808)
  st  5  Y1_pystacked  D1_pystacked    -2.269    (0.796)
  ss  5  [shortstack]          [ss]    -2.265    (0.797)
  ps  5   [poolstack]          [ps]    -2.268    (0.794)
  st  6  Y1_pystacked  D1_pystacked    -2.272    (0.762)
  ss  6  [shortstack]          [ss]    -2.108    (0.764)
  ps  6   [poolstack]          [ps]    -2.142    (0.749)
  st  7  Y1_pystacked  D1_pystacked    -2.269    (0.734)
  ss  7  [shortstack]          [ss]    -2.252    (0.735)
  ps  7   [poolstack]          [ps]    -2.255    (0.726)
  st  8  Y1_pystacked  D1_pystacked    -1.912    (0.715)
  ss  8  [shortstack]          [ss]    -1.892    (0.733)
  ps  8   [poolstack]          [ps]    -1.940    (0.725)
  st  9  Y1_pystacked  D1_pystacked    -2.077    (0.758)
  ss  9  [shortstack]          [ss]    -1.941    (0.749)
  ps  9   [poolstack]          [ps]    -2.030    (0.752)
  st 10  Y1_pystacked  D1_pystacked    -2.300    (0.714)
  ss 10  [shortstack]          [ss]    -2.231    (0.735)
  ps 10   [poolstack]          [ps]    -2.240    (0.741)
  st 11  Y1_pystacked  D1_pystacked    -1.702    (0.783)
  ss 11  [shortstack]          [ss]    -1.911    (0.763)
  ps 11   [poolstack]          [ps]    -1.951    (0.773)

Mean/med    Y learner     D learner         b        SE 
  st mn  Y1_pystacked  D1_pystacked    -2.106    (0.782)
  ss mn  [shortstack]          [ss]    -2.094    (0.774)
  ps mn   [poolstack]          [ps]    -2.122    (0.774)
  st md  Y1_pystacked  D1_pystacked    -2.160    (0.770)
  ss md  [shortstack]          [ss]    -2.108    (0.767)
  ps md   [poolstack]          [ps]    -2.142    (0.760)

Shortstack DDML model (median over 11 resamples)
y-E[y|X]  = y-Y_A198new_ss                         Number of obs   =        74
D-E[D|X]  = D-D_sd_EE_ss 
------------------------------------------------------------------------------
             |               Robust
     A198new | Coefficient  std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
       sd_EE |  -2.108401   .7674987    -2.75   0.006    -3.612671   -.6041314
------------------------------------------------------------------------------
Stacking final estimator: nnls1

Summary over 11 resamples:
       D eqn      mean       min       p25       p50       p75       max
       sd_EE     -2.0937   -2.3256   -2.2521   -2.1084   -1.9105   -1.8915

. ddml estimate, spec(st) rep(md) notable replay

Median over 11 stacking resamples
y-E[y|X]  = y-Y1_pystacked                         Number of obs   =        74
D-E[D|X]  = D-D1_pystacked 
------------------------------------------------------------------------------
             |               Robust
     A198new | Coefficient  std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
       sd_EE |  -2.160377   .7700378    -2.81   0.005    -3.669624   -.6511308
------------------------------------------------------------------------------
Stacking final estimator: nnls1

Summary over 11 resamples:
       D eqn      mean       min       p25       p50       p75       max
       sd_EE     -2.1062   -2.2996   -2.2694   -2.1604   -1.9118   -1.7016

. ddml estimate, spec(ps) rep(md) notable replay

Poolstack DDML model (median over 11 resamples)
y-E[y|X]  = y-Y_A198new_ps                         Number of obs   =        74
D-E[D|X]  = D-D_sd_EE_ps 
------------------------------------------------------------------------------
             |               Robust
     A198new | Coefficient  std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
       sd_EE |  -2.142135   .7601858    -2.82   0.005    -3.632072   -.6521985
------------------------------------------------------------------------------
Stacking final estimator: nnls1

Summary over 11 resamples:
       D eqn      mean       min       p25       p50       p75       max
       sd_EE     -2.1219   -2.3657   -2.2549   -2.1421   -1.9505   -1.8655


```

</details>

The median results from the 11 DML estimations are again similar to the original G-N results. The conclusion is again that their specification is robust to dropping the linearity assumption.

Note that the variation across the 11 refits introduced by the randomization of the cross-fit split is not trivial - the DML coefficient estimates range from about -1.7 to about -2.3 - but not enough to overturn the conclusion above. Increasing the number of refits is worth considering here.

It's also still the case that there is evidence of nonlinearity:
all 3 stacking procedures tend to put a low weight on unregularized OLS.
Now the nonlinear random forest learner typically gets the biggest weight.
Again, this is evidence of some nonlinearity, but not enough to overturn the OLS-based results.

<details markdown="block">
<summary>Stata output</summary>

```
. // Display the stacking weights.
. // As before, unregularized OLS gets a low weight for both Y and D,
. // and the random forest learner gets a substantial weight in both.
. ddml extract, show(weights)

mean stacking weights across folds/resamples for Y1_pystacked (A198new)
final stacking estimator: nnls1
             learner  mean_weight        rep_1        rep_2        rep_3        rep_4        rep_5        rep_6        rep_7
    ols            1    .20945066     .1895086    .09985818    .19017306    .19589241    .28617069     .2656593    .23127083
lassocv            2    .35366375     .3562733    .36574411    .44811724    .34870471     .3043117    .26965765    .36310303
     rf            3     .4368856     .4542181    .53439771     .3617097    .45540288    .40951761    .46468305    .40562614

               rep_8        rep_9       rep_10       rep_11
    ols    .19321946    .17267348      .321406    .15812519
lassocv    .39887847    .38808662    .25554487    .39187953
     rf    .40790207     .4392399    .42304913    .44999528

mean stacking weights across folds/resamples for D1_pystacked (sd_EE)
final stacking estimator: nnls1
             learner  mean_weight        rep_1        rep_2        rep_3        rep_4        rep_5        rep_6        rep_7
    ols            1    .00672472    .02516423    .00982364    2.134e-18    .00645771    6.113e-19    .00434357    1.012e-18
lassocv            2    .32615507    .35428627    .30116975    .35093255    .30099415    .33042825    .30649567    .34408304
     rf            3    .66712021     .6205495    .68900663    .64906745    .69254814    .66957175    .68916076    .65591696

               rep_8        rep_9       rep_10       rep_11
    ols    1.789e-18    .01617726    1.873e-18    .01200553
lassocv    .32774874    .26841758    .35133847    .35181133
     rf    .67225126    .71540516    .64866153    .63618314

short-stacked weights across resamples for A198new
final stacking estimator: nnls1
             learner  mean_weight        rep_1        rep_2        rep_3        rep_4        rep_5        rep_6        rep_7
    ols            1    .27806771     .2502159     .4460415    .15316251    .68821837    6.760e-18    2.504e-18    .11566587
lassocv            2    .15543803            0    .11247025    .31531427    1.409e-18    .49763253    .31023981    .17960824
     rf            3    .56649426     .7497841    .44148825    .53152322    .31178163    .50236747    .68976019    .70472589

               rep_8        rep_9       rep_10       rep_11
    ols     .0858323    .34503221    .49642475    .47815146
lassocv    .28354987    3.687e-18            0    .01100331
     rf    .63061783    .65496779    .50357525    .51084522

short-stacked weights across resamples for sd_EE
final stacking estimator: nnls1
             learner  mean_weight        rep_1        rep_2        rep_3        rep_4        rep_5        rep_6        rep_7
    ols            1    1.359e-18            0    3.903e-18            0    1.887e-18    3.469e-18    2.692e-18    3.000e-18
lassocv            2    .33170231    .37136171     .3452035    .32768059    .27627498    .32830873    .38245887    .40774357
     rf            3    .66829769    .62863829     .6547965    .67231941    .72372502    .67169127    .61754113    .59225643

               rep_8        rep_9       rep_10       rep_11
    ols            0            0            0            0
lassocv    .37568257    .26729688    .30843851    .25827548
     rf    .62431743    .73270312    .69156149    .74172452

pool-stacked weights across resamples for A198new
final stacking estimator: nnls1
             learner  mean_weight        rep_1        rep_2        rep_3        rep_4        rep_5        rep_6        rep_7
    ols            1     .0882426    5.910e-18    3.253e-19    .04188493    .02999945    .07251774      .355264    .18943572
lassocv            2    .45341228    .50761667    .45857367    .55908989    .49095177    .49668769    .15541324    .38446623
     rf            3    .45834511    .49238333    .54142633    .39902518    .47904879    .43079456    .48932277    .42609805

               rep_8        rep_9       rep_10       rep_11
    ols    1.613e-18    .08744457    .19412219    3.844e-18
lassocv    .57457416    .44844654    .37994551    .53176977
     rf    .42542584     .4641089     .4259323    .46823023

pool-stacked weights across resamples for sd_EE
final stacking estimator: nnls1
             learner  mean_weight        rep_1        rep_2        rep_3        rep_4        rep_5        rep_6        rep_7
    ols            1    2.496e-18    1.681e-18            0            0    2.412e-18            0            0    3.470e-18
lassocv            2    .33309237    .37621197    .31351971    .35642509    .30378299    .32386649    .31441793    .34445249
     rf            3    .66690763    .62378803    .68648029    .64357491    .69621701    .67613351    .68558207    .65554751

               rep_8        rep_9       rep_10       rep_11
    ols    6.539e-18            0            0    1.336e-17
lassocv     .3286361    .28624261    .35260303    .36385763
     rf     .6713639    .71375739    .64739697    .63614237

```

</details>
