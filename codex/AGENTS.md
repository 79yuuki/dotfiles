# Global agent instructions

- すべての返答は日本語で行ってください。
- 技術的な内容でも日本語を優先して説明してください。
- 可能な限り日本語で応答し、英語の併記は求められた場合のみ行ってください。

# Development workflow defaults

この dotfiles は Claude Code の `claude/skills/` に Superpowers 由来の開発ワークフローを、個別プロジェクト prefix なしの汎用 skill 名で配置しています。Codex では同じ流れをこの AGENTS.md から自然に適用してください。

## Before implementation

- 新機能・複数ファイル変更・仕様が曖昧な依頼では、いきなり実装せず、目的、制約、代替案、非目標を短く確認する。
- 要件が固まったら `writing-plans` 相当で、実装前に小さな手順へ分割する。計画には対象ファイル、テスト、検証コマンド、完了条件を含める。
- 大きい作業は main/master 直作業を避け、`using-git-worktrees` 相当でブランチまたは worktree を使う。

## During implementation

- 可能な限り `test-driven-development` 相当で RED → GREEN → REFACTOR を守る。テストを書かずに実装した場合は、完了前に必ず不足テストを補う。
- 3つ以上の独立した作業がある場合は `dispatching-parallel-agents` / `subagent-driven-development` 相当で、ファイル範囲が重ならない単位に分ける。
- バグ修正では `systematic-debugging` 相当で、症状確認 → 仮説 → 最小再現/ログ → 根本原因 → 修正 → 回帰テストの順に進める。
- 計画書が渡された場合は `executing-plans` 相当で、計画を批判的に読んでから順番に実行する。計画の穴・ブロッカー・危険な指示は実装前に指摘する。

## Before completion

- `verification-before-completion` 相当で、実際にテスト・lint・typecheck・ビルドなど該当する検証を実行してから完了宣言する。実行していない検証は PASS と書かない。
- 変更が大きい時は `requesting-code-review` 相当で、差分を品質・セキュリティ・性能・テスト観点から自己レビューする。
- レビュー指摘を受けたら `receiving-code-review` 相当で、指摘ごとに修正/保留/不採用理由を明確にし、必要な検証を再実行する。
- 作業完了時は `finishing-a-development-branch` 相当で、git status、差分要約、検証結果、未完了事項、次の選択肢（merge/PR/保留）をまとめる。

## Skill naming

- 追加する skill や計画名に個別プロジェクト prefix は付けない。汎用名（例: `writing-plans`, `systematic-debugging`, `verification-before-completion`）を優先する。
- プロジェクト固有ルールはグローバル skill 名ではなく、各リポジトリの AGENTS.md / CLAUDE.md に置く。
