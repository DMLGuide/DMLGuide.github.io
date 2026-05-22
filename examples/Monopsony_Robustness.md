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

*Part 3 of a three-post series. <a href="{{ '/examples/Monopsony_DML' | relative_url }}">Part 1</a> ran DDML on the Dube et al. (2020) MTurk data with hand-coded controls only. <a href="{{ '/examples/Monopsony_Finetune' | relative_url }}">Part 2</a> added fine-tuned DeBERTa embeddings. Both used $K = 3$ recruiter-honest folds, a single XGBoost nuisance learner, one seed, and cluster-robust standard errors at the recruiter level. This post asks: how much of that headline number is a function of those choices?*

This final part highlights key validation checks that are worth considering when applying DDML. We first repeat the baseline cross-fitting under $S = 5$ independent randomisation seeds and aggregate them with the paper’s median-of-medians estimator. We then compare the resulting baseline median *pairwise* against three one-knob variants — a larger number of folds, a linear nuisance learner, and IID instead of recruiter-honest fold construction — one comparison per subsection so the reader can read each knob’s table next to its discussion.

The baseline throughout is the Part 2 specification: $K = 3$ recruiter-honest folds, XGBoost as the single nuisance learner, and cluster-robust standard errors at the recruiter level.

## 1. Multi-seed aggregation

A single randomization seed generates one random partition of the sample into folds, and also affects machine learning algorithms relying on randomization. Asymptotically the exact random partition does not matter; in finite samples it can make a difference. Section 5 of the review paper recommends repeating the cross-fitting $S$ times and reporting the median-aggregate estimate:

$$\hat\theta_0^{\text{median}} = \mathrm{median}\bigl\{\hat\theta_{0,s}\bigr\}_{s=1}^{S},\qquad
\widehat{\mathrm{s.e.}}^{\text{median}} \;=\; \sqrt{\mathrm{median}\bigl\{\widehat{\mathrm{s.e.}}_s^{\,2} + (\hat\theta_{0,s} - \hat\theta_0^{\text{median}})^2\bigr\}_{s=1}^{S}}.$$

We here use $S = 5$ seeds, matching the paper.

<div id="tbl-multiseed">

Table 1: Per-seed estimates and median-of-medians aggregation for the baseline specification. XGBoost; K = 3 cluster-honest folds; cluster-robust SE per seed.
<!-- preamble start -->
&#10;    <script src="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.js"></script>
&#10;    <script>
      // Create table-specific functions using external factory
      const tableFns_jr32vf6zwcnk2iad79hf = TinyTable.createTableFunctions("tinytable_jr32vf6zwcnk2iad79hf");
      // tinytable span after
      window.addEventListener('load', function () {
          var cellsToStyle = [
            // tinytable style arrays after
          { positions: [ { i: '6', j: 2 }, { i: '6', j: 3 }, { i: '6', j: 4 }, { i: '6', j: 5 }, { i: '6', j: 6 }, { i: '6', j: 7 } ], css_id: 'tinytable_css_bl3ayb6zjxlo4txmhpx7',}, 
          { positions: [ { i: '2', j: 2 }, { i: '2', j: 3 }, { i: '2', j: 4 }, { i: '2', j: 5 }, { i: '2', j: 6 }, { i: '2', j: 7 } ], css_id: 'tinytable_css_6ak6ortjx0d2n13ld2ng',}, 
          { positions: [ { i: '1', j: 2 }, { i: '3', j: 2 }, { i: '4', j: 2 }, { i: '5', j: 2 }, { i: '1', j: 3 }, { i: '3', j: 3 }, { i: '4', j: 3 }, { i: '5', j: 3 }, { i: '1', j: 4 }, { i: '3', j: 4 }, { i: '4', j: 4 }, { i: '5', j: 4 }, { i: '1', j: 5 }, { i: '3', j: 5 }, { i: '4', j: 5 }, { i: '5', j: 5 }, { i: '1', j: 6 }, { i: '3', j: 6 }, { i: '4', j: 6 }, { i: '5', j: 6 }, { i: '1', j: 7 }, { i: '3', j: 7 }, { i: '4', j: 7 }, { i: '5', j: 7 } ], css_id: 'tinytable_css_53vgx9a90avcwkjy268p',}, 
          { positions: [ { i: '0', j: 2 }, { i: '0', j: 3 }, { i: '0', j: 4 }, { i: '0', j: 5 }, { i: '0', j: 6 }, { i: '0', j: 7 } ], css_id: 'tinytable_css_a6qpos91ijbdkr0domlv',}, 
          { positions: [ { i: '6', j: 1 } ], css_id: 'tinytable_css_2fw0zfmgvemb2c8lo9yt',}, 
          { positions: [ { i: '2', j: 1 } ], css_id: 'tinytable_css_ujg66ftruxr38u1unjq9',}, 
          { positions: [ { i: '1', j: 1 }, { i: '3', j: 1 }, { i: '4', j: 1 }, { i: '5', j: 1 } ], css_id: 'tinytable_css_90nnd7aaevqstnovk0c5',}, 
          { positions: [ { i: '0', j: 1 } ], css_id: 'tinytable_css_rlyoqg89g6cwuwkgz56v',}, 
          ];
&#10;          // Loop over the arrays to style the cells
          cellsToStyle.forEach(function (group) {
              group.positions.forEach(function (cell) {
                  tableFns_jr32vf6zwcnk2iad79hf.styleCell(cell.i, cell.j, group.css_id);
              });
          });
      });
    </script>
