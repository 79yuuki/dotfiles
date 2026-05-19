# Benchmark Corpus Shortlist

`coding-agent` / harness 改善を **単発の成功談** ではなく、
**比較可能な scenario / hold-out / onboarding corpus** で見るための最小スターター。

## 使い方

まずは 1 run で全部試さない。
改善を比べる時は、最低でも以下の **3本セット** から始める。

- **scenario** — 今すぐ運用に効く代表ケース
- **hold-out** — 似てるけど少しズレた境界ケース
- **onboarding** — 新メンバーや別案件に説明しやすいケース

artifact には最低これを残す。

```md
## Benchmark bundle
- scenario: <asset>
- hold-out: <asset>
- onboarding: <asset>
- why this bundle: <どの failure mode を見たいか>
```

## Candidate shortlist (v0)

> Source cluster: 2026-04-30 の bookmark insight（1087）で触れた
> DeNA+GO 公開AI勉強会群 / Claude Code log 系の公開資産。

| # | Candidate asset | Source cluster | Primary tag(s) | Why keep it in the corpus |
|---|---|---|---|---|
| 1 | Claude Codeのログから学びを得る（2026-03） | DeNA+GO AI Community / public study deck | scenario, onboarding | 実行ログから学びを抽出する型を見れる。prompt・tool loop・review loop の比較材料になる |
| 2 | GUI操作LLM論文紹介: UI-TARS / InfiGUI-R1 +α（2025-07） | DeNA+GO AI Community / public study deck | hold-out, onboarding | browser / computer-use 系の failure mode を見る時の境界ケースになる |
| 3 | DeepSeek-OCR: 画像によるコンテキスト圧縮は可能か？（2025-10） | DeNA+GO AI Community / public study deck | hold-out | 画像/OCR/圧縮系で、普段の coding-agent とは違う入力構造を試せる |
| 4 | Kaggle / competition retrospective 系 deck | DeNA+GO AI Community / public study deck | hold-out, onboarding | research-heavy な進め方が、実務ハーネス改善にそのまま乗らない境界を見れる |
| 5 | NLP2026 参加報告系 deck | DeNA+GO AI Community / public study deck | onboarding | conference insight を実務運用へ落とす時の説明素材になる |
| 6 | CVPR / NeurIPS / ICLR 論文紹介系 deck | DeNA+GO AI Community / public study deck | hold-out, onboarding | 論文サーベイを runnable rule に変換できるかを見るための非実装寄りコーパス |
| 7 | 現場AI技術の動向調査 deck | DeNA+GO AI Community / public study deck | scenario | trend scan を hot take で終わらせず reusable change に変える比較材料 |
| 8 | 社内ツール開発の知見 deck | DeNA+GO AI Community / public study deck | scenario, onboarding | internal tool / docs / review flow 改善にそのまま効く実務寄りケース |
| 9 | MLOps / DevOps 実践系 deck | DeNA+GO AI Community / public study deck | scenario | hook / test / deploy / evaluation loop の改善で比較しやすい |
| 10 | 次に見つけた Claude Code / agent ops retrospective 公開ログ | Claude Code public log family | scenario, hold-out | 同じ log 系 asset を増やして、単発 deck 依存を避けるための拡張スロット |

## Starter bundles

### Bundle A — coding-agent 実務改善
- scenario: #1 Claude Codeのログから学びを得る
- hold-out: #4 Kaggle / competition retrospective
- onboarding: #8 社内ツール開発の知見
- 使いどころ: review loop / shared language / slice 分割の改善比較

### Bundle B — browser / multimodal 境界確認
- scenario: #9 MLOps / DevOps 実践系
- hold-out: #2 GUI操作LLM論文紹介
- onboarding: #3 DeepSeek-OCR
- 使いどころ: coding-agent 以外に横展開する時の無理筋チェック

### Bundle C — org learning / recruiting / explainability
- scenario: #7 現場AI技術の動向調査
- hold-out: #6 論文紹介系
- onboarding: #5 NLP2026参加報告系
- 使いどころ: 学習資産を採用 / 会社説明 / onboarding へ転用する時

## Selection rules

- まず **3本だけ** 使う
- 同じ系統の asset だけで固めない
- `scenario` だけ勝っても promote しない
- `hold-out` で崩れたら、skill 本文か routing を見直す
- onboarding に使えない改善は、company-wide ルールへ昇格しにくいとみなす

## Next expansion

次の実運用では、上の shortlist から **実URL / 正式タイトル / 1行メモ** を埋めていく。
いきなり100件掘らず、まず 3 asset で 1回比較を回してから増やす。
