#!/usr/bin/env bash
set -euo pipefail

# Session start: reads .goal/ files and outputs formatted context for preamble injection.
# Unlike tess-plugins' hook-based approach, this script outputs plain text for
# gstack's preamble bash block to consume directly.

eval "$(~/.claude/skills/gstack/bin/gstack-paths 2>/dev/null)" 2>/dev/null || true
ROOT="${GSTACK_STATE_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

STATE="${ROOT}/.goal/state.json"
PLAN="${ROOT}/.goal/plan.md"
RESOURCES="${ROOT}/.goal/resources.md"

if [[ ! -f "${STATE}" ]]; then
  echo "GOAL_STATUS: none"
  exit 0
fi

python3 - "${STATE}" "${PLAN}" "${RESOURCES}" <<'PY'
import json
import sys
from pathlib import Path

state_path = Path(sys.argv[1])
plan_path = Path(sys.argv[2])
resources_path = Path(sys.argv[3])

try:
    data = json.loads(state_path.read_text(encoding="utf-8"))
except json.JSONDecodeError:
    data = {}

obj = data.get("objective", "")
status = data.get("status", "")
created = data.get("created_at", "")
updated = data.get("updated_at", "")

print(f"GOAL_STATUS: {status}")
print(f"GOAL_OBJECTIVE: {obj}")
if created:
    print(f"GOAL_CREATED: {created}")
if updated:
    print(f"GOAL_UPDATED: {updated}")

if plan_path.is_file():
    plan_content = plan_path.read_text(encoding="utf-8").strip()
    if plan_content:
        print(f"GOAL_PLAN:")
        print(plan_content)

if resources_path.is_file():
    res_content = resources_path.read_text(encoding="utf-8").strip()
    # Don't show if it's just the default placeholder
    if res_content and "Drop links, ideas, and snippets here for the agent to triage." not in res_content:
        print(f"GOAL_RESOURCES:")
        print(res_content)
PY
