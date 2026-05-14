---
layout: default
title: Monopsony II — DDML with fine-tuned embeddings
parent: Examples
nav_order: 35
math: true
description: "Adding fine-tuned DeBERTa embeddings of the HIT text to the DDML control set."
permalink: /examples/Monopsony_Finetune
enable_copy_code_button: true
---

# Monopsony II — fine-tuned text embeddings as DDML controls

*Part 2 of a three-post series. Part 1 estimated the partially linear coefficient with hand-coded controls only. This post appends the fine-tuned DeBERTa embedding of each HIT’s title and description, and re-runs the same cross-fit.*

The model is exactly the one from \[Monopsony I\]({{ ‘/examples/Monopsony_DML’ \| relative_url }}):

$$\log(\text{duration}_i) \;=\; \theta_0 \cdot \log(\text{reward}_i) \;+\; g_0(X_i) \;+\; \varepsilon_i,
\qquad E[\varepsilon_i \mid X_i, D_i] = 0.$$

Only $X_i$ changes. We append the hand-engineered controls with a 768-dimensional vector per HIT, retrieved from a DeBERTa-v3 language model that has been fine-tuned to our setting.

In this part, we discuss two things: First, we explain what embeddings are, how fine-tuning works and we describe our specific implementation choices. Second, we explain how the fine-tuning process is integrated into the DDML algorithm.

## 1. Fine-tuning, in the version we need

### Embeddings and choice of language model

An embedding is a fixed-length vector representation of a string, retrieved from a language model such as a transformer. The appeal of using embeddings over hand-engineered features is obvious: The tasks “transcribe 20 audio clips” versus “label sentiment in 100 tweets” differ in cognitive load, reading time, and recruiter conventions in ways that ad-hoc engineered features may fail to capture.

We specifically use the `[CLS]` token from DeBERTa-v3-base which gives us a 768-dimensional vector. We opt here for DeBERTa-v3-base because it is a small bi-directional encoder model that allows us to retrieve embeddings at low cost and fine-tune these to our specific context. Bi-directional here means that the `[CLS]` token can aggregate information from the entire sequence into a single vector.

An alternative option is larger reasoning models such as Qwen3 or Gemini. They benefit from substantially more pretraining data and tend to produce stronger representations when there is limited training data and on tasks requiring nuanced reasoning. However, even the smallest Qwen3 embedding variant has roughly an order of magnitude more parameters than DeBERTa-v3-base, making both fine-tuning and inference markedly more expensive. In our setting, as we describe below, we need to repeat the fine-tuning process for each fold and outcome, making considerations about computational cost more important.

### How to fine-tune

A pretrained language model is trained on a generic corpus with a generic objective. Fine-tuning adapts the model parameters using contextual data. The language model acts as a backbone on which a small head is placed. In our context, we separately use the log reward and log duration as outcomes and link these to the text via a tokenizer (which converts strings to indices), a backbone language model (DeBERTa) and a regression head (linear regression). The loss metric is the mean-squared error. After fine-tuning, the regression head is discarded and only the embeddings are retrieved, which are used as inputs for a downstream machine learner.

### LoRA, not full fine-tuning

