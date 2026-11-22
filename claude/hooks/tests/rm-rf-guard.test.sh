#!/usr/bin/env bash
# Tests for rm-rf-guard.py と、その登録（settings.base.json / sync-claude-settings.sh）。
# Usage: bash rm-rf-guard.test.sh
#   HOOK_PATH で検査する hook を差し替えられる。期待値: ASK / NONE（何も出力しない）。
#   hook に渡す TMPDIR と HOME は固定値にして、結果が実行環境で変わらないようにする。

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
HOOK="${HOOK_PATH:-$REPO/claude/hooks/rm-rf-guard.py}"
RUN=("$HOOK")
HOOK_TMPDIR=/var/folders/zz/abc123/T/
HOOK_HOME=/Users/tester
HOOK_ENV_PATH="$PATH"
S=/private/tmp/claude-501/-Users-x-repo/0a1b2c3d/scratchpad
T="$(mktemp -d /tmp/rm-rf-guard-test.XXXXXX)" || exit 1
[[ -d "$T" ]] || exit 1
trap 'rm -rf "$T"' EXIT
mkdir "$T/real" && ln -s /usr "$T/link" || exit 1
PASS=0
FAIL=0

check() { # name expected raw-stdin
  local name="$1" expected="$2" input="$3" out rc got="NONE"
  out="$(printf '%s' "$input" | env PATH="$HOOK_ENV_PATH" TMPDIR="$HOOK_TMPDIR" HOME="$HOOK_HOME" "${RUN[@]}" 2>&1)"; rc=$?
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

ok() { # name condition(0=true)
  if [[ "$2" -eq 0 ]]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi
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

read -r -d '' DOLLAR_DELIMITER <<'CMD'
cat <<'E$OF'
text
E$OF
rm -rf ~/project
CMD

read -r -d '' UNCALLED_FUNCTION <<'CMD'
cleanup() {
S=/tmp/job
}; rm -rf "$S/build"
CMD

read -r -d '' BARE_DOLLAR_DELIMITER <<'CMD'
cat <<E$OF
text
E$OF
rm -rf /tmp/job
CMD

read -r -d '' BACKGROUND_SUBSHELL <<'CMD'
S=/tmp/x
(cd "$S" && make) &
wait
rm -rf "$S"
CMD

read -r -d '' CONTINUED_LINES <<'CMD'
set -e
S=/tmp/x &&

  rm -rf "$S" \
    "$S.bak"
CMD

# NONE: 実際に止まった2例
check "real: headroot"          NONE "$(j "S=$S/headroot && rm -rf \$S && mkdir -p \$S && git archive HEAD | tar -x -C \$S")"
check "real: ux-state"          NONE "$(j "S=$S; cd \"\$S/exp/foo\" && npm test | tail -5 && export UX_WALKTHROUGH_STATE_DIR=\"\$S/exp/ux-state\" PYTHONDONTWRITEBYTECODE=1 && rm -rf \"\$UX_WALKTHROUGH_STATE_DIR\" && python3 run.py")"
# NONE: 対象がすべて一時フォルダ配下
check "/tmp literal"            NONE "$(j 'rm -rf /tmp/build-123')"
check "\$TMPDIR"                NONE "$(j 'rm -rf "$TMPDIR/work" "${TMPDIR}cache"')"
check "\${S:?} guard"           NONE "$(j 'S=/tmp/x; rm -rf "${S:?}/out" "${S:?unset}"/*')"
check "/private/var/folders"    NONE "$(j 'rm -r -f /private/var/folders/zz/abc123/T/x')"
check "long flags and --"       NONE "$(j 'rm --recursive --force -- /tmp/x')"
check "redirects and || true"   NONE "$(j 'rm -rf /tmp/x 2>/dev/null >&2 || true')"
check "process substitution"    NONE "$(j 'rm -rf 2> >(cat) /tmp/job')"
check "trailing comment"        NONE "$(j 'rm -rf /tmp/x # 後片付け')"
check "subshell"                NONE "$(j '(S=/tmp/x && rm -rf "$S/build")')"
check "var used inside if"      NONE "$(j 'S=/tmp/x; if [ -d "$S" ]; then rm -rf "$S"; fi')"
check "var used inside { }"     NONE "$(j 'S=/tmp/x; test -d "$S" && { rm -rf "$S"; echo done; }')"
check "sequential reassignment" NONE "$(j 'S=/tmp/job; S=/tmp/job/sub; rm -rf "$S"')"
check "&& list with \$() and |" NONE "$(j 'true && S=/tmp/job && echo "$(pwd)" | tail -1 && rm -rf "$S"')"
check "unset in a subshell"     NONE "$(j 'S=/tmp/job; (unset S); rm -rf "$S"')"
check "background subshell"     NONE "$(j "$BACKGROUND_SUBSHELL")"
check "continued lines"         NONE "$(j "$CONTINUED_LINES")"
check "heredoc delimiter E\$OF" NONE "$(j "$BARE_DOLLAR_DELIMITER")"
check "sudo, temp target"       NONE "$(j 'sudo rm -rf /tmp/x')"
check "timeout / env / nice"    NONE "$(j 'timeout 5 rm -rf /tmp/x && env A=1 nice -n 5 rm -rf /tmp/y')"
check "glob below a subdir"     NONE "$(j 'rm -rf /tmp/x/*')"
check "existing real dir"       NONE "$(j "rm -rf $T/real")"
# NONE: 再帰 + 強制の rm を実行しない
check "rm file"                 NONE "$(j 'rm file.txt')"
check "rm -r only"              NONE "$(j 'rm -r dir')"
check "rm -f only"              NONE "$(j 'rm -f file.txt')"
check "rm unknown var, no -rf"  NONE "$(j 'rm "$f"')"
check "git rm -rf"              NONE "$(j 'git rm -rf --cached node_modules')"
check "git -C rm -r -f"         NONE "$(j 'git -C repo rm -r -f x')"
check "/usr/bin/git rm -rf"     NONE "$(j '/usr/bin/git rm -rf --cached node_modules')"
check "env ... git rm -rf"      NONE "$(j 'env GIT_CONFIG_NOSYSTEM=1 git rm -rf --cached node_modules')"
check "echo rm -rf"             NONE "$(j 'echo rm -rf /etc')"
check "docker run --rm"         NONE "$(j 'docker run --rm -f Dockerfile img')"
check "grep for rm -rf"         NONE "$(j 'grep -n "rm -rf" README.md')"
check "echo quoted rm -rf"      NONE "$(j "echo 'rm -rf /'")"
check "commit message heredoc"  NONE "$(j "$COMMIT")"
check "commit message \$'..'"   NONE "$(j "git commit -m \$'fix rm guard: don\\'t block cleanup'")"
check "\$' inside double quotes" NONE "$(j "git commit -m \"Fix rm parser for \$' quoting\"")"
check "heredoc body is data"    NONE "$(j "$WRITE_SCRIPT")"
check "arithmetic shift"        NONE "$(j $'echo $((1 << 2\n)); echo rm')"
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
check "target after procsubst"  ASK "$(j 'rm -rf /tmp/job 2> >(cat) ~/project')"
check "quoted digits target"    ASK "$(j 'rm -rf /tmp/job "123">/dev/null')"
check "escaped digits target"   ASK "$(j 'rm -rf /tmp/job \123>/dev/null')"
check "glob at temp root"       ASK "$(j 'rm -rf /tmp/*')"
check "temp root with slash"    ASK "$(j 'rm -rf /private/tmp/')"
check "\$TMPDIR itself"         ASK "$(j 'rm -rf "$TMPDIR"')"
check "glob at \$TMPDIR"        ASK "$(j 'rm -rf "$TMPDIR"/*')"
check "brace reaching root"     ASK "$(j 'rm -rf /tmp/{a,}')"
check "whitespace in target"    ASK "$(j 'rm -rf "/tmp/my dir"')"
check "symlink leaving temp"    ASK "$(j "rm -rf $T/link/share")"
HOOK_TMPDIR=/Users check "TMPDIR above HOME" ASK "$(j 'rm -rf "$TMPDIR/tester/x"')"
# ASK: 変数の値が確かではない
check "var from \$HOME"         ASK "$(j 'S=$HOME/work; rm -rf "$S"')"
check "assigned after &&"       ASK "$(j '[ -d /tmp/a ] && S=/tmp/a; rm -rf "$S/old"')"
check "assigned after ||"       ASK "$(j 'cd /x || S=/tmp/a; rm -rf "$S/old"')"
check "assigned inside if"      ASK "$(j 'if [ -n "$CI" ]; then S=/tmp/a; fi; rm -rf "$S/old"')"
check "assigned inside { }"     ASK "$(j '{ S=/tmp/job; rm -rf "$S"; }')"
check "assigned in function"    ASK "$(j "$UNCALLED_FUNCTION")"
check "assigned in pipeline"    ASK "$(j 'S=/tmp/job | cat; rm -rf "$S/build"')"
check "assigned in background"  ASK "$(j 'S=/tmp/job & wait; rm -rf "$S/build"')"
check "&& list in background"   ASK "$(j 'S=/Users/tester/project; S=/tmp/job && echo ready & wait; rm -rf "$S"')"
check "&& list ended by ( )"    ASK "$(j 'true && S=/tmp/x && (true); rm -rf "$S/y"')"
check "&& list crossed by ||"   ASK "$(j 'true && S=/tmp/x || true && rm -rf "$S/y"')"
check "appended var"            ASK "$(j 'S=/tmp/a; S+=b; rm -rf "$S"')"
check "local outside function"  ASK "$(j 'local S=/tmp/l; rm -rf "$S"')"
check "readonly keeps old value" ASK "$(j 'readonly S=/Users/x; S=/tmp/a; rm -rf "$S"')"
check "unset var"               ASK "$(j 'S=/tmp/job; unset S; rm -rf "$S"')"
check "\${S:=x} assigns"        ASK "$(j 'S=/tmp/job; : "${S:=/Users/tester/project}"; rm -rf "$S"')"
check "read rebinds"            ASK "$(j 'S=/tmp/x; read S; rm -rf "$S"')"
check "builtin read rebinds"    ASK "$(j 'S=/tmp/job; builtin read -r S; rm -rf "$S"')"
check "read sets REPLY"         ASK "$(j 'REPLY=/tmp/job; read; rm -rf "$REPLY"')"
check "read inside subshell"    ASK "$(j 'S=/tmp/job; (S=/tmp/inner; read -r S; rm -rf "$S")')"
check "for rebinds"             ASK "$(j 'S=/tmp/x; for S in ~/a ~/b; do :; done; rm -rf "$S"')"
check "single-quoted \$S"       ASK "$(j "S=/tmp/x; rm -rf '\$S'")"
check "prefix assignment"       ASK "$(j 'S=/tmp/x true; rm -rf "$S"')"
check "subshell-scoped var"     ASK "$(j '(S=/tmp/x); rm -rf "$S/sub"')"
check "used before assigned"    ASK "$(j 'rm -rf "$S"; S=/tmp/x')"
check "export sees old value"   ASK "$(j 'export A=/tmp/x B=$A/y; rm -rf "$B"')"
check "parameter expansion"     ASK "$(j 'S=/tmp/x; rm -rf "${S:-/}"')"
check "zsh modifier \$S:h"      ASK "$(j 'S=/tmp/x; rm -rf $S:h')"
check "zsh subscript \$S[1]"    ASK "$(j 'S=/tmp/x; rm -rf "$S[1]"')"
check "loop variable"           ASK "$(j 'for d in a b; do rm -rf "$d"; done')"
# ASK: rm の置かれ方
check "inside \$()"             ASK "$(j 'echo "$(rm -rf ~/x)"')"
check "inside \${..:-\$()}"     ASK "$(j 'echo "${UNSET:-$(rm -rf ~/project)}"')"
check "inside \$(( \$() ))"     ASK "$(j 'echo "$(( $(rm -rf ~/project; echo 0) + 1 ))"')"
check "inside backticks"        ASK "$(j 'echo `rm -rf ~/x`')"
check "after newline"           ASK "$(j $'cd repo\nrm -rf node_modules')"
check "after odd heredoc"       ASK "$(j "$DOLLAR_DELIMITER")"
check "find -exec"              ASK "$(j 'find . -name __pycache__ -exec rm -rf {} +')"
check "find git -exec"          ASK "$(j 'find git -name cache -exec rm -rf {} +')"
check "xargs, no target"        ASK "$(j 'ls | xargs rm -rf')"
check "xargs adds targets"      ASK "$(j "printf '%s\\0' /Users/tester/project | xargs -0 rm -rf /tmp/job")"
check "sudo xargs"              ASK "$(j 'sudo xargs rm -rf /tmp/x')"
check "sudo, outside temp"      ASK "$(j 'sudo rm -rf /etc/foo')"
check "/bin/rm"                 ASK "$(j '/bin/rm -rf ~/x')"
check "backslash rm"            ASK "$(j '\rm -rf ~/x')"
check "quoted rm"               ASK "$(j '"rm" -rf ~/x')"
check "unparsable with rm"      ASK "$(j 'rm -rf "/tmp/x')"
check "unclosed ( with rm"      ASK "$(j '(rm -rf /tmp/job')"
check "unclosed heredoc"        ASK "$(j 'rm -rf /tmp/job <<EOF')"

