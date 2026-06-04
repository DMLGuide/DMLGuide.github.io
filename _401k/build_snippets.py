#!/usr/bin/env python3
"""Extract `@snippet:NAME ... @end` blocks from the _401k sources/logs.

Walks _401k/{R,Python,Stata}, extracts each marked section, and writes it
to `_includes/401k/<name>_<lang>.txt` where <lang> is r / python / stata.

Markers (comment-style, on their own line):
    R / Python / output logs:  # @snippet:NAME    ...   # @end
    Stata source (.do):        // @snippet:NAME   ...   // @end

The marker lines themselves are stripped from the extracted snippet.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent  # website root
SRC_DIRS = {
    "r":      ROOT / "_401k" / "R",
    "python": ROOT / "_401k" / "Python",
    "stata":  ROOT / "_401k" / "Stata",
}
OUT_DIR = ROOT / "_includes" / "401k"

SNIPPET_START = re.compile(r"(?:#|//)\s*@snippet:(\w+)\s*$")
SNIPPET_END   = re.compile(r"(?:#|//)\s*@end\s*$")
# Strip Stata `display "###BEGIN_OUT:..."` / `display "###END_OUT:..."` helper
# lines used by run_stata.py to slice the log into per-snippet outputs.
STATA_OUT_MARKER = re.compile(r'^\s*display\s+"###(?:BEGIN|END)_OUT:[^"]*"\s*$')


def extract(text: str) -> dict[str, str]:
    """Return {snippet_name: content} parsed from `text`."""
    snippets: dict[str, str] = {}
    current: str | None = None
    buf: list[str] = []
    for line in text.splitlines():
        if current is None:
            m = SNIPPET_START.search(line)
            if m:
                current = m.group(1)
                buf = []
            continue
        if SNIPPET_END.search(line):
            snippets[current] = "\n".join(buf).rstrip() + "\n"
            current = None
            buf = []
            continue
        # Watch for nested snippets — error early.
        if SNIPPET_START.search(line):
            raise SystemExit(
                f"Nested @snippet found inside `{current}` at line:\n  {line!r}"
            )
        # Strip Stata output-fence markers from CODE snippets.
        if STATA_OUT_MARKER.search(line):
            continue
        buf.append(line)
    if current is not None:
        raise SystemExit(f"Unterminated @snippet:{current} (missing @end)")
    return snippets


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    written: list[str] = []
    for lang, src_dir in SRC_DIRS.items():
        if not src_dir.is_dir():
            print(f"WARN: {src_dir} not found", file=sys.stderr)
            continue
        for path in sorted(src_dir.iterdir()):
            if not path.is_file():
                continue
            # Only parse source files and the canonical output logs.
            if path.suffix.lower() not in {".r", ".py", ".do", ".txt"}:
                continue
            try:
                snippets = extract(path.read_text())
            except SystemExit as e:
                raise SystemExit(f"{path}: {e}")
            for name, content in snippets.items():
                out_path = OUT_DIR / f"{name}_{lang}.txt"
                out_path.write_text(content)
                written.append(out_path.name)

    print(f"Wrote {len(written)} snippets to {OUT_DIR.relative_to(ROOT)}:")
    for w in sorted(written):
        print(f"  {w}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
