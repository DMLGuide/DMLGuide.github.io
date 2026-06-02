# =========================
# GN full replication in Python
#  Hand-rolled DML (sum-to-one constrained NNLS short-stacking)
#
# `# @snippet:NAME ... # @end` blocks are extracted by
# `_GN/build_snippets.py` into `_includes/GN/NAME_python.txt`
# and imported by `examples/GN.md`.


import sys
print("Python version:", sys.version)


# =============================================================
# (1) OLS replication — Table 1, column (4)
# =============================================================

# @snippet:ols_code
import numpy as np
import pandas as pd
import statsmodels.api as sm
import matplotlib.pyplot as plt

# Load data
gn = pd.read_stata("https://dmlguide.github.io/assets/dta/GN2021.dta")

# Shorten the name of the causal variable of interest to sd_EE
gn["sd_EE"] = gn["sd_of_gen_mean_temp_anom_EE"]

# Replicate Table 1, column (4): OLS with the 4 controls, HC1 robust SE.
# Drop the country with missing loggdp (N goes from 75 to 74).
gn_full = gn.dropna(subset=["loggdp"]).copy()
controls = ["v104_ee", "settlement_ee", "polhierarchies_ee", "loggdp"]

X_full = sm.add_constant(gn_full[["sd_EE"] + controls], has_constant="add")
y_full = gn_full["A198new"].astype(float)

model_full        = sm.OLS(y_full, X_full).fit()
model_full_robust = model_full.get_robustcov_results(cov_type="HC1")

print(model_full_robust.summary())
# @end


# =============================================================
# (2) Figure 5 — bivariate scatter (column 3)
# =============================================================

# @snippet:fig5_code
# Figure 5 visualises the bivariate (no-controls) relationship — column (3).
X_bi = sm.add_constant(gn[["sd_EE"]], has_constant="add")
model_bivariate = sm.OLS(gn["A198new"].astype(float), X_bi).fit()
gn["hat"] = model_bivariate.predict(X_bi)

fig, ax = plt.subplots(figsize=(7, 5))
ax.scatter(gn["sd_EE"], gn["A198new"], s=30)

for _, row in gn.iterrows():
    ax.text(row["sd_EE"], row["A198new"], str(row["isocode"]),
            fontsize=8, va="bottom", ha="center")

tmp = gn.sort_values("sd_EE")
ax.plot(tmp["sd_EE"], tmp["hat"], linewidth=2)

ax.set_xlim(0, 0.5)
ax.set_xticks([0, 0.25, 0.5])
ax.set_ylim(2.8, 6.0)
ax.set_yticks([3, 4, 5, 6])
ax.set_xlabel("Climatic instability")
ax.set_ylabel("Importance of tradition")
ax.grid(False)
ax.text(0, 2.85, "(coef = -1.92, t = -3.68)", fontsize=10, ha="left", va="bottom")

plt.tight_layout()
plt.show()
gn = gn.drop(columns=["hat"])
# @end


# =============================================================
# (3) DML robustness check — single 10-fold split, sum-to-one NNLS
# =============================================================

# @snippet:dml_code
# DoubleML does not natively implement short-stacking, so we hand-roll
# the cross-fitting with sklearn and combine the per-learner OOF
# predictions via non-negative least squares constrained to sum to one
# (the "nnls1" stacking used by ddml / pystacked).

import numpy as np
import pandas as pd
import statsmodels.api as sm

from sklearn.linear_model import LinearRegression, LassoCV
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import KFold
from scipy.optimize import minimize


def stack_nnls1(A, b):
    """Solve min ||A w - b||^2 subject to w >= 0 and sum(w) = 1."""
    k = A.shape[1]
    res = minimize(lambda w: np.sum((A @ w - b) ** 2),
                   x0=np.full(k, 1.0 / k),
                   method="SLSQP",
                   bounds=[(0.0, 1.0)] * k,
                   constraints=[{"type": "eq", "fun": lambda w: w.sum() - 1.0}],
                   options={"ftol": 1e-12})
    return res.x


# In the GN estimations, GDP is missing for one country.
# For simplicity, we drop this one country so that it is never used.
gn = gn.dropna(subset=["loggdp"]).copy().reset_index(drop=True)

# To make the code more readable, define variables for Y, D and X:
Y_var  = "A198new"
D_var  = "sd_EE"
X_vars = ["v104_ee", "settlement_ee", "polhierarchies_ee", "loggdp"]

Y = gn[Y_var].astype(float).to_numpy()
D = gn[D_var].astype(float).to_numpy()
X = gn[X_vars].astype(float).to_numpy()

