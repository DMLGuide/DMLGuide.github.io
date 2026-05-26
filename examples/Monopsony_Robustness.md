---
layout: default
title: Monopsony III — Further analysis
parent: Examples
nav_order: 36
math: true
description: "Varying the nuisance learner, the number of cross-fitting seeds, K, and cluster-vs-IID fold construction."
permalink: /examples/Monopsony_Robustness
enable_copy_code_button: true
---

# Monopsony III — how robust is the headline elasticity?

*Part 3 of a three-post series. <a href="{{ '/examples/Monopsony_DML' | relative_url }}">Part 1</a> ran DDML on the Dube et al. (2020) MTurk data with hand-coded controls only. <a href="{{ '/examples/Monopsony_Finetune' | relative_url }}">Part 2</a> added fine-tuned DeBERTa embeddings. Both used $K = 3$ recruiter-honest folds, a single XGBoost nuisance learner, one seed, and cluster-robust standard errors at the recruiter level. This post asks: how much of that headline number is a function of those choices?*

This final part highlights validation checks worth running when applying DDML. We start by repeating the baseline cross-fitting under $S = 5$ independent randomisation seeds and aggregating them with the paper’s median-of-medians estimator. We then compare the resulting baseline median *pairwise* against three one-knob variants — a different nuisance learner, IID instead of recruiter-honest fold construction, and a larger number of folds — so each knob’s contribution can be read in isolation.

The baseline throughout is the Part 2 specification: $K = 3$ recruiter-honest folds, XGBoost (the third XGB configuration, `XGB 3`) as the reported nuisance learner, and cluster-robust standard errors at the recruiter level. All numbers in this post are read directly from the per-seed `.RData` results saved by `Code/dube_monopsony/run_cvc.R`; the setup chunk walks the `monopsony_data/intermediate` tree and exposes them as the named lists `iid_K3`, `xclust_K3`, and `xclust_K5`, each keyed by seed.

## 1. Multi-seed aggregation

A single randomization seed generates one random partition of the sample into folds, and also affects machine learning algorithms relying on randomization. Asymptotically the exact random partition does not matter; in finite samples it can make a difference. Section 5 of the review paper recommends repeating the cross-fitting $S$ times and reporting the median-aggregate estimate:

$$\hat\theta_0^{\text{median}} = \mathrm{median}\bigl\{\hat\theta_{0,s}\bigr\}_{s=1}^{S},\qquad
\widehat{\mathrm{s.e.}}^{\text{median}} \;=\; \sqrt{\mathrm{median}\bigl\{\widehat{\mathrm{s.e.}}_s^{\,2} + (\hat\theta_{0,s} - \hat\theta_0^{\text{median}})^2\bigr\}_{s=1}^{S}}.$$

We here use $S = 5$ seeds, matching the paper.

<div id="tbl-multiseed">

