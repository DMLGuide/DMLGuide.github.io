# =========================
# GN Full Replication (Python)
# "By-hand" DDML approach


# Version information
import sys
import numpy as np
import pandas as pd
import statsmodels.api as sm
import sklearn
import scipy

from sklearn.linear_model import LinearRegression, LassoCV
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import StandardScaler
from scipy.optimize import minimize

import matplotlib.pyplot as plt

print("Python version:", sys.version)
print("numpy version:", np.__version__)
print("pandas version:", pd.__version__)
print("statsmodels version:", sm.__version__)
print("sklearn version:", sklearn.__version__)
print("scipy version:", scipy.__version__)


# =============================================================
# NNLS helper: constrained non-negative least squares
# Minimizes ||P @ b - y|| (L2 norm) subject to:
#   sum(b) = 1  (equality constraint)
#   0 <= b <= 1 (bounds)
# Uses scipy.optimize.minimize with method='SLSQP', exactly as in
# Multiple starting points used to avoid local optima / convergence failures.

def nnls_constrained(P, y):
    xdim = P.shape[1]

    # Objective: L2 norm ||P @ b - y|| (matching np.linalg.norm)
    def fn(coef, P, y):
        return np.linalg.norm(P.dot(coef) - y)

    # Constraints and bounds
    cons   = {'type': 'eq', 'fun': lambda coef: np.sum(coef) - 1}
    bounds = [[0.0, 1.0] for _ in range(xdim)]


    # This avoids convergence failures when prediction matrices are nearly collinear
    starts = [np.ones(xdim) / xdim]          # uniform (same as Python's np.ones / flatten)
    starts += [np.eye(xdim)[i] for i in range(xdim)]  # corner starts

    best_val = np.inf
    best_par = np.ones(xdim) / xdim

    for coef0 in starts:
        fit = minimize(
            fn, coef0, args=(P, y),
            method='SLSQP',
            bounds=bounds,
            constraints=cons
        )
        if fit.fun < best_val:
            best_val = fit.fun
            best_par = fit.x

    # Clip to [0,1] and renormalise for numerical safety
    b = np.clip(best_par, 0.0, 1.0)
    return b / b.sum()


# =============================================================
# PART 1: OLS replication


# Load data
gn = pd.read_stata("https://dmlguide.github.io/assets/dta/GN2021.dta")

# Shorten the name of the causal variable of interest to sd_EE
gn["sd_EE"] = gn["sd_of_gen_mean_temp_anom_EE"]

# Replicate results with no controls in Table 1, column (3). HC1 robust SE
model_simple_X = sm.add_constant(gn[["sd_EE"]], has_constant="add")
model_simple_y = gn["A198new"].astype(float)

model_simple        = sm.OLS(model_simple_y, model_simple_X).fit()
model_simple_robust = model_simple.get_robustcov_results(cov_type="HC1")

print("\nPART 1: OLS (A198new ~ sd_EE) with HC1 robust SE\n")
print(model_simple_robust.summary())

# Figure 5
gn["hat"] = model_simple.predict(model_simple_X)

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


# =============================================================
# PART 2: DML robustness check (single 10-fold shortstack)


# In the G-N estimations, GDP is missing for one country.
# For simplicity, we just drop this one country so that it is never used.
gn = gn.dropna(subset=["loggdp"]).copy()

# To make the code more readable, define locals for Y, D and X:
Y_var  = "A198new"
D_var  = "sd_EE"
X_vars = ["v104_ee", "settlement_ee", "polhierarchies_ee", "loggdp"]

Y = gn[Y_var].to_numpy(dtype=float)
D = gn[D_var].to_numpy(dtype=float)
X = gn[X_vars].to_numpy(dtype=float)

n = X.shape[0]
K = 10

# Step 1: Specify the model.
# Partially-linear model with 10-fold cross-fitting and a single cross-fit split.

# Create 10-fold split
np.random.seed(12345)
fold_id = np.random.permutation(
    np.repeat(np.arange(1, K + 1), int(np.ceil(n / K)))
)[:n]

# Storage for out-of-sample (cross-fitted) predictions
Y_hat_ols   = np.full(n, np.nan)
Y_hat_lasso = np.full(n, np.nan)
Y_hat_rf    = np.full(n, np.nan)

D_hat_ols   = np.full(n, np.nan)
D_hat_lasso = np.full(n, np.nan)
D_hat_rf    = np.full(n, np.nan)

# Step 2: Choose the learners.
# Unregularized OLS, cross-validated lasso, and random forest.
# Note: lasso pipeline is instantiated fresh inside each fold to avoid data leakage.

