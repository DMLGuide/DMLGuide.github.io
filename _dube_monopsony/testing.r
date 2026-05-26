
library(arrow)
library(dplyr)
library(tidyr)
library(stringr)
library(purrr)
library(readr)
library(fixest)
library(tibble)
library(broom)
library(modelsummary)

# Default paths (override via args if needed)
MONOPSONY_ROOT <- "/Users/kahrens/PP Dropbox/Achim Ahrens/monopsony_data"
XFIT_BASE      <- file.path(MONOPSONY_ROOT, "dube_monopsony-selected", "xfit")
DATA_PATH      <- file.path(MONOPSONY_ROOT, "dube_monopsony", "Data")

# File name pattern: xfit_<outcome>_fold<f>_of<K>_learner<L>_foldseed<seed>.parquet
# Outcome may contain underscores (e.g. "log_duration", "log_reward").
FILE_PATTERN <- "^xfit_(.+)_fold(\\d+)_of(\\d+)_learner(\\d+)_foldseed(\\d+)\\.parquet$"

parse_xfit_meta <- function(xfit_dir) {
  files <- list.files(xfit_dir, pattern = "\\.parquet$", full.names = TRUE)
  m <- str_match(basename(files), FILE_PATTERN)
  tibble(
    path     = files,
    outcome  =            m[, 2],
    fold     = as.integer(m[, 3]),
    K        = as.integer(m[, 4]),
    learner  = as.integer(m[, 5]),
    foldseed = as.integer(m[, 6])
  )
}

read_subset <- function(meta_df) {
  meta_df |>
    mutate(data = map(path, read_parquet)) |>
    select(-path) |>
    unnest(data)
}

load_ipeirotis <- function(data_path = DATA_PATH) {
  read_delim(
    file.path(data_path, "Monopsony_cleaned.csv"),
    delim = ";", show_col_types = FALSE
  )
}

# ------------------------------------------------------------------------------
# Wrapper: fit DML residual-on-residual feols for a given (K, learner, foldseed).
# Returns S3 "dml_fit" carrying the feols object plus R^2 for the outcome (Y)
# and treatment (D) equations computed from the out-of-fold residuals.
# ------------------------------------------------------------------------------
fit_dml_feols <- function(K, learner, foldseed,
                          xfit_mode = "xclust",
                          xfit_base = XFIT_BASE,
                          data_path = DATA_PATH,
                          ipeirotis = NULL) {

  xfit_dir <- file.path(xfit_base, sprintf("%s_K%d", xfit_mode, K))
  if (!dir.exists(xfit_dir)) stop("Directory not found: ", xfit_dir)

  meta <- parse_xfit_meta(xfit_dir) |>
    filter(learner == !!learner, foldseed == !!foldseed)

  pick <- function(outcome_name, hat_col) {
    meta |>
      filter(outcome == outcome_name) |>
      read_subset() |>
      rename(!!hat_col := hat)
  }

  dta_D <- pick("log_reward",   "hat_log_reward")
  dta_Y <- pick("log_duration", "hat_log_duration")

  dta <- left_join(dta_Y, dta_D,
                   by = c("fold", "K", "learner", "foldseed", "row_id"))

  if (is.null(ipeirotis)) ipeirotis <- load_ipeirotis(data_path)

  dta <- dta |>
    left_join(ipeirotis |> mutate(index = index + 1),
              by = c("row_id" = "index")) |>
    mutate(resid_Y = log_duration - hat_log_duration,
           resid_D = log_reward   - hat_log_reward)

  fit <- feols(resid_Y ~ resid_D, data = dta, cluster = ~requester_id)

  r2_Y <- 1 - var(dta$resid_Y, na.rm = TRUE) / var(dta$log_duration, na.rm = TRUE)
  r2_D <- 1 - var(dta$resid_D, na.rm = TRUE) / var(dta$log_reward,   na.rm = TRUE)

  structure(
    list(
      fit       = fit,
      r2_Y      = r2_Y,
      r2_D      = r2_D,
      nobs      = nobs(fit),
      K         = K,
      learner   = learner,
      foldseed  = foldseed,
      xfit_mode = xfit_mode
    ),
    class = "dml_fit"
  )
}