Table 1: Per-seed estimates and median-of-medians aggregation for the baseline specification. XGB 3 nuisance learner; K = 3 recruiter-honest folds; cluster-robust SE per seed. R² rows are seed-specific for the per-seed columns and median-across-seeds for the aggregate column.
<!-- preamble start -->
&#10;    <script src="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.js"></script>
&#10;    <script>
      // Create table-specific functions using external factory
      const tableFns_musp3ubai0h0wiphh5jn = TinyTable.createTableFunctions("tinytable_musp3ubai0h0wiphh5jn");
      // tinytable span after
      window.addEventListener('load', function () {
          var cellsToStyle = [
            // tinytable style arrays after
          { positions: [ { i: '5', j: 2 }, { i: '5', j: 3 }, { i: '5', j: 4 }, { i: '5', j: 5 }, { i: '5', j: 6 }, { i: '5', j: 7 } ], css_id: 'tinytable_css_rqocdvkwx5ig247utqh1',}, 
          { positions: [ { i: '2', j: 2 }, { i: '2', j: 3 }, { i: '2', j: 4 }, { i: '2', j: 5 }, { i: '2', j: 6 }, { i: '2', j: 7 } ], css_id: 'tinytable_css_gpt0pz0dl03gex2lokj7',}, 
          { positions: [ { i: '1', j: 2 }, { i: '3', j: 2 }, { i: '4', j: 2 }, { i: '1', j: 3 }, { i: '3', j: 3 }, { i: '4', j: 3 }, { i: '1', j: 4 }, { i: '3', j: 4 }, { i: '4', j: 4 }, { i: '1', j: 5 }, { i: '3', j: 5 }, { i: '4', j: 5 }, { i: '1', j: 6 }, { i: '3', j: 6 }, { i: '4', j: 6 }, { i: '1', j: 7 }, { i: '3', j: 7 }, { i: '4', j: 7 } ], css_id: 'tinytable_css_if09b27soln7rbkjdk24',}, 
          { positions: [ { i: '0', j: 2 }, { i: '0', j: 3 }, { i: '0', j: 4 }, { i: '0', j: 5 }, { i: '0', j: 6 }, { i: '0', j: 7 } ], css_id: 'tinytable_css_njuq26x1lte4y64xzf6z',}, 
          { positions: [ { i: '5', j: 1 } ], css_id: 'tinytable_css_r788ahqs94a7h8gsrvv6',}, 
          { positions: [ { i: '2', j: 1 } ], css_id: 'tinytable_css_hn6jvjntd1rb1y79tf29',}, 
          { positions: [ { i: '1', j: 1 }, { i: '3', j: 1 }, { i: '4', j: 1 } ], css_id: 'tinytable_css_xzg5446ypgx6jzg50kvj',}, 
          { positions: [ { i: '0', j: 1 } ], css_id: 'tinytable_css_t2x6a312kylv5qvw3gce',}, 
          ];
&#10;          // Loop over the arrays to style the cells
          cellsToStyle.forEach(function (group) {
              group.positions.forEach(function (cell) {
                  tableFns_musp3ubai0h0wiphh5jn.styleCell(cell.i, cell.j, group.css_id);
              });
          });
      });
    </script>
&#10;    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.css">
    <style>
    /* tinytable css entries after */
    #tinytable_musp3ubai0h0wiphh5jn td.tinytable_css_rqocdvkwx5ig247utqh1, #tinytable_musp3ubai0h0wiphh5jn th.tinytable_css_rqocdvkwx5ig247utqh1 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_musp3ubai0h0wiphh5jn td.tinytable_css_gpt0pz0dl03gex2lokj7, #tinytable_musp3ubai0h0wiphh5jn th.tinytable_css_gpt0pz0dl03gex2lokj7 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_musp3ubai0h0wiphh5jn td.tinytable_css_if09b27soln7rbkjdk24, #tinytable_musp3ubai0h0wiphh5jn th.tinytable_css_if09b27soln7rbkjdk24 { text-align: center }
    #tinytable_musp3ubai0h0wiphh5jn td.tinytable_css_njuq26x1lte4y64xzf6z, #tinytable_musp3ubai0h0wiphh5jn th.tinytable_css_njuq26x1lte4y64xzf6z {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_musp3ubai0h0wiphh5jn td.tinytable_css_r788ahqs94a7h8gsrvv6, #tinytable_musp3ubai0h0wiphh5jn th.tinytable_css_r788ahqs94a7h8gsrvv6 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_musp3ubai0h0wiphh5jn td.tinytable_css_hn6jvjntd1rb1y79tf29, #tinytable_musp3ubai0h0wiphh5jn th.tinytable_css_hn6jvjntd1rb1y79tf29 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_musp3ubai0h0wiphh5jn td.tinytable_css_xzg5446ypgx6jzg50kvj, #tinytable_musp3ubai0h0wiphh5jn th.tinytable_css_xzg5446ypgx6jzg50kvj { text-align: left }
    #tinytable_musp3ubai0h0wiphh5jn td.tinytable_css_t2x6a312kylv5qvw3gce, #tinytable_musp3ubai0h0wiphh5jn th.tinytable_css_t2x6a312kylv5qvw3gce {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    </style>
    <div class="container">
      <table class="tinytable" id="tinytable_musp3ubai0h0wiphh5jn" style="width: auto; margin-left: auto; margin-right: auto;" data-quarto-disable-processing='true'>
        &#10;        <thead>
              <tr>
                <th scope="col" data-row="0" data-col="1"> </th>
                <th scope="col" data-row="0" data-col="2">seed12487</th>
                <th scope="col" data-row="0" data-col="3">seed17929</th>
                <th scope="col" data-row="0" data-col="4">seed28327</th>
                <th scope="col" data-row="0" data-col="5">seed63595</th>
                <th scope="col" data-row="0" data-col="6">seed85886</th>
                <th scope="col" data-row="0" data-col="7">median-of-medians (S=5)</th>
              </tr>
        </thead>
        &#10;        <tbody>
                <tr>
                  <td data-row="1" data-col="1">log(reward)</td>
                  <td data-row="1" data-col="2">−0.033</td>
                  <td data-row="1" data-col="3">−0.037</td>
                  <td data-row="1" data-col="4">−0.073</td>
                  <td data-row="1" data-col="5">−0.065</td>
                  <td data-row="1" data-col="6">−0.061</td>
                  <td data-row="1" data-col="7">−0.061</td>
                </tr>
                <tr>
                  <td data-row="2" data-col="1"></td>
                  <td data-row="2" data-col="2">(0.135)</td>
                  <td data-row="2" data-col="3">(0.173)</td>
                  <td data-row="2" data-col="4">(0.233)</td>
                  <td data-row="2" data-col="5">(0.306)</td>
                  <td data-row="2" data-col="6">(0.148)</td>
                  <td data-row="2" data-col="7">(0.174)</td>
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
                  <td data-row="4" data-col="1">R²(Y|X)</td>
                  <td data-row="4" data-col="2">0.867</td>
                  <td data-row="4" data-col="3">0.862</td>
                  <td data-row="4" data-col="4">0.863</td>
                  <td data-row="4" data-col="5">0.856</td>
                  <td data-row="4" data-col="6">0.861</td>
                  <td data-row="4" data-col="7">0.862</td>
                </tr>
                <tr>
                  <td data-row="5" data-col="1">R²(D|X)</td>
                  <td data-row="5" data-col="2">0.750</td>
                  <td data-row="5" data-col="3">0.719</td>
                  <td data-row="5" data-col="4">0.742</td>
                  <td data-row="5" data-col="5">0.744</td>
                  <td data-row="5" data-col="6">0.756</td>
                  <td data-row="5" data-col="7">0.744</td>
                </tr>
        </tbody>
      </table>
    </div>
