---
name: harness-engineering
description: >-
  Design and improve AI-agent harnesses: context loading, routing, verification gates, safety boundaries, skill/tool packaging, monitoring, and feedback loops. Use when improving how Claude Code, Codex CLI, Hermes, or other agents operate across repositories.
---

# Harness Engineering

> "Anytime you find an agent makes a mistake, you take the time to engineer a solution such that the agent never makes that mistake again." — Mitchell Hashimoto
> Muser運用パターン: [references/muser-operating-patterns.md](references/muser-operating-patterns.md)
> DB/CloudWatch系の隠れボトルネック診断: [references/observability-bottleneck-triage.md](references/observability-bottleneck-triage.md)
> 共有ブラウザ/WebBridge導入ポリシー: [references/shared-browser-policy.md](references/shared-browser-policy.md)
> 会社/プロジェクトagent運用4層テンプレ: [references/company-agent-operating-map.md](references/company-agent-operating-map.md)
> モデル/コーディングrouter実験ポリシー: [references/model-routing-experiment-policy.md](references/model-routing-experiment-policy.md)
> Coding-agent公開ソース取り込み: [references/coding-agent-source-ingestion.md](references/coding-agent-source-ingestion.md)

## コア概念

**ハーネスエンジニアリング** = AIエージェントの「環境」を設計して品質・信頼性を上げる技術。

```
coding agent = AI model + harness
```

モデルは所与。ハーネス（環境・設定・ツール・プロンプト・構造）が変数。
「モデルが賢くなれば解決する」は幻想。賢くなれば難しい問題を投げるだけ。

### ハーネスの5つのレバー

| # | レバー | 例 | 効果 |
|---|--------|-----|------|
| 1 | **System Prompt** | AGENTS.md, CLAUDE.md, SKILL.md | 行動指針・制約・知識注入 |
| 2 | **Tools / MCP** | CLI, MCP servers, ファイルI/O | 環境との相互作用能力 |
| 3 | **Context Management** | Compaction, progress files, git history | セッション間の記憶継続 |
| 4 | **Sub-agents** | Generator/Evaluator, context firewall | 役割分離・コンテキスト隔離 |
| 5 | **Hooks / Back-pressure** | Pre-commit checks, 自動テスト, linter | 確定的な品質ゲート |

### 3層で意味を取り違えない

「ハーネス」は文脈によって指す層が違う。設計レビューでは最初にどの層の改善かを明示する。

| 層 | 何を指すか | Muserでの例 |
|---|---|---|
| **Runtime harness** | agent loop / tool execution / retry / queue / state machine | Hermes runtime、browser/terminal tool、scheduler |
| **Context harness** | modelに渡す資料・指示・検索・skill・AGENTS.md | skills、memory、profile routing、handoff artifact |
| **Safety harness** | 権限・承認・監査・外部送信境界 | Rule of Two、outbound guard、security scan、approval gates |

改善案は `runtime / context / safety` のどれに効くか、複数層に跨るならどこがSSOTかまで書く。語の混同で「promptを足せば解決」や「ツールを入れれば安全」のような過剰単純化に落とさない。

### ハーネス ⊂ コンテキストエンジニアリング

ハーネスエンジニアリングは **コンテキストエンジニアリングのサブセット**。
- **コンテキストエンジニアリング:** エージェントのコンテキストウィンドウに「何を・いつ・どう入れるか」の全体設計
- **ハーネスエンジニアリング:** その中でも「ハーネスの設定面（configuration surfaces）」を活用する部分

### サイバネティクスとしてのハーネス

Coding Agentは `prompt → action/tool → observation → next prompt` のフィードバックループで動く。Harness Engineeringは、このループに**負のフィードバック**を意図的に入れて発散を収束させる設計。

- 誤差信号を明示する: test failure、lint、benchmark regression、security finding、review comment、unmet acceptance criteria
- 調節できる変量を分ける: prompt / context / tool permission / evaluator / deterministic gate / task slice size
- Desired stateを artifact に固定する: Definition of Done、eval scenario、progress file、rollback condition
- 発散フェーズと収束フェーズを混ぜない: 生成・探索の後に、別役割または確定的チェックで収束させる

