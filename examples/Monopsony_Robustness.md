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
<!-- preamble start -->
&#10;    <script src="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.js"></script>
&#10;    <script>
      // Create table-specific functions using external factory
      const tableFns_txrvxurl1v9katu6xpuv = TinyTable.createTableFunctions("tinytable_txrvxurl1v9katu6xpuv");
      // tinytable span after
      window.addEventListener('load', function () {
          var cellsToStyle = [
            // tinytable style arrays after
          { positions: [ { i: '9', j: 2 }, { i: '9', j: 3 }, { i: '9', j: 4 }, { i: '9', j: 5 }, { i: '9', j: 6 }, { i: '9', j: 7 } ], css_id: 'tinytable_css_7tjmp1zixy260te4qv37',}, 
          { positions: [ { i: '2', j: 2 }, { i: '2', j: 3 }, { i: '2', j: 4 }, { i: '2', j: 5 }, { i: '2', j: 6 }, { i: '2', j: 7 } ], css_id: 'tinytable_css_j64q84apalsxeeo3zr03',}, 
          { positions: [ { i: '1', j: 2 }, { i: '3', j: 2 }, { i: '4', j: 2 }, { i: '5', j: 2 }, { i: '6', j: 2 }, { i: '7', j: 2 }, { i: '8', j: 2 }, { i: '1', j: 3 }, { i: '3', j: 3 }, { i: '4', j: 3 }, { i: '5', j: 3 }, { i: '6', j: 3 }, { i: '7', j: 3 }, { i: '8', j: 3 }, { i: '1', j: 4 }, { i: '3', j: 4 }, { i: '4', j: 4 }, { i: '5', j: 4 }, { i: '6', j: 4 }, { i: '7', j: 4 }, { i: '8', j: 4 }, { i: '1', j: 5 }, { i: '3', j: 5 }, { i: '4', j: 5 }, { i: '5', j: 5 }, { i: '6', j: 5 }, { i: '7', j: 5 }, { i: '8', j: 5 }, { i: '1', j: 6 }, { i: '3', j: 6 }, { i: '4', j: 6 }, { i: '5', j: 6 }, { i: '6', j: 6 }, { i: '7', j: 6 }, { i: '8', j: 6 }, { i: '1', j: 7 }, { i: '3', j: 7 }, { i: '4', j: 7 }, { i: '5', j: 7 }, { i: '6', j: 7 }, { i: '7', j: 7 }, { i: '8', j: 7 } ], css_id: 'tinytable_css_sr9ay305ysdtpdsby283',}, 
          { positions: [ { i: '0', j: 2 }, { i: '0', j: 3 }, { i: '0', j: 4 }, { i: '0', j: 5 }, { i: '0', j: 6 }, { i: '0', j: 7 } ], css_id: 'tinytable_css_rt4b0tdqv5eygalsx21w',}, 
          { positions: [ { i: '9', j: 1 } ], css_id: 'tinytable_css_qibmfy91gfysbxt7yhuv',}, 
          { positions: [ { i: '2', j: 1 } ], css_id: 'tinytable_css_8dgo1zfe51acrm1f3gzw',}, 
          { positions: [ { i: '1', j: 1 }, { i: '3', j: 1 }, { i: '4', j: 1 }, { i: '5', j: 1 }, { i: '6', j: 1 }, { i: '7', j: 1 }, { i: '8', j: 1 } ], css_id: 'tinytable_css_2fcyiqi722hka704fl3z',}, 
          { positions: [ { i: '0', j: 1 } ], css_id: 'tinytable_css_4t1lin3mvashdx9kmikh',}, 
          ];
&#10;          // Loop over the arrays to style the cells
          cellsToStyle.forEach(function (group) {
              group.positions.forEach(function (cell) {
                  tableFns_txrvxurl1v9katu6xpuv.styleCell(cell.i, cell.j, group.css_id);
              });
          });
      });
    </script>