for k in range(1, K + 1):
    idx_train = np.where(fold_id != k)[0]
    idx_test  = np.where(fold_id == k)[0]

    X_train = X[idx_train, :]
    X_test  = X[idx_test,  :]
    Y_train = Y[idx_train]
    D_train = D[idx_train]

    # Learners for E[Y|X]

    # OLS
    fit_ols_Y = LinearRegression()
    fit_ols_Y.fit(X_train, Y_train)
    Y_hat_ols[idx_test] = fit_ols_Y.predict(X_test)

    # Lasso (cross-validated) - fresh pipeline each fold to avoid leakage
    scaler_Y      = StandardScaler()
    X_train_sc_Y  = scaler_Y.fit_transform(X_train)
    X_test_sc_Y   = scaler_Y.transform(X_test)
    fit_lasso_Y   = LassoCV(cv=5, max_iter=100000)
    fit_lasso_Y.fit(X_train_sc_Y, Y_train)
    Y_hat_lasso[idx_test] = fit_lasso_Y.predict(X_test_sc_Y)

    # Random forest
    fit_rf_Y = RandomForestRegressor(n_estimators=500, min_samples_leaf=5)
    fit_rf_Y.fit(X_train, Y_train)
    Y_hat_rf[idx_test] = fit_rf_Y.predict(X_test)

    # Learners for E[D|X]

    # OLS
    fit_ols_D = LinearRegression()
    fit_ols_D.fit(X_train, D_train)
    D_hat_ols[idx_test] = fit_ols_D.predict(X_test)

    # Lasso (cross-validated) - fresh pipeline each fold
    scaler_D      = StandardScaler()
    X_train_sc_D  = scaler_D.fit_transform(X_train)
    X_test_sc_D   = scaler_D.transform(X_test)
    fit_lasso_D   = LassoCV(cv=5, max_iter=100000)
    fit_lasso_D.fit(X_train_sc_D, D_train)
    D_hat_lasso[idx_test] = fit_lasso_D.predict(X_test_sc_D)

    # Random forest
    fit_rf_D = RandomForestRegressor(n_estimators=500, min_samples_leaf=5)
    fit_rf_D.fit(X_train, D_train)
    D_hat_rf[idx_test] = fit_rf_D.predict(X_test)

# Check that predictions are complete
assert np.all(np.isfinite(Y_hat_ols))
assert np.all(np.isfinite(Y_hat_lasso))
assert np.all(np.isfinite(Y_hat_rf))
assert np.all(np.isfinite(D_hat_ols))
assert np.all(np.isfinite(D_hat_lasso))
assert np.all(np.isfinite(D_hat_rf))

# Step 3: Short-stacking via constrained NNLS.
# Weights are non-negative and sum to 1.
# minimizes ||P @ b - y|| subject to sum(b)=1 and 0 <= b <= 1.

PY = np.column_stack([Y_hat_ols, Y_hat_lasso, Y_hat_rf])
PD = np.column_stack([D_hat_ols, D_hat_lasso, D_hat_rf])

# Short-stack weights for Y
w_Y = nnls_constrained(PY, Y)

# Short-stack weights for D
w_D = nnls_constrained(PD, D)

# Short-stacked conditional expectations
Y_hat_ss = PY @ w_Y
D_hat_ss = PD @ w_D

# Step 4: PLM estimation (residualised Y on residualised D)
Y_tilde = Y - Y_hat_ss
D_tilde = D - D_hat_ss

X_reg           = sm.add_constant(D_tilde, has_constant="add")
dml_model       = sm.OLS(Y_tilde, X_reg).fit()
vcov_dml_robust = dml_model.get_robustcov_results(cov_type="HC1")

print("\nPART 2: DML shortstack (single split), HC1 robust SE\n")
print(vcov_dml_robust.summary())

learners = ["ols", "lassocv", "rf"]

print("\nshort-stacked weights across resamples for A198new\n")
for name, w in zip(learners, w_Y):
    print(f"{name:7s}  mean_weight={w:.6f}  rep_1={w:.6f}")

print("\nshort-stacked weights across resamples for sd_EE\n")
for name, w in zip(learners, w_D):
    print(f"{name:7s}  mean_weight={w:.6f}  rep_1={w:.6f}")


# =============================================================
# PART 3: Final DML model (11 resamples, median aggregation)


# Step 1: Set seed for replicability
np.random.seed(42)

K = 10
R = 11

coef_vec  = np.zeros(R)
se_vec    = np.zeros(R)

weights_Y = np.zeros((3, R))
weights_D = np.zeros((3, R))

