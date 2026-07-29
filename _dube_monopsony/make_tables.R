#!/usr/bin/env Rscript
# make_tables.R (website/_dube_monopsony copy)
#
# Adapted from Code/dube_monopsony/make_tables.R for standalone use from the
# website folder. Only the paths to the intermediate results and the raw
# Ipeirotis data have been changed; the table-generation logic is identical.
#
# Usage:
#   Rscript make_tables.R <nfolds> <xfit_mode> <seed1> <seed2> ...
# Defaults if no args:
#   nfolds = 3, xfit_mode = "xclust", seeds = the five run_cvc seeds.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) >= 3L) {
  nfolds    <- as.integer(args[1])
  xfit_mode <- args[2]
  seeds     <- as.integer(args[3:length(args)])
} else {
  nfolds    <- 3L
  xfit_mode <- "xclust"
  seeds     <- c(12487L, 17929L, 28327L, 63595L, 85886L)
}

cat(sprintf("=== make_tables.R: K=%d, mode=%s, seeds=%s ===\n",
            nfolds, xfit_mode, paste(seeds, collapse = ", ")))

suppressPackageStartupMessages({
  library(ddml)
  library(arrow)
  library(readr)
  library(dplyr)
  library(modelsummary)
  library(tinytable)
  library(fixest)
})
options(modelsummary_factory_latex = "tinytable")

# ==============================================================================
# Paths (adapted for website/_dube_monopsony)
# ==============================================================================

monopsony_root <- "/Users/kahrens/PP Dropbox/Achim Ahrens/monopsony_data"
data_path <- "/Users/kahrens/MyProjects/JEL/Data" # raw Ipeirotis CSVs
int_dir   <- file.path(monopsony_root, "intermediate",
                       sprintf("%s_K%d", xfit_mode, nfolds))

# Write LaTeX output under the local website folder.
script_dir  <- "/Users/kahrens/MyProjects/JEL/website/_dube_monopsony"
output_path <- file.path(script_dir, "output",
                         sprintf("%s_K%d", xfit_mode, nfolds))
dir.create(output_path, showWarnings = FALSE, recursive = TRUE)

# ==============================================================================
# Load per-seed results
# ==============================================================================

cat("Loading per-seed results...\n")

fits <- list()
fits_cvc <- list()
diag_list <- list()
diag_cvc_list <- list()

for (i in seq_along(seeds)) {
  s <- seeds[i]
  fn <- file.path(int_dir, sprintf("cvc_seed%d_K%d.RData", s, nfolds))
  cat(sprintf("  Loading %s...\n", fn))
  env <- new.env()
  load(fn, envir = env)
  fits[[i]] <- env$fit
  fits_cvc[[i]] <- env$fit_cvc
  diag_list[[i]] <- env$diag_obj
  diag_cvc_list[[i]] <- env$diag_cvc
}
names(fits) <- as.character(seeds)
names(fits_cvc) <- as.character(seeds)
names(diag_list) <- as.character(seeds)
names(diag_cvc_list) <- as.character(seeds)

# ==============================================================================
# Load data (needed for het-robust SE swap and OLS reference)
# ==============================================================================

ipeirotis <- read_delim(
  file.path(data_path, "Monopsony_cleaned.csv"),
  delim = ";", show_col_types = FALSE
)
y <- ipeirotis$log_duration
D <- ipeirotis$log_reward
nobs <- length(y)

# ==============================================================================
# Multi-resample aggregation
# ==============================================================================

cat("Aggregating across seeds (median method)...\n")

# Cluster-robust (default)
rep_obj <- ddml_rep(fits)
smry_clust <- summary(rep_obj, aggregation = "median")

# CVC aggregation
rep_cvc <- ddml_rep(fits_cvc)
smry_cvc_clust <- summary(rep_cvc, aggregation = "median")

# ==============================================================================
# Diagnostics averaging
# ==============================================================================

learner_names <- c("OLS", "CV-Lasso", "CV-Ridge",
                   "RF 1", "RF 2", "RF 3",
                   "XGB 1", "XGB 2", "XGB 3",
                   "NN 1", "NN 2", "NN 3")

