# =========================
# 401(k) replication in Python
#  Using the DoubleML package
#
# Each `# @snippet:NAME ... # @end` block is extracted by
# `_401k/build_snippets.py` into `_includes/401k/NAME_python.txt`
# and imported by `examples/401k.md` via Liquid.
#
# Running this script also writes Python/PVW_ddml_output.txt with
# `# @snippet:NAME ... # @end` blocks for the printed outputs that the
# blog imports as the "Output" tab.

import sys, io
from contextlib import redirect_stdout
from pathlib import Path

print("Python version:", sys.version)


# =============================================================
# (1) Data preparation
# =============================================================

# @snippet:data_code
import numpy as np
import pandas as pd
from doubleml import (DoubleMLData, DoubleMLPLR, DoubleMLIRM,
                      DoubleMLPLIV, DoubleMLIIVM)
from sklearn.ensemble import RandomForestRegressor, RandomForestClassifier
from sklearn.base import clone

dat = pd.read_stata("https://dmlguide.github.io/assets/dta/PVW_data.dta")

np.random.seed(20241111)

# Define control variables
control_names = ["age", "tw", "inc", "fsize", "db", "marr",
                 "twoearn", "pira", "hown"]
# @end


# =============================================================
# (2) Learner settings
# =============================================================

# @snippet:learner_code
# Random forest with 1000 trees: depth 8 for the outcome equation,
# depth 4 for the remaining nuisance functions. We use regressors for
# continuous targets and classifiers for the binary treatment / instrument.
ml_outcome_reg = RandomForestRegressor(n_estimators=1000, max_depth=8,
                                       random_state=20241111, n_jobs=-1)
ml_other_reg   = RandomForestRegressor(n_estimators=1000, max_depth=4,
                                       random_state=20241111, n_jobs=-1)
ml_other_cls   = RandomForestClassifier(n_estimators=1000, max_depth=4,
                                        random_state=20241111, n_jobs=-1)
# @end


# =============================================================
# (3) The effect of 401(k) eligibility — PLR + ATE
# =============================================================

# @snippet:elig_code
# Build the DoubleMLData object (treatment = e401)
dml_data_e = DoubleMLData(dat, y_col="net_tfa", d_cols="e401",
                          x_cols=control_names)

# PLR: partially linear regression coefficient
plr_fit = DoubleMLPLR(dml_data_e,
                      ml_l=clone(ml_outcome_reg),
                      ml_m=clone(ml_other_reg),
                      n_folds=10)
plr_fit.fit()

# ATE: average treatment effect (interactive regression model)
irm_fit = DoubleMLIRM(dml_data_e,
                      ml_g=clone(ml_outcome_reg),
                      ml_m=clone(ml_other_cls),
                      n_folds=10,
                      trimming_threshold=0.001)
irm_fit.fit()

# Side-by-side comparison of the two estimands
def compare(fits, labels, row_label, n_obs):
    fmt = lambda x: f"{x:>12.2f}"
    rows = [
        f"{row_label:<14}" + "".join(f"{l:>12}" for l in labels),
        f"  estimate   " + "".join(fmt(f.coef[0])    for f in fits),
        f"  (SE)       " + "".join(fmt(f.se[0])      for f in fits),
        f"  p-value    " + "".join(fmt(f.pval[0])    for f in fits),
        f"  Num. obs.  " + "".join(f"{n_obs:>12d}"   for _ in fits),
    ]
    return "\n".join(rows)

print(compare([plr_fit, irm_fit], ["PLR", "ATE"],
              "eligibility", dml_data_e.n_obs))
# @end


# =============================================================
# (4) The effect of 401(k) participation — PLIV + LATE
# =============================================================

# @snippet:part_code
# Build the DoubleMLData object with e401 as instrument for p401
dml_data_p = DoubleMLData(dat, y_col="net_tfa", d_cols="p401",
                          z_cols="e401", x_cols=control_names)

# PLIV: partially linear IV regression coefficient
pliv_fit = DoubleMLPLIV(dml_data_p,
                        ml_l=clone(ml_outcome_reg),
                        ml_m=clone(ml_other_reg),
                        ml_r=clone(ml_other_reg),
                        n_folds=10)
pliv_fit.fit()

# LATE: local average treatment effect (interactive IV model)
iivm_fit = DoubleMLIIVM(dml_data_p,
                        ml_g=clone(ml_outcome_reg),
                        ml_m=clone(ml_other_cls),
                        ml_r=clone(ml_other_cls),
                        n_folds=10,
                        trimming_threshold=0.001)
iivm_fit.fit()

print(compare([pliv_fit, iivm_fit], ["PLIV", "LATE"],
              "participation", dml_data_p.n_obs))
# @end


# =============================================================
# Persist the captured outputs to the snippet file.
# =============================================================

outfile = Path(__file__).resolve().parent / "PVW_ddml_output.txt"

elig_buf = io.StringIO()
with redirect_stdout(elig_buf):
    print(compare([plr_fit, irm_fit], ["PLR", "ATE"],
                  "eligibility", dml_data_e.n_obs))

part_buf = io.StringIO()
with redirect_stdout(part_buf):
    print(compare([pliv_fit, iivm_fit], ["PLIV", "LATE"],
                  "participation", dml_data_p.n_obs))

outfile.write_text("\n".join([
    "# Outputs produced by PVW_ddml.py.",
    "# `# @snippet:NAME ... # @end` blocks are imported by examples/401k.md via",
    "# _includes/401k/ -- keep these in sync with the .py script when re-running.",
    "",
    "",
    "# @snippet:elig_out",
    elig_buf.getvalue().rstrip(),
    "# @end",
    "",
    "",
    "# @snippet:part_out",
    part_buf.getvalue().rstrip(),
    "# @end",
    "",
]))

print("\n========================================")
print("401(k) replication complete!")
print(f"Wrote {outfile}")
