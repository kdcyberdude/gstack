#!/usr/bin/env bash
set -euo pipefail

eval "$(~/.claude/skills/gstack/bin/gstack-paths 2>/dev/null)" 2>/dev/null || true
ROOT="${GSTACK_STATE_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

STATE="${ROOT}/.goal/state.json"
PLAN="${ROOT}/.goal/plan.md"
RESOURCES="${ROOT}/.goal/resources.md"

if [[ ! -f "${STATE}" ]]; then
  echo "No goal to clear."
  exit 0
fi

rm -f "${STATE}" "${PLAN}" "${RESOURCES}"
echo "Goal cleared."
