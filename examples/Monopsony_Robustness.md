---
layout: default
title: Monopsony III — Further analysis
parent: Examples
nav_order: 36
nav_exclude: true
math: true
description: "Varying the nuisance learner, the number of cross-fitting seeds, K, and cluster-vs-IID fold construction."
permalink: /examples/Monopsony_Robustness
enable_copy_code_button: true
---

# Monopsony III — how robust is the headline elasticity?

*Part 3 of a three-post series. <a href="{{ '/examples/Monopsony_DML' | relative_url }}">Part 1</a> ran DML on the Dube et al. (2020) MTurk data with hand-coded controls only. <a href="{{ '/examples/Monopsony_Finetune' | relative_url }}">Part 2</a> added fine-tuned DeBERTa embeddings. This final post refines and validates the DML specification.*

In Part 2, we considered a particular DML specification with $K=3$ cross-fitting folds, randomly split by recruiter, and XGBoost (using 800 trees, a minimum node size of 500, early stopping) as the nuisance learner. This final part illustrates how to refine the DML specification and highlights sensible validation checks.

## Multi-seed median aggregation (XGBoost)

A single randomization seed generates one random partition of the sample into folds. Asymptotically the exact partition does not matter; in finite samples, however, it can make a noticeable difference.

The table below repeats the random fold splitting and DML estimation five times, using five different seeds. The per-seed estimates span a non-trivial range, so sample-split randomness has a noticeable impact in finite samples.

<div id="tbl-multiseed-xgb">

Table 1: Per-seed estimates and median-aggregated estimates for the baseline specification.

|                           | seed=12487     | seed=17929     | seed=28327     | seed=63595     | seed=85886     | median agg. (S=5) |
|---------------------------|----------------|----------------|----------------|----------------|----------------|-------------------|
| theta (resid_Y ~ resid_D) | -0.033 (0.013) | -0.037 (0.017) | -0.073 (0.022) | -0.065 (0.030) | -0.061 (0.014) | -0.061 (0.029)    |
| N                         | 258352         | 258352         | 258352         | 258352         | 258352         | 258352            |
| S (replications)          |                |                |                |                |                | 5                 |
| R^2 outcome eq.           | 0.867          | 0.862          | 0.864          | 0.856          | 0.861          | 0.862             |
| R^2 treatment eq.         | 0.750          | 0.720          | 0.746          | 0.744          | 0.756          | 0.743             |
| K                         | 3              | 3              | 3              | 3              | 3              |                   |
| Learner                   | 9              | 9              | 9              | 9              | 9              |                   |
| Fold seed                 | 12487          | 17929          | 28327          | 63595          | 85886          |                   |

</div>

To avoid unnecessary reliance on a single draw, **we recommend repeating the cross-fitting multiple times and reporting the median- (or mean-) aggregated estimate**. The median-aggregate estimate can be calculated as:

$$\hat\theta_0^{\text{median}} = \mathrm{median}\bigl\{\hat\theta_{0,s}\bigr\}_{s=1}^{S},\qquad
\widehat{\mathrm{s.e.}}^{\text{median}} \;=\; \sqrt{\mathrm{median}\bigl\{\widehat{\mathrm{s.e.}}_s^{\,2} + (\hat\theta_{0,s} - \hat\theta_0^{\text{median}})^2\bigr\}_{s=1}^{S}}.$$

The rationale for reporting an aggregated estimate (shown above in the last column) is that it provides an intuitive summary of DML estimates that is less susceptible to particular random draws.

### Fold-clustering by recruiter or by observation

In the Ipeirotis data, some recruiters have many postings. The same recruiter’s postings may share unobserved features that correlate with both posted reward and duration until acceptance.

The table below investigates the impact of random fold construction by recruiter versus by observation on the DML estimate and its standard error:

<div id="tbl-S2-folds">

Table 2: Recruiter-honest folds with cluster-robust SE vs. IID-assumed folds. Both columns are median-of-medians over S = 5 seeds; K = 3; XGB 3 nuisance learner.

|                           | xclust (baseline) | IID-assumed folds |
|---------------------------|-------------------|-------------------|
| theta (resid_Y ~ resid_D) | -0.061 (0.029)    | -0.042 (0.006)    |
| N                         | 258352            | 258352            |
| S (replications)          | 5                 | 5                 |
| R^2 outcome eq.           | 0.862             | 0.892             |
| R^2 treatment eq.         | 0.743             | 0.877             |

</div>

We find that the cross-fitted $R^2$ values drop noticeably when moving from IID to recruiter folds. The likely reason is that splitting at the observation level lets postings from the same recruiter appear in different folds, making out-of-sample predictions look more precise than they are. This in turn might bias the DML estimates. To avoid this, **we recommend forming folds that acknowledge the dependence structure of the data**.

The R package `ddml` allows for automatic fold splitting by cluster using the `cluster_variable` option. The option also ensures standard errors are clustered at the same level:

``` r
fit <- ddml_plm(
  y = y, D = D, X = X,
  learners      = list(xgb_spec),
  sample_folds  = 3,
  ensemble_type = "singlebest",
  shortstack    = FALSE,
  cluster_variable = rid,   # omit for IID folds + het-robust SE
  silent        = TRUE
)
```

### Number of folds $K$

