---
name: orchestrate-with-advisory
description: Fable 5 をオーケストレーター、Sonnet 5 を実装者とする Workflow ツール多エージェント開発パターン。実装・修正・調査など複数ステップの作業を開始する時に毎回使う。タスク分割（ファイル所有権の排他）、構造化返却（done/blocked）、統合検証エージェント、blocked 時のアドバイザリーループ（Fable が助言を ADVICE 欄に追記して resumeFromRunId で再開）を提供する。NOT for: 会話的な応答や1ファイルの軽微な修正（workflow 化しない）、Codex CLI とのレビュー対話（→ codex スキル）、Agent ツール単発の軽量タスク（→ coding-agent / dispatching-parallel-agents）。
---

# Orchestrate with Advisory

Fable 5（メインループ）= 判断・統合・レビュー。Sonnet 5（サブエージェント）= 実装・調査・機械的作業。
Workflow ツールで編成し、サブタスクが詰まったら **blocked → Fable が助言 → resume** で回す。

本スキルは **メインループ（オーケストレーター）専用**。Workflow ツールはサブエージェントからは
使えない。script は Workflow ツールの `script` パラメータにインラインで渡す（自動で
ファイルに永続化され、パスがツール結果に返る。resume 時はそのパスを `scriptPath` で指定）。

テンプレート（スキーマ・プロンプト雛形・script 雛形・実測済みの落とし穴）は
[references/workflow-templates.md](references/workflow-templates.md) を実装前に必ず読む。

## コアワークフロー

### 1. タスク分割（オーケストレーターの仕事）

- 計画をサブタスクに分割し、**各タスクの担当ファイルを排他にする**（並列時の衝突防止の要）。
- 共有設定ファイル（package.json / knip.json / cspell.json 等）はどのタスクにも属しうる。
  「編集直前に再読込して自分の差分だけ重ねる」ルールをプロンプトに必ず入れる。
- 依存グラフを書く: 依存のないもの → parallel、A の成果を B が使う → チェーン
  （async 関数内で直列 await）、両方混在 → parallel の中にチェーンを入れる。
- 粒度の目安: 1 タスク = 1 エージェントが自分の担当ファイル群 + 参照仕様だけで完結でき、
  独立に検証・コミットできる単位。迷ったら「レビュアーが片方だけ却下できるか」で分ける。
  複数ファイルでも概ね直列で軽い作業（小さな機能修正）は Workflow 化せず
  Agent ツール 1 体（coding-agent 相当）+ 直接検証で済ませてよい。
- 判断が必要な設計（セキュリティ境界・スキーマ・命名）は **投げる前に Fable が確定**し、
  「この設計で実装せよ。設計を変えないこと」とプロンプトに固定する。

### 2. サブタスク契約（全エージェント共通）

- StructuredOutput スキーマで返させる。必須: `status: done | blocked`、
  `filesChanged`、`verification`（実際に実行した出力に基づく）、`deviations`、`notes`。
- **blocked の定義をプロンプトに明記**: 環境・権限・仕様矛盾など解決不能な問題に当たったら、
  場当たり的な回避（仕様の勝手な変更・検証のスキップ）をせず blocked で返す。
  notes に「何を試し、どこで詰まり、オーケストレーターに何を判断してほしいか」を書かせる。
- 並列実行時は **git commit / add をさせない**（統合エージェントに集約）。
- 検証は「実行していない検証を PASS と書かない」を明記。フルゲートが他タスクの
  書きかけで落ちる場合は「自分起因でないことを確認して notes に記録すれば PASS 扱い」。

### 3. モデル選定

- `model: 'sonnet'`: 仕様が確定している実装・転記・調査・検証・テスト作成（大半のサブタスク）。
- 省略（Fable 継承）: 敵対的検証、広い裁量が必要な設計タスク（ただし原則は投げる前に Fable が設計を確定する）。

### 4. 統合検証エージェント（ステージの締め）

並列・直列を問わず、複数タスクが 1 つの成果に合流する箇所では必須。完了後に 1 体、以下を任せる:
フルゲート実行（lint / typecheck / test / build）→ 成果物間の不整合を修正（設計は変えない）→
実地スモーク → **タスク別に commit を分割**（各タスクの filesChanged + 帰属する共有設定変更、
指定 commitMessage 使用）→ 統合修正は別 fix commit。

### 5. アドバイザリーループ（blocked からの再開）

1. Workflow script の冒頭に助言欄を用意しておく:
   `const ADVICE_<TASK> = ''` を宣言し、各プロンプト末尾に条件付きで埋め込む。
2. サブタスクが blocked を返したら Workflow は途中 return する（`stoppedAt` を返す設計にする）。
3. Fable が notes を読み、**判断**する: 助言して続行 / 設計変更 / タスク分割し直し / 自分で直接修正。
4. 助言する場合: ツール結果に出た script ファイルを Edit で開き、ADVICE 定数に助言を書き、
   `Workflow({ scriptPath, resumeFromRunId })` で再実行。**完了済みエージェントはキャッシュから
   即時再生され、プロンプトが変わった blocked タスク以降だけが再実行される。**
5. Agent ツール単発で走らせたエージェントには `SendMessage`（agentId 宛）で対話継続できる。
   Workflow 内の agent() は途中対話不可 — blocked→resume がアドバイザリーの正規経路。

### 6. ステージ間は Fable がレビュー

Workflow はステージ（意味のあるまとまり）ごとに分け、完了通知のたびに Fable が
journal / 成果を読んで判断してから次ステージの Workflow を起動する。
1 本の script に全ステージを詰め込まない（途中判断を挟めなくなる）。

### 7. Codex レビューゲート（ステージ完了ごと）

ステージ（サブタスクのまとまり）が完了するたびに、`codex` スキル経由で Codex CLI
（gpt-5.5 xhigh）にレビューを依頼する。依頼には対象コミット範囲・実施済み検証・
重点観点・出力フォーマット（✅ APPROVED / ⚠️ APPROVED WITH CONCERNS / ❌ NEEDS FIXES）を含める。
**✅ APPROVED が出るまで修正 → 再レビューを繰り返し、未承認のまま次ステージへ進まない。**
指摘は鵜呑みにせず、コード・仕様と突き合わせて技術検証してから適用する
（receiving-code-review の原則。正当でない指摘は根拠を添えて Codex に反論してよい）。
修正はこのスキルのオーケストレーション手順（分割 → Sonnet 委譲 → 統合検証）で行う。

## チェックリスト（起動前）

- [ ] 各タスクの担当ファイルが排他か。共有設定ファイルの再読込ルールを入れたか
- [ ] blocked の定義と「検証は実出力ベース」をプロンプトに入れたか
- [ ] 並列タスクに commit 禁止を入れ、統合エージェントを置いたか
- [ ] ADVICE 欄を script に用意したか（blocked 時に resume で助言を届ける経路）
- [ ] script は plain JS か（テンプレートリテラル内のバッククォート、TS 構文は parse error）
- [ ] ステージ完了後の Codex レビューゲート（✅ APPROVED まで修正）を計画に入れたか
