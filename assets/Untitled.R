
# Set random seed for reproducibility
set.seed(20241111)


# ==============================================================================
# Load and Prepare Data

# Load 401k data
dat <- read_dta("http://dmlguide.github.io/assets/dta/PVW_data.dta")

# Define control variables
control_names <- c("age", "tw", "inc", "fsize", "db", "marr", 
                   "twoearn", "pira", "hown")

# Extract variables
y <- dat$net_tfa
D <- dat$e401
X <- as.matrix(dat[, control_names])

# Define model configuration
learners = list(
  list(fun = mdl_ranger,
       args = list(num.trees = 1000, # random forest
                   max.depth = 8)))

learners_DX = list(
  list(fun = mdl_ranger,
       args = list(num.trees = 1000, # random forest
                   max.depth = 4)))

# ==============================================================================
# Analysis

# 1. DML ate with sample splitting
ate_fit <- ddml_ate(y, D, X,
                    learners = learners,
                    learners_DX = learners_DX,
                    sample_folds = 10,
                    ensemble_type = "average",
                    trim = 0.001,
                    silent = FALSE)
summary(ate_fit)
