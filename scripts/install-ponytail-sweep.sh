#!/usr/bin/env bash
# Register scripts/ponytail-sweep.py as a daily launchd agent (macOS).
# Usage: install-ponytail-sweep.sh [install|uninstall|status]

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LABEL="local.dotfiles.ponytail-sweep"
PLIST="${HOME}/Library/LaunchAgents/${LABEL}.plist"
STATE_DIR="${PONYTAIL_SWEEP_STATE_DIR:-${HOME}/.local/state/ponytail-sweep}"
LOG_FILE="${STATE_DIR}/sweep.log"

usage() {
  printf 'usage: %s [install|uninstall|status]\n' "$(basename "$0")" >&2
}

xml_escape() {
  local s="$1"
  s="${s//&/&amp;}"
  s="${s//</&lt;}"
  s="${s//>/&gt;}"
  s="${s//\"/&quot;}"
  s="${s//\'/&apos;}"
  printf '%s' "${s}"
}

strip_zeros() {
  local s="${1#"${1%%[!0]*}"}"
  printf '%s' "${s:-0}"
}

is_int() {
  case "$1" in
    '' | *[!0-9]*) return 1 ;;
    *) return 0 ;;
  esac
}

do_install() {
  local python claude node missing=""
  python="$(command -v python3 || true)"
  claude="$(command -v claude || true)"
  node="$(command -v node || true)"
  [[ -n "${python}" ]] || missing="${missing} python3"
  [[ -n "${claude}" ]] || missing="${missing} claude"
  [[ -n "${node}" ]] || missing="${missing} node"
  if [[ -n "${missing}" ]]; then
    printf 'error: command not found:%s\n' "${missing}" >&2
    exit 1
  fi

  local hour="${PONYTAIL_SWEEP_HOUR:-12}"
  local minute="${PONYTAIL_SWEEP_MINUTE:-30}"
  # strip leading zeros as text (they would read as octal) and cap the length before any arithmetic,
  # so huge values cannot overflow into the valid range
  local h m
  h="$(strip_zeros "${hour}")"
  m="$(strip_zeros "${minute}")"
  if ! is_int "${hour}" || [[ ${#h} -gt 2 ]] || (( h > 23 )); then
    printf 'error: PONYTAIL_SWEEP_HOUR must be an integer 0-23: %s\n' "${hour}" >&2
    exit 1
  fi
  if ! is_int "${minute}" || [[ ${#m} -gt 2 ]] || (( m > 59 )); then
    printf 'error: PONYTAIL_SWEEP_MINUTE must be an integer 0-59: %s\n' "${minute}" >&2
    exit 1
  fi
  hour="${h}"
  minute="${m}"

  # PATH: dirs of every claude/node/python on PATH first (a wrapper such as Superset's finds the
  # real claude through PATH), then standard dirs, deduplicated
  # (one path per line, so directories with spaces survive)
  local path_value="" dir
  while IFS= read -r dir; do
    case ":${path_value}:" in
      *":${dir}:"*) ;;
      *) path_value="${path_value:+${path_value}:}${dir}" ;;
    esac
  done <<EOF_DIRS
$(type -ap claude node python3 | while IFS= read -r p; do dirname "${p}"; done)
/opt/homebrew/bin
/usr/local/bin
/usr/bin
/bin
/usr/sbin
/sbin
EOF_DIRS

  local out="${PONYTAIL_SWEEP_PLIST_OUT:-${PLIST}}"
  mkdir -p "${STATE_DIR}" "$(dirname "${out}")"

  cat >"${out}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$(xml_escape "${LABEL}")</string>
  <key>ProgramArguments</key>
  <array>
    <string>$(xml_escape "${python}")</string>
    <string>$(xml_escape "${REPO_ROOT}/scripts/ponytail-sweep.py")</string>
    <string>run</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key>
    <integer>${hour}</integer>
    <key>Minute</key>
    <integer>${minute}</integer>
  </dict>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>$(xml_escape "${path_value}")</string>
    <key>HOME</key>
    <string>$(xml_escape "${HOME}")</string>
    <key>LANG</key>
    <string>ja_JP.UTF-8</string>
    <key>PONYTAIL_SWEEP_STATE_DIR</key>
    <string>$(xml_escape "${STATE_DIR}")</string>
  </dict>
  <key>StandardOutPath</key>
  <string>$(xml_escape "${LOG_FILE}")</string>
  <key>StandardErrorPath</key>
  <string>$(xml_escape "${LOG_FILE}")</string>
  <key>ProcessType</key>
  <string>Background</string>
  <key>LowPriorityIO</key>
  <true/>
  <key>Nice</key>
  <integer>10</integer>
  <key>RunAtLoad</key>
  <false/>
</dict>
</plist>
EOF

  if ! plutil -lint "${out}" >/dev/null; then
    printf 'error: plutil -lint failed: %s\n' "${out}" >&2
    exit 1
  fi

  if [[ -n "${PONYTAIL_SWEEP_PLIST_OUT:-}" ]]; then
    printf 'wrote and validated %s (launchctl not called)\n' "${out}"
    return 0
  fi

  local uid
  uid="$(id -u)"
  launchctl bootout "gui/${uid}/${LABEL}" >/dev/null 2>&1 || true
  launchctl bootstrap "gui/${uid}" "${PLIST}"

  printf 'registered %s\n' "${LABEL}"
  printf 'plist: %s\n' "${PLIST}"
  printf 'next run: daily at %02d:%02d\n' "${hour}" "${minute}"
  printf 'run now: launchctl kickstart gui/%s/%s\n' "${uid}" "${LABEL}"
  printf 'log: %s\n' "${LOG_FILE}"
  printf 'dry-run: "%s" "%s/scripts/ponytail-sweep.py" run --dry-run\n' "${python}" "${REPO_ROOT}"
}

do_uninstall() {
  launchctl bootout "gui/$(id -u)/${LABEL}" >/dev/null 2>&1 || true
  rm -f "${PLIST}"
  printf 'unregistered %s and removed %s\n' "${LABEL}" "${PLIST}"
  printf 'state directory kept: %s\n' "${STATE_DIR}"
}

do_status() {
  if launchctl print "gui/$(id -u)/${LABEL}" >/dev/null 2>&1; then
    printf 'registered: yes (%s)\n' "${LABEL}"
  else
    printf 'registered: no (%s)\n' "${LABEL}"
  fi
  printf 'plist: %s\n' "${PLIST}"
  if [[ -f "${LOG_FILE}" ]]; then
    printf 'log tail (%s):\n' "${LOG_FILE}"
    tail -n 20 "${LOG_FILE}"
  else
    printf 'log: none yet (%s)\n' "${LOG_FILE}"
  fi
}

case "${1:-install}" in
  install) do_install ;;
  uninstall) do_uninstall ;;
  status) do_status ;;
  *)
    usage
    exit 2
    ;;
esac
