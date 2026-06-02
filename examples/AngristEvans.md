---
layout: default
title: DML for the Angrist & Evans
parent: Examples
nav_order: 40
nav_exclude: true
math: true
description: "Imposing no-interaction restrictions in DML estimations."
permalink: /examples/AngristEvans
enable_copy_code_button: true
---

# Machine Labor — DML for the Angrist & Evans IV

The classical study of [Angrist & Evans (1998)](https://doi.org/10.1257/aer.88.3.450) estimates the effect of a third child on maternal labor supply using the instrument `samesex`, an indicator for the first two children sharing a sex. The rationale is that parents whose first two children share a sex are modestly more likely to have a third child, but — conditional on the sex of each of the first two children — `samesex` is plausibly unrelated to the mother’s labor-market outcomes.

[Angrist & Frandsen (2022)](https://doi.org/10.1086/717933) revisit this application in *Machine Labor* and ask whether machine learning can be used inside the first stage of two-stage least squares. They show that it can go badly: with random forests, the second-stage effect of a third child becomes imprecisely estimated, and a placebo check using a signal-free fake instrument yields spurious results.

This post shows that the failure of ML generated instruments is not fundamental. With nuisance estimators that respect the identifying restrictions of the design, DML reproduces the 2SLS point estimate on the real instrument and correctly refuses to find signal using placebo instruments.

## The identification issue

To see why a random forest can fail here, consider the partially linear IV (PLIV) model

$$Y = \theta\, D + g(X) + \varepsilon, \qquad
D = m(X) + \alpha\, Z + u, \qquad
Z = r(X) + v.$$

The outcome ($Y$ = `workedm`) is an indicator for whether the mother is working. The treatment ($D$ = `morekids`) indicates more than two children. The instrument ($Z$ = `samesex`) is defined above. The controls $X$ are:

| Variable                      | Definition                        |
|-------------------------------|-----------------------------------|
| `boy1st`, `boy2nd`            | Sex of first / second child       |
| `agem1`, `agefstm`            | Mother’s age / age at first birth |
| `blackm`, `hispm`, `othracem` | Race indicators                   |
| `educm`                       | Years of education                |

DML estimates $\theta$ from a residualized score: it instruments the residualized treatment $\tilde D = D - \hat m(X)$ with the residualized instrument $\tilde Z = Z - \hat r(X)$ in a regression on $\tilde Y = Y - \hat g(X)$. The nuisance functions $\hat g$, $\hat m$, and $\hat r$ are estimated by machine learning on held-out folds.

The problem sits in $\hat r(X)$. By construction,

$$\text{samesex} = \text{boy1st}\cdot\text{boy2nd} + (1-\text{boy1st})(1-\text{boy2nd}),$$

so any flexible machine learner that is free to combine `boy1st` and `boy2nd` will discover this interaction and predict `samesex` almost exactly from $X$. The residualized instrument then collapses to $\tilde Z \approx 0$ and the second-stage coefficient becomes uninformative.

2SLS does not fail in the same way, because it never fits the `boy1st × boy2nd` interaction unless the analyst adds it by hand. The identifying assumption — that `boy1st` and `boy2nd` enter $r(X)$ additively — is baked into the linear functional form. Flexible learners (random forests, gradient-boosted trees, deep nets) undo that protection: they exploit any interaction that helps prediction, including the one that destroys identification.

## Two ways to encode the restriction

We need a learner that fits $r(X)$ flexibly in `agem1`, `agefstm`, race, and `educm`, but is forbidden from interacting `boy1st` with `boy2nd`. Below we show two ways to enforce this: the first approach uses regularized regression and relies on block-structured polynomial; the second approach implements no-interaction constraints in tree-based boosting (using the XGBoost package).

### Setup and variables

We define three named groups of regressors:

<details markdown="block" open>

<summary>

R code — variable groups
</summary>

``` r
X_vars     <- c("boy1st", "boy2nd", "agem1", "agefstm",
                "blackm", "hispm", "othracem", "educm")
Xbase_boy1 <- c("boy1st",          "agem1", "agefstm",
                "blackm", "hispm", "othracem", "educm")  # drops boy2nd
Xbase_boy2 <- c(         "boy2nd", "agem1", "agefstm",
                "blackm", "hispm", "othracem", "educm")  # drops boy1st

D_var  <- "morekids"
Z_var  <- "instr" # either `same_sex` or a placebo instrument
kfolds <- 2L
```

</details>

`Xbase_boy1` and `Xbase_boy2` each contain only one of the two sex indicators. Building a polynomial dictionary separately on each block guarantees that no resulting feature multiplies a `boy1st` term by a `boy2nd` term.

### Polynomial dictionaries built block-by-block

For lasso and ridge we build a cubic polynomial dictionary *separately* on `Xbase_boy1` and `Xbase_boy2`, then column-bind them. Because neither dictionary contains both sex indicators, no resulting term involves their interaction.

<details markdown="block" open>

<summary>

R code — `build_poly3()` and the block-structured design matrix
</summary>

``` r
build_poly3 <- function(df, base_cols) {
  X <- as.matrix(df[, base_cols, drop = FALSE])
  P <- poly(X, degree = 3L, raw = TRUE)
  out <- model.matrix(~ P)[, -1L, drop = FALSE]
  exps <- do.call(rbind, lapply(
    strsplit(sub("^P", "", colnames(out)), ".", fixed = TRUE),
    as.integer))
  colnames(out) <- apply(exps, 1L,
    function(e) paste(rep(base_cols, e), collapse = "_x_"))
  out[, order(rowSums(exps)), drop = FALSE]
}

X_poly_b1 <- build_poly3(data, Xbase_boy1)   # cubic poly without boy2nd
X_poly_b2 <- build_poly3(data, Xbase_boy2)   # cubic poly without boy1st
```

</details>

### XGBoost interaction constraints

Tree ensembles can incorporate no-interaction contraints by declaring which features are allowed to share a single tree path. The idea is to let the tree paths split on `boy1st` *or* `boy2nd` but never on both. Standard random-forest implementations in R do not allow specifying these constraints, but XGBoost does, via `interaction_constraints`. We pass two groups: one containing `boy1st` (index 1) plus the demographics, and one containing `boy2nd` (index 2) plus the demographics. We also consider two XGBoost specifications with two learning rates (0.01 and 0.03).

<details markdown="block" open>

<summary>

R code — learner specifications\`
</summary>

``` r
# X_vars order: 1=boy1st, 2=boy2nd, 3=agem1, 4=agefstm,
#               5=blackm, 6=hispm, 7=othracem, 8=educm
xgb_args1 <- list(nrounds = 500L, learning_rate = 0.01, nthread = 1L,
                  interaction_constraints = list(c(1, 3:8), c(2:8)))
xgb_args2 <- list(nrounds = 500L, learning_rate = 0.03, nthread = 1L,
                  interaction_constraints = list(c(1, 3:8), c(2:8)))

specs_stack <- list(
  list(what = mdl_glmnet,  args = list(alpha = 1, cv = TRUE),
                           assign_X = poly_idx),
  list(what = mdl_glmnet,  args = list(alpha = 0, cv = TRUE),
                           assign_X = poly_idx),
  list(what = mdl_xgboost, args = xgb_args1, assign_X = base_idx),
  list(what = mdl_xgboost, args = xgb_args2, assign_X = base_idx)
)
```

</details>

The `assign_X` field tells `ddml` which columns of `X_full` each learner sees: XGBoost gets the eight original variables, while lasso and ridge work on the (additivity-respecting) polynomial dictionary.

## DML estimation

We call `ddml::ddml_pliv()` with the four-learner stack, short-stacking via non-negative least squares, two folds, and heteroskedasticity-robust standard errors.

Setting `custom_ensemble_weights = diag(4)` makes `ddml` return both the NNLS-stacked estimate and each learner’s standalone estimate from a single fit — that is where the per-learner rows in the tables below come from.

<details markdown="block" open>

<summary>

R code — `ddml_pliv()` call
</summary>

``` r
fit_ddml <- ddml_pliv(
  y                       = y,
  D                       = D,            # morekids
  Z                       = Z,            # instr (one of three flavors)
  X                       = X_full,
  learners                = specs_stack,
  sample_folds            = kfolds,
  ensemble_type           = "nnls",
  custom_ensemble_weights = diag(length(specs_stack)),  # one "ensemble" per learner
  shortstack              = TRUE,
  silent                  = TRUE
)
```

</details>

## Estimation

We estimate the model twice: once with the observed `samesex` instrument, and once with a placebo $Z=$ `agem1 + educm + Uniform(0,1)`, following Angrist & Frandsen. After residualizing on $X$, the placebo is just noise, so any apparent first-stage signal there is spurious by construction.

### Real IV (`samesex`) — DML reproduces 2SLS

With the observed instrument, all constrained DML variants — stacking, lasso, ridge, XGBoost — land essentially on the 2SLS point estimate. Unconstrained XGBoost (the last two rows of the table) drifts off and standard errors inflate.

| Learner | Structural / constrained | First stage / constrained | Structural / unconstrained | First stage / unconstrained |
|:---|:---|:---|:---|:---|
| 2SLS | -0.118 (0.028) | 0.069 (0.002) | — | — |
| Stacking | -0.119 (0.028) | 0.070 (0.002) | -0.467 (0.319) | 946.342 (278.321) |
| Lasso | -0.119 (0.028) | 0.069 (0.002) | -0.412 (5.453) | 0.012 (0.060) |
| Ridge | -0.120 (0.028) | 0.069 (0.002) | -0.456 (0.439) | 0.058 (0.023) |
| XGB(.01) | -0.118 (0.027) | 0.070 (0.002) | -0.448 (0.173) | 1.743 (0.279) |
| XGB(.03) | -0.115 (0.027) | 0.070 (0.002) | -0.649 (0.459) | 368.518 (147.053) |

*Notes.* Outcome: `workedm` (mother works). Instrument: observed (`samesex`). Each cell shows the coefficient with its standard error in parentheses; columns split each estimate by stage (structural vs. first-stage) and by whether the no-interaction constraint between `boy1st` and `boy2nd` is imposed. The 2SLS row does not depend on the constraint and is reported once per stage.
{: .fs-2 }

### Pure-noise IV (`fake`) — DML refuses to find signal

When $Z=$ `agem1 + educm + noise`, the true first-stage coefficient is zero. DML behaves the way it should on a noise instrument: the first-stage DML estimates (with or without constraint enforced) are clustering around zero. The standard errors of the structural estimates are inflated, with confidence intervals easily covering zero. The constrained-vs-unconstrained distinction has essentially no effect here.

| Learner | Structural / constrained | First stage / constrained | Structural / unconstrained | First stage / unconstrained |
|:---|:---|:---|:---|:---|
| 2SLS | -1.613 (1.278) | -0.004 (0.003) | — | — |
| Stacking | -1.583 (1.314) | -0.004 (0.003) | -1.526 (1.180) | -0.005 (0.003) |
| Lasso | -1.720 (1.423) | -0.004 (0.003) | -1.744 (1.444) | -0.004 (0.003) |
| Ridge | 1.722 (1.363) | 0.004 (0.002) | 2.056 (1.546) | 0.003 (0.002) |
| XGB(.01) | -1.838 (1.527) | -0.004 (0.003) | -1.929 (1.629) | -0.004 (0.003) |
| XGB(.03) | -1.661 (1.504) | -0.004 (0.003) | -1.355 (1.035) | -0.005 (0.003) |

*Notes.* Outcome: `workedm` (mother works). Instrument: placebo, $Z=$ `agem1 + educm + Uniform(0,1)`; the true first-stage coefficient is zero. Each cell shows the coefficient with its standard error in parentheses; columns split each estimate by stage (structural vs. first-stage) and by whether the no-interaction constraint between `boy1st` and `boy2nd` is imposed. The 2SLS row does not depend on the constraint and is reported once per stage.
{: .fs-2 }

## Takeaway

In the Angrist & Evans application, identification rests on a functional-form restriction that 2SLS imposes implicitly. Replacing the linear first stage with a flexible learner leaves it unenforced. This post shows two ways to re-impose it without losing flexibility: regularized regression on a custom polynomial dictionary, and XGBoost with interaction constraints. With first-stage learners that respect the restriction, DML reproduces the 2SLS estimate on the observed instrument and returns a first stage indistinguishable from zero on the placebo.

## References

- Angrist, J. D., & Evans, W. N. (1998). Children and their parents’ labor supply: Evidence from exogenous variation in family size. *American Economic Review*, 88(3), 450–477. <https://doi.org/10.1257/aer.88.3.450>
- Angrist, J. D., & Frandsen, B. (2022). Machine labor. *Journal of Labor Economics*, 40(S1), S97–S140. <https://doi.org/10.1086/717933>
- Chernozhukov, V., Chetverikov, D., Demirer, M., Duflo, E., Hansen, C., Newey, W., & Robins, J. (2018). Double/debiased machine learning for treatment and structural parameters. *Econometrics Journal*, 21(1), C1–C68. <https://doi.org/10.1111/ectj.12097>
- Ahrens, A., Hansen, C. B., Schaffer, M. E., & Wiemann, T. (2024). `ddml`: Double/debiased machine learning in R. *Journal of Statistical Software*, 108(3). <https://doi.org/10.18637/jss.v108.i03>
- Chen, T., & Guestrin, C. (2016). XGBoost: A scalable tree boosting system. *KDD ’16*, 785–794. <https://doi.org/10.1145/2939672.2939785>
