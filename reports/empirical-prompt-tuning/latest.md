# Empirical Prompt Tuning — latest

- target: ui-refine（claude/skills/ui-refine/SKILL.md）
- date: 2026-11-23
- iteration: 2
- status: doing
- 結果: 白紙の実行者（Sonnet）2 本。iter1（仕様が文言・図・色まで決めている確認の段）は critical 2/2・checklist 7/7、iter2（hold-out。架空の払い戻しの確認の段、題材は fixtures/ui-refine/）は critical 2/2・checklist 6/7（重い順が 1 か所崩れた）。どちらも説明を足さず、仕様を変える直しを「聞く案」に分けた
- 詳細: 2026-11-23-ui-refine-iter1.md / -iter2.md
- 追記（2026-11-24）: 実際の導線で 1 回使った（非公開の題材。白紙の AI の前後比較 1 回ずつ、左右に並べた静止画で人が確認）。使い心地で詰まった 10 件（数える範囲、表の中のボタンの数え方、長い画面の渡し方、E2E が無いリポジトリの柵、人に聞けない作業者の進め方ほか）と、依頼者の追加の方針（人は文を読まない前提、図で見せる、文字の予算、控えめ版と大胆版、仕様の書き換えの提案）を反映した。白紙の実行者での再試行はしていない
- next action: 大胆版まで含めた形で次の導線に使い、本文を隠すテストの合格の条件と文字の予算が回るかを見る。ux-walkthrough の録画のページでの前後比較を一度通す
