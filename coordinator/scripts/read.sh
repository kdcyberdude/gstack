#!/usr/bin/env bash
set -euo pipefail

# Read and display the coordinator state.
# Usage: read.sh

eval "$(~/.claude/skills/gstack/bin/gstack-paths 2>/dev/null)" 2>/dev/null || true
ROOT="${GSTACK_STATE_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

COORDINATOR="${ROOT}/.memory/coordinator_spoc.md"

if [[ ! -f "${COORDINATOR}" ]]; then
  echo "No coordinator found. Initialize with: coordinator/scripts/init.sh"
  exit 0
fi

cat "${COORDINATOR}"
