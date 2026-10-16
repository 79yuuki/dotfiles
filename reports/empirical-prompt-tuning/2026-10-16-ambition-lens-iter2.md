# Empirical Prompt Tuning — ambition-lens

- date: 2026-10-16
- target: claude/skills/ambition-lens/SKILL.md (+ references/techniques.md)
- iteration: 2
- status: doing

## Scenario set（references の例に無い新シナリオ）
- N1: 「採用面接の評価シートを作りたい」
- N2: 「このAPIのレスポンスが遅いから速くして。今 p95 が 1.2 秒くらい」
- N3: 「毎週月曜に手でやってる競合サイトの価格チェック、もうちょっと楽にしたい」
- N4: 「明日の朝イチの役員会で使う、新規事業の進捗報告資料を今日中に作って」（緊急）
- Hold-out H3: 「git の rebase と merge の違いって何？」（概念の質問）
- Hold-out H4: 「ブログ記事のネタ出し、もっと野心的にやりたい」（明示要求 + 創作）

## Checklist
iteration 1 と同じ（[critical] 判定の一致、[critical] 1問・依頼固有の書き換え案、そのまま案、推奨先頭と前提、preview 全文、選択前に着手しない）。
期待判定: N1/N2/N3/H4 = ask_now、N4 = ask_after（当時の規定）、H3 = skip。

## Change in this iteration
- iteration 1 の Next action をすべて反映（判定順の番号化と Skip 優先、選択肢 2〜3+そのまま、同軸の段階違い可、選ばれたら追加質問不要な依頼文、事実の曖昧さの扱い、他 skill との順序、非対話の Skip）

## Results
| Scenario | success | accuracy | efficiency note | retries |
|---|---|---|---|---|
| N1 | ○ ask_now | 6/6 | 推奨軸の選び方で1回入れ替え | 2 |
| N2 | ○ ask_now | 6/6 | 本番の遅延を障害とみなすか検討 | 2（判断は不変） |
| N3 | ○ ask_now | 6/6 | 「楽にしたい」= Speed かで迷う | 0 |
| N4 | ○ ask_after | 6/6 | 資料は後置きだと手戻りが大きいと指摘 | 0 |
| H3 | ○ skip | 6/6 | references 不要 | 0 |
| H4 | ○ ask_now | 6/6 | 明示要求ルールで即決 | 0 |

## New ambiguities（要約）
- 推奨案（先頭）の選び方の基準が無い（N1, N2, N3, N4）
- 緊急時に資料を後置きにすると、Altitude が選ばれた時に締切前夜の手戻りになる（N4）
- 明示語の「急ぎ」と、文脈上の締切（今日中・明日朝）の境界（N4）
- 「事実質問」に概念の説明依頼が含まれるか（H3）
- 明示要求の時、シグナルが弱い軸の案を作ってよいか。「そのまま」の意味がずれる（H4）
- 繰り返しシグナルに、ユーザーが手でやっている定型業務が含まれるか（N3）
- 入力データ（対象 URL 一覧など）の不足が「選ばれた後の追加質問」に当たるか（N3）
- 仮定が複数ある時の質問文への書き方（N1, N3, H4）
- 数値目標の「非常識」の程度（N2）
- Range の「単一分野の視点でしか見ていない」が広すぎる（H3）

## Codex review（同時実施）: ❌ NEEDS FIXES
- 明示要求が非対話・質問不要・triage 済みより優先されていた
- hook: no-ambition が明示要求に誤一致、否定・引用・語の質問まで STRONG、jq の失敗未検査、stderr 未検証、短い依頼の取りこぼし
- hook の入力フィールドは公式ドキュメント上 `prompt`（`user_input` という記述は要約の誤り。ドキュメント原文で確認済み）
- 「1問だけ」を野心度の質問に限定すべき。techniques の例に元依頼に無い前提が入っていた

## Decision
- keep iterating。判定は 12/12 一致が続くが、判定順と緊急時の分岐を構造的に直す必要がある。

## Next action（iteration 3 で反映済み）
- 判定順: 聞けない/聞くな → 明示要求 → Speed → 緊急（バグは後置き、資料は先に絞った案で聞く）→ シグナル
- 推奨の基準、明示要求時の軸とそのまま、概念の質問、繰り返し業務の行、入力データ不足の扱い、仮定の書き方、目標は1桁以上、Range の行を絞る
- iteration 3 は判定順の境界ケースで回す