<!-- hack to avoid NA insertion in last line -->

</div>

The single-seed estimates span a non-trivial range relative to any individual seed’s SE, so sample-split randomness has a noticeable impact in finite samples. The median-of-medians point estimate is the inference-bearing number we carry into the cross-set comparisons below.

## 2. Pairwise baseline-vs-variant comparisons

Each subsection below holds the baseline fixed and varies one knob. Every column is a median-of-medians over the same five seeds, so within-table differences reflect the knob rather than seed noise. R² rows are the median across seeds of the cross-fitted $R^2$ for that learner.

### 2.1 Choice of nuisance learner

<div id="tbl-learner">

Table 2: Baseline (XGB 3) vs. CV-Lasso, both aggregated over S = 5 seeds. K = 3 recruiter-honest folds; cluster-robust SE.
<!-- preamble start -->
&#10;    <script src="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.js"></script>
&#10;    <script>
      // Create table-specific functions using external factory
      const tableFns_q5f8bvb7uylkeb8fx2rq = TinyTable.createTableFunctions("tinytable_q5f8bvb7uylkeb8fx2rq");
      // tinytable span after
      window.addEventListener('load', function () {
          var cellsToStyle = [
            // tinytable style arrays after
          { positions: [ { i: '5', j: 2 }, { i: '5', j: 3 } ], css_id: 'tinytable_css_g3km4xwlma10dm5b0wwv',}, 
          { positions: [ { i: '2', j: 2 }, { i: '2', j: 3 } ], css_id: 'tinytable_css_z765n4hoixyukbp21qoj',}, 
          { positions: [ { i: '1', j: 2 }, { i: '3', j: 2 }, { i: '4', j: 2 }, { i: '1', j: 3 }, { i: '3', j: 3 }, { i: '4', j: 3 } ], css_id: 'tinytable_css_rk6yrc7goevjiu1qp53l',}, 
          { positions: [ { i: '0', j: 2 }, { i: '0', j: 3 } ], css_id: 'tinytable_css_1nugc7er97u9sep25woa',}, 
          { positions: [ { i: '5', j: 1 } ], css_id: 'tinytable_css_2zy4x6d7nigakp326ou3',}, 
          { positions: [ { i: '2', j: 1 } ], css_id: 'tinytable_css_mxq9uoy3cv0c75xj7lf2',}, 
          { positions: [ { i: '1', j: 1 }, { i: '3', j: 1 }, { i: '4', j: 1 } ], css_id: 'tinytable_css_lp844hwmu1m97s6v3jl5',}, 
          { positions: [ { i: '0', j: 1 } ], css_id: 'tinytable_css_o3v18xs2yfg9ec4frs9h',}, 
          ];
&#10;          // Loop over the arrays to style the cells
          cellsToStyle.forEach(function (group) {
              group.positions.forEach(function (cell) {
                  tableFns_q5f8bvb7uylkeb8fx2rq.styleCell(cell.i, cell.j, group.css_id);
              });
          });
      });
    </script>
