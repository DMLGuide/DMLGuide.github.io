
suppressPackageStartupMessages({
  library(ddml)
  library(modelsummary)
})

nfolds <- 3L
seed   <- 42L
set.seed(seed)

script_dir <- "/Users/kahrens/MyProjects/JEL/website/_dube_monopsony"
data_path  <- file.path(script_dir, "data", "monopsony_blog.rds")
out_file   <- file.path(script_dir, "results_entry1.rds")

dat <- readRDS(data_path)

y <- dat$log_duration
D <- dat$log_reward
X <- as.matrix(dat[, 5:ncol(dat), drop = FALSE])
n <- length(y)

# ---- DDML PLM, cluster-honest folds by requester ----------------------------
lasso_spec <- list(
  what = mdl_glmnet,
  args = list(alpha = 1)
)

t0 <- proc.time()[3]
fit <- ddml_plm(
  y                = y,
  D                = D,
  X                = X,
  learners         = lasso_spec,
  sample_folds     = nfolds,
  cluster_variable = dat$requester_id
)
cat(sprintf("DDML fit time: %.1f s\n", proc.time()[3] - t0))

co      <- summary(fit)$coefficients
ddml_b  <- unname(co["D1", "Estimate",   1L])
ddml_se <- unname(co["D1", "Std. Error", 1L])

hat_y <- as.numeric(fit$fitted$y_X$cf_fitted[, 1L])
hat_d <- as.numeric(fit$fitted$D1_X$cf_fitted[, 1L])
r2_y  <- 1 - sum((y - hat_y)^2) / sum((y - mean(y))^2)
r2_d  <- 1 - sum((D - hat_d)^2) / sum((D - mean(D))^2)
cat(sprintf("Cross-fitted R^2: y = %.3f, d = %.3f\n", r2_y, r2_d))

# Wrap the DDML result so modelsummary can render it alongside the OLS fit.
ddml_ms <- list(
  tidy = data.frame(
    term      = "log_reward",
    estimate  = ddml_b,
    std.error = ddml_se,
    statistic = ddml_b / ddml_se,
    p.value   = 2 * pnorm(-abs(ddml_b / ddml_se))
  ),
  glance = data.frame(
    nobs = n,
    K    = nfolds,
    r2_y = r2_y,
    r2_d = r2_d
  )
)
class(ddml_ms) <- "modelsummary_list"

models <- list(
  "DDML" = ddml_ms
)
saveRDS(models, out_file)
cat("Wrote ", out_file, "\n", sep = "")
