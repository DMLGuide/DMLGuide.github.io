---
layout: default
title: Monopsony I — DDML on MTurk, the simplest setting
parent: Examples
nav_order: 34
math: true
description: "DDML applied to Dube, Jacobs, Naidu & Suri (2020) on monopsony power in MTurk: partialling out task-level controls with XGBoost via the ddml package."
permalink: /examples/Monopsony_DML
enable_copy_code_button: true
---

# Monopsony I — DDML on MTurk, the simplest setting

*This is Part 1 of a series of three posts. The companion scripts are available at XXX.*

How much monopsony power does an online labour platform give to the firms that post jobs there? To answer this question Dube, Jacobs, Naidu and Suri (2020) estimate the elasticity of labor supply using Amazon Mechanical Turk (MTurk).

MTurk is a marketplace for short, online tasks called HITs (Human Intelligence Tasks), e.g., labelling images, transcribing audio, filling out surveys. A recruiter posts a HIT, sets a reward in dollars, and waits for workers to claim and complete it. The labour-supply object of interest is how quickly workers fill a HIT in response to the reward the recruiter posts, holding the task itself fixed. The faster they fill it at a given reward, the more elastic supply to that recruiter is. Dube et al. (2020) use the *time to fill* as the empirical proxy: short fill times mean elastic supply, long ones mean inelastic, and the elasticity is the partial regression coefficient of log fill-time on log reward.

We discuss this application in three blog entries: Part 1 illustrates a simple DDML estimation of the labor supply elasticity using only a single learner and hand-coded control variables. Part 2 incorporates unstructured text data describing the tasks using fine-tuned DeBERTa embeddings. Part 3 stress-tests the result (more folds, construction, different learners, stacking, multi-seed aggregation).

## 1. Model and identification

The estimating equation is the partially linear model that Dube et al. (2020) build on:

$$\underbrace{\log(\text{duration}_i)}_{Y_i} \;=\; \theta_0 \cdot \underbrace{\log(\text{reward}_i)}_{D_i} \;+\; g_0(X_i) \;+\; \varepsilon_i,
\qquad E[\varepsilon_i \mid X_i, D_i] = 0.$$

where:

- $Y_i$ is the log time it takes for HIT $i$ to be accepted;
- $D_i$ is the log reward posted by the recruiter;
- $X_i$ collects task-level controls.

Under the conditional mean-independence assumption above, $-\theta_0$ is interpretable as the labour supply elasticity faced by the recruiter: a 1% rise in posted reward reduces labor supply by $-\theta_0$%. A small $\lvert\theta_0\rvert$ — workers indifferent to reward conditional on the task — indicates that recruiters have monopsony power.

MTurk tasks differ in length, complexity, qualification requirements, recruiter reputation, and content (e.g., a 30-second image label versus a 20-minute transcription). Conditioning on $X$ is thus crucial being able to assign a meaningful interpretation to $-\theta_0$.

## 2. Data and controls

