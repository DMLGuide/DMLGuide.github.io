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

*Part 3 of a three-post series. \[Part 1\]({{ '/examples/Monopsony_DML' | relative_url }}) ran DDML on the Dube et al. (2020) MTurk data with hand-coded controls only. \[Part 2\]({{ '/examples/Monopsony_Finetune' | relative_url }}) added fine-tuned DeBERTa embeddings. Both used $K = 3$ recruiter-honest folds, a single XGBoost nuisance learner, one seed, and cluster-robust standard errors at the recruiter level. This post asks: how much of that headline number is a function of those choices?*

This final part highlights key validation checks that are worth considering when applying DDML. Specificallu, we repeat the cross-fitting to assess sensitivity to the random fold division, we vary the number of folds $K$, and the construction of the folds (randomize by recruiter vs independent sampling).

## 1. Multi-seed aggregation

A single randomization seed generates one random partition of the sample into folds, and also affects machine learning algorithms relying on randomization. Asymptotically the exact random partition does not matter; in finite samples it can make a difference. Section 5 of the review paper recommends repeating the cross-fitting $S$ times and reporting the median-aggregate estimate:

$$\hat\theta_0^{\text{median}} = \mathrm{median}\bigl\{\hat\theta_{0,s}\bigr\}_{s=1}^{S},\qquad
\widehat{\mathrm{s.e.}}^{\text{median}} \;=\; \sqrt{\mathrm{median}\bigl\{\widehat{\mathrm{s.e.}}_s^{\,2} + (\hat\theta_{0,s} - \hat\theta_0^{\text{median}})^2\bigr\}_{s=1}^{S}}.$$

We here use $S = 5$ seeds, matching the paper.

<div id="tbl-multiseed">

Table 1: Per-seed estimates and median-of-medians aggregation. XGBoost; K = 3 cluster-honest folds; cluster-robust SE per seed.
<!-- preamble start -->
&#10;    <script src="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.js"></script>
&#10;    <script>
      // Create table-specific functions using external factory
      const tableFns_whqgbz4xyym63ylx2cjs = TinyTable.createTableFunctions("tinytable_whqgbz4xyym63ylx2cjs");
      // tinytable span after
      window.addEventListener('load', function () {
          var cellsToStyle = [
            // tinytable style arrays after
          { positions: [ { i: '6', j: 2 }, { i: '6', j: 3 }, { i: '6', j: 4 }, { i: '6', j: 5 }, { i: '6', j: 6 }, { i: '6', j: 7 } ], css_id: 'tinytable_css_1krwo28lefwt3kimcau2',}, 
          { positions: [ { i: '2', j: 2 }, { i: '2', j: 3 }, { i: '2', j: 4 }, { i: '2', j: 5 }, { i: '2', j: 6 }, { i: '2', j: 7 } ], css_id: 'tinytable_css_my30193r5jwp7jgc5fr6',}, 
          { positions: [ { i: '1', j: 2 }, { i: '3', j: 2 }, { i: '4', j: 2 }, { i: '5', j: 2 }, { i: '1', j: 3 }, { i: '3', j: 3 }, { i: '4', j: 3 }, { i: '5', j: 3 }, { i: '1', j: 4 }, { i: '3', j: 4 }, { i: '4', j: 4 }, { i: '5', j: 4 }, { i: '1', j: 5 }, { i: '3', j: 5 }, { i: '4', j: 5 }, { i: '5', j: 5 }, { i: '1', j: 6 }, { i: '3', j: 6 }, { i: '4', j: 6 }, { i: '5', j: 6 }, { i: '1', j: 7 }, { i: '3', j: 7 }, { i: '4', j: 7 }, { i: '5', j: 7 } ], css_id: 'tinytable_css_k7remdmz6cab6612ldws',}, 
          { positions: [ { i: '0', j: 2 }, { i: '0', j: 3 }, { i: '0', j: 4 }, { i: '0', j: 5 }, { i: '0', j: 6 }, { i: '0', j: 7 } ], css_id: 'tinytable_css_mgcujyciwuivsskvixoa',}, 
          { positions: [ { i: '6', j: 1 } ], css_id: 'tinytable_css_gustt4me5bi899281p24',}, 
          { positions: [ { i: '2', j: 1 } ], css_id: 'tinytable_css_9thiv9jq8qmr8jokk7ei',}, 
          { positions: [ { i: '1', j: 1 }, { i: '3', j: 1 }, { i: '4', j: 1 }, { i: '5', j: 1 } ], css_id: 'tinytable_css_i2mu1t3954acbrn451fr',}, 
          { positions: [ { i: '0', j: 1 } ], css_id: 'tinytable_css_p5d1a2ao9lvi5lxxtq8a',}, 
          ];
&#10;          // Loop over the arrays to style the cells
          cellsToStyle.forEach(function (group) {
              group.positions.forEach(function (cell) {
                  tableFns_whqgbz4xyym63ylx2cjs.styleCell(cell.i, cell.j, group.css_id);
              });
          });
      });
    </script>