&#10;    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.css">
    <style>
    /* tinytable css entries after */
    #tinytable_txrvxurl1v9katu6xpuv td.tinytable_css_7tjmp1zixy260te4qv37, #tinytable_txrvxurl1v9katu6xpuv th.tinytable_css_7tjmp1zixy260te4qv37 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_txrvxurl1v9katu6xpuv td.tinytable_css_j64q84apalsxeeo3zr03, #tinytable_txrvxurl1v9katu6xpuv th.tinytable_css_j64q84apalsxeeo3zr03 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_txrvxurl1v9katu6xpuv td.tinytable_css_sr9ay305ysdtpdsby283, #tinytable_txrvxurl1v9katu6xpuv th.tinytable_css_sr9ay305ysdtpdsby283 { text-align: center }
    #tinytable_txrvxurl1v9katu6xpuv td.tinytable_css_rt4b0tdqv5eygalsx21w, #tinytable_txrvxurl1v9katu6xpuv th.tinytable_css_rt4b0tdqv5eygalsx21w {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_txrvxurl1v9katu6xpuv td.tinytable_css_qibmfy91gfysbxt7yhuv, #tinytable_txrvxurl1v9katu6xpuv th.tinytable_css_qibmfy91gfysbxt7yhuv {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_txrvxurl1v9katu6xpuv td.tinytable_css_8dgo1zfe51acrm1f3gzw, #tinytable_txrvxurl1v9katu6xpuv th.tinytable_css_8dgo1zfe51acrm1f3gzw {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_txrvxurl1v9katu6xpuv td.tinytable_css_2fcyiqi722hka704fl3z, #tinytable_txrvxurl1v9katu6xpuv th.tinytable_css_2fcyiqi722hka704fl3z { text-align: left }
    #tinytable_txrvxurl1v9katu6xpuv td.tinytable_css_4t1lin3mvashdx9kmikh, #tinytable_txrvxurl1v9katu6xpuv th.tinytable_css_4t1lin3mvashdx9kmikh {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    </style>
    <div class="container">
      <table class="tinytable" id="tinytable_txrvxurl1v9katu6xpuv" style="width: auto; margin-left: auto; margin-right: auto;" data-quarto-disable-processing='true'>
        &#10;        <thead>
              <tr>
                <th scope="col" data-row="0" data-col="1"> </th>
                <th scope="col" data-row="0" data-col="2">seed=12487</th>
                <th scope="col" data-row="0" data-col="3">seed=17929</th>
                <th scope="col" data-row="0" data-col="4">seed=28327</th>
                <th scope="col" data-row="0" data-col="5">seed=63595</th>
                <th scope="col" data-row="0" data-col="6">seed=85886</th>
                <th scope="col" data-row="0" data-col="7">median agg. (S=5)</th>
              </tr>
        </thead>
        &#10;        <tbody>
                <tr>
                  <td data-row="1" data-col="1">theta (resid_Y ~ resid_D)</td>
                  <td data-row="1" data-col="2">−0.033</td>
                  <td data-row="1" data-col="3">−0.037</td>
                  <td data-row="1" data-col="4">−0.073</td>
                  <td data-row="1" data-col="5">−0.065</td>
                  <td data-row="1" data-col="6">−0.061</td>
                  <td data-row="1" data-col="7">−0.061</td>
                </tr>
                <tr>
                  <td data-row="2" data-col="1"></td>
                  <td data-row="2" data-col="2">(0.013)</td>
                  <td data-row="2" data-col="3">(0.017)</td>
                  <td data-row="2" data-col="4">(0.022)</td>
                  <td data-row="2" data-col="5">(0.030)</td>
                  <td data-row="2" data-col="6">(0.014)</td>
                  <td data-row="2" data-col="7">(0.029)</td>
                </tr>
                <tr>
                  <td data-row="3" data-col="1">N</td>
                  <td data-row="3" data-col="2">258352</td>
                  <td data-row="3" data-col="3">258352</td>
                  <td data-row="3" data-col="4">258352</td>
                  <td data-row="3" data-col="5">258352</td>
                  <td data-row="3" data-col="6">258352</td>
                  <td data-row="3" data-col="7">258352</td>
                </tr>
                <tr>
                  <td data-row="4" data-col="1">S (replications)</td>
                  <td data-row="4" data-col="2"></td>
                  <td data-row="4" data-col="3"></td>
                  <td data-row="4" data-col="4"></td>
                  <td data-row="4" data-col="5"></td>
                  <td data-row="4" data-col="6"></td>
                  <td data-row="4" data-col="7">5</td>
                </tr>
                <tr>
                  <td data-row="5" data-col="1">R^2 outcome eq.</td>
                  <td data-row="5" data-col="2">0.867</td>
                  <td data-row="5" data-col="3">0.862</td>
                  <td data-row="5" data-col="4">0.864</td>
                  <td data-row="5" data-col="5">0.856</td>
                  <td data-row="5" data-col="6">0.861</td>
                  <td data-row="5" data-col="7">0.862</td>
                </tr>
                <tr>
                  <td data-row="6" data-col="1">R^2 treatment eq.</td>
                  <td data-row="6" data-col="2">0.750</td>
                  <td data-row="6" data-col="3">0.720</td>
                  <td data-row="6" data-col="4">0.746</td>
                  <td data-row="6" data-col="5">0.744</td>
                  <td data-row="6" data-col="6">0.756</td>
                  <td data-row="6" data-col="7">0.743</td>
                </tr>
                <tr>
                  <td data-row="7" data-col="1">K</td>
                  <td data-row="7" data-col="2">3</td>
                  <td data-row="7" data-col="3">3</td>
                  <td data-row="7" data-col="4">3</td>
                  <td data-row="7" data-col="5">3</td>
                  <td data-row="7" data-col="6">3</td>
                  <td data-row="7" data-col="7"></td>
                </tr>
                <tr>
                  <td data-row="8" data-col="1">Learner</td>
                  <td data-row="8" data-col="2">9</td>
                  <td data-row="8" data-col="3">9</td>
                  <td data-row="8" data-col="4">9</td>
                  <td data-row="8" data-col="5">9</td>
                  <td data-row="8" data-col="6">9</td>
                  <td data-row="8" data-col="7"></td>
                </tr>
                <tr>
                  <td data-row="9" data-col="1">Fold seed</td>
                  <td data-row="9" data-col="2">12487</td>
                  <td data-row="9" data-col="3">17929</td>
                  <td data-row="9" data-col="4">28327</td>
                  <td data-row="9" data-col="5">63595</td>
                  <td data-row="9" data-col="6">85886</td>
                  <td data-row="9" data-col="7"></td>
                </tr>
        </tbody>
      </table>
    </div>
