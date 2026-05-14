---
layout: default
title: Monopsony III — Further analysis
parent: Examples
nav_order: 36
math: true
description: "Varying the nuisance learner, with the number of cross-fitting seeds, with K, and with cluster-vs-IID fold construction."
permalink: /examples/Monopsony_Robustness
enable_copy_code_button: true
---

# Monopsony III — how robust is the headline elasticity?

*Part 3 of a three-post series. \[Part 1\]({{ ‘/examples/Monopsony_DML’ \| relative_url }}) ran DDML on the Dube et al. (2020) MTurk data with hand-coded controls only. \[Part 2\]({{ ‘/examples/Monopsony_Finetune’ \| relative_url }}) added fine-tuned DeBERTa embeddings. Both used $K = 3$ recruiter-honest folds, a single XGBoost nuisance learner, one seed, and cluster-robust standard errors at the recruiter level. This post asks: how much of that headline number is a function of those choices?*

The DDML review paper makes a sharp point about the Dube application specifically: across twelve plausible nuisance learners, the point estimate of $\theta_0$ ranges from $-3.9$ to $2.1$ (Table 5). Most of those are obviously bad — outcome $R^2$ values below 5%, neural nets that fail to converge — but the three XGBoost specifications, which dominate predictively, still spread from $-0.061$ to $-0.040$, and the three random-forest tunings produce a fourth cluster around $-0.19$. So “DDML with a single learner” is not a complete specification; the learner, how learners are combined, how the splits are formed, and how many times we resplit are all knobs.

We stress-test the Entry-2 headline along the axes Section 6 and the Implementation Guidance of Section 7 of the review paper highlight:

| Sweep | What varies | What’s held fixed |
|----|----|----|
| \(A\) Single learner | XGBoost vs Lasso | $K = 3$; cluster folds; one seed |
| \(B\) Stacking | short-stacked ensemble of the candidate learners vs. single-best | $K = 3$; cluster folds; one seed |
| \(C\) Multi-seed | $S = 5$ cross-fitting repetitions, median-of-medians aggregation | xgb; $K = 3$; cluster folds |
| \(D\) Number of folds | $K \in \{3, 5\}$ | xgb; cluster folds; one seed |
| \(E\) Cluster vs IID folds | recruiter-level vs random IID | xgb; $K = 3$; one seed |

The default convention from Entries 1–2 — recruiter-honest folds with cluster-robust SEs — is the baseline for every sweep except (E), which is the one place where comparing IID against recruiter-clustered folds is the point. `blog3_robust.R` runs (A) for XGBoost vs Lasso (the two learners in scope here), (C) with $S=5$ seeds, and the full (D) and (E) sweeps. Sweep (B) — short-stacking — is not run in this blog; the full pipeline lives in `Code/dube_monopsony/`.

## 1. Sensitivity to the nuisance learner

This is the sweep the paper makes the most noise about, and rightly so. The estimating equation, the cross-fitting, $K$, and $X$ are all held fixed; only the learner used to estimate $E[Y \mid X]$ and $E[D \mid X]$ moves.

``` r
fit <- ddml_plm(
  y = y, D = D, X = X,
  learners      = list(learner_spec),  # xgb_spec or lasso_spec
  sample_folds  = 3,
  ensemble_type = "singlebest",
  shortstack    = FALSE,
  cluster_variable = dat$requester_id,
  silent        = TRUE
)
```

<div id="tbl-learner">

Table 1: Coefficient on log(reward) by single nuisance learner. K = 3 cluster-honest folds; cluster-robust SE.
<!-- preamble start -->
&#10;    <script src="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.js"></script>
&#10;    <script>
      // Create table-specific functions using external factory
      const tableFns_wxtu900w9ek62pt3zlql = TinyTable.createTableFunctions("tinytable_wxtu900w9ek62pt3zlql");
      // tinytable span after
      window.addEventListener('load', function () {
          var cellsToStyle = [
            // tinytable style arrays after
          { positions: [ { i: '6', j: 2 }, { i: '6', j: 3 } ], css_id: 'tinytable_css_a4qrqa853cf6upi278pi',}, 
          { positions: [ { i: '2', j: 2 }, { i: '2', j: 3 } ], css_id: 'tinytable_css_30dlfhhhz8snpst42v70',}, 
          { positions: [ { i: '1', j: 2 }, { i: '3', j: 2 }, { i: '4', j: 2 }, { i: '5', j: 2 }, { i: '1', j: 3 }, { i: '3', j: 3 }, { i: '4', j: 3 }, { i: '5', j: 3 } ], css_id: 'tinytable_css_5kl9u47bnfkovk6b900h',}, 
          { positions: [ { i: '0', j: 2 }, { i: '0', j: 3 } ], css_id: 'tinytable_css_ecvodzod27k72y4adfxz',}, 
          { positions: [ { i: '6', j: 1 } ], css_id: 'tinytable_css_2te7t89t3jcng1pmy5g6',}, 
          { positions: [ { i: '2', j: 1 } ], css_id: 'tinytable_css_jgz8uprd1nbvnbol3z2t',}, 
          { positions: [ { i: '1', j: 1 }, { i: '3', j: 1 }, { i: '4', j: 1 }, { i: '5', j: 1 } ], css_id: 'tinytable_css_0eezrzkulsy16hjhyb77',}, 
          { positions: [ { i: '0', j: 1 } ], css_id: 'tinytable_css_9uuxag8jeee27lgnoknb',}, 
          ];
&#10;          // Loop over the arrays to style the cells
          cellsToStyle.forEach(function (group) {
              group.positions.forEach(function (cell) {
                  tableFns_wxtu900w9ek62pt3zlql.styleCell(cell.i, cell.j, group.css_id);
              });
          });
      });
    </script>
