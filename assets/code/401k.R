
################################################################################
###### preparation                                                        ######
################################################################################
library(haven)
library(ddml)
dat <- read_dta("http://dmlguide.github.io/assets/dta/PVW_data.dta")
library(texreg)

set.seed(20241111)

# Define control variables
control_names <- c("age", "tw", "inc", "fsize", "db", "marr", 
                   "twoearn", "pira", "hown")

# Extract variables
y <- dat$net_tfa
Z <- dat$e401
D <- dat$p401
X <- as.matrix(dat[, control_names])

################################################################################
###### settings                                                           ######
################################################################################

# Define model configuration
learners = list(
  list(fun = mdl_ranger,
       args = list(num.trees = 1000, # random forest
                   max.depth = 8)))

learners_DX = list(
  list(fun = mdl_ranger,
       args = list(num.trees = 1000, # random forest
                   max.depth = 4)))

################################################################################
###### estimation                                                         ######
################################################################################

# DML estimation of the PLR coefficient
plm_fit <- ddml_plm(y, Z, X,
                    learners = learners,
                    learners_DX = learners_DX,
                    sample_folds = 10,
                    ensemble_type = "average"
)

# DML estimation of the ATE 
ate_fit <- ddml_ate(y, Z, X,
                    learners = learners,
                    learners_DX = learners_DX,
                    sample_folds = 10,
                    ensemble_type = "average",
                    trim = 0.001
)
summary(ate_fit)

# create screenreg-compatible object from `ate_fit`
ate_texreg <- createTexreg(coef.names="elligibility",
                           coef=summary(ate_fit)[1],
                           se=summary(ate_fit)[2],
                           pvalues=summary(ate_fit)[4]
)
screenreg(list(plm_fit$ols_fit,ate_texreg),
          include.ci=FALSE,
          custom.coef.map=list("D_r"="elligibility",
                               "elligibility"="elligibility") 
)


################################################################################
###### estimation                                                         ######
################################################################################

# DML estimation of the PLR coefficient
pliv_fit <- ddml_pliv(y, D, Z, X,
                    learners = learners,
                    sample_folds = 10,
                    ensemble_type = "average"
)

# DML estimation of the ATE 
late_fit <- ddml_late(y, D, Z, X,
                    learners = learners, 
                    sample_folds = 10,
                    ensemble_type = "average",
                    trim = 0.001
                    )
# create screenreg-compatible object from `late_fit`
late_texreg <- createTexreg(coef.names="participation",
                           coef=summary(late_fit)[1],
                           se=summary(late_fit)[2],
                           pvalues=summary(late_fit)[4]
                           )
 
screenreg(list(pliv_fit$iv_fit,late_texreg),
          include.ci=FALSE,
          custom.coef.map=list("D_r"="participation",
                               "participation"="participation") 
          )