<!-- hack to avoid NA insertion in last line -->

</div>

To avoid unnecessary reliance on a single draw, **we recommend repeating the cross-fitting multiple times and reporting the median- (or mean-) aggregated estimate**. The median-aggregate estimate can be calculated as:

$$\hat\theta_0^{\text{median}} = \mathrm{median}\bigl\{\hat\theta_{0,s}\bigr\}_{s=1}^{S},\qquad
\widehat{\mathrm{s.e.}}^{\text{median}} \;=\; \sqrt{\mathrm{median}\bigl\{\widehat{\mathrm{s.e.}}_s^{\,2} + (\hat\theta_{0,s} - \hat\theta_0^{\text{median}})^2\bigr\}_{s=1}^{S}}.$$

The rationale for reporting an aggregated estimate (shown above in the last column) is that it provides an intuitive summary of DML estimates that is less susceptible to particular random draws.

### Fold-clustering by recruiter or by observation

In the Ipeirotis data, some recruiters have many postings. The same recruiter’s postings may share unobserved features that correlate with both posted reward and duration until acceptance.

The table below investigates the impact of random fold construction by recruiter versus by observation on the DML estimate and its standard error:

<div id="tbl-S2-folds">

Table 2: Table S.2 replica. Recruiter-honest folds with cluster-robust SE vs. IID folds. Both columns are median-of-medians over S = 5 seeds; K = 3; XGB 3 nuisance learner.
<!-- preamble start -->
&#10;    <script src="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.js"></script>
&#10;    <script>
      // Create table-specific functions using external factory
      const tableFns_98dtexcv9wd7ltiis3e6 = TinyTable.createTableFunctions("tinytable_98dtexcv9wd7ltiis3e6");
      // tinytable span after
      window.addEventListener('load', function () {
          var cellsToStyle = [
            // tinytable style arrays after
          { positions: [ { i: '6', j: 2 }, { i: '6', j: 3 } ], css_id: 'tinytable_css_0az13uwp7o4r7aspehta',}, 
          { positions: [ { i: '2', j: 2 }, { i: '2', j: 3 } ], css_id: 'tinytable_css_aheh94qwq1dc4j64cusv',}, 
          { positions: [ { i: '1', j: 2 }, { i: '3', j: 2 }, { i: '4', j: 2 }, { i: '5', j: 2 }, { i: '1', j: 3 }, { i: '3', j: 3 }, { i: '4', j: 3 }, { i: '5', j: 3 } ], css_id: 'tinytable_css_khyb1untppkjdttu8esj',}, 
          { positions: [ { i: '0', j: 2 }, { i: '0', j: 3 } ], css_id: 'tinytable_css_j8t12au19bdbh1zvdrhd',}, 
          { positions: [ { i: '6', j: 1 } ], css_id: 'tinytable_css_d98j5b82745jsydda09w',}, 
          { positions: [ { i: '2', j: 1 } ], css_id: 'tinytable_css_grwe3p1l8nu9gril2hyz',}, 
          { positions: [ { i: '1', j: 1 }, { i: '3', j: 1 }, { i: '4', j: 1 }, { i: '5', j: 1 } ], css_id: 'tinytable_css_ucgjhr2r24stmq889idl',}, 
          { positions: [ { i: '0', j: 1 } ], css_id: 'tinytable_css_0g04mgj7pwvhnzdsavs6',}, 
          ];
&#10;          // Loop over the arrays to style the cells
          cellsToStyle.forEach(function (group) {
              group.positions.forEach(function (cell) {
                  tableFns_98dtexcv9wd7ltiis3e6.styleCell(cell.i, cell.j, group.css_id);
              });
          });
      });
    </script>
