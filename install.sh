#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_ROOT="${HOME}/.dotfiles-backups/$(date +%Y%m%d-%H%M%S)"

link_file() {
  local source_path="$1"
  local target_path="$2"
  local target_dir

  target_dir="$(dirname "${target_path}")"
  mkdir -p "${target_dir}"

  if [[ -e "${target_path}" || -L "${target_path}" ]]; then
    local current_target=""
    if [[ -L "${target_path}" ]]; then
      current_target="$(readlink "${target_path}")"
    fi
    if [[ "${current_target}" == "${source_path}" ]]; then
      printf 'skip  %s -> %s\n' "${target_path}" "${source_path}"
      return
    fi

    local backup_path="${BACKUP_ROOT}${target_path}"
    mkdir -p "$(dirname "${backup_path}")"
    mv "${target_path}" "${backup_path}"
    printf 'backup %s -> %s\n' "${target_path}" "${backup_path}"
  fi

  ln -snf "${source_path}" "${target_path}"
  printf 'link  %s -> %s\n' "${target_path}" "${source_path}"
}

main() {
  printf 'repo   %s\n' "${REPO_ROOT}"
  printf 'backup %s\n' "${BACKUP_ROOT}"

  mkdir -p \
    "${HOME}/.config/git" \
    "${HOME}/.claude/plugins" \
    "${HOME}/.codex/browser" \
    "${HOME}/.config/secrets/ai-tools"

  link_file "${REPO_ROOT}/gitconfig" "${HOME}/.gitconfig"
  link_file "${REPO_ROOT}/gitignore" "${HOME}/.config/git/ignore"
  link_file "${REPO_ROOT}/editorconfig" "${HOME}/.editorconfig"
  link_file "${REPO_ROOT}/bash_profile" "${HOME}/.bash_profile"
  link_file "${REPO_ROOT}/bashrc" "${HOME}/.bashrc"
  link_file "${REPO_ROOT}/zprofile" "${HOME}/.zprofile"
  link_file "${REPO_ROOT}/zshenv" "${HOME}/.zshenv"
  link_file "${REPO_ROOT}/zshrc" "${HOME}/.zshrc"
  link_file "${REPO_ROOT}/tmux.conf" "${HOME}/.tmux.conf"
  link_file "${REPO_ROOT}/vimrc" "${HOME}/.vimrc"
  link_file "${REPO_ROOT}/vim" "${HOME}/.vim"
  link_file "${REPO_ROOT}/claude/settings.json" "${HOME}/.claude/settings.json"
  link_file "${REPO_ROOT}/claude/skills" "${HOME}/.claude/skills"
  link_file "${REPO_ROOT}/codex/AGENTS.md" "${HOME}/.codex/AGENTS.md"
  link_file "${REPO_ROOT}/codex/browser/config.toml" "${HOME}/.codex/browser/config.toml"
  "${REPO_ROOT}/scripts/sync-codex-config.sh"

  if [[ ! -f "${HOME}/.zshrc.local" ]]; then
    cp "${REPO_ROOT}/local/zshrc.local.example" "${HOME}/.zshrc.local"
    printf 'create %s\n' "${HOME}/.zshrc.local"
  fi

  if [[ ! -f "${HOME}/.config/secrets/ai-tools/.env.example" ]]; then
    cp "${REPO_ROOT}/secrets/ai-tools/.env.example" "${HOME}/.config/secrets/ai-tools/.env.example"
    printf 'create %s\n' "${HOME}/.config/secrets/ai-tools/.env.example"
  fi

  printf '\nnext steps:\n'
  printf '1. ./scripts/setup-homebrew.sh\n'
  printf '2. ./scripts/setup-node.sh\n'
  printf '3. edit ~/.config/secrets/ai-tools/.env and ~/.config/secrets/ai-tools/.env.keys\n'
  printf '4. rerun ./scripts/sync-codex-config.sh if codex base settings change\n'
  printf '5. source ~/.zshrc or restart your shell\n'
}

main "$@"
