#!/usr/bin/env bash
# Harness opportunity detectors.
#
# Each detector reads the session transcript (jsonl, one event per line) and
# emits 0+ harness-opportunity rows to stdout in the v1 schema:
#
#   {"ts":"...","project":"...","cwd":"...","session_id":"...",
#    "signal":"<name>","evidence":"...","candidate":"...",
#    "layer":"runtime|context|safety","confidence":"low|medium|high"}
#
# Detectors must:
#   - never modify state outside stdout
#   - never call the network
#   - return quickly (grep / awk only, no LLM)
#   - emit one JSON object per line, no trailing comma

emit_signal() {
  local ts="$1" project="$2" cwd="$3" session_id="$4"
  local signal="$5" evidence="$6" candidate="$7" layer="$8" confidence="$9"

  # Escape double quotes in evidence/candidate.
  local ev_esc cand_esc
  ev_esc=$(printf '%s' "${evidence}" | sed 's/"/\\"/g')
  cand_esc=$(printf '%s' "${candidate}" | sed 's/"/\\"/g')

  printf '{"ts":"%s","project":"%s","cwd":"%s","session_id":"%s","signal":"%s","evidence":"%s","candidate":"%s","layer":"%s","confidence":"%s"}\n' \
    "${ts}" "${project}" "${cwd}" "${session_id}" "${signal}" "${ev_esc}" "${cand_esc}" "${layer}" "${confidence}"
}

# Extract Bash tool invocations from transcript. Returns command lines.
_extract_bash_commands() {
  local transcript="$1"
  # transcript is jsonl. Look for tool_use entries where name == "Bash".
  # Fallback to grep if jq missing.
  if command -v jq >/dev/null 2>&1; then
    jq -r 'select(.type? == "tool_use" and .name? == "Bash") | .input.command? // empty' \
      "${transcript}" 2>/dev/null
  else
    grep -oE '"name":"Bash"[^}]*"command":"[^"]*"' "${transcript}" 2>/dev/null \
      | sed -E 's/.*"command":"([^"]*)".*/\1/'
  fi
}

# Extract assistant text content from transcript.
_extract_assistant_text() {
  local transcript="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -r 'select(.role? == "assistant") | .content? // empty | tostring' \
      "${transcript}" 2>/dev/null
  else
    grep -oE '"role":"assistant"[^}]*"content":"[^"]*"' "${transcript}" 2>/dev/null \
      | sed -E 's/.*"content":"([^"]*)".*/\1/'
  fi
}

# Extract Write/Edit/MultiEdit tool invocations.
_extract_edits() {
  local transcript="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -r 'select(.type? == "tool_use" and (.name? | IN("Write","Edit","MultiEdit"))) | .input.file_path? // empty' \
      "${transcript}" 2>/dev/null
  else
    grep -oE '"name":"(Write|Edit|MultiEdit)"[^}]*"file_path":"[^"]*"' "${transcript}" 2>/dev/null \
      | sed -E 's/.*"file_path":"([^"]*)".*/\1/'
  fi
}

# --- detectors -----------------------------------------------------------

# Detect: same Bash command run 3+ times.
detect_bash_repeat() {
  local transcript="$1" ts="$2" project="$3" cwd="$4" session_id="$5"
  local cmds top_cmd count
  cmds="$(_extract_bash_commands "${transcript}")"
  [[ -z "${cmds}" ]] && return 0

  # Trim args after first word + first 40 chars to cluster similar commands.
  local clustered
  clustered="$(echo "${cmds}" | awk '{ print substr($0,1,80) }' | sort | uniq -c | sort -rn)"

  while IFS= read -r line; do
    count=$(echo "${line}" | awk '{print $1}')
    top_cmd=$(echo "${line}" | sed -E 's/^[[:space:]]*[0-9]+[[:space:]]+//')
    if [[ -z "${top_cmd}" ]]; then continue; fi
    if (( count >= 3 )); then
      emit_signal "${ts}" "${project}" "${cwd}" "${session_id}" \
        "bash_repeat_3x" \
        "${top_cmd} (${count}x)" \
        "Consider Bash alias / make target / PostToolUse hook for: ${top_cmd}" \
        "runtime" "medium"
    fi
  done <<< "${clustered}"
}

