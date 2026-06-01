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

*Part 3 of a three-post series. <a href="{{ '/examples/Monopsony_DML' | relative_url }}">Part 1</a> ran DDML on the Dube et al. (2020) MTurk data with hand-coded controls only. <a href="{{ '/examples/Monopsony_Finetune' | relative_url }}">Part 2</a> added fine-tuned DeBERTa embeddings. This final post refines and validates the DDML specification.*

In Part 2, we considered a particular DDML specification with $K=3$ cross-fitting folds, randomly split by recruiter, and XGBoost (using 800 trees, a minimum node size of 500, early stopping) as the nuisance learner. This final part illustrates how to refine the DDML specification and highlights sensible validation checks.

## Multi-seed median aggregation (XGBoost)

A single randomization seed generates one random partition of the sample into folds. Asymptotically the exact partition does not matter; in finite samples, however, it can make a noticeable difference.

The table below repeats the random fold splitting and DDML estimation five times, using five different seeds. The per-seed estimates span a non-trivial range, so sample-split randomness has a noticeable impact in finite samples.

<div id="tbl-multiseed-xgb">

Table 1: Per-seed estimates and median-aggregated estimates for the baseline specification.
<!-- preamble start -->
&#10;    <script src="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.js"></script>
&#10;    <script>
      // Create table-specific functions using external factory
      const tableFns_y2hnvt6wl2tiqyupykk7 = TinyTable.createTableFunctions("tinytable_y2hnvt6wl2tiqyupykk7");
      // tinytable span after
      window.addEventListener('load', function () {
          var cellsToStyle = [
            // tinytable style arrays after
          { positions: [ { i: '9', j: 2 }, { i: '9', j: 3 }, { i: '9', j: 4 }, { i: '9', j: 5 }, { i: '9', j: 6 }, { i: '9', j: 7 } ], css_id: 'tinytable_css_t29sm0m4g794zg7je8kx',}, 
          { positions: [ { i: '2', j: 2 }, { i: '2', j: 3 }, { i: '2', j: 4 }, { i: '2', j: 5 }, { i: '2', j: 6 }, { i: '2', j: 7 } ], css_id: 'tinytable_css_5xgl6adm8djeusje1dlx',}, 
          { positions: [ { i: '1', j: 2 }, { i: '3', j: 2 }, { i: '4', j: 2 }, { i: '5', j: 2 }, { i: '6', j: 2 }, { i: '7', j: 2 }, { i: '8', j: 2 }, { i: '1', j: 3 }, { i: '3', j: 3 }, { i: '4', j: 3 }, { i: '5', j: 3 }, { i: '6', j: 3 }, { i: '7', j: 3 }, { i: '8', j: 3 }, { i: '1', j: 4 }, { i: '3', j: 4 }, { i: '4', j: 4 }, { i: '5', j: 4 }, { i: '6', j: 4 }, { i: '7', j: 4 }, { i: '8', j: 4 }, { i: '1', j: 5 }, { i: '3', j: 5 }, { i: '4', j: 5 }, { i: '5', j: 5 }, { i: '6', j: 5 }, { i: '7', j: 5 }, { i: '8', j: 5 }, { i: '1', j: 6 }, { i: '3', j: 6 }, { i: '4', j: 6 }, { i: '5', j: 6 }, { i: '6', j: 6 }, { i: '7', j: 6 }, { i: '8', j: 6 }, { i: '1', j: 7 }, { i: '3', j: 7 }, { i: '4', j: 7 }, { i: '5', j: 7 }, { i: '6', j: 7 }, { i: '7', j: 7 }, { i: '8', j: 7 } ], css_id: 'tinytable_css_al4v9ri5xkab1n1kpvfg',}, 
          { positions: [ { i: '0', j: 2 }, { i: '0', j: 3 }, { i: '0', j: 4 }, { i: '0', j: 5 }, { i: '0', j: 6 }, { i: '0', j: 7 } ], css_id: 'tinytable_css_d0g36p59d5a2rkl996ay',}, 
          { positions: [ { i: '9', j: 1 } ], css_id: 'tinytable_css_9v8pcq6elqrbxz3jymx7',}, 
          { positions: [ { i: '2', j: 1 } ], css_id: 'tinytable_css_62jlrpmpg2kt0kaizsa1',}, 
          { positions: [ { i: '1', j: 1 }, { i: '3', j: 1 }, { i: '4', j: 1 }, { i: '5', j: 1 }, { i: '6', j: 1 }, { i: '7', j: 1 }, { i: '8', j: 1 } ], css_id: 'tinytable_css_83vyv8mamuc68nlzyqog',}, 
          { positions: [ { i: '0', j: 1 } ], css_id: 'tinytable_css_8jobqwcl5otdnk2tdjzr',}, 
          ];
&#10;          // Loop over the arrays to style the cells
          cellsToStyle.forEach(function (group) {
              group.positions.forEach(function (cell) {
                  tableFns_y2hnvt6wl2tiqyupykk7.styleCell(cell.i, cell.j, group.css_id);
              });
          });
      });
    </script>
