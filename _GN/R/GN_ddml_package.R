# =========================
# GN full replication in R
#  Using the ddml package
#
# Each `# @snippet:NAME ... # @end` block is extracted by
# `_GN/build_snippets.py` into `_includes/GN/NAME_r.txt` and imported by
# `examples/GN.md` via Liquid. Keep the snippets self-contained enough
# that they read well on their own in the blog.


# Version banner — useful when rerunning the script for the log file.
cat("R version:\n"); print(R.version.string)


# =============================================================
# (1) OLS replication — Table 1, column (4)
# =============================================================

# @snippet:ols_code
set.seed(42)

library(haven)
library(dplyr)
library(sandwich)
library(lmtest)
library(ggplot2)
library(ddml)
library(ranger)
library(glmnet)

# Load data
gn <- read_dta("https://dmlguide.github.io/assets/dta/GN2021.dta")

# Shorten the name of the causal variable of interest to sd_EE
gn$sd_EE <- gn$sd_of_gen_mean_temp_anom_EE

# Replicate Table 1, column (4): OLS with the 4 controls, HC1 robust SE.
# lm() drops the country with missing loggdp automatically (N = 74).
model_full <- lm(A198new ~ sd_EE + v104_ee + settlement_ee +
                          polhierarchies_ee + loggdp, data = gn)
coeftest(model_full, vcov = vcovHC(model_full, type = "HC1"))
# @end


# =============================================================
# (2) Figure 5 — bivariate scatter (column 3)
# =============================================================

# @snippet:fig5_code
# Figure 5 visualises the bivariate (no-controls) relationship — column (3).
model_bivariate <- lm(A198new ~ sd_EE, data = gn)
gn$hat <- fitted(model_bivariate)

p_fig5 <- ggplot(gn, aes(x = sd_EE, y = A198new, label = isocode)) +
  geom_point(color = "#1f77b4", size = 2) +
  geom_text(color = "#1f77b4", vjust = -0.6, size = 3) +
  geom_line(aes(y = hat), linewidth = 1.2, color = "#B1004F") +
  scale_x_continuous(breaks = c(0, 0.25, 0.5), limits = c(0, 0.5)) +
  scale_y_continuous(breaks = c(3, 4, 5, 6)) +
  coord_cartesian(ylim = c(2.8, 6)) +
  labs(x = "Climatic instability", y = "Importance of tradition") +
  theme_minimal() +
  theme(
    panel.grid      = element_blank(),
    legend.position = "none",
    axis.title      = element_text(size = 12),
    axis.text       = element_text(size = 10)
  ) +
  annotate("text", x = 0, y = 2.85,
           label = "(coef = -1.92, t = -3.68)", hjust = 0, size = 4)

print(p_fig5)
gn$hat <- NULL
# @end


# =============================================================
# (3) DML robustness check — single 10-fold split with short-stacking
# =============================================================

# @snippet:dml_code
# In the GN estimations, GDP is missing for one country.
# For simplicity, we just drop this one country so that it is never used.
gn <- gn |> filter(!is.na(loggdp))

# To make the code more readable, define locals for Y, D and X:
Y_var  <- "A198new"
D_var  <- "sd_EE"
X_vars <- c("v104_ee", "settlement_ee", "polhierarchies_ee", "loggdp")

# In R, we now use ddml with learners for OLS, cross-validated lasso,
# and random forest combined via short-stacking (nnls1).

# Prepare data matrices
Y <- gn[[Y_var]]
D <- gn[[D_var]]
X <- as.matrix(gn[, X_vars])

# Step 1: Specify learners for partially linear model
learners <- list(
  list(fun = ols),
  list(fun = mdl_glmnet, args = list(alpha = 1, nfolds = 5)),  # lasso (5-fold CV)
  list(fun = mdl_ranger, args = list(num.trees = 500, min.node.size = 5))
)

# Step 2: Set seed for this single split
set.seed(12345)

