# Large-codebase harness patterns

> Source: Anthropic「How Claude Code works in large codebases: best practices and where to start」
> URL: https://claude.com/blog/how-claude-code-works-in-large-codebases-best-practices-and-where-to-start

大規模codebaseで Claude Code を運用する時の harness 設計指針。dotfilesの harness-engineering SKILL.md 本体は短く保ち、詳細はここに置く。

## 1. CLAUDE.md / AGENTS.md は pointers + critical gotchas only

公式表現の要点:

> The root file should be **pointers and critical gotchas only**; everything else drifts into noise.

> Keep CLAUDE.md files **lean and layered**.

> Load **additively**: root file for the big picture, subdirectory files for local conventions.

### 書くもの
- ビルド・テスト・デプロイの最低限コマンド
- 禁止事項（各項目に ADR / リンタールール参照）
- skill / MCP / hook へのポインタ
- "critical gotcha" 系（誤動作で実害が出る制約）

### 書かないもの
- システムの現状説明文（コードとテストが真実）
- 技術スタック解説（package.json / go.mod を読める）
- 長文のスタイルガイド（リンターに委ねる）

### 行数 / 指示数の目安
- 50行以下が理想
- 150指示超で primacy bias 発動・性能劣化（IFScale 研究）
- Claude Code のシステムプロンプト自体が ~50 指示 → 100 行で計 150 指示 → 限界域

## 2. Stop / Start hook による self-reflection

公式の最重要パターン:

> **A stop hook can reflect on what happened during a session and propose CLAUDE.md updates while the context is fresh.**
> **A start hook can load team-specific context dynamically so every developer gets the right setup for their module without manual configuration.**

### Stop hook の設計原則

| 原則 | 理由 |
|---|---|
| **検出と適用を分離** | 自己 patch は不安定。jsonl 等の artifact に staging し、別セッション / 人間 review で適用 |
| **副作用なし** | 失敗時は exit 0、外部送信なし、append only |
| **grep ベース、LLM 不使用** | コストと latency を抑える。LLM 分析は別セッションに切り出す |
| **検出した signal を構造化保存** | layer (runtime/context/safety) / confidence / evidence を含める |

### Start hook の設計原則

| 原則 | 理由 |
|---|---|
| **module-specific context を動的注入** | 全員のCLAUDE.mdに書くと肥大化する |
| **読み取り専用** | 環境状態を変えない |
| **失敗時は無音** | session 開始を止めない |

## 3. 3-6か月毎の configuration review (剪定サイクル)

公式:

> Teams should expect to do a **meaningful configuration review every three to six months**, but it's also worth doing one **whenever performance feels like it's plateaued after major model releases**.

> Reassess whether **skills and hooks built to compensate for specific model limitations become overhead once those limitations no longer exist**.

### 剪定対象の見つけ方

| 兆候 | 確認 |
|---|---|
| 主要モデル更新後の plateau | 旧モデルの弱点を補う hook が今も必要か |
| 半年以上 不変の skill | trigger description の精度を測り直す (empirical-prompt-tuning) |
| 同じ undertrigger / overtrigger 苦情が続く | description / body を再設計 |
| `MUST/ALWAYS/CRITICAL` が増えた skill | attention 希釈の兆候。トーンを下げる |

### 公式の具体例

> A hook that intercepted file writes to enforce `p4 edit` in a Perforce codebase, for example, became redundant once Claude Code added **native Perforce mode**.

→ 公式ツール追加で外部 hook が不要化するパターンは頻繁に起きる。reading release notes は剪定 trigger になる。

## 4. Hooks の二面性: enforcement と continuous improvement

公式:

> Hooks for both **enforcement ("prevent Claude from doing something wrong")** and **continuous improvement** (= Stop hook で session を反省して CLAUDE.md / skill を改善する).

| 面 | 例 | 失敗時の影響 |
|---|---|---|
| Enforcement | PreToolUse でリンター設定改竄を block / PostToolUse で format 強制 | 即座に作業 block。誤発火コスト高 |
| Continuous improvement | Stop hook で transcript を反省し jsonl に候補追記 | 副作用なし。誤検出は次セッションで人間 review で除外 |

設計上の境界:
- Enforcement hook は **少なく、確実に**
- Continuous improvement hook は **広く、副作用なし**

## 5. Progressive disclosure (skill loading)

公式:

> Skills solve this through **progressive disclosure**, offloading specialized workflows and domain knowledge that would otherwise compete for context space and loading them only when the task calls for it.

- メタデータ (frontmatter description) は常駐 → 発火判定に使う
- 本文は発火時のみ load → context budget を保護
- 長い参考資料は `references/` に分離 → 必要時のみ Read

dotfiles実装ルール:
- SKILL.md body は 200 行以下を目安
- 長文資料・コード例・テンプレートは `references/<topic>.md` へ
- frontmatter description は trigger keyword と「Use ALSO when noticing」句を含める (1024 chars 上限)

## 6. dotfiles における実装マップ

| Anthropic 公式パターン | dotfiles 実装 |
|---|---|
| Stop hook で session 反省 → CLAUDE.md 改善提案 | `claude/hooks/harness-reflection.sh` (Layer B, 実装予定) |
| Start hook で team-specific context 動的注入 | v2。現状は static skill load |
| CLAUDE.md lean rule | `claude/skills/prompt-design`, このreference |
| 3-6か月剪定サイクル | `claude/skills/skill-portfolio-evolution` の Improvement loop に統合 |
| Enforcement hook | 既存 PostToolUse / PreToolUse パターン (`coding-agent/references/harness-engineering.md` 参照) |
| Continuous improvement hook | harness-reflection.sh + skill-portfolio-evolution patch loop |
| Progressive disclosure | 既存 skill 構造に準拠 |

## 7. 既存 dotfiles harness との関係

- `coding-agent/references/harness-engineering.md`: PostToolUse / PreToolUse / Stop hook の **enforcement** 側テンプレート
- 本 reference: Stop hook の **continuous improvement** 側パターン (公式 large-codebase 記事準拠)
- `skill-portfolio-evolution`: 検出された候補を review可能 patch に変換する loop

3つで `enforcement / detection / patch` の3段が揃う。