avg_diagnostics <- function(diag_list,
                            ens_type_y = "nnls1", ens_type_d = "nnls1",
                            nlearners = 12L) {
  all_diag <- lapply(diag_list, function(d) {
    td <- tidy(d)
    # Filter to base learners only (first nlearners rows per equation);
    # tidy() may include ensemble-level rows after adding ensemble R².
    idx_y <- which(td$equation == "y_X")[seq_len(nlearners)]
    idx_d <- which(td$equation == "D1_X")[seq_len(nlearners)]
    cvc_pval_y <- td$cvc_pval[idx_y]
    cvc_pval_d <- td$cvc_pval[idx_d]
    # Derive CVC weights (same logic as run_cvc.R)
    cvc_w_y <- ifelse(!is.na(cvc_pval_y) & cvc_pval_y > 0.2, 1, 0)
    if (sum(cvc_w_y) == 0) cvc_w_y <- rep(1, length(cvc_w_y))
    cvc_w_y <- cvc_w_y / sum(cvc_w_y)
    cvc_w_d <- ifelse(!is.na(cvc_pval_d) & cvc_pval_d > 0.2, 1, 0)
    if (sum(cvc_w_d) == 0) cvc_w_d <- rep(1, length(cvc_w_d))
    cvc_w_d <- cvc_w_d / sum(cvc_w_d)
    list(
      r2_y = td$r2[idx_y],
      r2_d = td$r2[idx_d],
      w_y  = td[[paste0("weight_", ens_type_y)]][idx_y],
      w_d  = td[[paste0("weight_", ens_type_d)]][idx_d],
      cvc_y = cvc_pval_y,
      cvc_d = cvc_pval_d,
      cvc_w_y = cvc_w_y,
      cvc_w_d = cvc_w_d
    )
  })
  data.frame(
    r2_y    = Reduce("+", lapply(all_diag, `[[`, "r2_y"))    / length(all_diag),
    r2_d    = Reduce("+", lapply(all_diag, `[[`, "r2_d"))    / length(all_diag),
    w_y     = Reduce("+", lapply(all_diag, `[[`, "w_y"))     / length(all_diag),
    w_d     = Reduce("+", lapply(all_diag, `[[`, "w_d"))     / length(all_diag),
    cvc_y   = Reduce("+", lapply(all_diag, `[[`, "cvc_y"))   / length(all_diag),
    cvc_d   = Reduce("+", lapply(all_diag, `[[`, "cvc_d"))   / length(all_diag),
    cvc_w_y = Reduce("+", lapply(all_diag, `[[`, "cvc_w_y")) / length(all_diag),
    cvc_w_d = Reduce("+", lapply(all_diag, `[[`, "cvc_w_d")) / length(all_diag)
  )
}
diag_avg <- avg_diagnostics(diag_list)

# ==============================================================================
# Ensemble R² helper
# ==============================================================================

#' Extract ddml-internal ensemble R² from diagnostics, averaged across seeds.
ensemble_r2 <- function(diag_list, ensemble_name, equation) {
  mean(sapply(diag_list, function(d) {
    td <- tidy(d)
    td$r2[td$equation == equation & td$learner == ensemble_name]
  }))
}

# ==============================================================================
# Table helpers
# ==============================================================================

fmt_gof <- function(val, digits = 4) {
  formatC(round(val, digits), format = "f", digits = digits)
}

make_perlearner_table <- function(rep_obj, se_label, learner_indices,
                                  diag_avg, learner_names, output_file) {
  all_ensembles <- as.list(rep_obj)

  mdl_list <- setNames(
    lapply(learner_names[learner_indices], function(nm) all_ensembles[[nm]]),
    learner_names[learner_indices]
  )

  gof_df <- data.frame(
    term = c(
      "Out-of-sample $R^2$ Outcome",
      "Out-of-sample $R^2$ Treatment",
      "CVC $p$-value Outcome",
      "CVC $p$-value Treatment",
      "Weights Outcome",
      "Weights Treatment",
      "ML"
    ),
    stringsAsFactors = FALSE
  )
  for (j in learner_indices) {
    col_name <- learner_names[j]
    gof_df[[col_name]] <- c(
      fmt_gof(diag_avg$r2_y[j]),
      fmt_gof(diag_avg$r2_d[j]),
      fmt_gof(diag_avg$cvc_y[j]),
      fmt_gof(diag_avg$cvc_d[j]),
      fmt_gof(diag_avg$w_y[j]),
      fmt_gof(diag_avg$w_d[j]),
      learner_names[j]
    )
  }

  msummary(
    mdl_list,
    output = output_file,
    escape = FALSE,
    stars = c("***" = 0.001, "**" = 0.01, "*" = 0.05),
    coef_rename = c("D1" = "log reward"),
    coef_omit = "Intercept",
    gof_map = NA,
    add_rows = gof_df,
    title = paste0(se_label, " standard errors")
  )
  cat(sprintf("  Wrote %s\n", output_file))
}

