# setup.R
# Run this once to install all required packages.
# After installation, restart R and run gn_ddml_byhand.R

pkgs <- c(
  "haven", "dplyr", "broom", "sandwich", "lmtest", "ggplot2",
  "DoubleML", "mlr3", "mlr3learners", "mlr3verse",
  "ranger", "glmnet", "nloptr", "patchwork", "gridExtra", "tibble"
)

install.packages(pkgs)

cat("\nAll packages installed. Please restart R and run the file")

rm(list = ls())

# Version information 
cat("R version:\n"); print(R.version.string)

library(haven)
library(dplyr)
library(broom)
library(sandwich)
library(lmtest)
library(ggplot2)
library(nloptr)
library(DoubleML)
library(mlr3)
library(mlr3learners)
library(ranger)
library(glmnet)
library(patchwork)
library(gridExtra)
library(tibble)

cat("Package versions:\n")
cat("ranger:",   as.character(packageVersion("ranger")),   "\n")
cat("glmnet:",   as.character(packageVersion("glmnet")),   "\n")
cat("DoubleML:", as.character(packageVersion("DoubleML")), "\n")
cat("mlr3:",     as.character(packageVersion("mlr3")),     "\n")
cat("nloptr:",   as.character(packageVersion("nloptr")),   "\n")

# =============================================================
# PART 1: OLS replication


# Load data
gn <- read_dta("https://dmlguide.github.io/assets/dta/GN2021.dta")

# Shorten the name of the causal variable of interest to sd_EE
gn$sd_EE <- gn$sd_of_gen_mean_temp_anom_EE

# Replicate results with no controls in Table 1, column (3). HC1 robust SE
model_simple       <- lm(A198new ~ sd_EE, data = gn)
vcov_simple_robust <- vcovHC(model_simple, type = "HC1")
coeftest(model_simple, vcov = vcov_simple_robust)

cat("\nPART 1: OLS (A198new ~ sd_EE) with HC1 robust SE\n")

# Figure 5
gn$hat <- fitted(model_simple)

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

# =============================================================
# NNLS helper: constrained non-negative least squares
# Minimizes ||P %*% b - y|| (L2 norm) subject to:
#   sum(b) = 1  (equality constraint)
#   b >= 0      (non-negativity)
#   b <= 1      (upper bound)
# Uses nloptr::slsqp(), the R implementation of the same SLSQP algorithm
# used by scipy.optimize.minimize(method='SLSQP') in Python.
# Multiple starting points used to avoid local optima / convergence failures.

nnls_constrained <- function(P, y) {
  k <- ncol(P)
  
  # Objective: L2 norm ||P %*% b - y|| (matching Python's np.linalg.norm)
  fn <- function(b) sqrt(sum((P %*% b - y)^2))
  
  # Equality constraint: sum(b) = 1 (matching Python's cons)
  heq <- function(b) sum(b) - 1
  
  # Try k+1 starting points: uniform weights + each corner (all weight on one learner)
  # This avoids convergence failures when prediction matrices are nearly collinear
  starts <- rbind(
    rep(1/k, k),  # uniform start (same as Python's np.ones / flatten)
    diag(k)       # corner starts: all weight on one learner
  )
  
  best_val <- Inf
  best_par <- rep(1/k, k)
  
  for (i in 1:nrow(starts)) {
    res <- tryCatch(
      slsqp(
        x0    = starts[i, ],
        fn    = fn,
        heq   = heq,
        lower = rep(0, k),  # matching Python's bounds = [[0,1],...]
        upper = rep(1, k)
      ),
      error = function(e) NULL
    )
    if (!is.null(res) && res$value < best_val) {
      best_val <- res$value
      best_par <- res$par
    }
  }
  
  # Clip to [0,1] and renormalise for numerical safety
  b <- pmax(pmin(best_par, 1), 0)
  b / sum(b)
}

# =============================================================
# PART 2: DML robustness check (single 10-fold shortstack)


# In the G-N estimations, GDP is missing for one country.
# For simplicity, we just drop this one country so that it is never used.
gn <- gn |> filter(!is.na(loggdp))

