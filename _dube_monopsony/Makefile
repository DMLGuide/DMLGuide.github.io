# Three-post Monopsony DDML series.
#
# Targets (high-level):
#   make data        -> rebuilds the shared analysis dataset (data/monopsony_blog.rds)
#                       from the raw Ipeirotis CSVs. SLOW; skip if monopsony_blog.rds
#                       already exists and you just want to render.
#   make results     -> runs all three per-post analysis scripts, writing
#                       results_entry{1,2,3}.rds (modelsummary_list shims) alongside
#                       this Makefile.
#   make render      -> renders all three .qmd files to ../examples/Monopsony_*.md
#   make figures     -> compiles the TikZ figures to PNG via pdflatex + pdftoppm
#                       (currently: assets/images/monopsony/crossfit_algorithm.png)
#   make all         -> figures + results + render
#   make clean       -> removes per-post results .rds, generated figures, and Quarto
#                       freeze cache (does NOT delete data/monopsony_blog.rds)
#
# Per-post targets:
#   make blog1 / blog2 / blog3 -> results .rds + render for that post only
#
# blog3 is split across four specs (baseline, K5, lasso, iid) so each one can
# be run independently to bound peak memory (see blog3_robust.R `specs` list):
#   make blog3-baseline / blog3-K5 / blog3-lasso / blog3-iid
#                  -> runs only that spec, writes results_entry3_<spec>.rds
#   make blog3-parts    -> all four parts (no combine)
#   make blog3-combine  -> assemble results_entry3.rds from the four parts
#   make blog3          -> ensures all four parts exist, combines, renders
#
# The shared dataset target is intentionally not a dependency of `results` / `render`,
# because rebuilding it requires the raw monopsony_data root which is not part of
# this repo. The committed data/monopsony_blog.rds is the source of truth.

R         ?= Rscript
QUARTO    ?= quarto
PDFLATEX  ?= pdflatex
PDFTOPPM  ?= pdftoppm
PNG_DPI   ?= 200

DATA_RDS  := data/monopsony_blog.rds

# --- TikZ figures (source -> PDF -> PNG) ---
FIG_DIR   := ../assets/images/monopsony

ALGO_TEX  := algorithm_flowchart.tex
ALGO_PDF  := algorithm_flowchart.pdf
ALGO_PNG  := $(FIG_DIR)/crossfit_algorithm.png

BASIC_TEX := algorithm_flowchart_basic.tex
BASIC_PDF := algorithm_flowchart_basic.pdf
BASIC_PNG := $(FIG_DIR)/crossfit_basic.png

FIGURES   := $(ALGO_PNG) $(BASIC_PNG)

BLOG1_R   := blog1_wo_embed.R
BLOG2_R   := blog2_w_embed.R
BLOG3_R   := blog3_robust.R

BLOG1_OUT := results_entry1.rds
BLOG2_OUT := results_entry2.rds
BLOG3_OUT := results_entry3.rds

# blog3 is split into four per-spec parts (see specs registry in blog3_robust.R).
# Each part runs independently and saves a lean (b, SE, R^2) summary; the final
# results_entry3.rds is assembled by the `combine` action.
BLOG3_SPECS := baseline K5 lasso iid
BLOG3_PARTS := $(addprefix results_entry3_,$(addsuffix .rds,$(BLOG3_SPECS)))

BLOG1_QMD := Monopsony_DML.qmd
BLOG2_QMD := Monopsony_Finetune.qmd
BLOG3_QMD := Monopsony_Robustness.qmd

BLOG1_MD  := ../examples/Monopsony_DML.md
BLOG2_MD  := ../examples/Monopsony_Finetune.md
BLOG3_MD  := ../examples/Monopsony_Robustness.md

.PHONY: all data results render figures clean blog1 blog2 blog3 \
        blog3-parts blog3-baseline blog3-K5 blog3-lasso blog3-iid blog3-combine

all: figures render

# --- Shared dataset (slow; only run if the raw inputs are present) ---
data: $(DATA_RDS)

$(DATA_RDS): build_blog_dataset.R
	$(R) build_blog_dataset.R

