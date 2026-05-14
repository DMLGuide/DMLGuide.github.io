
suppressPackageStartupMessages({
  library(ddml)
  library(fixest)
  library(modelsummary)
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
                dat, "log_reward",   seed, foldnum, cluster,
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

    return(list(ols_fit = ols_fit, R2y = R2y, R2d = R2d))

}

fit1 <- ddml_with_embed(seed=12487,foldnum=3,learner=xgb_spec,cluster=TRUE)
fit2 <- ddml_with_embed(seed=17929,foldnum=3,learner=xgb_spec,cluster=TRUE)
fit3 <- ddml_with_embed(seed=28327,foldnum=3,learner=xgb_spec,cluster=TRUE)
fit4 <- ddml_with_embed(seed=63595,foldnum=3,learner=xgb_spec,cluster=TRUE)
fit5 <- ddml_with_embed(seed=85886,foldnum=3,learner=xgb_spec,cluster=TRUE)
fit6 <- ddml_with_embed(seed=12487,foldnum=3,learner=lasso_spec,cluster=TRUE)
fit7 <- ddml_with_embed(seed=12487,foldnum=5,learner=xgb_spec,cluster=TRUE)
fit8 <- ddml_with_embed(seed=12487,foldnum=3,learner=xgb_spec,cluster=FALSE)

# ==============================================================================
# Save results (modelsummary_list shims, mirroring blog1 / blog2)
# ==============================================================================

out_file <- file.path(script_dir, "results_entry3.rds")

to_modelsummary <- function(fit, K) {
  co <- summary(fit$ols_fit)$coeftable
  b  <- unname(co["resid_log_reward", "Estimate"])
  se <- unname(co["resid_log_reward", "Std. Error"])
  ms <- list(
    tidy = data.frame(
      term      = "log_reward",
      estimate  = b,
      std.error = se,
      statistic = b / se,
      p.value   = 2 * pnorm(-abs(b / se))
    ),
    glance = data.frame(
      nobs = nobs(fit$ols_fit),
      K    = K,
      r2_y = fit$R2y,
      r2_d = fit$R2d
    )
  )
  class(ms) <- "modelsummary_list"
  ms
}

# --- Median-of-medians over the multi-seed sweep (paper §5, eq. 23) ---------
seed_fits <- list(fit1, fit2, fit3, fit4, fit5)
seed_b  <- sapply(seed_fits, function(f) {
  unname(summary(f$ols_fit)$coeftable["resid_log_reward", "Estimate"])
})
seed_se <- sapply(seed_fits, function(f) {
  unname(summary(f$ols_fit)$coeftable["resid_log_reward", "Std. Error"])
})
b_med  <- median(seed_b)
se_med <- sqrt(median(seed_se^2 + (seed_b - b_med)^2))

median_ms <- list(
  tidy = data.frame(
    term      = "log_reward",
    estimate  = b_med,
    std.error = se_med,
    statistic = b_med / se_med,
    p.value   = 2 * pnorm(-abs(b_med / se_med))
  ),
  glance = data.frame(
    nobs = nobs(fit1$ols_fit),
    K    = 3L,
    r2_y = median(sapply(seed_fits, function(f) f$R2y)),
    r2_d = median(sapply(seed_fits, function(f) f$R2d))
  )
)
class(median_ms) <- "modelsummary_list"

# --- Grouped export ---------------------------------------------------------
models <- list(
  # (A) Learner sweep: XGBoost vs Lasso (K=3, cluster, seed=12487).
  learner = list(
    "XGBoost" = to_modelsummary(fit1, K = 3L),
    "Lasso"   = to_modelsummary(fit6, K = 3L)
  ),
  # (C) Multi-seed: 5 seeds + median-of-medians (XGBoost, K=3, cluster).
  multiseed = list(
    "seed=12487"               = to_modelsummary(fit1, K = 3L),
    "seed=17929"               = to_modelsummary(fit2, K = 3L),
    "seed=28327"               = to_modelsummary(fit3, K = 3L),
    "seed=63595"               = to_modelsummary(fit4, K = 3L),
    "seed=85886"               = to_modelsummary(fit5, K = 3L),
    "median-of-medians (S=5)"  = median_ms
  ),
  # (D) K sweep: K=3 vs K=5 (XGBoost, cluster, seed=12487).
  K = list(
    "K=3" = to_modelsummary(fit1, K = 3L),
    "K=5" = to_modelsummary(fit7, K = 5L)
  ),
  # (E) Fold-mode sweep: cluster vs IID (XGBoost, K=3, seed=12487).
  foldmode = list(
    "Cluster" = to_modelsummary(fit1, K = 3L),
    "IID"     = to_modelsummary(fit8, K = 3L)
  )
)
saveRDS(models, out_file)
cat("Wrote ", out_file, "\n", sep = "")