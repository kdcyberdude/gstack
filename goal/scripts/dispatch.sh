#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_resolve_root.sh
source "${SCRIPT_DIR}/_resolve_root.sh"

export GOAL_PROJECT_ROOT="${ROOT}"

RAW="${*}"
RAW="${RAW#"${RAW%%[![:space:]]*}"}"
RAW="${RAW%"${RAW##*[![:space:]]}"}"

while [[ -n "${RAW}" ]]; do
  VERB="$(printf '%s' "${RAW}" | awk '{print tolower($1)}')"
  REST="$(printf '%s' "${RAW}" | awk '{$1=""; sub(/^ /, ""); print}')"
  case "${VERB}" in
    /goal | goal)
      RAW="${REST}"
      ;;
    pause | stop)
      bash "${SCRIPT_DIR}/status.sh" pause
      exec bash "${SCRIPT_DIR}/read.sh"
      ;;
    resume)
      bash "${SCRIPT_DIR}/status.sh" active
      exec bash "${SCRIPT_DIR}/read.sh"
      ;;
    complete)
      bash "${SCRIPT_DIR}/status.sh" complete
      exec bash "${SCRIPT_DIR}/read.sh"
      ;;
    clear)
      bash "${SCRIPT_DIR}/clear.sh"
      exec bash "${SCRIPT_DIR}/read.sh"
      ;;
    status)
      exec bash "${SCRIPT_DIR}/read.sh"
      ;;
    set)
      if [[ -z "${REST}" ]]; then
        echo "error: objective must not be empty" >&2
        exit 1
      fi
      bash "${SCRIPT_DIR}/set.sh" "${REST}"
      exec bash "${SCRIPT_DIR}/read.sh"
      ;;
    *)
      bash "${SCRIPT_DIR}/set.sh" "${RAW}"
      exec bash "${SCRIPT_DIR}/read.sh"
      ;;
  esac
done

exec bash "${SCRIPT_DIR}/read.sh"
