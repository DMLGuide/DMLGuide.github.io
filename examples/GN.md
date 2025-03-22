---
layout: default
title: Effect of 401(k) Participation on Financial Wealth
nav_order: 4
math: true
description: ""
permalink: /examples/GN
---

# Effect of 401(k) Participation on Financial Wealth

{% tabs log %}

{% tab log php %}
gsg
```php
var_dump('hello');
```
{% endtab %}

{% tab log js %}
```javascript
console.log('hello');
```
{% endtab %}

{% endtabs %}

In this example we illustrate the basic workings of DML using a simple empirical example.

The application is drawn from [Giuliano and Nunn (2021)](https://doi.org/10.1093/restud/rdaa074), who look at the relationship between climate instability and cultural persistence using a number of different datasets.

Their first estimation is a cross-country regression where the dependent variable is a measure $Y$ of the importance of tradition taken from the World Values Survey, and the causal variable of interest $D$ is a measure of ancestral climatic instability. The dataset is quite small: only 74-75 countries.

Giuliano and Nunn (G-N) are concerned about omitted confounders, and include 4 controls to address the issue.

1. distance from the equator;
2. a proxy for early economic development, proxied by complexity of settlements;
3. a measure of political centralization;
4. real per capital GDP in the survey year.

The example is useful for illustrating how DML works for several reasons: the dataset is small and available online, visualization is easy, reproduction of results is straightforward, and the example shows how DML can be used as a robustness check even in the simplest of settings.

The G-N dataset used for this demonstration is available at ...
The example below is based in part on the G-N replication code.

The variables used are:

| Variable | Description |
| ----------- | ----------------|
| `A198new`	| The outcome variable of interest: country-level average of the self-reported importance of tradition. Ranges from 1 to 6 (bigger=more important). |
| `sd_EE` | The causal variable of interest: a measure of ancestral climatic instability (standard deviation of temperature anomaly measure across generations; see G-N for details). |
| `v104_ee`	| Control #1: distance from the equator. | 
| `settlement_ee` | Control #2: early economic development (proxied by complexity of settlements). | 
| `polhierarchies_ee` | Control #3: political hierarchies (a measure of political centralization). | 
| `loggdp`| Control #4: log GDP per capita in the country of origin at the time of the survey. |

Their model with controls is one where the controls enter linearly and is estimated using OLS.
The effect of climatic instability on the importance of tradition is negative, with a coefficient that is different from zero at conventional significance levels. 
G-N summarize as follows (p. 155):
> Based on the estimates from column 4, a one-standard-deviation increase in cross-generational instability (0.11) is associated with a reduction in the tradition index of 1.824×0.11=0.20, which is 36% of a standard deviation of the tradition variable.

The code below reproduces columns (3) and (4) in Table 1 of the published paper.
Column (3) is a bivariate linear regression of the outcome (importance of tradition) on the causal variable of interest (ancestral climatic instability).
Column (4) has the OLS results when the 4 controls are included.
In the DML example below, we show how to use DML to estimate the Column (4) specification.

We also reproduce their replication code for Figure 5, which is a simple scatterplot of the bivariate regression with no controls reported in Column (3).



```R
library(ddml)
```

etc 
```R
# Runs code
code_that_runs()

#> results_from_code_that_runs
#> more_results_from_code_that_runs
```