# Detect: assistant text contains phrases suggesting future-fragile manual work.
detect_manual_checklist() {
  local transcript="$1" ts="$2" project="$3" cwd="$4" session_id="$5"
  local text matches
  text="$(_extract_assistant_text "${transcript}")"
  [[ -z "${text}" ]] && return 0

  matches="$(echo "${text}" \
    | grep -oE '次回も?気をつけ|忘れないように|次は気をつけ|来週も同じ|毎回必ず|忘れずに' \
    | sort -u | head -5)"

  if [[ -n "${matches}" ]]; then
    local ev
    ev="$(echo "${matches}" | tr '\n' ',' | sed 's/,$//')"
    emit_signal "${ts}" "${project}" "${cwd}" "${session_id}" \
      "manual_checklist" \
      "phrases: ${ev}" \
      "Promote to progress file / skill / SKILL.md trigger so future sessions auto-handle this" \
      "context" "high"
  fi
}

# Detect: file edits without subsequent lint/test/typecheck/build run.
detect_edit_without_lint() {
  local transcript="$1" ts="$2" project="$3" cwd="$4" session_id="$5"
  local edits cmds edit_count verify_count
  edits="$(_extract_edits "${transcript}")"
  cmds="$(_extract_bash_commands "${transcript}")"

  # `grep -c` always prints a number; avoid `|| echo 0` which would double-print.
  edit_count=$(printf '%s\n' "${edits}" | grep -c .)
  verify_count=$(printf '%s\n' "${cmds}" | grep -ciE 'lint|test|tsc|typecheck|biome|eslint|ruff|mypy|pytest|jest|vitest|go test|cargo test|golangci|gofumpt')

  # Treat empty input as 0.
  [[ -z "${edits}" ]] && edit_count=0
  [[ -z "${cmds}" ]] && verify_count=0

  if (( edit_count >= 3 )) && (( verify_count == 0 )); then
    emit_signal "${ts}" "${project}" "${cwd}" "${session_id}" \
      "edit_without_lint" \
      "${edit_count} edits, 0 lint/test runs" \
      "Add PostToolUse hook (lint/format on edit) and/or Stop hook (test gate)" \
      "runtime" "high"
  fi
}

# Detect: user/assistant mentions cron/scheduled/recurring keywords.
detect_recurring_keyword() {
  local transcript="$1" ts="$2" project="$3" cwd="$4" session_id="$5"
  local text matches
  text="$(_extract_assistant_text "${transcript}")"
  [[ -z "${text}" ]] && return 0

  matches="$(echo "${text}" \
    | grep -oiE 'cron|scheduled|recurring|every (day|week|hour|morning)|毎日|毎週|毎朝|定期(的|実行)|定時' \
    | sort -u | head -5)"

  if [[ -n "${matches}" ]]; then
    local ev
    ev="$(echo "${matches}" | tr '\n' ',' | sed 's/,$//')"
    emit_signal "${ts}" "${project}" "${cwd}" "${session_id}" \
      "recurring_keyword" \
      "keywords: ${ev}" \
      "Candidate for scheduled agent (/schedule), cron, or Claude Code routine" \
      "runtime" "medium"
  fi
}

# Detect: any CLAUDE.md / AGENTS.md / SKILL.md edited and now exceeds size thresholds.
detect_instruction_bloat() {
  local transcript="$1" ts="$2" project="$3" cwd="$4" session_id="$5"
  local edited_paths f lines
  edited_paths="$(_extract_edits "${transcript}" | grep -E '(CLAUDE|AGENTS|SKILL)\.md$' | sort -u)"
  [[ -z "${edited_paths}" ]] && return 0

  while IFS= read -r f; do
    [[ -z "${f}" ]] && continue
    [[ ! -r "${f}" ]] && continue
    lines=$(wc -l < "${f}" 2>/dev/null | tr -d ' ')
    [[ -z "${lines}" ]] && continue
    if (( lines > 200 )); then
      emit_signal "${ts}" "${project}" "${cwd}" "${session_id}" \
        "instruction_bloat" \
        "${f} (${lines} lines)" \
        "Run prompt-design / harness-engineering lean rule: move long sections to references/, keep root file pointers + critical gotchas only" \
        "context" "medium"
    fi
  done <<< "${edited_paths}"
}