Cross-fitting theory accommodates any fixed number of cross-fitting folds $K$, but in practice results may vary depending on the choice of $K$, especially when the sample size is small. In the paper, **we recommend a large $K$ consistent with available computing resources, plus a sensitivity check**.

The table below compares the baseline $K = 3$ specification against $K = 5$, both median-aggregated over $S = 5$ seeds using the same recruiter-honest fold structure:

<div id="tbl-S3-K">

Table 3: K = 3 vs. K = 5. Both columns are median-of-medians over S = 5 seeds; XGB 3 nuisance learner; recruiter-honest folds; cluster-robust SE.

|                           | K = 3 (baseline) | K = 5          |
|---------------------------|------------------|----------------|
| theta (resid_Y ~ resid_D) | -0.061 (0.029)   | -0.050 (0.029) |
| N                         | 258352           | 258352         |
| S (replications)          | 5                | 5              |
| R^2 outcome eq.           | 0.862            | 0.863          |
| R^2 treatment eq.         | 0.743            | 0.739          |

</div>

We find the results to be fairly robust to the choice of $K$, with the $K=5$ specification yielding a slightly smaller point estimate in magnitude.

## The choice of learner: XGBoost vs CV-Lasso

So far, we have exclusively relied on a particular XGBoost learner for illustration.

The choice of nuisance function estimator is consequential for DML estimation. Poorly chosen or poorly tuned learners can yield misleading DML point estimates because the residual-on-residual regression then absorbs leftover signal that should have been partialed out. As an example, below we compare the baseline `XGB 3` specification against `CV-Lasso` (learner index 2), both median-aggregated over $S = 5$ seeds using the same recruiter-honest fold structure:

<div id="tbl-xgb-vs-lasso">

Table 4: XGB 3 vs. CV-Lasso, both median-aggregated over S = 5 seeds. K = 3 recruiter-honest folds; cluster-robust SE.

|                           | XGB 3 (median agg.) | CV-Lasso (median agg.) |
|---------------------------|---------------------|------------------------|
| theta (resid_Y ~ resid_D) | -0.061 (0.029)      | -0.008 (0.066)         |
| N                         | 258352              | 258352                 |
| S (replications)          | 5                   | 5                      |
| R^2 outcome eq.           | 0.862               | 0.680                  |
| R^2 treatment eq.         | 0.743               | 0.724                  |

</div>

CV-Lasso underperforms badly on both $R^2(Y\mid X)$ and $R^2(D\mid X)$, and the resulting estimate is indistinguishable from zero. A priori one would not know whether the relevant DGP favors boosted trees or a sparse linear model, so committing to a single learner without validation is fragile.

## How to select and validate the nuisance learner?

In Section 6 of the paper, we discuss **three recommended options for constructing and validating nuisance function estimators**:

1.  Consider performance metrics based on cross-fitted predicted values (e.g., cross-fitted $R^2$), which allow selecting the best-performing learner for each nuisance function separately.
2.  Use formal inference-based learner selection, e.g., the Cross-Validation with Confidence test of [Lei (2020)](https://doi.org/10.1080/01621459.2019.1672556).
3.  Use model averaging (stacking) to optimally combine candidate learners using non-negative least squares. See [Ahrens et al. (2025)](https://doi.org/10.1002/jae.3103) for a discussion of stacking in the DML context.

We focus here on the third approach. For both the outcome and the treatment equation, we form a combination of learners by regressing $Y$ and $D$ on the cross-fitted predicted values of every candidate learner, subject to non-negative weights that sum to one. We refer to this approach as “short-stacking” to distinguish it from an alternative, computationally more demanding approach that re-estimates the stacking weights for each fold.

Table 6 from the paper reports the stacked DML result: $\hat\theta_0 \approx -0.054$ with $\mathrm{s.e.} = 0.020$. The stacking weights (shown in Table 5 of the paper) load almost entirely on the three XGBoost specifications.

## What to take away

Before reporting DML results, it is essential to validate the nuisance function estimators and to question their performance. Other important implementation choices include the number of cross-fitting folds, the fold splitting scheme, and the aggregation method.

## References

- Ahrens, A., V. Chernozhukov, C. Hansen, D. Kozbur, M. Schaffer and T. Wiemann. *An Introduction to Double/Debiased Machine Learning.* §5 (median aggregation), §6 (Dube application, Tables 5–6), §7 (implementation guidance).
- Ahrens, A., C. B. Hansen, M. E. Schaffer and T. Wiemann (2024). [`ddml`: Double/debiased machine learning in R.](https://doi.org/10.18637/jss.v108.i03)
- Ahrens, A., C. B. Hansen, M. E. Schaffer and T. Wiemann (2025). [Model averaging and double machine learning.](https://doi.org/10.1002/jae.3103) *Journal of Applied Econometrics* 40 (3).
- Chernozhukov, V., D. Chetverikov, M. Demirer, E. Duflo, C. Hansen, W. Newey and J. Robins (2018). [Double/Debiased machine learning for treatment and structural parameters.](https://doi.org/10.1111/ectj.12097)
- Dube, A., J. Jacobs, S. Naidu and S. Suri (2020). [Monopsony in online labor markets.](https://doi.org/10.3386/w26108) *AER: Insights* 2 (1).
- Lei, J. (2020). [Cross-validation with confidence.](https://doi.org/10.1080/01621459.2019.1672556) *Journal of the American Statistical Association* 115 (532).
