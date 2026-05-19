---
name: prompt-design
description: >-
  Design and review long agent-facing prompts such as AGENTS.md, CLAUDE.md, SKILL.md, subagent tasks, system prompts, and cron prompts. Use when writing or improving instructions for Claude Code, Codex CLI, or other coding agents. Use ALSO when noticing: CLAUDE.md/AGENTS.md/SKILL.md が 200行 or 150指示 を超えている, 矛盾指示や MUST/ALWAYS/CRITICAL の過剰使用で primacy bias / attention希釈 が起きそう, 「現在のシステムはこう」型の説明文がコードと乖離している, モデル更新後に旧モデル向け制約が残っている時. Proactively propose 剪定 / 再構成 / pointer 化 even if user did not explicitly ask.
---

# Prompt Design — エージェント向けプロンプト設計スキル

Claude公式ベストプラクティス（Opus 4.6 / Sonnet 4.5対応）を
チェックリストとパターン集に凝縮。

> Source: https://platform.claude.com/docs/ja/build-with-claude/prompt-engineering/

---

## 📋 チェックリスト

### 必須（全プロンプト共通）

- [ ] **明確で具体的か？** — 「いい感じに」ではなく具体的な指示
- [ ] **なぜそうするか（動機）を書いたか？** — Claudeは動機から一般化できる
- [ ] **例が意図と一致しているか？** — 促進したい動作のみ
- [ ] **「何をするか」で書いたか？** — 否定形より肯定形
- [ ] **アクション指示は明示的か？** — 「提案してもらえますか」→「実装してください」

### エージェント/長時間タスク向け

- [ ] **コンテキスト継続指示があるか？** — 圧縮環境での早期停止防止
- [ ] **状態管理の指示があるか？** — JSON + テキストメモ + git追跡
- [ ] **検証手段を提供したか？** — テスト、Playwright、チェックコマンド
- [ ] **インクリメンタル進捗指示があるか？** — 少しずつ着実に
- [ ] **長セッションのGoalアンカーがあるか？** — 冒頭で「今回の最終状態」を1–3行で固定し、ドリフト時に戻れる北極星を置く

### 安全性・自律性

- [ ] **破壊的アクションの確認指示？** — Opus 4.6は無ガイドでforce pushする
- [ ] **サブエージェント使用ガイドライン？** — Opus 4.6は過剰にサブエージェント使う

### Opus 4.6 固有

- [ ] **過激な言語を控えめに？** — ×「CRITICAL: MUST」→ ○「Use when...」
- [ ] **過度な探索を制御？** — 「1つ選んで最後まで進め」
- [ ] **並列ツール呼び出しを明示？** — 独立呼び出しは並列指示

---

## 🧱 パターン集

→ 詳細: [references/patterns.md](references/patterns.md)

| # | パターン | 用途 |
|---|---------|------|
| 1 | コンテキスト継続 | 長時間タスク必須 |
| 2 | アクション志向 | 「提案」止まり防止 |
| 3 | 安全ガードレール | 破壊的操作の制御 |
| 4 | 思考の効率化 | 過度な探索を防ぐ |
| 5 | マルチウィンドウ | 大規模タスク |
| 6 | 調査・リサーチ | 構造化された探索 |
| 7 | サブエージェント制御 | 過剰委任の防止 |
| 8 | 並列ツール呼び出し | 効率最適化 |
| 9 | 進捗報告 | 完了時の要約 |
| 10 | 一時ファイルクリーンアップ | 後片付け |
| 11 | Goalアンカー | 長セッションのドリフト防止 |

---

## 📦 Progressive Disclosure最適化

SKILL.md構造の最適化パターン（トークン40-45%削減）。
→ 詳細: [references/progressive-disclosure.md](references/progressive-disclosure.md)

---

## 🔧 使い方

| シーン | やること |
|--------|---------|
| 新しいプロンプトを書く | パターン集からコピペ → チェックリストで確認 |
| 既存プロンプトをレビュー | チェックリストを上から確認 → パターン追加 |
| sessions_spawn タスク設計 | 長時間→P1, 実装→P2, リサーチ→P6, 並列→P7+P8 |
| SKILL.md を書く | 「なぜそうするか」の動機を必ず書く |

---

## 📚 元ソース
- https://platform.claude.com/docs/ja/build-with-claude/prompt-engineering/claude-prompting-best-practices
- 最終同期: 2026-03-04

## 振り返り
- 初回作成: 2026-03-04
- 2026-03-16: Progressive Disclosure適用。本体255→90行。パターン集・詳細をreferences/に分離
