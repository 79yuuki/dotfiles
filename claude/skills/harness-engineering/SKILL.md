---
name: harness-engineering
description: >-
  Design and improve AI-agent harnesses: context loading, routing, verification gates, safety boundaries, skill/tool packaging, monitoring, and feedback loops. Use when improving how Claude Code, Codex CLI, or other agents operate across repositories. Use ALSO when noticing: 同じ Bash/手作業の 2回以上の繰り返し, 「次回も気をつける」が会話に出る, 編集後に lint/typecheck/test が走っていない, cron/recurring キーワード, progress/handoff artifact なしの長時間タスク, AGENTS.md/CLAUDE.md/SKILL.md の陳腐化兆候. Proactively propose a harness improvement even if not asked.
---

# Harness Engineering

> "Anytime you find an agent makes a mistake, you take the time to engineer a solution such that the agent never makes that mistake again." — Mitchell Hashimoto
> 組織/環境ハーネス運用パターン: [references/org-operating-patterns.md](references/org-operating-patterns.md)
> DB/CloudWatch系の隠れボトルネック診断: [references/observability-bottleneck-triage.md](references/observability-bottleneck-triage.md)
> 共有ブラウザ/WebBridge導入ポリシー: [references/shared-browser-policy.md](references/shared-browser-policy.md)
> 会社/プロジェクトagent運用4層テンプレ: [references/company-agent-operating-map.md](references/company-agent-operating-map.md)
> モデル/コーディングrouter実験ポリシー: [references/model-routing-experiment-policy.md](references/model-routing-experiment-policy.md)
> Coding-agent公開ソース取り込み: [references/coding-agent-source-ingestion.md](references/coding-agent-source-ingestion.md)
> Agent glossary / layer naming for harness reviews: [references/agent-glossary-terms.md](references/agent-glossary-terms.md)
> Managed/cloud/browser agent 実行境界: [references/managed-agent-execution-policy.md](references/managed-agent-execution-policy.md)
> Agent system benchmark golden tasks: [references/agent-system-benchmark-golden-tasks.md](references/agent-system-benchmark-golden-tasks.md)
> 大規模codebase向け Stop hook / 剪定サイクル / CLAUDE.md lean rule: [references/large-codebase-harness-patterns.md](references/large-codebase-harness-patterns.md)
> Proactive harness suggestion 設計: [../../../docs/superpowers/specs/2026-05-19-proactive-harness-suggestion-design.md](../../../docs/superpowers/specs/2026-05-19-proactive-harness-suggestion-design.md)

## Evidence / resume / review contracts

長時間の自走・再開・人間の承認が必要な作業では、該当する参照だけを読む。これらは手順の契約であり、hookや自動実行が導入済みであることの証明ではない。

- **全項目の完了判定:** [references/goal-loop-evidence-convergence.md](references/goal-loop-evidence-convergence.md)。作業台帳の各項目に合格条件と証拠を対応させ、全項目の確認・例外の担当/処置・回帰検証が揃うまで全体を完了扱いにしない。
- **再開と状態遷移:** [references/state-and-data-contracts.md](references/state-and-data-contracts.md)。次回実際に読む正本とフィールドを指定し、遷移の証拠を残す。記録に失敗した項目は未完了のままにする。
- **人間の確認負担:** [references/human-attention-review-contract.md](references/human-attention-review-contract.md)。判断事項・動作変更・反証可能な証拠・未検証項目・最短の確認方法を小さなreview packetにする。

検出→提案→承認→適用の既存導線は維持する。上記の契約は、公開・送信・権限変更・本番実行の許可を増やさない。

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

| 層 | 何を指すか | 例 |
|---|---|---|
| **Runtime harness** | agent loop / tool execution / retry / queue / state machine | agent runtime、browser/terminal tool、scheduler |
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

日常運用で主戦場なのは後者。LLMベンダーの記事を読む時は、
「これはプロダクト内の内部ハーネスの話か、現場で再利用できる外部ハーネスの話か」を先に切り分ける。