# To make the code more readable, define locals for Y, D and X:
Y_var  <- "A198new"
D_var  <- "sd_EE"
X_vars <- c("v104_ee", "settlement_ee", "polhierarchies_ee", "loggdp")

Y <- gn[[Y_var]]
D <- gn[[D_var]]
X <- as.matrix(gn[, X_vars])

n <- nrow(X)
K <- 10

# Step 1: Specify the model.
# Partially-linear model with 10-fold cross-fitting and a single cross-fit split.

# Create 10-fold split
set.seed(12345)
fold_id <- sample(rep(1:K, length.out = n))

# Storage for out-of-sample (cross-fitted) predictions
Y_hat_ols   <- Y_hat_lasso <- Y_hat_rf <- rep(NA_real_, n)
D_hat_ols   <- D_hat_lasso <- D_hat_rf <- rep(NA_real_, n)

# Step 2: Choose the learners.
# Unregularized OLS, cross-validated lasso, and random forest.

for (k in 1:K) {
  idx_train <- which(fold_id != k)
  idx_test  <- which(fold_id == k)
  
  X_train <- X[idx_train, , drop = FALSE]
  X_test  <- X[idx_test,  , drop = FALSE]
  Y_train <- Y[idx_train]
  D_train <- D[idx_train]
  
  # Learners for E[Y|X]
  
  # OLS
  df_Y_train <- data.frame(y = Y_train, X_train)
  df_Y_test  <- data.frame(X_test)
  colnames(df_Y_train) <- c("y", X_vars)
  colnames(df_Y_test)  <- X_vars
  fit_ols_Y <- lm(y ~ ., data = df_Y_train)
  Y_hat_ols[idx_test] <- predict(fit_ols_Y, newdata = df_Y_test)
  
  # Lasso (cross-validated)
  fit_lasso_Y <- cv.glmnet(x = X_train, y = Y_train, alpha = 1)
  Y_hat_lasso[idx_test] <- as.numeric(
    predict(fit_lasso_Y, newx = X_test, s = "lambda.min")
  )
  
  # Random forest
  df_Y_train_rf <- data.frame(y = Y_train, X_train)
  df_Y_test_rf  <- data.frame(X_test)
  colnames(df_Y_train_rf) <- c("y", X_vars)
  colnames(df_Y_test_rf)  <- X_vars
  fit_rf_Y <- ranger(y ~ ., data = df_Y_train_rf, num.trees = 500, min.node.size = 5)
  Y_hat_rf[idx_test] <- predict(fit_rf_Y, data = df_Y_test_rf)$predictions
  
  # Learners for E[D|X]
  
  # OLS
  df_D_train <- data.frame(d = D_train, X_train)
  df_D_test  <- data.frame(X_test)
  colnames(df_D_train) <- c("d", X_vars)
  colnames(df_D_test)  <- X_vars
  fit_ols_D <- lm(d ~ ., data = df_D_train)
  D_hat_ols[idx_test] <- predict(fit_ols_D, newdata = df_D_test)
  
  # Lasso
  fit_lasso_D <- cv.glmnet(x = X_train, y = D_train, alpha = 1)
  D_hat_lasso[idx_test] <- as.numeric(
    predict(fit_lasso_D, newx = X_test, s = "lambda.min")
  )
  
  # Random forest
  df_D_train_rf <- data.frame(d = D_train, X_train)
  df_D_test_rf  <- data.frame(X_test)
  colnames(df_D_train_rf) <- c("d", X_vars)
  colnames(df_D_test_rf)  <- X_vars
  fit_rf_D <- ranger(d ~ ., data = df_D_train_rf, num.trees = 500, min.node.size = 5)
  D_hat_rf[idx_test] <- predict(fit_rf_D, data = df_D_test_rf)$predictions
}

# Check that predictions are complete
stopifnot(
  all(!is.na(Y_hat_ols)),
  all(!is.na(Y_hat_lasso)),
  all(!is.na(Y_hat_rf)),
  all(!is.na(D_hat_ols)),
  all(!is.na(D_hat_lasso)),
  all(!is.na(D_hat_rf))
)

