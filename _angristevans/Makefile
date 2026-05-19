# Two-step build for the Angrist-Evans DDML post.
#
#   make data    -> runs AE_analysis.R once, writes results.parquet + results.csv
#   make render  -> renders AngristEvans.qmd to ../examples/AngristEvans.md
#   make all     -> data + render
#   make clean   -> removes results and Quarto freeze cache

R         ?= Rscript
QUARTO    ?= quarto

DATA_OUT  := results.parquet results.csv
QMD       := AngristEvans.qmd
MD_OUT    := ../examples/AngristEvans.md

.PHONY: all data render clean

all: render

data: $(DATA_OUT)

$(DATA_OUT): AE_analysis.R pums80m.dta
	$(R) AE_analysis.R

render: $(MD_OUT)

$(MD_OUT): $(QMD) results.parquet
	$(QUARTO) render $(QMD)
	# Strip leading blank lines so Jekyll sees `---` at line 1.
	awk 'NF{found=1} found' $(MD_OUT) > $(MD_OUT).tmp && mv $(MD_OUT).tmp $(MD_OUT)
	# Quarto's GFM writer drops `markdown="block"` from <details>; normalise
	# every opening <details ...> tag to keep code fences kramdown-parseable
	# and to default the collapsible blocks to expanded.
	sed -i.bak 's|^<details[^>]*>$$|<details markdown="block" open>|' $(MD_OUT) && rm $(MD_OUT).bak

clean:
	rm -f $(DATA_OUT)
	rm -rf _freeze .quarto