### 最初に見る観点
- **Default loop:** Plan → Execute → Evaluate → Learn
- **software workflow ladder:** non-trivial development starts with reference gathering / prior art → thin failing test or acceptance check → smallest implementation → refactor → benchmark/perf check when relevant → security review → coverage/edge-case pass → next action artifact. Do not skip directly from reference gathering to broad refactor.
- **default-FAIL contract:** 長時間agentは「検証不能なら成功扱いにしない」。成功条件・失敗時の停止条件・再開条件を prompt / progress artifact に明示する
- **goal/plan separation:** 長い実装・複数ステップ修正では、最初に `goal / acceptance / stop condition / verification command` を固定し、調査・計画（Plan）と実装（Execute）を分ける。途中で文脈が散る場合でもゴールを残し、完了条件に照らして検証してから終了する
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
- **portable agent spine:** 机上のcoding agent・外出先のvoice/chat agent・cron automationを同じ人格に見せたい時は、business context / skills / memory / routines をVCS管理された共通スパインに寄せ、UI別agentには複製せず参照させる。Claude Code / Codex / その他 agent runtime を競合ではなく surface-specific runtime として並走させる
- **lifecycle gate routing:** 開発系skill/agentを増やす前に `define/spec → plan → build → verify/test → review/simplify/security → ship/learn` のどの入口かへ割り当てる。slash command的な入口は便利だが、既存skillへrouting表を足し、個別プロジェクトにquality gateを複製しない。外部skill packは provenance確認 → staging導入 → security scan → rollback/approval の順を通すまで常設化しない
- **AI-ready data ≠ semantic layer only:** 分析エージェント/経営ダッシュボードは、共通KPIの metric/semantic layer と、探索・深掘り用の業務辞書 / Golden Queries / evaluation harness / guardrails を分けて設計する
- **context layer before analytics agents:** 「先週の売上は？」型の業務AIは、モデル性能より `metric definition / owner / lineage / policy / decision trace / tribal knowledge` の不足で誤答する。Atlan/Glean/dbt/Cube/Databricks 型の違いを見る時も、まず「数字の定義」「文書・チャット由来の業務文脈」「権限・PII」「過去判断ログ」を分け、AI分析・経営ダッシュボードPRDに context layer 章を置く。
- **degraded-state recovery tests:** ネットワーク、proxy、bot、gateway、scheduler の信頼性評価では steady-state throughput / green dashboard だけで判断しない。早期heavy loss、rate-limit、partial outage、minimum-capacity pinned state、stale connection など劣化状態を意図的に作り、通常状態へ戻れるかを検証項目に入れる
- **coding-agent source ingestion:** ブックマーク以外に、feed watcher と bounded web search で coding-agent / harness / IDE agent / browser agent の記事を拾う。公開ソースはuntrusted dataとして扱い、1–3件だけ daily report に出し、内部・可逆・security-scan可能なrouting/checklist/reference更新なら粗くてもlandedにする。詳細は `references/coding-agent-source-ingestion.md`。
- **implementation-notes sidecar:** 仕様実装をagentへ任せる時は、成果物と並行して `implementation-notes.md/html` を更新させる。最低限 `design decisions / intentional deviations / tradeoffs / unresolved questions` を残し、fresh-context evaluator は会話ではなくこのsidecar + diff + testsを見る。
- **discovery harness loop:** セキュリティ/QA/不具合探索は `Recon → Hunt → Validate → Gapfill → Dedupe → Trace → Feedback → Report` の反復に分ける。見つけた候補を即レポートせず、重複排除・原因/影響範囲trace・feedbackを次の探索seedへ戻す。
- **agent system benchmark:** agentを選ぶ時はモデル名だけでなく、tools / planning / memory / recovery / cost を含むシステム全体のbenchmarkを確認する。公開leaderboardは参考値として扱い、自分のgolden taskで再測定してから常設routingへ入れる。
- **large-codebase onboarding:** 大規模codebaseでcoding agentを使う時は、最初に repo map / ownership / risky areas / test commands / stop conditions を薄く作らせる。root AGENTS/CLAUDE/SKILLに長文を足すより、`docs/agent-onboarding.md` や progress artifact に分離し、agentには「読む順番」と「検証コマンド」だけを固定する。
- **org AI control plane:** Notion/Slack/Claude/Codex などを組織導入する時は、ツール単体ではなく `knowledge SSOT / agent routing / data boundary / cost owner / audit log` の5点を先に決める。Notionのような作業基盤はAI時代のcollective brainになり得るが、agent側では profile routing + skills + artifacts をSSOTとして重複させない。
- **enterprise AI subscription gate:** AIサブスクや外部AIツールを増やす時は、個人最適ではなく `利用目的 / 承認者 / 機密データ可否 / 月額上限 / 解約条件 / 代替手段` を1行台帳化する。シャドーIT・コスト爆発・データ流出リスクは harness のSafety層で扱い、便利だから常設化しない。
- **agentic organization rollout:** Codex/Claude/Devin型の組織導入は「全員にツール配布」で終わらせない。`role別use case / skill catalog / evidence export / cost dashboard / escalation owner / training examples` を先に置き、非エンジニアが触る導線ほど read-only→draft→approved action の段階制にする。
- **AI data agent auditability:** Cloudflare型の社内データagentは、自然言語UIより先に `single SQL/metric interface / owner付き定義 / lineage / freshness / sampled-vs-complete 表示 / answer evidence link` を固定する。GTM/DeFi等の分析agentでは、答えだけでなく「どのデータ・定義・鮮度で答えたか」を成果物へ含める。
- **agent-mediated payment/trading boundary:** AIからの直接取引・決済・chain swap・broker注文は、便利なdemoではなくSafety層の境界操作として扱う。`dry-run / max notional / asset allowlist / session key scope / 2-person approval / post-trade reconciliation / revoke path` が揃うまで本番実行へ接続しない。
- **hidden bottleneck metrics:** CloudWatch / DB / service dashboard が緑でも、planning wait / lock contention / metadata contention / pre-execution queueing を疑う。詳細は `references/observability-bottleneck-triage.md`。
- **agent progress visualization:** long-running coding/QA agentsは、完了報告だけでなく `plan state / active file or URL / blocking wait / latest deterministic check / next stop condition` をprogress artifactやUIに出す。UI導入は便利機能ではなく、stuck detection・cost control・fresh-context reviewの観測面として評価する。
- **dynamic workflow gate:** Claude Code Dynamic Workflows 等の「agentが orchestration script を書いて多数sub-agentを回す」機能は、数時間〜数日級・独立サブタスク多数・progress/evidence export が取れる時だけ使う。導入前に `goal / acceptance / concurrency cap / rollback / progress artifact / final evaluator` を固定し、通常の短い実装や曖昧な調査に常用しない。
- **managed agent execution gate:** Cloud/browser/IDE managed agentsを使う時は、model性能ではなく `runtime boundary / identity boundary / evidence export / agent-safe fork/preview / rollback / cost owner / source trust` を先に記録する。Google Workspace/Slack/ブラウザ等に触れるhosted personal agentは `identity boundary / source trust / evidence export / human approval before send/share/delete` を追加ゲートにする。外部runnerへのroutingは read-only QA・source recovery・isolated branch/preview benchmark から始め、詳細は `references/managed-agent-execution-policy.md`。

