# Empirical Prompt Tuning — latest

- target: ui-refine（claude/skills/ui-refine/SKILL.md）
- date: 2026-11-23
- iteration: 2
- status: doing
- 結果: 白紙の実行者（Sonnet）2 本。iter1（仕様が文言・図・色まで決めている確認の段）は critical 2/2・checklist 7/7、iter2（hold-out。架空の払い戻しの確認の段、題材は fixtures/ui-refine/）は critical 2/2・checklist 6/7（重い順が 1 か所崩れた）。どちらも説明を足さず、仕様を変える直しを「聞く案」に分けた
- 詳細: 2026-11-23-ui-refine-iter1.md / -iter2.md
- next action: 実際の導線で前後比較（白紙の AI と ux-walkthrough の録画のページ）を一度通す。次に使った時に iter2 の修正（分類の例、重い順）が効いたかを見る