# Step 3: Short-stacking via constrained NNLS.
# Weights are non-negative and sum to 1.

PY <- cbind(Y_hat_ols, Y_hat_lasso, Y_hat_rf)
PD <- cbind(D_hat_ols, D_hat_lasso, D_hat_rf)

# Short-stack weights for Y
w_Y <- nnls_constrained(PY, Y)
names(w_Y) <- c("ols", "lassocv", "rf")

# Short-stack weights for D
w_D <- nnls_constrained(PD, D)
names(w_D) <- c("ols", "lassocv", "rf")

# Short-stacked conditional expectations
Y_hat_ss <- as.numeric(PY %*% w_Y)
D_hat_ss <- as.numeric(PD %*% w_D)

# Step 4: PLM estimation (residualised Y on residualised D)
Y_tilde <- Y - Y_hat_ss
D_tilde <- D - D_hat_ss

dml_model       <- lm(Y_tilde ~ D_tilde)
vcov_dml_robust <- vcovHC(dml_model, type = "HC1")
dml_res         <- coeftest(dml_model, vcov = vcov_dml_robust)
print(dml_res)

dml_summary <- tidy(dml_res)
dml_summary$term[dml_summary$term == "D_tilde"] <- "sd_EE (shortstack DML)"
print(dml_summary)

cat("\nPART 2: DML shortstack (single split), HC1 robust SE\n")

learners    <- c("ols", "lassocv", "rf")
ssweights_Y <- data.frame(learner = learners, mean_weight = w_Y, rep_1 = w_Y)
ssweights_D <- data.frame(learner = learners, mean_weight = w_D, rep_1 = w_D)

cat("\nshort-stacked weights across resamples for A198new\n")
print(ssweights_Y)

cat("\nshort-stacked weights across resamples for sd_EE\n")
print(ssweights_D)

# Results by learner
gn$Y_L1_r <- Y - Y_hat_ols
gn$Y_L2_r <- Y - Y_hat_lasso
gn$Y_L3_r <- Y - Y_hat_rf
gn$Y_ss_r <- Y - Y_hat_ss

gn$D_L1_r <- D - D_hat_ols
gn$D_L2_r <- D - D_hat_lasso
gn$D_L3_r <- D - D_hat_rf
gn$D_ss_r <- D - D_hat_ss

# OLS learners
fit_L1     <- lm(Y_L1_r ~ D_L1_r, data = gn)
vc_L1      <- vcovHC(fit_L1, type = "HC1")
L1_res     <- coeftest(fit_L1, vcov = vc_L1)
gn$hat_1_1 <- fitted(fit_L1)

# Lasso learners
fit_L2     <- lm(Y_L2_r ~ D_L2_r, data = gn)
vc_L2      <- vcovHC(fit_L2, type = "HC1")
L2_res     <- coeftest(fit_L2, vcov = vc_L2)
gn$hat_2_2 <- fitted(fit_L2)

# RF learners
fit_L3     <- lm(Y_L3_r ~ D_L3_r, data = gn)
vc_L3      <- vcovHC(fit_L3, type = "HC1")
L3_res     <- coeftest(fit_L3, vcov = vc_L3)
gn$hat_3_3 <- fitted(fit_L3)

# Short-stacked learners
fit_SS       <- lm(Y_ss_r ~ D_ss_r, data = gn)
vc_SS        <- vcovHC(fit_SS, type = "HC1")
SS_res       <- coeftest(fit_SS, vcov = vc_SS)
gn$hat_ss_ss <- fitted(fit_SS)

base_scatter <- function(df, xvar, yvar, hatvar, title_text) {
  ggplot(df, aes_string(x = xvar, y = yvar, label = "isocode")) +
    geom_point(size = 2) +
    geom_text(vjust = -0.6, size = 3) +
    geom_line(aes_string(y = hatvar), linewidth = 1.2, color = "#B1004F") +
    scale_x_continuous(breaks = c(-0.3, -0.2, -0.1, 0, 0.1, 0.2, 0.3),
                       limits = c(-0.3, 0.3)) +
    scale_y_continuous(breaks = c(-2, -1, 0, 1, 2), limits = c(-2, 2)) +
    labs(x = "Climatic instability", y = "Importance of tradition", title = title_text) +
    theme_minimal() +
    theme(
      panel.grid      = element_blank(),
      legend.position = "none",
      plot.title      = element_text(size = 14, face = "bold"),
      axis.title      = element_text(size = 12),
      axis.text       = element_text(size = 10)
    )
}

