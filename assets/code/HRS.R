 
#library(haven)
#library(readr)
#df <- read_dta("/Users/kahrens/Downloads/HRS_long.dta")
#dat <- df %>%
#  filter(wave >= 7) %>%
#  group_by(hhidpn) %>%
#  mutate(n = n()) %>%
#  filter(n == 5) %>%
#  filter((first_hosp > 7) & !is.na(first_hosp)) %>%
#  filter(ever_hospitalized == 1) %>% # redundant
#  filter(age_hosp <= 59)
#write_csv(dat,"/Users/kahrens/MyProjects/DMLGuide.github.io/assets/dta/HRS_long.csv")
#dat <- read_csv("/Users/kahrens/MyProjects/DMLGuide.github.io/assets/dta/HRS_long.csv")
 
## Including Plots
 
# Hard-coded hyperparameters
library("did")
#devtools::install_github("thomaswiemann/did",ref="dev-ddml")
library(ddml)
library(readr)
library(dplyr)
library(ggplot2)


dat <- read_csv("/Users/kahrens/MyProjects/DMLGuide.github.io/assets/dta/HRS_long.csv")


################################################################################
###### model setting                                                      ######
################################################################################

# Learners for E[Y|D=0,X] estimation
learners = list(
  list(fun = ols),
  list(fun = mdl_glmnet,
       args = list(alpha = 1)),
  list(fun = mdl_glmnet,
       args = list(alpha = 0)),
  list(fun = mdl_ranger,
       args = list(num.trees = 1000, # random forest, high regularization
                   min.node.size = 100)),
  list(fun = mdl_ranger,
       args = list(num.trees = 1000, # random forest, medium regularization
                   min.node.size = 10)),
  list(fun = mdl_ranger,
       args = list(num.trees = 1000, # random forest, low regularization
                   min.node.size = 1)))

# Hard-code learners for treatment reduced-form
learners_DX = list(
  list(fun = mdl_glm,
       args = list(family = "binomial")),
  list(fun = mdl_glmnet,
       args = list(family = "binomial", # logit-lasso
                   alpha = 1)),
  list(fun = mdl_glmnet,
       args = list(family = "binomial", # logit-ridge
                   alpha = 0)),
  list(fun = mdl_ranger,
       args = list(num.trees = 1000, # random forest, high regularization
                   min.node.size = 100)),
  list(fun = mdl_ranger,
       args = list(num.trees = 1000, # random forest, medium regularization
                   min.node.size = 10)),
  list(fun = mdl_ranger,
       args = list(num.trees = 1000, # random forest, low regularization
                   min.node.size = 1)))


################################################################################
###### estimations                                                        ######
################################################################################

attgt_0 <- att_gt(yname = "oop_spend",
                  gname = "first_hosp",
                  idname = "hhidpn",
                  tname = "wave",
                  control_group = "notyettreated",
                  xformla = NULL,
                  data = dat,
                  bstrap=FALSE)
dyn_0 <- aggte(attgt_0, type = "dynamic", bstrap = FALSE)

attgt_lm <- att_gt(yname = "oop_spend",
                   gname = "first_hosp",
                   idname = "hhidpn",
                   tname = "wave",
                   control_group = "notyettreated",
                   xformla = ~ ragey_b+ragey_b^2+ragey_b^3+female+black+
                     hispanic+race_other+hs_grad+some_college+collegeplus,
                   data = dat,
                   bstrap=FALSE,
                   est_method = "dr",
                   learners = list(list(fun = ols)),
                   learners_DX = list(list(fun = mdl_glm,
                                           args = list(family = binomial))),
                   type = "average",
                   trim = 0.001)
dyn_lm <- aggte(attgt_lm, type = "dynamic", bstrap = FALSE, na.rm=TRUE)
dyn_lm

attgt_dml <- att_gt(yname = "oop_spend",
                    gname = "first_hosp",
                    idname = "hhidpn",
                    tname = "wave",
                    control_group = "notyettreated",
                    xformla = ~ ragey_b+female+black+
                      hispanic+race_other+hs_grad+some_college+collegeplus,
                    data = dat,
                    bstrap=FALSE,
                    est_method = "ddml",
                    learners=learners,
                    learners_DX=learners_DX,
                    ensemble_type="nnls",
                    sample_folds=15,
                    shortstack=TRUE,
                    trim = 0.001,
                    silent=FALSE)
dyn_dml <- aggte(attgt_dml, type = "dynamic", bstrap = FALSE)


################################################################################
###### plotting.                                                          ######
################################################################################

res <- bind_rows(
  data.frame(egt=dyn_dml$egt,att=dyn_dml$att.egt,se=dyn_dml$se.egt,estimator="DiD-DML"),
  data.frame(egt=dyn_lm$egt,att=dyn_lm$att.egt,se=dyn_lm$se.egt,estimator="With controls"),
  data.frame(egt=dyn_0$egt,att=dyn_0$att.egt,se=dyn_0$se.egt,estimator="Without controls")
) 
res |>
  ggplot() +
  geom_pointrange(aes(x=egt,y=att,
                      ymin=att-1.96*se,ymax=att+1.96*se,
                      color=estimator),position=position_dodge(width=0.2)) +
  geom_hline(yintercept=0,linetype="dashed") 
ggsave("/Users/kahrens/MyProjects/DMLGuide.github.io/assets/images/HRS.png")
