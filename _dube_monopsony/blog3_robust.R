
suppressPackageStartupMessages({
  library(ddml)
  library(fixest)
  library(modelsummary)
  library(broom)
  library(dplyr)
  library(tidyr)
})

script_dir <- "/Users/kahrens/MyProjects/JEL/website/_dube_monopsony"
data_path  <- file.path(script_dir, "data", "monopsony_blog.rds") 
foldvar_path <- file.path("/Users/kahrens/PP Dropbox/Achim Ahrens/monopsony_data/foldvars")
embed_path <- file.path("/Users/kahrens/PP Dropbox/Achim Ahrens/monopsony_data/Embeddings")
embed5_path <- file.path("/Users/kahrens/PP Dropbox/Achim Ahrens/monopsony_data/Embeddings5")
embedNoClust_path <- file.path('/Users/kahrens/PP Dropbox/Achim Ahrens/monopsony_data/Embeddings_noclust')

# ==============================================================================
# auxiliary functions
# ==============================================================================

get_embeddings <- function(seed,k,foldnum,var=c("log_reward","log_duration"),cluster) {
  require(arrow)
  var <- match.arg(var)
  if (foldnum==3 & cluster) {
    path <- embed_path
  } else if (foldnum==5 & cluster) {
    path <- embed5_path
  } else if (foldnum==3 & !cluster) {
    path <- embedNoClust_path
  } else {
    stop("embeddings not available")
  }
  embed <- read_parquet(file.path(path,paste0("finetuned_train_",var,"_fold",k,"_foldseed",seed,"_foldnum",foldnum,".parquet")))
  return(embed)
}

get_foldvar <- function(seed,foldnum,cluster) {
  if (cluster) {
    cluster_str <- "cluster_"
  } else {
    cluster_str <- ""
  }
  df <- readr::read_csv(file.path(foldvar_path,paste0("foldvar_",cluster_str,seed,"_",foldnum,".csv")))
  return(df)
}

# ==============================================================================
# learner specification
# ==============================================================================

xgb_spec <- list(
  what = mdl_xgboost,
  args = list(nrounds               = 800L,
              min_child_weight      = 500L,
              eval_set              = 0.1,
              early_stopping_rounds = 10L,
              nthread               = 1L)
)

lasso_spec <- list(
  what = mdl_glmnet,
  args = list(alpha=1)
)

# Cross-fit a single equation E[var | hand-features, fine-tuned embedding].
# Returns a length-n vector of out-of-fold predictions aligned to dat$id.
crossfit_with_embed <- function(dat, var, seed, foldnum, cluster,
                                learner, hand_features) {
    n    <- nrow(dat)
    pred <- rep(NA_real_, n)

    # Project once to the columns the join + feature matrix actually need, so
    # dat_k doesn't drag every original column alongside the 768 embedding
    # features — peak RAM in left_join is what gets this OOM-killed on 16 GB.
    dat <- dat |> select(id, fid, all_of(var), all_of(hand_features))

    for (k in 1:foldnum) {
        emb  <- get_embeddings(seed=seed, k=k, foldnum=foldnum,
                               var=var, cluster=cluster)
        dat_k <- tidylog::left_join(
                     dat,
                     emb |> select(starts_with("feat_"), row_id),
                     by = c("id" = "row_id"))
        stopifnot(identical(dat$id, dat_k$id))
        train_id <- dat_k$fid != k
        X <- dat_k |>
               select(all_of(var), all_of(hand_features),
                      starts_with("feat_")) |>
               as.matrix()
        rm(emb, dat_k); gc(verbose = FALSE)

        fit <- do.call(learner$what,
                       c(list(y = X[train_id, 1, drop = TRUE],
                              X = X[train_id, -1, drop = FALSE]),
                         learner$args))
        hat <- predict(fit, newdata = X[!train_id, -1, drop = FALSE])
        stopifnot(length(hat) == sum(!train_id))
        pred[!train_id] <- hat
        rm(X, fit, hat); gc(verbose = FALSE)
    }

    return(pred)
}

