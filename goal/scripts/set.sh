#!/usr/bin/env bash
set -euo pipefail

OBJECTIVE="${*}"
OBJECTIVE="${OBJECTIVE#"${OBJECTIVE%%[![:space:]]*}"}"
OBJECTIVE="${OBJECTIVE%"${OBJECTIVE##*[![:space:]]}"}"

if [[ -z "${OBJECTIVE}" ]]; then
  echo "error: objective must not be empty" >&2
  exit 1
fi

eval "$(~/.claude/skills/gstack/bin/gstack-paths 2>/dev/null)" 2>/dev/null || true
ROOT="${GSTACK_STATE_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

GOAL_DIR="${ROOT}/.goal"
STATE="${GOAL_DIR}/state.json"
PLAN="${GOAL_DIR}/plan.md"
RESOURCES="${GOAL_DIR}/resources.md"

mkdir -p "${GOAL_DIR}"

if [[ ! -f "${PLAN}" ]]; then
  printf '# Active Plan\n1. \n' > "${PLAN}"
fi

if [[ ! -f "${RESOURCES}" ]]; then
  printf '# Resources Inbox\nDrop links, ideas, and snippets here for the agent to triage.\n' > "${RESOURCES}"
fi

python3 - "${STATE}" "${OBJECTIVE}" <<'PY'
import json, sys
from datetime import datetime, timezone
from pathlib import Path

path = Path(sys.argv[1])
objective = sys.argv[2]
now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

if path.is_file():
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        data = {}
    created = data.get("created_at") or now
else:
    created = now

out = {
    "objective": objective,
    "status": "active",
    "created_at": created,
    "updated_at": now,
}
path.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
PY

echo "Goal saved (active)."
