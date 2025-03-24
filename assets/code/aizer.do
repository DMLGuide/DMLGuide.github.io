
cd "/Users/kahrens/MyProjects/DMLGuide.github.io/assets"

use dta/MP_data, replace
keep if nmatches==1 

set seed 42

*** define variable globals
global mom "divorced husbandaway marst_miss"
global kid "childageyears length_name sib2-sib8  maxage minage"
global county10 "sei_mean sei_sd p_urban p_widows children_singlemom poverty fem_lfp child_labor val_farm"
global countyd "CID2-CID75"
global match "datemiss"
global state "S2-S11"
global state_year "manwrat ageent labage contschl gen_total char_tot tot_edu_schools work_required limited_duration  monthlyallowfirstchild monthlyallowaddchild"
global state_year2 "manwrat ageent labage contschl gen_total char_tot tot_edu_schools  work_required limited_duration  monthlyallowfirstchild monthlyallowaddchild"
global cohort "yob1 yob2"
global cohortd "BY2-BY26"
global det "year yob childageyears datemiss numkids  maxage minage length_name widow divorced husbandaway marst_miss famearn miss nmatches keepssn ageatdeath2 logageatdeath"
global det2 "year yob childageyears datemiss numkids  maxage minage length_name widow divorced husbandaway marst_miss famearn miss nmatches"
global X1 $state $cohortd 
global X2 $kid  $mom  $match $county10 $state_year $cohortd
global X3 $kid  $mom  $match $countyd $state_year $cohortd
global Xall $state $cohortd   $kid  $mom  $match $county10 $countyd  $state_year $cohortd

**** replication of Table 4, Panel 1, col 1-3

/*

We re-examine the analysis of Aizer at al (AER, 2016) and estimate the effect 
of a cash transfer paid out to mothers in the US over 1911--1935 on children's 
long-term education, health, and economic outcomes. 

We focus on children's longevity for this demonstration.

The sample includes 7860 children. For identification, the authors use 
families who applied for the transfer but were rejected as the control 
group and estimate the effect of longevity using linear regression with a 
battery of controls, including mother and children characteristics, 
application year, cohort and county fixed effects 
(between 34 and 61 controls in total).

*/ 

eststo m1: ///
reg logageatdeath accepted $state $cohortd , cluster(fips) 
 
eststo m2: ///
reg logageatdeath accepted $kid $mom $match $county10 $state_year $cohortd, cluster(fips) 

eststo m3: ///
reg logageatdeath accepted $kid $mom $match $countyd $state_year $cohortd, cluster(fips) 

esttab m1 m2 m3  , keep(accepted)



*** Sloczynski, see Table 2

/*

Sloczynski (ReStat 2022) re-examines the same analysis and argues that 
the OLS estimate is a poor proxy for the average treatment effect (ATE) since 
the OLS estimate is biased towards the average treatment effect on the 
\emph{un}treated (ATEU). As a solution, \citet{sloczynski2022} propose to 
decompose the OLS estimate into the average treatment effect on the treated 
(ATET) and the ATEU. The decomposition, however, assumes that the CEFs 
are linear. 


 
eststo slo_1: ///
bootstrap e(ate) e(att) e(atu),  reps(100) seed(123456789): ///
	hettreatreg $state $cohortd, o(logageatdeath) t(accepted) noisily 
 
eststo slo_2: /// 
bootstrap e(ate) e(att) e(atu) ,  reps(100) seed(123456789): ///
	hettreatreg $kid  $mom  $match $county10 $state_year $cohortd, o(logageatdeath) t(accepted) noisily 
 
eststo slo_3: /// 
bootstrap e(ate) e(att) e(atu) ,  reps(100) seed(123456789): ///
	hettreatreg $kid  $mom  $match $countyd $state_year $cohortd, o(logageatdeath) t(accepted) noisily 
*/

	
*** ddml: specify candidate learners
 
global rflow max_depth(10) max_features(sqrt) n_estimators(500)
global rfmid max_depth(6) max_features(sqrt) n_estimators(500)
global rfhigh max_depth(2) max_features(sqrt) n_estimators(500)
global gradlow max_depth(3) n_estimators(1000) learning_rate(0.3) validation_fraction(0.2) n_iter_no_change(5) tol(0.01)
global gradmid max_depth(3) n_estimators(1000) learning_rate(0.1) validation_fraction(0.2) n_iter_no_change(5) tol(0.01)
global gradhigh max_depth(3) n_estimators(1000) learning_rate(0.01) validation_fraction(0.2) n_iter_no_change(5) tol(0.01)
global nnetopt hidden_layer_sizes(20 20)


*** ddml: partially linear model