&#10;    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.css">
    <style>
    /* tinytable css entries after */
    #tinytable_jr32vf6zwcnk2iad79hf td.tinytable_css_bl3ayb6zjxlo4txmhpx7, #tinytable_jr32vf6zwcnk2iad79hf th.tinytable_css_bl3ayb6zjxlo4txmhpx7 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_jr32vf6zwcnk2iad79hf td.tinytable_css_6ak6ortjx0d2n13ld2ng, #tinytable_jr32vf6zwcnk2iad79hf th.tinytable_css_6ak6ortjx0d2n13ld2ng {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_jr32vf6zwcnk2iad79hf td.tinytable_css_53vgx9a90avcwkjy268p, #tinytable_jr32vf6zwcnk2iad79hf th.tinytable_css_53vgx9a90avcwkjy268p { text-align: center }
    #tinytable_jr32vf6zwcnk2iad79hf td.tinytable_css_a6qpos91ijbdkr0domlv, #tinytable_jr32vf6zwcnk2iad79hf th.tinytable_css_a6qpos91ijbdkr0domlv {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_jr32vf6zwcnk2iad79hf td.tinytable_css_2fw0zfmgvemb2c8lo9yt, #tinytable_jr32vf6zwcnk2iad79hf th.tinytable_css_2fw0zfmgvemb2c8lo9yt {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_jr32vf6zwcnk2iad79hf td.tinytable_css_ujg66ftruxr38u1unjq9, #tinytable_jr32vf6zwcnk2iad79hf th.tinytable_css_ujg66ftruxr38u1unjq9 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_jr32vf6zwcnk2iad79hf td.tinytable_css_90nnd7aaevqstnovk0c5, #tinytable_jr32vf6zwcnk2iad79hf th.tinytable_css_90nnd7aaevqstnovk0c5 { text-align: left }
    #tinytable_jr32vf6zwcnk2iad79hf td.tinytable_css_rlyoqg89g6cwuwkgz56v, #tinytable_jr32vf6zwcnk2iad79hf th.tinytable_css_rlyoqg89g6cwuwkgz56v {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    </style>
    <div class="container">
      <table class="tinytable" id="tinytable_jr32vf6zwcnk2iad79hf" style="width: auto; margin-left: auto; margin-right: auto;" data-quarto-disable-processing='true'>
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

Compare the median-aggregate column against the seed-specific columns. The single-seed estimates span roughly $-0.06$ to $-0.09$ — a non-trivial spread relative to any individual seed’s SE — so sample-split randomness has a noticeable impact here. The median-of-medians point estimate is the inference-bearing number we carry into the cross-set comparison below.