p_ols   <- base_scatter(gn, "D_L1_r", "Y_L1_r", "hat_1_1",   "Y and D: Unregularized OLS")
p_lasso <- base_scatter(gn, "D_L2_r", "Y_L2_r", "hat_2_2",   "Y and D: Lasso")
p_rf    <- base_scatter(gn, "D_L3_r", "Y_L3_r", "hat_3_3",   "Y and D: Random Forest")
p_ss    <- base_scatter(gn, "D_ss_r", "Y_ss_r", "hat_ss_ss", "Y and D: Short-stacked")

print(p_ols)
print(p_lasso)
print(p_rf)
print(p_ss)
print((p_ols | p_lasso) / (p_rf | p_ss))

# =============================================================
# PART 3: Final DML model (11 resamples, median aggregation)


# Step 1: Set seed for replicability
set.seed(42)

K <- 10
R <- 11

coef_vec  <- numeric(R)
se_vec    <- numeric(R)

weights_Y <- matrix(NA_real_, nrow = 3, ncol = R)
weights_D <- matrix(NA_real_, nrow = 3, ncol = R)
rownames(weights_Y) <- rownames(weights_D) <- c("ols", "lassocv", "rf")

# Step 2: 11 separate cross-fit splits, 10-fold each
for (r in 1:R) {
  
  cat(sprintf("Processing resample %d of %d...\n", r, R))
  
  fold_id <- sample(rep(1:K, length.out = n))
  
  Y_hat_ols   <- Y_hat_lasso <- Y_hat_rf <- rep(NA_real_, n)
  D_hat_ols   <- D_hat_lasso <- D_hat_rf <- rep(NA_real_, n)
  
  for (k in 1:K) {
    idx_train <- which(fold_id != k)
    idx_test  <- which(fold_id == k)
    
    X_train <- X[idx_train, , drop = FALSE]
    X_test  <- X[idx_test,  , drop = FALSE]
    Y_train <- Y[idx_train]
    D_train <- D[idx_train]
    
    # E[Y|X]
    df_Y_train <- data.frame(y = Y_train, X_train)
    df_Y_test  <- data.frame(X_test)
    colnames(df_Y_train) <- c("y", X_vars)
    colnames(df_Y_test)  <- X_vars
    fit_ols_Y <- lm(y ~ ., data = df_Y_train)
    Y_hat_ols[idx_test] <- predict(fit_ols_Y, newdata = df_Y_test)
    
    fit_lasso_Y <- cv.glmnet(x = X_train, y = Y_train, alpha = 1)
    Y_hat_lasso[idx_test] <- as.numeric(
      predict(fit_lasso_Y, newx = X_test, s = "lambda.min")
    )
    
    df_Y_train_rf <- data.frame(y = Y_train, X_train)
    df_Y_test_rf  <- data.frame(X_test)
    colnames(df_Y_train_rf) <- c("y", X_vars)
    colnames(df_Y_test_rf)  <- X_vars
    fit_rf_Y <- ranger(y ~ ., data = df_Y_train_rf, num.trees = 500, min.node.size = 5)
    Y_hat_rf[idx_test] <- predict(fit_rf_Y, data = df_Y_test_rf)$predictions
    
    # E[D|X]
    df_D_train <- data.frame(d = D_train, X_train)
    df_D_test  <- data.frame(X_test)
    colnames(df_D_train) <- c("d", X_vars)
    colnames(df_D_test)  <- X_vars
    fit_ols_D <- lm(d ~ ., data = df_D_train)
    D_hat_ols[idx_test] <- predict(fit_ols_D, newdata = df_D_test)
    
    fit_lasso_D <- cv.glmnet(x = X_train, y = D_train, alpha = 1)
    D_hat_lasso[idx_test] <- as.numeric(
      predict(fit_lasso_D, newx = X_test, s = "lambda.min")
    )
    
    df_D_train_rf <- data.frame(d = D_train, X_train)
    df_D_test_rf  <- data.frame(X_test)
    colnames(df_D_train_rf) <- c("d", X_vars)
    colnames(df_D_test_rf)  <- X_vars
    fit_rf_D <- ranger(d ~ ., data = df_D_train_rf, num.trees = 500, min.node.size = 5)
    D_hat_rf[idx_test] <- predict(fit_rf_D, data = df_D_test_rf)$predictions
  }
  
  # Short-stacking via constrained NNLS for this rep
  PY <- cbind(Y_hat_ols, Y_hat_lasso, Y_hat_rf)
  PD <- cbind(D_hat_ols, D_hat_lasso, D_hat_rf)
  
  w_Y <- nnls_constrained(PY, Y)
  w_D <- nnls_constrained(PD, D)
  
  weights_Y[, r] <- w_Y
  weights_D[, r] <- w_D
  
  Y_hat_ss <- as.numeric(PY %*% w_Y)
  D_hat_ss <- as.numeric(PD %*% w_D)
  
  # PLM estimation for this resample
  Y_tilde <- Y - Y_hat_ss
  D_tilde <- D - D_hat_ss
  
  dml_model_r <- lm(Y_tilde ~ D_tilde)
  vcov_r      <- vcovHC(dml_model_r, type = "HC1")
  tt_r        <- coeftest(dml_model_r, vcov = vcov_r)
  
  coef_vec[r] <- tt_r["D_tilde", 1]
  se_vec[r]   <- tt_r["D_tilde", 2]
}