&#10;    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.css">
    <style>
    /* tinytable css entries after */
    #tinytable_wxtu900w9ek62pt3zlql td.tinytable_css_a4qrqa853cf6upi278pi, #tinytable_wxtu900w9ek62pt3zlql th.tinytable_css_a4qrqa853cf6upi278pi {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_wxtu900w9ek62pt3zlql td.tinytable_css_30dlfhhhz8snpst42v70, #tinytable_wxtu900w9ek62pt3zlql th.tinytable_css_30dlfhhhz8snpst42v70 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_wxtu900w9ek62pt3zlql td.tinytable_css_5kl9u47bnfkovk6b900h, #tinytable_wxtu900w9ek62pt3zlql th.tinytable_css_5kl9u47bnfkovk6b900h { text-align: center }
    #tinytable_wxtu900w9ek62pt3zlql td.tinytable_css_ecvodzod27k72y4adfxz, #tinytable_wxtu900w9ek62pt3zlql th.tinytable_css_ecvodzod27k72y4adfxz {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_wxtu900w9ek62pt3zlql td.tinytable_css_2te7t89t3jcng1pmy5g6, #tinytable_wxtu900w9ek62pt3zlql th.tinytable_css_2te7t89t3jcng1pmy5g6 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_wxtu900w9ek62pt3zlql td.tinytable_css_jgz8uprd1nbvnbol3z2t, #tinytable_wxtu900w9ek62pt3zlql th.tinytable_css_jgz8uprd1nbvnbol3z2t {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_wxtu900w9ek62pt3zlql td.tinytable_css_0eezrzkulsy16hjhyb77, #tinytable_wxtu900w9ek62pt3zlql th.tinytable_css_0eezrzkulsy16hjhyb77 { text-align: left }
    #tinytable_wxtu900w9ek62pt3zlql td.tinytable_css_9uuxag8jeee27lgnoknb, #tinytable_wxtu900w9ek62pt3zlql th.tinytable_css_9uuxag8jeee27lgnoknb {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    </style>
    <div class="container">
      <table class="tinytable" id="tinytable_wxtu900w9ek62pt3zlql" style="width: auto; margin-left: auto; margin-right: auto;" data-quarto-disable-processing='true'>
        &#10;        <thead>
              <tr>
                <th scope="col" data-row="0" data-col="1"> </th>
                <th scope="col" data-row="0" data-col="2">XGBoost</th>
                <th scope="col" data-row="0" data-col="3">Lasso</th>
              </tr>
        </thead>
        &#10;        <tbody>
                <tr>
                  <td data-row="1" data-col="1">log(reward)</td>
                  <td data-row="1" data-col="2">−0.062</td>
                  <td data-row="1" data-col="3">−0.103</td>
                </tr>
                <tr>
                  <td data-row="2" data-col="1"></td>
                  <td data-row="2" data-col="2">(0.012)</td>
                  <td data-row="2" data-col="3">(0.044)</td>
                </tr>
                <tr>
                  <td data-row="3" data-col="1">n</td>
                  <td data-row="3" data-col="2">258352</td>
                  <td data-row="3" data-col="3">258352</td>
                </tr>
                <tr>
                  <td data-row="4" data-col="1">K</td>
                  <td data-row="4" data-col="2">3</td>
                  <td data-row="4" data-col="3">3</td>
                </tr>
                <tr>
                  <td data-row="5" data-col="1">R²(Y|X)</td>
                  <td data-row="5" data-col="2">0.868</td>
                  <td data-row="5" data-col="3">0.679</td>
                </tr>
                <tr>
                  <td data-row="6" data-col="1">R²(D|X)</td>
                  <td data-row="6" data-col="2">0.750</td>
                  <td data-row="6" data-col="3">0.728</td>
                </tr>
        </tbody>
      </table>
    </div>
<!-- hack to avoid NA insertion in last line -->

</div>

