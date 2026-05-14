---
layout: default
title: Examples
nav_order: 3
math: true
description: "A collection of double/debiased machine learning examples."
permalink: /examples
---

# Examples

On this page, we discuss several applications:
 
- *"The Effect of 401k Eligibility on Financial Wealth"* is a toy example that shows you how you can estimate partially linear (IV) regression coefficients, average treatment effects and local average treatment effects using DML.
- *"Understanding Cultural Persistence and Change"* focuses on the partially linear model. The application illustrates how to employ DML in practice, and highlights some of the most important pitfalls.
- *"Dynamic Effects on Hospitalization"* showcasts DML estimation in difference-in-differences designs under conditional parallel trends assumptions.
- *"Monopsony in Online Labor Markets"* is a 3-part walkthrough of the monopsony application from our review paper: how to fine-tune DeBERTa text embeddings with LoRA ([Part I]({{ '/examples/Monopsony_Finetune' | relative_url }})), how to plug them into `ddml::ddml_plm()` to estimate the labor supply elasticity ([Part II]({{ '/examples/Monopsony_DML' | relative_url }})), and how to stress-test the result by varying the number of folds and the cluster-vs-IID fold construction ([Part III]({{ '/examples/Monopsony_Robustness' | relative_url }})).

We provide both R and Stata code for you to run these examples. You can also find the replication repository for the JEL paper here: **link to be added**.