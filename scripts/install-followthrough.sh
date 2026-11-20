#!/usr/bin/env bash
# Register scripts/followthrough.py check as a daily launchd agent (macOS).
# Usage: install-followthrough.sh [install|uninstall|status]
#   FOLLOWTHROUGH_HOUR / FOLLOWTHROUGH_MINUTE  実行時刻（既定 09:10）
#   FOLLOWTHROUGH_PLIST_OUT                    plist をこの path に書くだけで、launchctl を呼ばない（確認用）

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LABEL="local.dotfiles.followthrough"
PLIST="${HOME}/Library/LaunchAgents/${LABEL}.plist"
STATE_DIR="${HOME}/.claude/state/followthrough"
LOG_FILE="${STATE_DIR}/check.log"

xml_escape() {
  local s="$1"
  s="${s//&/&amp;}"; s="${s//</&lt;}"; s="${s//>/&gt;}"; s="${s//\"/&quot;}"; s="${s//\'/&apos;}"
  printf '%s' "${s}"
}

do_install() {
  local python gh missing="" hour="${FOLLOWTHROUGH_HOUR:-9}" minute="${FOLLOWTHROUGH_MINUTE:-10}"
  python="$(command -v python3 || true)"
  gh="$(command -v gh || true)"
  [[ -n "${python}" ]] || missing="${missing} python3"
  [[ -n "${gh}" ]] || missing="${missing} gh"
  if [[ -n "${missing}" ]]; then
    printf 'error: command not found:%s\n' "${missing}" >&2
    exit 1
  fi
  if ! [[ "${hour}" =~ ^([0-9]|1[0-9]|2[0-3])$ && "${minute}" =~ ^([0-9]|[1-5][0-9])$ ]]; then
    printf 'error: FOLLOWTHROUGH_HOUR must be 0-23 and FOLLOWTHROUGH_MINUTE 0-59 (no leading zero)\n' >&2
    exit 1
  fi

  local path_value dest="${FOLLOWTHROUGH_PLIST_OUT:-${PLIST}}" out
  path_value="$(dirname "${python}"):$(dirname "${gh}"):/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
  mkdir -p "${STATE_DIR}" "$(dirname "${dest}")"
  # 一時ファイルに書いて検証してから置き換える。検証に失敗しても、既にある plist は変えない。
  out="$(mktemp "${dest}.XXXXXX")"

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
    <string>$(xml_escape "${REPO_ROOT}/scripts/followthrough.py")</string>
    <string>check</string>
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
    rm -f "${out}"
    printf 'error: generated plist failed plutil -lint; nothing was changed\n' >&2
    exit 1
  fi
  if [[ -n "${FOLLOWTHROUGH_PLIST_OUT:-}" ]]; then
    mv "${out}" "${dest}"
    printf 'wrote and validated %s (launchctl not called)\n' "${dest}"
    return 0
  fi

  local uid backup=""
  uid="$(id -u)"
  if [[ -f "${PLIST}" ]]; then
    backup="$(mktemp "${PLIST}.bak.XXXXXX")"
    cp "${PLIST}" "${backup}"
  fi
  mv "${out}" "${PLIST}"
  launchctl bootout "gui/${uid}/${LABEL}" >/dev/null 2>&1 || true
  if ! launchctl bootstrap "gui/${uid}" "${PLIST}"; then
    # 登録に失敗したら、前の plist と登録に戻す。
    if [[ -n "${backup}" ]]; then
      mv "${backup}" "${PLIST}"
      launchctl bootstrap "gui/${uid}" "${PLIST}" >/dev/null 2>&1 || true
      printf 'error: launchctl bootstrap failed; restored the previous plist\n' >&2
    else
      rm -f "${PLIST}"
      printf 'error: launchctl bootstrap failed; removed the new plist\n' >&2
    fi
    exit 1
  fi
  [[ -z "${backup}" ]] || rm -f "${backup}"
  printf 'registered %s (daily at %02d:%02d)\n' "${LABEL}" "${hour}" "${minute}"
  printf 'runs: %s %s/scripts/followthrough.py check\n' "${python}" "${REPO_ROOT}"
  printf 'run now: launchctl kickstart gui/%s/%s\n' "${uid}" "${LABEL}"
  printf 'log: %s\n' "${LOG_FILE}"
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
    printf 'usage: %s [install|uninstall|status]\n' "$(basename "$0")" >&2
    exit 2
    ;;
esac