What to read off the table. The two estimates differ materially — Lasso lands roughly $1.7\times$ further from zero than XGBoost, and with a standard error several times larger. Lasso’s outcome $R^2$ sits ~20 percentage points below XGBoost’s, but its treatment $R^2$ is broadly comparable; that asymmetric drop is enough to make the linear residualisation of $Y$ noticeably noisier. The DDML paper’s Table 5 shows a sharper version of this gap (CV-lasso outcome $R^2 \approx 6\text{–}15\%$ vs XGBoost in the seventies); here the embedding columns help linear models more than they help in the no-text setting, so Lasso doesn’t fall as far. The lesson is not that “DDML disagrees with itself”; it is that the learner with the better cross-fitted prediction is the one whose residualisation we should trust.

## 2. Stacking the learners

The remedy the paper proposes for learner sensitivity is short-stacking: regress $Y$ (and $D$) on the cross-fitted predicted values of every candidate learner, under non-negative weights that sum to one, and use the resulting weights to build a super-learner for each nuisance function. The `ddml_plm` interface supports this directly via `shortstack = TRUE` with `ensemble_type = "nnls1"`:

``` r
fit <- ddml_plm(
  y = y, D = D, X = X,
  learners      = list(xgb_spec, lasso_spec, ridge_spec, rf_spec),
  ensemble_type = c("nnls1", "singlebest"),
  shortstack    = TRUE,
  sample_folds  = 5,
  silent        = TRUE
)
```

> *Stacking sweep not run in `blog3_robust.R`. See `Code/dube_monopsony/` for the full implementation.*

The paper’s Table 6 reports stacked-DDML at $\hat\theta_0 = -0.054$ (s.e. $0.020$) and single-best at $-0.060$ (s.e. $0.018$); the stacking weights load almost entirely on the three XGBoost specifications. The practical implication is that *if* one cannot decide between learners ex ante, short-stacking does the deciding inside the cross-fit and inherits XGBoost’s performance when it dominates the linear alternatives, as it does here.

## 3. Multi-seed aggregation

A single seed lands the estimator on one random partition of the data into folds. Asymptotically that does not matter; in finite samples it can. Section 5 of the review paper recommends repeating the cross-fitting $S$ times and reporting the **median-of-medians** of Chernozhukov et al. (2018, eq. 23):

$$\hat\theta_0^{\text{median}} = \mathrm{median}\bigl\{\hat\theta_{0,s}\bigr\}_{s=1}^{S},\qquad
\widehat{\mathrm{s.e.}}^{\text{median}} \;=\; \sqrt{\mathrm{median}\bigl\{\widehat{\mathrm{s.e.}}_s^{\,2} + (\hat\theta_{0,s} - \hat\theta_0^{\text{median}})^2\bigr\}_{s=1}^{S}}.$$

The standard error absorbs both sampling uncertainty and the variability induced by sample splitting. We use $S = 5$ seeds, matching the paper:

``` r
seeds <- c(12487, 17929, 28327, 63595, 85886)
fits  <- lapply(seeds, function(s) ddml_with_embed(seed = s,
                                                   foldnum = 3,
                                                   learner = xgb_spec,
                                                   cluster = TRUE))
```

<div id="tbl-multiseed">

Table 2: Per-seed estimates and median-of-medians aggregation. XGBoost; K = 3 cluster-honest folds; cluster-robust SE per seed.
<!-- preamble start -->
&#10;    <script src="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.js"></script>
&#10;    <script>
      // Create table-specific functions using external factory
      const tableFns_wur38noqkiggyky5olcn = TinyTable.createTableFunctions("tinytable_wur38noqkiggyky5olcn");
      // tinytable span after
      window.addEventListener('load', function () {
          var cellsToStyle = [
            // tinytable style arrays after
          { positions: [ { i: '6', j: 2 }, { i: '6', j: 3 }, { i: '6', j: 4 }, { i: '6', j: 5 }, { i: '6', j: 6 }, { i: '6', j: 7 } ], css_id: 'tinytable_css_503qc6xhd7105ujul311',}, 
          { positions: [ { i: '2', j: 2 }, { i: '2', j: 3 }, { i: '2', j: 4 }, { i: '2', j: 5 }, { i: '2', j: 6 }, { i: '2', j: 7 } ], css_id: 'tinytable_css_ed8r8mjj17gntbynx51e',}, 
          { positions: [ { i: '1', j: 2 }, { i: '3', j: 2 }, { i: '4', j: 2 }, { i: '5', j: 2 }, { i: '1', j: 3 }, { i: '3', j: 3 }, { i: '4', j: 3 }, { i: '5', j: 3 }, { i: '1', j: 4 }, { i: '3', j: 4 }, { i: '4', j: 4 }, { i: '5', j: 4 }, { i: '1', j: 5 }, { i: '3', j: 5 }, { i: '4', j: 5 }, { i: '5', j: 5 }, { i: '1', j: 6 }, { i: '3', j: 6 }, { i: '4', j: 6 }, { i: '5', j: 6 }, { i: '1', j: 7 }, { i: '3', j: 7 }, { i: '4', j: 7 }, { i: '5', j: 7 } ], css_id: 'tinytable_css_qwj2wd1gxm22frcx6iyf',}, 
          { positions: [ { i: '0', j: 2 }, { i: '0', j: 3 }, { i: '0', j: 4 }, { i: '0', j: 5 }, { i: '0', j: 6 }, { i: '0', j: 7 } ], css_id: 'tinytable_css_jzefwhg1lpk7ovu64po5',}, 
          { positions: [ { i: '6', j: 1 } ], css_id: 'tinytable_css_nordaikiab3np4a5ibgk',}, 
          { positions: [ { i: '2', j: 1 } ], css_id: 'tinytable_css_jbh4fjazs9qnayqvdy8f',}, 
          { positions: [ { i: '1', j: 1 }, { i: '3', j: 1 }, { i: '4', j: 1 }, { i: '5', j: 1 } ], css_id: 'tinytable_css_jc0mib51usoijjyn4t8e',}, 
          { positions: [ { i: '0', j: 1 } ], css_id: 'tinytable_css_cvt2b0r2cl927d5bb0n3',}, 
          ];
&#10;          // Loop over the arrays to style the cells
          cellsToStyle.forEach(function (group) {
              group.positions.forEach(function (cell) {
                  tableFns_wur38noqkiggyky5olcn.styleCell(cell.i, cell.j, group.css_id);
              });
          });
      });
    </script>