# Step 3: Cross-fit with short-stacking
ddml_fit <- ddml_plm(
  y             = Y,
  D             = D,
  X             = X,
  learners      = learners,
  sample_folds  = 10,
  ensemble_type = "nnls1",
  shortstack    = TRUE,
  cv_folds      = 5,
  silent        = FALSE
)

# Step 4: Estimate the partially linear model
summary(ddml_fit, type = "HC1")
# @end


# =============================================================
# (4) Short-stack weights from the single-split fit
# =============================================================

# @snippet:ssw_code
# Display short-stack weights from the single-split fit.
print(ddml_fit$ensemble_weights)
# @end


# =============================================================
# (5) Results by learner — per-learner residual regression + scatter
# =============================================================

# @snippet:rbl_est_code
# The ddml_plm fit object exposes per-learner OOF residuals via
#   fit$fitted$y_X$cf_resid_bylearner    (n x #learners)
#   fit$fitted$D1_X$cf_resid_bylearner
# and the short-stacked predictions via $cf_fitted.

Y_resids <- list(
  OLS   = ddml_fit$fitted$y_X$cf_resid_bylearner[, 1],
  Lasso = ddml_fit$fitted$y_X$cf_resid_bylearner[, 2],
  RF    = ddml_fit$fitted$y_X$cf_resid_bylearner[, 3],
  SS    = as.numeric(Y - ddml_fit$fitted$y_X$cf_fitted[, "nnls1"])
)
D_resids <- list(
  OLS   = ddml_fit$fitted$D1_X$cf_resid_bylearner[, 1],
  Lasso = ddml_fit$fitted$D1_X$cf_resid_bylearner[, 2],
  RF    = ddml_fit$fitted$D1_X$cf_resid_bylearner[, 3],
  SS    = as.numeric(D - ddml_fit$fitted$D1_X$cf_fitted[, "nnls1"])
)

# Comparison table: HC1 robust SE per learner
build_row <- function(key) {
  est <- lm(Y_resids[[key]] ~ D_resids[[key]])
  ct  <- coeftest(est, vcov = vcovHC(est, type = "HC1"))
  data.frame(
    spec      = key,
    b         = unname(ct[2, "Estimate"]),
    se_d      = unname(ct[2, "Std. Error"]),
    intercept = unname(ct[1, "Estimate"]),
    se_int    = unname(ct[1, "Std. Error"])
  )
}
tab <- do.call(rbind, lapply(c("OLS", "Lasso", "RF", "SS"), build_row))
print(tab, row.names = FALSE)
# @end


# @snippet:rbl_plot_code
library(patchwork)

iso <- gn$isocode

panel_titles <- c(OLS = "Y and D: Unregularized OLS",
                  Lasso = "Y and D: Lasso",
                  RF = "Y and D: Random Forest",
                  SS = "Y and D: Short-stacked")

make_panel <- function(key) {
  df <- data.frame(y = Y_resids[[key]], d = D_resids[[key]], iso = iso)
  est <- lm(y ~ d, data = df)
  df$hat <- fitted(est)
  ggplot(df, aes(x = d, y = y, label = iso)) +
    geom_point(color = "#1f77b4", size = 1.6) +
    geom_text(color = "#1f77b4", vjust = -0.6, size = 2.6) +
    geom_line(aes(y = hat), linewidth = 1.0, color = "#B1004F") +
    scale_x_continuous(breaks = seq(-0.3, 0.3, 0.1), limits = c(-0.3, 0.3)) +
    scale_y_continuous(breaks = seq(-2, 2, 1), limits = c(-2, 2)) +
    labs(title = panel_titles[[key]],
         x = "Climatic instability",
         y = "Importance of tradition") +
    theme_minimal() +
    theme(panel.grid = element_blank(),
          plot.title = element_text(size = 10, face = "bold"),
          axis.title = element_text(size = 9),
          axis.text  = element_text(size = 8))
}

p_all <- (make_panel("OLS") | make_panel("Lasso")) /
         (make_panel("RF")  | make_panel("SS"))
print(p_all)
# @end


# =============================================================
# (6) Final DML model — 11 resamples + median aggregation
# =============================================================

