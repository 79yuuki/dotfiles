#!/usr/bin/env bash
# Tests for skill-usage-log.sh. Usage: bash skill-usage-log.test.sh
#   HOOK_PATH で検査する hook を差し替えられる。HOME は一時ディレクトリに差し替え、本物の $HOME は触らない。

HOOK="${HOOK_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/skill-usage-log.sh}"
TMP_ROOT="$(mktemp -d)" || exit 1
[[ -d "$TMP_ROOT" ]] || exit 1
trap 'chmod -R u+w "$TMP_ROOT" 2>/dev/null; rm -rf "$TMP_ROOT"' EXIT
PASS=0
FAIL=0
N=0

# run_hook <stdin-string> -> 新しい HOME で実行。sets HOME_DIR, LOG, OUT, ERR, RC
run_hook() {
  N=$((N+1))
  HOME_DIR="$TMP_ROOT/h$N"; mkdir -p "$HOME_DIR"
  LOG="$HOME_DIR/.claude/state/skill-usage.jsonl"
  rerun "$1"
}
rerun() {
  OUT="$(printf '%s' "$1" | env HOME="$HOME_DIR" bash "$HOOK" 2>"$TMP_ROOT/stderr")"
  RC=$?
  ERR="$(cat "$TMP_ROOT/stderr")"
}

ok() { # name condition(0=true)
  if [[ "$2" -eq 0 && "$RC" -eq 0 && -z "$OUT" && -z "$ERR" ]]; then
    PASS=$((PASS+1)); echo "PASS $1"
  else
    FAIL=$((FAIL+1)); echo "FAIL $1 (cond=$2 rc=$RC out=${OUT:+non-empty} err=${ERR:+non-empty})"
  fi
}

IN='{"session_id":"s","cwd":"/work/x","hook_event_name":"PreToolUse","tool_name":"Skill","tool_input":{"skill":"codex","args":"secret-token-123"}}'

run_hook "$IN"
jq -e '(keys|sort) == ["cwd","skill","ts"] and .skill == "codex" and .cwd == "/work/x" and (.ts | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}[+-][0-9]{2}:[0-9]{2}$"))' "$LOG" >/dev/null 2>&1
ok "records ts/skill/cwd" $?

rerun "$IN"
[[ "$(wc -l <"$LOG" | tr -d ' ')" == "2" ]]
ok "appends second line" $?

! grep -q 'secret-token-123\|args' "$LOG"
ok "args not recorded" $?

run_hook '{not json'
[[ ! -e "$LOG" ]]; ok "invalid json" $?

run_hook ''
[[ ! -e "$LOG" ]]; ok "empty stdin" $?

run_hook '{"cwd":"/x","tool_input":{"args":"a"}}'
[[ ! -e "$LOG" ]]; ok "missing skill" $?

run_hook '{"cwd":"/x","tool_input":{"skill":""}}'
[[ ! -e "$LOG" ]]; ok "empty skill" $?

N=$((N+1)); HOME_DIR="$TMP_ROOT/h$N"; mkdir -p "$HOME_DIR/.claude/state"; chmod 555 "$HOME_DIR/.claude/state"
rerun "$IN"
ok "unwritable state dir" 0
chmod 755 "$HOME_DIR/.claude/state"

run_hook '{"cwd":"/w","hook_event_name":"UserPromptExpansion","expansion_type":"slash_command","command_name":"careful","command_args":"secret-arg","prompt":"/careful secret-arg"}'
jq -e '.skill == "careful" and .cwd == "/w"' "$LOG" >/dev/null 2>&1 && ! grep -q 'secret-arg' "$LOG"
ok "user-typed /skill via UserPromptExpansion" $?

run_hook '{"cwd":"/w","hook_event_name":"UserPromptExpansion","expansion_type":"mcp_prompt","command_name":"srv:p"}'
[[ ! -e "$LOG" ]]; ok "mcp prompt not recorded" $?

OUT="$(printf '%s' "$IN" | env -u HOME bash "$HOOK" 2>"$TMP_ROOT/stderr")"; RC=$?; ERR="$(cat "$TMP_ROOT/stderr")"
ok "HOME unset" 0

echo "---"
echo "PASS=$PASS FAIL=$FAIL"
[[ "$FAIL" -eq 0 ]] || exit 1
exit 0