## 2. Pairwise baseline-vs-variant comparisons

Each subsection below holds the baseline fixed and varies one knob. Every column is itself a median-of-medians over five seeds, so within-table differences reflect the knob rather than seed noise.

### 2.1 Number of folds $K$

<div id="tbl-K">

Table 2: Baseline vs. K = 5. Both columns are median-of-medians over S = 5 seeds; XGBoost; recruiter-honest folds; cluster-robust SE.
<!-- preamble start -->
&#10;    <script src="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.js"></script>
&#10;    <script>
      // Create table-specific functions using external factory
      const tableFns_wf2p7wolfawy5wukw96t = TinyTable.createTableFunctions("tinytable_wf2p7wolfawy5wukw96t");
      // tinytable span after
      window.addEventListener('load', function () {
          var cellsToStyle = [
            // tinytable style arrays after
          { positions: [ { i: '6', j: 2 }, { i: '6', j: 3 } ], css_id: 'tinytable_css_s8jtfnopisfyolzyma5f',}, 
          { positions: [ { i: '2', j: 2 }, { i: '2', j: 3 } ], css_id: 'tinytable_css_etq4kb67un4f29htwghl',}, 
          { positions: [ { i: '1', j: 2 }, { i: '3', j: 2 }, { i: '4', j: 2 }, { i: '5', j: 2 }, { i: '1', j: 3 }, { i: '3', j: 3 }, { i: '4', j: 3 }, { i: '5', j: 3 } ], css_id: 'tinytable_css_u5z18uza6oz2uvp1dhjn',}, 
          { positions: [ { i: '0', j: 2 }, { i: '0', j: 3 } ], css_id: 'tinytable_css_9bczm484e48ix9r5yd3v',}, 
          { positions: [ { i: '6', j: 1 } ], css_id: 'tinytable_css_j5shunzxt7qdsnxv6pz3',}, 
          { positions: [ { i: '2', j: 1 } ], css_id: 'tinytable_css_b5inlgzcqmme95fcvx5u',}, 
          { positions: [ { i: '1', j: 1 }, { i: '3', j: 1 }, { i: '4', j: 1 }, { i: '5', j: 1 } ], css_id: 'tinytable_css_xb79mfasi8d3rwt05h6t',}, 
          { positions: [ { i: '0', j: 1 } ], css_id: 'tinytable_css_katnpsqdv4k8sqf6ykm3',}, 
          ];
&#10;          // Loop over the arrays to style the cells
          cellsToStyle.forEach(function (group) {
              group.positions.forEach(function (cell) {
                  tableFns_wf2p7wolfawy5wukw96t.styleCell(cell.i, cell.j, group.css_id);
              });
          });
      });
    </script>
