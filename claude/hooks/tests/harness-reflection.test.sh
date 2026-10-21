#!/usr/bin/env bash
# Tests for harness-reflection.sh. Usage: bash harness-reflection.test.sh
#   HOOK_SHELL で hook を動かす bash を差し替えられる（例: HOOK_SHELL=/bin/bash）。
# HOME は一時ディレクトリに差し替え、本物の $HOME は触らない。transcript は全て合成。

HOOK="${HOOK_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/harness-reflection.sh}"
HOOK_SHELL="${HOOK_SHELL:-bash}"
TMP_HOME="$(mktemp -d)" || exit 1
[[ -d "$TMP_HOME" ]] || exit 1
trap 'rm -rf "$TMP_HOME"' EXIT
LOG="$TMP_HOME/.claude/state/harness-opportunities.jsonl"
PASS=0
FAIL=0

ok() { PASS=$((PASS+1)); echo "PASS $1"; }
ng() { FAIL=$((FAIL+1)); echo "FAIL $1 ${2:-}"; }
expect() { # name expected actual
  if [[ "$2" == "$3" ]]; then ok "$1"; else ng "$1" "(expected=[$2] got=[$3])"; fi
}

# --- transcript builders (Claude Code の実形式: 外側 type + message.content[]) ---
T="$TMP_HOME/t.jsonl"
tr_reset() { : > "$T"; printf '%s\n' '{"type":"system","subtype":"init","cwd":"/x"}' '{"type":"user","message":{"role":"user","content":"hello"}}' '{"type":"attachment","attachment":{"type":"file"}}' >> "$T"; }
tr_bash() { jq -nc --arg c "$1" '{type:"assistant",message:{role:"assistant",content:[{type:"tool_use",name:"Bash",input:{command:$c}}]}}' >> "$T"; }
tr_text() { jq -nc --arg c "$1" '{type:"assistant",message:{role:"assistant",content:[{type:"text",text:$c}]}}' >> "$T"; }
tr_edit() { jq -nc --arg c "$1" '{type:"assistant",message:{role:"assistant",content:[{type:"tool_use",name:"Edit",input:{file_path:$c}}]}}' >> "$T"; printf '%s\n' '{"type":"user","message":{"role":"user","content":[{"type":"tool_result","content":"ok"}]}}' >> "$T"; }

# run_hook <session_id> [cwd] [path_override]
run_hook() {
  local sid="$1" cwd="${2:-/work/proj}" path="${3:-$PATH}"
  jq -nc --arg s "$sid" --arg c "$cwd" --arg t "${TP:-$T}" '{session_id:$s,cwd:$c,transcript_path:$t}' \
    | env HOME="$TMP_HOME" PATH="$path" "$HOOK_SHELL" "$HOOK" 2>"$TMP_HOME/stderr"
  RC=$?
}
count_sig() { # signal [session]
  if [[ -f "$LOG" ]]; then jq -r --arg s "$1" --arg ss "${2:-}" 'select(.signal==$s and ($ss=="" or .session_id==$ss)) | .signal' "$LOG" | wc -l | tr -d ' '; else echo 0; fi
}
lines() { if [[ -f "$LOG" ]]; then wc -l < "$LOG" | tr -d ' '; else echo 0; fi; }
reset_all() { rm -rf "$TMP_HOME/.claude"; tr_reset; unset TP; }

# 1. bash_repeat_3x
reset_all; tr_bash 'make build'; tr_bash 'make build'; tr_bash 'make build'; tr_bash 'ls'
run_hook s1
expect "bash_repeat_3x emitted once" 1 "$(count_sig bash_repeat_3x)"
expect "rc 0" 0 "$RC"

# 2. text signals
reset_all; tr_text '次は忘れずに実行する。これは毎日回す。'
run_hook s1
expect "manual_checklist" 1 "$(count_sig manual_checklist)"
expect "recurring_keyword" 1 "$(count_sig recurring_keyword)"

# 3. edit_without_lint
reset_all; tr_edit /a/x.ts; tr_edit /a/y.ts; tr_edit /a/z.ts
run_hook s1
expect "edit_without_lint present" 1 "$(count_sig edit_without_lint)"
reset_all; tr_edit /a/x.ts; tr_edit /a/y.ts; tr_edit /a/z.ts; tr_bash 'npm test'
run_hook s1
expect "edit_without_lint absent after npm test" 0 "$(count_sig edit_without_lint)"

# 4. dedup across runs
reset_all; tr_bash 'make build'; tr_bash 'make build'; tr_bash 'make build'
run_hook s1; n1="$(lines)"
run_hook s1; n2="$(lines)"
expect "first run wrote 1 line" 1 "$n1"
expect "second run adds nothing" "$n1" "$n2"
tr_text '毎日やる'
run_hook s1; n3="$(lines)"
expect "third run adds only the new signal" $((n1+1)) "$n3"
expect "new signal is recurring_keyword" 1 "$(count_sig recurring_keyword s1)"

# 5. different session
run_hook s2
expect "other session writes again" 1 "$(count_sig bash_repeat_3x s2)"