新しいハーネス改善案は「どの誤差信号を増幅/減衰させるのか」「次回同じ失敗をどう検出するのか」まで書く。

### 内部ハーネス / 外部ハーネス

同じ「ハーネス」でも、誰の視点かで意味がズレる。

- **内部ハーネス:** モデルの外側にある実装面。ランタイム、ツール、検索、永続化、評価器、レート制御など、**作り手側** が用意するもの
- **外部ハーネス:** AGENTS.md、SKILL.md、progress file、review gate、承認フロー、artifact handoff みたいな、**使い手側** が品質を安定させるための環境設計

Muser運用で主戦場なのは後者。LLMベンダーの記事を読む時は、
「これはプロダクト内の内部ハーネスの話か、現場で再利用できる外部ハーネスの話か」を先に切り分ける。

### Muserで最初に見る観点
- **Default loop:** Plan → Execute → Evaluate → Learn
- **software workflow ladder:** non-trivial development starts with reference gathering / prior art → thin failing test or acceptance check → smallest implementation → refactor → benchmark/perf check when relevant → security review → coverage/edge-case pass → next action artifact. Do not skip directly from reference gathering to broad refactor.
- **default-FAIL contract:** 長時間agentは「検証不能なら成功扱いにしない」。成功条件・失敗時の停止条件・再開条件を prompt / progress artifact に明示する
- **fresh-context evaluator:** 評価役は実装セッションの会話をそのまま引き継がず、成果物・diff・テスト結果・handoff artifact だけで独立評価する
- **agent-maintained handoff:** 長時間agent自身に `progress / decisions / known failures / next command` を更新させ、次セッションは会話ではなくartifactから再開する
- **eval-before-PRD:** AIプロダクト/LP/QAでは、長いPRDより先に「合格/不合格を判定できる eval scenario」を置く。仕様文は eval を満たすための補助にする
- **quality decision process:** AIプロダクトは出力が分布し運用中にも振る舞いが変わるため、テスト技法だけでなく「主張・証拠・閾値・例外時の決定者」を先に決める。PdM/QA/SRE/事業側で品質会議テンプレを共有し、合否ではなく運用判断の再現性を上げる
- **high-stakes domain boundary:** 金融・給与・法務・決済・署名など「それっぽく動く誤り」が高コストな領域では、AIに中核ロジックを丸投げしない。人間/ドメイン責任者が前提・例外・説明責任を握り、AIは `仕様の言語化補助 / 境界値・異常系の洗い出し / レビュー観点の追加 / 周辺UIやデモの高速化` に寄せる
- **failure-log → harness fix:** 失敗を「次は気をつける」で終えず、失敗ログから原因を `instruction / tool / context / evaluator / deterministic gate` に分類し、再発防止を AGENTS.md / skill / hook / template のどれかへ最小反映する
- **maintenance ROI gate:** AI導入で生成速度だけ上がっても、保守コストが下がらないと数か月で逆効果になる。新しい agent / skill / codegen 導線を入れる時は `速度向上 × 保守コスト削減` で見て、保守削減に効く evidence（テスト、owner、handoff、削除基準、障害時の戻し方）がないものは常設化しない
- **sandbox / permission split:** 外部入力・未検証コード・ブラウザ操作・公開送信を同じ agent chain に詰め込まない。scan / stage / verify / publish を分け、公開・秘密・破壊的操作は境界ツールか人間承認に寄せる
- **benchmark corpus before rule:** 公開AI運用事例やClaude Codeログは、常設ルール化の前に scenario / hold-out / onboarding corpus に変換し、実測で効くものだけ standing rule に昇格する
- **trace-based skill improvement:** skill / AGENTS.md / prompt を自己評価だけで書き換えない。失敗ログ・実行trace・golden/hold-out scenarioを先に集め、別評価器またはGEPA等のoffline optimizerで候補差分を比較し、best variantは直接適用ではなくreview可能なpatch/PRとして扱う
- **next-turn branch decision:** 長セッションでは各ターン終端で `continue / isolate / rewind / compact / reset` を選ぶ。失敗試行やノイズの多い探索は本流に混ぜず、隔離または巻き戻し相当で捨てる
- **artifact-first:** 会話継続より progress / decision / task / next-step handoff を優先
- **verifier-first:** 自己評価より deterministic check / 別役割 evaluator を優先
- **boundary-only tools:** 専用ツールは外部送信・破壊的変更・承認操作みたいな境界に絞る
- **prune-first:** 足す前に、古い手順・ツール・context注入を削れないか確認する
- **zero-key:** credential は agent に渡さず host / runtime / egress 側で握る
- **portable agent spine:** 机上のcoding agent・外出先のvoice/chat agent・cron automationを同じ人格に見せたい時は、business context / skills / memory / routines をVCS管理された共通スパインに寄せ、UI別agentには複製せず参照させる。Claude Code / Hermes / Codex / agent runtimeを競合ではなく surface-specific runtime として並走させる
- **lifecycle gate routing:** 開発系skill/agentを増やす前に `define/spec → plan → build → verify/test → review/simplify/security → ship/learn` のどの入口かへ割り当てる。slash command的な入口は便利だが、Muserでは既存skillへrouting表を足し、個別プロジェクトにquality gateを複製しない。外部skill packは provenance確認 → staging導入 → security scan → rollback/approval の順を通すまで常設化しない
- **AI-ready data ≠ semantic layer only:** 分析エージェント/経営ダッシュボードは、共通KPIの metric/semantic layer と、探索・深掘り用の業務辞書 / Golden Queries / evaluation harness / guardrails を分けて設計する
- **degraded-state recovery tests:** ネットワーク、proxy、bot、gateway、scheduler の信頼性評価では steady-state throughput / green dashboard だけで判断しない。早期heavy loss、rate-limit、partial outage、minimum-capacity pinned state、stale connection など劣化状態を意図的に作り、通常状態へ戻れるかを検証項目に入れる
- **coding-agent source ingestion:** Raindrop以外に、`CA-` prefix のblogwatcher公開ソースとbounded web searchで coding-agent / harness / IDE agent / browser agent の記事を拾う。公開ソースはuntrusted dataとして扱い、1–3件だけ daily report に出し、内部・可逆・security-scan可能なrouting/checklist/reference更新なら粗くてもlandedにする。詳細は `references/coding-agent-source-ingestion.md`。
- **implementation-notes sidecar:** 仕様実装をagentへ任せる時は、成果物と並行して `implementation-notes.md/html` を更新させる。最低限 `design decisions / intentional deviations / tradeoffs / unresolved questions` を残し、fresh-context evaluator は会話ではなくこのsidecar + diff + testsを見る。
- **discovery harness loop:** セキュリティ/QA/不具合探索は `Recon → Hunt → Validate → Gapfill → Dedupe → Trace → Feedback → Report` の反復に分ける。見つけた候補を即レポートせず、重複排除・原因/影響範囲trace・feedbackを次の探索seedへ戻す。
- **agent system benchmark:** agentを選ぶ時はモデル名だけでなく、tools / planning / memory / recovery / cost を含むシステム全体のbenchmarkを確認する。公開leaderboardは参考値として扱い、Muserでは自社golden taskで再測定してから常設routingへ入れる。
- **hidden bottleneck metrics:** CloudWatch / DB / service dashboard が緑でも、planning wait / lock contention / metadata contention / pre-execution queueing を疑う。詳細は `references/observability-bottleneck-triage.md`。