# Step 2: 11 separate cross-fit splits, 10-fold each
for r in range(R):

    print(f"Processing resample {r+1} of {R}...")

    fold_id = np.random.permutation(
        np.repeat(np.arange(1, K + 1), int(np.ceil(n / K)))
    )[:n]

    Y_hat_ols   = np.full(n, np.nan)
    Y_hat_lasso = np.full(n, np.nan)
    Y_hat_rf    = np.full(n, np.nan)

    D_hat_ols   = np.full(n, np.nan)
    D_hat_lasso = np.full(n, np.nan)
    D_hat_rf    = np.full(n, np.nan)

    for k in range(1, K + 1):
        idx_train = np.where(fold_id != k)[0]
        idx_test  = np.where(fold_id == k)[0]

        X_train = X[idx_train, :]
        X_test  = X[idx_test,  :]
        Y_train = Y[idx_train]
        D_train = D[idx_train]

        # E[Y|X]
        fit_ols_Y = LinearRegression()
        fit_ols_Y.fit(X_train, Y_train)
        Y_hat_ols[idx_test] = fit_ols_Y.predict(X_test)

        scaler_Y     = StandardScaler()
        X_train_sc_Y = scaler_Y.fit_transform(X_train)
        X_test_sc_Y  = scaler_Y.transform(X_test)
        fit_lasso_Y  = LassoCV(cv=5, max_iter=100000)
        fit_lasso_Y.fit(X_train_sc_Y, Y_train)
        Y_hat_lasso[idx_test] = fit_lasso_Y.predict(X_test_sc_Y)

        fit_rf_Y = RandomForestRegressor(n_estimators=500, min_samples_leaf=5)
        fit_rf_Y.fit(X_train, Y_train)
        Y_hat_rf[idx_test] = fit_rf_Y.predict(X_test)

        # E[D|X]
        fit_ols_D = LinearRegression()
        fit_ols_D.fit(X_train, D_train)
        D_hat_ols[idx_test] = fit_ols_D.predict(X_test)

        scaler_D     = StandardScaler()
        X_train_sc_D = scaler_D.fit_transform(X_train)
        X_test_sc_D  = scaler_D.transform(X_test)
        fit_lasso_D  = LassoCV(cv=5, max_iter=100000)
        fit_lasso_D.fit(X_train_sc_D, D_train)
        D_hat_lasso[idx_test] = fit_lasso_D.predict(X_test_sc_D)

        fit_rf_D = RandomForestRegressor(n_estimators=500, min_samples_leaf=5)
        fit_rf_D.fit(X_train, D_train)
        D_hat_rf[idx_test] = fit_rf_D.predict(X_test)

    # Short-stacking via constrained NNLS for this rep
    PY = np.column_stack([Y_hat_ols, Y_hat_lasso, Y_hat_rf])
    PD = np.column_stack([D_hat_ols, D_hat_lasso, D_hat_rf])

    w_Y = nnls_constrained(PY, Y)
    w_D = nnls_constrained(PD, D)

    weights_Y[:, r] = w_Y
    weights_D[:, r] = w_D

    Y_hat_ss = PY @ w_Y
    D_hat_ss = PD @ w_D

    # PLM estimation for this resample
    Y_tilde = Y - Y_hat_ss
    D_tilde = D - D_hat_ss

    X_reg       = sm.add_constant(D_tilde, has_constant="add")
    dml_model_r = sm.OLS(Y_tilde, X_reg).fit()
    dml_rob_r   = dml_model_r.get_robustcov_results(cov_type="HC1")

    coef_vec[r] = dml_rob_r.params[1]
    se_vec[r]   = dml_rob_r.bse[1]

# Results across 11 resamples
results_reps = pd.DataFrame({
    "rep": np.arange(1, R + 1),
    "b":   coef_vec,
    "se":  se_vec
})

print("\nDDML shortstack results across 11 resamples (Python analogue of ss 1..11):\n")
print(results_reps.to_string(index=False))

# Step 5: Median aggregation
b_med  = float(np.median(coef_vec))

 # sigma = sqrt( Median( sigma_m^2 + (theta_m - theta_tilde)^2 ) )
se_med = float(np.sqrt(np.median(se_vec**2 + (coef_vec - b_med)**2)))

print("\nMedian aggregated short-stack results:\n")
print(f"   shortstack median  {b_med:10.7f}  {se_med:10.7f}")

print("\nMean/median aggregated short-stack results:\n")

# Summary over 11 resamples
summary_over_reps = pd.DataFrame({
    "D_eqn": ["sd_EE"],
    "mean":  [float(np.mean(coef_vec))],
    "min":   [float(np.min(coef_vec))],
    "p25":   [float(np.quantile(coef_vec, 0.25))],
    "p50":   [float(np.quantile(coef_vec, 0.50))],
    "p75":   [float(np.quantile(coef_vec, 0.75))],
    "max":   [float(np.max(coef_vec))]
})

print("\nSummary over 11 resamples:\n")
print(summary_over_reps.to_string(index=False))

# Step 6: Report stacking weights across the 11 reps
rep_names = [f"rep_{i}" for i in range(1, R + 1)]

ssweights_Y_multi = pd.DataFrame({
    "learner":     learners,
    "mean_weight": weights_Y.mean(axis=1)
})
for j, nm in enumerate(rep_names):
    ssweights_Y_multi[nm] = weights_Y[:, j]

ssweights_D_multi = pd.DataFrame({
    "learner":     learners,
    "mean_weight": weights_D.mean(axis=1)
})
for j, nm in enumerate(rep_names):
    ssweights_D_multi[nm] = weights_D[:, j]

print("\nshort-stacked weights across resamples for A198new (11 reps)\n")
print(ssweights_Y_multi.to_string(index=False))

print("\nshort-stacked weights across resamples for sd_EE (11 reps)\n")
print(ssweights_D_multi.to_string(index=False))

print("\n========================================")
print("GN replication complete!")