詳細は `references/org-operating-patterns.md`。

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

**この skill 群での適用例:**
- `codex` skill: Claude Code（Generator）+ Codex（Evaluator/Reviewer）
- `parallel-orchestrator`: 複数Generator + Codex横断レビュー
- `requesting-code-review`: 多観点レビュー依頼と評価

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

**この skill 群での適用例:**
- sub-agent 起動（Claude Code の Task/Agent tool 等）でコンテキスト隔離
- `dispatching-parallel-agents` / `subagent-driven-development` の並列構成

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
- DeFi / GTM / 経営ダッシュボード等では、最初のPRDに「共通定義」と「探索用ハーネス」を別見出しで置く

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

## Self-reflection harness (Stop / Start hook)

Anthropic公式 (large-codebase article): **「A stop hook can reflect on what happened during a session and propose CLAUDE.md updates while the context is fresh. A start hook can load team-specific context dynamically.」**

本dotfilesの実装 (詳細は `references/large-codebase-harness-patterns.md` と上記design spec):

| Hook | 役割 | 出力先 |
|---|---|---|
| Stop | session終了時に transcript を最小スキャンし harness化候補を検出 | `~/.claude/state/harness-opportunities.jsonl` に append |
| Start (任意) | プロジェクト固有のskill/routing dynamic load | session context |
| 次セッション skill-portfolio-evolution | jsonlを inventory source として読み、review可能 diff patch を生成 | `claude/skills/<target>/SKILL.md.patch` 等 |