make_stacking_table <- function(fits, rep_obj, ens_name, ens_label,
                                 se_label, output_file) {
  mdl_list <- setNames(
    lapply(fits, function(f) as.list(f)[[ens_name]]),
    paste0("Seed ", names(fits))
  )
  mdl_list[["Median"]] <- as.list(rep_obj)[[ens_name]]

  msummary(
    mdl_list,
    output = output_file,
    escape = FALSE,
    stars = c("***" = 0.001, "**" = 0.01, "*" = 0.05),
    coef_rename = c("D1" = "log reward"),
    coef_omit = "Intercept",
    gof_map = NA,
    title = paste0(ens_label, " (", se_label, ")")
  )
  cat(sprintf("  Wrote %s\n", output_file))
}

make_part3_table <- function(rep_obj, rep_cvc, se_label,
                              diag_list, diag_cvc_list, output_file) {
  all_ens <- as.list(rep_obj)
  mdl_list <- list("NNLS1" = all_ens[["nnls1"]],
                   "Single-best" = all_ens[["singlebest"]],
                   "CVC" = as.list(rep_cvc)[["CVC"]])

  # All ensemble R² from ddml diagnostics (averaged across seeds)
  nnls_r2_y <- ensemble_r2(diag_list, "nnls1", "y_X")
  nnls_r2_d <- ensemble_r2(diag_list, "nnls1", "D1_X")
  sb_r2_y   <- ensemble_r2(diag_list, "singlebest", "y_X")
  sb_r2_d   <- ensemble_r2(diag_list, "singlebest", "D1_X")
  cvc_r2_y  <- ensemble_r2(diag_cvc_list, "CVC", "y_X")
  cvc_r2_d  <- ensemble_r2(diag_cvc_list, "CVC", "D1_X")

  gof_df <- data.frame(
    term = c("$R^2$ Outcome",
             "$R^2$ Treatment",
             "ML"),
    stringsAsFactors = FALSE
  )
  gof_df[["NNLS1"]] <- c(fmt_gof(nnls_r2_y), fmt_gof(nnls_r2_d), "NNLS1")
  gof_df[["Single-best"]] <- c(fmt_gof(sb_r2_y), fmt_gof(sb_r2_d), "Single-best")
  gof_df[["CVC"]] <- c(fmt_gof(cvc_r2_y), fmt_gof(cvc_r2_d), "CVC")

  msummary(
    mdl_list,
    output = output_file,
    escape = FALSE,
    stars = c("***" = 0.001, "**" = 0.01, "*" = 0.05),
    coef_rename = c("D1" = "log reward"),
    coef_omit = "Intercept",
    gof_map = NA,
    add_rows = gof_df,
    title = paste0(se_label, " standard errors")
  )
  cat(sprintf("  Wrote %s\n", output_file))
}

# ==============================================================================
# Generate tables
# ==============================================================================

cat("Generating tables...\n")

# --- Generate Robust Tables ---
if (xfit_mode == "iid") {
  se_label_title <- "Heteroskedasticity-robust"
  se_label_file <- "het-robust"
} else {
  se_label_title <- "Cluster-robust"
  se_label_file <- "cluster-robust"
}

cat(sprintf("  %s tables:\n", se_label_title))

make_perlearner_table(
  rep_obj, se_label_title, 1:6, diag_avg, learner_names,
  file.path(output_path,
            sprintf("output_%s_part1_K%d.tex",
                    se_label_file, nfolds))
)

make_perlearner_table(
  rep_obj, se_label_title, 7:12, diag_avg, learner_names,
  file.path(output_path,
            sprintf("output_%s_part2_K%d.tex",
                    se_label_file, nfolds))
)

make_stacking_table(
  fits, rep_obj, "nnls1", "NNLS1", se_label_title,
  file.path(output_path,
            sprintf("output_%s_nnls1_K%d.tex",
                    se_label_file, nfolds))
)

make_stacking_table(
  fits, rep_obj, "singlebest", "Single Best", se_label_title,
  file.path(output_path,
            sprintf("output_%s_singlebest_K%d.tex",
                    se_label_file, nfolds))
)

make_part3_table(
  rep_obj, rep_cvc, se_label_title,
  diag_list, diag_cvc_list,
  file.path(output_path,
            sprintf("output_%s_part3_K%d.tex",
                    se_label_file, nfolds))
)


# ==============================================================================
# Unconditional OLS reference
# ==============================================================================

cat("\n=== Unconditional OLS ===\n")
if (xfit_mode == "iid") {
  ols_ref <- feols(log_duration ~ log_reward, se = "hetero",
                   data = ipeirotis)
} else {
  ols_ref <- feols(log_duration ~ log_reward, cluster = "rid",
                   data = ipeirotis)
}
print(summary(ols_ref))

cat("\nDone.\n")
