#!/usr/bin/env bash
# Stop hook: harness opportunity detection.
#
# Anthropic公式 (large-codebase blog) の "A stop hook can reflect on what happened
# during a session and propose CLAUDE.md updates while the context is fresh" を実装。
#
# Design principles:
# - Detect only. No mutation, no external send.
# - Append-only jsonl. No LLM calls. grep-based heuristics only.
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

mkdir -p "${STATE_DIR}" 2>/dev/null || exit 0

# Read stdin payload (may be empty if hook invoked manually for testing).
PAYLOAD=""
if [[ ! -t 0 ]]; then
  PAYLOAD="$(cat)"
fi

# Best-effort field extraction. jq is optional.
get_field() {
  local field="$1"
  if [[ -z "${PAYLOAD}" ]]; then
    echo ""
    return
  fi
  if command -v jq >/dev/null 2>&1; then
    echo "${PAYLOAD}" | jq -r --arg f "${field}" '.[$f] // empty' 2>/dev/null
  else
    # Fallback: naive grep.
    echo "${PAYLOAD}" | grep -oE "\"${field}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
      | head -1 | sed -E "s/.*\"${field}\"[[:space:]]*:[[:space:]]*\"([^\"]*)\".*/\1/"
  fi
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

# Run each detector. Each emits 0+ jsonl rows to stdout.
{
  detect_bash_repeat "${TRANSCRIPT_PATH}" "${TS}" "${PROJECT}" "${CWD}" "${SESSION_ID}"
  detect_manual_checklist "${TRANSCRIPT_PATH}" "${TS}" "${PROJECT}" "${CWD}" "${SESSION_ID}"
  detect_edit_without_lint "${TRANSCRIPT_PATH}" "${TS}" "${PROJECT}" "${CWD}" "${SESSION_ID}"
  detect_recurring_keyword "${TRANSCRIPT_PATH}" "${TS}" "${PROJECT}" "${CWD}" "${SESSION_ID}"
  detect_instruction_bloat "${TRANSCRIPT_PATH}" "${TS}" "${PROJECT}" "${CWD}" "${SESSION_ID}"
} >> "${LOG_FILE}" 2>/dev/null

exit 0
