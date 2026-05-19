# Proactive Harness Suggestion Design

**Date:** 2026-05-19
**Status:** Approved for implementation planning
**Scope:** Make `harness-engineering` / `skill-portfolio-evolution` / `coding-agent` 等の harness 系 skill が、Claude Code / Codex の通常作業中に harness 化候補を自発的に提案し、検出ログから review 可能な patch を生成して dotfiles に反映できる状態にする。

---

## 1. 背景と問題

現状の `claude/skills/harness-engineering/SKILL.md` および `claude/skills/skill-portfolio-evolution/SKILL.md` は内容が濃いものの、構造が **「ユーザーが明示的に harness 設計を依頼した時の参考書」** になっており、通常作業中に「こういう harness を組めば自動化できる」という提案が自然発火しない。

ユーザー要望: Claude/Codex を使っている時に **自然に「これ harness 化したら効率いいですよ」** と提案され、合意できた改善は dotfiles に反映されていく状態を作る。

## 2. 設計原則（Anthropic 公式準拠）

| 出典 | 採用する原則 |
|---|---|
| [skill-creator (anthropics/skills)](https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md) | Claude は skill を **undertrigger** する傾向がある → description は "pushy" に。`Use ALSO when noticing X, Y, Z, even if user doesn't explicitly ask`。description は 1024 chars 上限。 |
| [How Claude Code works in large codebases](https://claude.com/blog/how-claude-code-works-in-large-codebases-best-practices-and-where-to-start) | **「Stop hook can reflect on what happened during a session and propose CLAUDE.md updates while the context is fresh.」** Start hook は team-specific context を動的注入。CLAUDE.md は **pointers + critical gotchas only**。**3-6か月毎に configuration review** し、モデル進化で不要になった hook/skill は剪定する。 |
| [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) | 引き継ぎは progress file + git history + JSON status file による **artifact-first**。会話継続より artifact を優先。 |
| [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps) | Generator / Evaluator 分離。自己評価より別役割評価が強い。 |

設計上の派生原則:

- **検出と適用を分離**: Stop hook は検出と記録だけ。skill-portfolio-evolution が review 可能 patch を生成。patch の適用は人間 review を必須にする（Anthropic「trace-based skill improvement は直接適用ではなく review 可能な patch/PR」原則）。
- **副作用なし優先**: hook は jsonl 追記のみ。skill 本体改修は別レイヤー。
- **prune-first**: 提案は「追加」だけでなく「削除候補」も同形式で扱う。

## 3. アーキテクチャ

```
[通常会話 (Claude Code / Codex)]
    │
    │  Layer A: pushy description が会話パターンに反応 → skill が自発invoke
    │           → 会話内でその場で提案
    │
    ▼
[Stop hook (Layer B)]
    │
    │  transcript を最小スキャンしてサインを検出
    │  → ~/.claude/state/harness-opportunities.jsonl に1行追記
    │
    ▼
[次回 skill-portfolio-evolution 起動 (Layer C)]
    │
    │  jsonl を inventory ソースとして取り込み
    │  → 候補を 5レバー (instruction/tool/context/sub-agent/hook) に分類
    │  → diff patch を生成し claude/skills/.../SKILL.md.patch に保存
    │  → review 用に PR 提案 or 手動 apply 用 patch
    │
    ▼
[人間 review → apply → commit]
    │
    ▼
[harness-engineering SKILL.md (Layer D) が剪定サイクル/CLAUDE.md lean rule を保証]
    │
    ▼
[codex/AGENTS.md (Layer E) が Codex 側でも同等の自己 review を実行]
```

## 4. レイヤー別仕様

### Layer A: SKILL.md description の "pushy" 化

#### A-1. 対象 skill

| Skill | 改修理由 |
|---|---|
| `harness-engineering` | 本体。自発発火が最重要。 |
| `skill-portfolio-evolution` | 候補ログを inventory に取り込む発火点。 |
| `coding-agent` | 反復タスク検出時に harness 化提案を促す。 |
| `prompt-design` | 長すぎる instruction の検出と剪定提案。 |
| `dispatching-parallel-agents` | sub-agent に切り出せそうな反復タスクの検出。 |

#### A-2. テンプレート（公式 skill-creator パターン）

```yaml
description: |
  [What the skill does in 1 sentence].
  Use ALSO when noticing during normal work:
  - <trigger 1: 観察可能な signal>
  - <trigger 2: 観察可能な signal>
  - <trigger 3: 観察可能な signal>
  Proactively propose a harness improvement even if the user did not explicitly ask.
```

#### A-3. `harness-engineering` の新 description（案）

```yaml
description: |
  Design and improve AI-agent harnesses: context loading, routing, verification gates,
  safety boundaries, skill/tool packaging, monitoring, feedback loops.
  Use ALSO when noticing during normal work:
  - user repeats the same Bash command or 手作業 2回以上
  - チェックリストや「次回も気をつける」「忘れないように」が会話に現れる
  - file 編集後に lint/typecheck/test が走っていない
  - cron / scheduled / recurring / 毎回 keywords が出る
  - sub-agent に切り出せそうな反復タスク
  - progress file / handoff artifact なしで長時間タスクが進んでいる
  Proactively propose a harness improvement (runtime/context/safety layer 明示) even if user did not explicitly ask.
```

1024 chars 上限を意識して短縮。日本語混在でもトリガーとして機能する（既存 description も日英混在）。

#### A-4. 他 skill の trigger 行（要点だけ）

- `skill-portfolio-evolution`: "Use ALSO when ~/.claude/state/harness-opportunities.jsonl に新規エントリがある, または 3-6か月以上 audit していない skill がある"
- `coding-agent`: "Use ALSO when 同じ修正パターンを別ファイルで繰り返している, テスト/lint なしで PR を出そうとしている"
- `prompt-design`: "Use ALSO when CLAUDE.md/AGENTS.md/SKILL.md が 150 指示超 or 200 行超, 矛盾指示や MUST/CRITICAL の過剰使用がある"
- `dispatching-parallel-agents`: "Use ALSO when 3つ以上の独立な調査/実装タスクが直列で進行している"

### Layer B: Stop hook で harness opportunity を検出

#### B-1. ファイル配置

```
claude/hooks/harness-reflection.sh        # 検出ロジック
claude/hooks/lib/harness-signals.sh       # サイン検出関数群（共有）
.claude/settings.json                     # Stop hook 登録（user-level）
```

`.claude/settings.local.json` ではなく `.claude/settings.json` に置く。dotfiles で portable に保つ。

#### B-2. 検出サイン（v1）

| サイン名 | 検出方法 | 提案カテゴリ | layer |
|---|---|---|---|
| `bash_repeat_3x` | 同じ Bash command が3回以上 | bash alias / make target / Stop hook | runtime |
| `edit_without_lint` | Write/Edit 後に lint/test 実行なし | PostToolUse hook 追加 | runtime |
| `manual_checklist` | "次回" "忘れないように" "気をつける" などの自然言語 | progress file or skill 化 | context |
| `unverified_completion` | Stop 直前にテスト/lint/typecheck の実行 trace なし | Stop hook で完了条件強制 | runtime |
| `long_session_no_progress_file` | session 長 + progress/decision artifact 更新なし | progress file テンプレ導入 | context |
| `recurring_keyword` | "cron" "scheduled" "毎日" "毎週" keyword | scheduled agent 化候補 | runtime |
| `instruction_bloat` | CLAUDE.md / AGENTS.md が 200 行超 or 150 指示超 | prompt-design で剪定 | context |

検出は transcript の最小スキャン（grep + 行数カウント）に留める。LLM call は使わない。

#### B-3. 出力スキーマ

`~/.claude/state/harness-opportunities.jsonl`:

```json
{
  "ts": "2026-05-19T13:00:00Z",
  "project": "muser",
  "cwd": "/Users/yuki/Development/muser",
  "signal": "bash_repeat_3x",
  "evidence": "npm run build (3 times)",
  "candidate": "alias or PostToolUse hook for npm run build",
  "layer": "runtime",
  "confidence": "medium"
}
```

副作用は **append only**。既存エントリへの mutate なし。

#### B-4. 失敗時の挙動

- スクリプト失敗時は `exit 0`（セッション終了を止めない）
- jsonl 書き込み権限なしの場合は無音で skip
- transcript 取得方法: Claude Code Stop hook は `$CLAUDE_TRANSCRIPT_PATH` 環境変数で transcript を提供（実装時に再確認）

### Layer C: skill-portfolio-evolution が候補を patch に変換

#### C-1. SKILL.md の改修点

`claude/skills/skill-portfolio-evolution/SKILL.md` の `## Source priority` に追記:

```markdown
0. **Harness opportunity log**: `~/.claude/state/harness-opportunities.jsonl` を最優先で確認。
   過去 N 日 (default: 7) の新規エントリを confidence 順に最大 5 件まで処理する。
```

`## Improvement loop` を以下に拡張:

```markdown
1. **Inventory**: 既存 skill 変更 + harness-opportunities.jsonl 新規エントリ
2. **Classify**: 各候補を 5レバー (instruction / tool / context / sub-agent / hook) に分類
3. **Locate target**: 既存 skill / hook / AGENTS.md / CLAUDE.md のどこに反映すべきか決定
4. **Generate diff**: 反映する場合は SKILL.md.patch / hook 追加 / settings.json patch を生成
   - 直接適用しない。`claude/skills/<target>/SKILL.md.patch` または `claude/_proposed/` に置く
5. **Review gate**: Codex または別 Claude Code セッションで diff を review
6. **Apply by human**: 人間が apply してから git commit
```

#### C-2. 自動 patch の自動化境界

提案された Layer A / B / D の **どの変更を自動 patch にして良いか**:

| 変更種別 | 自動 patch 化 | 理由 |
|---|---|---|
| description の trigger 行追加 | OK（diff として提案） | review コスト低、安全 |
| SKILL.md 本文への新セクション追加 | OK（diff として提案） | review 必須だが明示的 |
| 新規 hook 追加 (`.claude/settings.json`) | **手動のみ** | 副作用大、ユーザー承認必須 |
| 既存 skill の削除/大幅書き換え | **手動のみ** | 破壊的 |
| 古い hook / skill の剪定提案 | OK（提案のみ、削除実行は手動） | prune-first 原則 |

### Layer D: harness-engineering SKILL.md 本体の補強

#### D-1. 追加セクション

`### Stop / Start hook による self-reflection`:

> Anthropic 公式: **「A stop hook can reflect on what happened during a session and propose CLAUDE.md updates while the context is fresh.」** 失敗ログから AGENTS.md / skill を更新する `failure-log → harness fix` パターンの実装版。本 dotfiles では `claude/hooks/harness-reflection.sh` が該当。検出 → jsonl 追記 → 次回 `skill-portfolio-evolution` で review 可能 patch 化、の3段。

`### Maintenance ROI と剪定サイクル`:

> Anthropic 公式: 3-6か月毎に configuration review を実施し、モデル進化で不要になった hook/skill を削除する。例: Perforce 用 file write 介入 hook は Claude Code の native Perforce mode 追加で不要に。**`prune-first`**: 追加前に削除候補を確認する。

`### CLAUDE.md / AGENTS.md lean rule（強化）`:

> root file は **pointers + critical gotchas only**。長文説明は subdirectory CLAUDE.md or skill に退避。200 行 / 150 指示を超えたら剪定対象。primacy bias で attention が希釈される。

#### D-2. references 追加

```
claude/skills/harness-engineering/references/large-codebase-harness-patterns.md
```

内容: Anthropic 公式記事 (large codebase blog) の要点 + Stop/Start hook 設計 + 剪定サイクル運用テンプレ。

### Layer E: Codex parity

`codex/AGENTS.md` に追記:

```markdown
## Session-end self-review

Codex は PostToolUse hook を持たないため、セッション終了前に自己 review を行う。
最後の応答の前に、当該セッションで以下があれば 1-3 個列挙する:
- 同じ作業を 2 回以上繰り返した箇所 → harness 化候補
- 「次回も気をつける」「忘れないように」と発言した箇所 → progress file / skill 化候補
- lint / test なしで完了宣言しそうな箇所 → 確定的ゲート化候補

列挙先: `~/.claude/state/harness-opportunities.jsonl` に手動 append、
または会話末尾に「Harness opportunity:」セクションとして出力。
```

Codex 側は人間が直接 jsonl に書き込むか、Claude Code 側 Stop hook で Codex セッションも拾える仕組みは v2 に回す。

## 5. 実装順序（dependency 順）

| # | Layer | 内容 | 安全性 | 検証方法 |
|---|---|---|---|---|
| 1 | A | description pushy 化（5 skill） | 高（description 編集のみ） | 別 Claude Code セッションで該当 trigger 発火を実測 |
| 2 | D | harness-engineering 本体補強 + references 追加 | 高（文書追加のみ） | skill load 確認 |
| 3 | C | skill-portfolio-evolution の Inventory loop 改修 | 中（運用ルール変更） | dry-run で jsonl 読み込み確認 |
| 4 | B | Stop hook + jsonl 出力 | **要レビュー**（hook 副作用あり） | settings.local.json で先行検証 → 問題なければ settings.json へ昇格 |
| 5 | E | codex/AGENTS.md 追記 | 高（文書追加のみ） | Codex 1セッションで自己 review 出力を確認 |

## 6. 検証 (empirical-prompt-tuning 適用)

A 層は trigger description の効果測定が必要。`empirical-prompt-tuning` skill を使って:

1. **Golden scenarios**: trigger すべき会話 5 + trigger すべきでない会話 5 を作る
2. **Blank executor** で description before/after を比較
3. Recall (true positive) / Precision (no false trigger) を確認
4. False trigger 多発時は trigger 句を絞る

## 7. 想定リスクと緩和

| リスク | 緩和 |
|---|---|
| pushy description で別 skill のトラフィックを奪う | A-2 テンプレで「Use ALSO」と明示し、既存 description は残す。empirical-prompt-tuning で precision 測定 |
| Stop hook が transcript を外部に漏らす | hook script は jsonl 追記のみ。外部送信なし。`zero-key` 原則 |
| jsonl 肥大化 | rotation スクリプト（最古 N 日分を別ファイルへ）を v2 で追加 |
| 自動 patch が破壊的変更を含む | C-2 表で「自動 OK」と「手動のみ」を明示。新規 hook / 削除は手動限定 |
| Codex 側で同じ仕組みが取れない | Layer E で自己 review を文書化。完全 parity は v2 |
| モデル進化で trigger 句が古くなる | Layer D の 3-6か月剪定サイクルで再評価 |

## 8. 非対象（YAGNI）

- 自動 PR 作成（GitHub API 経由）: v2
- jsonl の web UI: v2
- 検出時に Slack 通知: v2
- LLM ベースの transcript 分析: 副作用とコストが上がる、v1 では grep ベースに留める

## 9. 成功条件

1. 新規 Claude Code セッションで harness 化候補会話を 5 件流し、最低 3 件で skill が自発 invoke される
2. Stop hook が問題なく `~/.claude/state/harness-opportunities.jsonl` に追記する
3. `skill-portfolio-evolution` 起動時に jsonl エントリが inventory として処理され、review 可能 diff patch が生成される
4. `harness-engineering` SKILL.md 本体行数が現状（~370行）から大きく増えない（references へ退避）
5. Codex セッションでも session-end self-review が機能する

## 10. 次ステップ

- `superpowers:writing-plans` で実装プランへ展開
- 実装プラン承認後、worktree で順次実装
- 各 layer 完了時に empirical-prompt-tuning で trigger 精度を測定
