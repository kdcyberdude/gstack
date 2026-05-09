#!/usr/bin/env bash
set -euo pipefail

# check_limit.sh — Ensures no .memory/*.md file exceeds the 75,000-word threshold.
# Exit 0: All files are under the threshold.
# Exit 2: One or more files are at or over 75,000 words (triggers delegation).

eval "$(~/.claude/skills/gstack/bin/gstack-paths 2>/dev/null)" 2>/dev/null || true
ROOT="${GSTACK_STATE_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

MEMORY_DIR="${ROOT}/.memory"
THRESHOLD=75000

if [ ! -d "$MEMORY_DIR" ]; then
  echo "No .memory directory found. Exiting cleanly."
  exit 0
fi

OVER_LIMIT=false

for file in "$MEMORY_DIR"/*.md; do
  [ -f "$file" ] || continue
  WORD_COUNT=$(wc -w < "$file")
  if [ "$WORD_COUNT" -ge "$THRESHOLD" ]; then
    echo "OVER LIMIT: $file ($WORD_COUNT words / $THRESHOLD threshold)"
    OVER_LIMIT=true
  fi
done

if $OVER_LIMIT; then
  echo "One or more files have exceeded the word threshold. Run the delegation SOP."
  exit 2
fi

echo "All .memory/*.md files are under the word threshold."
exit 0
