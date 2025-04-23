#!/usr/bin/env python3
"""
output.py  <issue-body-file>  <output-dir>

Parses markdown headings and writes a simple text file:
  Constraint Name: Boolean
  Constraint Type: Boolean
  ...
"""

import os
import sys
import re
import logging
from typing import Dict, Optional
from MainMethods import createConstraintAtPath

# ---------- Logging ---------- #
logging.basicConfig(level=logging.INFO, format="%(levelname)s | %(message)s")
log = logging.getLogger(__name__)

# --------- Parser ------------ #
HEADING_RE = re.compile(r"^###\s+(.*)$")

def parse_issue_markdown(text: str) -> Dict[str, Optional[str]]:
    data: Dict[str, Optional[str]] = {}
    current, buf = None, []

    def flush():
        nonlocal buf, current
        if current is not None:
            val = "\n".join(buf).strip()
            if val.lower() in ("", "_no response_", "none"):
                val = None
            data[current] = val
        buf.clear()

    for line in text.splitlines():
        m = HEADING_RE.match(line)
        if m:
            flush()
            current = m.group(1).strip()
        else:
            buf.append(line)
    flush()
    return data

def make_plain_text(d: Dict[str, Optional[str]]) -> str:
    """Turn dict into simple key: value lines."""
    lines = []
    for k, v in d.items():
        lines.append(f"{k}: {v if v is not None else 'null'}")
    return "\n".join(lines) + "\n"

# ----------- Main ------------ #
def main(body_path: str, out_dir: str) -> None:
    log.info("Reading issue body: %s", body_path)
    with open(body_path, "r", encoding="utf-8") as f:
        body = f.read()

    parsed = parse_issue_markdown(body)
    log.info("Parsed headings: %s", list(parsed.keys()))

    file_stem = (parsed.get("Constraint Name") or "unnamed_constraint") \
                  .replace("/", "_").replace(" ", "_")

    os.makedirs(out_dir, exist_ok=True)
    log.info("Output directory ensured: %s", out_dir)

    content = make_plain_text(parsed)
    createConstraintAtPath(out_dir, file_stem, content)

    out_file = os.path.join(out_dir, f"{file_stem}.yaml")
    if os.path.isfile(out_file):
        log.info("✅ File written: %s", out_file)
    else:
        log.error("❌ Expected file not found after createConstraintAtPath")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        log.error("Usage: output.py <body.md> <output-dir>")
        sys.exit(1)

    main(sys.argv[1], sys.argv[2])
