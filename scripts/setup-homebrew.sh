#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BREWFILE="${REPO_ROOT}/Brewfile"

if ! command -v brew >/dev/null 2>&1; then
  printf 'Homebrew is required. Install Homebrew first.\n' >&2
  exit 1
fi

printf 'using Brewfile: %s\n' "${BREWFILE}"
brew bundle --file="${BREWFILE}"
