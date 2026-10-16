# Empirical Prompt Tuning — ambition-lens

- date: 2026-10-16
- target: claude/skills/ambition-lens/SKILL.md (+ references/techniques.md)
- iteration: 3
- status: converged（判定）/ wording は軽微な修正のみ

## Scenario set（判定順の境界ケース）
- E1: 「野心的にやりたいけど質問不要で。テックブログのネタ出しして」（明示要求 + 質問不要）
- E2: claude -p の非対話実行で「この四半期の KPI レポートを深掘りして作って」
- E3: 11:00 時点で「今日17時の顧客提案で使う、3社の見積もり比較表を作って」（緊急の資料）
- E4: Depth を選んだ直後の同一タスクで「地域別のグラフも追加して、まとめのスライドも作って」
- Hold-out E5: 「記事に出てくる ambitious と aspirational ってニュアンスどう違うの？」（語の質問）

## Checklist
iteration 1 と同じ。期待判定: E1/E2/E4/E5 = skip、E3 = ask_now（締切内の規模に絞った案）。

## Change in this iteration
- 判定順を「聞けない/聞くな/もう聞いた → 明示要求 → Speed → 緊急（バグは後置き、資料は先に聞く）→ シグナル」に再構成（Codex 指摘の反映を含む）

## Results
| Scenario | success | accuracy | efficiency note | retries |
|---|---|---|---|---|
| E1 | ○ skip | 6/6 | 明示要求と質問不要の優先順で1回迷う | 1 |
| E2 | ○ skip | 6/6 | references 不要 | 0 |
| E3 | ○ ask_now | 6/6 | 初回は API 側の誤検知で失敗し、再実行で成功。案は 14:30 一次版に絞られた | 0 |
| E4 | ○ skip | 6/6 | 選択済みの Depth を引き継いだ | 0 |
| E5 | ○ skip | 6/6 | 「語の意味の質問は明示要求ではない」で即決 | 0 |

## New ambiguities（要約）
- Skip すると「Speed に決まる」と書いていたため、依頼文の「野心的に」「深掘り」や選択済みの Depth を捨ててよいように読めた（E1, E2, E4）→ 修正済み
- 緊急の資料は §1-5 のシグナルが無くても聞くのか（E3）→ 修正済み
- hook 経由なら常に無言とも読める（E3）→ 修正済み
- 非対話の検知方法、AskUserQuestion が無い対話環境との境界（E2）→ 未修正（実環境では AskUserQuestion の有無で判断できるため軽微）

## Metrics
- tool_uses: 8 / duration_ms: 171562（再実行分を含む workflow 全体）

## Decision
- 3 iteration・17 シナリオで判定は全一致。新規の曖昧点は Skip の意味と緊急資料の条件の2系統に収束し、どちらも修正した。運用に入れ、実使用で再評価する。

## Next action
- 実セッションで hook の発火と skill の起動率を観察する（誤発火・取りこぼしの実例を集める）
- 1〜2週間使ったら、聞き返しが邪魔だった例・役立った例をもとに Skip 条件と hook の語彙を見直す
