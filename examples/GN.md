---
layout: default
title: Understanding Cultural Persistence and Change 
parent: Examples
nav_order: 32
math: true
description: ""
permalink: /examples/GN
enable_copy_code_button: true
---

# Understanding Cultural Persistence and Change 

In this example, we illustrate DML estimation of the partially linear model using a simple empirical example. The application is drawn from [Giuliano and Nunn (2021, henceforth GN)](https://doi.org/10.1093/restud/rdaa074), who look at the relationship between climate instability and cultural persistence using a number of different datasets.

GN draw on evolutionary anthropology to argue that when the environment changes slowly across generations, traditions inherited from one's ancestors carry information that is still useful today, so societies place greater weight on maintaining them. When the environment is volatile, inherited customs are less reliable guides and tradition matters less. Using paleoclimatic temperature and drought data covering 500–1900 CE, GN construct a measure of *cross-generational climatic instability* — defined as the the standard deviation of 20-year climate averages across 70 generations — and link it to ancestral groups via their pre-industrial locations. 

## Estimation Strategy

Their first estimation strategy uses cross-country regressions where the dependent variable <span style="white-space: nowrap">($Y$)</span> is a measure of the importance of tradition taken from the World Values Survey, and the causal variable of interest <span style="white-space: nowrap">($D$)</span> is a measure of ancestral climatic instability. The dataset is quite small: only 74 countries.

The example is useful for illustrating how DML works for several reasons: the dataset is small and available online, visualization is easy, reproduction of results is straightforward, and the example shows how DML can be used as a robustness check even in the simplest of settings. The GN dataset used for this demonstration is available [here](https://dmlguide.github.io/assets/dta/GN2021.dta). 

GN are concerned about omitted confounders, and include 4 controls to address the issue.
The outcome, treatment and control variables are:

| Variable | Description |
| ----------- | ----------------|
| `A198new`	| The outcome variable of interest: country-level average of the self-reported importance of tradition. Ranges from 1 to 6 (bigger=more important). |
| `sd_EE` | The causal variable of interest: a measure of ancestral climatic instability (standard deviation of temperature anomaly measure across generations; see GN for details). |
| `v104_ee`	| Control #1: distance from the equator. | 
| `settlement_ee` | Control #2: early economic development (proxied by complexity of settlements). | 
| `polhierarchies_ee` | Control #3: political hierarchies (a measure of political centralization). | 
| `loggdp`| Control #4: log GDP per capita in the country of origin at the time of the survey. |

Their model with controls is one where the controls enter linearly and is estimated using OLS. The effect of climatic instability on the importance of tradition is negative, with a coefficient that is different from zero at conventional significance levels. 

## Replication

We start by reproducing GN's Figure 5 — a simple scatterplot of the bivariate relationship — and then add the four control variables to reproduce column (4).

GN's Figure 5 visualizes the unconditional relationship between climatic instability and the importance of tradition. The fitted line is the OLS coefficient from column (3): $-1.92$ <span style="white-space: nowrap">($s.e.=0.523$)</span>.

{% capture fig5_code_stata %}
```stata
{% include GN/fig5_code_stata.txt %}
```
{% endcapture %}

{% capture fig5_code_r %}
```r
{% include GN/fig5_code_r.txt %}
```
{% endcapture %}

{% capture fig5_code_python %}
```python
{% include GN/fig5_code_python.txt %}
```
{% endcapture %}

{% include codetabs.html id="fig5-code" title="Code" stata=fig5_code_stata r=fig5_code_r python=fig5_code_python %}

{% capture fig5_out_stata %}
![GN Figure 5](https://dmlguide.github.io/assets/images/GN_Figure5.png "GN Figure 5")
{% endcapture %}

{% capture fig5_out_r %}
![GN Figure 5 (R)]({{ '/assets/images/GN_Figure5_R.png' | relative_url }} "GN Figure 5 (R)")
{% endcapture %}

{% capture fig5_out_python %}
![GN Figure 5 (Python)]({{ '/assets/images/GN_Figure5_Python.png' | relative_url }} "GN Figure 5 (Python)")
{% endcapture %}

{% include codetabs.html id="fig5-out" title="Figure" open=true stata=fig5_out_stata r=fig5_out_r python=fig5_out_python %}

Adding the four control variables yields GN's headline column-(4) estimate of $-1.824$ <span style="white-space: nowrap">($s.e.=0.696$)</span>. They interpret the result as follows (p. 155):
> Based on the estimates from column 4, a one-standard-deviation increase in cross-generational instability (0.11) is associated with a reduction in the tradition index of 1.824×0.11=0.20, which is 36% of a standard deviation of the tradition variable.

{% capture ols_code_stata %}
```stata
{% include GN/ols_code_stata.txt %}
```
{% endcapture %}

{% capture ols_code_r %}
```r
{% include GN/ols_code_r.txt %}
```
{% endcapture %}

{% capture ols_code_python %}
```python
{% include GN/ols_code_python.txt %}
```
{% endcapture %}

{% include codetabs.html id="ols-code" title="Code" stata=ols_code_stata r=ols_code_r python=ols_code_python %}

{% capture ols_out_stata %}
```
{% include GN/ols_out_stata.txt %}
```
{% endcapture %}

{% capture ols_out_r %}
```
{% include GN/ols_out_r.txt %}
```
{% endcapture %}

{% capture ols_out_python %}
```
{% include GN/ols_out_python.txt %}
```
{% endcapture %}

{% include codetabs.html id="ols-out" title="Output" open=true stata=ols_out_stata r=ols_out_r python=ols_out_python %}


## DML as a robustness check

A useful robustness check is to ask whether the results with controls are sensitive to the assumption that the controls enter linearly. DML can help answer this question. 

Below we estimate the model with controls using DML and the partially-linear model (PLM). The specification is still very simple: we keep the assumption that the controls enter separately from the treatment, but we drop linearity.

The estimation procedure takes the following steps:

1. **Specify the target estimand:** in this case, the PLM coefficient.
2. **Specify the learners:** choose the learners for the conditional expectation functions for the outcome variable and the causal variable of interest.
3. **Cross-fitting:** obtain cross-fit estimates of the two conditional expectations.
4. **Estimation of structural parameter:** regress the residualized outcome variable on the residualized causal variable of interest.

We have no strong priors on whether a linear or non-linear learner is more appropriate, or whether regularization is needed at all. Hence we use 3 learners in this example:

- unregularized OLS, 
- cross-validated Lasso, 
- and a random forest. 

We also use model averaging to combine the estimated conditional expectations from these 3 learners. Specifically, we use short-stacking which is a computationally cheap and fast way of pairing DML and model averaging (see [Ahrens et al. (2025)](https://doi.org/10.1002/jae.3103) for a description of the algorithm and other model averaging strategies). Also to make the example run quickly the initial estimation is done just once, i.e., we do not resample (repeat the cross-fit based on different splits).

The dataset is small, and so we choose 10-fold cross-fitting. This means that learners are trained on about 66-67 observations, and OOS predictions are obtained for the remaining 7-8 observations. (If the dataset were larger, we could also consider a smaller number of folds to save computational time.)

{% capture dml_code_stata %}
```stata
{% include GN/dml_code_stata.txt %}
```
{% endcapture %}

{% capture dml_code_r %}
```r
{% include GN/dml_code_r.txt %}
```
{% endcapture %}

{% capture dml_code_python %}
```python
{% include GN/dml_code_python.txt %}
```
{% endcapture %}

{% include codetabs.html id="dml-code" title="Code" stata=dml_code_stata r=dml_code_r python=dml_code_python %}

{% capture dml_out_stata %}
```
{% include GN/dml_out_stata.txt %}
```
{% endcapture %}

{% capture dml_out_r %}
```
{% include GN/dml_out_r.txt %}
```
{% endcapture %}

{% capture dml_out_python %}
```
{% include GN/dml_out_python.txt %}
```
{% endcapture %}

{% include codetabs.html id="dml-out" title="Output" open=true stata=dml_out_stata r=dml_out_r python=dml_out_python %}

Typically the DML short-stacked results are quite close to the original linear specification used by GN. A natural interpretation is that the GN results still stand in this robustness check. This does not mean, however, that the linear specification was the "right" choice. 

The stacking weights (shown below) provide insights on the relative importance of linear vs non-linear learners: Depending on the randomization in the cross-fit split and the learners, the short-stacking weights typically put a low weight on unregularized OLS. The random forest learner also typically get a substantial weight in both of the conditional expectation estimates. This suggests that some nonlinearity is present, but that the assumption of linearity does not substantially affect the results.

{% capture ssw_code_stata %}
```stata
{% include GN/ssw_code_stata.txt %}
```
{% endcapture %}

{% capture ssw_code_r %}
```r
{% include GN/ssw_code_r.txt %}
```
{% endcapture %}

{% capture ssw_code_python %}
```python
{% include GN/ssw_code_python.txt %}
```
{% endcapture %}

{% include codetabs.html id="ssw-code" title="Code" stata=ssw_code_stata r=ssw_code_r python=ssw_code_python %}

{% capture ssw_out_stata %}
```
{% include GN/ssw_out_stata.txt %}
```
{% endcapture %}

{% capture ssw_out_r %}
```
{% include GN/ssw_out_r.txt %}
```
{% endcapture %}

{% capture ssw_out_python %}
```
{% include GN/ssw_out_python.txt %}
```
{% endcapture %}

{% include codetabs.html id="ssw-out" title="Output" open=true stata=ssw_out_stata r=ssw_out_r python=ssw_out_python %}

## Results by learner

We now inspect the DML results by learner. We use the same learner for both estimating the outcome and treatment equation. But we could also consider combinations where we use different learners by equation.

### Estimation table

{% capture rbl_est_code_stata %}
```stata
{% include GN/rbl_est_code_stata.txt %}
```
{% endcapture %}

{% capture rbl_est_code_r %}
```r
{% include GN/rbl_est_code_r.txt %}
```
{% endcapture %}

{% capture rbl_est_code_python %}
```python
{% include GN/rbl_est_code_python.txt %}
```
{% endcapture %}

{% include codetabs.html id="rbl-est-code" title="Code" stata=rbl_est_code_stata r=rbl_est_code_r python=rbl_est_code_python %}

{% capture rbl_est_out_stata %}
```
{% include GN/rbl_est_out_stata.txt %}
```
{% endcapture %}

{% capture rbl_est_out_r %}
```
{% include GN/rbl_est_out_r.txt %}
```
{% endcapture %}

{% capture rbl_est_out_python %}
```
{% include GN/rbl_est_out_python.txt %}
```
{% endcapture %}

{% include codetabs.html id="rbl-est-out" title="Output" open=true stata=rbl_est_out_stata r=rbl_est_out_r python=rbl_est_out_python %}

### Scatterplots

The GN dataset is very small. This makes it easy to visualize the conditional relationship by plotting the residualized outcome and residualized treatment, where residualization uses one of the learners. 

{% capture rbl_plot_code_stata %}
```stata
{% include GN/rbl_plot_code_stata.txt %}
```
{% endcapture %}

{% capture rbl_plot_code_r %}
```r
{% include GN/rbl_plot_code_r.txt %}
```
{% endcapture %}

{% capture rbl_plot_code_python %}
```python
{% include GN/rbl_plot_code_python.txt %}
```
{% endcapture %}

{% include codetabs.html id="rbl-plot-code" title="Code" stata=rbl_plot_code_stata r=rbl_plot_code_r python=rbl_plot_code_python %}

{% capture rbl_plot_out_stata %}
![GN Four learners](https://dmlguide.github.io/assets/images/GN_4learners.png "GN Four learners")
{% endcapture %}

{% capture rbl_plot_out_r %}
![GN four learners (R)]({{ '/assets/images/GN_4learners_R.png' | relative_url }} "GN four learners (R)")
{% endcapture %}

{% capture rbl_plot_out_python %}
![GN four learners (Python)]({{ '/assets/images/GN_4learners_Python.png' | relative_url }} "GN four learners (Python)")
{% endcapture %}

{% include codetabs.html id="rbl-plot-out" title="Figure" open=true stata=rbl_plot_out_stata r=rbl_plot_out_r python=rbl_plot_out_python %}

## Final model

The procedure above is suitable for "work-in-progress".

{: .important }
> For "final" results (e.g., for publication), a researcher should:
> 
> 1. Set the random number seed(s) for replicability.
> 2. Consider using multiple cross-fit splits and aggregate them.
> 3. Check if results are robust to the number of cross-fitting folds.
> 4. Validate the choice of machine learner, e.g., by inspecting cross-validate loss measures or through model averaging approaches such as short-stacking.[^2]

[^2]: Short-stacking stacking is computationally appealing but there are other options. Standard stacking - stacking separately for each cross-fit estimation - is also a possibility. "Pooled stacking" is similar to standard stacking except that the weights for combining learners are based on the OOS predictions for the entire sample (rather than for each cross-fit fold separately). See the discussion in [Ahrens et al. (2025)](https://doi.org/10.1002/jae.3103).

Cross-fitting introduces randomness by using a random split into cross-fit folds. A straightfoward way to reduce the sensitivity of the results to the split is to re-estimate using different cross-fit splits and aggregate the results. Aggregation can use the median or the mean.

The example below illustrates.

{% capture final_code_stata %}
```stata
{% include GN/final_code_stata.txt %}
```
{% endcapture %}

{% capture final_code_r %}
```r
{% include GN/final_code_r.txt %}
```
{% endcapture %}

{% capture final_code_python %}
```python
{% include GN/final_code_python.txt %}
```
{% endcapture %}

{% include codetabs.html id="final-code" title="Code" stata=final_code_stata r=final_code_r python=final_code_python %}

{% capture final_out_stata %}
```
{% include GN/final_out_stata.txt %}
```
{% endcapture %}

{% capture final_out_r %}
```
{% include GN/final_out_r.txt %}
```
{% endcapture %}

{% capture final_out_python %}
```
{% include GN/final_out_python.txt %}
```
{% endcapture %}

{% include codetabs.html id="final-out" title="Output" open=true stata=final_out_stata r=final_out_r python=final_out_python %}

The median results from the 11 DML estimations are again similar to the original GN results. The conclusion is again that their specification is robust to dropping the linearity assumption.

Note that the variation across the 11 refits introduced by the randomization of the cross-fit split is not trivial - the DML coefficient estimates range from about -1.7 to about -2.3 - but not enough to overturn the conclusion above. Increasing the number of refits is worth considering here.

It's also still the case that there is evidence of nonlinearity: all 3 stacking procedures tend to put a low weight on unregularized OLS. Now the nonlinear random forest learner typically gets the biggest weight. Again, this is evidence of some nonlinearity, but not enough to overturn the OLS-based results. (Below we only show the short-stacking weights for the sake of brevity.)

{% capture fsw_out_stata %}
```
{% include GN/fsw_out_stata.txt %}
```
{% endcapture %}

{% capture fsw_out_r %}
```
{% include GN/fsw_out_r.txt %}
```
{% endcapture %}

{% capture fsw_out_python %}
```
{% include GN/fsw_out_python.txt %}
```
{% endcapture %}

{% include codetabs.html id="fsw-out" title="Output: short-stack weights across the 11 resamples" stata=fsw_out_stata r=fsw_out_r python=fsw_out_python %}
