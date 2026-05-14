# `_angristevans/` — source for the "DDML for the Angrist & Evans" blog post

This folder produces [`examples/AngristEvans.md`](../examples/AngristEvans.md), the website page that revisits Angrist & Evans (1998) through Angrist & Frandsen's (2022) critique and shows how to fix the ML-first-stage failure by encoding the no-interaction restriction directly into the learners.

Jekyll ignores any directory whose name starts with `_`, so this folder is *not* served by the site — it is purely a working/build directory.

## Files

| File | Role |
| --- | --- |
| `AE_analysis.R` | Producer. Loads `pums80m.dta`, runs 2SLS and `ddml_pliv()` over 3 instruments × 2 outcomes × 2 constraint flags (12 DDML fits in total) and writes `results.parquet` + `results.csv`. Slow — full pums80m sample, no bootstrap. |
| `pums80m.dta` | Angrist & Evans (1998) replication data. |
| `AngristEvans.qmd` | Consumer. Reads `results.parquet` and renders the blog post. All prose, math, and the per-instrument result tables live here. |
| `_quarto.yml` | Quarto project config: output goes to `../examples/`, R chunks use `freeze: auto`, format is GFM. |
| `Makefile` | Wraps the two-step build (`make data`, `make render`, `make all`, `make clean`). |
| `results.parquet`, `results.csv` | Build artifacts from `AE_analysis.R`. Either format is fine; the `.qmd` reads the parquet. |
| `_freeze/` | Quarto's chunk cache (auto-managed). |
| `AngristFrandsen2022.pdf`, `old_draft.tex` | Reference material. |

## Build pipeline

Two steps, decoupled so we don't rerun DDML every time we tweak prose:

```bash
cd website/_angristevans

# 1. Generate the results artifact. Slow — full pums80m, 12 DDML fits.
make data           # = Rscript AE_analysis.R; writes results.parquet + results.csv

# 2. Render the Quarto document. Fast — just reads the parquet.
make render         # = quarto render AngristEvans.qmd; writes ../examples/AngristEvans.md
                    #   then strips Quarto's leading blank lines so Jekyll sees `---` at line 1

make all            # data + render
make clean          # remove results.* and _freeze/
```

`make render` also depends on `results.parquet`, so the first time you run it from a clean tree it will trigger `make data` automatically.

## How the Jekyll front matter survives Quarto

Quarto's own YAML front matter is consumed by the renderer. To keep the Just-the-Docs front matter that Jekyll needs at the very top of the output `.md`, the `.qmd` declares it inside a raw-markdown block:

````markdown
```{=markdown}
---
layout: default
title: DDML for the Angrist & Evans
parent: Examples
nav_order: 36
...
---
```
````

The raw block is emitted verbatim. A final `awk` step in the Makefile strips any leading blank lines Quarto inserts so the `---` lands on line 1.

## What's in the results object

`AE_analysis.R` builds a long tibble `res` with one row per (instrument × outcome × constraint × learner × spec). Columns of interest:

- `estimator ∈ {"tsls", "ddml"}`
- `spec ∈ {"structural", "first_stage"}`
- `learner` — `"ols"` for 2SLS; `"nnls"` for the DDML short-stack; `"custom_1"..."custom_5"` for the five single learners in the order of `make_learner_specs()`: 1 = OLS, 2 = Lasso, 3 = Ridge, 4 = XGBoost(lr = .01), 5 = XGBoost(lr = .03).
- `constraint ∈ {TRUE, FALSE}` — whether the no-interaction restriction was imposed (block-structured polynomial dictionary for lasso/ridge + `interaction_constraints` for XGBoost).
- `instr ∈ {"observed", "fake"}` — the instrument flavor used for the row. `prepare_data()` populates the *data-frame* column `instr` (the actual $Z$ vector) on each call: `samesex` for `observed` and `agem1 + educm + Uniform(0,1)` for `fake`. The `instr` column in `res` is the flavor *label*, not the $Z$ values.
- `estimate`, `std.error`, `conf.low`, `conf.high`, `statistic`, `term`, `yvar`.

The friendly column labels used in the rendered tables are mapped in the `setup` chunk of `AngristEvans.qmd`.

## Naming convention

Two `instr` symbols coexist in the code; they don't collide because they live in different scopes, but it helps to know which is which:

- **`instr` (data-frame column / `Z_var`)**: the realized instrument vector inside `d`. Built by `prepare_data()` and consumed by `estimate()` via `d[, Z_var]`.
- **`instr` (column in `res`)**: the flavor *label* — one of `"observed"`, `"fake"`. Set by `mutate(instr = instrument)` at the end of `estimate()`.
- **`flavor` (loop variable in the main loop)**: the flavor label being iterated over. Renamed from the earlier `instr` to avoid shadowing the column name.
