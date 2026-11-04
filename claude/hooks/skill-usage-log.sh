#!/usr/bin/env bash
# PreToolUse (matcher: Skill) / UserPromptExpansion hook: skill 起動ログ。
#
# どの skill が実際に使われたかを記録し、skill-portfolio-evolution の剪定判断（長期間未使用の skill）の材料にする。
#
# Design principles:
# - Log only. 判断は返さず stdout には何も出さない。stderr にも出さない。
# - Always exit 0 so the tool call is never blocked（jq なし・JSON 不正・skill 名なし・書き込み失敗でも同じ）。
# - args は記録しない（秘匿情報が入りうる）。bash は 3.2 互換。
#
# Input: Claude Code passes JSON on stdin.
#   - PreToolUse: tool_input.skill（Claude が Skill ツールで起動した時）、cwd
#   - UserPromptExpansion: command_name（ユーザーが /skill を直接打った時。PreToolUse を通らない）、cwd
#
# Output: ~/.claude/state/skill-usage.jsonl に1行追記: {"ts":"ISO8601+TZ","skill":"...","cwd":"..."}

set -u
set +e  # never break PreToolUse. exit 0 everywhere.

JQ="$(command -v jq 2>/dev/null)"
[[ -n "$JQ" && -n "${HOME:-}" ]] || exit 0

{
  INPUT="$(cat)"
  SKILL="$(printf '%s' "$INPUT" | "$JQ" -r '(if .hook_event_name == "UserPromptExpansion" then (select(.expansion_type == "slash_command") | .command_name) else .tool_input.skill end) | select(type == "string") // empty')"
  [[ -n "$SKILL" ]] || exit 0
  CWD="$(printf '%s' "$INPUT" | "$JQ" -r '.cwd | select(type == "string") // empty')"
  TS="$(date +%Y-%m-%dT%H:%M:%S%z)"
  TS="${TS%??}:${TS: -2}"  # +0900 -> +09:00（BSD date に %:z は無い）
  DIR="${HOME}/.claude/state"
  mkdir -p "$DIR" &&
    "$JQ" -nc --arg ts "$TS" --arg skill "$SKILL" --arg cwd "$CWD" '{ts:$ts,skill:$skill,cwd:$cwd}' >>"$DIR/skill-usage.jsonl"
} >/dev/null 2>&1
exit 0
