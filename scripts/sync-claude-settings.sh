#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_FILE="${REPO_ROOT}/claude/settings.base.json"
TARGET_FILE="${HOME}/.claude/settings.json"
LOCAL_OVERRIDE_FILE="${HOME}/.claude/settings.local.json"
BACKUP_ROOT="${HOME}/.dotfiles-backups/$(date +%Y%m%d-%H%M%S)"

mkdir -p "$(dirname "${TARGET_FILE}")"

if [[ -L "${TARGET_FILE}" ]]; then
  backup_path="${BACKUP_ROOT}${TARGET_FILE}"
  mkdir -p "$(dirname "${backup_path}")"
  mv "${TARGET_FILE}" "${backup_path}"
  printf 'backup %s -> %s\n' "${TARGET_FILE}" "${backup_path}"
elif [[ -e "${TARGET_FILE}" ]]; then
  base_compact="$(python3 -c 'import json,sys; print(json.dumps(json.load(open(sys.argv[1])), sort_keys=True, separators=(",",":")))' "${BASE_FILE}")"
  target_compact="$(python3 -c 'import json,sys; print(json.dumps(json.load(open(sys.argv[1])), sort_keys=True, separators=(",",":")))' "${TARGET_FILE}" 2>/dev/null || true)"
  if [[ "${target_compact}" != "${base_compact}" ]]; then
    backup_path="${BACKUP_ROOT}${TARGET_FILE}"
    mkdir -p "$(dirname "${backup_path}")"
    cp "${TARGET_FILE}" "${backup_path}"
    printf 'backup %s -> %s\n' "${TARGET_FILE}" "${backup_path}"
  fi
fi

python3 - "${BASE_FILE}" "${LOCAL_OVERRIDE_FILE}" "${TARGET_FILE}" <<'PY'
import json
import sys
from pathlib import Path

base_path = Path(sys.argv[1])
override_path = Path(sys.argv[2])
target_path = Path(sys.argv[3])

def deep_merge(left, right):
    if isinstance(left, dict) and isinstance(right, dict):
        merged = dict(left)
        for key, value in right.items():
            if key in merged:
                merged[key] = deep_merge(merged[key], value)
            else:
                merged[key] = value
        return merged
    return right

with base_path.open() as fh:
    data = json.load(fh)

if override_path.exists():
    with override_path.open() as fh:
        override = json.load(fh)
    data = deep_merge(data, override)

target_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
PY

printf 'write  %s\n' "${TARGET_FILE}"