# --- Per-entry results .rds ---
results: $(BLOG1_OUT) $(BLOG2_OUT) $(BLOG3_OUT)

# Order-only prerequisite on DATA_RDS (after `|`): make requires the file to
# exist but does NOT rebuild it when the build script's mtime moves. The
# committed monopsony_blog.rds is the source of truth — use `make data`
# explicitly to rebuild.
$(BLOG1_OUT): $(BLOG1_R) | $(DATA_RDS)
	$(R) $(BLOG1_R)

$(BLOG2_OUT): $(BLOG2_R) | $(DATA_RDS)
	$(R) $(BLOG2_R)

# blog3 per-spec parts (each is one entry of the spec registry in blog3_robust.R).
# Pattern rule: results_entry3_<spec>.rds <- Rscript blog3_robust.R <spec>
results_entry3_%.rds: $(BLOG3_R) | $(DATA_RDS)
	$(R) $(BLOG3_R) $*

# Convenience aliases.
blog3-baseline: results_entry3_baseline.rds
blog3-K5:       results_entry3_K5.rds
blog3-lasso:    results_entry3_lasso.rds
blog3-iid:      results_entry3_iid.rds
blog3-parts:    $(BLOG3_PARTS)
blog3-combine:  $(BLOG3_OUT)

# Final blog3 output is assembled by the `combine` action from the four parts.
$(BLOG3_OUT): $(BLOG3_PARTS) $(BLOG3_R)
	$(R) $(BLOG3_R) combine

# --- TikZ figures: .tex -> .pdf -> .png ---
# pdflatex emits the PDF in the current directory; pdftoppm rasterises it
# straight into the assets folder Jekyll serves.
figures: $(FIGURES)

$(ALGO_PDF): $(ALGO_TEX)
	$(PDFLATEX) -interaction=nonstopmode $(ALGO_TEX) > /dev/null

$(ALGO_PNG): $(ALGO_PDF)
	@mkdir -p $(FIG_DIR)
	$(PDFTOPPM) -png -r $(PNG_DPI) -singlefile $(ALGO_PDF) $(basename $(ALGO_PNG))

$(BASIC_PDF): $(BASIC_TEX)
	$(PDFLATEX) -interaction=nonstopmode $(BASIC_TEX) > /dev/null

$(BASIC_PNG): $(BASIC_PDF)
	@mkdir -p $(FIG_DIR)
	$(PDFTOPPM) -png -r $(PNG_DPI) -singlefile $(BASIC_PDF) $(basename $(BASIC_PNG))

# --- Quarto renders ---
render: $(BLOG1_MD) $(BLOG2_MD) $(BLOG3_MD)

# Quarto's gfm output prepends two blank lines before the {=markdown} raw
# block (an artefact of the suppressed title block). Jekyll requires the
# `---` front-matter delimiter on line 1, so we strip leading blank lines
# after each render.
$(BLOG1_MD): $(BLOG1_QMD) $(BLOG1_OUT) $(BASIC_PNG)
	$(QUARTO) render $(BLOG1_QMD)
	sed -i '' '/./,$$!d' $(BLOG1_MD)

$(BLOG2_MD): $(BLOG2_QMD) $(BLOG2_OUT) $(ALGO_PNG)
	$(QUARTO) render $(BLOG2_QMD)
	sed -i '' '/./,$$!d' $(BLOG2_MD)

$(BLOG3_MD): $(BLOG3_QMD) $(BLOG3_OUT)
	$(QUARTO) render $(BLOG3_QMD)
	sed -i '' '/./,$$!d' $(BLOG3_MD)

# --- Per-entry convenience targets ---
blog1: $(BLOG1_MD)
blog2: $(BLOG2_MD)
blog3: $(BLOG3_MD)

clean:
	rm -f $(BLOG1_OUT) $(BLOG2_OUT) $(BLOG3_OUT) $(BLOG3_PARTS)
	rm -f $(FIGURES)
	rm -f *.aux *.log $(ALGO_PDF) $(BASIC_PDF)
	rm -rf _freeze .quarto
