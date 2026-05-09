#!/usr/bin/env bash
set -euo pipefail

# Initialize .memory/coordinator_spoc.md from the node template.
# Usage: init.sh [project-name]

eval "$(~/.claude/skills/gstack/bin/gstack-paths 2>/dev/null)" 2>/dev/null || true
ROOT="${GSTACK_STATE_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"

MEMORY_DIR="${ROOT}/.memory"
COORDINATOR="${MEMORY_DIR}/coordinator_spoc.md"
TODAY=$(date -u +%Y-%m-%d)
PROJECT_NAME="${1:-$(basename "${ROOT}")}"

mkdir -p "${MEMORY_DIR}"

if [[ -f "${COORDINATOR}" ]]; then
  echo "Coordinator already exists at ${COORDINATOR}"
  exit 0
fi

cat > "${COORDINATOR}" <<EOF
# Coordinator (${PROJECT_NAME})

## Core Mandate

SPOC for ${PROJECT_NAME}. Routes tasks to domain delegates, preserves institutional knowledge, and tracks decisions across sessions.

## Current State

- Coordinator initialized on ${TODAY}
- No delegates created yet

## Hypothesis Graveyard

<!-- What we tried, why it failed, what we learned. -->

## Decisions & Rationale

<!-- Why we chose this approach; user preferences; SOPs. -->

## Delegate Index (Max 3 Levels)

<!-- Child nodes under .memory/ with relative links. -->

## Relevant Experts (Direct Access)

<!-- Frequently accessed experts across the project. -->

## Full System Map

Read [full_hierarchy.md](./full_hierarchy.md) for the complete list of all active delegates.

## Session Log

- ${TODAY} — Coordinator initialized for ${PROJECT_NAME}
EOF

echo "Coordinator initialized at ${COORDINATOR}"