&#10;    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.css">
    <style>
    /* tinytable css entries after */
    #tinytable_y2hnvt6wl2tiqyupykk7 td.tinytable_css_t29sm0m4g794zg7je8kx, #tinytable_y2hnvt6wl2tiqyupykk7 th.tinytable_css_t29sm0m4g794zg7je8kx {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_y2hnvt6wl2tiqyupykk7 td.tinytable_css_5xgl6adm8djeusje1dlx, #tinytable_y2hnvt6wl2tiqyupykk7 th.tinytable_css_5xgl6adm8djeusje1dlx {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_y2hnvt6wl2tiqyupykk7 td.tinytable_css_al4v9ri5xkab1n1kpvfg, #tinytable_y2hnvt6wl2tiqyupykk7 th.tinytable_css_al4v9ri5xkab1n1kpvfg { text-align: center }
    #tinytable_y2hnvt6wl2tiqyupykk7 td.tinytable_css_d0g36p59d5a2rkl996ay, #tinytable_y2hnvt6wl2tiqyupykk7 th.tinytable_css_d0g36p59d5a2rkl996ay {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_y2hnvt6wl2tiqyupykk7 td.tinytable_css_9v8pcq6elqrbxz3jymx7, #tinytable_y2hnvt6wl2tiqyupykk7 th.tinytable_css_9v8pcq6elqrbxz3jymx7 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_y2hnvt6wl2tiqyupykk7 td.tinytable_css_62jlrpmpg2kt0kaizsa1, #tinytable_y2hnvt6wl2tiqyupykk7 th.tinytable_css_62jlrpmpg2kt0kaizsa1 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_y2hnvt6wl2tiqyupykk7 td.tinytable_css_83vyv8mamuc68nlzyqog, #tinytable_y2hnvt6wl2tiqyupykk7 th.tinytable_css_83vyv8mamuc68nlzyqog { text-align: left }
    #tinytable_y2hnvt6wl2tiqyupykk7 td.tinytable_css_8jobqwcl5otdnk2tdjzr, #tinytable_y2hnvt6wl2tiqyupykk7 th.tinytable_css_8jobqwcl5otdnk2tdjzr {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    </style>
    <div class="container">
      <table class="tinytable" id="tinytable_y2hnvt6wl2tiqyupykk7" style="width: auto; margin-left: auto; margin-right: auto;" data-quarto-disable-processing='true'>
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

The rationale for reporting an aggregated estimate (shown above in the last column) is that it provides an intuitive summary of DDML estimates that is less susceptible to particular random draws.

### Fold-clustering by recruiter or by observation

In the Ipeirotis data, some recruiters have many postings. The same recruiter’s postings may share unobserved features that correlate with both posted reward and duration until acceptance.

The table below investigates the impact of random fold construction by recruiter versus by observation on the DDML estimate and its standard error:

<div id="tbl-S2-folds">

