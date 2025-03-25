---
layout: default
#title: JTPA
parent: Examples
nav_order: 4
math: true
description: ""
permalink: /examples/JTPA
enable_copy_code_button: true
---

## Introduction

In this application, we consider the evaluation of the Job Training Partnership Act (JTPA) program.
The program supported job training for economically disadvantaged individuals in the United States. 
The offer of participation in training was randomized, but not all individuals who were offered training actually enrolled.

Due to the self-selection into enrollment, we target the local average treatment effect (LATE) of enrollment. Since the training offers were randomized, there is in principle no need to adjust for covariate in the TSLS estimation. However, by adjusting for covariates, we may be able to increase the precision of parameter estimates.

There is one catch: As discussed by [Blandhol, Bonney, Mogstad, & Torgovitsky (2025)](https://a-torgovitsky.github.io/tslslate.pdf), 
if covariates are present, TSLS might not be *weakly causal* (i.e., be affected by negative weights) and loose its LATE interpretation. DML allows estimating weakly causal parameters, including the LATE, as long as we estimate the nuisance function sufficiently flexibly. See also [Mogstad & Torgovitsky (2024)](https://doi.org/10.1016/bs.heslab.2024.11.003) for discussions. 

The sample considered here covers applications submitted in 1987-1989 and includes 6,102 women and 5,102 men.
The data is available in Stata format from the
[Statistical Software Components](http://fmwww.bc.edu/repec/bocode/j/jtpa.dta) (SSC) archive, 
and was analyzed, among others, by Abadie, Angrist, and Imbens (henceforth AAI; 2002).

## Data preparations

The main variables of interest are:

| Variable | Description |
| --------- | ----------- |
| `earnings` | Total earnings over 30 months (Outcome) |
| `assignmt` | Assignment to training (Encouragement) |
| `training` | Enrollment in training (Treatment) |
| `hsorged` | High School Diploma or GED |
| `black` | Race: Black, non-Hispanic |
| `hispanic` | Ethnicity: Hispanic |
| `married` | Married, living with spouse |
| `wkless13` | Worked less than 13 week in pas |
| `class_tr` | Service strategy recommended : Classroom training |
| `ojt_jsa` | Service strategy recommended : OJT/JSA |
| `age2225` | Age: 22-25 years |
| `age2629` | Age: 26-29 years |
| `age3035` |  Age: 30-35 years |
| `age3644` | Age: 36-44 years |
| `age4554` | Age: 45-54 years |
| `f2sms` | Indicator for follow-up survey |
| `sex` | Sex (Male=1) |

We load the data into R/Stata and define the estimation equations.

<details markdown="block">
<summary>R code</summary>

```
...
```

</details>

## OLS and TSLS estimates

For reference, we estimate the OLS and TSLS coefficients with and without control variables.

<details markdown="block">
<summary>R code</summary>

```
...
```

</details>

## DML with lasso

We now consider two estimation strategies: First, we estimate the regression parameter in the partially linear regression model using DML and Lasso regression. Second, we estimate the LATE parameter using the double-robust DML-LATE estimator. We report the partially linear regression coefficient for comparison.

<details markdown="block">
<summary>R code</summary>

```
...
```

</details>

## DML with multiple learners

<details markdown="block">
<summary>R code</summary>

```
...
```

</details>

<details markdown="block">
<summary>R code</summary>

```
...
```

</details>