# ------------------------------------------------------------------------------
# Median aggregation across S replications (Chernozhukov et al. 2018).
#   theta_med = median_s { theta_s }
#   se_med    = sqrt( median_s { se_s^2 + (theta_s - theta_med)^2 } )
# R^2 reported as the median across replications.
# ------------------------------------------------------------------------------
median_aggregate_dml <- function(fits, coef_name = "resid_D") {
  stopifnot(length(fits) > 0,
            all(vapply(fits, inherits, logical(1), "dml_fit")))

  ests <- vapply(fits, function(f) coef(f$fit)[coef_name],                  numeric(1))
  ses  <- vapply(fits, function(f) sqrt(diag(vcov(f$fit)))[coef_name],      numeric(1))
  r2Y  <- vapply(fits, `[[`, numeric(1), "r2_Y")
  r2D  <- vapply(fits, `[[`, numeric(1), "r2_D")
  ns   <- vapply(fits, `[[`, numeric(1), "nobs")

  theta_med <- stats::median(ests)
  se_med    <- sqrt(stats::median(ses^2 + (ests - theta_med)^2))

  structure(
    list(
      estimate  = unname(theta_med),
      std.error = unname(se_med),
      S         = length(fits),
      r2_Y      = mean(r2Y),
      r2_D      = mean(r2D),
      nobs      = stats::median(ns),
      individual = tibble(
        s         = seq_along(fits),
        foldseed  = vapply(fits, `[[`, integer(1), "foldseed"),
        estimate  = unname(ests),
        std.error = unname(ses),
        r2_Y      = r2Y,
        r2_D      = r2D
      )
    ),
    class = "dml_median"
  )
}

# Convenience: fit DML across all seeds for given (K, learner) and aggregate.
fit_dml_all_seeds <- function(K, learner, xfit_mode = "xclust",
                              xfit_base = XFIT_BASE, data_path = DATA_PATH) {

  ipeirotis <- load_ipeirotis(data_path)
  xfit_dir  <- file.path(xfit_base, sprintf("%s_K%d", xfit_mode, K))
  seeds <- parse_xfit_meta(xfit_dir) |>
    filter(learner == !!learner) |>
    distinct(foldseed) |> pull(foldseed) |> sort()

  fits <- map(seeds, ~ fit_dml_feols(
    K = K, learner = learner, foldseed = .x,
    xfit_mode = xfit_mode, xfit_base = xfit_base,
    ipeirotis = ipeirotis
  ))
  names(fits) <- sprintf("seed=%d", seeds)
  fits
}

# ------------------------------------------------------------------------------
# broom/modelsummary integration
# ------------------------------------------------------------------------------
tidy.dml_fit <- function(x, ...) {
  est <- coef(x$fit)["resid_D"]
  se  <- sqrt(diag(vcov(x$fit)))["resid_D"]
  tibble(
    term      = "theta",
    estimate  = unname(est),
    std.error = unname(se),
    statistic = unname(est / se),
    p.value   = 2 * stats::pnorm(-abs(unname(est / se)))
  )
}
glance.dml_fit <- function(x, ...) {
  tibble(
    nobs       = x$nobs,
    r2.outcome = x$r2_Y,
    r2.treat   = x$r2_D,
    K          = x$K,
    learner    = x$learner,
    foldseed   = x$foldseed
  )
}
tidy.dml_median <- function(x, ...) {
  tibble(
    term      = "theta",
    estimate  = x$estimate,
    std.error = x$std.error,
    statistic = x$estimate / x$std.error,
    p.value   = 2 * stats::pnorm(-abs(x$estimate / x$std.error))
  )
}
glance.dml_median <- function(x, ...) {
  tibble(
    nobs       = x$nobs,
    S          = x$S,
    r2.outcome = x$r2_Y,
    r2.treat   = x$r2_D
  )
}
.S3method("tidy",   "dml_fit",    tidy.dml_fit)
.S3method("glance", "dml_fit",    glance.dml_fit)
.S3method("tidy",   "dml_median", tidy.dml_median)
.S3method("glance", "dml_median", glance.dml_median)

# Map of GOF rows shown by modelsummary, in order.
DML_GOF_MAP <- tribble(
  ~raw,         ~clean,             ~fmt,
  "nobs",       "N",                "%.0f",
  "S",          "S (replications)", "%.0f",
  "r2.outcome", "R^2 outcome eq.",  "%.3f",
  "r2.treat",   "R^2 treatment eq.","%.3f",
  "K",          "K",                "%.0f",
  "learner",    "Learner",          "%.0f",
  "foldseed",   "Fold seed",        "%.0f"
)

export_dml_table <- function(fits, output = NULL, ...) {
  args <- list(
    fits,
    gof_map  = DML_GOF_MAP,
    coef_map = c("theta" = "theta (resid_Y ~ resid_D)"),
    ...
  )
  if (!is.null(output)) args$output <- output
  do.call(modelsummary, args)
}

# ------------------------------------------------------------------------------
# Example: fit S = 5 seeds at (K=3, learner=11), median-aggregate, export table.
# ------------------------------------------------------------------------------
fits <- fit_dml_all_seeds(K = 3, learner = 9, xfit_mode = "xclust")
med  <- median_aggregate_dml(fits)

export_dml_table(c(fits, list("Median agg." = med)))
