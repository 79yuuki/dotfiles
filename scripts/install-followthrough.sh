#!/usr/bin/env bash
# Register scripts/followthrough.py check as a daily launchd agent (macOS).
# Usage: install-followthrough.sh [install|uninstall|status|hook|unhook]
#   hook / unhook   SessionStart のリマインド hook（claude/hooks/followthrough-remind.sh）を登録する・外す
#   FOLLOWTHROUGH_HOUR / FOLLOWTHROUGH_MINUTE  実行時刻（既定 09:10）
#   FOLLOWTHROUGH_PLIST_OUT                    plist をこの path に書くだけで、launchctl を呼ばない（確認用）
#   FOLLOWTHROUGH_SETTINGS_FILES               hook を書く設定ファイル（: 区切り。テスト用）

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

# hook は 2 つのファイルに書く。settings.json はいま効いている設定で、settings.local.json は
# sync-claude-settings.sh が settings.json を作り直す時の入力（ここに無いと、作り直しで消える）。
# 既にある登録は、このチェックアウトの path に付け替える（ブランチでの試用から本体へ移す時のため）。
do_hook() {
  local mode="$1" hook="${REPO_ROOT}/claude/hooks/followthrough-remind.sh"
  local files="${FOLLOWTHROUGH_SETTINGS_FILES:-${HOME}/.claude/settings.json:${HOME}/.claude/settings.local.json}"
  if [[ "${mode}" == "add" && ! -x "${hook}" ]]; then
    printf 'error: hook script not found or not executable: %s\n' "${hook}" >&2
    exit 1
  fi
  python3 - "${mode}" "${hook}" "${files}" <<'PY'
import json
import os
import shutil
import sys

mode, hook, files = sys.argv[1], sys.argv[2], [f for f in sys.argv[3].split(":") if f]
entry = {"matcher": "startup", "hooks": [{"type": "command", "command": hook, "timeout": 5}]}


def ours(h):
    c = h.get("command") if isinstance(h, dict) else None
    return isinstance(c, str) and (c == hook or os.path.basename(c.strip()) == "followthrough-remind.sh")


plans = []
for path in files:  # 全部を読んで検証してから書く。1 つでも読めなければ、どれも変えない
    exists = os.path.exists(path)
    if not exists and mode == "remove":
        continue
    data = {}
    if exists:
        try:
            with open(path) as fh:
                data = json.load(fh)
        except (OSError, ValueError) as e:
            sys.exit(f"error: cannot read {path}: {e}; nothing was changed")
    hooks = data.get("hooks", {}) if isinstance(data, dict) else None
    groups = hooks.get("SessionStart", []) if isinstance(hooks, dict) else None
    # グループと、その中の hook の形まで確かめる。知らない形のものを抱えたまま書き換えない
    if not isinstance(groups, list) or not all(
        isinstance(g, dict) and isinstance(g.get("hooks", []), list) and all(isinstance(h, dict) for h in g.get("hooks", []))
        for g in groups
    ):
        sys.exit(f"error: unexpected shape in {path}; nothing was changed")
    new = []
    for g in groups:  # 自分の hook だけを外す。同じグループのほかの hook は残す
        if any(ours(h) for h in g.get("hooks", [])):
            rest = [h for h in g["hooks"] if not ours(h)]
            if rest:
                new.append({**g, "hooks": rest})
        else:
            new.append(g)
    if mode == "add":
        new.append(entry)
    if new == groups:
        print(f"unchanged  {path}")
        continue
    data.setdefault("hooks", {})["SessionStart"] = new
    plans.append((path, exists, json.dumps(data, ensure_ascii=False, indent=2) + "\n"))

staged, done = [], []


def cleanup():
    for _, tmp, _ in staged:
        if os.path.exists(tmp):
            os.remove(tmp)


try:  # 準備: 一時ファイルとバックアップを全部作る。ここで失敗しても、設定はどれも変わっていない
    for path, exists, text in plans:
        tmp, backup = f"{path}.tmp-followthrough", (f"{path}.bak-followthrough" if exists else None)
        staged.append((path, tmp, backup))
        with open(tmp, "w") as fh:
            fh.write(text)
        if backup:
            shutil.copy2(path, backup)
except OSError as e:
    cleanup()
    sys.exit(f"error: {e}; nothing was changed")

try:  # 反映: 途中で失敗したら、反映済みのファイルを元に戻す
    for path, tmp, backup in staged:
        os.replace(tmp, path)
        done.append((path, backup))
except OSError as e:
    for path, backup in done:
        if backup:
            shutil.copy2(backup, path)
        else:
            os.remove(path)
    cleanup()
    sys.exit(f"error: {e}; restored the files changed so far")

for path, backup in done:
    print(f"{'registered' if mode == 'add' else 'removed'}  {path}" + (f"  (backup: {backup})" if backup else ""))
if mode == "add":
    print(f"hook: {hook} (SessionStart, matcher startup). Applies to sessions started from now on.")
PY
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
  hook) do_hook add ;;
  unhook) do_hook remove ;;
  *)
    printf 'usage: %s [install|uninstall|status|hook|unhook]\n' "$(basename "$0")" >&2
    exit 2
    ;;
esac
