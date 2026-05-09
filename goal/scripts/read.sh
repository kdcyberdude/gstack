#!/usr/bin/env bash
set -euo pipefail

eval "$(~/.claude/skills/gstack/bin/gstack-paths 2>/dev/null)" 2>/dev/null || true
ROOT="${GSTACK_STATE_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

STATE="${ROOT}/.goal/state.json"

if [[ ! -f "${STATE}" ]]; then
  echo "No goal set"
  exit 0
fi

python3 - "${STATE}" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
try:
    data = json.loads(path.read_text(encoding="utf-8"))
except json.JSONDecodeError:
    print("Goal file corrupted")
    sys.exit(1)

obj = data.get("objective", "")
status = data.get("status", "")
created = data.get("created_at", "")
updated = data.get("updated_at", "")

print(f"[Project goal]")
print(f"Status: {status}")
print(f"Objective: {obj}")
if created:
    print(f"Created: {created}")
if updated:
    print(f"Updated: {updated}")
PY
