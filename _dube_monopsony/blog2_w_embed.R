
suppressPackageStartupMessages({
  library(ddml)
  library(fixest)
  library(modelsummary)
  library(dplyr)
  library(tidyr)
  library(tidylog)
}) 

script_dir <- "/Users/kahrens/MyProjects/JEL/website/_dube_monopsony"
data_path  <- file.path(script_dir, "data", "monopsony_blog.rds")
out_file   <- file.path(script_dir, "results_entry2.rds")
foldvar_path <- file.path("/Users/kahrens/PP Dropbox/Achim Ahrens/monopsony_data/foldvars")
embed_path <- file.path("/Users/kahrens/PP Dropbox/Achim Ahrens/monopsony_data/Embeddings")

# ==============================================================================
# auxiliary functions
# ==============================================================================

get_embeddings <- function(seed,k,foldnum,var=c("log_reward","log_duration")) {
  require(arrow)
  embed <- read_parquet(file.path(embed_path,paste0("finetuned_train_",var,"_fold",k,"_foldseed",seed,"_foldnum",foldnum,".parquet")))
  return(embed)
}

get_foldvar <- function(seed,foldnum,cluster="cluster_") {
  df <- readr::read_csv(file.path(foldvar_path,paste0("foldvar_",cluster,seed,"_",foldnum,".csv")))
  return(df)
}

# ==============================================================================
# learner specification
# ==============================================================================

nfolds <- 3L

dat <- readRDS(data_path)

n <- nrow(dat)

set.seed(12487)
fvar <- get_foldvar(12487,3)
dat <- left_join(dat,fvar,by=c("group_id"))
out <- dat |> select(group_id,id,requester_id,log_duration,log_reward)
out <- out |> 
        mutate(pred_log_reward=NA,
               pred_log_duration=NA
        )

for (k in 1:nfolds) {

  # load embeddings
  y_embed <- get_embeddings(seed=12487,k=k,foldnum=3,var="log_duration")
  D_embed <- get_embeddings(seed=12487,k=k,foldnum=3,var="log_reward")

  # join embeddings
  dat_y <- tidylog::left_join(dat,
                              y_embed |> select(starts_with("feat_"),row_id),
                              by=c("id"="row_id"))

  dat_D <- tidylog::left_join(dat,
                              D_embed |> select(starts_with("feat_"),row_id),
                              by=c("id"="row_id"))

  mean(dat_y$id == dat_D$id)
  mean(1:n == dat_D$id)

  # train data indicator
  train_id <- dat$fid!=k

  # convert to matrix
  dat_y <- dat_y |> 
            select(log_duration,time_allotted:appr_num_gt1000p,starts_with("feat_")) |>
            as.matrix()
  dat_D <- dat_D |>  
            select(log_reward,time_allotted:appr_num_gt1000p,starts_with("feat_")) |>
            as.matrix()      

  # fitting E[Y|X]
  fitY <- mdl_xgboost(y = dat_y[train_id,1,drop=TRUE],
                      X = dat_y[train_id,-1,drop=FALSE],
                      nrounds               = 800L,
                      min_child_weight      = 500L,
                      eval_set              = 0.1,
                      early_stopping_rounds = 10L,
                      nthread               = 1L)
  hatY <- predict(fitY, newdata = dat_y[!train_id,-1,drop=FALSE])

  # fitting E[D|X]
  fitD <- mdl_xgboost(y = dat_D[train_id,1,drop=TRUE],
                      X = dat_D[train_id,-1,drop=FALSE],
                      nrounds               = 800L,
                      min_child_weight      = 500L,
                      eval_set              = 0.1,
                      early_stopping_rounds = 10L,
                      nthread               = 1L)
  hatD <- predict(fitD, newdata = dat_D[!train_id,-1,drop=FALSE])

  out$pred_log_duration[!train_id] <- hatY
  out$pred_log_reward[!train_id] <- hatD

}

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

# ==============================================================================
# Save results (modelsummary_list shim, mirroring blog1_wo_embed.R)
# ==============================================================================

co      <- summary(ols_fit)$coeftable
ddml_b  <- unname(co["resid_log_reward", "Estimate"])
ddml_se <- unname(co["resid_log_reward", "Std. Error"])

ddml_ms <- list(
  tidy = data.frame(
    term      = "log_reward",
    estimate  = ddml_b,
    std.error = ddml_se,
    statistic = ddml_b / ddml_se,
    p.value   = 2 * pnorm(-abs(ddml_b / ddml_se))
  ),
  glance = data.frame(
    nobs = nrow(out),
    K    = 3L,
    r2_y = R2y,
    r2_d = R2d
  )
)
class(ddml_ms) <- "modelsummary_list"

models <- list("DML" = ddml_ms)
saveRDS(models, out_file)
cat("Wrote ", out_file, "\n", sep = "")
