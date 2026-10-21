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
#   - return quickly (one jq pass over the transcript, then grep / awk, no LLM)
#   - require jq (the hook exits before running detectors when jq is missing)
#   - emit one JSON object per line, no trailing comma

emit_signal() {
  local ts="$1" project="$2" cwd="$3" session_id="$4"
  local signal="$5" evidence="$6" candidate="$7" layer="$8" confidence="$9"

  # jq builds the JSON so every field is escaped correctly (quotes, backslashes, tabs).
  jq -nc \
    --arg ts "${ts}" --arg project "${project}" --arg cwd "${cwd}" \
    --arg session_id "${session_id}" --arg signal "${signal}" \
    --arg evidence "${evidence}" --arg candidate "${candidate}" \
    --arg layer "${layer}" --arg confidence "${confidence}" \
    '{ts:$ts,project:$project,cwd:$cwd,session_id:$session_id,signal:$signal,evidence:$evidence,candidate:$candidate,layer:$layer,confidence:$confidence}'
}

# Read the transcript once with jq and cache the result in a variable.
# Each output line is "<kind>\t<value>": B = Bash command, T = assistant text,
# E = edited file path (Write/Edit/MultiEdit). Newlines inside values become spaces.
# A transcript line looks like {"type":"assistant","message":{"content":[{"type":"tool_use",...}]}};
# other line types (user / attachment / system) are skipped. Transcripts can reach
# ~11MB, so reading them once instead of once per extractor keeps the Stop hook fast.
# Call this from the main shell (not inside $(...)) so the cache survives.
_TRANSCRIPT_CACHE_PATH=""
_TRANSCRIPT_CACHE=""
_load_transcript_events() {
  local transcript="$1"
  if [[ "${_TRANSCRIPT_CACHE_PATH}" == "${transcript}" ]]; then
    return 0
  fi
  _TRANSCRIPT_CACHE="$(jq -rR 'fromjson? | select(type == "object" and .type == "assistant") | .message.content[]? | if .type == "tool_use" and .name == "Bash" then "B\t" + ((.input.command // "") | gsub("\n"; " ")) elif .type == "text" then "T\t" + ((.text // "") | gsub("\n"; " ")) elif .type == "tool_use" and (.name | IN("Write","Edit","MultiEdit")) then "E\t" + (.input.file_path // "") else empty end' \
    "${transcript}" 2>/dev/null)"
  _TRANSCRIPT_CACHE_PATH="${transcript}"
}

# Return the values of one kind (B/T/E) from the cached events.
_events_of_kind() {
  local transcript="$1" kind="$2"
  _load_transcript_events "${transcript}"
  [[ -z "${_TRANSCRIPT_CACHE}" ]] && return 0
  printf '%s\n' "${_TRANSCRIPT_CACHE}" | grep "^${kind}"$'\t' | cut -f2-
}

# Extract Bash tool invocations from transcript. Returns command lines.
_extract_bash_commands() { _events_of_kind "$1" B; }

# Extract assistant text content from transcript.
_extract_assistant_text() { _events_of_kind "$1" T; }

# Extract Write/Edit/MultiEdit tool invocations.
_extract_edits() { _events_of_kind "$1" E; }

# --- detectors -----------------------------------------------------------

# Detect: same Bash command run 3+ times.
detect_bash_repeat() {
  local transcript="$1" ts="$2" project="$3" cwd="$4" session_id="$5"
  local cmds top_cmd count
  cmds="$(_extract_bash_commands "${transcript}")"
  [[ -z "${cmds}" ]] && return 0

  # Trim args after first word + first 40 chars to cluster similar commands.
  local clustered
  # Keep only 3+ repeats here: the loop below forks per line, and long sessions have
  # thousands of distinct commands.
  clustered="$(echo "${cmds}" | awk '{ print substr($0,1,80) }' | sort | uniq -c | sort -rn | awk '$1 >= 3')"

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
        "Run prompt-design / harness-engineering lean rule on ${f}: move long sections to references/, keep root file pointers + critical gotchas only" \
        "context" "medium"
    fi
  done <<< "${edited_paths}"
}