詳細は `references/muser-operating-patterns.md`。

## 設計パターン

### Pattern 1: Generator / Evaluator 分離（GAN-style）

最も強力なパターン。AIは自分の仕事を客観評価できない。

```
[Generator] → 成果物 → [Evaluator] → フィードバック → [Generator] → ...
```

**なぜ分離するか:**
- 単一エージェントは自己評価が甘い（常に高得点をつける）
- 別エージェントを「懐疑的に」チューニングする方が、Generatorを自己批判的にするより簡単
- Evaluatorのフィードバックが具体的な改善入力になる

**評価基準の設計:**
- 主観的タスク（デザイン等）→ 重み付きルーブリック（4観点: Quality, Originality, Craft, Function）
- 客観的タスク（コード等）→ テスト + linter + 型チェック
- **重要:** ルーブリックでは「何を重視するか」で出力傾向が変わる（Originality重視 → AIっぽさ脱却）

**Muserでの適用:**
- `dual-agent-dev`: Claude Code（Generator）+ Codex（Evaluator/Reviewer）
- `agent-teams-dev`: 複数Generator + Codex横断レビュー
- `code-review`: 3観点並列レビュー

### Pattern 1.5: AI Product Quality Decision Template

AIプロダクト/agent機能/LLM出力を含むLP・QAでは、テストケース一覧だけで品質判断しない。最小テンプレ:

