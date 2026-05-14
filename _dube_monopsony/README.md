# Dube et al. monopsony — blog series source

Source files for the three-part *Monopsony* DDML series. The folder mirrors the
layout of `_angristevans/`: per-post Quarto documents alongside the R scripts
that produce their results files, wired together by a `Makefile`. Quarto
renders each post into the served `examples/` directory:

| Post | Quarto source | R analysis script | Results | Rendered |
| --- | --- | --- | --- | --- |
| Monopsony I — DDML in the simplest setting | `Monopsony_DML.qmd` | `blog1_wo_embed.R` | `results_entry1.rds` | `../examples/Monopsony_DML.md` |
| Monopsony II — DDML with fine-tuned embeddings | `Monopsony_Finetune.qmd` | `blog2_w_embed.R` | `results_entry2.rds` | `../examples/Monopsony_Finetune.md` |
| Monopsony III — Robustness checks | `Monopsony_Robustness.qmd` | `blog3_robust.R` | `results_entry3.rds` | `../examples/Monopsony_Robustness.md` |

The folder name has a leading underscore, so Jekyll skips it when serving the
site. The Quarto build still writes its outputs into `../examples/` (which
*is* served), via `_quarto.yml`.

Each `.rds` is a named list of fitted models / `modelsummary_list` shims; the
corresponding `.qmd` reads it and renders the result table via
`modelsummary()`.

## Shared analysis dataset

All three R analysis scripts read the same dataset:

```
data/monopsony_blog.rds       # R-native
```

It is built once by `build_blog_dataset.R` from the raw Ipeirotis CSVs. One row
per HIT group, with:

- `group_id`, `requester_id` — identifiers
- `log_duration`, `log_reward` — outcome and treatment
- ~80 hand-coded numeric / dummy controls

Blog 2 and 3 *additionally* read fine-tuned DeBERTa embedding parquets from
`<MONOPSONY_DATA_ROOT>/Embeddings/` (K=3 cluster), `.../Embeddings5/` (K=5
cluster), and `.../Embeddings_noclust/` (K=3 IID). Per-fold foldvar CSVs live
under `<MONOPSONY_DATA_ROOT>/foldvars/`.

## Build

```bash
make data        # rebuilds data/monopsony_blog.rds (slow; needs raw inputs)
make results     # runs all three analysis scripts -> results_entry{1,2,3}.rds
make render      # quarto render -> ../examples/Monopsony_*.md
make all         # results + render
make blog1       # just blog 1 (results .rds + rendered md)
make blog2       # just blog 2
make blog3       # just blog 3
make clean       # removes results .rds + Quarto freeze cache
                 # (does NOT delete data/monopsony_blog.rds)
```

`data/monopsony_blog.rds` is not a target of `results` / `render`, because
rebuilding it requires the raw `MONOPSONY_DATA_ROOT` (with the embedding
parquet) which is not part of this repo. The committed `.rds` is the source of
truth for downstream scripts.

## Entries — what each does

### Entry 1 — `blog1_wo_embed.R` (Monopsony I)

The simplest possible DDML estimate of $\theta_0$ in
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

### Entry 3 — `blog3_robust.R` (Monopsony III)

Three runs of the same `crossfit_with_embed` + residual-regression pipeline:

- (D, K-sensitivity) `foldnum=3, cluster=TRUE` vs. `foldnum=5, cluster=TRUE`.
- (E, fold construction) `foldnum=3, cluster=TRUE` vs. `foldnum=3, cluster=FALSE`.

Sweeps (A) single-learner, (B) stacking, and (C) multi-seed `ddml_rep` are
described in the post text but are not run here; see `Code/dube_monopsony/`
for the full pipeline.

## Other files

- `crossfit_xgb.R` — original self-contained, "no shared dataset" XGBoost-only
  replication. Kept for reference.
- `build_blog_dataset.R` — the dataset-build script described above.

## Where to look for the full pipeline

- `Code/dube_monopsony/crossfit_with_embed.R` — full per-fold cross-fitting with all 12 learners and fold-honest embeddings.
- `Code/dube_monopsony/run_cvc.R` — assembles cross-fitted predictions, runs `ddml_plm`, computes CVC diagnostics, builds the CVC-weighted ensemble.
- `Code/dube_monopsony/fine_tune/` — DeBERTa fine-tuning that produces the fold-specific embeddings.