&#10;    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.css">
    <style>
    /* tinytable css entries after */
    #tinytable_wur38noqkiggyky5olcn td.tinytable_css_503qc6xhd7105ujul311, #tinytable_wur38noqkiggyky5olcn th.tinytable_css_503qc6xhd7105ujul311 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_wur38noqkiggyky5olcn td.tinytable_css_ed8r8mjj17gntbynx51e, #tinytable_wur38noqkiggyky5olcn th.tinytable_css_ed8r8mjj17gntbynx51e {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_wur38noqkiggyky5olcn td.tinytable_css_qwj2wd1gxm22frcx6iyf, #tinytable_wur38noqkiggyky5olcn th.tinytable_css_qwj2wd1gxm22frcx6iyf { text-align: center }
    #tinytable_wur38noqkiggyky5olcn td.tinytable_css_jzefwhg1lpk7ovu64po5, #tinytable_wur38noqkiggyky5olcn th.tinytable_css_jzefwhg1lpk7ovu64po5 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_wur38noqkiggyky5olcn td.tinytable_css_nordaikiab3np4a5ibgk, #tinytable_wur38noqkiggyky5olcn th.tinytable_css_nordaikiab3np4a5ibgk {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_wur38noqkiggyky5olcn td.tinytable_css_jbh4fjazs9qnayqvdy8f, #tinytable_wur38noqkiggyky5olcn th.tinytable_css_jbh4fjazs9qnayqvdy8f {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_wur38noqkiggyky5olcn td.tinytable_css_jc0mib51usoijjyn4t8e, #tinytable_wur38noqkiggyky5olcn th.tinytable_css_jc0mib51usoijjyn4t8e { text-align: left }
    #tinytable_wur38noqkiggyky5olcn td.tinytable_css_cvt2b0r2cl927d5bb0n3, #tinytable_wur38noqkiggyky5olcn th.tinytable_css_cvt2b0r2cl927d5bb0n3 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    </style>
    <div class="container">
      <table class="tinytable" id="tinytable_wur38noqkiggyky5olcn" style="width: auto; margin-left: auto; margin-right: auto;" data-quarto-disable-processing='true'>
        &#10;        <thead>
              <tr>
                <th scope="col" data-row="0" data-col="1"> </th>
                <th scope="col" data-row="0" data-col="2">seed=12487</th>
                <th scope="col" data-row="0" data-col="3">seed=17929</th>
                <th scope="col" data-row="0" data-col="4">seed=28327</th>
                <th scope="col" data-row="0" data-col="5">seed=63595</th>
                <th scope="col" data-row="0" data-col="6">seed=85886</th>
                <th scope="col" data-row="0" data-col="7">median-of-medians (S=5)</th>
              </tr>
        </thead>
        &#10;        <tbody>
                <tr>
                  <td data-row="1" data-col="1">log(reward)</td>
                  <td data-row="1" data-col="2">−0.062</td>
                  <td data-row="1" data-col="3">−0.081</td>
                  <td data-row="1" data-col="4">−0.056</td>
                  <td data-row="1" data-col="5">−0.089</td>
                  <td data-row="1" data-col="6">−0.057</td>
                  <td data-row="1" data-col="7">−0.062</td>
                </tr>
                <tr>
                  <td data-row="2" data-col="1"></td>
                  <td data-row="2" data-col="2">(0.012)</td>
                  <td data-row="2" data-col="3">(0.025)</td>
                  <td data-row="2" data-col="4">(0.020)</td>
                  <td data-row="2" data-col="5">(0.031)</td>
                  <td data-row="2" data-col="6">(0.023)</td>
                  <td data-row="2" data-col="7">(0.024)</td>
                </tr>
                <tr>
                  <td data-row="3" data-col="1">n</td>
                  <td data-row="3" data-col="2">258352</td>
                  <td data-row="3" data-col="3">258352</td>
                  <td data-row="3" data-col="4">258352</td>
                  <td data-row="3" data-col="5">258352</td>
                  <td data-row="3" data-col="6">258352</td>
                  <td data-row="3" data-col="7">258352</td>
                </tr>
                <tr>
                  <td data-row="4" data-col="1">K</td>
                  <td data-row="4" data-col="2">3</td>
                  <td data-row="4" data-col="3">3</td>
                  <td data-row="4" data-col="4">3</td>
                  <td data-row="4" data-col="5">3</td>
                  <td data-row="4" data-col="6">3</td>
                  <td data-row="4" data-col="7">3</td>
                </tr>
                <tr>
                  <td data-row="5" data-col="1">R²(Y|X)</td>
                  <td data-row="5" data-col="2">0.868</td>
                  <td data-row="5" data-col="3">0.859</td>
                  <td data-row="5" data-col="4">0.858</td>
                  <td data-row="5" data-col="5">0.851</td>
                  <td data-row="5" data-col="6">0.859</td>
                  <td data-row="5" data-col="7">0.859</td>
                </tr>
                <tr>
                  <td data-row="6" data-col="1">R²(D|X)</td>
                  <td data-row="6" data-col="2">0.750</td>
                  <td data-row="6" data-col="3">0.721</td>
                  <td data-row="6" data-col="4">0.729</td>
                  <td data-row="6" data-col="5">0.738</td>
                  <td data-row="6" data-col="6">0.746</td>
                  <td data-row="6" data-col="7">0.738</td>
                </tr>
        </tbody>
      </table>
    </div>