# @snippet:final_code
# "Final" results using ddml (multiple resamples, median aggregation)
# 1. Set seed for replicability.
# 2. Use 11 separate cross-fit splits (reps = 11).
# 3. Use 10-fold cross-fitting in each rep.
# 4. Short-stacking via nnls1 in each rep (automatic in ddml).
# 5. Aggregate coefficients (mean and median).
# 6. Report stacking weights across reps.

# Reload data for fresh start
gn <- read_dta("https://dmlguide.github.io/assets/dta/GN2021.dta")
gn$sd_EE <- gn$sd_of_gen_mean_temp_anom_EE
gn <- gn |> filter(!is.na(loggdp))

Y <- gn[[Y_var]]
D <- gn[[D_var]]
X <- as.matrix(gn[, X_vars])

# Step 1: Set seed for replicability
set.seed(42)

# Step 2: Run ddml_plm 11 times with different random splits
# Note: the R ddml package does not have a built-in reps() argument,
# so we loop manually and aggregate following Chernozhukov et al.

K <- 10
R <- 11

coef_vec  <- numeric(R)
se_vec    <- numeric(R)
weights_Y <- matrix(NA_real_, nrow = 3, ncol = R)
weights_D <- matrix(NA_real_, nrow = 3, ncol = R)

for (r in 1:R) {
  cat(sprintf("Processing resample %d of %d...\n", r, R))

  fit_r <- ddml_plm(
    y             = Y,
    D             = D,
    X             = X,
    learners      = learners,
    sample_folds  = 10,
    ensemble_type = "nnls1",
    shortstack    = TRUE,
    cv_folds      = 5,
    silent        = TRUE
  )

  # Residualise Y and D using the short-stacked predictions, then
  # estimate theta and its HC1-robust SE from the standard PLR moment.
  resY <- as.numeric(Y - fit_r$fitted$y_X$cf_fitted[, "nnls1"])
  resD <- as.numeric(D - fit_r$fitted$D1_X$cf_fitted[, "nnls1"])
  fit_resid    <- lm(resY ~ resD)
  coef_vec[r]  <- coef(fit_resid)["resD"]
  se_vec[r]    <- sqrt(diag(vcovHC(fit_resid, type = "HC1")))["resD"]

  # Extract stacking weights (current ddml uses $ensemble_weights)
  weights_Y[, r] <- fit_r$ensemble_weights$y_X[, "nnls1"]
  weights_D[, r] <- fit_r$ensemble_weights$D1_X[, "nnls1"]
}

# Aggregate following DoubleML's median-of-CI formula
cv        <- 1.96
b_med     <- median(coef_vec)
se_med    <- (median(coef_vec + cv*se_vec) - median(coef_vec - cv*se_vec)) / (2*cv)
b_mean    <- mean(coef_vec)
se_mean   <- mean(se_vec)

agg_summary <- data.frame(
  spec = c("shortstack mean", "shortstack median"),
  b    = c(b_mean, b_med),
  se   = c(se_mean, se_med)
)
cat("\nMean/median aggregated short-stack results:\n")
print(agg_summary, row.names = FALSE)
# @end


# =============================================================
# (7) Final stacking weights — across the 11 resamples
# =============================================================

# @snippet:fsw_code
rownames(weights_Y) <- rownames(weights_D) <- c("ols", "lassocv", "rf")
rep_names <- paste0("rep_", 1:R)

ssweights_Y <- data.frame(learner = c("ols", "lassocv", "rf"),
                          mean_weight = rowMeans(weights_Y))
ssweights_Y[rep_names] <- t(weights_Y)

ssweights_D <- data.frame(learner = c("ols", "lassocv", "rf"),
                          mean_weight = rowMeans(weights_D))
ssweights_D[rep_names] <- t(weights_D)

cat("\nshort-stacked weights across resamples for A198new (11 reps)\n")
print(ssweights_Y)

cat("\nshort-stacked weights across resamples for sd_EE (11 reps)\n")
print(ssweights_D)
# @end


cat("\n========================================\n")
cat("GN replication complete!\n")
