// =========================
// 401(k) replication in Stata
//  Using the ddml package (with pystacked random forest learners)
//
// Each `// @snippet:NAME ... // @end` block is extracted by
// `_401k/build_snippets.py` into `_includes/401k/NAME_stata.txt`
// and imported by `examples/401k.md` via Liquid.

clear all
set more off
set seed 20241111


// =============================================================
// (1) Data preparation
// =============================================================

// @snippet:data_code
clear all
set more off
set seed 20241111

use "https://dmlguide.github.io/assets/dta/PVW_data.dta", clear

global Y net_tfa
global X age tw inc fsize db marr twoearn pira hown
global D p401
global Z e401
// @end


// =============================================================
// (2) Learner settings
// =============================================================

// @snippet:learner_code
// Random forest with 1000 trees: depth 8 for the outcome equation,
// depth 4 for the remaining nuisance functions.
global rfoutcome n_estimators(1000) max_depth(8)
global rfother   n_estimators(1000) max_depth(4)
// @end


// =============================================================
// (3) The effect of 401(k) eligibility — PLR + ATE
// =============================================================

// @snippet:elig_code
// PLR: partially linear regression coefficient
ddml init partial, kfolds(10)
ddml E[Y|X]: pystacked $Y $X , type(reg) methods(rf) cmdopt1($rfoutcome)
ddml E[D|X]: pystacked $Z $X , type(reg) methods(rf) cmdopt1($rfother)
ddml crossfit
eststo m_plr: ddml estimate, robust

// ATE: average treatment effect (interactive model)
ddml init interactive, kfolds(10)
ddml E[Y|X,D]: pystacked $Y $X , type(reg)   methods(rf) cmdopt1($rfoutcome)
ddml E[D|X]:   pystacked $Z $X , type(class) methods(rf) cmdopt1($rfother)
ddml crossfit
eststo m_ate: ddml estimate, robust trim(0.001)

display "###BEGIN_OUT:elig_out###"
esttab m_plr m_ate, mtitles("PLR" "ATE") ///
    b(%9.2f) se(%9.2f) star(* 0.05 ** 0.01 *** 0.001) ///
    stats(N, fmt(%9.0f) labels("Num. obs."))
display "###END_OUT:elig_out###"
// @end


// =============================================================
// (4) The effect of 401(k) participation — PLIV + LATE
// =============================================================

// @snippet:part_code
// PLIV: partially linear IV regression coefficient
ddml init iv, kfolds(10)
ddml E[Y|X]: pystacked $Y $X , type(reg) methods(rf) cmdopt1($rfoutcome)
ddml E[D|X]: pystacked $D $X , type(reg) methods(rf) cmdopt1($rfother)
ddml E[Z|X]: pystacked $Z $X , type(reg) methods(rf) cmdopt1($rfother)
ddml crossfit
eststo m_pliv: ddml estimate, robust

// LATE: local average treatment effect (interactive IV model)
ddml init interactiveiv, kfolds(10)
ddml E[Y|X,Z]: pystacked $Y $X , type(reg)   methods(rf) cmdopt1($rfoutcome)
ddml E[D|X,Z]: pystacked $D $X , type(class) methods(rf) cmdopt1($rfother)
ddml E[Z|X]:   pystacked $Z $X , type(class) methods(rf) cmdopt1($rfother)
ddml crossfit
eststo m_late: ddml estimate, robust trim(0.001)

display "###BEGIN_OUT:part_out###"
esttab m_pliv m_late, mtitles("PLIV" "LATE") ///
    b(%9.2f) se(%9.2f) star(* 0.05 ** 0.01 *** 0.001) ///
    stats(N, fmt(%9.0f) labels("Num. obs."))
display "###END_OUT:part_out###"
// @end


di ""
di "========================================"
di "401(k) replication complete!"