| 項目 | 書くこと |
|---|---|
| Quality claim | 何が十分に良いと言いたいか |
| Evidence | eval結果、ログ、ユーザー観察、失敗例、再現手順 |
| Threshold | ship / watch / rollback / block の境界 |
| Distribution risk | 出力ぶれ、モデル更新、入力分布変化、長尾ケース |
| Owner | PdM / QA / SRE / Biz の誰が例外判断するか |
| Feedback loop | 失敗をどのskill / issue / hook / evalへ戻すか |

このテンプレはPRDの前または同時に作り、QAを「チェックリスト消化」ではなく「意思決定プロセス」にする。

### Pattern 2: Initializer / Coder 分離（Long-running）

長時間タスクの構造。初回と継続でプロンプトを変える。

```
[Initializer] → 環境セットアップ + Feature List + init.sh
    ↓
[Coder Session 1] → 1機能実装 → git commit + progress更新
    ↓
[Coder Session 2] → 次の機能 → git commit + progress更新
    ↓ ...
```

**Initializerの仕事:**
1. Feature list作成（JSON推奨。Markdownより改変されにくい）
2. `init.sh` スクリプト生成（開発サーバー起動 + E2Eテスト）
3. 初回git commit（ベースライン）
4. `progress.txt` 作成（次セッションへの引き継ぎ）

**Coderの仕事:**
1. progress.txt + git history で現状把握
2. **1機能だけ** 実装（one-shot禁止）
3. git commit（descriptive message）
4. progress.txt 更新
5. 環境をクリーンな状態で終了

**失敗パターンと対策:**
| 失敗 | 原因 | 対策 |
|------|------|------|
| 一気にやろうとする | 明示的に制約がない | 「1機能ずつ」を強制プロンプト |
| 途中で完了宣言 | 進捗が見えて満足 | Feature listのpasses: falseで残タスク可視化 |
| コンテキスト不安 | ウィンドウ枯渇への焦り | Context reset（compactionではなく完全リセット） |

### Pattern 3: Planner / Generator / Evaluator（3-agent）

大規模アプリ向け。Plannerが全体設計、Generator/Evaluatorがスプリント実行。

```
[Planner] → Product Spec（what/why、howは書かない）
    ↓
[Generator] ←→ [Evaluator]（スプリント単位でループ）
```

- Plannerは1-4文のプロンプトから200+の機能仕様を展開
- Generator/Evaluatorは「スプリント契約」を結んでからコード開始
- 単一エージェント: 20分/$9 → 3-agent: 6時間/$200 で品質は次元が違う

### Pattern 4: Sub-agents as Context Firewall

サブエージェント = コンテキストの防火壁。

```
[Orchestrator]（コンテキスト: 全体計画のみ）
    ├── [Sub-agent A]（コンテキスト: タスクAの詳細のみ）
    ├── [Sub-agent B]（コンテキスト: タスクBの詳細のみ）
    └── [Sub-agent C]（コンテキスト: タスクCの詳細のみ）
```

**なぜ重要:**
- 各サブタスクの中間ノイズがOrchestratorに蓄積しない
- Orchestratorは長期間一貫性を維持できる
- 失敗したサブエージェントだけリトライ可能

**Muserでの適用:**
- `sessions_spawn` でサブエージェント起動
- `agent-teams-dev` の並列チームメイト構成

### Pattern 5: AI-Ready Data Harness