&#10;    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.css">
    <style>
    /* tinytable css entries after */
    #tinytable_98dtexcv9wd7ltiis3e6 td.tinytable_css_0az13uwp7o4r7aspehta, #tinytable_98dtexcv9wd7ltiis3e6 th.tinytable_css_0az13uwp7o4r7aspehta {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_98dtexcv9wd7ltiis3e6 td.tinytable_css_aheh94qwq1dc4j64cusv, #tinytable_98dtexcv9wd7ltiis3e6 th.tinytable_css_aheh94qwq1dc4j64cusv {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_98dtexcv9wd7ltiis3e6 td.tinytable_css_khyb1untppkjdttu8esj, #tinytable_98dtexcv9wd7ltiis3e6 th.tinytable_css_khyb1untppkjdttu8esj { text-align: center }
    #tinytable_98dtexcv9wd7ltiis3e6 td.tinytable_css_j8t12au19bdbh1zvdrhd, #tinytable_98dtexcv9wd7ltiis3e6 th.tinytable_css_j8t12au19bdbh1zvdrhd {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_98dtexcv9wd7ltiis3e6 td.tinytable_css_d98j5b82745jsydda09w, #tinytable_98dtexcv9wd7ltiis3e6 th.tinytable_css_d98j5b82745jsydda09w {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_98dtexcv9wd7ltiis3e6 td.tinytable_css_grwe3p1l8nu9gril2hyz, #tinytable_98dtexcv9wd7ltiis3e6 th.tinytable_css_grwe3p1l8nu9gril2hyz {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_98dtexcv9wd7ltiis3e6 td.tinytable_css_ucgjhr2r24stmq889idl, #tinytable_98dtexcv9wd7ltiis3e6 th.tinytable_css_ucgjhr2r24stmq889idl { text-align: left }
    #tinytable_98dtexcv9wd7ltiis3e6 td.tinytable_css_0g04mgj7pwvhnzdsavs6, #tinytable_98dtexcv9wd7ltiis3e6 th.tinytable_css_0g04mgj7pwvhnzdsavs6 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    </style>
    <div class="container">
      <table class="tinytable" id="tinytable_98dtexcv9wd7ltiis3e6" style="width: auto; margin-left: auto; margin-right: auto;" data-quarto-disable-processing='true'>
        &#10;        <thead>
              <tr>
                <th scope="col" data-row="0" data-col="1"> </th>
                <th scope="col" data-row="0" data-col="2">xclust (baseline)</th>
                <th scope="col" data-row="0" data-col="3">IID folds</th>
              </tr>
        </thead>
        &#10;        <tbody>
                <tr>
                  <td data-row="1" data-col="1">theta (resid_Y ~ resid_D)</td>
                  <td data-row="1" data-col="2">−0.061</td>
                  <td data-row="1" data-col="3">−0.042</td>
                </tr>
                <tr>
                  <td data-row="2" data-col="1"></td>
                  <td data-row="2" data-col="2">(0.029)</td>
                  <td data-row="2" data-col="3">(0.006)</td>
                </tr>
                <tr>
                  <td data-row="3" data-col="1">N</td>
                  <td data-row="3" data-col="2">258352</td>
                  <td data-row="3" data-col="3">258352</td>
                </tr>
                <tr>
                  <td data-row="4" data-col="1">S (replications)</td>
                  <td data-row="4" data-col="2">5</td>
                  <td data-row="4" data-col="3">5</td>
                </tr>
                <tr>
                  <td data-row="5" data-col="1">R^2 outcome eq.</td>
                  <td data-row="5" data-col="2">0.862</td>
                  <td data-row="5" data-col="3">0.892</td>
                </tr>
                <tr>
                  <td data-row="6" data-col="1">R^2 treatment eq.</td>
                  <td data-row="6" data-col="2">0.743</td>
                  <td data-row="6" data-col="3">0.877</td>
                </tr>
        </tbody>
      </table>
    </div>
