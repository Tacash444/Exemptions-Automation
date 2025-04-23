from MainMethods import createConstraintAtPath
import sys
from typing import Dict
import re

HEADING_RE = re.compile(r"^###\s+(.*)$")

def parse_issue_markdown(text: str) -> Dict[str, str | None]:
    lines = text.splitlines()
    data: Dict[str, str | None] = {}

    current_key = None
    buffer = []

    def flush():
        nonlocal buffer, current_key
        if current_key is not None:
            value = "\n".join(buffer).strip()
            # Treat GitHub's _No response_ (or empty) as None
            if value == "" or value.lower() == "_no response_":
                value = None
            data[current_key] = value
        buffer = []

    for line in lines:
        m = HEADING_RE.match(line)
        if m:
            flush()
            current_key = m.group(1).strip()
        else:
            # Collect content lines until next heading
            buffer.append(line)
    flush()  # last block
    return data

if __name__ == "__main__":
    issue_body_path = sys.argv[1]             # e.g., tmp/body.md
    
    with open(issue_body_path, 'r') as f:
        body = f.read()

    constraint_data = parse_issue_markdown(body)
    createConstraintAtPath("./check", "checking", constraint_data)