The sample is the cross-section of HITs compiled by [Ipeirotis (2010)](https://archive.nyu.edu/handle/2451/29801), which is one of the datasets analyzed in Dube et al. (2020). One row is one HIT group (a batch of identical tasks posted by one recruiter).

The $X$ matrix in this entry is the hand-engineered controls only — *no* text embeddings. They fall into four blocks:

- **Task design and pricing.** Allotted time per HIT, the number of HITs in the batch (first/last/max), how many have already been completed at observation, the recruiter’s rate of completed HITs, indicators for time mentioned in the title/keywords.
- **Qualifications and access.** Indicators for whether the recruiter requires a qualification (and how long that requirement is), the number of distinct qualifications required, approval-rate and approval-count thresholds, custom-qualification flag, location restrictions (e.g. US-only).
- **Recruiter aggregates.** Log average reward and log average duration across all of the recruiter’s other HITs.
- **Task content.** Binarised bag-of-words indicators for keywords/title/description tokens, plus Gadiraju task-category dummies (image labelling, transcription, survey, etc.) — these are the cheap, ad-hoc representation of the task text that Entry 2 will replace with DeBERTa embeddings.

Continuous variables are `log(1+x)` transformed and top-1% winsorised where they are right-skewed counts; mass-at-zero variables (minutes mentioned in the title, qualification length, number of qualifications, approval thresholds) are discretised into a small set of indicators.

| rows | K_folds | fold_construction | SE |
|---:|---:|:---|:---|
| 258352 | 3 | recruiter-honest (cluster_variable = requester_id) | cluster-robust by requester_id |

Sample and design.

## 3. Estimation

We start with the simplest reasonable nuisance learner: a CV-tuned linear lasso (`mdl_glmnet` with `alpha = 1`). The penalty $\lambda$ is selected by `cv.glmnet`’s default cross-validation; in `ddml`’s wrapper, predictions are made at the lambda that minimises CV error.

We use $K = 3$ cross-fitting folds, constructed at the recruiter level: all HITs from the same `requester_id` are kept in the same fold. This respects the panel structure of the data and matches the cluster-robust SE convention below. \[Monopsony III\]({{ ‘/examples/Monopsony_Robustness’ \| relative_url }}) sweeps this baseline against XGBoost and other choices.

``` r
set.seed(42)

lasso_spec <- list(
  what = mdl_glmnet,
  args = list(alpha = 1)
)

fit <- ddml_plm(
  y = y, D = D, X = X,                # X = hand-coded controls only
  learners         = lasso_spec,
  sample_folds     = 3,
  cluster_variable = dat$requester_id # recruiter-honest folds + cluster SE
)
summary(fit)
```

A note for usage of `ddml`: passing `cluster_variable` does two things at once. It tells `ddml_plm` to keep each recruiter’s HITs together when constructing folds (so that no recruiter is “leaked” across the train/predict split), and it switches the standard error to cluster-robust on the same variable.

## 4. Result

<div id="tbl-result">

Table 1: Coefficient on log(reward). Cluster-robust SE by requester_id in parentheses.
<!-- preamble start -->
&#10;    <script src="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.js"></script>
&#10;    <script>
      // Create table-specific functions using external factory
      const tableFns_58mzhth2p3o5jquj8mqn = TinyTable.createTableFunctions("tinytable_58mzhth2p3o5jquj8mqn");
      // tinytable span after
      window.addEventListener('load', function () {
          var cellsToStyle = [
            // tinytable style arrays after
          { positions: [ { i: '6', j: 2 } ], css_id: 'tinytable_css_lm0q6namq7m6tnjws3tu',}, 
          { positions: [ { i: '2', j: 2 } ], css_id: 'tinytable_css_uiogimw5lkvtv1pbgoqn',}, 
          { positions: [ { i: '1', j: 2 }, { i: '3', j: 2 }, { i: '4', j: 2 }, { i: '5', j: 2 } ], css_id: 'tinytable_css_rq79gczgkpp6h1dsnaz5',}, 
          { positions: [ { i: '0', j: 2 } ], css_id: 'tinytable_css_i9dnxvx0qm07mbuxgcet',}, 
          { positions: [ { i: '6', j: 1 } ], css_id: 'tinytable_css_wr200ycycf80dlvzp876',}, 
          { positions: [ { i: '2', j: 1 } ], css_id: 'tinytable_css_ebls6asns5rn2bzzexpt',}, 
          { positions: [ { i: '1', j: 1 }, { i: '3', j: 1 }, { i: '4', j: 1 }, { i: '5', j: 1 } ], css_id: 'tinytable_css_a4c0frxqvogvupghad1a',}, 
          { positions: [ { i: '0', j: 1 } ], css_id: 'tinytable_css_hd81z62fqpszijp8m0lk',}, 
          ];
&#10;          // Loop over the arrays to style the cells
          cellsToStyle.forEach(function (group) {
              group.positions.forEach(function (cell) {
                  tableFns_58mzhth2p3o5jquj8mqn.styleCell(cell.i, cell.j, group.css_id);
              });
          });
      });
    </script>
&#10;    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.css">
    <style>
    /* tinytable css entries after */
    #tinytable_58mzhth2p3o5jquj8mqn td.tinytable_css_lm0q6namq7m6tnjws3tu, #tinytable_58mzhth2p3o5jquj8mqn th.tinytable_css_lm0q6namq7m6tnjws3tu {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_58mzhth2p3o5jquj8mqn td.tinytable_css_uiogimw5lkvtv1pbgoqn, #tinytable_58mzhth2p3o5jquj8mqn th.tinytable_css_uiogimw5lkvtv1pbgoqn {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_58mzhth2p3o5jquj8mqn td.tinytable_css_rq79gczgkpp6h1dsnaz5, #tinytable_58mzhth2p3o5jquj8mqn th.tinytable_css_rq79gczgkpp6h1dsnaz5 { text-align: center }
    #tinytable_58mzhth2p3o5jquj8mqn td.tinytable_css_i9dnxvx0qm07mbuxgcet, #tinytable_58mzhth2p3o5jquj8mqn th.tinytable_css_i9dnxvx0qm07mbuxgcet {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_58mzhth2p3o5jquj8mqn td.tinytable_css_wr200ycycf80dlvzp876, #tinytable_58mzhth2p3o5jquj8mqn th.tinytable_css_wr200ycycf80dlvzp876 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_58mzhth2p3o5jquj8mqn td.tinytable_css_ebls6asns5rn2bzzexpt, #tinytable_58mzhth2p3o5jquj8mqn th.tinytable_css_ebls6asns5rn2bzzexpt {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_58mzhth2p3o5jquj8mqn td.tinytable_css_a4c0frxqvogvupghad1a, #tinytable_58mzhth2p3o5jquj8mqn th.tinytable_css_a4c0frxqvogvupghad1a { text-align: left }
    #tinytable_58mzhth2p3o5jquj8mqn td.tinytable_css_hd81z62fqpszijp8m0lk, #tinytable_58mzhth2p3o5jquj8mqn th.tinytable_css_hd81z62fqpszijp8m0lk {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    </style>
    <div class="container">
      <table class="tinytable" id="tinytable_58mzhth2p3o5jquj8mqn" style="width: auto; margin-left: auto; margin-right: auto;" data-quarto-disable-processing='true'>
        &#10;        <thead>
              <tr>
                <th scope="col" data-row="0" data-col="1"> </th>
                <th scope="col" data-row="0" data-col="2">DDML</th>
              </tr>
        </thead>
        &#10;        <tbody>
                <tr>
                  <td data-row="1" data-col="1">log(reward)</td>
                  <td data-row="1" data-col="2">0.024</td>
                </tr>
                <tr>
                  <td data-row="2" data-col="1"></td>
                  <td data-row="2" data-col="2">(0.523)</td>
                </tr>
                <tr>
                  <td data-row="3" data-col="1">n</td>
                  <td data-row="3" data-col="2">258352</td>
                </tr>
                <tr>
                  <td data-row="4" data-col="1">K</td>
                  <td data-row="4" data-col="2">3</td>
                </tr>
                <tr>
                  <td data-row="5" data-col="1">R²(Y|X)</td>
                  <td data-row="5" data-col="2">0.687</td>
                </tr>
                <tr>
                  <td data-row="6" data-col="1">R²(D|X)</td>
                  <td data-row="6" data-col="2">0.743</td>
                </tr>
        </tbody>
      </table>
    </div>
<!-- hack to avoid NA insertion in last line -->

</div>

The cross-fitted $R^2$ values are diagnostic: they tell us how predictable the outcome and the treatment are from the hand-coded controls. With CV-lasso on the hand-coded block alone, $R^2(Y \mid X)$ sits in the high-60s and $R^2(D \mid X)$ in the low-70s — both noticeably below what a non-linear learner would deliver here. The standard error on $\hat\theta_0$ is correspondingly large, and the point estimate is statistically indistinguishable from zero. This is the canonical “learner that doesn’t fit cannot debias” pattern that \[Monopsony III\]({{ ‘/examples/Monopsony_Robustness’ \| relative_url }}) returns to.

Entry 2 takes the natural next step: it adds fine-tuned DeBERTa embeddings of each HIT’s text to $X$, holding everything else fixed.

## 5. Next step

The headline coefficient is identified by the residual variation in posted reward after partialling out hand-coded task characteristics — but those characteristics ignore the *text* of each HIT, which is where most of the substantive content lives. \[Monopsony II\]({{ ‘/examples/Monopsony_Finetune’ \| relative_url }}) adds fine-tuned DeBERTa embeddings to $X$ and re-runs the same cross-fit; \[Monopsony III\]({{ ‘/examples/Monopsony_Robustness’ \| relative_url }}) stress-tests the result against alternative fold constructions, learner choices, and seed aggregation.

## 6. References

- Ahrens, A., V. Chernozhukov, C. Hansen, D. Kozbur, M. Schaffer and T. Wiemann. *An Introduction to Double/Debiased Machine Learning.* (Working paper, this site.)
- Ahrens, A., C. B. Hansen, M. E. Schaffer, and T. Wiemann (2024). [`ddml`: Double/Debiased machine learning in R.](https://doi.org/10.18637/jss.v108.i03)
- Chernozhukov, V., D. Chetverikov, M. Demirer, E. Duflo, C. Hansen, W. Newey, and J. Robins (2018). [Double/Debiased machine learning for treatment and structural parameters.](https://doi.org/10.1111/ectj.12097)
- Dube, A., J. Jacobs, S. Naidu and S. Suri (2020). [Monopsony in online labor markets.](https://doi.org/10.3386/w26108) *AER: Insights* 2 (1).
- Ipeirotis, P. G. (2010). [Analyzing the Amazon Mechanical Turk marketplace.](https://archive.nyu.edu/handle/2451/29801)

Continue: \[**Monopsony II — fine-tuned text embeddings**\]({{ ‘/examples/Monopsony_Finetune’ \| relative_url }}) · \[**Monopsony III — robustness**\]({{ ‘/examples/Monopsony_Robustness’ \| relative_url }}).
