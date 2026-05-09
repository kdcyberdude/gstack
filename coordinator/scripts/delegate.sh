#!/usr/bin/env bash
set -euo pipefail

# Create a new delegate node from the template.
# Usage: delegate.sh <delegate-name> [<parent-file>]
# Example: delegate.sh auth_specialist coordinator_spoc.md

if [[ $# -lt 1 ]]; then
  echo "usage: delegate.sh <delegate-name> [<parent-file>]" >&2
  exit 1
fi

DELEGATE_NAME="${1}"
PARENT="${2:-coordinator_spoc.md}"

eval "$(~/.claude/skills/gstack/bin/gstack-paths 2>/dev/null)" 2>/dev/null || true
ROOT="${GSTACK_STATE_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"

MEMORY_DIR="${ROOT}/.memory"
DELEGATE_FILE="${MEMORY_DIR}/${DELEGATE_NAME}.md"
TODAY=$(date -u +%Y-%m-%d)
TEMPLATE="${SKILL_ROOT}/templates/node_template.md"

if [[ -f "${DELEGATE_FILE}" ]]; then
  echo "Delegate ${DELEGATE_NAME} already exists at ${DELEGATE_FILE}"
  exit 0
fi

mkdir -p "${MEMORY_DIR}"

# Create delegate from template or inline default
if [[ -f "${TEMPLATE}" ]]; then
  sed "s/<Node Title>/${DELEGATE_NAME}/g; s/<YYYY-MM-DD>/${TODAY}/g" "${TEMPLATE}" > "${DELEGATE_FILE}"
else
  cat > "${DELEGATE_FILE}" <<EOF
# ${DELEGATE_NAME}

## Core Mandate

<!-- What this delegate owns. -->

## Current State

- Created on ${TODAY} as a delegate of ${PARENT}

## Hypothesis Graveyard

<!-- What we tried, why it failed, what we learned. -->

## Decisions & Rationale

<!-- Why we chose this approach. -->

## Delegate Index (Max 3 Levels)

<!-- Child nodes. -->

## Session Log

- ${TODAY} — Created as delegate of ${PARENT}
EOF
fi

echo "Delegate created: ${DELEGATE_FILE}"
echo "Update the parent (${PARENT}) Delegate Index to link to this file."
