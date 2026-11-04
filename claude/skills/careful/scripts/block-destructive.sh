#!/usr/bin/env bash
# PreToolUse(Bash) hook for /careful: deny destructive commands.
# jq 無し・JSON 不正・command 無しは何も出さず exit 0（止めない）。
# shortcut: 文字列ベースの検出で迂回可能、安全境界にはしない。

command -v jq >/dev/null 2>&1 || exit 0
cmd="$(jq -r '.tool_input.command // empty' 2>/dev/null)" || exit 0
[[ -n "$cmd" ]] || exit 0

deny() {
  jq -nc --arg r "/careful: $1 をブロックしました。ユーザーに意図を確認してから別の手段を取ってください（hook の回避は不可）。" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

# SQL（コマンド全体）
shopt -s nocasematch
[[ "$cmd" =~ (^|[^[:alnum:]_])(drop[[:space:]]+(table|database|schema)|truncate[[:space:]]+table)([^[:alnum:]_]|$) ]] \
  && deny "破壊的な SQL (DROP/TRUNCATE)"
shopt -u nocasematch

# rm / git push は ; & | 改行で区切ったセグメントごとに判定
re_ws='[[:space:]]'
re_rflag="(^|$re_ws)(-[a-zA-Z]*[rR][a-zA-Z]*|--recursive)($re_ws|\$)"
re_fflag="(^|$re_ws)(-[a-zA-Z]*f[a-zA-Z]*|--force)($re_ws|\$)"
while IFS= read -r seg; do
  seg="${seg//[\"\'()]/ }"  # 引用符と括弧を空白に（"--force" や (rm -rf x) を拾う）
  if [[ "$seg" =~ (^|[[:space:]/])rm[[:space:]] && "$seg" =~ $re_rflag && "$seg" =~ $re_fflag ]]; then
    deny "rm -rf 系の再帰強制削除"
  fi
  if [[ "$seg" =~ (^|[[:space:]/])git([[:space:]]+(-[Cc][[:space:]]+[^[:space:]]+|-[^[:space:]]+))*[[:space:]]+push([[:space:]]|$) ]]; then
    if [[ "$seg" =~ $re_fflag || "$seg" =~ (^|$re_ws)--force-(with-lease|if-includes)([=[:space:]]|$) || "$seg" =~ $re_ws\+[^[:space:]] ]]; then
      deny "git push の強制 push"
    fi
  fi
done < <(printf '%s\n' "$cmd" | sed -E 's/&&|\|\||[;|&]/\
/g')
exit 0