Table 2: Table S.2 replica. Recruiter-honest folds with cluster-robust SE vs. IID folds. Both columns are median-of-medians over S = 5 seeds; K = 3; XGB 3 nuisance learner.
<!-- preamble start -->
&#10;    <script src="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.js"></script>
&#10;    <script>
      // Create table-specific functions using external factory
      const tableFns_1e62ggzt0t2cwhhvhx39 = TinyTable.createTableFunctions("tinytable_1e62ggzt0t2cwhhvhx39");
      // tinytable span after
      window.addEventListener('load', function () {
          var cellsToStyle = [
            // tinytable style arrays after
          { positions: [ { i: '6', j: 2 }, { i: '6', j: 3 } ], css_id: 'tinytable_css_wjl6lvkbr3p7fxkwel72',}, 
          { positions: [ { i: '2', j: 2 }, { i: '2', j: 3 } ], css_id: 'tinytable_css_i3bgulzi0fhstbyjzdcl',}, 
          { positions: [ { i: '1', j: 2 }, { i: '3', j: 2 }, { i: '4', j: 2 }, { i: '5', j: 2 }, { i: '1', j: 3 }, { i: '3', j: 3 }, { i: '4', j: 3 }, { i: '5', j: 3 } ], css_id: 'tinytable_css_lw0z302wuj04msc7nzhu',}, 
          { positions: [ { i: '0', j: 2 }, { i: '0', j: 3 } ], css_id: 'tinytable_css_idsdo2yg03l3v7q3uvwr',}, 
          { positions: [ { i: '6', j: 1 } ], css_id: 'tinytable_css_d427b0xy2noyoo8hzqyn',}, 
          { positions: [ { i: '2', j: 1 } ], css_id: 'tinytable_css_gs91vvikmhwtzmn9rg5h',}, 
          { positions: [ { i: '1', j: 1 }, { i: '3', j: 1 }, { i: '4', j: 1 }, { i: '5', j: 1 } ], css_id: 'tinytable_css_f3vjha64up0bau2hn4ry',}, 
          { positions: [ { i: '0', j: 1 } ], css_id: 'tinytable_css_820f3nq44k6vcnvoavax',}, 
          ];
&#10;          // Loop over the arrays to style the cells
          cellsToStyle.forEach(function (group) {
              group.positions.forEach(function (cell) {
                  tableFns_1e62ggzt0t2cwhhvhx39.styleCell(cell.i, cell.j, group.css_id);
              });
          });
      });
    </script>
&#10;    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.css">
    <style>
    /* tinytable css entries after */
    #tinytable_1e62ggzt0t2cwhhvhx39 td.tinytable_css_wjl6lvkbr3p7fxkwel72, #tinytable_1e62ggzt0t2cwhhvhx39 th.tinytable_css_wjl6lvkbr3p7fxkwel72 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_1e62ggzt0t2cwhhvhx39 td.tinytable_css_i3bgulzi0fhstbyjzdcl, #tinytable_1e62ggzt0t2cwhhvhx39 th.tinytable_css_i3bgulzi0fhstbyjzdcl {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_1e62ggzt0t2cwhhvhx39 td.tinytable_css_lw0z302wuj04msc7nzhu, #tinytable_1e62ggzt0t2cwhhvhx39 th.tinytable_css_lw0z302wuj04msc7nzhu { text-align: center }
    #tinytable_1e62ggzt0t2cwhhvhx39 td.tinytable_css_idsdo2yg03l3v7q3uvwr, #tinytable_1e62ggzt0t2cwhhvhx39 th.tinytable_css_idsdo2yg03l3v7q3uvwr {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_1e62ggzt0t2cwhhvhx39 td.tinytable_css_d427b0xy2noyoo8hzqyn, #tinytable_1e62ggzt0t2cwhhvhx39 th.tinytable_css_d427b0xy2noyoo8hzqyn {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_1e62ggzt0t2cwhhvhx39 td.tinytable_css_gs91vvikmhwtzmn9rg5h, #tinytable_1e62ggzt0t2cwhhvhx39 th.tinytable_css_gs91vvikmhwtzmn9rg5h {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_1e62ggzt0t2cwhhvhx39 td.tinytable_css_f3vjha64up0bau2hn4ry, #tinytable_1e62ggzt0t2cwhhvhx39 th.tinytable_css_f3vjha64up0bau2hn4ry { text-align: left }
    #tinytable_1e62ggzt0t2cwhhvhx39 td.tinytable_css_820f3nq44k6vcnvoavax, #tinytable_1e62ggzt0t2cwhhvhx39 th.tinytable_css_820f3nq44k6vcnvoavax {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    </style>
    <div class="container">
      <table class="tinytable" id="tinytable_1e62ggzt0t2cwhhvhx39" style="width: auto; margin-left: auto; margin-right: auto;" data-quarto-disable-processing='true'>
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