<!-- hack to avoid NA insertion in last line -->

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

Cross-fitting theory accommodates any fixed number of cross-fitting folds $K$, but in practice results may vary depending on the choice of $K$, especially when the sample size is small. In the paper, **we recommend the largest $K$ consistent with available computing resources, plus a sensitivity check**.

The table below compares the baseline $K = 3$ specification against $K = 5$, both median-aggregated over $S = 5$ seeds using the same recruiter-honest fold structure:

<div id="tbl-S3-K">

Table 3: Table S.3 replica. K = 3 vs. K = 5. Both columns are median-of-medians over S = 5 seeds; XGB 3 nuisance learner; recruiter-honest folds; cluster-robust SE.
<!-- preamble start -->
&#10;    <script src="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.js"></script>
&#10;    <script>
      // Create table-specific functions using external factory
      const tableFns_fge1weys11aqmo2k8gvn = TinyTable.createTableFunctions("tinytable_fge1weys11aqmo2k8gvn");
      // tinytable span after
      window.addEventListener('load', function () {
          var cellsToStyle = [
            // tinytable style arrays after
          { positions: [ { i: '6', j: 2 }, { i: '6', j: 3 } ], css_id: 'tinytable_css_7abofc40rcxrf0w4ku96',}, 
          { positions: [ { i: '2', j: 2 }, { i: '2', j: 3 } ], css_id: 'tinytable_css_sinkr1dboptj5dqkgrsb',}, 
          { positions: [ { i: '1', j: 2 }, { i: '3', j: 2 }, { i: '4', j: 2 }, { i: '5', j: 2 }, { i: '1', j: 3 }, { i: '3', j: 3 }, { i: '4', j: 3 }, { i: '5', j: 3 } ], css_id: 'tinytable_css_4ex7scisiz3644jukv1k',}, 
          { positions: [ { i: '0', j: 2 }, { i: '0', j: 3 } ], css_id: 'tinytable_css_nmm2v8qe3tmnoojlx3sz',}, 
          { positions: [ { i: '6', j: 1 } ], css_id: 'tinytable_css_uf45q73x64x50zbtywwa',}, 
          { positions: [ { i: '2', j: 1 } ], css_id: 'tinytable_css_nwisscegk61dv5nqyl5o',}, 
          { positions: [ { i: '1', j: 1 }, { i: '3', j: 1 }, { i: '4', j: 1 }, { i: '5', j: 1 } ], css_id: 'tinytable_css_or4kf1c5kdwxraukfvk7',}, 
          { positions: [ { i: '0', j: 1 } ], css_id: 'tinytable_css_m55l3u2rw6gjxjxv7j2g',}, 
          ];
&#10;          // Loop over the arrays to style the cells
          cellsToStyle.forEach(function (group) {
              group.positions.forEach(function (cell) {
                  tableFns_fge1weys11aqmo2k8gvn.styleCell(cell.i, cell.j, group.css_id);
              });
          });
      });
    </script>
