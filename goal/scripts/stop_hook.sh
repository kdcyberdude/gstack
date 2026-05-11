#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_resolve_root.sh
source "${SCRIPT_DIR}/_resolve_root.sh"

HOOK_JSON="$(cat || true)"
export HOOK_JSON
export GOAL_PROJECT_ROOT="${ROOT}"

STATE="${ROOT}/.goal/state.json"
PLAN="${ROOT}/.goal/plan.md"

python3 - "${STATE}" "${PLAN}" <<'PY'
import json
import os
import re
import sys
from pathlib import Path

state_path = Path(sys.argv[1])
plan_path = Path(sys.argv[2])
raw = os.environ.get("HOOK_JSON") or ""
try:
    hook_in = json.loads(raw) if raw.strip() else {}
except json.JSONDecodeError:
    hook_in = {}

status = hook_in.get("status")
if status != "completed":
    print("{}")
    raise SystemExit(0)

loop_count = hook_in.get("loop_count")
if isinstance(loop_count, int) and loop_count >= 5:
    print("{}")
    raise SystemExit(0)

if not state_path.is_file():
    print("{}")
    raise SystemExit(0)

try:
    data = json.loads(state_path.read_text(encoding="utf-8"))
except json.JSONDecodeError:
    print("{}")
    raise SystemExit(0)

if data.get("status") != "active":
    print("{}")
    raise SystemExit(0)

objective = (data.get("objective") or "").strip()
if not objective:
    print("{}")
    raise SystemExit(0)

plan_text = plan_path.read_text(encoding="utf-8") if plan_path.is_file() else ""
unchecked = []
for line in plan_text.splitlines():
    stripped = line.strip()
    if re.match(r"^- \[ \]", stripped):
        unchecked.append(stripped)
    elif re.match(r"^\d+\.\s+\S", stripped) and not stripped.endswith("done"):
        unchecked.append(stripped)

if not unchecked:
    print("{}")
    raise SystemExit(0)

next_item = unchecked[0]
message = (
    "Continue the active project goal. Re-read `.goal/plan.md` and `.goal/state.json`, "
    f"then work the next unchecked item: {next_item}. Objective: {objective}"
)
print(json.dumps({"followup_message": message}))
PY
