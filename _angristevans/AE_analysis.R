#!/usr/bin/env Rscript
# Single-shot Angrist-Evans analysis on the full pums80m sample (no bootstrap).
# Reuses the helper functions from sim_AE.R: build_poly3, make_specs, estimate,
# load_data, prepare_data. Pick dgp and yvar via CLI args or interactive defaults.

suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(tibble)
  library(broom)
  library(arrow)
  library(ddml)
  library(fixest)
  library(Matrix)
  library(purrr)
  library(stringr)
  library(readr)
  library(withr)
})

set.seed(42)

`%||%` <- function(a, b) if (is.null(a)) b else a

# CLI args when run as a script; sensible defaults when sourced/interactive.
args <- commandArgs(trailingOnly = TRUE)
seed_arg <- if (length(args) >= 1L) as.integer(args[1]) else 42L
dgp_arg  <- if (length(args) >= 2L) as.integer(args[2]) else 1L
yvar_arg <- if (length(args) >= 3L) as.integer(args[3]) else 1L

# --- variable groups (mirror Stata globals) ---
X_vars         <- c("boy1st", "boy2nd", "agem1", "agefstm",
                    "blackm", "hispm", "othracem", "educm")
Xbase_boy1     <- c("boy1st", "agem1", "agefstm",
                    "blackm", "hispm", "othracem", "educm")
Xbase_boy2     <- c("boy2nd", "agem1", "agefstm",
                    "blackm", "hispm", "othracem", "educm")
D_var <- "morekids"
Z_var <- "instr"
kfolds <- 2L

# Cubic interaction features used for lasso/ridge ($xvar_poly3 in Stata).
# Linear + all 2-way + all 3-way monomials (with repetition).
build_poly3 <- function(df, base_cols) {
  X <- as.matrix(df[, base_cols, drop = FALSE])
  # poly() on a matrix returns all monomials of total degree <= 3, named by
  # exponent vector (e.g. "1.0.0.2.0.1.0"). model.matrix() wraps it as a
  # design matrix; drop the intercept it adds.
  P <- poly(X, degree = 3L, raw = TRUE)
  out <- model.matrix(~ P)[, -1L, drop = FALSE]
  # Translate exponent-string names to base_cols[i]_x_base_cols[j]... and
  # reorder so columns are degree-1, then degree-2, then degree-3.
  exps <- do.call(rbind, lapply(
    strsplit(sub("^P", "", colnames(out)), ".", fixed = TRUE),
    as.integer))
  colnames(out) <- apply(exps, 1L,
    function(e) paste(rep(base_cols, e), collapse = "_x_"))
  out[, order(rowSums(exps)), drop = FALSE]
}

make_learner_specs <- function(constraint=TRUE,base_idx,poly_idx) {
  if (constraint) {
    # impose constraint required for identification: no interactions between boy1st and boy2nd, but allow all other interactions. 
    xgb_args1 <- list(nrounds = 500L, 
                     learning_rate = 0.01, 
                     nthread = 1L, 
                     interaction_constraints = list(c(1,3:8),c(2:8))) 
    xgb_args2 <- list(nrounds = 500L, 
                     learning_rate = 0.03, 
                     nthread = 1L, 
                     interaction_constraints = list(c(1,3:8),c(2:8)))
    ll <- list(
      list(what = mdl_glmnet,
            args = list(alpha = 1, cv = TRUE),
            assign_X = poly_idx),
      list(what = mdl_glmnet,
            args = list(alpha = 0, cv = TRUE),
            assign_X = poly_idx),
      list(what = mdl_xgboost, args = xgb_args1, assign_X = base_idx),
      list(what = mdl_xgboost, args = xgb_args2, assign_X = base_idx)
      )
  } else {
    # no constraint: allow all interactions, so use the full X_full matrix for all learners.
    xgb_args1 <- list(nrounds = 500L, 
                     learning_rate = 0.01, 
                     nthread = 1L)
    xgb_args2 <- list(nrounds = 500L, 
                     learning_rate = 0.03, 
                     nthread = 1L)
    ll <- list(
        list(what = mdl_glmnet, args = list(alpha = 1, cv = TRUE)),
        list(what = mdl_glmnet, args = list(alpha = 0, cv = TRUE)),
        list(what = mdl_xgboost, args = xgb_args1, assign_X = base_idx),
        list(what = mdl_xgboost, args = xgb_args2, assign_X = base_idx)
    )
  }
  return(ll)
}

extract_coef_se <- function(fit, ens = "nnls1", coef = "D1") {
  s <- summary(fit)$coefficients
  c(b = unname(s[coef, "Estimate", ens]),
    se = unname(s[coef, "Std. Error", ens]))
}

avg_weights <- function(fit) {
  lapply(fit$ensemble_weights, function(w) apply(w, c(1, 2), mean))
}

load_data <- function(path = "pums80m.dta") {
  raw <- read_dta(path)
  raw$id <- seq_len(nrow(raw))
  raw
}

prepare_data <- function(d, instrument=c("observed","fake")) {
  instrument <- match.arg(instrument)
  if (instrument == "fake") {
    # Lock the noise draw so the same Z is used for constrained and
    # unconstrained calls. with_seed scopes the seed: the global RNG
    # state used by ddml downstream is untouched.
    d$instr <- d$agem1 + d$educm + with_seed(42L, runif(nrow(d)))
  } else if (instrument == "observed") {
    d$instr <- d$samesex
  } else {
    stop("Invalid instrument argument")
  }
  d$ix <- d$agem1 + d$educm
  d
}