分析自動化エージェントでは、セマンティックレイヤーだけをSSOT化しても深掘り分析は安定しない。目的別に層を分ける。

| 層 | 役割 | 例 |
|---|---|---|
| Base tables | 事実データの整備 | raw → clean → gold、粒度・期間・join key |
| Metric / semantic layer | 組織横断KPIの共通定義 | ARR、CVR、active user、粗利 |
| Business context | 探索・深掘りの文脈 | 業務辞書、禁則、セグメント定義、施策履歴 |
| Golden Queries | 正解例・比較基準 | 月次KPI、ファネル、cohort、営業進捗 |
| Evaluation harness | 回答品質の継続評価 | SQL正確性、粒度一致、漏洩/誤集計検知 |
| Guardrails | 安全境界 | PII、権限、費用上限、外部送信禁止 |

**設計ルール:**
- 組織の定例KPIは metric/semantic layer に寄せる
- 「なぜ下がったか」「どのセグメントか」など探索系は business context + Golden Queries + evaluator で支える
- the product / DeFi / GTM / 経営ダッシュボードでは、最初のPRDに「共通定義」と「探索用ハーネス」を別見出しで置く

## コンテキストウィンドウ管理

### Instruction Budget

ツール定義・システムプロンプト・スキルが全てcontextを消費する。

```
[System Prompt] + [Tool Descriptions] + [Skills] + [Conversation] = Context Window
```

- MCPツールを増やすほど、ツール説明がcontextを圧迫（「dumb zone」に入る）
- **Progressive Disclosure:** 全スキルのメタデータは常駐、本文は発火時のみロード
- 不要なツール/スキルは外す。「あると便利かも」は害

### Next-turn branch: Continue / Isolate / Rewind / Compact / Reset

長セッションは「続ける」だけでなく、次の1ターンをどう扱うかを毎回選ぶ。

| 分岐 | 使う場面 | 具体アクション |
|---|---|---|
| Continue | 方針が明確でノイズが少ない | そのまま次の小ステップへ |
| Isolate | 大量ログ・比較調査・中間出力が必要 | サブエージェント/別プロセスに隔離し、要約だけ戻す |
| Rewind | 試行が失敗し、以後の文脈を汚す | diff / git / artifact で失敗前に戻し、失敗理由だけ記録 |
| Compact | 残すべき意思決定があり、まだ品質劣化前 | 方向性・未完了・禁止事項を明示して圧縮 |
| Reset | 新タスク化・品質低下・context rot | progress artifact + git history から新セッション再開 |

**目安:** context rot が見え始めてから compact するのではなく、判断余裕があるうちに「次に読むべき artifact / 次コマンド / 捨てる試行」を残す。
- `Compact`: まだ方針は正しいが、会話が長くなり「何を残すか」を選べる時
- `Reset`: 新しい目的に切り替わった時、失敗試行が多くて判断が濁った時、または artifact + git history だけで再開できる時

### Compaction vs Context Reset

| | Compaction | Context Reset |
|---|-----------|---------------|
| 方式 | 会話履歴を要約して圧縮 | ウィンドウを完全クリア + 構造化ハンドオフ |
| 利点 | 連続性維持、シンプル | クリーンスレート、不安解消 |
| 欠点 | context anxiety残存 | オーケストレーション複雑、レイテンシ |
| 使い分け | 短〜中タスク | 長時間タスク、品質低下時 |

### Progress File設計

セッション間の記憶を繋ぐ最重要アーティファクト。

```json
{
  "current_sprint": "Authentication",
  "completed_features": ["User signup", "Login form"],
  "next_steps": ["Password reset flow", "OAuth integration"],
  "known_issues": ["CSS grid alignment on mobile"],
  "tech_decisions": {
    "auth": "JWT with httpOnly cookies",
    "db": "PostgreSQL with Drizzle ORM"
  }
}
```

- **JSON推奨:** Markdownより改変されにくい（Feature listも同様）
- **git history併用:** progress fileが壊れてもgit logで復元可能
- **artifact remoteも検討:** セッションやsandboxが短命なら、progress fileだけでなく Git-compatible remote / per-session repo / fork URL を handoff artifact に含める。会話より clone 可能な状態を渡す方が強い