&#10;    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.css">
    <style>
    /* tinytable css entries after */
    #tinytable_whqgbz4xyym63ylx2cjs td.tinytable_css_1krwo28lefwt3kimcau2, #tinytable_whqgbz4xyym63ylx2cjs th.tinytable_css_1krwo28lefwt3kimcau2 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_whqgbz4xyym63ylx2cjs td.tinytable_css_my30193r5jwp7jgc5fr6, #tinytable_whqgbz4xyym63ylx2cjs th.tinytable_css_my30193r5jwp7jgc5fr6 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_whqgbz4xyym63ylx2cjs td.tinytable_css_k7remdmz6cab6612ldws, #tinytable_whqgbz4xyym63ylx2cjs th.tinytable_css_k7remdmz6cab6612ldws { text-align: center }
    #tinytable_whqgbz4xyym63ylx2cjs td.tinytable_css_mgcujyciwuivsskvixoa, #tinytable_whqgbz4xyym63ylx2cjs th.tinytable_css_mgcujyciwuivsskvixoa {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_whqgbz4xyym63ylx2cjs td.tinytable_css_gustt4me5bi899281p24, #tinytable_whqgbz4xyym63ylx2cjs th.tinytable_css_gustt4me5bi899281p24 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_whqgbz4xyym63ylx2cjs td.tinytable_css_9thiv9jq8qmr8jokk7ei, #tinytable_whqgbz4xyym63ylx2cjs th.tinytable_css_9thiv9jq8qmr8jokk7ei {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_whqgbz4xyym63ylx2cjs td.tinytable_css_i2mu1t3954acbrn451fr, #tinytable_whqgbz4xyym63ylx2cjs th.tinytable_css_i2mu1t3954acbrn451fr { text-align: left }
    #tinytable_whqgbz4xyym63ylx2cjs td.tinytable_css_p5d1a2ao9lvi5lxxtq8a, #tinytable_whqgbz4xyym63ylx2cjs th.tinytable_css_p5d1a2ao9lvi5lxxtq8a {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    </style>
    <div class="container">
      <table class="tinytable" id="tinytable_whqgbz4xyym63ylx2cjs" style="width: auto; margin-left: auto; margin-right: auto;" data-quarto-disable-processing='true'>
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

Compare the median-aggregate estimate column against the seed-specific columns. The single-seed estimates span roughly $-0.06$ to $-0.09$ — a non-trivial spread relative to any individual seed’s SE — so sample-split randomness has a noticeable impact real here.

## 2. Sensitivity to the number of folds $K$

Cross-fitting theory accommodates any fixed $K$. Velez (2024) shows performance improves with more folds, peaking at $K = n$ with diminishing returns. In the paper, we recommend to consider the largest number consistent with available compute, and check sensitivity.

<div id="tbl-K">

Table 2: Coefficient on log(reward) by number of folds K. XGBoost; cluster-honest folds; cluster-robust SE.
<!-- preamble start -->
&#10;    <script src="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.js"></script>
&#10;    <script>
      // Create table-specific functions using external factory
      const tableFns_me5ldemvzu0nf9xfifyh = TinyTable.createTableFunctions("tinytable_me5ldemvzu0nf9xfifyh");
      // tinytable span after
      window.addEventListener('load', function () {
          var cellsToStyle = [
            // tinytable style arrays after
          { positions: [ { i: '6', j: 2 }, { i: '6', j: 3 } ], css_id: 'tinytable_css_j8ymz9wsaw49haeq2kpf',}, 
          { positions: [ { i: '2', j: 2 }, { i: '2', j: 3 } ], css_id: 'tinytable_css_rb9u4aysndar4pbthzxx',}, 
          { positions: [ { i: '1', j: 2 }, { i: '3', j: 2 }, { i: '4', j: 2 }, { i: '5', j: 2 }, { i: '1', j: 3 }, { i: '3', j: 3 }, { i: '4', j: 3 }, { i: '5', j: 3 } ], css_id: 'tinytable_css_3cs5yx5zly8p8glkryyi',}, 
          { positions: [ { i: '0', j: 2 }, { i: '0', j: 3 } ], css_id: 'tinytable_css_kds4l7v7338s5jj066ri',}, 
          { positions: [ { i: '6', j: 1 } ], css_id: 'tinytable_css_iubu2dgbkkpk7pcvnue7',}, 
          { positions: [ { i: '2', j: 1 } ], css_id: 'tinytable_css_xqwyeuih45ryykcor91d',}, 
          { positions: [ { i: '1', j: 1 }, { i: '3', j: 1 }, { i: '4', j: 1 }, { i: '5', j: 1 } ], css_id: 'tinytable_css_a7n9vsm3pnrnan09auaj',}, 
          { positions: [ { i: '0', j: 1 } ], css_id: 'tinytable_css_ftqv186z709xmcjv04zg',}, 
          ];
&#10;          // Loop over the arrays to style the cells
          cellsToStyle.forEach(function (group) {
              group.positions.forEach(function (cell) {
                  tableFns_me5ldemvzu0nf9xfifyh.styleCell(cell.i, cell.j, group.css_id);
              });
          });
      });
    </script>