# 登録: settings.base.json のコマンドを、Claude Code と同じように sh -c で動かす
REGISTERED="$(jq -r '.hooks.PreToolUse[] | select(.matcher == "Bash") | .hooks[0].command' "$REPO/claude/settings.base.json")"
RUN=(/bin/sh -c "$REGISTERED")
mkdir -p "$T/with/.claude/hooks" "$T/without" "$T/bin" && ln -s "$HOOK" "$T/with/.claude/hooks/rm-rf-guard.py" && ln -s "$(command -v grep)" "$T/bin/grep" || exit 1
HOOK_HOME="$T/with"
check "registered: outside temp"     ASK  "$(j 'rm -rf ~/foo')"
check "registered: temp"             NONE "$(j 'rm -rf /tmp/x')"
# hook か python3 が無い時は細かい判定をしない。rm という語を含む呼び出しはすべて確認する
HOOK_HOME="$T/without"
check "no hook: rm -rf"              ASK  "$(j 'rm -rf /tmp/x')"
check "no hook: rm after newline"    ASK  "$(j $'cd a\nrm -fr b')"
check "no hook: rm, line continued"  ASK  "$(j $'cd a && rm \\\n  -rf ~/foo')"
check "no hook: rm, tab"             ASK  "$(j $'rm\t-rf ~/foo')"
check "no hook: no rm"               NONE "$(j 'docker run --rm -r x && npm run perform -r && ls rm-rf-guard.py')"
HOOK_HOME="$T/with"
HOOK_ENV_PATH="$T/bin" check "no python3: rm -rf" ASK "$(j 'rm -rf /tmp/x')"
HOOK_ENV_PATH="$T/bin" check "no python3: no rm"  NONE "$(j 'ls -la')"

