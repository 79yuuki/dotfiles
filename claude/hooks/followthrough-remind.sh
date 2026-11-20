#!/usr/bin/env bash
# SessionStart hook: 段階導入の計画が「次へ進む条件」を満たしていたら、1 行だけ文脈に差し込む。
# 手元の状態ファイルを読むだけで、ネットワークも LLM も使わない。失敗しても黙って終わる（常に exit 0）。
# 条件の点検そのものは、launchd の日次ジョブ（scripts/install-followthrough.sh）が行う。

cat >/dev/null 2>&1 || true   # hook の入力（JSON）は使わない

SCRIPT="${FOLLOWTHROUGH_PY:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd -P)/scripts/followthrough.py}"
[ -f "$SCRIPT" ] || exit 0
python3 "$SCRIPT" remind 2>/dev/null || true
exit 0