# Set seed for replicability.
np.random.seed(12345)

# Step 1: Define the three candidate learners — OLS, CV-Lasso, RandomForest.
learners = {
    "OLS":   lambda: LinearRegression(),
    "Lasso": lambda: LassoCV(cv=5, random_state=12345, max_iter=10000),
    "RF":    lambda: RandomForestRegressor(random_state=12345),
}

# Step 2: 10-fold OOF predictions, same fold split for every learner.
kf = KFold(n_splits=10, shuffle=True, random_state=12345)


def cv_predict(make_estimator, target):
    preds = np.empty_like(target, dtype=float)
    for tr, te in kf.split(X):
        est = make_estimator()
        est.fit(X[tr], target[tr])
        preds[te] = est.predict(X[te])
    return preds


Yhat = {name: cv_predict(make, Y) for name, make in learners.items()}
Dhat = {name: cv_predict(make, D) for name, make in learners.items()}

# Step 3: Short-stack via sum-to-one constrained NNLS on the OOF predictions.
Yhat_mat = np.column_stack([Yhat["OLS"], Yhat["Lasso"], Yhat["RF"]])
Dhat_mat = np.column_stack([Dhat["OLS"], Dhat["Lasso"], Dhat["RF"]])
w_Y = stack_nnls1(Yhat_mat, Y)
w_D = stack_nnls1(Dhat_mat, D)
Yhat_ss = Yhat_mat @ w_Y
Dhat_ss = Dhat_mat @ w_D

# Step 4: Estimate theta from the residualised OLS, HC1 robust SE.
resY = Y - Yhat_ss
resD = D - Dhat_ss
fit  = sm.OLS(resY, sm.add_constant(resD)).fit().get_robustcov_results(cov_type="HC1")

print(f"theta = {fit.params[1]:.4f}  (SE {fit.bse[1]:.4f})")
# @end


# =============================================================
# (4) Short-stack weights from the single-split fit
# =============================================================

# @snippet:ssw_code
# w_Y, w_D are the NNLS weights from the hand-rolled short-stack above.
print("Short-stack NNLS weights (Y eq):  "
      f"OLS={w_Y[0]:.3f}, Lasso={w_Y[1]:.3f}, RF={w_Y[2]:.3f}")
print("Short-stack NNLS weights (D eq):  "
      f"OLS={w_D[0]:.3f}, Lasso={w_D[1]:.3f}, RF={w_D[2]:.3f}")
# @end


# =============================================================
# (5) Results by learner — per-learner residual regression + scatter
# =============================================================

# @snippet:rbl_est_code
Yhat["SS"] = Yhat_mat @ w_Y
Dhat["SS"] = Dhat_mat @ w_D

resY_dict = {k: Y - Yhat[k] for k in Yhat}
resD_dict = {k: D - Dhat[k] for k in Dhat}

rows = []
for key in ["OLS", "Lasso", "RF", "SS"]:
    Xc  = sm.add_constant(resD_dict[key])
    f_k = sm.OLS(resY_dict[key], Xc).fit().get_robustcov_results(cov_type="HC1")
    rows.append({"spec": key,
                 "b": f_k.params[1], "se_d": f_k.bse[1],
                 "intercept": f_k.params[0], "se_int": f_k.bse[0]})

tbl = pd.DataFrame(rows)
print(tbl.to_string(index=False))
# @end


# @snippet:rbl_plot_code
import matplotlib.pyplot as plt

iso = gn["isocode"].to_numpy()

fig, axes = plt.subplots(2, 2, figsize=(9, 7))
panels = [
    ("OLS",   "Y and D: Unregularized OLS"),
    ("Lasso", "Y and D: Lasso"),
    ("RF",    "Y and D: Random Forest"),
    ("SS",    "Y and D: Short-stacked"),
]
for ax, (key, title) in zip(axes.flat, panels):
    rY, rD = resY_dict[key], resD_dict[key]
    ax.scatter(rD, rY, color="#1f77b4", s=14)
    for x, y, lab in zip(rD, rY, iso):
        ax.text(x, y, str(lab), color="#1f77b4",
                fontsize=7, va="bottom", ha="center")
    Xc  = sm.add_constant(rD)
    f_k = sm.OLS(rY, Xc).fit()
    xs  = np.linspace(rD.min(), rD.max(), 50)
    ax.plot(xs, f_k.params[0] + f_k.params[1] * xs,
            color="#B1004F", linewidth=1.5)
    ax.set_xlim(-0.3, 0.3); ax.set_ylim(-2, 2)
    ax.set_title(title, fontsize=10, fontweight="bold")
    ax.set_xlabel("Climatic instability", fontsize=9)
    ax.set_ylabel("Importance of tradition", fontsize=9)
    ax.grid(False)

