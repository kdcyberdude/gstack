#!/usr/bin/env bash
# shellcheck shell=bash
# Resolve the project workspace root for .goal/ state. Sets ROOT.

if [[ -n "${GOAL_PROJECT_ROOT:-}" ]]; then
  ROOT="${GOAL_PROJECT_ROOT}"
elif [[ -n "${CURSOR_PROJECT_DIR:-}" ]]; then
  ROOT="${CURSOR_PROJECT_DIR}"
elif [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
  ROOT="${CLAUDE_PROJECT_DIR}"
else
  dir="$(pwd)"
  ROOT=""
  while [[ "${dir}" != "/" ]]; do
    if [[ -d "${dir}/.git" ]] || [[ -f "${dir}/.git" ]]; then
      ROOT="$(git -C "${dir}" rev-parse --show-toplevel 2>/dev/null || echo "${dir}")"
      break
    fi
    dir="$(dirname "${dir}")"
  done
  [[ -z "${ROOT}" ]] && ROOT="$(pwd)"
fi