&#10;    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.css">
    <style>
    /* tinytable css entries after */
    #tinytable_me5ldemvzu0nf9xfifyh td.tinytable_css_j8ymz9wsaw49haeq2kpf, #tinytable_me5ldemvzu0nf9xfifyh th.tinytable_css_j8ymz9wsaw49haeq2kpf {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_me5ldemvzu0nf9xfifyh td.tinytable_css_rb9u4aysndar4pbthzxx, #tinytable_me5ldemvzu0nf9xfifyh th.tinytable_css_rb9u4aysndar4pbthzxx {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_me5ldemvzu0nf9xfifyh td.tinytable_css_3cs5yx5zly8p8glkryyi, #tinytable_me5ldemvzu0nf9xfifyh th.tinytable_css_3cs5yx5zly8p8glkryyi { text-align: center }
    #tinytable_me5ldemvzu0nf9xfifyh td.tinytable_css_kds4l7v7338s5jj066ri, #tinytable_me5ldemvzu0nf9xfifyh th.tinytable_css_kds4l7v7338s5jj066ri {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_me5ldemvzu0nf9xfifyh td.tinytable_css_iubu2dgbkkpk7pcvnue7, #tinytable_me5ldemvzu0nf9xfifyh th.tinytable_css_iubu2dgbkkpk7pcvnue7 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_me5ldemvzu0nf9xfifyh td.tinytable_css_xqwyeuih45ryykcor91d, #tinytable_me5ldemvzu0nf9xfifyh th.tinytable_css_xqwyeuih45ryykcor91d {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_me5ldemvzu0nf9xfifyh td.tinytable_css_a7n9vsm3pnrnan09auaj, #tinytable_me5ldemvzu0nf9xfifyh th.tinytable_css_a7n9vsm3pnrnan09auaj { text-align: left }
    #tinytable_me5ldemvzu0nf9xfifyh td.tinytable_css_ftqv186z709xmcjv04zg, #tinytable_me5ldemvzu0nf9xfifyh th.tinytable_css_ftqv186z709xmcjv04zg {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    </style>
    <div class="container">
      <table class="tinytable" id="tinytable_me5ldemvzu0nf9xfifyh" style="width: auto; margin-left: auto; margin-right: auto;" data-quarto-disable-processing='true'>
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

## 3. Cluster-respecting vs IID folds

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

Table 3: Coefficient on log(reward) under recruiter-clustered vs IID folds, with matching SE estimator. XGBoost; K = 3.
<!-- preamble start -->
&#10;    <script src="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.js"></script>
&#10;    <script>
      // Create table-specific functions using external factory
      const tableFns_zjxbathtmtc1l5iqaakp = TinyTable.createTableFunctions("tinytable_zjxbathtmtc1l5iqaakp");
      // tinytable span after
      window.addEventListener('load', function () {
          var cellsToStyle = [
            // tinytable style arrays after
          { positions: [ { i: '6', j: 2 }, { i: '6', j: 3 } ], css_id: 'tinytable_css_8ful1dwus027kcbo0h7z',}, 
          { positions: [ { i: '2', j: 2 }, { i: '2', j: 3 } ], css_id: 'tinytable_css_my53lppicxq32xa5uxm2',}, 
          { positions: [ { i: '1', j: 2 }, { i: '3', j: 2 }, { i: '4', j: 2 }, { i: '5', j: 2 }, { i: '1', j: 3 }, { i: '3', j: 3 }, { i: '4', j: 3 }, { i: '5', j: 3 } ], css_id: 'tinytable_css_3xmum9kzxm9ju27br5ba',}, 
          { positions: [ { i: '0', j: 2 }, { i: '0', j: 3 } ], css_id: 'tinytable_css_9uqwo54tn6rw37tux7td',}, 
          { positions: [ { i: '6', j: 1 } ], css_id: 'tinytable_css_0v132ho2v4cc20rotsfx',}, 
          { positions: [ { i: '2', j: 1 } ], css_id: 'tinytable_css_6rzwvovhb476fyjq77w5',}, 
          { positions: [ { i: '1', j: 1 }, { i: '3', j: 1 }, { i: '4', j: 1 }, { i: '5', j: 1 } ], css_id: 'tinytable_css_5znam1xuh12tywkkon3n',}, 
          { positions: [ { i: '0', j: 1 } ], css_id: 'tinytable_css_f9swjxildg5ot4e30v32',}, 
          ];
&#10;          // Loop over the arrays to style the cells
          cellsToStyle.forEach(function (group) {
              group.positions.forEach(function (cell) {
                  tableFns_zjxbathtmtc1l5iqaakp.styleCell(cell.i, cell.j, group.css_id);
              });
          });
      });
    </script>