## ハーネス診断チェックリスト

エージェント品質が安定しない時、このチェックリストで診断する。

### 1. Instruction層
- [ ] AGENTS.md / CLAUDE.md は簡潔か（不要な情報を削除）
- [ ] 矛盾する指示がないか
- [ ] 「MUST/ALWAYS/CRITICAL」の過剰使用がないか（attention希釈）
- [ ] NOT forの境界が明確か

### 2. Tool層
- [ ] 使ってないMCPサーバー/ツールが残ってないか
- [ ] ツール説明がcontextを圧迫してないか
- [ ] 同じ機能のツールが重複してないか

### 3. Context層
- [ ] compactionで品質が落ちてないか → context resetを検討
- [ ] progress file / git commitで状態引き継ぎできてるか
- [ ] サブエージェントでcontext隔離できてるか

### 4. Evaluation層
- [ ] 自己評価に頼ってないか → Generator/Evaluator分離を検討
- [ ] 評価基準が具体的か（「良いコード」ではなく「テスト通過 + lintクリア + 型安全」）
- [ ] フィードバックループが回ってるか
- [ ] 本番系の品質指標を置いているか（例: keep rate、unknown tool error rate、tool/model別 baseline からの異常検知）
- [ ] 劣化を backlog / issue に戻す自動回収導線があるか（週次ログ監査・エラーログ分類など）

### 5. Determinism層
- [ ] 確定的にチェックできることをLLMに任せてないか
- [ ] hooks / pre-commit / linter / formatter が設定されてるか
- [ ] テストが自動実行されてるか

## Muser環境での適用マップ

| Muserスキル/機能 | ハーネスパターン | 役割 |
|---|---|---|
| `AGENTS.md` | Instruction層 | 全セッションの行動指針 |
| `SOUL.md` / `USER.md` | Instruction層 | ペルソナ・ユーザーコンテキスト |
| `coding-agent` | Initializer/Coder | ワンショット実装 |
| `dual-agent-dev` | Generator/Evaluator | Claude Code + Codexレビュー |
| `agent-teams-dev` | Sub-agents + Evaluator | 並列開発 + 横断レビュー |
| `lessons-gate` | Learn gate | ミス再発防止の確定的ゲート |
| `code-review` | Evaluator | 3観点並列レビュー |
| `prompt-design` | Instruction層 | プロンプト品質チェックリスト |
| `sessions_spawn` | Sub-agents | コンテキスト隔離 |
| `compaction-save` hook | Context Management | compaction時の状態保存 |
| `memory/` | Context Management | セッション間記憶 |

### Lifecycle gate map

外部の production-grade skill pack / slash command 体系を読む時は、導入前にこの対応へ畳む。

| Gate | Muserでの主な受け皿 | 合格条件 |
|---|---|---|
| Define / Spec | `prompt-design`, `harness-engineering`, project brief | what/why、制約、成功条件が明示されている |
| Plan | `coding-agent`, `dual-agent-dev`, `agent-teams-dev` | 小さく検証可能な単位に分かれている |
| Build | `coding-agent` / project-specific ops | 1 sliceずつ実装し、handoffが残る |
| Verify / Test | deterministic checks, browser QA, fresh-context evaluator | テスト・lint・typecheck・UI QA等の証拠がある |
| Review / Simplify / Security | `code-review`, `skill-creator` security audit, security policy | merge/常設化前に別視点・安全境界を通す |
| Ship / Learn | release checklist, `lessons-gate`, bookmark self-improvement | rollback/monitoring/学習の戻し先がある |

## 参考文献

詳細は `references/sources.md` を参照。

- Anthropic「Effective harnesses for long-running agents」
- Anthropic「Harness design for long-running application development」（GAN-style）
- HumanLayer「Skill Issue: Harness Engineering for Coding Agents」
- Viv Trivedy「Harness as a Service」「Anatomy of an Agent Harness」
- Mitchell Hashimoto「My AI Adoption Journey — Step 5: Engineer the Harness」
- Claude 4 Prompting Guide: Multi-context window workflows
- OpenAI「Harness Engineering」blog post
