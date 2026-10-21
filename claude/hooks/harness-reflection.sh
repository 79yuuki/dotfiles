#!/usr/bin/env bash
# Stop hook: harness opportunity detection.
#
# Anthropic公式 (large-codebase blog) の "A stop hook can reflect on what happened
# during a session and propose CLAUDE.md updates while the context is fresh" を実装。
#
# Design principles:
# - Detect only. No mutation, no external send.
# - Append-only jsonl. No LLM calls. jq reads the transcript once; heuristics are grep/awk.
# - Requires jq. Without jq the hook does nothing and exits 0.
# - Always exit 0 so session end is never blocked.
#
# Input: Claude Code passes session metadata on stdin (json).
#   Expected fields (subject to change in Claude Code releases):
#     - session_id
#     - cwd
#     - transcript_path  (path to session transcript jsonl)
#
# Output: appends 0..N rows to ~/.claude/state/harness-opportunities.jsonl
#
# Stop fires after every assistant turn (not only at session end), so rows already
# logged for this session (same signal + candidate) are skipped. Stop is kept over
# SessionEnd because SessionEnd may never fire (e.g. the terminal is closed).
#
# Next session: skill-portfolio-evolution reads jsonl and stages review patches.

set -u
set +e  # never break Stop. exit 0 at end.

STATE_DIR="${HOME}/.claude/state"
LOG_FILE="${STATE_DIR}/harness-opportunities.jsonl"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

# shellcheck source=lib/harness-signals.sh
if [[ -f "${LIB_DIR}/harness-signals.sh" ]]; then
  # shellcheck disable=SC1091
  source "${LIB_DIR}/harness-signals.sh"
else
  exit 0
fi

# jq is required (transcript parsing + JSON output). Without it, do nothing.
command -v jq >/dev/null 2>&1 || exit 0

mkdir -p "${STATE_DIR}" 2>/dev/null || exit 0

# Read stdin payload (may be empty if hook invoked manually for testing).
PAYLOAD=""
if [[ ! -t 0 ]]; then
  PAYLOAD="$(cat)"
fi

get_field() {
  local field="$1"
  if [[ -z "${PAYLOAD}" ]]; then
    echo ""
    return
  fi
  echo "${PAYLOAD}" | jq -r --arg f "${field}" '.[$f] // empty' 2>/dev/null
}

SESSION_ID="$(get_field session_id)"
CWD="$(get_field cwd)"
TRANSCRIPT_PATH="$(get_field transcript_path)"

# If no transcript, exit silently.
if [[ -z "${TRANSCRIPT_PATH}" ]] || [[ ! -r "${TRANSCRIPT_PATH}" ]]; then
  exit 0
fi

TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
PROJECT="$(basename "${CWD:-unknown}")"

# Read the transcript once in this shell; detectors reuse the cached result.
_load_transcript_events "${TRANSCRIPT_PATH}"

# Run each detector. Each emits 0+ jsonl rows to stdout.
NEW_ROWS="$(
  detect_bash_repeat "${TRANSCRIPT_PATH}" "${TS}" "${PROJECT}" "${CWD}" "${SESSION_ID}"
  detect_manual_checklist "${TRANSCRIPT_PATH}" "${TS}" "${PROJECT}" "${CWD}" "${SESSION_ID}"
  detect_edit_without_lint "${TRANSCRIPT_PATH}" "${TS}" "${PROJECT}" "${CWD}" "${SESSION_ID}"
  detect_recurring_keyword "${TRANSCRIPT_PATH}" "${TS}" "${PROJECT}" "${CWD}" "${SESSION_ID}"
  detect_instruction_bloat "${TRANSCRIPT_PATH}" "${TS}" "${PROJECT}" "${CWD}" "${SESSION_ID}"
)"
[[ -z "${NEW_ROWS}" ]] && exit 0

# Drop rows whose {signal, candidate} pair is already logged for this session.
SEEN="[]"
if [[ -r "${LOG_FILE}" ]]; then
  SEEN="$(jq -cR --arg s "${SESSION_ID}" 'fromjson? | select(type == "object" and .session_id == $s) | [.signal, .candidate]' \
    "${LOG_FILE}" 2>/dev/null | jq -cs . 2>/dev/null)"
  [[ -z "${SEEN}" ]] && SEEN="[]"
fi
FRESH="$(printf '%s\n' "${NEW_ROWS}" \
  | jq -cs --argjson seen "${SEEN}" '
      reduce .[] as $r ({seen: $seen, out: []};
        ([$r.signal, $r.candidate]) as $k
        | if any(.seen[]; . == $k) then . else .seen += [$k] | .out += [$r] end)
      | .out[]' 2>/dev/null)"
if [[ -n "${FRESH}" ]]; then
  # A truncated last line (no trailing newline) would swallow the first new row; terminate it first.
  if [[ -s "${LOG_FILE}" ]] && [[ -n "$(tail -c1 "${LOG_FILE}" 2>/dev/null)" ]]; then
    printf '\n' >> "${LOG_FILE}" 2>/dev/null
  fi
  printf '%s\n' "${FRESH}" >> "${LOG_FILE}" 2>/dev/null
fi

exit 0
