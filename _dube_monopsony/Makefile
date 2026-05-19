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

BLOG1_QMD := Monopsony_DML.qmd
BLOG2_QMD := Monopsony_Finetune.qmd
BLOG3_QMD := Monopsony_Robustness.qmd

BLOG1_MD  := ../examples/Monopsony_DML.md
BLOG2_MD  := ../examples/Monopsony_Finetune.md
BLOG3_MD  := ../examples/Monopsony_Robustness.md

.PHONY: all data results render figures clean blog1 blog2 blog3

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

$(BLOG3_OUT): $(BLOG3_R) | $(DATA_RDS)
	$(R) $(BLOG3_R)

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
	rm -f $(BLOG1_OUT) $(BLOG2_OUT) $(BLOG3_OUT)
	rm -f $(FIGURES)
	rm -f *.aux *.log $(ALGO_PDF) $(BASIC_PDF)
	rm -rf _freeze .quarto