<!-- hack to avoid NA insertion in last line -->

</div>

Read the median-of-medians row against the per-seed rows. The single-seed estimates span roughly $-0.06$ to $-0.09$ — a non-trivial spread relative to any individual seed’s SE — so sample-split randomness is real here. The median-of-medians SE ($\approx 0.024$) is roughly twice any single-seed SE precisely because the eq. 23 formula adds the cross-seed dispersion $(\hat\theta_s - \hat\theta^{\text{median}})^2$ to each seed’s variance before taking the median. The headline elasticity in Entries 1–2 is the seed-1 estimate; the inference-bearing number for this dataset is the median-of-medians row.

## 4. Sensitivity to the number of folds $K$

Cross-fitting theory accommodates any fixed $K$. Velez (2024) shows performance improves with more folds, peaking at $K = n$ with diminishing returns; the review paper’s Implementation Guidance summarises this as: choose a round number consistent with available compute, and check sensitivity if you can.

<div id="tbl-K">

Table 3: Coefficient on log(reward) by number of folds K. XGBoost; cluster-honest folds; cluster-robust SE.
<!-- preamble start -->
&#10;    <script src="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.js"></script>
&#10;    <script>
      // Create table-specific functions using external factory
      const tableFns_w2kptcyz45ys4at4anod = TinyTable.createTableFunctions("tinytable_w2kptcyz45ys4at4anod");
      // tinytable span after
      window.addEventListener('load', function () {
          var cellsToStyle = [
            // tinytable style arrays after
          { positions: [ { i: '6', j: 2 }, { i: '6', j: 3 } ], css_id: 'tinytable_css_bi8crkt3upukg4eq38f2',}, 
          { positions: [ { i: '2', j: 2 }, { i: '2', j: 3 } ], css_id: 'tinytable_css_2gl54i2if92z4krwk7gi',}, 
          { positions: [ { i: '1', j: 2 }, { i: '3', j: 2 }, { i: '4', j: 2 }, { i: '5', j: 2 }, { i: '1', j: 3 }, { i: '3', j: 3 }, { i: '4', j: 3 }, { i: '5', j: 3 } ], css_id: 'tinytable_css_734uzo0vkr1gkqnn2m8m',}, 
          { positions: [ { i: '0', j: 2 }, { i: '0', j: 3 } ], css_id: 'tinytable_css_wdacyih6jcoidrymhg3n',}, 
          { positions: [ { i: '6', j: 1 } ], css_id: 'tinytable_css_tmz5uk2mhs3tfecudqlf',}, 
          { positions: [ { i: '2', j: 1 } ], css_id: 'tinytable_css_xdsd04wym2q686u2hnzp',}, 
          { positions: [ { i: '1', j: 1 }, { i: '3', j: 1 }, { i: '4', j: 1 }, { i: '5', j: 1 } ], css_id: 'tinytable_css_l0dko89rt3tmqnnibj4i',}, 
          { positions: [ { i: '0', j: 1 } ], css_id: 'tinytable_css_ze0w1gppb2por4lca5ni',}, 
          ];
&#10;          // Loop over the arrays to style the cells
          cellsToStyle.forEach(function (group) {
              group.positions.forEach(function (cell) {
                  tableFns_w2kptcyz45ys4at4anod.styleCell(cell.i, cell.j, group.css_id);
              });
          });
      });
    </script>
