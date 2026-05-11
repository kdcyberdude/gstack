#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_resolve_root.sh
source "${SCRIPT_DIR}/_resolve_root.sh"

OBJECTIVE="${*}"
OBJECTIVE="${OBJECTIVE#"${OBJECTIVE%%[![:space:]]*}"}"
OBJECTIVE="${OBJECTIVE%"${OBJECTIVE##*[![:space:]]}"}"

if [[ -z "${OBJECTIVE}" ]]; then
  echo "error: objective must not be empty" >&2
  exit 1
fi

GOAL_DIR="${ROOT}/.goal"
STATE="${GOAL_DIR}/state.json"
PLAN="${GOAL_DIR}/plan.md"
RESOURCES="${GOAL_DIR}/resources.md"

mkdir -p "${GOAL_DIR}"

if [[ ! -f "${PLAN}" ]]; then
  echo "# Active Plan" > "${PLAN}"
  echo "1. " >> "${PLAN}"
fi

if [[ ! -f "${RESOURCES}" ]]; then
  echo "# Resources Inbox" > "${RESOURCES}"
  echo "Drop links, ideas, and snippets here for the agent to triage." >> "${RESOURCES}"
fi

python3 - "${STATE}" "${OBJECTIVE}" <<'PY'
import json
import sys
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