&#10;    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.css">
    <style>
    /* tinytable css entries after */
    #tinytable_wf2p7wolfawy5wukw96t td.tinytable_css_s8jtfnopisfyolzyma5f, #tinytable_wf2p7wolfawy5wukw96t th.tinytable_css_s8jtfnopisfyolzyma5f {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_wf2p7wolfawy5wukw96t td.tinytable_css_etq4kb67un4f29htwghl, #tinytable_wf2p7wolfawy5wukw96t th.tinytable_css_etq4kb67un4f29htwghl {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_wf2p7wolfawy5wukw96t td.tinytable_css_u5z18uza6oz2uvp1dhjn, #tinytable_wf2p7wolfawy5wukw96t th.tinytable_css_u5z18uza6oz2uvp1dhjn { text-align: center }
    #tinytable_wf2p7wolfawy5wukw96t td.tinytable_css_9bczm484e48ix9r5yd3v, #tinytable_wf2p7wolfawy5wukw96t th.tinytable_css_9bczm484e48ix9r5yd3v {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_wf2p7wolfawy5wukw96t td.tinytable_css_j5shunzxt7qdsnxv6pz3, #tinytable_wf2p7wolfawy5wukw96t th.tinytable_css_j5shunzxt7qdsnxv6pz3 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_wf2p7wolfawy5wukw96t td.tinytable_css_b5inlgzcqmme95fcvx5u, #tinytable_wf2p7wolfawy5wukw96t th.tinytable_css_b5inlgzcqmme95fcvx5u {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_wf2p7wolfawy5wukw96t td.tinytable_css_xb79mfasi8d3rwt05h6t, #tinytable_wf2p7wolfawy5wukw96t th.tinytable_css_xb79mfasi8d3rwt05h6t { text-align: left }
    #tinytable_wf2p7wolfawy5wukw96t td.tinytable_css_katnpsqdv4k8sqf6ykm3, #tinytable_wf2p7wolfawy5wukw96t th.tinytable_css_katnpsqdv4k8sqf6ykm3 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    </style>
    <div class="container">
      <table class="tinytable" id="tinytable_wf2p7wolfawy5wukw96t" style="width: auto; margin-left: auto; margin-right: auto;" data-quarto-disable-processing='true'>
        &#10;        <thead>
              <tr>
                <th scope="col" data-row="0" data-col="1"> </th>
                <th scope="col" data-row="0" data-col="2">Baseline (K=3, XGB, cluster)</th>
                <th scope="col" data-row="0" data-col="3">K=5, XGB, cluster</th>
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
                  <td data-row="2" data-col="2">(0.024)</td>
                  <td data-row="2" data-col="3">(0.028)</td>
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
                  <td data-row="5" data-col="2">0.859</td>
                  <td data-row="5" data-col="3">0.863</td>
                </tr>
                <tr>
                  <td data-row="6" data-col="1">R²(D|X)</td>
                  <td data-row="6" data-col="2">0.738</td>
                  <td data-row="6" data-col="3">0.738</td>
                </tr>
        </tbody>
      </table>
    </div>
<!-- hack to avoid NA insertion in last line -->

</div>

Cross-fitting theory accommodates any fixed $K$. Velez (2024) shows performance improves with more folds, peaking at $K = n$ with diminishing returns. In the paper we recommend the largest $K$ consistent with available compute, and a sensitivity check. Moving from $K = 3$ to $K = 5$ trains each nuisance fit on $4/5$ of the data instead of $2/3$ and compute scales roughly linearly. With $n \approx 258{,}000$ either value is in the range where the bias–variance tradeoff is favourable.

### 2.2 Choice of nuisance learner

<div id="tbl-learner">

Table 3: Baseline (XGBoost) vs. Lasso. Both columns are median-of-medians over S = 5 seeds; K = 3 recruiter-honest folds; cluster-robust SE.
<!-- preamble start -->
&#10;    <script src="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.js"></script>
&#10;    <script>
      // Create table-specific functions using external factory
      const tableFns_sjdznllbynplre9i06m0 = TinyTable.createTableFunctions("tinytable_sjdznllbynplre9i06m0");
      // tinytable span after
      window.addEventListener('load', function () {
          var cellsToStyle = [
            // tinytable style arrays after
          { positions: [ { i: '6', j: 2 }, { i: '6', j: 3 } ], css_id: 'tinytable_css_1g5eko7c109jhsxsdmiz',}, 
          { positions: [ { i: '2', j: 2 }, { i: '2', j: 3 } ], css_id: 'tinytable_css_kowgb2v7zc12owul1vwa',}, 
          { positions: [ { i: '1', j: 2 }, { i: '3', j: 2 }, { i: '4', j: 2 }, { i: '5', j: 2 }, { i: '1', j: 3 }, { i: '3', j: 3 }, { i: '4', j: 3 }, { i: '5', j: 3 } ], css_id: 'tinytable_css_641xnhkamxttvwafzrra',}, 
          { positions: [ { i: '0', j: 2 }, { i: '0', j: 3 } ], css_id: 'tinytable_css_9pimxpkhbcu709f0sx53',}, 
          { positions: [ { i: '6', j: 1 } ], css_id: 'tinytable_css_hduu9jxh54foe6z6n5hx',}, 
          { positions: [ { i: '2', j: 1 } ], css_id: 'tinytable_css_puc7dwxkcanzxw38rtv8',}, 
          { positions: [ { i: '1', j: 1 }, { i: '3', j: 1 }, { i: '4', j: 1 }, { i: '5', j: 1 } ], css_id: 'tinytable_css_dhcr6pwe6yck6zw0vtzi',}, 
          { positions: [ { i: '0', j: 1 } ], css_id: 'tinytable_css_1vmadvdrrmq76msfl1dr',}, 
          ];
&#10;          // Loop over the arrays to style the cells
          cellsToStyle.forEach(function (group) {
              group.positions.forEach(function (cell) {
                  tableFns_sjdznllbynplre9i06m0.styleCell(cell.i, cell.j, group.css_id);
              });
          });
      });
    </script>