estimate <- function(d, yvar = "workedm", single_learners = FALSE, constraint=FALSE, instrument) {

  d <- prepare_data(d, instrument)

  Y_var <- match.arg(yvar)

  y <- d[[Y_var]]
  D <- as.matrix(d[, D_var, drop = FALSE]); colnames(D) <- "D1"
  Z <- as.matrix(d[, Z_var, drop = FALSE]); colnames(Z) <- "Z1"
  X_base <- as.matrix(d[, X_vars])

  if (constraint) {
    X_poly_b1 <- build_poly3(d, Xbase_boy1)
    X_poly_b2 <- build_poly3(d, Xbase_boy2)
    X_full <- cbind(X_base, X_poly_b1, X_poly_b2)
    base_idx <- seq_len(ncol(X_base))
    poly_idx <- (ncol(X_base) + 1L):ncol(X_full)
  } else {
    X_full <- build_poly3(d, X_vars)
    base_idx <- NULL
    poly_idx <- NULL
  }
  
  rows <- list()

  # ---- 2SLS structural ----
  fml_iv <- as.formula(sprintf(
    "%s ~ %s | %s ~ %s",
    Y_var, paste(X_vars, collapse = " + "), D_var, Z_var))
  m_iv <- feols(fml_iv, data = d, se = "hetero")
  rows$tsls_struct <- broom::tidy(m_iv, conf.int = TRUE) %>%
    filter(term == paste0("fit_", D_var)) %>%
    mutate(estimator = "tsls", spec = "structural", learner = "ols")

  # ---- 2SLS first stage ----
  fml_fs <- as.formula(sprintf("%s ~ %s + %s", D_var, Z_var,
                               paste(X_vars, collapse = " + ")))
  m_fs <- feols(fml_fs, data = d, se = "hetero")
  rows$tsls_fs <- broom::tidy(m_fs, conf.int = TRUE) %>%
    filter(term == Z_var) %>%
    mutate(estimator = "tsls", spec = "first_stage", learner = "ols")

  # ---- DML stacked (4 learners) ----
  specs_stack <- make_learner_specs(constraint = constraint,
                                    base_idx = base_idx, 
                                    poly_idx = poly_idx)

  fit_ddml <- ddml_pliv(
    y = y, D = D, Z = Z, X = X_full,
    learners = specs_stack,
    sample_folds = kfolds,
    ensemble_type = "nnls",
    custom_ensemble_weights = diag(length(specs_stack)),
    shortstack = TRUE,
    silent = TRUE
  )

  ddml_array <- summary(fit_ddml)$coefficients
  ddml_tidy <- map_dfr(
    dimnames(ddml_array)[[3]],
    ~ as.data.frame(ddml_array[, , .x]) |>
        rownames_to_column("term") |>
        mutate(model = .x, .before = 1)
  ) |>
    as_tibble() 
  rows[[paste0("ddml")]] <- ddml_tidy |>
    filter(term == "D1") |>
    rename(estimate = Estimate, std.error = `Std. Error`) |>
    mutate(conf.low = estimate - 1.96 * std.error,
           conf.high = estimate + 1.96 * std.error, 
           statistic = estimate / std.error) |>
    mutate(estimator = "ddml", spec = "structural", learner = model) |>
    select(-model)  

  learner_names <- colnames(fit_ddml$fitted$D1_X$cf_fitted)
  for (l in learner_names) { 
    print(l)
    tmp <- d
    tmp$D_resid <- as.numeric(D[,1] - fit_ddml$fitted$D1_X$cf_fitted[,l])
    tmp$Z_resid <- as.numeric(Z[,1] - fit_ddml$fitted$Z1_X$cf_fitted[,l])
    tmp$Y_resid <- as.numeric(y - fit_ddml$fitted$y_X$cf_fitted[,l])
    rows[[paste0("ddml_fs_", l)]] <- feols(D_resid ~ Z_resid, data = tmp, se = "hetero") %>%
      broom::tidy(conf.int = TRUE) %>%
      filter(str_detect(term, "Z_resid")) %>%
      mutate(estimator = "ddml", spec = "first_stage", learner = l)  
  }

  out <- bind_rows(rows) |>
    mutate(yvar = Y_var) |>
    mutate(constraint = constraint,
           instr = instrument) 

  out
}

# ============================================================================
# Run the analysis once on the full sample.
# ============================================================================

df <- load_data("pums80m.dta")
res <- list()
for (flavor in c("observed", "fake")) {
  for (constraint in c(TRUE, FALSE)) {
    res[[paste(flavor, "workedm", ifelse(constraint, "constrained", "unconstrained"), sep = "_")]] <-
      estimate(df, yvar = "workedm", instrument = flavor, constraint = constraint)
  }
}
res <- bind_rows(res)

# Persist results so the Quarto post can load them without re-running DML.
# Run this script from _angristevans/ (the Makefile target does so).
arrow::write_parquet(res, "results.parquet")
readr::write_csv(res,    "results.csv")
message("Wrote results.parquet and results.csv to ", normalizePath("."))