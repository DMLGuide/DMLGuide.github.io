---
layout: default
title: Dynamic Effects on Hospitalization
parent: Examples
nav_order: 4
math: true
description: ""
permalink: /examples/HRS
enable_copy_code_button: true
---

# Dynamic Effects on Hospitalization

## Setting

We follow [Dobkin et al (2018)](https://www.aeaweb.org/articles?id=10.1257/aer.20161038) in estimating the causal effect of hospital admissions on out-of-pocket medical spendings.[^bhnote] This application is instructive in that it illustrates how DML can be used for difference-in-difference analyses. The analysis of Dobkin et al. (2018) was reconsidered by [Sun & Abraham (2021)](https://doi.org/10.1016/j.jeconom.2020.09.006) to showcast their proposed DiD estimator. 

[^bhnote]: The full data is available from the [OpenICPSR repository](https://www.openicpsr.org/openicpsr/project/116186/version/V1/view?path=/openicpsr/116186/fcr:versions/V1&type=project). We consider here the subset of the data that that was also considered by Sun Abraham.

The illustration here is a simplified version of the analysis presented in Section 5 of our review paper. For the full replication code, see our replication repository (Link to be added).

The variables used are:

| Variable | Description |
| ----------- | ----------------|
| `oop_spend` | Out of pocket medical expenditures prev 12 months|
| `first_hosp` | First hospitalization |
| `hhidpn` | Household/person indicator |
| `wave` | Wave indicator |
| `ragey_b` | Age in years |
| `female` | Female indicator |         
| `black` | Black indicator |          
| `hispanic` | Hispanic indicator |         
| `race_other` | Other race |           
| `hs_grad` | High school graduate |
| `some_college` | College degree |         
| `collegeplus` | Higher than college education |       

## Data and model set-up

We begin by loading the data, and specifying settings for a number of nuisance function estimators that we will use below. 

Note that for the DiD analyses to run in R, you will need to install a modified version of the original `did` package by Callaway & Santa'Anna.

<details markdown="block">
<summary>R code</summary>

```
# Hard-coded hyperparameters
library("did")
#devtools::install_github("thomaswiemann/did",ref="dev-ddml")
library(ddml)
library(readr)

dat <- read_csv("https://dmlguide.github.io/assets/dta/HRS_long.csv")

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
```

</details>

## DiD estimation with parametric nuisance functions

Next, we employ the Callway & Sant'Anna estimator of group-time average treatment effects (GT-ATT) with and without any controls. Each GT-ATT corresponds to the ATT of a hospitalization on out-of-pocket medical spending at time $g$ observed at time $t$. These GT-ATT are then aggregated to yield dynamic effects measured up to two periods before and after treatment onset. To adjust for covariates, we use doubly robust DiD estimator and assume that the nuisance functions are parameteric (an assumption that we will relax when employing DML).

<details markdown="block">
<summary>R code</summary>

```
# Without controls
attgt_0 <- att_gt(yname = "oop_spend",
                  gname = "first_hosp",
                  idname = "hhidpn",
                  tname = "wave",
                  control_group = "notyettreated",
                  xformla = NULL,
                  data = dat,
                  bstrap=FALSE)
dyn_0 <- aggte(attgt_0, type = "dynamic", bstrap = FALSE)

# With controls
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
dyn_lm <- aggte(attgt_lm, type = "dynamic", bstrap = FALSE)
```

</details>

<details markdown="block">
<summary>Stata code</summary>

To be added. 

</details>


## Double Machine Learning DiD estimation

Finally, we 

<details markdown="block">
<summary>R code</summary>

```
// In the G-N estimations, GDP is missing for one country.
// For simplicity, we just drop this one country so that it is never used.
drop if loggdp==.

```

</details>

<details markdown="block">
<summary>Stata code</summary>

To be added. 

</details>

## Results

Finally, we prepare a plot to display the results:

<details markdown="block">
<summary>R output</summary>

```
. // Step 1: Specify the model.

```

</details>

<details markdown="block">
<summary>Stata output</summary>

To be added. 

</details>