&#10;    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.css">
    <style>
    /* tinytable css entries after */
    #tinytable_sjdznllbynplre9i06m0 td.tinytable_css_1g5eko7c109jhsxsdmiz, #tinytable_sjdznllbynplre9i06m0 th.tinytable_css_1g5eko7c109jhsxsdmiz {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_sjdznllbynplre9i06m0 td.tinytable_css_kowgb2v7zc12owul1vwa, #tinytable_sjdznllbynplre9i06m0 th.tinytable_css_kowgb2v7zc12owul1vwa {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_sjdznllbynplre9i06m0 td.tinytable_css_641xnhkamxttvwafzrra, #tinytable_sjdznllbynplre9i06m0 th.tinytable_css_641xnhkamxttvwafzrra { text-align: center }
    #tinytable_sjdznllbynplre9i06m0 td.tinytable_css_9pimxpkhbcu709f0sx53, #tinytable_sjdznllbynplre9i06m0 th.tinytable_css_9pimxpkhbcu709f0sx53 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_sjdznllbynplre9i06m0 td.tinytable_css_hduu9jxh54foe6z6n5hx, #tinytable_sjdznllbynplre9i06m0 th.tinytable_css_hduu9jxh54foe6z6n5hx {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_sjdznllbynplre9i06m0 td.tinytable_css_puc7dwxkcanzxw38rtv8, #tinytable_sjdznllbynplre9i06m0 th.tinytable_css_puc7dwxkcanzxw38rtv8 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_sjdznllbynplre9i06m0 td.tinytable_css_dhcr6pwe6yck6zw0vtzi, #tinytable_sjdznllbynplre9i06m0 th.tinytable_css_dhcr6pwe6yck6zw0vtzi { text-align: left }
    #tinytable_sjdznllbynplre9i06m0 td.tinytable_css_1vmadvdrrmq76msfl1dr, #tinytable_sjdznllbynplre9i06m0 th.tinytable_css_1vmadvdrrmq76msfl1dr {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    </style>
    <div class="container">
      <table class="tinytable" id="tinytable_sjdznllbynplre9i06m0" style="width: auto; margin-left: auto; margin-right: auto;" data-quarto-disable-processing='true'>
        &#10;        <thead>
              <tr>
                <th scope="col" data-row="0" data-col="1"> </th>
                <th scope="col" data-row="0" data-col="2">Baseline (K=3, XGB, cluster)</th>
                <th scope="col" data-row="0" data-col="3">K=3, Lasso, cluster</th>
              </tr>
        </thead>
        &#10;        <tbody>
                <tr>
                  <td data-row="1" data-col="1">log(reward)</td>
                  <td data-row="1" data-col="2">−0.062</td>
                  <td data-row="1" data-col="3">−0.008</td>
                </tr>
                <tr>
                  <td data-row="2" data-col="1"></td>
                  <td data-row="2" data-col="2">(0.024)</td>
                  <td data-row="2" data-col="3">(0.066)</td>
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
                  <td data-row="5" data-col="2">0.859</td>
                  <td data-row="5" data-col="3">0.679</td>
                </tr>
                <tr>
                  <td data-row="6" data-col="1">R²(D|X)</td>
                  <td data-row="6" data-col="2">0.738</td>
                  <td data-row="6" data-col="3">0.728</td>
                </tr>
        </tbody>
      </table>
    </div>