&#10;    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.css">
    <style>
    /* tinytable css entries after */
    #tinytable_q5f8bvb7uylkeb8fx2rq td.tinytable_css_g3km4xwlma10dm5b0wwv, #tinytable_q5f8bvb7uylkeb8fx2rq th.tinytable_css_g3km4xwlma10dm5b0wwv {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_q5f8bvb7uylkeb8fx2rq td.tinytable_css_z765n4hoixyukbp21qoj, #tinytable_q5f8bvb7uylkeb8fx2rq th.tinytable_css_z765n4hoixyukbp21qoj {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_q5f8bvb7uylkeb8fx2rq td.tinytable_css_rk6yrc7goevjiu1qp53l, #tinytable_q5f8bvb7uylkeb8fx2rq th.tinytable_css_rk6yrc7goevjiu1qp53l { text-align: center }
    #tinytable_q5f8bvb7uylkeb8fx2rq td.tinytable_css_1nugc7er97u9sep25woa, #tinytable_q5f8bvb7uylkeb8fx2rq th.tinytable_css_1nugc7er97u9sep25woa {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_q5f8bvb7uylkeb8fx2rq td.tinytable_css_2zy4x6d7nigakp326ou3, #tinytable_q5f8bvb7uylkeb8fx2rq th.tinytable_css_2zy4x6d7nigakp326ou3 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_q5f8bvb7uylkeb8fx2rq td.tinytable_css_mxq9uoy3cv0c75xj7lf2, #tinytable_q5f8bvb7uylkeb8fx2rq th.tinytable_css_mxq9uoy3cv0c75xj7lf2 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_q5f8bvb7uylkeb8fx2rq td.tinytable_css_lp844hwmu1m97s6v3jl5, #tinytable_q5f8bvb7uylkeb8fx2rq th.tinytable_css_lp844hwmu1m97s6v3jl5 { text-align: left }
    #tinytable_q5f8bvb7uylkeb8fx2rq td.tinytable_css_o3v18xs2yfg9ec4frs9h, #tinytable_q5f8bvb7uylkeb8fx2rq th.tinytable_css_o3v18xs2yfg9ec4frs9h {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    </style>
    <div class="container">
      <table class="tinytable" id="tinytable_q5f8bvb7uylkeb8fx2rq" style="width: auto; margin-left: auto; margin-right: auto;" data-quarto-disable-processing='true'>
        &#10;        <thead>
              <tr>
                <th scope="col" data-row="0" data-col="1"> </th>
                <th scope="col" data-row="0" data-col="2">XGB 3 (baseline)</th>
                <th scope="col" data-row="0" data-col="3">CV-Lasso</th>
              </tr>
        </thead>
        &#10;        <tbody>
                <tr>
                  <td data-row="1" data-col="1">log(reward)</td>
                  <td data-row="1" data-col="2">−0.061</td>
                  <td data-row="1" data-col="3">−0.008</td>
                </tr>
                <tr>
                  <td data-row="2" data-col="1"></td>
                  <td data-row="2" data-col="2">(0.174)</td>
                  <td data-row="2" data-col="3">(0.522)</td>
                </tr>
                <tr>
                  <td data-row="3" data-col="1">n</td>
                  <td data-row="3" data-col="2">258352</td>
                  <td data-row="3" data-col="3">258352</td>
                </tr>
                <tr>
                  <td data-row="4" data-col="1">R²(Y|X)</td>
                  <td data-row="4" data-col="2">0.862</td>
                  <td data-row="4" data-col="3">0.679</td>
                </tr>
                <tr>
                  <td data-row="5" data-col="1">R²(D|X)</td>
                  <td data-row="5" data-col="2">0.744</td>
                  <td data-row="5" data-col="3">0.728</td>
                </tr>
        </tbody>
      </table>
    </div>
