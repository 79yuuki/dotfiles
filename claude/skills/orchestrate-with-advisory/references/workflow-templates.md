# Workflow テンプレート集（実測済み）

実プロジェクト（Fidem: 18タスク実装 + レビュー修正 + UX改善、計10本超の Workflow）で
動作確認済みのテンプレート。コピーして固有名を差し替えて使う。

## 目次
1. 構造化返却スキーマ（IMPL_SCHEMA）
2. サブタスク共通プロンプト（taskPrompt）
3. script 雛形: 並列 + 統合検証
4. script 雛形: 監査 → 手術 → 独立検証（直列 + ADVICE）
5. アドバイザリー resume の手順
6. 実測済みの落とし穴

## 1. 構造化返却スキーマ

```js
const IMPL_SCHEMA = {
  type: 'object',
  properties: {
    task: { type: 'string' },
    status: { type: 'string', enum: ['done', 'blocked'] },
    filesChanged: { type: 'array', items: { type: 'string' } },
    verification: { type: 'string', description: '実行した検証と実際の出力の要約' },
    deviations: { type: 'array', items: { type: 'string' }, description: '指示からの逸脱と理由' },
    notes: { type: 'string', description: '申し送り。blocked 時は詰まった箇所・試したこと・判断してほしいことを具体的に' },
    commitMessage: { type: 'string' },
  },
  required: ['task', 'status', 'filesChanged', 'verification', 'deviations', 'notes', 'commitMessage'],
};
```

`deviations` は重要。Sonnet は指示の不備を現場で発見して直すことがあり
（例: 指示どおりだと退会処理が FK 違反で失敗する二次バグを実 DB で発見して修正）、
その判断を明示報告させることでオーケストレーターが妥当性を検証できる。

## 2. サブタスク共通プロンプト

```js
function taskPrompt(name, spec, extra) {
  return 'リポジトリ: ' + REPO + '（他タスクが同じ作業ツリーで並行作業中）\n\n' +
'あなたは ' + name + ' の実装者である。\n\n' +
spec + '\n\n' +
'並行作業のための特別ルール:\n' +
'- git commit / git add はしない（統合エージェントが行う）\n' +
'- 割り当てファイル以外は変更しない\n' +
'- 共有設定ファイル（package.json / knip.json / cspell.json 等）は編集直前に再読込して自分の差分のみ重ねる\n' +
'- 検証は自分のスコープ優先。フルゲート失敗が他タスクの書きかけ起因なら、自分起因でないことを確認して notes に記録すれば PASS 扱いでよい\n' +
'- 実行していない検証を PASS と報告しない\n' +
'- 環境・権限・仕様矛盾など解決不能な問題は、場当たり的な回避（仕様の勝手な変更・検証のスキップ）をせず status="blocked" で詳細報告する\n' +
(extra ? '\n追加の注意:\n' + extra + '\n' : '') +
'\n最終出力は StructuredOutput ツールで返す。';
}
```

前タスクの `notes` を次タスクの `extra` に埋め込むと申し送りが伝わる
（`(prev.notes || '').slice(0, 800)` 程度に切る）。

## 3. script 雛形: 並列 + 統合検証

