#!/usr/bin/env bash
# Tests for block-destructive.sh. Usage: bash block-destructive.test.sh
#   HOOK_PATH で検査する hook を差し替えられる。期待値: DENY / NONE。

HOOK="${HOOK_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/block-destructive.sh}"
PASS=0
FAIL=0

check() { # name expected raw-stdin
  local name="$1" expected="$2" input="$3" out rc got="NONE"
  out="$(printf '%s' "$input" | bash "$HOOK" 2>/dev/null)"; rc=$?
  if [[ -n "$out" ]]; then
    if printf '%s' "$out" | jq -e '.hookSpecificOutput | .hookEventName == "PreToolUse" and .permissionDecision == "deny"' >/dev/null 2>&1; then
      got="DENY"
    else got="INVALID"; fi
  fi
  if [[ "$got" == "$expected" && "$rc" -eq 0 ]]; then
    PASS=$((PASS+1)); echo "PASS [$expected] $name"
  else
    FAIL=$((FAIL+1)); echo "FAIL [$expected] $name (got=$got rc=$rc)"
  fi
}

j() { jq -nc --arg c "$1" '{tool_input:{command:$c}}'; }

# DENY
check "rm -rf"            DENY "$(j 'rm -rf build')"
check "rm -fr"            DENY "$(j 'rm -fr x')"
check "rm -Rf"            DENY "$(j 'rm -Rf x')"
check "rm -r -f chained"  DENY "$(j 'cd a && rm -r -f b')"
check "rm long flags"     DENY "$(j 'rm --recursive --force x')"
check "sudo rm -rf"       DENY "$(j 'sudo rm -rf /var/x')"
check "git push --force"  DENY "$(j 'git push --force')"
check "git push -f"       DENY "$(j 'git push -f origin main')"
check "force-with-lease"  DENY "$(j 'git push --force-with-lease origin main')"
check "force-if-includes" DENY "$(j 'git push --force-if-includes origin main')"
check "git push +main"    DENY "$(j 'git push origin +main')"
check "git -C push -f"    DENY "$(j 'git -C repo push -f')"
check "psql drop table"   DENY "$(j 'psql -c "drop table users"')"
check "DROP DATABASE"     DENY "$(j 'mysql -e "DROP DATABASE app;"')"
check "DROP SCHEMA"       DENY "$(j 'psql -c "Drop Schema public cascade"')"
check "TRUNCATE TABLE"    DENY "$(j 'psql -c "TRUNCATE TABLE logs"')"
# NONE
check "rm file"           NONE "$(j 'rm file.txt')"
check "rm -r only"        NONE "$(j 'rm -r dir')"
check "rm -f only"        NONE "$(j 'rm -f file.txt')"
check "rm -r; ls -f"      NONE "$(j 'rm -r dir; ls -f')"
check "git push"          NONE "$(j 'git push origin main')"
check "git push -u"       NONE "$(j 'git push -u origin feature')"
check "git commit msg"    NONE "$(j 'git commit -m "update"')"
check "echo DROP"         NONE "$(j 'echo "DROP は危険"')"
check "grep -rf"          NONE "$(j 'grep -rf patterns file')"
check "truncate -s"       NONE "$(j 'truncate -s 0 file.log')"
check "no command field"  NONE '{"tool_input":{}}'
check "invalid json"      NONE 'not json {'
check "empty input"       NONE ''

echo "---"; echo "PASS=$PASS FAIL=$FAIL"
[[ "$FAIL" -eq 0 ]]
