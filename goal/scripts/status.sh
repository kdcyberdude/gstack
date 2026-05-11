#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_resolve_root.sh
source "${SCRIPT_DIR}/_resolve_root.sh"

RAW="${1:-}"
NEXT="$(printf '%s' "${RAW}" | tr '[:upper:]' '[:lower:]')"

case "${NEXT}" in
  pause)
    STATUS="paused"
    ;;
  active | resume)
    STATUS="active"
    ;;
  complete)
    STATUS="complete"
    ;;
  *)
    echo "usage: status.sh pause|active|resume|complete" >&2
    exit 1
    ;;
esac

STATE="${ROOT}/.goal/state.json"

if [[ ! -f "${STATE}" ]]; then
  echo "error: no goal to update (missing ${STATE})" >&2
  exit 1
fi

python3 - "${STATE}" "${STATUS}" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

path = Path(sys.argv[1])
new_status = sys.argv[2]
now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

data = json.loads(path.read_text(encoding="utf-8"))
data["status"] = new_status
data["updated_at"] = now
path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY

echo "Goal status updated to ${STATUS}."