# Results across 11 resamples
results_reps <- tibble(rep = 1:R, b = coef_vec, se = se_vec)

cat("\nDDML shortstack results across 11 resamples (R analogue of ss 1..11):\n")
print(results_reps)

# Step 5: Median aggregation:
# sigma = sqrt( Median( sigma_m^2 + (theta_m - theta_tilde)^2 ) )
b_med  <- median(coef_vec)
se_med <- sqrt(median(se_vec^2 + (coef_vec - b_med)^2))

b_mean  <- mean(coef_vec)
se_mean <- mean(se_vec)

agg_summary <- tibble(
  spec = c("shortstack mean", "shortstack median"),
  b    = c(b_mean, b_med),
  se   = c(se_mean, se_med)
)

cat("\nMedian aggregated short-stack results:\n")
cat("\n                    spec           b          se\n")
cat(sprintf("   shortstack median  %10.7f  %10.7f\n", b_med, se_med))

cat("\nMean/median aggregated short-stack results:\n")
print(agg_summary)

# Summary over 11 resamples
summary_over_reps <- tibble(
  D_eqn = "sd_EE",
  mean  = mean(coef_vec),
  min   = min(coef_vec),
  p25   = quantile(coef_vec, 0.25),
  p50   = quantile(coef_vec, 0.50),
  p75   = quantile(coef_vec, 0.75),
  max   = max(coef_vec)
)

cat("\nSummary over 11 resamples:\n")
print(summary_over_reps)

# Step 6: Report stacking weights across the 11 reps
rep_names <- paste0("rep_", 1:R)

ssweights_Y_multi <- data.frame(
  learner     = rownames(weights_Y),
  mean_weight = rowMeans(weights_Y)
)
ssweights_Y_multi[rep_names] <- t(weights_Y)

ssweights_D_multi <- data.frame(
  learner     = rownames(weights_D),
  mean_weight = rowMeans(weights_D)
)
ssweights_D_multi[rep_names] <- t(weights_D)

cat("\nshort-stacked weights across resamples for A198new (11 reps)\n")
print(ssweights_Y_multi)

cat("\nshort-stacked weights across resamples for sd_EE (11 reps)\n")
print(ssweights_D_multi)

cat("\n========================================\n")
cat("GN replication complete!\n")