plt.tight_layout()
plt.show()
# @end


# =============================================================
# (6) Final DML model — 11 resamples + median aggregation
# =============================================================

# @snippet:final_code
# "Final" results: 11 cross-fit splits with sum-to-one NNLS short-stacking
# (OLS + CV-Lasso + RF) inside each split, then median aggregation
# following Chernozhukov et al. (2018):
#   se_med = sqrt( median( se^2 + (theta - theta_med)^2 ) )

# Reload data for a fresh start.
gn = pd.read_stata("https://dmlguide.github.io/assets/dta/GN2021.dta")
gn["sd_EE"] = gn["sd_of_gen_mean_temp_anom_EE"]
gn = gn.dropna(subset=["loggdp"]).copy().reset_index(drop=True)

Y = gn[Y_var].astype(float).to_numpy()
D = gn[D_var].astype(float).to_numpy()
X = gn[X_vars].astype(float).to_numpy()

np.random.seed(42)
R = 11


def make_learners(seed):
    return {
        "OLS":   LinearRegression(),
        "Lasso": LassoCV(cv=5, random_state=seed, max_iter=10000),
        "RF":    RandomForestRegressor(random_state=seed),
    }


def cv_predict_full(estimator, target, kf):
    preds = np.empty_like(target, dtype=float)
    for tr, te in kf.split(X):
        est_clone = type(estimator)(**estimator.get_params())
        est_clone.fit(X[tr], target[tr])
        preds[te] = est_clone.predict(X[te])
    return preds


coef_vec = np.empty(R)
se_vec   = np.empty(R)
wY_all   = np.zeros((3, R))
wD_all   = np.zeros((3, R))

for r in range(R):
    seed_r = np.random.randint(0, 2**31 - 1)
    kf_r = KFold(n_splits=10, shuffle=True, random_state=seed_r)
    lrn  = make_learners(seed_r)

    Yhat_r = {k: cv_predict_full(est, Y, kf_r) for k, est in lrn.items()}
    Dhat_r = {k: cv_predict_full(est, D, kf_r) for k, est in lrn.items()}

    Yhat_mat = np.column_stack([Yhat_r["OLS"], Yhat_r["Lasso"], Yhat_r["RF"]])
    Dhat_mat = np.column_stack([Dhat_r["OLS"], Dhat_r["Lasso"], Dhat_r["RF"]])
    w_Y = stack_nnls1(Yhat_mat, Y)
    w_D = stack_nnls1(Dhat_mat, D)

    resY = Y - Yhat_mat @ w_Y
    resD = D - Dhat_mat @ w_D
    fit_r = sm.OLS(resY, sm.add_constant(resD)).fit().get_robustcov_results(cov_type="HC1")

    coef_vec[r] = fit_r.params[1]
    se_vec[r]   = fit_r.bse[1]
    wY_all[:, r] = w_Y
    wD_all[:, r] = w_D

# Chernozhukov median aggregation
theta_med = float(np.median(coef_vec))
se_med    = float(np.sqrt(np.median(se_vec**2 + (coef_vec - theta_med)**2)))
theta_mean, se_mean = float(np.mean(coef_vec)), float(np.mean(se_vec))

agg = pd.DataFrame({"spec": ["shortstack mean", "shortstack median"],
                    "b":    [theta_mean, theta_med],
                    "se":   [se_mean,    se_med]})
print("\nMean/median aggregated short-stack results:")
print(agg.to_string(index=False))
# @end


# =============================================================
# (7) Final stacking weights — across the 11 resamples
# =============================================================

# @snippet:fsw_code
print("\nshort-stack NNLS weights across resamples for A198new (11 reps)")
dfY = pd.DataFrame(wY_all, index=["OLS", "Lasso", "RF"],
                   columns=[f"rep_{i+1}" for i in range(R)])
dfY.insert(0, "mean_weight", wY_all.mean(axis=1))
print(dfY.to_string(float_format=lambda x: f"{x:.4f}"))

print("\nshort-stack NNLS weights across resamples for sd_EE (11 reps)")
dfD = pd.DataFrame(wD_all, index=["OLS", "Lasso", "RF"],
                   columns=[f"rep_{i+1}" for i in range(R)])
dfD.insert(0, "mean_weight", wD_all.mean(axis=1))
print(dfD.to_string(float_format=lambda x: f"{x:.4f}"))
# @end


print("\n========================================")
print("GN replication complete!")