&#10;    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.css">
    <style>
    /* tinytable css entries after */
    #tinytable_fge1weys11aqmo2k8gvn td.tinytable_css_7abofc40rcxrf0w4ku96, #tinytable_fge1weys11aqmo2k8gvn th.tinytable_css_7abofc40rcxrf0w4ku96 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_fge1weys11aqmo2k8gvn td.tinytable_css_sinkr1dboptj5dqkgrsb, #tinytable_fge1weys11aqmo2k8gvn th.tinytable_css_sinkr1dboptj5dqkgrsb {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_fge1weys11aqmo2k8gvn td.tinytable_css_4ex7scisiz3644jukv1k, #tinytable_fge1weys11aqmo2k8gvn th.tinytable_css_4ex7scisiz3644jukv1k { text-align: center }
    #tinytable_fge1weys11aqmo2k8gvn td.tinytable_css_nmm2v8qe3tmnoojlx3sz, #tinytable_fge1weys11aqmo2k8gvn th.tinytable_css_nmm2v8qe3tmnoojlx3sz {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_fge1weys11aqmo2k8gvn td.tinytable_css_uf45q73x64x50zbtywwa, #tinytable_fge1weys11aqmo2k8gvn th.tinytable_css_uf45q73x64x50zbtywwa {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_fge1weys11aqmo2k8gvn td.tinytable_css_nwisscegk61dv5nqyl5o, #tinytable_fge1weys11aqmo2k8gvn th.tinytable_css_nwisscegk61dv5nqyl5o {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_fge1weys11aqmo2k8gvn td.tinytable_css_or4kf1c5kdwxraukfvk7, #tinytable_fge1weys11aqmo2k8gvn th.tinytable_css_or4kf1c5kdwxraukfvk7 { text-align: left }
    #tinytable_fge1weys11aqmo2k8gvn td.tinytable_css_m55l3u2rw6gjxjxv7j2g, #tinytable_fge1weys11aqmo2k8gvn th.tinytable_css_m55l3u2rw6gjxjxv7j2g {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    </style>
    <div class="container">
      <table class="tinytable" id="tinytable_fge1weys11aqmo2k8gvn" style="width: auto; margin-left: auto; margin-right: auto;" data-quarto-disable-processing='true'>
        &#10;        <thead>
              <tr>
                <th scope="col" data-row="0" data-col="1"> </th>
                <th scope="col" data-row="0" data-col="2">K = 3 (baseline)</th>
                <th scope="col" data-row="0" data-col="3">K = 5</th>
              </tr>
        </thead>
        &#10;        <tbody>
                <tr>
                  <td data-row="1" data-col="1">theta (resid_Y ~ resid_D)</td>
                  <td data-row="1" data-col="2">−0.061</td>
                  <td data-row="1" data-col="3">−0.050</td>
                </tr>
                <tr>
                  <td data-row="2" data-col="1"></td>
                  <td data-row="2" data-col="2">(0.029)</td>
                  <td data-row="2" data-col="3">(0.029)</td>
                </tr>
                <tr>
                  <td data-row="3" data-col="1">N</td>
                  <td data-row="3" data-col="2">258352</td>
                  <td data-row="3" data-col="3">258352</td>
                </tr>
                <tr>
                  <td data-row="4" data-col="1">S (replications)</td>
                  <td data-row="4" data-col="2">5</td>
                  <td data-row="4" data-col="3">5</td>
                </tr>
                <tr>
                  <td data-row="5" data-col="1">R^2 outcome eq.</td>
                  <td data-row="5" data-col="2">0.862</td>
                  <td data-row="5" data-col="3">0.863</td>
                </tr>
                <tr>
                  <td data-row="6" data-col="1">R^2 treatment eq.</td>
                  <td data-row="6" data-col="2">0.743</td>
                  <td data-row="6" data-col="3">0.739</td>
                </tr>
        </tbody>
      </table>
    </div>
<!-- hack to avoid NA insertion in last line -->

</div>

We find the results to be fairly robust to the choice of $K$, with the $K=5$ specification yielding a slightly smaller point estimate in magnitude.

## The choice of learner: XGBoost vs CV-Lasso

So far, we have exclusively relied on a particular XGBoost learner for illustration.

The choice of nuisance function estimator is consequential for DML estimation. Poorly chosen or poorly tuned learners can yield misleading DML point estimates because the residual-on-residual regression then absorbs leftover signal that should have been partialed out. As an example, below we compare the baseline `XGB 3` specification against `CV-Lasso` (learner index 2), both median-aggregated over $S = 5$ seeds using the same recruiter-honest fold structure:

<div id="tbl-xgb-vs-lasso">

