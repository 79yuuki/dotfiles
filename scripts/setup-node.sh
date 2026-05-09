#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NVM_VERSION="${NVM_VERSION:-v0.40.4}"
NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
DEFAULT_VERSION_FILE="${REPO_ROOT}/node/default-version"
VERSIONS_FILE="${REPO_ROOT}/node/versions.txt"
DEFAULT_PACKAGES_FILE="${REPO_ROOT}/node/default-packages"

install_nvm() {
  if [[ -s "${NVM_DIR}/nvm.sh" ]]; then
    return
  fi

  printf 'installing nvm into %s\n' "${NVM_DIR}"
  mkdir -p "${NVM_DIR}"
  git clone https://github.com/nvm-sh/nvm.git "${NVM_DIR}"
  (
    cd "${NVM_DIR}"
    git checkout "${NVM_VERSION}"
  )
}

load_nvm() {
  export NVM_DIR
  # shellcheck disable=SC1090
  . "${NVM_DIR}/nvm.sh"
  if [[ -s "${NVM_DIR}/bash_completion" ]]; then
    # shellcheck disable=SC1090
    . "${NVM_DIR}/bash_completion"
  fi
}

install_versions() {
  while IFS= read -r version || [[ -n "${version}" ]]; do
    [[ -z "${version}" ]] && continue
    [[ "${version}" =~ ^# ]] && continue
    printf 'nvm install %s\n' "${version}"
    nvm install "${version}"
  done < "${VERSIONS_FILE}"
}

link_default_packages() {
  mkdir -p "${NVM_DIR}"
  ln -snf "${DEFAULT_PACKAGES_FILE}" "${NVM_DIR}/default-packages"
  printf 'link %s -> %s\n' "${NVM_DIR}/default-packages" "${DEFAULT_PACKAGES_FILE}"
}

set_default_version() {
  local default_version
  default_version="$(tr -d '[:space:]' < "${DEFAULT_VERSION_FILE}")"
  printf 'nvm alias default %s\n' "${default_version}"
  nvm alias default "${default_version}"
  nvm use default
}

enable_corepack() {
  if command -v corepack >/dev/null 2>&1; then
    corepack enable
    printf 'corepack enabled\n'
  fi
}

main() {
  if ! command -v git >/dev/null 2>&1; then
    printf 'git is required to install nvm\n' >&2
    exit 1
  fi

  install_nvm
  load_nvm
  link_default_packages
  install_versions
  set_default_version
  enable_corepack

  printf '\nnode setup complete\n'
  printf 'default node: %s\n' "$(node -v)"
  printf 'npm: %s\n' "$(npm -v)"
}

main "$@"
