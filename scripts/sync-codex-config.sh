#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_FILE="${REPO_ROOT}/codex/config.base.toml"
TARGET_FILE="${HOME}/.codex/config.toml"
BACKUP_ROOT="${HOME}/.dotfiles-backups/$(date +%Y%m%d-%H%M%S)"
MARKER="# --- machine-local runtime state below ---"

mkdir -p "$(dirname "${TARGET_FILE}")"

base_content="$(cat "${BASE_FILE}")"
local_tail=""

if [[ -e "${TARGET_FILE}" || -L "${TARGET_FILE}" ]]; then
  target_content="$(cat "${TARGET_FILE}" 2>/dev/null || true)"

  if grep -Fq "${MARKER}" "${TARGET_FILE}" 2>/dev/null; then
    local_tail="$(awk -v marker="${MARKER}" '
      $0 == marker { found=1; next }
      found { print }
    ' "${TARGET_FILE}")"
  elif [[ "${target_content}" == "${base_content}"* ]]; then
    local_tail="${target_content#"$base_content"}"
  fi

  if [[ -L "${TARGET_FILE}" || "${target_content}" != *"${MARKER}"* ]]; then
    backup_path="${BACKUP_ROOT}${TARGET_FILE}"
    mkdir -p "$(dirname "${backup_path}")"
    mv "${TARGET_FILE}" "${backup_path}"
    printf 'backup %s -> %s\n' "${TARGET_FILE}" "${backup_path}"
  fi
fi

{
  printf '%s\n\n' "${base_content}"
  printf '%s\n' "${MARKER}"
  printf '# Codex may append project trust entries and other runtime-only state here.\n'
  if [[ -n "${local_tail}" ]]; then
    printf '\n%s\n' "${local_tail}"
  fi
} > "${TARGET_FILE}"

printf 'write  %s\n' "${TARGET_FILE}"