```js
export const meta = {
  name: 'project-stage-n',
  description: '…',
  phases: [
    { title: 'Implement', detail: 'A/B/C 並列' },
    { title: 'Integrate', detail: 'フルゲート + タスク別commit' },
  ],
}

const REPO = '/abs/path/to/repo'
// アドバイザリー欄: blocked 時にオーケストレーターが助言を追記して resume する
const ADVICE_A = ''
const ADVICE_B = ''

const INTEGRATION_SCHEMA = {
  type: 'object',
  properties: {
    status: { type: 'string', enum: ['done', 'blocked'] },
    commits: { type: 'array', items: { type: 'string' }, description: 'hash + subject の一覧' },
    fixesApplied: { type: 'array', items: { type: 'string' }, description: '統合時に適用した修正（なければ空）' },
    verification: { type: 'string' },
    notes: { type: 'string' },
  },
  required: ['status', 'commits', 'fixesApplied', 'verification', 'notes'],
}

phase('Implement')
const [a, b, c] = await parallel([
  () => agent(taskPrompt('A', SPEC_A, ADVICE_A), { label: 'A', phase: 'Implement', schema: IMPL_SCHEMA, model: 'sonnet' }),
  () => agent(taskPrompt('B', SPEC_B, ADVICE_B), { label: 'B', phase: 'Implement', schema: IMPL_SCHEMA, model: 'sonnet' }),
  // A の成果を使う後続がある場合はチェーンにする:
  // async () => { const a2 = await agent(...); if (a2?.status !== 'done') return a2; return agent(依存タスク, ...); }
  () => agent(taskPrompt('C', SPEC_C, ''), { label: 'C', phase: 'Implement', schema: IMPL_SCHEMA, model: 'sonnet' }),
])

const all = [a, b, c].filter(Boolean)
if (all.some(r => r.status === 'blocked') || all.length < 3) {
  return { stoppedAt: 'Implement', results: all }   // ← blocked は途中 return（アドバイザリーの入口）
}

phase('Integrate')
const integration = await agent('統合検証者。成果と申し送り:\n' +
  JSON.stringify(all.map(r => ({ task: r.task, files: r.filesChanged, deviations: r.deviations, notes: r.notes, commitMessage: r.commitMessage })), null, 2) +
  '\n手順: フルゲート → 成果物間の不整合を修正（設計は変えない）→ 実地スモーク → タスク別 commit（共有設定は帰属タスクへ）→ 統合修正は fix commit。',
  { label: 'integrate', phase: 'Integrate', schema: INTEGRATION_SCHEMA })
if (!integration || integration.status !== 'done') return { stoppedAt: 'Integrate', integration, results: all }
return { stoppedAt: null, results: all, integration }
```

## 4. script 雛形: 監査 → 手術 → 独立検証（直列・高リスク作業）

git 履歴書き換え等の高リスク作業は並列化せず、
**調査（read-only）→ 実行（制約を厳密に列挙）→ 独立検証（実行者の主張を信用しない）** の
3 段直列にする。実行エージェントのプロンプトには「絶対制約（違反したら失敗）」を
番号付きで列挙し、最終状態の検証可能な条件（例: `git diff main <branch>` が空）を含める。
オーケストレーターは開始前に backup を取り、完了後に自分でも最終確認してから反映する。

## 5. アドバイザリー resume の手順

1. Workflow が `{ stoppedAt: 'X', results: [...] }` で完了通知 → blocked タスクの `notes` を読む。
2. Opus が判断（助言で解決するか / 設計を変えるか / 自分で直すか / タスクを分け直すか）。
3. 助言する場合: ツール結果に記載された script ファイルパスを Edit し、
   `const ADVICE_X = ''` に助言を書く（そのタスクのプロンプトが変わる）。
4. `Workflow({ scriptPath: '<同じパス>', resumeFromRunId: '<元のRun ID>' })` で再起動。
   （prompt, opts）が不変の完了済み agent はキャッシュ再生、変更されたタスク以降のみ実行される。
5. 診断時は transcript dir の `journal.jsonl` に各 agent の実際の返り値がある。
   結果が空/想定外のときは推測せず journal を読む。

## 6. 実測済みの落とし穴

- **script 内のバッククォート**: プロンプト文字列（テンプレートリテラル）の中に
  `` `pnpm test` `` のようなコードスパンを書くと parse error。プロンプト内では
  シングルクォートか裸で書く。または文字列連結（'a' + var + 'b'）で組む。
- **並列エージェントの git 競合**: commit を統合エージェントに一元化すれば index.lock
  競合は起きない。中間コミットの分割は「各タスクの filesChanged リスト + 共有設定の帰属判断」で行える。
- **フルゲートの相互干渉**: 並列中の typecheck/lint は他タスクの書きかけファイルで落ちる。
  「自分起因でないことの確認 + notes 記録で PASS 扱い」ルールで吸収し、最終判定は統合エージェントが行う。
- **ポート競合**: 並行 dev サーバー・別プロジェクトの常駐プロセスとぶつかる。
  専用ポートを明示指定させる（PORT=3xxx）。検証後のプロセス停止を指示に含める。
- **`.next` の汚れ**: コミットを跨いで typecheck すると stale な `.next/types` が偽エラーを出す。
  `rm -rf .next` してから判定する。
- **zsh の単語分割**: `for c in $(git rev-list ...)` は zsh では分割されない。
  `| while read c` 形式を使うようプロンプトに明記する。
- **phase() と並列**: 並列中のフェーズ表示は agent() の `opts.phase` で明示する
  （グローバル phase() は並列内でレースする）。
- **モデル選定の実績**: 仕様が詳細なら Sonnet の品質は高い（実 DB 検証・二次バグ発見まで到達）。
  設計の確定・blocked の裁定・最終レビューだけを Opus が持てば十分に回る。