<!-- hack to avoid NA insertion in last line -->

</div>

The CV-Lasso column underperforms badly on both $R^2(Y\mid X)$ and $R^2(D\mid X)$ — a learner that does not fit cannot debias, and the DDML paper’s Table 5 documents a much sharper version of this pattern across twelve candidate learners. The cleanest way to sidestep the choice is short-stacking: regress $Y$ and $D$ on the cross-fitted predicted values of every candidate learner under non-negative weights summing to one. Table 6 of the paper reports stacked DDML at $\hat\theta_0 = -0.054$ (s.e. $0.020$); the stacking weights load almost entirely on the three XGBoost specifications, so when XGBoost dominates the linear alternatives — as it does here — stacking inherits its performance for free.

### 2.2 Cluster-respecting vs IID folds

<div id="tbl-folds">

Table 3: Baseline (recruiter-honest folds, cluster-robust SE) vs. IID folds with het-robust SE. Both columns are median-of-medians over S = 5 seeds; K = 3; XGB 3 nuisance learner.
<!-- preamble start -->
&#10;    <script src="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.js"></script>
&#10;    <script>
      // Create table-specific functions using external factory
      const tableFns_fuarcyrysf6dyshowohm = TinyTable.createTableFunctions("tinytable_fuarcyrysf6dyshowohm");
      // tinytable span after
      window.addEventListener('load', function () {
          var cellsToStyle = [
            // tinytable style arrays after
          { positions: [ { i: '5', j: 2 }, { i: '5', j: 3 } ], css_id: 'tinytable_css_rmrcb84sx2rl7nzpdf9p',}, 
          { positions: [ { i: '2', j: 2 }, { i: '2', j: 3 } ], css_id: 'tinytable_css_5oo2c54ixijd94muo6py',}, 
          { positions: [ { i: '1', j: 2 }, { i: '3', j: 2 }, { i: '4', j: 2 }, { i: '1', j: 3 }, { i: '3', j: 3 }, { i: '4', j: 3 } ], css_id: 'tinytable_css_uiuv5rma3s676ke0juud',}, 
          { positions: [ { i: '0', j: 2 }, { i: '0', j: 3 } ], css_id: 'tinytable_css_pr8sc5mgeinsm5zk5go8',}, 
          { positions: [ { i: '5', j: 1 } ], css_id: 'tinytable_css_3b9iwxh0o9ex73lgli1d',}, 
          { positions: [ { i: '2', j: 1 } ], css_id: 'tinytable_css_h1jz2vm1l0t5g7nz8zre',}, 
          { positions: [ { i: '1', j: 1 }, { i: '3', j: 1 }, { i: '4', j: 1 } ], css_id: 'tinytable_css_t31fdi9qdtogizwxrrzh',}, 
          { positions: [ { i: '0', j: 1 } ], css_id: 'tinytable_css_xym8gs0c59ag4unsfcco',}, 
          ];
&#10;          // Loop over the arrays to style the cells
          cellsToStyle.forEach(function (group) {
              group.positions.forEach(function (cell) {
                  tableFns_fuarcyrysf6dyshowohm.styleCell(cell.i, cell.j, group.css_id);
              });
          });
      });
    </script>