&#10;    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.css">
    <style>
    /* tinytable css entries after */
    #tinytable_w2kptcyz45ys4at4anod td.tinytable_css_bi8crkt3upukg4eq38f2, #tinytable_w2kptcyz45ys4at4anod th.tinytable_css_bi8crkt3upukg4eq38f2 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_w2kptcyz45ys4at4anod td.tinytable_css_2gl54i2if92z4krwk7gi, #tinytable_w2kptcyz45ys4at4anod th.tinytable_css_2gl54i2if92z4krwk7gi {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_w2kptcyz45ys4at4anod td.tinytable_css_734uzo0vkr1gkqnn2m8m, #tinytable_w2kptcyz45ys4at4anod th.tinytable_css_734uzo0vkr1gkqnn2m8m { text-align: center }
    #tinytable_w2kptcyz45ys4at4anod td.tinytable_css_wdacyih6jcoidrymhg3n, #tinytable_w2kptcyz45ys4at4anod th.tinytable_css_wdacyih6jcoidrymhg3n {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_w2kptcyz45ys4at4anod td.tinytable_css_tmz5uk2mhs3tfecudqlf, #tinytable_w2kptcyz45ys4at4anod th.tinytable_css_tmz5uk2mhs3tfecudqlf {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_w2kptcyz45ys4at4anod td.tinytable_css_xdsd04wym2q686u2hnzp, #tinytable_w2kptcyz45ys4at4anod th.tinytable_css_xdsd04wym2q686u2hnzp {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_w2kptcyz45ys4at4anod td.tinytable_css_l0dko89rt3tmqnnibj4i, #tinytable_w2kptcyz45ys4at4anod th.tinytable_css_l0dko89rt3tmqnnibj4i { text-align: left }
    #tinytable_w2kptcyz45ys4at4anod td.tinytable_css_ze0w1gppb2por4lca5ni, #tinytable_w2kptcyz45ys4at4anod th.tinytable_css_ze0w1gppb2por4lca5ni {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    </style>
    <div class="container">
      <table class="tinytable" id="tinytable_w2kptcyz45ys4at4anod" style="width: auto; margin-left: auto; margin-right: auto;" data-quarto-disable-processing='true'>
        &#10;        <thead>
              <tr>
                <th scope="col" data-row="0" data-col="1"> </th>
                <th scope="col" data-row="0" data-col="2">K=3</th>
                <th scope="col" data-row="0" data-col="3">K=5</th>
              </tr>
        </thead>
        &#10;        <tbody>
                <tr>
                  <td data-row="1" data-col="1">log(reward)</td>
                  <td data-row="1" data-col="2">−0.062</td>
                  <td data-row="1" data-col="3">−0.052</td>
                </tr>
                <tr>
                  <td data-row="2" data-col="1"></td>
                  <td data-row="2" data-col="2">(0.012)</td>
                  <td data-row="2" data-col="3">(0.019)</td>
                </tr>
                <tr>
                  <td data-row="3" data-col="1">n</td>
                  <td data-row="3" data-col="2">258352</td>
                  <td data-row="3" data-col="3">258352</td>
                </tr>
                <tr>
                  <td data-row="4" data-col="1">K</td>
                  <td data-row="4" data-col="2">3</td>
                  <td data-row="4" data-col="3">5</td>
                </tr>
                <tr>
                  <td data-row="5" data-col="1">R²(Y|X)</td>
                  <td data-row="5" data-col="2">0.868</td>
                  <td data-row="5" data-col="3">0.862</td>
                </tr>
                <tr>
                  <td data-row="6" data-col="1">R²(D|X)</td>
                  <td data-row="6" data-col="2">0.750</td>
                  <td data-row="6" data-col="3">0.731</td>
                </tr>
        </tbody>
      </table>
    </div>
<!-- hack to avoid NA insertion in last line -->

</div>

The point estimate moves modestly across $K \in \{3, 5\}$ (roughly within an SE of each other), but the SE itself widens noticeably — $K = 5$ trains each nuisance fit on $4/5$ of the data instead of $2/3$, but the cross-seed-style noise across the 5 held-out folds shows up in the cluster-robust SE. Compute time scales roughly linearly with $K$. The paper’s Implementation Guidance recommends choosing $K$ as the largest round number consistent with available compute; with $n \approx 258{,}000$ either value here is in the range where the bias-variance tradeoff is favourable.

