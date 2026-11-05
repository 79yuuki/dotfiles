#!/usr/bin/env bash
# Register scripts/bookmark-daily.sh as a daily launchd agent (macOS). Same shape as install-ponytail-sweep.sh.
# Usage: install-bookmark-daily.sh [install|uninstall|status]
#   BOOKMARK_DAILY_HOUR / BOOKMARK_DAILY_MINUTE (default 19:00), BOOKMARK_DAILY_PLIST_OUT (write + lint only).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LABEL="local.dotfiles.bookmark-daily"
PLIST="${HOME}/Library/LaunchAgents/${LABEL}.plist"
STATE_DIR="${BOOKMARK_DAILY_STATE_DIR:-${HOME}/.local/state/bookmark-daily}"
LOG_FILE="${STATE_DIR}/daily.log"

xml_escape() {
  local s="$1"
  s="${s//&/&amp;}"
  s="${s//</&lt;}"
  s="${s//>/&gt;}"
  printf '%s' "${s}"
}

in_range() { # value max
  case "$1" in '' | *[!0-9]*) return 1 ;; esac
  [[ ${#1} -le 2 ]] && (( 10#$1 <= $2 ))
}

do_install() {
  # first codex on PATH that actually runs, skipping wrappers such as Superset's (a stale global install can be broken)
  local codex="" p
  while IFS= read -r p; do
    case "${p}" in */.superset*/bin/codex) continue ;; esac
    if "${p}" --version >/dev/null 2>&1; then codex="${p}"; break; fi
  done <<EOF_CODEX
$(type -ap codex)
EOF_CODEX
  if [[ -z "${codex}" ]]; then
    printf 'error: no working codex found on PATH\n' >&2
    exit 1
  fi

  local hour="${BOOKMARK_DAILY_HOUR:-19}" minute="${BOOKMARK_DAILY_MINUTE:-0}"
  if ! in_range "${hour}" 23 || ! in_range "${minute}" 59; then
    printf 'error: BOOKMARK_DAILY_HOUR must be 0-23 and BOOKMARK_DAILY_MINUTE 0-59: %s:%s\n' "${hour}" "${minute}" >&2
    exit 1
  fi
  hour=$((10#${hour})); minute=$((10#${minute}))

  local path_value
  path_value="$(dirname "${codex}"):/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
  local out="${BOOKMARK_DAILY_PLIST_OUT:-${PLIST}}"
  mkdir -p "${STATE_DIR}" "$(dirname "${out}")"

  cat >"${out}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$(xml_escape "${REPO_ROOT}/scripts/bookmark-daily.sh")</string>
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
    <key>BOOKMARK_DAILY_STATE_DIR</key>
    <string>$(xml_escape "${STATE_DIR}")</string>
    <key>BOOKMARK_DAILY_TASK_DIR</key>
    <string>$(xml_escape "${BOOKMARK_DAILY_TASK_DIR:-${HOME}/.local/share/bookmark-skill-learning}")</string>
  </dict>
  <key>StandardOutPath</key>
  <string>$(xml_escape "${LOG_FILE}")</string>
  <key>StandardErrorPath</key>
  <string>$(xml_escape "${LOG_FILE}")</string>
  <key>ProcessType</key>
  <string>Background</string>
  <key>RunAtLoad</key>
  <false/>
</dict>
</plist>
EOF

  if ! plutil -lint "${out}" >/dev/null; then
    printf 'error: plutil -lint failed: %s\n' "${out}" >&2
    exit 1
  fi
  if [[ -n "${BOOKMARK_DAILY_PLIST_OUT:-}" ]]; then
    printf 'wrote and validated %s (launchctl not called)\n' "${out}"
    return 0
  fi

  local uid
  uid="$(id -u)"
  # bootout kills a run in progress, so refuse to re-register while it runs
  if launchctl print "gui/${uid}/${LABEL}" 2>/dev/null | grep -q 'state = running'; then
    printf 'error: %s is running now; re-run install after it finishes\n' "${LABEL}" >&2
    exit 1
  fi
  launchctl bootout "gui/${uid}/${LABEL}" >/dev/null 2>&1 || true
  launchctl bootstrap "gui/${uid}" "${PLIST}"
  printf 'registered %s (codex: %s)\n' "${LABEL}" "${codex}"
  printf 'next run: daily at %02d:%02d\n' "${hour}" "${minute}"
  printf 'run now: launchctl kickstart gui/%s/%s\n' "${uid}" "${LABEL}"
  printf 'log: %s\n' "${LOG_FILE}"
}

do_uninstall() {
  launchctl bootout "gui/$(id -u)/${LABEL}" >/dev/null 2>&1 || true
  rm -f "${PLIST}"
  printf 'unregistered %s and removed %s\n' "${LABEL}" "${PLIST}"
}

do_status() {
  if launchctl print "gui/$(id -u)/${LABEL}" >/dev/null 2>&1; then
    printf 'registered: yes (%s)\n' "${LABEL}"
  else
    printf 'registered: no (%s)\n' "${LABEL}"
  fi
  if [[ -f "${LOG_FILE}" ]]; then tail -n 20 "${LOG_FILE}"; else printf 'log: none yet (%s)\n' "${LOG_FILE}"; fi
}

case "${1:-install}" in
  install) do_install ;;
  uninstall) do_uninstall ;;
  status) do_status ;;
  *) printf 'usage: %s [install|uninstall|status]\n' "$(basename "$0")" >&2; exit 2 ;;
esac