&#10;    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.css">
    <style>
    /* tinytable css entries after */
    #tinytable_zjxbathtmtc1l5iqaakp td.tinytable_css_8ful1dwus027kcbo0h7z, #tinytable_zjxbathtmtc1l5iqaakp th.tinytable_css_8ful1dwus027kcbo0h7z {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_zjxbathtmtc1l5iqaakp td.tinytable_css_my53lppicxq32xa5uxm2, #tinytable_zjxbathtmtc1l5iqaakp th.tinytable_css_my53lppicxq32xa5uxm2 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_zjxbathtmtc1l5iqaakp td.tinytable_css_3xmum9kzxm9ju27br5ba, #tinytable_zjxbathtmtc1l5iqaakp th.tinytable_css_3xmum9kzxm9ju27br5ba { text-align: center }
    #tinytable_zjxbathtmtc1l5iqaakp td.tinytable_css_9uqwo54tn6rw37tux7td, #tinytable_zjxbathtmtc1l5iqaakp th.tinytable_css_9uqwo54tn6rw37tux7td {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_zjxbathtmtc1l5iqaakp td.tinytable_css_0v132ho2v4cc20rotsfx, #tinytable_zjxbathtmtc1l5iqaakp th.tinytable_css_0v132ho2v4cc20rotsfx {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_zjxbathtmtc1l5iqaakp td.tinytable_css_6rzwvovhb476fyjq77w5, #tinytable_zjxbathtmtc1l5iqaakp th.tinytable_css_6rzwvovhb476fyjq77w5 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_zjxbathtmtc1l5iqaakp td.tinytable_css_5znam1xuh12tywkkon3n, #tinytable_zjxbathtmtc1l5iqaakp th.tinytable_css_5znam1xuh12tywkkon3n { text-align: left }
    #tinytable_zjxbathtmtc1l5iqaakp td.tinytable_css_f9swjxildg5ot4e30v32, #tinytable_zjxbathtmtc1l5iqaakp th.tinytable_css_f9swjxildg5ot4e30v32 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    </style>
    <div class="container">
      <table class="tinytable" id="tinytable_zjxbathtmtc1l5iqaakp" style="width: auto; margin-left: auto; margin-right: auto;" data-quarto-disable-processing='true'>
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

## 4. Choice of nuisance learner (and a note on short-stacking)

<div id="tbl-learner">