&#10;    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.css">
    <style>
    /* tinytable css entries after */
    #tinytable_fuarcyrysf6dyshowohm td.tinytable_css_rmrcb84sx2rl7nzpdf9p, #tinytable_fuarcyrysf6dyshowohm th.tinytable_css_rmrcb84sx2rl7nzpdf9p {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_fuarcyrysf6dyshowohm td.tinytable_css_5oo2c54ixijd94muo6py, #tinytable_fuarcyrysf6dyshowohm th.tinytable_css_5oo2c54ixijd94muo6py {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_fuarcyrysf6dyshowohm td.tinytable_css_uiuv5rma3s676ke0juud, #tinytable_fuarcyrysf6dyshowohm th.tinytable_css_uiuv5rma3s676ke0juud { text-align: center }
    #tinytable_fuarcyrysf6dyshowohm td.tinytable_css_pr8sc5mgeinsm5zk5go8, #tinytable_fuarcyrysf6dyshowohm th.tinytable_css_pr8sc5mgeinsm5zk5go8 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_fuarcyrysf6dyshowohm td.tinytable_css_3b9iwxh0o9ex73lgli1d, #tinytable_fuarcyrysf6dyshowohm th.tinytable_css_3b9iwxh0o9ex73lgli1d {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_fuarcyrysf6dyshowohm td.tinytable_css_h1jz2vm1l0t5g7nz8zre, #tinytable_fuarcyrysf6dyshowohm th.tinytable_css_h1jz2vm1l0t5g7nz8zre {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_fuarcyrysf6dyshowohm td.tinytable_css_t31fdi9qdtogizwxrrzh, #tinytable_fuarcyrysf6dyshowohm th.tinytable_css_t31fdi9qdtogizwxrrzh { text-align: left }
    #tinytable_fuarcyrysf6dyshowohm td.tinytable_css_xym8gs0c59ag4unsfcco, #tinytable_fuarcyrysf6dyshowohm th.tinytable_css_xym8gs0c59ag4unsfcco {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    </style>
    <div class="container">
      <table class="tinytable" id="tinytable_fuarcyrysf6dyshowohm" style="width: auto; margin-left: auto; margin-right: auto;" data-quarto-disable-processing='true'>
        &#10;        <thead>
              <tr>
                <th scope="col" data-row="0" data-col="1"> </th>
                <th scope="col" data-row="0" data-col="2">xclust (baseline)</th>
                <th scope="col" data-row="0" data-col="3">IID folds</th>
              </tr>
        </thead>
        &#10;        <tbody>
                <tr>
                  <td data-row="1" data-col="1">log(reward)</td>
                  <td data-row="1" data-col="2">−0.061</td>
                  <td data-row="1" data-col="3">−0.042</td>
                </tr>
                <tr>
                  <td data-row="2" data-col="1"></td>
                  <td data-row="2" data-col="2">(0.174)</td>
                  <td data-row="2" data-col="3">(0.004)</td>
                </tr>
                <tr>
                  <td data-row="3" data-col="1">n</td>
                  <td data-row="3" data-col="2">258352</td>
                  <td data-row="3" data-col="3">258352</td>
                </tr>
                <tr>
                  <td data-row="4" data-col="1">R²(Y|X)</td>
                  <td data-row="4" data-col="2">0.862</td>
                  <td data-row="4" data-col="3">0.892</td>
                </tr>
                <tr>
                  <td data-row="5" data-col="1">R²(D|X)</td>
                  <td data-row="5" data-col="2">0.744</td>
                  <td data-row="5" data-col="3">0.878</td>
                </tr>
        </tbody>
      </table>
    </div>
<!-- hack to avoid NA insertion in last line -->

</div>

This is the sweep where leaving the default behind is the point. The Ipeirotis cross-section has many postings per recruiter, and the same recruiter’s HITs share unobserved features (recruiter style, payout norms, qualification preferences) that correlate with both posted reward and fill time. Splitting at the observation level lets siblings from the same recruiter sit on both sides of the fold boundary — making the residuals look more independent than they are, and the cross-fitted $R^2$ look better than the true generalisation $R^2$. In `ddml_plm` the lever is whether `cluster_variable` is supplied; passing the recruiter id forms recruiter-honest folds and clusters SEs at the same level; omitting it gives random IID folds and uses heteroskedasticity-robust SEs:

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

The cross-fitted $R^2$ values typically *fall* when fold construction moves from IID to recruiter-honest, because the held-out fold now contains recruiters the nuisance learner never saw — that is the honest predictive performance and it is what should enter the DDML score. The standard error typically *rises*, because clustering at the recruiter level accounts for the correlated residuals that het-robust ignores. The cluster-honest combination is the inference-bearing one for this application, which is why Entries 1–2 and the baseline of this post use it as their default.

### 2.3 Number of folds $K$

<div id="tbl-K">