## 5. Cluster-respecting vs IID folds

This is the one sweep where leaving the default behind is the point. The Ipeirotis cross-section has many postings per recruiter, and the same recruiter’s HITs share unobserved features (recruiter style, payout norms, qualification preferences) that correlate with both posted reward and fill time. Splitting at the observation level lets siblings from the same recruiter sit on both sides of the fold boundary — which makes the residuals look more independent than they are, and the cross-fitted $R^2$ look better than the true generalisation $R^2$.

In `ddml_plm` the lever is whether `cluster_variable` is supplied. Passing the recruiter id forms recruiter-honest folds and clusters SEs at the same level; omitting it gives random IID folds and uses heteroskedasticity-robust SEs.

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

<div id="tbl-fold">

Table 4: Coefficient on log(reward) under recruiter-clustered vs IID folds, with matching SE estimator. XGBoost; K = 3.
<!-- preamble start -->
&#10;    <script src="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.js"></script>
&#10;    <script>
      // Create table-specific functions using external factory
      const tableFns_pbz2lhnnqfdu7v397xky = TinyTable.createTableFunctions("tinytable_pbz2lhnnqfdu7v397xky");
      // tinytable span after
      window.addEventListener('load', function () {
          var cellsToStyle = [
            // tinytable style arrays after
          { positions: [ { i: '6', j: 2 }, { i: '6', j: 3 } ], css_id: 'tinytable_css_305pzrpxkgfz7nselj6d',}, 
          { positions: [ { i: '2', j: 2 }, { i: '2', j: 3 } ], css_id: 'tinytable_css_ixbaqms9nla0fs0j5d3p',}, 
          { positions: [ { i: '1', j: 2 }, { i: '3', j: 2 }, { i: '4', j: 2 }, { i: '5', j: 2 }, { i: '1', j: 3 }, { i: '3', j: 3 }, { i: '4', j: 3 }, { i: '5', j: 3 } ], css_id: 'tinytable_css_plq8mt5wpefuzw4ou83e',}, 
          { positions: [ { i: '0', j: 2 }, { i: '0', j: 3 } ], css_id: 'tinytable_css_n5bd6n9h9vwqe47xld2o',}, 
          { positions: [ { i: '6', j: 1 } ], css_id: 'tinytable_css_dmewcrc8rntvdoctq6xs',}, 
          { positions: [ { i: '2', j: 1 } ], css_id: 'tinytable_css_oprh4fmrepfao75ml4vu',}, 
          { positions: [ { i: '1', j: 1 }, { i: '3', j: 1 }, { i: '4', j: 1 }, { i: '5', j: 1 } ], css_id: 'tinytable_css_jda5gvztztuinay9sx1j',}, 
          { positions: [ { i: '0', j: 1 } ], css_id: 'tinytable_css_5gn7bk1vzw0xltyovoc8',}, 
          ];
&#10;          // Loop over the arrays to style the cells
          cellsToStyle.forEach(function (group) {
              group.positions.forEach(function (cell) {
                  tableFns_pbz2lhnnqfdu7v397xky.styleCell(cell.i, cell.j, group.css_id);
              });
          });
      });
    </script>