Table 4: XGB 3 vs. CV-Lasso, both median-aggregated over S = 5 seeds. K = 3 recruiter-honest folds; cluster-robust SE.
<!-- preamble start -->
&#10;    <script src="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.js"></script>
&#10;    <script>
      // Create table-specific functions using external factory
      const tableFns_cdh1owzbsflby6z1asct = TinyTable.createTableFunctions("tinytable_cdh1owzbsflby6z1asct");
      // tinytable span after
      window.addEventListener('load', function () {
          var cellsToStyle = [
            // tinytable style arrays after
          { positions: [ { i: '6', j: 2 }, { i: '6', j: 3 } ], css_id: 'tinytable_css_rnfg00p5yesb3gylve8d',}, 
          { positions: [ { i: '2', j: 2 }, { i: '2', j: 3 } ], css_id: 'tinytable_css_knfc6ix8hl28ryymc174',}, 
          { positions: [ { i: '1', j: 2 }, { i: '3', j: 2 }, { i: '4', j: 2 }, { i: '5', j: 2 }, { i: '1', j: 3 }, { i: '3', j: 3 }, { i: '4', j: 3 }, { i: '5', j: 3 } ], css_id: 'tinytable_css_ed8ceoq6hs37md5cz7b8',}, 
          { positions: [ { i: '0', j: 2 }, { i: '0', j: 3 } ], css_id: 'tinytable_css_kbilguf5colu4ngn87a5',}, 
          { positions: [ { i: '6', j: 1 } ], css_id: 'tinytable_css_awwqe9cumijwc89lu64v',}, 
          { positions: [ { i: '2', j: 1 } ], css_id: 'tinytable_css_mzi0ilzisjk0qr9w6k07',}, 
          { positions: [ { i: '1', j: 1 }, { i: '3', j: 1 }, { i: '4', j: 1 }, { i: '5', j: 1 } ], css_id: 'tinytable_css_6x8ncht5jk1pqpzdqe2r',}, 
          { positions: [ { i: '0', j: 1 } ], css_id: 'tinytable_css_5hqnyddyz2mgjmbh8m3w',}, 
          ];
&#10;          // Loop over the arrays to style the cells
          cellsToStyle.forEach(function (group) {
              group.positions.forEach(function (cell) {
                  tableFns_cdh1owzbsflby6z1asct.styleCell(cell.i, cell.j, group.css_id);
              });
          });
      });
    </script>
&#10;    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.css">
    <style>
    /* tinytable css entries after */
    #tinytable_cdh1owzbsflby6z1asct td.tinytable_css_rnfg00p5yesb3gylve8d, #tinytable_cdh1owzbsflby6z1asct th.tinytable_css_rnfg00p5yesb3gylve8d {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_cdh1owzbsflby6z1asct td.tinytable_css_knfc6ix8hl28ryymc174, #tinytable_cdh1owzbsflby6z1asct th.tinytable_css_knfc6ix8hl28ryymc174 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_cdh1owzbsflby6z1asct td.tinytable_css_ed8ceoq6hs37md5cz7b8, #tinytable_cdh1owzbsflby6z1asct th.tinytable_css_ed8ceoq6hs37md5cz7b8 { text-align: center }
    #tinytable_cdh1owzbsflby6z1asct td.tinytable_css_kbilguf5colu4ngn87a5, #tinytable_cdh1owzbsflby6z1asct th.tinytable_css_kbilguf5colu4ngn87a5 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_cdh1owzbsflby6z1asct td.tinytable_css_awwqe9cumijwc89lu64v, #tinytable_cdh1owzbsflby6z1asct th.tinytable_css_awwqe9cumijwc89lu64v {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_cdh1owzbsflby6z1asct td.tinytable_css_mzi0ilzisjk0qr9w6k07, #tinytable_cdh1owzbsflby6z1asct th.tinytable_css_mzi0ilzisjk0qr9w6k07 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_cdh1owzbsflby6z1asct td.tinytable_css_6x8ncht5jk1pqpzdqe2r, #tinytable_cdh1owzbsflby6z1asct th.tinytable_css_6x8ncht5jk1pqpzdqe2r { text-align: left }
    #tinytable_cdh1owzbsflby6z1asct td.tinytable_css_5hqnyddyz2mgjmbh8m3w, #tinytable_cdh1owzbsflby6z1asct th.tinytable_css_5hqnyddyz2mgjmbh8m3w {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    </style>
    <div class="container">
      <table class="tinytable" id="tinytable_cdh1owzbsflby6z1asct" style="width: auto; margin-left: auto; margin-right: auto;" data-quarto-disable-processing='true'>
        &#10;        <thead>
              <tr>
                <th scope="col" data-row="0" data-col="1"> </th>
                <th scope="col" data-row="0" data-col="2">XGB 3 (median agg.)</th>
                <th scope="col" data-row="0" data-col="3">CV-Lasso (median agg.)</th>
              </tr>
        </thead>
        &#10;        <tbody>
                <tr>
                  <td data-row="1" data-col="1">theta (resid_Y ~ resid_D)</td>
                  <td data-row="1" data-col="2">−0.061</td>
                  <td data-row="1" data-col="3">−0.008</td>
                </tr>
                <tr>
                  <td data-row="2" data-col="1"></td>
                  <td data-row="2" data-col="2">(0.029)</td>
                  <td data-row="2" data-col="3">(0.066)</td>
                </tr>
                <tr>
                  <td data-row="3" data-col="1">N</td>
                  <td data-row="3" data-col="2">258352</td>
                  <td data-row="3" data-col="3">258352</td>
                </tr>
                <tr>
                  <td data-row="4" data-col="1">S (replications)</td>
                  <td data-row="4" data-col="2">5</td>
                  <td data-row="4" data-col="3">5</td>
                </tr>
                <tr>
                  <td data-row="5" data-col="1">R^2 outcome eq.</td>
                  <td data-row="5" data-col="2">0.862</td>
                  <td data-row="5" data-col="3">0.680</td>
                </tr>
                <tr>
                  <td data-row="6" data-col="1">R^2 treatment eq.</td>
                  <td data-row="6" data-col="2">0.743</td>
                  <td data-row="6" data-col="3">0.724</td>
                </tr>
        </tbody>
      </table>
    </div>