# 生成: sync-claude-settings.sh が hook を登録し、local が PreToolUse を置き換えたら知らせる
mkdir -p "$T/sync/.claude"
ERR="$(HOME="$T/sync" "$REPO/scripts/sync-claude-settings.sh" 2>&1 >/dev/null)"
[[ -z "$ERR" ]] && jq -e '([.hooks.PreToolUse[] | select(.matcher == "Bash")] | length == 1) and (.permissions.ask | index("Bash(rm -rf *)") == null)' "$T/sync/.claude/settings.json" >/dev/null 2>&1
ok "sync: hook registered, ask rule gone" $?
printf '%s' '{"hooks":{"PreToolUse":[{"matcher":"*","hooks":[{"type":"command","command":"true"}]}]}}' >"$T/sync/.claude/settings.local.json"
ERR="$(HOME="$T/sync" "$REPO/scripts/sync-claude-settings.sh" 2>&1 >/dev/null)"
[[ "$ERR" == *"drops a base PreToolUse hook"*"rm-rf-guard.py"* ]]
ok "sync: warns when local replaces PreToolUse" $?
jq '.hooks.PreToolUse |= map(if .matcher == "Bash" then .hooks += [{"type":"command","command":"true"}] else . end) | {hooks: {PreToolUse: .hooks.PreToolUse}}' "$REPO/claude/settings.base.json" >"$T/sync/.claude/settings.local.json"
ERR="$(HOME="$T/sync" "$REPO/scripts/sync-claude-settings.sh" 2>&1 >/dev/null)"
[[ -z "$ERR" ]]
ok "sync: no warning when local keeps the base hooks" $?

echo "---"; echo "PASS=$PASS FAIL=$FAIL"
[[ "$FAIL" -eq 0 ]]