Table 4: Baseline K = 3 vs. K = 5. Both columns are median-of-medians over S = 5 seeds; XGB 3 nuisance learner; recruiter-honest folds; cluster-robust SE.
<!-- preamble start -->
&#10;    <script src="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.js"></script>
&#10;    <script>
      // Create table-specific functions using external factory
      const tableFns_i5ei7d2lvuiso3ni5i8f = TinyTable.createTableFunctions("tinytable_i5ei7d2lvuiso3ni5i8f");
      // tinytable span after
      window.addEventListener('load', function () {
          var cellsToStyle = [
            // tinytable style arrays after
          { positions: [ { i: '5', j: 2 }, { i: '5', j: 3 } ], css_id: 'tinytable_css_hbhkrwao2adjw3h4doqq',}, 
          { positions: [ { i: '2', j: 2 }, { i: '2', j: 3 } ], css_id: 'tinytable_css_txagbnir35t0z81mdhyu',}, 
          { positions: [ { i: '1', j: 2 }, { i: '3', j: 2 }, { i: '4', j: 2 }, { i: '1', j: 3 }, { i: '3', j: 3 }, { i: '4', j: 3 } ], css_id: 'tinytable_css_22haf9oeagxntfxp7680',}, 
          { positions: [ { i: '0', j: 2 }, { i: '0', j: 3 } ], css_id: 'tinytable_css_zimx553826e5s1i1d8uu',}, 
          { positions: [ { i: '5', j: 1 } ], css_id: 'tinytable_css_x2tx115egprgw9mkrqql',}, 
          { positions: [ { i: '2', j: 1 } ], css_id: 'tinytable_css_8z7ordm200gft74k2p9c',}, 
          { positions: [ { i: '1', j: 1 }, { i: '3', j: 1 }, { i: '4', j: 1 } ], css_id: 'tinytable_css_l3z4ka79m50c3xrj3x04',}, 
          { positions: [ { i: '0', j: 1 } ], css_id: 'tinytable_css_l9mx4hqh4ykbpnrbhp7i',}, 
          ];
&#10;          // Loop over the arrays to style the cells
          cellsToStyle.forEach(function (group) {
              group.positions.forEach(function (cell) {
                  tableFns_i5ei7d2lvuiso3ni5i8f.styleCell(cell.i, cell.j, group.css_id);
              });
          });
      });
    </script>
&#10;    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.css">
    <style>
    /* tinytable css entries after */
    #tinytable_i5ei7d2lvuiso3ni5i8f td.tinytable_css_hbhkrwao2adjw3h4doqq, #tinytable_i5ei7d2lvuiso3ni5i8f th.tinytable_css_hbhkrwao2adjw3h4doqq {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_i5ei7d2lvuiso3ni5i8f td.tinytable_css_txagbnir35t0z81mdhyu, #tinytable_i5ei7d2lvuiso3ni5i8f th.tinytable_css_txagbnir35t0z81mdhyu {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_i5ei7d2lvuiso3ni5i8f td.tinytable_css_22haf9oeagxntfxp7680, #tinytable_i5ei7d2lvuiso3ni5i8f th.tinytable_css_22haf9oeagxntfxp7680 { text-align: center }
    #tinytable_i5ei7d2lvuiso3ni5i8f td.tinytable_css_zimx553826e5s1i1d8uu, #tinytable_i5ei7d2lvuiso3ni5i8f th.tinytable_css_zimx553826e5s1i1d8uu {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_i5ei7d2lvuiso3ni5i8f td.tinytable_css_x2tx115egprgw9mkrqql, #tinytable_i5ei7d2lvuiso3ni5i8f th.tinytable_css_x2tx115egprgw9mkrqql {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_i5ei7d2lvuiso3ni5i8f td.tinytable_css_8z7ordm200gft74k2p9c, #tinytable_i5ei7d2lvuiso3ni5i8f th.tinytable_css_8z7ordm200gft74k2p9c {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_i5ei7d2lvuiso3ni5i8f td.tinytable_css_l3z4ka79m50c3xrj3x04, #tinytable_i5ei7d2lvuiso3ni5i8f th.tinytable_css_l3z4ka79m50c3xrj3x04 { text-align: left }
    #tinytable_i5ei7d2lvuiso3ni5i8f td.tinytable_css_l9mx4hqh4ykbpnrbhp7i, #tinytable_i5ei7d2lvuiso3ni5i8f th.tinytable_css_l9mx4hqh4ykbpnrbhp7i {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    </style>
    <div class="container">
      <table class="tinytable" id="tinytable_i5ei7d2lvuiso3ni5i8f" style="width: auto; margin-left: auto; margin-right: auto;" data-quarto-disable-processing='true'>
        &#10;        <thead>
              <tr>
                <th scope="col" data-row="0" data-col="1"> </th>
                <th scope="col" data-row="0" data-col="2">K = 3 (baseline)</th>
                <th scope="col" data-row="0" data-col="3">K = 5</th>
              </tr>
        </thead>
        &#10;        <tbody>
                <tr>
                  <td data-row="1" data-col="1">log(reward)</td>
                  <td data-row="1" data-col="2">−0.061</td>
                  <td data-row="1" data-col="3">−0.050</td>
                </tr>
                <tr>
                  <td data-row="2" data-col="1"></td>
                  <td data-row="2" data-col="2">(0.174)</td>
                  <td data-row="2" data-col="3">(0.243)</td>
                </tr>
                <tr>
                  <td data-row="3" data-col="1">n</td>
                  <td data-row="3" data-col="2">258352</td>
                  <td data-row="3" data-col="3">258352</td>
                </tr>
                <tr>
                  <td data-row="4" data-col="1">R²(Y|X)</td>
                  <td data-row="4" data-col="2">0.862</td>
                  <td data-row="4" data-col="3">0.864</td>
                </tr>
                <tr>
                  <td data-row="5" data-col="1">R²(D|X)</td>
                  <td data-row="5" data-col="2">0.744</td>
                  <td data-row="5" data-col="3">0.741</td>
                </tr>
        </tbody>
      </table>
    </div>