<!-- hack to avoid NA insertion in last line -->

</div>

The Lasso column underperforms on both $R^2(Y\mid X)$ and $R^2(D\mid X)$ — a learner that does not fit cannot debias, and the DDML paper’s Table 5 documents a much sharper version of this pattern across twelve candidate learners, with point estimates of $\theta_0$ spanning $-3.9$ to $2.1$. The cleanest way to sidestep the choice is short-stacking: regress $Y$ and $D$ on the cross-fitted predicted values of every candidate learner under non-negative weights summing to one, and use the resulting weights to build a super-learner for each nuisance function. Table 6 of the paper reports stacked DDML at $\hat\theta_0 = -0.054$ (s.e. $0.020$) and single-best at $-0.060$ (s.e. $0.018$); the stacking weights load almost entirely on the three XGBoost specifications, so when XGBoost dominates the linear alternatives — as it does here — stacking inherits its performance for free. We do not run short-stacking in `blog3_robust.R`; the full pipeline lives in `Code/dube_monopsony/`.

### 2.3 Cluster-respecting vs IID folds

<div id="tbl-folds">

Table 4: Baseline (recruiter-honest folds, cluster-robust SE) vs. IID folds with het-robust SE. Both columns are median-of-medians over S = 5 seeds; K = 3; XGBoost.
<!-- preamble start -->
&#10;    <script src="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.js"></script>
&#10;    <script>
      // Create table-specific functions using external factory
      const tableFns_bljljxrhpd2s21hj6yjw = TinyTable.createTableFunctions("tinytable_bljljxrhpd2s21hj6yjw");
      // tinytable span after
      window.addEventListener('load', function () {
          var cellsToStyle = [
            // tinytable style arrays after
          { positions: [ { i: '6', j: 2 }, { i: '6', j: 3 } ], css_id: 'tinytable_css_rqzkvp33uqym90uummpy',}, 
          { positions: [ { i: '2', j: 2 }, { i: '2', j: 3 } ], css_id: 'tinytable_css_4ducc0thl5yfyuwegmus',}, 
          { positions: [ { i: '1', j: 2 }, { i: '3', j: 2 }, { i: '4', j: 2 }, { i: '5', j: 2 }, { i: '1', j: 3 }, { i: '3', j: 3 }, { i: '4', j: 3 }, { i: '5', j: 3 } ], css_id: 'tinytable_css_nrq6im50n4tzztsu6ao6',}, 
          { positions: [ { i: '0', j: 2 }, { i: '0', j: 3 } ], css_id: 'tinytable_css_40h9vit5mjka7qm81328',}, 
          { positions: [ { i: '6', j: 1 } ], css_id: 'tinytable_css_tmo648citkeo2qzp8de6',}, 
          { positions: [ { i: '2', j: 1 } ], css_id: 'tinytable_css_4vrgl0wq7yjk9igbxbsx',}, 
          { positions: [ { i: '1', j: 1 }, { i: '3', j: 1 }, { i: '4', j: 1 }, { i: '5', j: 1 } ], css_id: 'tinytable_css_wetkgxvih2ya3t6irsjy',}, 
          { positions: [ { i: '0', j: 1 } ], css_id: 'tinytable_css_04004nht0w8mwqh7qn3q',}, 
          ];
&#10;          // Loop over the arrays to style the cells
          cellsToStyle.forEach(function (group) {
              group.positions.forEach(function (cell) {
                  tableFns_bljljxrhpd2s21hj6yjw.styleCell(cell.i, cell.j, group.css_id);
              });
          });
      });
    </script>
