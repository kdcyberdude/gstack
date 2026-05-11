#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_resolve_root.sh
source "${SCRIPT_DIR}/_resolve_root.sh"

STATE="${ROOT}/.goal/state.json"
PLAN="${ROOT}/.goal/plan.md"
RESOURCES="${ROOT}/.goal/resources.md"
HOOK_JSON="$(cat || true)"

export HOOK_JSON
python3 - "${STATE}" "${PLAN}" "${RESOURCES}" <<'PY'
import json
import os
import sys
from pathlib import Path

state_path = Path(sys.argv[1])
plan_path = Path(sys.argv[2])
resources_path = Path(sys.argv[3])
raw = os.environ.get("HOOK_JSON") or ""
try:
    hook_in = json.loads(raw) if raw.strip() else {}
except json.JSONDecodeError:
    hook_in = {}

data = {}
if state_path.is_file():
    try:
        data = json.loads(state_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        data = {}

obj = data.get("objective", "")
status = data.get("status", "")
created = data.get("created_at", "")
updated = data.get("updated_at", "")
lines = [
    "[Project goal]",
    f"Status: {status}",
    f"Objective: {obj}",
]
if created:
    lines.append(f"Created: {created}")
if updated:
    lines.append(f"Updated: {updated}")

if plan_path.is_file():
    plan_content = plan_path.read_text(encoding="utf-8").strip()
    if plan_content:
        lines.append(f"\n[Active Plan]\n{plan_content}")

if resources_path.is_file():
    res_content = resources_path.read_text(encoding="utf-8").strip()
    if res_content and "Drop links, ideas, and snippets here for the agent to triage." not in res_content:
        lines.append(f"\n[Resources Inbox]\n{res_content}")

lines.append(
    "\nChange via the goal skill: set objective, or pause / resume / clear when supported."
)
ctx = "\n".join(lines)

cursorish = hook_in.get("hook_event_name") is None and (
    "composer_mode" in hook_in or "is_background_agent" in hook_in
)
if cursorish:
    out = {"additional_context": ctx}
else:
    out = {
        "hookSpecificOutput": {
            "hookEventName": "SessionStart",
            "additionalContext": ctx,
        }
    }
print(json.dumps(out))
PY
