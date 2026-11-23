#!/usr/bin/env bash
# Tests for bin/mutator: which Node it picks. Fake node binaries print what they would run.
# Usage: bash bin/tests/mutator.test.sh

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
T="$(mktemp -d /tmp/mutator-wrapper-test.XXXXXX)" || exit 1
[[ -d "$T" ]] || exit 1
trap 'rm -rf "$T"' EXIT
PASS=0
FAIL=0

fake_node() { # dir major label
  mkdir -p "$1"
  printf '#!/bin/sh\nif [ "$1" = -e ]; then [ %s -ge 24 ]; exit $?; fi\necho "%s $*"\n' "$2" "$3" > "$1/node"
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

check() { # name expected-output-or-rc path nvm_dir prefix
  local got
  got="$(env PATH="$3:/usr/bin:/bin" NVM_DIR="$4" MUTATOR_PREFIX="$5" bash "$REPO/bin/mutator" --since HEAD 2>/dev/null; echo "rc=$?")"
  if [[ "$got" == "$2" ]]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1 (got: $got)"; fi
}

check "PATH の node が 24 以上ならそれを使う" $'path26 '"$CLI"$' --since HEAD\nrc=0' "$T/path26" "$T/nvm" "$T/prefix"
check "PATH の node が 24 未満なら nvm の最新（版の数字で比べる）を使う" $'v24.22.1 '"$CLI"$' --since HEAD\nrc=0' "$T/path22" "$T/nvm" "$T/prefix"
check "nvm に 24 以上が無ければ失敗する" 'rc=1' "$T/path22" "$T/nvm-old" "$T/prefix"
check "nvm が無ければ失敗する" 'rc=1' "$T/path22" "$T/none" "$T/prefix"
check "mutator が未導入なら 127" 'rc=127' "$T/path26" "$T/nvm" "$T/missing"

echo "passed=$PASS failed=$FAIL"
[[ "$FAIL" -eq 0 ]]
