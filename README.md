# A Guide to Double Machine Learning — Website

Jekyll-based companion site for our review paper. Live URL:
<https://dmlguide.github.io>.

Theme: [Just the Docs](https://just-the-docs.github.io/just-the-docs/).
Local build: `bundle install && bundle exec jekyll serve` →
<http://127.0.0.1:4000>.

---

## Where we stand (as of 2026-06-04)

### Landing page (`examples/index.md`)

Three example tiles are currently visible; two more are hidden behind a
comment block and can be re-enabled by removing the `<!-- … -->` wrapper.

| Tile | Status | Languages | Notes |
| --- | --- | --- | --- |
| 401(k) Eligibility | live | Stata · R · Python | revised to codetabs structure (see below) |
| Cultural Persistence (GN) | live | Stata · R · Python | reference template — all subsequent examples mirror this style |
| Hospitalization Effects (HRS) | live | R | still on old `<details>` blocks |
| Angrist & Evans IV | hidden | — | needs revision before re-enabling |
| Monopsony on MTurk | hidden | — | three-part write-up still under construction |

Tile layout (June 2026 revision): no longer aspect-ratio-locked. Icon is a
fixed 140 px header, body grows to fit content, grid stretches all tiles to
the tallest in a row. Footer carries the topic tags (small caps) plus
language chips (`Stata` dark blue, `R` blue, `Python` blue/yellow split).

### Example pages

Two styles coexist in `examples/`:

- **New (codetabs) style** — used by `GN.md` and `401k.md`.
  - Prose is interleaved with `{% include codetabs.html … %}` blocks that
    expose tabbed Stata / R / Python views.
  - Code and output are pulled from `_includes/<example>/<snippet>_<lang>.txt`.
  - Snippets are auto-generated from the per-language source files in
    `_<example>/{R,Python,Stata}/` via `@snippet:NAME … @end` markers
    (see "Snippet workflow" below).
- **Old (`<details>` blocks) style** — used by `Aizer.md`, `AngristEvans.md`,
  `HRS.md`, `JTPA.md`. Code and output are pasted inline inside collapsible
  HTML `<details>` elements. These pages still need migration.

| Page | Style | Files |
| --- | --- | --- |
| `examples/GN.md` | codetabs | sources in `_GN/`, snippets in `_includes/GN/` |
| `examples/401k.md` | codetabs | sources in `_401k/`, snippets in `_includes/401k/` |
| `examples/HRS.md` | `<details>` | inline |
| `examples/Aizer.md` | `<details>` | inline |
| `examples/AngristEvans.md` | `<details>` | inline |
| `examples/JTPA.md` | `<details>` | inline |
| `examples/Monopsony_*.md` | prose only | — |

### Snippet workflow (codetabs examples)

Each example folder (`_GN/`, `_401k/`) is self-contained:

```
_<example>/
├── Makefile
├── build_snippets.py
├── run_stata.py             # only if Stata is reproducible locally
├── R/
│   ├── <script>.R           # @snippet:NAME … @end markers
│   └── <script>_output.txt  # captured stdout, also marker-wrapped
├── Python/
│   ├── <script>.py
│   └── <script>_output.txt
└── Stata/
    ├── <script>.do
    └── <script>_output.txt  # written by run_stata.py from .log
```

Commands (run from inside `_<example>/`):

| Command | Effect |
| --- | --- |
| `make snippets` | re-extract `@snippet:NAME … @end` blocks from R, Python, Stata sources/logs into `../_includes/<example>/` |
| `make stata-run` | re-run Stata in batch mode (env var `STATA_BIN` to override path), then `make snippets` |
| `make clean` | drop the snippet directory and Stata log |

The R and Python scripts also write their own log files (similar
marker-wrapped) so that running the script and then `make snippets` is
enough to refresh the blog output. The R scripts use `ddml::tidy()` from
the `ddml` package together with `tidymodels` for compact comparison
tibbles. The Python scripts use `DoubleML` with `scikit-learn` learners.

Python deps: a local `.venv` lives at `website/.venv/` with `doubleml`,
`scikit-learn`, `pandas`, `statsmodels`, `matplotlib` installed against
homebrew's `python@3.12`. Activate or call binaries directly, e.g.
`./.venv/bin/python _401k/Python/PVW_ddml.py`.

### Build artifacts

- `_includes/GN/`, `_includes/401k/` — auto-generated; do not hand-edit.
  Re-run `make snippets` after touching the corresponding R/Python/Stata
  sources.
- `_site/` — Jekyll output; ignored by source control.
- `jekyll.log` — last serve session log.

### Theme tweaks (`_sass/custom/custom.scss`)

- UChicago maroon (`#800000`) replaces the default Just-the-Docs purple
  for headings, nav, buttons, footnote rule.
- Code-language tabs (`.codetabs`) styling lives here. The HTML lives in
  `_includes/codetabs.html`; the chosen tab is driven by `:checked` on
  hidden radio inputs (no JS).
- Examples landing-page grid: see `.example-grid`, `.example-tile`,
  `.example-tile-langs`, `.lang-chip`. The same rules are duplicated as
  an inline `<style>` block at the top of `examples/index.md` so that
  the layout still works if SCSS recompile fails (e.g. on a stale
  GitHub Pages cache).

---

## Open work

1. **Migrate the remaining `<details>`-style example pages** (HRS, Aizer,
   AngristEvans, JTPA) onto the codetabs structure. The GN page is the
   reference; the 401k page demonstrates the workflow on a smaller R/Python
   example using DoubleML.
2. **Decide language coverage** for HRS, Aizer, AngristEvans, JTPA. Add a
   Python implementation for any that should be Python-supported, then
   add the corresponding `lang-chip` badges to the index tiles.
3. **Re-enable the Angrist & Evans tile** once that page is revised.
4. **Complete the Monopsony series** (three Markdown files already exist
   in `examples/`); revise the tile copy/icon and re-enable.
5. **Replace `lang-chip` text labels with proper SVG logos** if a future
   pass wants brand-accurate marks instead of colored text chips.

---

## Local development

```sh
bundle install                          # one-time
bundle exec jekyll serve                # → http://127.0.0.1:4000
```

To refresh codetabs snippets after editing R or Python sources:

```sh
cd _GN   && make snippets               # or _401k
```

To re-run Stata and regenerate the Stata log + snippets:

```sh
cd _GN   && make stata-run              # or _401k
```

The `STATA_BIN` env var lets you point at a non-default Stata install
(default: `/Applications/StataNow/StataSE.app/Contents/MacOS/stata-se`).

---

## Publishing

The site is served from GitHub Pages with the workflow in
`.github/workflows/pages.yml` (boilerplate from the Just-the-Docs
template). A push to `main` triggers a build and deploy; the
`_includes/<example>/` snippets must be committed for the build to
succeed (the deploy runner does not re-run R/Python/Stata).