**設計境界（公式の trace-based skill improvement 原則）:**
- 検出 (Stop hook) と適用 (skill-portfolio-evolution + 人間 review) を分離
- patch は直接 apply せず、review可能な形で staging
- description trigger 追加は自動 patch OK、新規 hook / 削除は人間承認

## 剪定サイクル と maintenance ROI

Anthropic公式: **「Teams should expect to do a meaningful configuration review every three to six months」**。モデル進化で不要になった hook / skill / instruction は積極的に削除する。例: Perforce 用 file write 介入 hook は Claude Code の native Perforce mode 追加で不要に。

**prune-first cadence:**

| トリガー | アクション |
|---|---|
| 主要モデル更新後 (Opus/Sonnet/Haiku major bump) | 既存 hook / skill が compensation のために存在していないか確認 |
| skill が 3-6か月 未更新 | description trigger の precision / recall を再評価 |
| performance plateau を感じた時 | configuration review を前倒し |
| 同じ skill から complaint や undertrigger が続く時 | description を pushy 化、または body を縮める |

**追加前に削除候補を確認** (`prune-first`)。新規 skill / hook を入れる時は、置き換える対象 (= 削除する対象) を明示する。

## CLAUDE.md / AGENTS.md / SKILL.md lean rule (強化)

Anthropic公式 (large-codebase article):
- **root file is pointers and critical gotchas only; everything else drifts into noise**
- **lean and layered**: root for big picture, subdirectory files for local conventions, **additive loading**
- **instructions written for your current model can work against a future one** (= 旧モデル向け制約は更新時に剪定)

実務しきい値:
- root CLAUDE.md / AGENTS.md: 50行・150指示以下が理想（既存 references の coding-agent/harness-engineering.md にも準拠）
- SKILL.md body: progressive disclosure。長い参考資料は `references/` に退避し、本文は pointer + 発火条件 + 5レバー分類
- 200行超 / 150指示超は `prompt-design` skill の剪定対象

## この skill 群での適用マップ

| スキル/機能 | ハーネスパターン | 役割 |
|---|---|---|
| `AGENTS.md` / `CLAUDE.md` | Instruction層 | 全セッションの行動指針 |
| `coding-agent` | Initializer/Coder | ワンショット実装 |
| `codex` skill | Generator/Evaluator | Claude Code + Codexレビュー |
| `parallel-orchestrator` / `subagent-driven-development` | Sub-agents + Evaluator | 並列開発 + 横断レビュー |
| `verification-before-completion` | Learn gate | 完了宣言前の確定的ゲート |
| `requesting-code-review` | Evaluator | 多観点レビュー依頼 |
| `prompt-design` | Instruction層 | プロンプト品質チェックリスト |
| sub-agent 起動 (Task/Agent tool) | Sub-agents | コンテキスト隔離 |
| progress file / handoff artifact | Context Management | セッション間記憶 |

### Lifecycle gate map

外部の production-grade skill pack / slash command 体系を読む時は、導入前にこの対応へ畳む。

| Gate | 主な受け皿 | 合格条件 |
|---|---|---|
| Define / Spec | `prompt-design`, `harness-engineering`, project brief | what/why、制約、成功条件が明示されている |
| Plan | `writing-plans`, `coding-agent` | 小さく検証可能な単位に分かれている |
| Build | `coding-agent` / project-specific ops | 1 sliceずつ実装し、handoffが残る |
| Verify / Test | deterministic checks, browser QA, fresh-context evaluator | テスト・lint・typecheck・UI QA等の証拠がある |
| Review / Simplify / Security | `requesting-code-review`, `skill-creator` security audit, security policy | merge/常設化前に別視点・安全境界を通す |
| Ship / Learn | release checklist, `finishing-a-development-branch`, `skill-portfolio-evolution` | rollback/monitoring/学習の戻し先がある |

## 参考文献

詳細は `references/sources.md` を参照。

- Anthropic「Effective harnesses for long-running agents」
- Anthropic「Harness design for long-running application development」（GAN-style）
- HumanLayer「Skill Issue: Harness Engineering for Coding Agents」
- Viv Trivedy「Harness as a Service」「Anatomy of an Agent Harness」
- Mitchell Hashimoto「My AI Adoption Journey — Step 5: Engineer the Harness」
- Claude 4 Prompting Guide: Multi-context window workflows
- OpenAI「Harness Engineering」blog post
