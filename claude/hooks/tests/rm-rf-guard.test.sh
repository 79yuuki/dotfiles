#!/usr/bin/env bash
# Tests for rm-rf-guard.py. Usage: bash rm-rf-guard.test.sh
#   HOOK_PATH で検査する hook を差し替えられる。期待値: ASK / NONE（何も出力しない）。
#   hook に渡す TMPDIR と HOME は固定値にして、結果が実行環境で変わらないようにする。

HOOK="${HOOK_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/rm-rf-guard.py}"
HOOK_TMPDIR=/var/folders/zz/abc123/T/
S=/private/tmp/claude-501/-Users-x-repo/0a1b2c3d/scratchpad
T="$(mktemp -d)" || exit 1
[[ -d "$T" ]] || exit 1
trap 'rm -rf "$T"' EXIT
mkdir "$T/real" && ln -s /usr "$T/link" || exit 1
PASS=0
FAIL=0

check() { # name expected raw-stdin
  local name="$1" expected="$2" input="$3" out rc got="NONE"
  out="$(printf '%s' "$input" | env TMPDIR="$HOOK_TMPDIR" HOME=/Users/tester "$HOOK" 2>&1)"; rc=$?
  if [[ -n "$out" ]]; then
    if printf '%s' "$out" | jq -e '.hookSpecificOutput | .hookEventName == "PreToolUse" and .permissionDecision == "ask" and (.permissionDecisionReason | length > 0)' >/dev/null 2>&1; then
      got="ASK"
    else got="INVALID"; fi
  fi
  if [[ "$got" == "$expected" && "$rc" -eq 0 ]]; then
    PASS=$((PASS+1)); echo "PASS [$expected] $name"
  else
    FAIL=$((FAIL+1)); echo "FAIL [$expected] $name (got=$got rc=$rc)"
  fi
}

j() { jq -nc --arg c "$1" '{tool_input:{command:$c}}'; }

read -r -d '' COMMIT <<'CMD'
git commit -m "$(cat <<'EOF'
hooks: don't force a prompt for "rm -rf" under temp dirs

rm -rf ~/foo still asks.
EOF
)"
CMD

read -r -d '' WRITE_SCRIPT <<'CMD'
cat > clean.sh <<'EOF'
rm -rf "$1"
EOF
chmod +x clean.sh
CMD

read -r -d '' REASSIGNED <<'CMD'
S=/tmp/a
[ -d /Users/x/b ] && S=/Users/x/b
rm -rf "$S"
CMD