# 6. escaping round trip
reset_all
CWD_Q='/work/pro"j'
CMD_Q="$(printf 'echo a\\|b\tc "q"')"
tr_bash "$CMD_Q"; tr_bash "$CMD_Q"; tr_bash "$CMD_Q"
run_hook 's"9' "$CWD_Q"
bad=0; while IFS= read -r l; do printf '%s' "$l" | jq -e . >/dev/null 2>&1 || bad=$((bad+1)); done < "$LOG"
expect "all log lines valid JSON" 0 "$bad"
expect "log has a line" 1 "$(lines)"
expect "cwd round-trips" "$CWD_Q" "$(jq -r .cwd "$LOG")"
expect "session_id round-trips" 's"9' "$(jq -r .session_id "$LOG")"
expect "evidence round-trips" "$CMD_Q (3x)" "$(jq -r .evidence "$LOG")"

# 7. missing / unreadable transcript
reset_all
TP="$TMP_HOME/nonexistent.jsonl" run_hook s1
expect "missing transcript: rc 0" 0 "$RC"
expect "missing transcript: no log" 0 "$(lines)"
printf '{"session_id":"s1","cwd":"/x"}' | env HOME="$TMP_HOME" "$HOOK_SHELL" "$HOOK" 2>/dev/null
expect "no transcript_path: rc 0" 0 "$?"
expect "no transcript_path: no log" 0 "$(lines)"

# 7b. 同一実行内の重複: 200行超の CLAUDE.md を 2 回 Edit しても instruction_bloat は 1 行
reset_all
BLOAT_DIR="$TMP_HOME/bloat"; mkdir -p "$BLOAT_DIR"
seq 1 201 > "$BLOAT_DIR/CLAUDE.md"
tr_edit "$BLOAT_DIR/CLAUDE.md"; tr_edit "$BLOAT_DIR/CLAUDE.md"
run_hook s1
expect "same-run duplicate instruction_bloat written once" 1 "$(count_sig instruction_bloat)"
# 別の肥大したファイルは別の提案として残る（candidate にファイルのパスが入る）
mkdir -p "$BLOAT_DIR/sub"; seq 1 201 > "$BLOAT_DIR/sub/AGENTS.md"
tr_edit "$BLOAT_DIR/sub/AGENTS.md"
run_hook s1
expect "second bloated file gets its own row" 2 "$(count_sig instruction_bloat)"

# 7c. ログ末尾が改行の無い断片でも、新しい行は読める
reset_all; mkdir -p "$TMP_HOME/.claude/state"
printf '%s' '{"ts":"x","sig' > "$LOG"
tr_bash 'make build'; tr_bash 'make build'; tr_bash 'make build'; tr_text '毎日やる'
run_hook s1
bad=0; good=0; n=0
while IFS= read -r l; do
  n=$((n+1)); (( n == 1 )) && continue
  if printf '%s' "$l" | jq -e . >/dev/null 2>&1; then good=$((good+1)); else bad=$((bad+1)); fi
done < "$LOG"
expect "truncated tail: new lines all valid JSON" 0 "$bad"
expect "truncated tail: new lines written" 2 "$good"

# 8. jq absent from PATH
reset_all; tr_bash 'make build'; tr_bash 'make build'; tr_bash 'make build'
NOJQ="$TMP_HOME/nojq"; mkdir -p "$NOJQ"
for c in bash cat date basename dirname mkdir sort uniq awk sed grep tr head wc cut env; do
  p="$(command -v "$c")"; [[ -n "$p" ]] && ln -sf "$p" "$NOJQ/$c"
done
hash -r
if PATH="$NOJQ" command -v jq >/dev/null 2>&1; then ng "jq stripped from PATH"; else
  jq -nc --arg t "$T" '{session_id:"s1",cwd:"/x",transcript_path:$t}' \
    | env HOME="$TMP_HOME" PATH="$NOJQ" "$HOOK_SHELL" "$HOOK" 2>/dev/null
  expect "no jq: rc 0" 0 "$?"
  expect "no jq: no log" 0 "$(lines)"
fi

# 9. performance on ~11MB transcript
reset_all
CH="$TMP_HOME/chunk"; : > "$CH"
# 実 transcript と同様、サイズの大半は tool_result（user 行）で、assistant 行は短い。
BIG="$(head -c 9000 /dev/zero | tr '\0' 'x')"
i=0; while (( i < 100 )); do
  printf '%s\n' "{\"type\":\"assistant\",\"message\":{\"role\":\"assistant\",\"content\":[{\"type\":\"tool_use\",\"name\":\"Bash\",\"input\":{\"command\":\"echo hi\"}},{\"type\":\"text\",\"text\":\"working on it\"}]}}" >> "$CH"
  printf '%s\n' "{\"type\":\"user\",\"message\":{\"role\":\"user\",\"content\":[{\"type\":\"tool_result\",\"content\":\"$BIG\"}]}}" >> "$CH"
  i=$((i+1))
done
: > "$T"; for _ in $(seq 1 12); do cat "$CH" >> "$T"; done
echo "transcript bytes: $(wc -c < "$T" | tr -d ' ')"
TIMEFORMAT=%R
secs="$( { time run_hook perf >/dev/null; } 2>&1 )"
echo "hook elapsed: ${secs}s"
if awk -v s="$secs" 'BEGIN{exit !(s+0 <= 3)}'; then ok "11MB transcript within 3s"; else ng "11MB transcript within 3s" "(${secs}s)"; fi

echo "pass=$PASS fail=$FAIL"
[[ "$FAIL" -eq 0 ]]
