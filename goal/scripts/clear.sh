#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_resolve_root.sh
source "${SCRIPT_DIR}/_resolve_root.sh"

STATE="${ROOT}/.goal/state.json"
PLAN="${ROOT}/.goal/plan.md"
RESOURCES="${ROOT}/.goal/resources.md"

if [[ ! -f "${STATE}" ]]; then
  echo "No goal to clear."
  exit 0
fi

rm -f "${STATE}" "${PLAN}" "${RESOURCES}"
echo "Goal cleared."
