# Muser Coding Hygiene

`memory/topics/dev-workflow.md` から、再利用価値の高い手順だけを抽出した運用ルール。

## 1. コードを書く前に contract を固定する
最低限これを先に決める:
- Goal — 何を変えるか
- Non-goals — 何をやらないか
- Done when — 何を満たせば完了か
- Boundaries — どこまで編集してよいか / 触ってはいけない所はどこか

**自由度を上げる前にガードレールを作る。**

## 2. CLI-first で考える
- MCP は最後の手段
- まず CLI / file / test / git diff で十分か確認する
- agent runtimeスキルも self-contained scripts を優先する

## 3. ワンショットの守備範囲を超えたら昇格する
次に当てはまるなら `coding-agent` に留めず、`dual-agent-dev` / `agent-teams-dev` / `harness-engineering` を検討する:
- 複数ファイルをまたぐ
- 設計判断が大きい
- 長時間自走が必要
- generator / evaluator 分離が欲しい

## 4. JS/TS は dead code 掃除を定例にする
vibe / agent coding 後は、まず `knip` で以下を確認する:
- 未使用ファイル
- 未使用export
- 未使用依存
- ゴーストファイル（似た名前の新ファイル）

動いたかだけで終わらせず、**余計なコードが増えていないか** を見る。

## 5. レビュー観点は「動作」だけじゃない
最低でも以下を確認する:
- 動くか
- 余計な抽象化を混ぜていないか
- bad pattern を増やしていないか
- セキュリティ/設定逃げをしていないか

## 6. maintenance > new features
新しい実装を足す前に、既存の壊れや不整合を直せないかを見る。
「この機能を足す前に、既存のXは壊れてないか？」を毎回自問する。

## 7. Managed long task として扱う時
長時間タスクでは、先に以下を渡す:
- memory / decision / domain rule
- evaluation criteria
- progress artifact
- next-step handoff

会話で粘るより、**artifact-first** で継続する。
