# =========================
# 401(k) replication in R
#  Using the ddml package
#
# Each `# @snippet:NAME ... # @end` block is extracted by
# `_401k/build_snippets.py` into `_includes/401k/NAME_r.txt` and imported by
# `examples/401k.md` via Liquid. Keep the snippets self-contained enough
# that they read well on their own in the blog.
#
# Running this script also writes R/PVW_ddml_package_output.txt with
# `# @snippet:NAME ... # @end` blocks for the printed outputs that the
# blog imports as the "Output" tab.

OUTFILE <- file.path("R", "PVW_ddml_package_output.txt")

cat("R version:\n"); print(R.version.string)


# =============================================================
# (1) Data preparation
# =============================================================

# @snippet:data_code
library(haven)
library(ddml)
library(ranger)
library(tidymodels)

dat <- read_dta("https://dmlguide.github.io/assets/dta/PVW_data.dta")

set.seed(20241111)

# Define control variables
control_names <- c("age", "tw", "inc", "fsize", "db", "marr",
                   "twoearn", "pira", "hown")

# Extract variables
y      <- dat$net_tfa
D      <- dat$e401     # eligibility
D_part <- dat$p401     # participation
Z      <- dat$e401     # instrument
X      <- as.matrix(dat[, control_names])
# @end


# =============================================================
# (2) Learner settings
# =============================================================

# @snippet:learner_code
# Random forest with 1000 trees: depth 8 for the outcome equation,
# depth 4 for the remaining nuisance functions.
learners <- list(
  list(fun = mdl_ranger,
       args = list(num.trees = 1000,
                   max.depth = 8))
)

learners_DX <- list(
  list(fun = mdl_ranger,
       args = list(num.trees = 1000,
                   max.depth = 4))
)

# Small broom-style tidier so we can build comparison tibbles for any
# ddml fit. Pulls the structural-parameter row (D1 for PLR/PLIV,
# ATE for ddml_ate, LATE for ddml_late).
tidy_ddml <- function(fit, model, term) {
  s <- summary(fit)$coefficients
  tibble(
    model     = model,
    term      = term,
    estimate  = s[1, 1, 1],
    std.error = s[1, 2, 1],
    statistic = s[1, 3, 1],
    p.value   = s[1, 4, 1],
    n         = fit$nobs
  )
}
# @end


# =============================================================
# (3) The effect of 401(k) eligibility — PLR + ATE
# =============================================================

# @snippet:elig_code
# DML estimation of the partially linear regression (PLR) coefficient
plm_fit <- ddml_plm(y, D, X,
                    learners      = learners,
                    learners_DX   = learners_DX,
                    sample_folds  = 10,
                    ensemble_type = "average")

# DML estimation of the average treatment effect (ATE)
ate_fit <- ddml_ate(y, D, X,
                    learners      = learners,
                    learners_DX   = learners_DX,
                    sample_folds  = 10,
                    ensemble_type = "average",
                    trim          = 0.001)

# Tidy comparison of the two estimands
elig_tbl <- bind_rows(
  tidy_ddml(plm_fit, "PLR", "eligibility"),
  tidy_ddml(ate_fit, "ATE", "eligibility")
)
print(elig_tbl)
# @end


# =============================================================
# (4) The effect of 401(k) participation — PLIV + LATE
# =============================================================

# @snippet:part_code
# DML estimation of the partially linear IV regression (PLIV) coefficient
pliv_fit <- ddml_pliv(y, D_part, Z, X,
                      learners      = learners,
                      sample_folds  = 10,
                      ensemble_type = "average")

# DML estimation of the local average treatment effect (LATE)
late_fit <- ddml_late(y, D_part, Z, X,
                      learners      = learners,
                      sample_folds  = 10,
                      ensemble_type = "average",
                      trim          = 0.001)

# Tidy comparison of the two estimands
part_tbl <- bind_rows(
  tidy_ddml(pliv_fit, "PLIV", "participation"),
  tidy_ddml(late_fit, "LATE", "participation")
)
print(part_tbl)
# @end


# =============================================================
# Persist the captured outputs to the snippet file.
# =============================================================

elig_out_txt <- paste(capture.output(print(elig_tbl)), collapse = "\n")
part_out_txt <- paste(capture.output(print(part_tbl)), collapse = "\n")

out_lines <- c(
  "# Outputs produced by PVW_ddml_package.R.",
  "# `# @snippet:NAME ... # @end` blocks are imported by examples/401k.md via",
  "# _includes/401k/ -- keep these in sync with the .R script when re-running.",
  "",
  "",
  "# @snippet:elig_out",
  elig_out_txt,
  "# @end",
  "",
  "",
  "# @snippet:part_out",
  part_out_txt,
  "# @end",
  ""
)
writeLines(out_lines, OUTFILE)

cat("\n========================================\n")
cat("401(k) replication complete!\n")
cat(sprintf("Wrote %s\n", OUTFILE))
