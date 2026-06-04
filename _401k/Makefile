# Make targets for the 401k application.
#
# `make snippets`  — extract @snippet sections from _401k/{R,Python,Stata}
#                    into _includes/401k/.
# `make stata-run` — invoke Stata in batch mode to refresh the Stata
#                    output log, then regenerate snippets. Requires
#                    STATA_BIN (defaults to
#                    /Applications/StataNow/StataSE.app/Contents/MacOS/stata-se).

PY ?= python3

.PHONY: snippets stata-run clean

snippets:
	$(PY) build_snippets.py

stata-run:
	$(PY) run_stata.py
	$(MAKE) snippets

clean:
	rm -rf ../_includes/401k
	rm -f Stata/pvw_ddml_package.log
