#!/usr/bin/env bash
set -euo pipefail

# Append an update entry to the coordinator's Session Log.
# Usage: update.sh <category> <message>
# Categories: session_work, goal_completion, milestone, decision, experiment

if [[ $# -lt 2 ]]; then
  echo "usage: update.sh <category> <message>" >&2
  exit 1
fi

CATEGORY="${1}"
MESSAGE="${2}"

eval "$(~/.claude/skills/gstack/bin/gstack-paths 2>/dev/null)" 2>/dev/null || true
ROOT="${GSTACK_STATE_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

COORDINATOR="${ROOT}/.memory/coordinator_spoc.md"
TODAY=$(date -u +%Y-%m-%d)

if [[ ! -f "${COORDINATOR}" ]]; then
  echo "No coordinator found. Run init.sh first." >&2
  exit 1
fi

# Append to Session Log section
python3 - "${COORDINATOR}" "${TODAY}" "${CATEGORY}" "${MESSAGE}" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
today = sys.argv[2]
category = sys.argv[3]
message = sys.argv[4]

content = path.read_text(encoding="utf-8")

# Find or create Session Log section
log_line = f"- {today} — [{category}] {message}"
if "## Session Log" in content:
    # Insert before the end of the file or before ## Session Log
    idx = content.rindex("## Session Log")
    before = content[:idx]
    after = content[idx:]
    content = before + after.replace("## Session Log\n", f"## Session Log\n\n{log_line}\n", 1)
else:
    content += f"\n## Session Log\n\n{log_line}\n"

path.write_text(content, encoding="utf-8")
PY

echo "Updated coordinator: [${CATEGORY}] ${MESSAGE}"