set seed 123568
ddml init partial, kfolds(2) // fcluster(fips) // kfolds(10) fcluster(fips) reps(5)
ddml E[Y|X]: pystacked logageatdeath $Xall 			|| ///
						m(ols) xvars($X1)    		|| ///
						m(ols) xvars($X2)    		|| ///
						m(ols) xvars($X3) 			|| ///
						m(lassocv)   				|| ///
						m(ridgecv )   				|| ///
						m(rf) opt($rflow) 			|| ///
						m(rf) opt($rfmid) 			|| ///
						m(rf) opt($rfhigh) 			|| ///
						m(gradboost) opt($gradlow) 	|| ///
						m(gradboost) opt($gradmid) 	|| ///
						m(gradboost) opt($gradhigh) || ///
						, njobs(8)
ddml E[D|X]: pystacked accepted $Xall || ///
						m(logit) xvars($X1) 		|| ///
						m(logit) xvars($X2) 		|| ///
						m(logit) xvars($X3) 		|| ///
						m(lassocv)   				|| ///
						m(ridgecv )  				|| ///
						m(rf) opt($rflow) 			|| ///
						m(rf) opt($rfmid) 			|| ///
						m(rf) opt($rfhigh) 			|| ///
						m(gradboost) opt($gradlow) 	|| ///
						m(gradboost) opt($gradmid) 	|| ///
						m(gradboost) opt($gradhigh) || ///
						, njobs(8) type(class)
ddml crossfit
eststo d1: ///
ddml estimate, vce(cluster fips)
ddml extract, show(pystacked)
ddml drop


*** ddml: partially linear model

set seed 123568
ddml init partial, kfolds(2) fcluster(fips) // kfolds(10) fcluster(fips) reps(5)
ddml E[Y|X]: pystacked logageatdeath $Xall 			|| ///
						m(ols) xvars($X1)    		|| ///
						m(ols) xvars($X2)    		|| ///
						m(ols) xvars($X3) 			|| ///
						m(lassocv)   				|| ///
						m(ridgecv )   				|| ///
						m(rf) opt($rflow) 			|| ///
						m(rf) opt($rfmid) 			|| ///
						m(rf) opt($rfhigh) 			|| ///
						m(gradboost) opt($gradlow) 	|| ///
						m(gradboost) opt($gradmid) 	|| ///
						m(gradboost) opt($gradhigh) || ///
						, njobs(8)
ddml E[D|X]: pystacked accepted $Xall || ///
						m(logit) xvars($X1) 		|| ///
						m(logit) xvars($X2) 		|| ///
						m(logit) xvars($X3) 		|| ///
						m(lassocv)   				|| ///
						m(ridgecv )  				|| ///
						m(rf) opt($rflow) 			|| ///
						m(rf) opt($rfmid) 			|| ///
						m(rf) opt($rfhigh) 			|| ///
						m(gradboost) opt($gradlow) 	|| ///
						m(gradboost) opt($gradmid) 	|| ///
						m(gradboost) opt($gradhigh) || ///
						, njobs(8) type(class)
ddml crossfit
eststo d2: ///
ddml estimate, vce(cluster fips)
ddml extract, show(pystacked)
ddml drop



*** ddml: interactive model

ddml init interactive, kfolds(2) // kfolds(10) fcluster(fips) reps(5)
ddml E[Y|X,D]: pystacked logageatdeath $Xall 		|| ///
						m(ols) xvars($X1)    		|| ///
						m(ols) xvars($X2)    		|| ///
						m(ols) xvars($X3) 			|| ///
						m(lassocv)   				|| ///
						m(ridgecv )   				|| ///
						m(rf) opt($rflow) 			|| ///
						m(rf) opt($rfmid) 			|| ///
						m(rf) opt($rfhigh) 			|| ///
						m(gradboost) opt($gradlow) 	|| ///
						m(gradboost) opt($gradmid) 	|| ///
						m(gradboost) opt($gradhigh) || ///
						, njobs(8)
ddml E[D|X]: pystacked accepted $Xall 				|| ///
						m(logit) xvars($X1) 		|| ///
						m(logit) xvars($X2) 		|| ///
						m(logit) xvars($X3) 		|| ///
						m(lassocv)   				|| ///
						m(ridgecv )  				|| ///
						m(rf) opt($rflow) 			|| ///
						m(rf) opt($rfmid) 			|| ///
						m(rf) opt($rfhigh) 			|| ///
						m(gradboost) opt($gradlow) 	|| ///
						m(gradboost) opt($gradmid) 	|| ///
						m(gradboost) opt($gradhigh) || ///
						, njobs(8) type(class)
ddml crossfit
eststo d3: ///
ddml estimate, vce(cluster fips) atet
ddml extract, show(pystacked)
ddml drop