# NONE: 実際に止まった2例
check "real: headroot"          NONE "$(j "S=$S/headroot && rm -rf \$S && mkdir -p \$S && git archive HEAD | tar -x -C \$S")"
check "real: ux-state"          NONE "$(j "S=$S; cd \"\$S/exp/foo\" && npm test | tail -5 && export UX_WALKTHROUGH_STATE_DIR=\"\$S/exp/ux-state\" PYTHONDONTWRITEBYTECODE=1 && rm -rf \"\$UX_WALKTHROUGH_STATE_DIR\" && python3 run.py")"
# NONE: 対象がすべて一時フォルダ配下
check "/tmp literal"            NONE "$(j 'rm -rf /tmp/build-123')"
check "\$TMPDIR"                NONE "$(j 'rm -rf "$TMPDIR/work" "${TMPDIR}cache"')"
check "/private/var/folders"    NONE "$(j 'rm -r -f /private/var/folders/zz/abc123/T/x')"
check "long flags and --"       NONE "$(j 'rm --recursive --force -- /tmp/x')"
check "redirects and || true"   NONE "$(j 'rm -rf /tmp/x 2>/dev/null >&2 || true')"
check "trailing comment"        NONE "$(j 'rm -rf /tmp/x # 後片付け')"
check "subshell"                NONE "$(j '(S=/tmp/x && rm -rf "$S/build")')"
check "sudo, temp target"       NONE "$(j 'sudo rm -rf /tmp/x')"
check "glob below a subdir"     NONE "$(j 'rm -rf /tmp/x/*')"
check "existing real dir"       NONE "$(j "rm -rf $T/real")"
# NONE: 再帰 + 強制の rm ではない
check "rm file"                 NONE "$(j 'rm file.txt')"
check "rm -r only"              NONE "$(j 'rm -r dir')"
check "rm -f only"              NONE "$(j 'rm -f file.txt')"
check "rm unknown var, no -rf"  NONE "$(j 'rm "$f"')"
check "git rm -rf"              NONE "$(j 'git rm -rf --cached node_modules')"
check "git -C rm -r -f"         NONE "$(j 'git -C repo rm -r -f x')"
check "docker run --rm"         NONE "$(j 'docker run --rm -f Dockerfile img')"
check "grep for rm -rf"         NONE "$(j 'grep -n "rm -rf" README.md')"
check "echo quoted rm -rf"      NONE "$(j "echo 'rm -rf /'")"
check "commit message heredoc"  NONE "$(j "$COMMIT")"
check "heredoc body is data"    NONE "$(j "$WRITE_SCRIPT")"
check "broken quote, no rm"     NONE "$(j 'echo "abc')"
check "no command field"        NONE '{"tool_input":{}}'
check "invalid json"            NONE 'not json {'
check "empty input"             NONE ''
# ASK: 依頼にあった7例
check "home"                    ASK "$(j 'rm -rf ~/foo')"
check "unknown var"             ASK "$(j 'rm -rf $UNKNOWN')"
check ".. out of /tmp"          ASK "$(j 'rm -rf /tmp/../Users/x')"
check "temp root itself"        ASK "$(j 'rm -rf /tmp')"
check "command substitution"    ASK "$(j 'rm -rf "$(pwd)"')"
check "relative after cd"       ASK "$(j 'cd x && rm -rf build')"
check "rm -fr /etc"             ASK "$(j 'rm -fr /etc')"
# ASK: フラグの書き方
check "rm -Rf"                  ASK "$(j 'rm -Rf ~/x')"
check "rm -r -f"                ASK "$(j 'rm -r -f build')"
check "rm long flags"           ASK "$(j 'rm --recursive --force /Users/x')"
check "rm -rfv"                 ASK "$(j 'rm -rfv /Users/x')"
# ASK: 対象が一時フォルダ配下だと言い切れない
check "one target outside"      ASK "$(j 'rm -rf /tmp/a /Users/x/b')"
check "glob at temp root"       ASK "$(j 'rm -rf /tmp/*')"
check "temp root with slash"    ASK "$(j 'rm -rf /private/tmp/')"
check "\$TMPDIR itself"         ASK "$(j 'rm -rf "$TMPDIR"')"
check "glob at \$TMPDIR"        ASK "$(j 'rm -rf "$TMPDIR"/*')"
check "brace reaching root"     ASK "$(j 'rm -rf /tmp/{a,}')"
check "whitespace in target"    ASK "$(j 'rm -rf "/tmp/my dir"')"
check "symlink leaving temp"    ASK "$(j "rm -rf $T/link/share")"
HOOK_TMPDIR=/Users check "TMPDIR above HOME" ASK "$(j 'rm -rf "$TMPDIR/tester/x"')"
# ASK: 変数を解決できない
check "var from \$HOME"         ASK "$(j 'S=$HOME/work; rm -rf "$S"')"
check "reassigned var"          ASK "$(j "$REASSIGNED")"
check "appended var"            ASK "$(j 'S=/tmp/a; S+=b; rm -rf "$S"')"
check "single-quoted \$S"       ASK "$(j "S=/tmp/x; rm -rf '\$S'")"
check "prefix assignment"       ASK "$(j 'S=/tmp/x true; rm -rf "$S"')"
check "subshell-scoped var"     ASK "$(j '(S=/tmp/x); rm -rf "$S/sub"')"
check "used before assigned"    ASK "$(j 'rm -rf "$S"; S=/tmp/x')"
check "export sees old value"   ASK "$(j 'export A=/tmp/x B=$A/y; rm -rf "$B"')"
check "parameter expansion"     ASK "$(j 'S=/tmp/x; rm -rf "${S:-/}"')"
check "loop variable"           ASK "$(j 'for d in a b; do rm -rf "$d"; done')"
# ASK: rm の置かれ方
check "inside \$()"             ASK "$(j 'echo "$(rm -rf ~/x)"')"
check "inside backticks"        ASK "$(j 'echo `rm -rf ~/x`')"
check "after newline"           ASK "$(j $'cd repo\nrm -rf node_modules')"
check "find -exec"              ASK "$(j 'find . -name __pycache__ -exec rm -rf {} +')"
check "xargs, no target"        ASK "$(j 'ls | xargs rm -rf')"
check "sudo, outside temp"      ASK "$(j 'sudo rm -rf /etc/foo')"
check "/bin/rm"                 ASK "$(j '/bin/rm -rf ~/x')"
check "backslash rm"            ASK "$(j '\rm -rf ~/x')"
check "quoted rm"               ASK "$(j '"rm" -rf ~/x')"
check "unparsable with rm"      ASK "$(j 'rm -rf "/tmp/x')"

echo "---"; echo "PASS=$PASS FAIL=$FAIL"
[[ "$FAIL" -eq 0 ]]
