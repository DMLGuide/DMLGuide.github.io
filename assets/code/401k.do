clear all

cap cd /Users/kahrens/MyProjects/DMLGuide.github.io/assets

cap log close
log using "logs/example_401k.txt", replace text

which ddml

set seed 123

use "https://dmlguide.github.io/assets/dta/PVW_data.dta", clear 

global Y net_tfa
global X age tw inc fsize db marr twoearn pira hown
global D p401
global Z e401

*** partial regression coefficient 
ddml init partial, kfolds(10)
ddml E[Y|X]: pystacked $Y $X , type(reg) methods(rf) cmdopt1(n_estimators(1000) max_depth(8))
ddml E[D|X]: pystacked $Z $X , type(reg) methods(rf) cmdopt1(n_estimators(1000) max_depth(4))
ddml crossfit
eststo m1: ///
ddml estimate, robust

*** ATE coefficient
ddml init partial, kfolds(10)
ddml E[Y|X]: pystacked $Y $X , type(reg) methods(rf) cmdopt1(n_estimators(1000) max_depth(8))
ddml E[D|X]: pystacked $Z $X , type(reg) methods(rf) cmdopt1(n_estimators(1000) max_depth(4))
ddml crossfit
eststo m2: ///
ddml estimate, robust

esttab m1 m2

*** partial IV regression coefficient 
ddml init iv, kfolds(10)
ddml E[Y|X]: pystacked $Y $X , type(reg) methods(rf) cmdopt1(n_estimators(1000) max_depth(8))
ddml E[D|X]: pystacked $D $X , type(reg) methods(rf) cmdopt1(n_estimators(1000) max_depth(4))
ddml E[Z|X]: pystacked $Z $X , type(reg) methods(rf) cmdopt1(n_estimators(1000) max_depth(4))
ddml crossfit
eststo m3: ///
ddml estimate, robust

*** LATE coefficient
ddml init interactiveiv, kfolds(10)
ddml E[Y|X,Z]: pystacked $Y $X , type(reg) methods(rf) cmdopt1(n_estimators(1000) max_depth(8))
ddml E[D|X,Z]: pystacked $D $X , type(reg) methods(rf) cmdopt1(n_estimators(1000) max_depth(4))
ddml E[Z|X]: pystacked $Z $X , type(reg) methods(rf) cmdopt1(n_estimators(1000) max_depth(4))
ddml crossfit
eststo m4: ///
ddml estimate, robust

esttab m3 m4

cap log close
