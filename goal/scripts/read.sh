#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_resolve_root.sh
source "${SCRIPT_DIR}/_resolve_root.sh"

STATE="${ROOT}/.goal/state.json"

if [[ ! -f "${STATE}" ]]; then
  echo "No goal set"
  exit 0
fi

python3 - "${STATE}" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))
obj = data.get("objective", "")
status = data.get("status", "")
created = data.get("created_at", "")
updated = data.get("updated_at", "")
print("Goal")
print(f"  Status:    {status}")
print(f"  Objective: {obj}")
if created:
    print(f"  Created:   {created}")
if updated:
    print(f"  Updated:   {updated}")
PY
