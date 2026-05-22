# Walks each subfolder of the monopsony_data/intermediate tree and loads the
# per-seed cvc_seed*_K*.RData files into one named list per subfolder
# (iid_K3, xclust_K3, xclust_K5), exposed as separate objects in the global env.

suppressPackageStartupMessages({
  library(stringr)
  library(ddml)
})

intermediate_root <- "/Users/kahrens/PP Dropbox/Achim Ahrens/monopsony_data/intermediate"

subfolders <- list.dirs(intermediate_root, recursive = FALSE)

load_rdata_to_list <- function(file) {
  env <- new.env()
  load(file, envir = env)
  as.list(env)
}

for (sub in subfolders) {
  tag   <- basename(sub)
  files <- list.files(sub, pattern = "\\.RData$", full.names = TRUE)
  if (length(files) == 0L) {
    cat(sprintf("[%s] no .RData files found, skipping\n", tag))
    next
  }

  cat(sprintf("[%s] loading %d file(s)...\n", tag, length(files)))

  seeds <- as.integer(str_match(basename(files), "seed(\\d+)")[, 2])
  ord   <- order(seeds)
  files <- files[ord]
  seeds <- seeds[ord]

  results <- lapply(files, load_rdata_to_list)
  names(results) <- sprintf("seed%d", seeds)

  assign(tag, results, envir = globalenv())
  cat(sprintf("[%s] assigned list with %d entries\n", tag, length(results)))
}

cat("Done.\n")

get_r2 <- function(fit_list, which = c("y_X", "D1_X"), agg="median", learner=1) { 
  if (which == "y_X") {
    out <- unlist(lapply(fit_list,function(x) x$diag_obj[[1]]$y_X$r2[learner]))
  } else if (which == "D1_X") {
    out <- unlist(lapply(fit_list,function(x) x$diag_obj[[1]]$D1_X$r2[learner]))
  } else {
    stop("Invalid 'which' argument. Use 'y_X' or 'D1_X'.")
  } 
  if (agg == "median") {
    return(median(out))
  } else if (agg == "mean") {
    return(mean(out))
  } else if (is.numeric(agg)) {
    return(out[agg])
  } else {
    stop("Invalid 'agg' argument. Use 'median' or 'mean'.")
  }
}

################################################################################
### Table 1: comparison of XGB reference specification across seeds          ###
################################################################################

summary(xclust_K3[[1]]$fit)$coefficients[,,"XGB 3"]
summary(xclust_K3[[2]]$fit)$coefficients[,,"XGB 3"]
summary(xclust_K3[[3]]$fit)$coefficients[,,"XGB 3"]
summary(xclust_K3[[4]]$fit)$coefficients[,,"XGB 3"]
summary(xclust_K3[[5]]$fit)$coefficients[,,"XGB 3"]

# aggregation for comparison; the baseline specification
summary(ddml_rep(lapply(xclust_K3,function(x) x$fit)))$coefficients[,,"XGB 3"]

################################################################################
### Table 2: different learner                                               ###
################################################################################

# the baseline specification
summary(ddml_rep(lapply(xclust_K3,function(x) x$fit)))$coefficients[,,"XGB 3"]

# comparison with lasso
summary(ddml_rep(lapply(xclust_K3,function(x) x$fit)))$coefficients[,,"CV-Lasso"]

################################################################################
### Table 3: aggregated iid vs clustering                                    ###
################################################################################

# the baseline specification
summary(ddml_rep(lapply(xclust_K3,function(x) x$fit)))$coefficients[,,"XGB 3"]

# iid, K=3
summary(ddml_rep(lapply(iid_K3,function(x) x$fit)))$coefficients[,,"XGB 3"]

################################################################################
### Table 4: comparison K=3 vs K=5                                           ###
################################################################################

# the baseline specification
summary(ddml_rep(lapply(xclust_K3,function(x) x$fit)))$coefficients[,,"XGB 3"]

# clustering, K=5
summary(ddml_rep(lapply(xclust_K5,function(x) x$fit)))$coefficients[,,"XGB 3"]

 