We find that the cross-fitted $R^2$ values drop noticeably when moving from IID to recruiter folds. The likely reason is that splitting at the observation level lets postings from the same recruiter appear in different folds, making out-of-sample predictions look more precise than they are. This in turn might bias the DDML estimates. To avoid this, **we recommend forming folds that acknowledge the dependence structure of the data**.

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
      const tableFns_obgop859n037s1oo7m67 = TinyTable.createTableFunctions("tinytable_obgop859n037s1oo7m67");
      // tinytable span after
      window.addEventListener('load', function () {
          var cellsToStyle = [
            // tinytable style arrays after
          { positions: [ { i: '6', j: 2 }, { i: '6', j: 3 } ], css_id: 'tinytable_css_pnfdfmrpq57l9cbiq5nm',}, 
          { positions: [ { i: '2', j: 2 }, { i: '2', j: 3 } ], css_id: 'tinytable_css_21ndwbbirktrj7cmo56b',}, 
          { positions: [ { i: '1', j: 2 }, { i: '3', j: 2 }, { i: '4', j: 2 }, { i: '5', j: 2 }, { i: '1', j: 3 }, { i: '3', j: 3 }, { i: '4', j: 3 }, { i: '5', j: 3 } ], css_id: 'tinytable_css_86qqjjk1ecgwxgvw1n05',}, 
          { positions: [ { i: '0', j: 2 }, { i: '0', j: 3 } ], css_id: 'tinytable_css_xt4jy1p58vdwpwarjhpt',}, 
          { positions: [ { i: '6', j: 1 } ], css_id: 'tinytable_css_7s3txrvtp1f4j6lsxwrn',}, 
          { positions: [ { i: '2', j: 1 } ], css_id: 'tinytable_css_4h5ynewiag7xvkc8jlmf',}, 
          { positions: [ { i: '1', j: 1 }, { i: '3', j: 1 }, { i: '4', j: 1 }, { i: '5', j: 1 } ], css_id: 'tinytable_css_wsfmyaex1f0e98avas51',}, 
          { positions: [ { i: '0', j: 1 } ], css_id: 'tinytable_css_qt9mlxgucpou39jns1kx',}, 
          ];
&#10;          // Loop over the arrays to style the cells
          cellsToStyle.forEach(function (group) {
              group.positions.forEach(function (cell) {
                  tableFns_obgop859n037s1oo7m67.styleCell(cell.i, cell.j, group.css_id);
              });
          });
      });
    </script>
