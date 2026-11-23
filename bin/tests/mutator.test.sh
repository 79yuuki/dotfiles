#!/usr/bin/env bash
# Tests for bin/mutator: which Node it picks, the PATH its children see, arguments and exit codes.
# Fake node binaries print what they would run. PATH is minimal, so the wrapper runs on /bin/bash
# (3.2 on macOS), the strictest bash it meets.
# Usage: bash bin/tests/mutator.test.sh

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
T="$(mktemp -d /tmp/mutator-wrapper-test.XXXXXX)" || exit 1
[[ -d "$T" ]] || exit 1
trap 'rm -rf "$T"' EXIT
PASS=0
FAIL=0

fake_node() { # dir major label
  mkdir -p "$1"
  cat > "$1/node" <<EOF
#!/bin/sh
if [ "\$1" = -e ]; then [ $2 -ge 24 ]; exit \$?; fi
printf '%s child=%s' "$3" "\$(command -v node)"
for a in "\$@"; do printf ' [%s]' "\$a"; done
echo
exit "\${FAKE_RC:-0}"
EOF
  chmod +x "$1/node"
}

mkdir -p "$T/prefix/lib/node_modules/@mizchi/mutator/dist" && touch "$T/prefix/lib/node_modules/@mizchi/mutator/dist/cli.js"
CLI="$T/prefix/lib/node_modules/@mizchi/mutator/dist/cli.js"
fake_node "$T/path22" 22 path22
fake_node "$T/path26" 26 path26
fake_node "$T/nvm/versions/node/v9.0.0/bin" 9 v9.0.0
fake_node "$T/nvm/versions/node/v24.4.0/bin" 24 v24.4.0
fake_node "$T/nvm/versions/node/v24.22.1/bin" 24 v24.22.1
fake_node "$T/nvm-old/versions/node/v22.23.4/bin" 22 v22.23.4

check() { # name expected path nvm_dir prefix [fake_rc]
  local got
  got="$(env PATH="$3:/usr/bin:/bin" NVM_DIR="$4" MUTATOR_PREFIX="$5" FAKE_RC="${6:-0}" bash "$REPO/bin/mutator" --since 'origin/main' 'a b' 2>&1; echo "rc=$?")"
  if [[ "$got" == "$2" ]]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1 (got: $got)"; fi
}

NEED24=$'mutator: needs Node >= 24; install one with nvm (e.g. nvm install 24)\nrc=1'
check "PATH の node が 24 以上ならそれを使い、PATH は変えない" \
  "path26 child=$T/path26/node [$CLI] [--since] [origin/main] [a b]"$'\nrc=0' "$T/path26" "$T/nvm" "$T/prefix"
check "PATH の node が 24 未満なら nvm の最新（版の数字で比べる）を使い、子プロセスにもその node が見える" \
  "v24.22.1 child=$T/nvm/versions/node/v24.22.1/bin/node [$CLI] [--since] [origin/main] [a b]"$'\nrc=0' "$T/path22" "$T/nvm" "$T/prefix"
check "mutator の終了コードをそのまま返す" \
  "path26 child=$T/path26/node [$CLI] [--since] [origin/main] [a b]"$'\nrc=2' "$T/path26" "$T/nvm" "$T/prefix" 2
check "nvm に 24 以上が無ければ案内して失敗する" "$NEED24" "$T/path22" "$T/nvm-old" "$T/prefix"
check "nvm が無ければ案内して失敗する" "$NEED24" "$T/path22" "$T/none" "$T/prefix"
check "mutator が未導入なら案内して 127" \
  "mutator: $T/missing/lib/node_modules/@mizchi/mutator/dist/cli.js not found; run scripts/setup-node.sh in dotfiles"$'\nrc=127' "$T/path26" "$T/nvm" "$T/missing"

echo "passed=$PASS failed=$FAIL"
[[ "$FAIL" -eq 0 ]]
