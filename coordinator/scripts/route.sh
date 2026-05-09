#!/usr/bin/env bash
set -euo pipefail

# Find the right delegate for a task by scanning the coordinator's Delegate Index.
# Usage: route.sh <task-description>

if [[ $# -lt 1 ]]; then
  echo "usage: route.sh <task-description>" >&2
  exit 1
fi

TASK="${*}"

eval "$(~/.claude/skills/gstack/bin/gstack-paths 2>/dev/null)" 2>/dev/null || true
ROOT="${GSTACK_STATE_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

COORDINATOR="${ROOT}/.memory/coordinator_spoc.md"

if [[ ! -f "${COORDINATOR}" ]]; then
  echo "No coordinator found. Run init.sh first." >&2
  exit 1
fi

echo "[Routing: ${TASK}]"
echo "---"

# Extract delegate links from Delegate Index section
python3 - "${COORDINATOR}" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
content = path.read_text(encoding="utf-8")

# Find Delegate Index section
in_section = False
delegates = []
for line in content.split("\n"):
    if "## Delegate Index" in line:
        in_section = True
        continue
    if in_section:
        if line.startswith("## "):
            break
        if line.strip().startswith("- ["):
            delegates.append(line.strip())

if delegates:
    print("Available delegates:")
    for d in delegates:
        print(f"  {d}")
else:
    print("No delegates created yet. All tasks route to the coordinator.")
PY

echo "---"
echo "Match the task to a delegate or keep it in the coordinator."
