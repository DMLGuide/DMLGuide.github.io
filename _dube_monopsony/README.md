# Dube et al. monopsony — blog series source

Source files for the three-part *Monopsony* DML series. The folder mirrors the
layout of `_angristevans/`: per-post Quarto documents alongside the R scripts
that produce their results files (Parts 1 and 2 only — Part 3 reads its inputs
directly inside the qmd), wired together by a `Makefile`. Quarto renders each
post into the served `examples/` directory:

| Post | Quarto source | R analysis script | Inputs | Rendered |
| --- | --- | --- | --- | --- |
| Monopsony I — DML in the simplest setting | `Monopsony_DML.qmd` | `blog1_wo_embed.R` | `results_entry1.rds` | `../examples/Monopsony_DML.md` |
| Monopsony II — DML with fine-tuned embeddings | `Monopsony_Finetune.qmd` | `blog2_w_embed.R` | `results_entry2.rds` | `../examples/Monopsony_Finetune.md` |
| Monopsony III — Robustness checks | `Monopsony_Robustness.qmd` | — (inlined in qmd) | `monopsony_data/intermediate/{iid_K3,xclust_K3,xclust_K5}/*.RData` | `../examples/Monopsony_Robustness.md` |

The folder name has a leading underscore, so Jekyll skips it when serving the
site. The Quarto build still writes its outputs into `../examples/` (which
*is* served), via `_quarto.yml`.

For Parts 1 and 2, each `.rds` is a named list of fitted models /
`modelsummary_list` shims that the qmd reads and renders via `modelsummary()`.
Part 3 has no `.rds` cache: its setup chunk walks the per-seed `.RData` files
produced by `Code/dube_monopsony/run_cvc.R`, builds the named lists `iid_K3`,
`xclust_K3`, `xclust_K5` in-memory, and renders the four robustness tables
directly from them.

## Shared analysis dataset

Parts 1 and 2 read the same dataset:

```
data/monopsony_blog.rds       # R-native
```

It is built once by `build_blog_dataset.R` from the raw Ipeirotis CSVs. One row
per HIT group, with:

- `group_id`, `requester_id` — identifiers
- `log_duration`, `log_reward` — outcome and treatment
- ~80 hand-coded numeric / dummy controls

Part 2 *additionally* reads fine-tuned DeBERTa embedding parquets from
`<MONOPSONY_DATA_ROOT>/Embeddings/`. Part 3 does not use the shared dataset at
all; it consumes only the per-seed `.RData` files under
`<MONOPSONY_DATA_ROOT>/intermediate/{iid_K3,xclust_K3,xclust_K5}/`, each
containing `fit`, `fit_cvc`, `diag_obj`, `diag_cvc`, and `fitted_obj` as saved
by `Code/dube_monopsony/run_cvc.R`.

## Build

```bash
make data        # rebuilds data/monopsony_blog.rds (slow; needs raw inputs)
make results     # runs analysis scripts for Parts 1 and 2 -> results_entry{1,2}.rds
make render      # quarto render -> ../examples/Monopsony_*.md
make all         # figures + render
make blog1       # just blog 1 (results .rds + rendered md)
make blog2       # just blog 2
make blog3       # just blog 3 (rendered md only; reads .RData tree directly)
make clean       # removes results .rds, figures, and Quarto freeze cache
                 # (does NOT delete data/monopsony_blog.rds)
```

`data/monopsony_blog.rds` is not a target of `results` / `render`, because
rebuilding it requires the raw `MONOPSONY_DATA_ROOT` (with the embedding
parquet) which is not part of this repo. The committed `.rds` is the source of
truth for downstream scripts.

The `monopsony_data/intermediate/` tree consumed by Part 3 is likewise
external; it is produced by running `Code/dube_monopsony/run_cvc.R` across the
five seeds and three (xfit_mode, K) combinations.

## Entries — what each does

### Entry 1 — `blog1_wo_embed.R` (Monopsony I)

The simplest possible DML estimate of $\theta_0$ in
$\log(\text{duration}) = \theta_0 \log(\text{reward}) + g_0(X) + \varepsilon$:
**one** learner (XGBoost "XGB 2" spec from the paper), **no** text embeddings,
hand-coded controls only. Recruiter-honest folds with `cluster_variable =
requester_id`; cluster-robust SEs. Also fits OLS-with-controls for comparison.

### Entry 2 — `blog2_w_embed.R` (Monopsony II)

Adds the 768 fine-tuned DeBERTa embedding columns to $X$. Loads one parquet
per fold from `<MONOPSONY_DATA_ROOT>/Embeddings/` (fold-honest), then hand-
rolls the residual-on-residual `feols` for the partially-linear coefficient.
The post text spends most of its prose explaining LoRA / DeBERTa fine-tuning,
with the production code in `Code/dube_monopsony/fine_tune/` flagged as the
fully reproducible reference.

### Entry 3 — `Monopsony_Robustness.qmd` (Monopsony III)

No standalone R script — the analysis lives in the qmd setup chunk. Walks
`<MONOPSONY_DATA_ROOT>/intermediate/{iid_K3, xclust_K3, xclust_K5}/`, loads
each `cvc_seed*_K*.RData` into a named list, and renders four
median-of-medians comparison tables:

1. **Per-seed × aggregate** for the baseline (`xclust_K3`, XGB 3) across the 5
   seeds plus the `ddml_rep` aggregate.
2. **Learner sensitivity**: XGB 3 vs CV-Lasso, both aggregated on `xclust_K3`.
3. **Fold construction**: cluster-honest (`xclust_K3`) vs IID (`iid_K3`), XGB 3
   aggregated.
4. **Number of folds**: $K = 3$ (`xclust_K3`) vs $K = 5$ (`xclust_K5`), XGB 3
   aggregated.

Every table reports $n$, $R^2(Y \mid X)$, $R^2(D \mid X)$, with R² values pulled
from `diag_obj` via the in-qmd `get_r2()` helper. Median-across-seeds for the
aggregate columns, seed-specific for Table 1's per-seed columns.

Sweeps not run here (single-learner without aggregation, short-stacking,
multi-seed `ddml_rep` against alternative learner pools) are discussed in the
post text but deferred to `Code/dube_monopsony/`.

## Other files

- `build_blog_dataset.R` — the dataset-build script described above.
- `algorithm_flowchart{,_basic}.tex` — TikZ sources rasterised to PNG under
  `../assets/images/monopsony/` by `make figures`.

## Where to look for the full pipeline

- `Code/dube_monopsony/crossfit_with_embed.R` — full per-fold cross-fitting with all 12 learners and fold-honest embeddings.
- `Code/dube_monopsony/run_cvc.R` — assembles cross-fitted predictions, runs `ddml_plm`, computes CVC diagnostics, builds the CVC-weighted ensemble. Produces the per-seed `.RData` files consumed by Part 3.
- `Code/dube_monopsony/make_tables.R` — assembles the LaTeX tables in the paper from the same per-seed `.RData` files.
- `Code/dube_monopsony/fine_tune/` — DeBERTa fine-tuning that produces the fold-specific embeddings.
