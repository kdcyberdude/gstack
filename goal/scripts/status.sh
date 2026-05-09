#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: status.sh <active|paused|complete>" >&2
  exit 1
fi

NEW_STATUS="${1}"

eval "$(~/.claude/skills/gstack/bin/gstack-paths 2>/dev/null)" 2>/dev/null || true
ROOT="${GSTACK_STATE_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

STATE="${ROOT}/.goal/state.json"

python3 - "${STATE}" "${NEW_STATUS}" <<'PY'
import json, sys
from datetime import datetime, timezone
from pathlib import Path

path = Path(sys.argv[1])
new_status = sys.argv[2]

if not path.is_file():
    print("error: no goal set", file=sys.stderr)
    sys.exit(1)

try:
    data = json.loads(path.read_text(encoding="utf-8"))
except json.JSONDecodeError:
    data = {}

data["status"] = new_status
data["updated_at"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY

echo "Status set to ${NEW_STATUS}."