&#10;    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.css">
    <style>
    /* tinytable css entries after */
    #tinytable_bljljxrhpd2s21hj6yjw td.tinytable_css_rqzkvp33uqym90uummpy, #tinytable_bljljxrhpd2s21hj6yjw th.tinytable_css_rqzkvp33uqym90uummpy {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_bljljxrhpd2s21hj6yjw td.tinytable_css_4ducc0thl5yfyuwegmus, #tinytable_bljljxrhpd2s21hj6yjw th.tinytable_css_4ducc0thl5yfyuwegmus {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_bljljxrhpd2s21hj6yjw td.tinytable_css_nrq6im50n4tzztsu6ao6, #tinytable_bljljxrhpd2s21hj6yjw th.tinytable_css_nrq6im50n4tzztsu6ao6 { text-align: center }
    #tinytable_bljljxrhpd2s21hj6yjw td.tinytable_css_40h9vit5mjka7qm81328, #tinytable_bljljxrhpd2s21hj6yjw th.tinytable_css_40h9vit5mjka7qm81328 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_bljljxrhpd2s21hj6yjw td.tinytable_css_tmo648citkeo2qzp8de6, #tinytable_bljljxrhpd2s21hj6yjw th.tinytable_css_tmo648citkeo2qzp8de6 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_bljljxrhpd2s21hj6yjw td.tinytable_css_4vrgl0wq7yjk9igbxbsx, #tinytable_bljljxrhpd2s21hj6yjw th.tinytable_css_4vrgl0wq7yjk9igbxbsx {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_bljljxrhpd2s21hj6yjw td.tinytable_css_wetkgxvih2ya3t6irsjy, #tinytable_bljljxrhpd2s21hj6yjw th.tinytable_css_wetkgxvih2ya3t6irsjy { text-align: left }
    #tinytable_bljljxrhpd2s21hj6yjw td.tinytable_css_04004nht0w8mwqh7qn3q, #tinytable_bljljxrhpd2s21hj6yjw th.tinytable_css_04004nht0w8mwqh7qn3q {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    </style>
    <div class="container">
      <table class="tinytable" id="tinytable_bljljxrhpd2s21hj6yjw" style="width: auto; margin-left: auto; margin-right: auto;" data-quarto-disable-processing='true'>
        &#10;        <thead>
              <tr>
                <th scope="col" data-row="0" data-col="1"> </th>
                <th scope="col" data-row="0" data-col="2">Baseline (K=3, XGB, cluster)</th>
                <th scope="col" data-row="0" data-col="3">K=3, XGB, IID folds</th>
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
                  <td data-row="2" data-col="2">(0.024)</td>
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
                  <td data-row="5" data-col="2">0.859</td>
                  <td data-row="5" data-col="3">0.893</td>
                </tr>
                <tr>
                  <td data-row="6" data-col="1">R²(D|X)</td>
                  <td data-row="6" data-col="2">0.738</td>
                  <td data-row="6" data-col="3">0.881</td>
                </tr>
        </tbody>
      </table>
    </div>
<!-- hack to avoid NA insertion in last line -->

</div>

This is the sweep where leaving the default behind is the point. The Ipeirotis cross-section has many postings per recruiter, and the same recruiter’s HITs share unobserved features (recruiter style, payout norms, qualification preferences) that correlate with both posted reward and fill time. Splitting at the observation level lets siblings from the same recruiter sit on both sides of the fold boundary — which makes the residuals look more independent than they are, and the cross-fitted $R^2$ look better than the true generalisation $R^2$. In `ddml_plm` the lever is whether `cluster_variable` is supplied; passing the recruiter id forms recruiter-honest folds and clusters SEs at the same level; omitting it gives random IID folds and uses heteroskedasticity-robust SEs:

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

The cross-fitted $R^2$ values typically *fall* when fold construction moves from IID to recruiter-honest, because the held-out fold now contains recruiters the nuisance learner never saw — that is the honest predictive performance and it is what should enter the DDML score. The standard error typically *rises*, because clustering at the recruiter level accounts for the correlated residuals that het-robust ignores. Footnote 19 of the review paper, which points to an online-appendix table comparing the two, makes the same point: the cluster-honest combination is the inference-bearing one for this application, which is why Entries 1–2 and the baseline of this post use it as their default.

## 3. What to take away

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