<!-- hack to avoid NA insertion in last line -->

</div>

Cross-fitting theory accommodates any fixed $K$. Velez (2024) shows performance improves with more folds, peaking at $K = n$ with diminishing returns. In the paper we recommend the largest $K$ consistent with available compute, plus a sensitivity check. Moving from $K = 3$ to $K = 5$ trains each nuisance fit on $4/5$ of the data instead of $2/3$ and compute scales roughly linearly. With $n \approx 258{,}000$ either value is in the range where the bias–variance tradeoff is favourable.

## 3. What to take away

- A single ML learner is not a complete DDML specification. The point estimate is informative only when the nuisance learner can actually predict — cross-fitted $R^2$ is the diagnostic to lean on.
- Short-stacking (or, more conservatively, reporting both stacking and single-best) sidesteps the learner-selection problem and is cheap relative to refitting four nuisance models from scratch.
- Median-of-medians over $S \ge 3$ seeds is the inference-bearing point estimate; one-seed numbers are fine for iteration but should not be the published number.
- Cluster vs IID fold construction is the design decision with the largest swing in SE and the most consequential one for inference. The blog defaults to recruiter-honest folds + cluster-robust SEs; the IID variant is included only as a contrast.
- $K$ matters less than the other knobs in this application.

## References

- Ahrens, A., V. Chernozhukov, C. Hansen, D. Kozbur, M. Schaffer and T. Wiemann. *An Introduction to Double/Debiased Machine Learning.* §5 (median aggregation), §6 (Dube application, Tables 5–6), §7 (implementation guidance).
- Ahrens, A., C. B. Hansen, M. E. Schaffer and T. Wiemann (2024). [`ddml`: Double/debiased machine learning in R.](https://doi.org/10.18637/jss.v108.i03)
- Chernozhukov, V., D. Chetverikov, M. Demirer, E. Duflo, C. Hansen, W. Newey and J. Robins (2018). [Double/Debiased machine learning for treatment and structural parameters.](https://doi.org/10.1111/ectj.12097)
- Dube, A., J. Jacobs, S. Naidu and S. Suri (2020). [Monopsony in online labor markets.](https://doi.org/10.3386/w26108) *AER: Insights* 2 (1).
- Lei, J. (2020). Cross-validation with confidence. *Journal of the American Statistical Association.*
- Velez, A. (2024). On the asymptotic properties of debiased machine learning estimators.