&#10;    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.css">
    <style>
    /* tinytable css entries after */
    #tinytable_pbz2lhnnqfdu7v397xky td.tinytable_css_305pzrpxkgfz7nselj6d, #tinytable_pbz2lhnnqfdu7v397xky th.tinytable_css_305pzrpxkgfz7nselj6d {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_pbz2lhnnqfdu7v397xky td.tinytable_css_ixbaqms9nla0fs0j5d3p, #tinytable_pbz2lhnnqfdu7v397xky th.tinytable_css_ixbaqms9nla0fs0j5d3p {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_pbz2lhnnqfdu7v397xky td.tinytable_css_plq8mt5wpefuzw4ou83e, #tinytable_pbz2lhnnqfdu7v397xky th.tinytable_css_plq8mt5wpefuzw4ou83e { text-align: center }
    #tinytable_pbz2lhnnqfdu7v397xky td.tinytable_css_n5bd6n9h9vwqe47xld2o, #tinytable_pbz2lhnnqfdu7v397xky th.tinytable_css_n5bd6n9h9vwqe47xld2o {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_pbz2lhnnqfdu7v397xky td.tinytable_css_dmewcrc8rntvdoctq6xs, #tinytable_pbz2lhnnqfdu7v397xky th.tinytable_css_dmewcrc8rntvdoctq6xs {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_pbz2lhnnqfdu7v397xky td.tinytable_css_oprh4fmrepfao75ml4vu, #tinytable_pbz2lhnnqfdu7v397xky th.tinytable_css_oprh4fmrepfao75ml4vu {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_pbz2lhnnqfdu7v397xky td.tinytable_css_jda5gvztztuinay9sx1j, #tinytable_pbz2lhnnqfdu7v397xky th.tinytable_css_jda5gvztztuinay9sx1j { text-align: left }
    #tinytable_pbz2lhnnqfdu7v397xky td.tinytable_css_5gn7bk1vzw0xltyovoc8, #tinytable_pbz2lhnnqfdu7v397xky th.tinytable_css_5gn7bk1vzw0xltyovoc8 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    </style>
    <div class="container">
      <table class="tinytable" id="tinytable_pbz2lhnnqfdu7v397xky" style="width: auto; margin-left: auto; margin-right: auto;" data-quarto-disable-processing='true'>
        &#10;        <thead>
              <tr>
                <th scope="col" data-row="0" data-col="1"> </th>
                <th scope="col" data-row="0" data-col="2">Cluster</th>
                <th scope="col" data-row="0" data-col="3">IID</th>
              </tr>
        </thead>
        &#10;        <tbody>
                <tr>
                  <td data-row="1" data-col="1">log(reward)</td>
                  <td data-row="1" data-col="2">−0.062</td>
                  <td data-row="1" data-col="3">−0.041</td>
                </tr>
                <tr>
                  <td data-row="2" data-col="1"></td>
                  <td data-row="2" data-col="2">(0.012)</td>
                  <td data-row="2" data-col="3">(0.006)</td>
                </tr>
                <tr>
                  <td data-row="3" data-col="1">n</td>
                  <td data-row="3" data-col="2">258352</td>
                  <td data-row="3" data-col="3">258352</td>
                </tr>
                <tr>
                  <td data-row="4" data-col="1">K</td>
                  <td data-row="4" data-col="2">3</td>
                  <td data-row="4" data-col="3">3</td>
                </tr>
                <tr>
                  <td data-row="5" data-col="1">R²(Y|X)</td>
                  <td data-row="5" data-col="2">0.868</td>
                  <td data-row="5" data-col="3">0.892</td>
                </tr>
                <tr>
                  <td data-row="6" data-col="1">R²(D|X)</td>
                  <td data-row="6" data-col="2">0.750</td>
                  <td data-row="6" data-col="3">0.880</td>
                </tr>
        </tbody>
      </table>
    </div>
<!-- hack to avoid NA insertion in last line -->

</div>

Two things to watch. The cross-fitted $R^2$ values typically *fall* when fold construction moves from IID to recruiter-honest, because the held-out fold now contains recruiters the nuisance learner never saw — that is the honest predictive performance and it is what should enter the DDML score. The standard error typically *rises*, because clustering at the recruiter level accounts for the correlated residuals that het-robust ignores. Footnote 19 of the review paper, which points to an online-appendix table comparing the two, makes the same point: the cluster-honest combination is the inference-bearing one for this application, which is why Entries 1–2 and the rest of this post use it as their default.

## 6. What to take away

- A single ML learner is not a complete DDML specification. The point estimate is informative only when the nuisance learner can actually predict — cross-fitted $R^2$ is the diagnostic to lean on.
- Short-stacking (or, more conservatively, reporting both stacking and single-best) sidesteps the learner-selection problem and is cheap relative to refitting four nuisance models from scratch.
- Median-of-medians over $S \ge 3$ seeds is the inference-bearing point estimate; one-seed numbers are fine for iteration but should not be the published number.
- $K$ matters less than the other knobs in this application.
- Cluster vs IID fold construction is the design decision with the largest swing in SE and the most consequential one for inference. The blog defaults to recruiter-honest folds + cluster-robust SEs; the IID variant is included only as a contrast.

## References

- Ahrens, A., V. Chernozhukov, C. Hansen, D. Kozbur, M. Schaffer and T. Wiemann. *An Introduction to Double/Debiased Machine Learning.* §5 (median aggregation), §6 (Dube application, Tables 5–6), §7 (implementation guidance).
- Ahrens, A., C. B. Hansen, M. E. Schaffer and T. Wiemann (2024). [`ddml`: Double/debiased machine learning in R.](https://doi.org/10.18637/jss.v108.i03)
- Chernozhukov, V., D. Chetverikov, M. Demirer, E. Duflo, C. Hansen, W. Newey and J. Robins (2018). [Double/Debiased machine learning for treatment and structural parameters.](https://doi.org/10.1111/ectj.12097)
- Dube, A., J. Jacobs, S. Naidu and S. Suri (2020). [Monopsony in online labor markets.](https://doi.org/10.3386/w26108) *AER: Insights* 2 (1).
- Lei, J. (2020). Cross-validation with confidence. *Journal of the American Statistical Association.*
- Velez, A. (2024). On the asymptotic properties of debiased machine learning estimators.