<!-- hack to avoid NA insertion in last line -->

</div>

CV-Lasso underperforms badly on both $R^2(Y\mid X)$ and $R^2(D\mid X)$, and the resulting estimate is indistinguishable from zero. A priori one would not know whether the relevant DGP favors boosted trees or a sparse linear model, so committing to a single learner without validation is fragile.

## How to select and validate the nuisance learner?

In Section 6 of the paper, we discuss **three recommended options for constructing and validating nuisance function estimators**:

1.  Consider performance metrics based on cross-fitted predicted values (e.g., cross-fitted $R^2$), which allow selecting the best-performing learner for each nuisance function separately.
2.  Use formal inference-based learner selection, e.g., the Cross-Validation with Confidence test of Lei (2020).
3.  Use model averaging (stacking) to optimally combine candidate learners using non-negative least squares.

We focus here on the third approach. For both the outcome and the treatment equation, we form a combination of learners by regressing $Y$ and $D$ on the cross-fitted predicted values of every candidate learner, subject to non-negative weights that sum to one. We refer to this approach as “short-stacking” to distinguish it from an alternative approach that re-estimates the stacking weights for each fold.

Table 6 from the paper reports the stacked DML result: $\hat\theta_0 \approx -0.054$ with $\mathrm{s.e.} = 0.020$. The stacking weights (shown in Table 5 of the paper) load almost entirely on the three XGBoost specifications.

## What to take away

Before reporting DML results, it is essential to validate the nuisance function estimators and to question their performance. Other important implementation choices include the number of cross-fitting folds, the fold splitting scheme, and the aggregation method.

## References

- Ahrens, A., V. Chernozhukov, C. Hansen, D. Kozbur, M. Schaffer and T. Wiemann. *An Introduction to Double/Debiased Machine Learning.* §5 (median aggregation), §6 (Dube application, Tables 5–6), §7 (implementation guidance).
- Ahrens, A., C. B. Hansen, M. E. Schaffer and T. Wiemann (2024). [`ddml`: Double/debiased machine learning in R.](https://doi.org/10.18637/jss.v108.i03)
- Chernozhukov, V., D. Chetverikov, M. Demirer, E. Duflo, C. Hansen, W. Newey and J. Robins (2018). [Double/Debiased machine learning for treatment and structural parameters.](https://doi.org/10.1111/ectj.12097)
- Dube, A., J. Jacobs, S. Naidu and S. Suri (2020). [Monopsony in online labor markets.](https://doi.org/10.3386/w26108) *AER: Insights* 2 (1).
- Lei, J. (2020). Cross-validation with confidence. *Journal of the American Statistical Association.*