Table 4: Coefficient on log(reward) by single nuisance learner. K = 3 cluster-honest folds; cluster-robust SE.
<!-- preamble start -->
&#10;    <script src="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.js"></script>
&#10;    <script>
      // Create table-specific functions using external factory
      const tableFns_sz8ydwpaaf857vw2lmft = TinyTable.createTableFunctions("tinytable_sz8ydwpaaf857vw2lmft");
      // tinytable span after
      window.addEventListener('load', function () {
          var cellsToStyle = [
            // tinytable style arrays after
          { positions: [ { i: '6', j: 2 }, { i: '6', j: 3 } ], css_id: 'tinytable_css_upbx8b78logbd2p5dxnw',}, 
          { positions: [ { i: '2', j: 2 }, { i: '2', j: 3 } ], css_id: 'tinytable_css_bvh23xuq6hmnyuye3rpy',}, 
          { positions: [ { i: '1', j: 2 }, { i: '3', j: 2 }, { i: '4', j: 2 }, { i: '5', j: 2 }, { i: '1', j: 3 }, { i: '3', j: 3 }, { i: '4', j: 3 }, { i: '5', j: 3 } ], css_id: 'tinytable_css_h2srdmucx9ej6dqjrjmk',}, 
          { positions: [ { i: '0', j: 2 }, { i: '0', j: 3 } ], css_id: 'tinytable_css_cizp4c65jsxwfs20i49v',}, 
          { positions: [ { i: '6', j: 1 } ], css_id: 'tinytable_css_a87r2clcvzi1ce2u3eim',}, 
          { positions: [ { i: '2', j: 1 } ], css_id: 'tinytable_css_l7a2t1h0ns5a53cydkz8',}, 
          { positions: [ { i: '1', j: 1 }, { i: '3', j: 1 }, { i: '4', j: 1 }, { i: '5', j: 1 } ], css_id: 'tinytable_css_7l9u74u6k9kwvu5m0cmm',}, 
          { positions: [ { i: '0', j: 1 } ], css_id: 'tinytable_css_08xp6ppol9ftzkmtt13p',}, 
          ];
&#10;          // Loop over the arrays to style the cells
          cellsToStyle.forEach(function (group) {
              group.positions.forEach(function (cell) {
                  tableFns_sz8ydwpaaf857vw2lmft.styleCell(cell.i, cell.j, group.css_id);
              });
          });
      });
    </script>
&#10;    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.css">
    <style>
    /* tinytable css entries after */
    #tinytable_sz8ydwpaaf857vw2lmft td.tinytable_css_upbx8b78logbd2p5dxnw, #tinytable_sz8ydwpaaf857vw2lmft th.tinytable_css_upbx8b78logbd2p5dxnw {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_sz8ydwpaaf857vw2lmft td.tinytable_css_bvh23xuq6hmnyuye3rpy, #tinytable_sz8ydwpaaf857vw2lmft th.tinytable_css_bvh23xuq6hmnyuye3rpy {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_sz8ydwpaaf857vw2lmft td.tinytable_css_h2srdmucx9ej6dqjrjmk, #tinytable_sz8ydwpaaf857vw2lmft th.tinytable_css_h2srdmucx9ej6dqjrjmk { text-align: center }
    #tinytable_sz8ydwpaaf857vw2lmft td.tinytable_css_cizp4c65jsxwfs20i49v, #tinytable_sz8ydwpaaf857vw2lmft th.tinytable_css_cizp4c65jsxwfs20i49v {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_sz8ydwpaaf857vw2lmft td.tinytable_css_a87r2clcvzi1ce2u3eim, #tinytable_sz8ydwpaaf857vw2lmft th.tinytable_css_a87r2clcvzi1ce2u3eim {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_sz8ydwpaaf857vw2lmft td.tinytable_css_l7a2t1h0ns5a53cydkz8, #tinytable_sz8ydwpaaf857vw2lmft th.tinytable_css_l7a2t1h0ns5a53cydkz8 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_sz8ydwpaaf857vw2lmft td.tinytable_css_7l9u74u6k9kwvu5m0cmm, #tinytable_sz8ydwpaaf857vw2lmft th.tinytable_css_7l9u74u6k9kwvu5m0cmm { text-align: left }
    #tinytable_sz8ydwpaaf857vw2lmft td.tinytable_css_08xp6ppol9ftzkmtt13p, #tinytable_sz8ydwpaaf857vw2lmft th.tinytable_css_08xp6ppol9ftzkmtt13p {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    </style>
    <div class="container">
      <table class="tinytable" id="tinytable_sz8ydwpaaf857vw2lmft" style="width: auto; margin-left: auto; margin-right: auto;" data-quarto-disable-processing='true'>
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

The choice of nuisance learner matters in this application: Lasso lands roughly $1.7\times$ further from zero than XGBoost, with a standard error several times larger and an outcome $R^2$ about 20 percentage points lower — a learner that does not fit cannot debias. The DDML paper’s Table 5 documents a much sharper version of this pattern across twelve candidate learners, with point estimates of $\theta_0$ spanning $-3.9$ to $2.1$. The cleanest way to sidestep the choice is short-stacking: regress $Y$ and $D$ on the cross-fitted predicted values of every candidate learner under non-negative weights summing to one, and use the resulting weights to build a super-learner for each nuisance function. Table 6 of the paper reports stacked DDML at $\hat\theta_0 = -0.054$ (s.e. $0.020$) and single-best at $-0.060$ (s.e. $0.018$); the stacking weights load almost entirely on the three XGBoost specifications, so when XGBoost dominates the linear alternatives — as it does here — stacking inherits its performance for free. We do not run short-stacking in `blog3_robust.R`; the full pipeline lives in `Code/dube_monopsony/`.

## 5. What to take away

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