Full fine-tuning would update all 184M DeBERTa parameters. In total, we have to perform $2K \cdot S$ fine-tuning operations where $K=$ number of folds, $S=$ number of cross-fitting repetitions, and two outcomes. To further limit the computational complexity, we use Low-Rank Adaptation ([Hu et al., 2021](https://arxiv.org/abs/2106.09685)) instead of full fine tuning. LoRA freezes the pretrained weight matrices $W$ and inserts trainable rank-$r$ updates $BA$ into the attention projections:

$$W_{\text{adapted}} \;=\; W_{\text{frozen}} \;+\; \underbrace{B A}_{\text{trainable, rank } r},
\qquad B \in \mathbb{R}^{d \times r}, \; A \in \mathbb{R}^{r \times d}, \; r \ll d.$$

With $r=16$ applied to the query, key, value, and dense projections, roughly $10^5$ parameters move per fine-tune — three orders of magnitude fewer than full fine-tuning. The empirical pattern is the usual one: training is much faster, overfitting on a moderate sample is materially less of a concern, and downstream cross-fitted $R^2$ values are essentially indistinguishable from full fine-tuning at our sample size.

### Fine-tuning implementation details

The input is the concatenation of HIT title and description, tokenised by DeBERTa’s own SentencePiece tokeniser and truncated to 160 tokens. We train with the AdamW optimiser at learning rate $2 \times 10^{-4}$ (LoRA needs a higher LR than full fine-tuning because only the low-rank factors move), batch size 32, for three epochs.

### Integrating fine-tuning into DDML

A naive approach might proceed as follows: using the full sample, fine-tune DeBERTa separately on log reward and log duration, retrieve the fine-tuned embeddings, and use these as inputs along with hand-coded controls in the cross-fitting process. This approach, however, would produce predicted values that are not pure “out-of-sample” as the embeddings are estimated using in-sample outcomes.

For the estimation process to remain “leak-free”, we move the fine-tuning step inside the cross-fitting loop. The figure below walks through the procedure. We do this twice — once with $y = \log(\text{reward})$, once with $y = \log(\text{duration})$ — because each nuisance equation gets its own fine-tuned embeddings. Within each, we run a standard $K$-fold cross-fit: for every held-out fold $k$, the backbone is trained on the other $K-1$ folds only, its embeddings are concatenated with the hand-coded controls, and the downstream learner is fit on the training folds and used to predict on fold $k$. The embedding for any observation in fold $k$ therefore never saw $k$’s own outcome — that is what keeps the cross-fitted predictions honest.

<figure style="text-align: center; margin: 1.2em 0;">
  <img src="{{ '/assets/images/monopsony/crossfit_algorithm.png' | relative_url }}"
       alt="Cross-fit with fold-honest fine-tuning."
       style="max-width: 92%; height: auto;">
  <figcaption style="margin-top: 0.6em; color: #555; font-size: 0.85em; line-height: 1.45; text-align: left; max-width: 92%; margin-left: auto; margin-right: auto;">
    <strong>Notes.</strong>
    The procedure is repeated for both nuisance equations,
    <em>y</em> = log(reward) and <em>y</em> = log(duration).
    <em>K</em> is the number of cross-fitting folds (<em>K</em> = 3 in this post).
    For each fold <em>k</em>, the training sample is the <em>K&minus;1</em> remaining folds.
    "Fine-tune the DeBERTa backbone" refers to the LoRA process defined below; 
    the linear regression head is then discarded
    and the adapted backbone is used to retrieve a 768-dimensional embedding vector
    <em>e<sub>i</sub></em> for every observation, including those in fold <em>k</em>.
    The downstream ML learner is fit on the training sample only, and its predictions
    <em>&#375;<sub>i</sub></em> on fold <em>k</em> are the cross-fitted nuisance values
    that enter the partially linear residual regression.
  </figcaption>
</figure>

## Implementation of DML

For practical reasons, we perform the fine-tuning step in Python (saving the embeddings for each $k$, outcome and seed), but the downstream nuisance function estimation and structural parameter estimation in R. The code below illustrates the implementation in R for log duration (the code for log reward is analogous):

``` r
# retrieve fine-tuned embeddings
embed <- get_embeddings(seed = seed, k = k, foldnum = K,
                          var = "log_duration")
# column-bind hand-coded controls and embeddings
dat <- dat |> left_join(y_embed |> select(starts_with("feat_"), row_id),
                       by = c("id" = "row_id"))

# define training sample index
train_id <- dat$fid != k

# convert to matrix
X <- dat |> select(log_duration,
                     time_allotted:appr_num_gt1000p,
                     starts_with("feat_")
                     ) |>
              as.matrix()

# nuisance function estimation (here XGBoost)
fit <- mdl_xgboost( y = X[train_id, 1],
                    X = X[train_id, -1],
                    nrounds = 800, min_child_weight = 500,
                    eval_set = 0.1, early_stopping_rounds = 10)

# out-of-sample predicted values
hat <- predict(fit, newdata = X[!train_id, -1])
```

Above, we use XGBoost as the nuisance function estimator.

The partial linear regression coefficient is then estimated using OLS (with cluster-robust standard errors):

``` r
fit_ols <- feols(resid_log_duration ~ resid_log_reward,
                  data = out,
                  cluster = ~ requester_id)
```

## 4. Result

<div id="tbl-result">

Table 1: Coefficient on log(reward). Cluster-robust SE by requester_id in parentheses; cross-fitted R² reported.
<!-- preamble start -->
&#10;    <script src="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.js"></script>
&#10;    <script>
      // Create table-specific functions using external factory
      const tableFns_ef45azpldv6nwc14dkyl = TinyTable.createTableFunctions("tinytable_ef45azpldv6nwc14dkyl");
      // tinytable span after
      window.addEventListener('load', function () {
          var cellsToStyle = [
            // tinytable style arrays after
          { positions: [ { i: '6', j: 2 } ], css_id: 'tinytable_css_c7gustoac7grrh5dojp1',}, 
          { positions: [ { i: '2', j: 2 } ], css_id: 'tinytable_css_1yjnar1yeqqozsu0llt7',}, 
          { positions: [ { i: '1', j: 2 }, { i: '3', j: 2 }, { i: '4', j: 2 }, { i: '5', j: 2 } ], css_id: 'tinytable_css_lfvoh1cv25b1xysczsda',}, 
          { positions: [ { i: '0', j: 2 } ], css_id: 'tinytable_css_3ooibevvgn37xh0cuyg3',}, 
          { positions: [ { i: '6', j: 1 } ], css_id: 'tinytable_css_ulawteiwyuhfd716x26p',}, 
          { positions: [ { i: '2', j: 1 } ], css_id: 'tinytable_css_ia3n0rxqo0xdahptvlyd',}, 
          { positions: [ { i: '1', j: 1 }, { i: '3', j: 1 }, { i: '4', j: 1 }, { i: '5', j: 1 } ], css_id: 'tinytable_css_sd52cm9qsqyzn38b4qog',}, 
          { positions: [ { i: '0', j: 1 } ], css_id: 'tinytable_css_qbtr4zmzwclngxp8fr0o',}, 
          ];
&#10;          // Loop over the arrays to style the cells
          cellsToStyle.forEach(function (group) {
              group.positions.forEach(function (cell) {
                  tableFns_ef45azpldv6nwc14dkyl.styleCell(cell.i, cell.j, group.css_id);
              });
          });
      });
    </script>
&#10;    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/vincentarelbundock/tinytable@main/inst/tinytable.css">
    <style>
    /* tinytable css entries after */
    #tinytable_ef45azpldv6nwc14dkyl td.tinytable_css_c7gustoac7grrh5dojp1, #tinytable_ef45azpldv6nwc14dkyl th.tinytable_css_c7gustoac7grrh5dojp1 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_ef45azpldv6nwc14dkyl td.tinytable_css_1yjnar1yeqqozsu0llt7, #tinytable_ef45azpldv6nwc14dkyl th.tinytable_css_1yjnar1yeqqozsu0llt7 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_ef45azpldv6nwc14dkyl td.tinytable_css_lfvoh1cv25b1xysczsda, #tinytable_ef45azpldv6nwc14dkyl th.tinytable_css_lfvoh1cv25b1xysczsda { text-align: center }
    #tinytable_ef45azpldv6nwc14dkyl td.tinytable_css_3ooibevvgn37xh0cuyg3, #tinytable_ef45azpldv6nwc14dkyl th.tinytable_css_3ooibevvgn37xh0cuyg3 {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: center }
    #tinytable_ef45azpldv6nwc14dkyl td.tinytable_css_ulawteiwyuhfd716x26p, #tinytable_ef45azpldv6nwc14dkyl th.tinytable_css_ulawteiwyuhfd716x26p {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.08em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_ef45azpldv6nwc14dkyl td.tinytable_css_ia3n0rxqo0xdahptvlyd, #tinytable_ef45azpldv6nwc14dkyl th.tinytable_css_ia3n0rxqo0xdahptvlyd {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 0; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.1em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    #tinytable_ef45azpldv6nwc14dkyl td.tinytable_css_sd52cm9qsqyzn38b4qog, #tinytable_ef45azpldv6nwc14dkyl th.tinytable_css_sd52cm9qsqyzn38b4qog { text-align: left }
    #tinytable_ef45azpldv6nwc14dkyl td.tinytable_css_qbtr4zmzwclngxp8fr0o, #tinytable_ef45azpldv6nwc14dkyl th.tinytable_css_qbtr4zmzwclngxp8fr0o {  position: relative; --border-bottom: 1; --border-left: 0; --border-right: 0; --border-top: 1; --line-color-bottom: var(--tt-line-color); --line-color-left: var(--tt-line-color); --line-color-right: var(--tt-line-color); --line-color-top: var(--tt-line-color); --line-width-bottom: 0.05em; --line-width-left: 0.1em; --line-width-right: 0.1em; --line-width-top: 0.08em; --trim-bottom-left: 0%; --trim-bottom-right: 0%; --trim-left-bottom: 0%; --trim-left-top: 0%; --trim-right-bottom: 0%; --trim-right-top: 0%; --trim-top-left: 0%; --trim-top-right: 0%; ; text-align: left }
    </style>
    <div class="container">
      <table class="tinytable" id="tinytable_ef45azpldv6nwc14dkyl" style="width: auto; margin-left: auto; margin-right: auto;" data-quarto-disable-processing='true'>
        &#10;        <thead>
              <tr>
                <th scope="col" data-row="0" data-col="1"> </th>
                <th scope="col" data-row="0" data-col="2">Hand-coded + fine-tuned DeBERTa embeds</th>
              </tr>
        </thead>
        &#10;        <tbody>
                <tr>
                  <td data-row="1" data-col="1">log(reward)</td>
                  <td data-row="1" data-col="2">−0.066</td>
                </tr>
                <tr>
                  <td data-row="2" data-col="1"></td>
                  <td data-row="2" data-col="2">(0.015)</td>
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
                  <td data-row="5" data-col="2">0.867</td>
                </tr>
                <tr>
                  <td data-row="6" data-col="1">R²(D|X)</td>
                  <td data-row="6" data-col="2">0.754</td>
                </tr>
        </tbody>
      </table>
    </div>
<!-- hack to avoid NA insertion in last line -->

</div>

With the fine-tuned embeddings in $X$, the cross-fitted $R^2$ values both sit comfortably above 75%, and the cluster-robust standard error on $\hat\theta_0$ is tight enough for the point estimate to be unambiguously different from zero. $\hat\theta_0 \approx -0.066$ is in the same neighbourhood as column 9 of Table 5 (panel B) in the DDML paper. The two numbers do not coincide exactly: the blog uses a single cross-fitting seed, whereas column 9 of the paper is a *median-aggregated* estimate over $S = 5$ seeds, so a precise match would be a coincidence rather than the rule.

The third and final post, \[Monopsony III\]({{ ‘/examples/Monopsony_Robustness’ \| relative_url }}), takes up exactly this issue: how sensitive is the headline elasticity to the seed, the choice of nuisance learner, and the construction of the cross-fitting folds — and what does the multi-seed median-of-medians aggregation actually pin down for this dataset?

## 5. References

- Ahrens, A., V. Chernozhukov, C. Hansen, D. Kozbur, M. Schaffer and T. Wiemann. *An Introduction to Double/Debiased Machine Learning.* (Working paper, this site.) §6 motivates the fine-tuned-embedding approach used here.
- Dube, A., J. Jacobs, S. Naidu and S. Suri (2020). [Monopsony in online labor markets.](https://doi.org/10.3386/w26108) *AER: Insights* 2 (1).
- He, P., J. Gao and W. Chen (2023). [DeBERTa-v3.](https://arxiv.org/abs/2111.09543)
- Hu, E. J., Y. Shen, P. Wallis, Z. Allen-Zhu, Y. Li, S. Wang, L. Wang and W. Chen (2021). [LoRA: Low-Rank Adaptation of Large Language Models.](https://arxiv.org/abs/2106.09685)
- Ahrens, A., C. B. Hansen, M. E. Schaffer and T. Wiemann (2024). [`ddml`: Double/debiased machine learning in R.](https://doi.org/10.18637/jss.v108.i03)

Continue to \[**Monopsony III — robustness**\]({{ ‘/examples/Monopsony_Robustness’ \| relative_url }}).
