# Make targets for the GN application.
#
# `make snippets`  — extract @snippet sections from _GN/{R,Python,Stata}
#                    into _includes/GN/.
# `make stata-run` — invoke Stata in batch mode to refresh the Stata
#                    output log, then regenerate snippets. Requires
#                    STATA_BIN (defaults to
#                    /Applications/StataNow/StataSE.app/Contents/MacOS/stata-se).
#
# The build script is cheap, so we run it unconditionally rather than
# track per-source dependencies (the Stata source filename contains a
# space, which trips `make`).

PY ?= python3

.PHONY: snippets stata-run clean

snippets:
	$(PY) build_snippets.py

stata-run:
	$(PY) run_stata.py
	$(MAKE) snippets

clean:
	rm -rf ../_includes/GN
	rm -f Stata/gn_ddml_package.log
