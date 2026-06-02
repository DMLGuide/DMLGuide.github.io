---
layout: default
title: Monopsony I — Simple DML
parent: Examples
nav_order: 34
nav_exclude: true
math: true
description: "DML applied to examine monopsony power on MTurk."
permalink: /examples/Monopsony_DML
enable_copy_code_button: true
---

# Monopsony I — Using DML to examine monopsony power.

*This is Part 1 of a series of three posts, which revisits the Monopsony application in Section 6 of the JEL paper.*

How much monopsony power does an online platform give to firms? To answer this question [Dube, Jacobs, Naidu and Suri (2020)](https://www.aeaweb.org/articles?id=10.1257/aeri.20180150) estimate the elasticity of labor supply using Amazon Mechanical Turk (MTurk).

MTurk is a marketplace for short, online tasks called HITs (Human Intelligence Tasks), e.g., labeling images, transcribing audio, filling out surveys. A recruiter posts a HIT, including a description of the task, sets a reward in dollars, and waits for workers to claim and complete it.

We discuss this application in three blog entries that complement Section 6 in the paper: Part 1 (this part) illustrates a simple DML estimation of the labor supply elasticity using only a single learner and hand-coded control variables. Part 2 incorporates unstructured text data describing the tasks using fine-tuned DeBERTa embeddings. Part 3 discusses validation exercises.

## 1. Model and identification

The estimating equation is the partially linear model considered by [Dube et al. (2020)](https://www.aeaweb.org/articles?id=10.1257/aeri.20180150):

$$\underbrace{\log(\text{duration}_i)}_{Y_i} \;=\; \theta_0 \cdot \underbrace{\log(\text{reward}_i)}_{D_i} \;+\; g_0(X_i) \;+\; \varepsilon_i,
\qquad E[\varepsilon_i \mid X_i, D_i] = 0.$$

where:

- $Y_i$ is the log duration it takes for HIT $i$ to be accepted;
- $D_i$ is the log reward posted by the recruiter;
- $X_i$ collects task-level controls.

The negative of $\theta_0$ is a proxy for the labor supply elasticity faced by the recruiter: If HIT are accepted more quickly when the reward rises ($\theta_0\ll 0$), labor supply is elastic. A value of $\theta_0$ close to zero — that is, when workers are unresponsive to the reward conditional on the task — indicates that recruiters have monopsony power.

MTurk tasks differ in length, complexity, qualification requirements, recruiter reputation, and content (e.g., a 30-second image label versus a 20-minute transcription). Flexibly conditioning on $X$ is thus crucial to giving $\theta_0$ a meaningful interpretation. Since tasks differ in many characteristics, this is far from trivial.

## 2. Data and controls

The sample is the cross-section of HITs compiled by [Ipeirotis (2010)](https://archive.nyu.edu/handle/2451/29801), which is one of the datasets examined in [Dube et al. (2020)](https://www.aeaweb.org/articles?id=10.1257/aeri.20180150). One row is one HIT group (a batch of identical tasks posted by one recruiter).

In this post, we only consider hand-engineered controls. Fortunately, we can rely on work by [Dube et al. (2020)](https://www.aeaweb.org/articles?id=10.1257/aeri.20180150) and previous authors who have coded information on the type of tasks using the task title and descriptions. Part 2 incorporates unstructured text using fine-tuned embeddings.

The hand-coded controls fall into four blocks:

- *Task design and pricing.* Allotted time per HIT, the number of HITs in the batch (first/last/max), how many have already been completed at observation, the recruiter’s rate of completed HITs, indicators for time mentioned in the title/keywords.
- *Qualifications and access.* Indicators for whether the recruiter requires a qualification (and how long that requirement is), the number of distinct qualifications required, approval-rate and approval-count thresholds, and a custom-qualification flag.
- *Recruiter aggregates.* Log average reward and log average duration across all of the recruiter’s other HITs.
- *Task content.* Binary bag-of-words indicators for keywords/title/description tokens, plus task-category dummies (image labeling, transcription, survey, etc.) — these are the ad-hoc representation of the task text that Part 2 will replace with DeBERTa embeddings.

We perform minimal data processing: continuous variables are `log(1+x)` transformed and top-1% winsorized if they are right-skewed; other variables with concentrated distributions are dichotomized or discretized into a small set of indicators.

## 3. Estimation

We start with a simple nuisance learner: linear lasso, implemented using the `ddml` package with `mdl_glmnet` and a cross-validated penalty parameter.

We use $K = 3$ cross-fitting folds, constructed at the recruiter level — i.e., all HITs from the same `requester_id` are kept in the same fold. This way we respect the dependence structure of the data and are consistent with the use of cluster-robust standard errors. The figure below sketches the DML procedure.

<figure style="text-align: center; margin: 1.2em 0;">
  <img src="{{ '/assets/images/monopsony/crossfit_basic.png' | relative_url }}"
       alt="Standard DML cross-fit with hand-coded controls only."
       style="max-width: 92%; height: auto;">
  <figcaption style="margin-top: 0.6em; color: #555; font-size: 0.85em; line-height: 1.45; text-align: left; max-width: 92%; margin-left: auto; margin-right: auto;">
    <strong>Notes.</strong>
    The procedure is repeated for both nuisance equations,
    <em>y</em> = log(reward) and <em>y</em> = log(duration).
    <em>K</em> is the number of cross-fitting folds (<em>K</em> = 3 in this post).
    For each fold <em>k</em>, the training sample is the <em>K&minus;1</em> remaining folds.
    The downstream ML learner (here, CV-tuned lasso) is fit on the training sample only,
    and its predictions <em>&#375;<sub>i</sub></em> on fold <em>k</em> are the cross-fitted
    nuisance values that enter the partially linear residual regression.
  </figcaption>
</figure>

We can use the `ddml` package so that we don’t have to implement the DML algorithm manually. We use the `ddml_plm` command (where `plm` is short-hand for partially linear model).

``` r
set.seed(42)

lasso_spec <- list(
  what = mdl_glmnet,
  args = list(alpha = 1)
)

fit <- ddml_plm(
  y = y, D = D, X = X, # X = hand-coded controls only
  learners         = lasso_spec,
  sample_folds     = 3,
  cluster_variable = dat$requester_id  
)
summary(fit)
```

A note on usage of `ddml`: passing the `cluster_variable` option does two things at once. It tells `ddml_plm` to keep each recruiter’s HITs together when constructing folds (so that no recruiter is “leaked” across the train/predict split), and it switches the standard error to cluster-robust on the same variable.

## 4. Result

<div id="tbl-result">

Table 1: Coefficient on log(reward). Cluster-robust SE by requester_id in parentheses.
<!-- preamble start -->
&#10;    <script src="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.js"></script>
&#10;    <script>
      // Create table-specific functions using external factory
      const tableFns_pyqd5k50s3r646ie140e = TinyTable.createTableFunctions("tinytable_pyqd5k50s3r646ie140e");
      // tinytable span after
      window.addEventListener('load', function () {
          var cellsToStyle = [
            // tinytable style arrays after
          { positions: [ { i: '6', j: 2 } ], css_id: 'tinytable_css_mb4vwgqf1oerzf3a7mn4',}, 
          { positions: [ { i: '2', j: 2 } ], css_id: 'tinytable_css_rz8odn0bo8uwd08tq0az',}, 
          { positions: [ { i: '1', j: 2 }, { i: '3', j: 2 }, { i: '4', j: 2 }, { i: '5', j: 2 } ], css_id: 'tinytable_css_ts48z9b40cvvx6dqkl36',}, 
          { positions: [ { i: '0', j: 2 } ], css_id: 'tinytable_css_207ymljg133pmzj7edku',}, 
          { positions: [ { i: '6', j: 1 } ], css_id: 'tinytable_css_qt6vpqa5an519ll2jncd',}, 
          { positions: [ { i: '2', j: 1 } ], css_id: 'tinytable_css_qxmhvsp33r7uaae0rx6p',}, 
          { positions: [ { i: '1', j: 1 }, { i: '3', j: 1 }, { i: '4', j: 1 }, { i: '5', j: 1 } ], css_id: 'tinytable_css_zbv7j1y81k3u7652oi4p',}, 
          { positions: [ { i: '0', j: 1 } ], css_id: 'tinytable_css_x28kfpobhocfwtsc15ax',}, 
          ];
&#10;          // Loop over the arrays to style the cells
          cellsToStyle.forEach(function (group) {
              group.positions.forEach(function (cell) {
                  tableFns_pyqd5k50s3r646ie140e.styleCell(cell.i, cell.j, group.css_id);
              });
          });
      });
    </script>
&#10;    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.css">
    <style>
    /* tinytable css entries after */
    #tinytable_pyqd5k50s3r646ie140e td.tinytable_css_mb4vwgqf1oerzf3a7mn4, #tinytable_pyqd5k50s3r646ie140e th.tinytable_css_mb4vwgqf1oerzf3a7mn4 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_pyqd5k50s3r646ie140e td.tinytable_css_rz8odn0bo8uwd08tq0az, #tinytable_pyqd5k50s3r646ie140e th.tinytable_css_rz8odn0bo8uwd08tq0az {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_pyqd5k50s3r646ie140e td.tinytable_css_ts48z9b40cvvx6dqkl36, #tinytable_pyqd5k50s3r646ie140e th.tinytable_css_ts48z9b40cvvx6dqkl36 { text-align: center }
    #tinytable_pyqd5k50s3r646ie140e td.tinytable_css_207ymljg133pmzj7edku, #tinytable_pyqd5k50s3r646ie140e th.tinytable_css_207ymljg133pmzj7edku {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_pyqd5k50s3r646ie140e td.tinytable_css_qt6vpqa5an519ll2jncd, #tinytable_pyqd5k50s3r646ie140e th.tinytable_css_qt6vpqa5an519ll2jncd {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_pyqd5k50s3r646ie140e td.tinytable_css_qxmhvsp33r7uaae0rx6p, #tinytable_pyqd5k50s3r646ie140e th.tinytable_css_qxmhvsp33r7uaae0rx6p {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_pyqd5k50s3r646ie140e td.tinytable_css_zbv7j1y81k3u7652oi4p, #tinytable_pyqd5k50s3r646ie140e th.tinytable_css_zbv7j1y81k3u7652oi4p { text-align: left }
    #tinytable_pyqd5k50s3r646ie140e td.tinytable_css_x28kfpobhocfwtsc15ax, #tinytable_pyqd5k50s3r646ie140e th.tinytable_css_x28kfpobhocfwtsc15ax {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    </style>
    <div class="container">
      <table class="tinytable" id="tinytable_pyqd5k50s3r646ie140e" style="width: auto; margin-left: auto; margin-right: auto;" data-quarto-disable-processing='true'>
        &#10;        <thead>
              <tr>
                <th scope="col" data-row="0" data-col="1"> </th>
                <th scope="col" data-row="0" data-col="2">DML</th>
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

Our first DML estimate is $0.024$ (with a standard error of $0.523$), indicating that $\theta_0$ is very imprecisely estimated. The cross-fitted $R^2$ values tell us how predictable the outcome and the treatment are using the hand-coded controls. With CV-lasso on the hand-coded block alone, $R^2(Y \mid X)$ sits in the high-60s and $R^2(D \mid X)$ at around 74%.

## 5. Next steps

We shouldn’t take this estimate very seriously: First, we haven’t validated the use of lasso against other nuisance function estimators. Second, the hand-coded variables might still miss out on important patterns in the data that are not captured through ad-hoc manual coding.

For these reasons, in the <a href="{{ '/examples/Monopsony_Finetune' | relative_url }}">next post</a> we will leverage fine-tuned DeBERTa embeddings to better approximate task types. The third post will refine the DML model and perform validation checks.

## 6. References

- Ahrens, A., V. Chernozhukov, C. Hansen, D. Kozbur, M. Schaffer and T. Wiemann. *An Introduction to Double/Debiased Machine Learning.* (Working paper, this site.)
- Ahrens, A., C. B. Hansen, M. E. Schaffer, and T. Wiemann (2024). [`ddml`: Double/Debiased machine learning in R.](https://doi.org/10.18637/jss.v108.i03)
- Chernozhukov, V., D. Chetverikov, M. Demirer, E. Duflo, C. Hansen, W. Newey, and J. Robins (2018). [Double/Debiased machine learning for treatment and structural parameters.](https://doi.org/10.1111/ectj.12097)
- Dube, A., J. Jacobs, S. Naidu and S. Suri (2020). [Monopsony in online labor markets.](https://doi.org/10.3386/w26108) *AER: Insights* 2 (1).
- Ipeirotis, P. G. (2010). [Analyzing the Amazon Mechanical Turk marketplace.](https://archive.nyu.edu/handle/2451/29801)

Continue: <a href="{{ '/examples/Monopsony_Finetune' | relative_url }}"><strong>Monopsony II</strong></a> · <a href="{{ '/examples/Monopsony_Robustness' | relative_url }}"><strong>Monopsony III</strong></a>.