ddml_with_embed <- function(seed,foldnum,learner,cluster=TRUE) {

    dat <- readRDS(data_path)
    n <- nrow(dat)

    set.seed(seed)
    fvar <- get_foldvar(seed=seed,foldnum=foldnum,cluster=cluster)
    dat <- left_join(dat, fvar, by = "group_id")

    # Hand-coded feature names, materialised once so the loop doesn't depend on
    # column-order tidyselect ranges.
    stopifnot(c("time_allotted","appr_num_gt1000p") %in% names(dat))
    nm <- names(dat)
    hand_features <- nm[match("time_allotted", nm):match("appr_num_gt1000p", nm)]

    out <- dat |>
        select(group_id, id, requester_id, log_duration, log_reward) |>
        mutate(
            pred_log_duration = crossfit_with_embed(
                dat, "log_duration", seed, foldnum, cluster,
                learner, hand_features),
            pred_log_reward   = crossfit_with_embed(
                dat, "log_reward", seed, foldnum, cluster,
                learner, hand_features)
        )

    out <- out |>
    mutate(
            resid_log_duration=log_duration-pred_log_duration,
            resid_log_reward=log_reward-pred_log_reward
    )

    ols_fit <- feols(
                    resid_log_duration~resid_log_reward,
                    data=out,
                    cluster=~requester_id
                    )

    R2y <- 1 - sum((out$log_duration - out$pred_log_duration)^2) /
                sum((out$log_duration - mean(out$log_duration))^2)

    R2d <- 1 - sum((out$log_reward   - out$pred_log_reward)^2) /
                sum((out$log_reward   - mean(out$log_reward))^2)

    # Return a modelsummary_list (tidy + glance). The feols object itself is
    # discarded so we don't carry it across seeds. The displayed term is
    # renamed from the residualised regressor back to "log_reward" to match
    # the qmd's coef_map.
    td <- as.data.frame(broom::tidy(ols_fit))
    td$term[td$term == "resid_log_reward"] <- "log_reward"
    ms <- list(
      tidy   = td,
      glance = data.frame(nobs = nobs(ols_fit), r2_y = R2y, r2_d = R2d)
    )
    class(ms) <- "modelsummary_list"
    ms
}

# ==============================================================================
# Spec registry
# ==============================================================================
# Each spec is one configuration of (K, learner, fold-clustering). Per-spec
# runs are independent: each holds only one spec's fits in memory, converts
# each seed's feols to a tidy modelsummary_list (so the feols object itself
# is never persisted), and saves its lean payload to results_entry3_<key>.rds.
# The combine step reads the four part files and writes the final
# results_entry3.rds consumed by Monopsony_Robustness.qmd.

seeds <- c(12487,17929,28327,63595,85886)

specs <- list(
  baseline = list(
    label   = "Baseline (K=3, XGB, cluster)",
    K       = 3L,
    foldnum = 3L,
    learner = xgb_spec,
    cluster = TRUE
  ),
  K5 = list(
    label   = "K=5, XGB, cluster",
    K       = 5L,
    foldnum = 5L,
    learner = xgb_spec,
    cluster = TRUE
  ),
  lasso = list(
    label   = "K=3, Lasso, cluster",
    K       = 3L,
    foldnum = 3L,
    learner = lasso_spec,
    cluster = TRUE
  ),
  iid = list(
    label   = "K=3, XGB, IID folds",
    K       = 3L,
    foldnum = 3L,
    learner = xgb_spec,
    cluster = FALSE
  )
)

per_spec_path <- function(key) file.path(script_dir, paste0("results_entry3_", key, ".rds"))
out_file      <- file.path(script_dir, "results_entry3.rds")

# ==============================================================================
# Per-spec runner
# ==============================================================================

run_one_spec <- function(key) {
  cfg <- specs[[key]]
  if (is.null(cfg)) stop("unknown spec key: '", key, "'")
  cat("[blog3] running spec '", key, "' (", cfg$label, ")\n", sep = "")

  n <- length(seeds)
  per_seed <- vector("list", n)

  for (i in seq_along(seeds)) {
    s <- seeds[i]
    cat("[blog3]  seed ", s, " (", i, "/", n, ")\n", sep = "")
    ms <- ddml_with_embed(seed = s, foldnum = cfg$foldnum,
                          learner = cfg$learner, cluster = cfg$cluster)
    ms$glance$K <- cfg$K
    per_seed[[i]] <- ms
    rm(ms); gc(verbose = FALSE)
  }
  names(per_seed) <- paste0("seed=", seeds)

  payload <- list(
    spec_key = key, label = cfg$label, K = cfg$K,
    seeds    = seeds,
    per_seed = per_seed
  )
  saveRDS(payload, per_spec_path(key))
  cat("[blog3] wrote ", per_spec_path(key), "\n", sep = "")
  invisible(payload)
}