&#10;    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.css">
    <style>
    /* tinytable css entries after */
    #tinytable_obgop859n037s1oo7m67 td.tinytable_css_pnfdfmrpq57l9cbiq5nm, #tinytable_obgop859n037s1oo7m67 th.tinytable_css_pnfdfmrpq57l9cbiq5nm {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_obgop859n037s1oo7m67 td.tinytable_css_21ndwbbirktrj7cmo56b, #tinytable_obgop859n037s1oo7m67 th.tinytable_css_21ndwbbirktrj7cmo56b {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_obgop859n037s1oo7m67 td.tinytable_css_86qqjjk1ecgwxgvw1n05, #tinytable_obgop859n037s1oo7m67 th.tinytable_css_86qqjjk1ecgwxgvw1n05 { text-align: center }
    #tinytable_obgop859n037s1oo7m67 td.tinytable_css_xt4jy1p58vdwpwarjhpt, #tinytable_obgop859n037s1oo7m67 th.tinytable_css_xt4jy1p58vdwpwarjhpt {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_obgop859n037s1oo7m67 td.tinytable_css_7s3txrvtp1f4j6lsxwrn, #tinytable_obgop859n037s1oo7m67 th.tinytable_css_7s3txrvtp1f4j6lsxwrn {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_obgop859n037s1oo7m67 td.tinytable_css_4h5ynewiag7xvkc8jlmf, #tinytable_obgop859n037s1oo7m67 th.tinytable_css_4h5ynewiag7xvkc8jlmf {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_obgop859n037s1oo7m67 td.tinytable_css_wsfmyaex1f0e98avas51, #tinytable_obgop859n037s1oo7m67 th.tinytable_css_wsfmyaex1f0e98avas51 { text-align: left }
    #tinytable_obgop859n037s1oo7m67 td.tinytable_css_qt9mlxgucpou39jns1kx, #tinytable_obgop859n037s1oo7m67 th.tinytable_css_qt9mlxgucpou39jns1kx {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    </style>
    <div class="container">
      <table class="tinytable" id="tinytable_obgop859n037s1oo7m67" style="width: auto; margin-left: auto; margin-right: auto;" data-quarto-disable-processing='true'>
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

The choice of nuisance function estimator is consequential for DDML estimation. Poorly chosen or poorly tuned learners can yield misleading DDML point estimates because the residual-on-residual regression then absorbs leftover signal that should have been partialed out. As an example, below we compare the baseline `XGB 3` specification against `CV-Lasso` (learner index 2), both median-aggregated over $S = 5$ seeds using the same recruiter-honest fold structure:

<div id="tbl-xgb-vs-lasso">

Table 4: XGB 3 vs. CV-Lasso, both median-aggregated over S = 5 seeds. K = 3 recruiter-honest folds; cluster-robust SE.
<!-- preamble start -->
&#10;    <script src="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.js"></script>
&#10;    <script>
      // Create table-specific functions using external factory
      const tableFns_2x5jntabb0sjbv1zwfug = TinyTable.createTableFunctions("tinytable_2x5jntabb0sjbv1zwfug");
      // tinytable span after
      window.addEventListener('load', function () {
          var cellsToStyle = [
            // tinytable style arrays after
          { positions: [ { i: '6', j: 2 }, { i: '6', j: 3 } ], css_id: 'tinytable_css_r56epl3mu3f7bwrk9fsp',}, 
          { positions: [ { i: '2', j: 2 }, { i: '2', j: 3 } ], css_id: 'tinytable_css_8gabeppeqnji2nore99u',}, 
          { positions: [ { i: '1', j: 2 }, { i: '3', j: 2 }, { i: '4', j: 2 }, { i: '5', j: 2 }, { i: '1', j: 3 }, { i: '3', j: 3 }, { i: '4', j: 3 }, { i: '5', j: 3 } ], css_id: 'tinytable_css_xbc77rghckbw36n4wsc3',}, 
          { positions: [ { i: '0', j: 2 }, { i: '0', j: 3 } ], css_id: 'tinytable_css_yly7fkycm2ef3b9ylahi',}, 
          { positions: [ { i: '6', j: 1 } ], css_id: 'tinytable_css_xjzruq48krtmc42z0b6t',}, 
          { positions: [ { i: '2', j: 1 } ], css_id: 'tinytable_css_7cu9ifwytyu0vdizoilf',}, 
          { positions: [ { i: '1', j: 1 }, { i: '3', j: 1 }, { i: '4', j: 1 }, { i: '5', j: 1 } ], css_id: 'tinytable_css_rlmzur177ckcfsiskopj',}, 
          { positions: [ { i: '0', j: 1 } ], css_id: 'tinytable_css_jxd4f7wzbytd4gbvbtfi',}, 
          ];
&#10;          // Loop over the arrays to style the cells
          cellsToStyle.forEach(function (group) {
              group.positions.forEach(function (cell) {
                  tableFns_2x5jntabb0sjbv1zwfug.styleCell(cell.i, cell.j, group.css_id);
              });
          });
      });
    </script>