# ==============================================================================
# Median-of-medians aggregation (paper §5, eq. 23)
# ==============================================================================
# Operates on a per-spec payload: a list with $per_seed (list of modelsummary_list
# objects, one per seed) and $K. Returns a single modelsummary_list.

median_aggregate <- function(p) {
  pick <- function(ms) ms$tidy[ms$tidy$term == "log_reward", , drop = FALSE]
  b   <- vapply(p$per_seed, function(ms) pick(ms)$estimate,  numeric(1))
  se  <- vapply(p$per_seed, function(ms) pick(ms)$std.error, numeric(1))
  R2y <- vapply(p$per_seed, function(ms) ms$glance$r2_y,     numeric(1))
  R2d <- vapply(p$per_seed, function(ms) ms$glance$r2_d,     numeric(1))
  nobs1 <- p$per_seed[[1]]$glance$nobs

  b_med  <- median(b)
  se_med <- sqrt(median(se^2 + (b - b_med)^2))
  ms <- list(
    tidy = data.frame(
      term      = "log_reward",
      estimate  = b_med,
      std.error = se_med,
      statistic = b_med / se_med,
      p.value   = 2 * pnorm(-abs(b_med / se_med))
    ),
    glance = data.frame(
      nobs = nobs1,
      K    = p$K,
      r2_y = median(R2y),
      r2_d = median(R2d)
    )
  )
  class(ms) <- "modelsummary_list"
  ms
}

# ==============================================================================
# Combine: read the four part files, write results_entry3.rds
# ==============================================================================

combine_specs <- function() {
  parts <- list(); missing_files <- character()
  for (key in names(specs)) {
    p <- per_spec_path(key)
    if (!file.exists(p)) { missing_files <- c(missing_files, p); next }
    parts[[key]] <- readRDS(p)
  }
  if (length(missing_files) > 0) {
    stop("missing per-spec result file(s):\n  ",
         paste(missing_files, collapse = "\n  "),
         "\nrun the corresponding spec(s) first (e.g. Rscript blog3_robust.R baseline).")
  }

  bl <- parts$baseline

  models <- list(
    # (A) Per-seed + median for the baseline set (headline table).
    baseline_multiseed = c(
      bl$per_seed,
      list("median-of-medians (S=5)" = median_aggregate(bl))
    ),
    # (B) Cross-set comparison: medians only.
    cross_set = list(
      "Baseline (K=3, XGB, cluster)" = median_aggregate(parts$baseline),
      "K=5, XGB, cluster"            = median_aggregate(parts$K5),
      "K=3, Lasso, cluster"          = median_aggregate(parts$lasso),
      "K=3, XGB, IID folds"          = median_aggregate(parts$iid)
    )
  )
  saveRDS(models, out_file)
  cat("[blog3] wrote ", out_file, "\n", sep = "")
  invisible(models)
}

# ==============================================================================
# CLI dispatch
# ==============================================================================
# Usage:
#   Rscript blog3_robust.R                 # run all four specs, then combine
#   Rscript blog3_robust.R all             # same as above
#   Rscript blog3_robust.R baseline        # run a single spec (one of: baseline, K5, lasso, iid)
#   Rscript blog3_robust.R combine         # combine existing per-spec parts into results_entry3.rds

args   <- commandArgs(trailingOnly = TRUE)
action <- if (length(args) == 0) "all" else args[1]

valid <- c("all", "combine", names(specs))
if (!action %in% valid) {
  stop("Unknown action: '", action, "'. Use one of: ", paste(valid, collapse = ", "))
}

if (action == "all") {
  for (key in names(specs)) run_one_spec(key)
  combine_specs()
} else if (action == "combine") {
  combine_specs()
} else {
  run_one_spec(action)
}