&#10;    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.css">
    <style>
    /* tinytable css entries after */
    #tinytable_2x5jntabb0sjbv1zwfug td.tinytable_css_r56epl3mu3f7bwrk9fsp, #tinytable_2x5jntabb0sjbv1zwfug th.tinytable_css_r56epl3mu3f7bwrk9fsp {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_2x5jntabb0sjbv1zwfug td.tinytable_css_8gabeppeqnji2nore99u, #tinytable_2x5jntabb0sjbv1zwfug th.tinytable_css_8gabeppeqnji2nore99u {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_2x5jntabb0sjbv1zwfug td.tinytable_css_xbc77rghckbw36n4wsc3, #tinytable_2x5jntabb0sjbv1zwfug th.tinytable_css_xbc77rghckbw36n4wsc3 { text-align: center }
    #tinytable_2x5jntabb0sjbv1zwfug td.tinytable_css_yly7fkycm2ef3b9ylahi, #tinytable_2x5jntabb0sjbv1zwfug th.tinytable_css_yly7fkycm2ef3b9ylahi {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_2x5jntabb0sjbv1zwfug td.tinytable_css_xjzruq48krtmc42z0b6t, #tinytable_2x5jntabb0sjbv1zwfug th.tinytable_css_xjzruq48krtmc42z0b6t {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_2x5jntabb0sjbv1zwfug td.tinytable_css_7cu9ifwytyu0vdizoilf, #tinytable_2x5jntabb0sjbv1zwfug th.tinytable_css_7cu9ifwytyu0vdizoilf {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_2x5jntabb0sjbv1zwfug td.tinytable_css_rlmzur177ckcfsiskopj, #tinytable_2x5jntabb0sjbv1zwfug th.tinytable_css_rlmzur177ckcfsiskopj { text-align: left }
    #tinytable_2x5jntabb0sjbv1zwfug td.tinytable_css_jxd4f7wzbytd4gbvbtfi, #tinytable_2x5jntabb0sjbv1zwfug th.tinytable_css_jxd4f7wzbytd4gbvbtfi {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    </style>
    <div class="container">
      <table class="tinytable" id="tinytable_2x5jntabb0sjbv1zwfug" style="width: auto; margin-left: auto; margin-right: auto;" data-quarto-disable-processing='true'>
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

Table 6 from the paper reports the stacked DDML result: $\hat\theta_0 \approx -0.054$ with $\mathrm{s.e.} = 0.020$. The stacking weights (shown in Table 5 of the paper) load almost entirely on the three XGBoost specifications.

## What to take away

Before reporting DDML results, it is essential to validate the nuisance function estimators and to question their performance. Other important implementation choices include the number of cross-fitting folds, the fold splitting scheme, and the aggregation method.

## References

- Ahrens, A., V. Chernozhukov, C. Hansen, D. Kozbur, M. Schaffer and T. Wiemann. *An Introduction to Double/Debiased Machine Learning.* §5 (median aggregation), §6 (Dube application, Tables 5–6), §7 (implementation guidance).
- Ahrens, A., C. B. Hansen, M. E. Schaffer and T. Wiemann (2024). [`ddml`: Double/debiased machine learning in R.](https://doi.org/10.18637/jss.v108.i03)
- Chernozhukov, V., D. Chetverikov, M. Demirer, E. Duflo, C. Hansen, W. Newey and J. Robins (2018). [Double/Debiased machine learning for treatment and structural parameters.](https://doi.org/10.1111/ectj.12097)
- Dube, A., J. Jacobs, S. Naidu and S. Suri (2020). [Monopsony in online labor markets.](https://doi.org/10.3386/w26108) *AER: Insights* 2 (1).
- Lei, J. (2020). Cross-validation with confidence. *Journal of the American Statistical Association.*
- Velez, A. (2024). On the asymptotic properties of debiased machine learning estimators.
