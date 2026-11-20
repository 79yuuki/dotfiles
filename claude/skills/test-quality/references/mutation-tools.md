# Mutation testing のツールと最小コマンド

ここに無いフラグは未確認。使う前に、そのツールの `--help` か公式 docs で確かめる。版は書いていない。動かした版を報告に書く。

## 選び方

| 言語・テスト基盤 | 第一候補 | 備考 |
|---|---|---|
| TypeScript / JavaScript（Jest、Mocha など） | StrykerJS | Jest の時は jest-runner のプラグインが要る |
| TypeScript / JavaScript（Vitest） | StrykerJS（vitest-runner）か `@mizchi/mutator` | mutator は差分だけを測る `--since` があり、繰り返しに向く。Node.js と Vitest の版の条件は README で確かめる |
| Rust | cargo-mutants | |
| Python | mutmut | |
| Java / Kotlin | PIT（pitest） | Maven か Gradle のプラグインとして動く |
| Go | 公式 docs で候補を確かめる | この skill では未検証 |
| Solidity | 公式 docs で候補を確かめる | この skill では未検証。コントラクトは smart-contract-audit の範囲も見る |

## 共通の進め方

1. **依存を足さずに試す。** `npx`、`pnpm dlx`、`uvx`、`cargo install` 済みのバイナリなど、リポジトリの依存を変えない実行を先に試す。monorepo でプラグインが解決できない時は、一時的な worktree で依存を足して測り、その worktree を捨てる。
2. **対象を 1〜3 ファイルに絞る。** 所要時間は、おおよそ「変種の数 × 関係するテストの時間 ÷ 並列数」。先にテストの所要時間を測り、見積もってから走らせる。
3. **テストも絞る。** 対象のファイルに関係する spec だけを走らせる設定にする。全テストを変種ごとに回さない。
4. **時間を区切る。** タイムアウトした変種は「検出」に数えず、別に報告する。
5. **出力は一時ディレクトリに出す。** ツールの出力先（`.stryker-tmp/`、`reports/`、`.mutator/`、`mutants.out/` など）は、指定できるなら一時ディレクトリにする。コミットしない。片づける時に消すのは、今回の実行で新しくできたものだけ。実行の前から在ったディレクトリやファイルは消さない。

## StrykerJS（TypeScript / JavaScript）

設定ファイル（`stryker.config.json`）の例。pnpm の monorepo で Jest を使うリポジトリで動かしたもの（StrykerJS 10.1.1、2026-11-20）。

```json
{
  "testRunner": "jest",
  "plugins": ["@stryker-mutator/jest-runner"],
  "jest": { "configFile": "jest.stryker.config.js", "enableFindRelatedTests": false },
  "mutate": ["libs/domain/src/payment/payment-status.ts"],
  "coverageAnalysis": "perTest",
  "reporters": ["clear-text", "json"],
  "tempDirName": ".stryker-tmp"
}
```

```bash
pnpm exec stryker run
```

- 必要なパッケージは `@stryker-mutator/core` と、テスト基盤に合わせた runner（Jest なら `@stryker-mutator/jest-runner`）。使い捨ての worktree で入れ、測り終えたら worktree ごと捨てる。
- 既に設定ファイルがあれば、上書きせずにそれを使う。無ければ一時的に作り、測り終えたら自分が作ったものだけを消す。
- 走らせるテストは、Jest の設定を継いで `roots` だけを対象のディレクトリに差し替えた一時の設定ファイルで絞る。

  ```js
  // jest.stryker.config.js（一時ファイル）
  const base = require('./jest.config.js');
  module.exports = { ...base, roots: ['<rootDir>/libs/domain/src/payment'] };
  ```

- `coverageAnalysis` を `perTest` にすると、変種ごとに関係するテストだけを回す。
- 出力の `Survived` が生き残り、`Killed` が検出、`Timeout` と `No coverage` は別に数える。JSON のレポート（`reports/mutation/mutation.json`）から、生き残りの場所と書き換えの内容を読める。

踏んだこと:

- pnpm では、runner のプラグインを自動で見つけられず「Cannot find TestRunner plugin」で止まる。`plugins` に明示する。
- `enableFindRelatedTests` を有効にすると、対象を import するテストがリポジトリ全体から選ばれ、生成物（ORM のクライアントなど）が要るテストが最初の実行で落ちて、全体が止まる。走らせるテストは自分で絞る。
- 文字列を空にする変種は、エラーの文言やログで大量に生き残る。その文言が仕様に関わらない（呼び出し側が分岐に使わず、利用者への約束でもない）と確かめたものは、読まない。呼び出し側が分岐に使うコード（エラーコード）の変種は読む。
- 生き残りの中に、空の配列を別の値に差し替える変種があった。型の上で来ない値への差し替えで、外から観測できる振る舞いは変わらない。等価として、理由を書いて除く。
- 3 ファイル・変種 109・テスト 144 本で、所要は約 40 秒だった（並列 3）。

## @mizchi/mutator（Vitest）

```bash
pnpm exec mutator                 # 設定なしなら src/ 以下が対象
pnpm exec mutator --since HEAD    # 最後のコミットからの変更だけ
pnpm exec mutator --since main    # main からの変更だけ
```

- キャッシュとレポートは `.mutator/` に出る。
- 対象を絞る時は `mutator.config.ts` の `include` と `exclude` に書く。

## cargo-mutants（Rust）

```bash
cargo mutants --file src/payment/status.rs
```

- 結果は `mutants.out/` に出る。`missed` が生き残り、`caught` が検出。

## mutmut（Python）

```bash
mutmut run
mutmut results
```

- 対象とテストのコマンドは設定（`pyproject.toml` か `setup.cfg`）に書く。書き方は版で違うので、README で確かめる。

## PIT（Java / Kotlin）

```bash
mvn test-compile org.pitest:pitest-maven:mutationCoverage
```

- 対象のクラスとテストは、プラグインの設定（`targetClasses`、`targetTests`）で絞る。

## ツールが動かない時の手動の変異

隔離したコピー（一時 worktree か、ファイルの写し）で、対象の性質に関係する書き換えを 1 つずつ入れ、関係するテストを走らせる。本物の作業ツリーでは行わない。

| 書き換え | 例 |
|---|---|
| 境界を 1 ずらす | `>` を `>=` に、`<= max` を `< max` に |
| ガードを外す | 権限の確認、状態の確認、null の確認を消す |
| 条件を反転する | `if (ok)` を `if (!ok)` に |
| 戻り値を固定する | 計算結果の代わりに `0`、`true`、空の配列を返す |
| 処理を飛ばす | 保存、通知、ロックの取得を消す |
| 順序を入れ替える | 確認と書き込みの順を逆にする |

- テストが落ちたら検出、通ったら生き残り。構文エラーやビルド失敗は、検出に数えない。
- 手動で試した変異は一部でしかない。報告には「手動の変異 5 個」と書き、スコアとは呼ばない。

## 出典

- StrykerJS https://github.com/stryker-mutator/stryker-js 、設定の一覧 https://stryker-mutator.io/docs/stryker-js/configuration/
- @mizchi/mutator https://github.com/mizchi/mutator
- cargo-mutants https://mutants.rs/
- Google「State of Mutation Testing at Google」https://research.google/pubs/state-of-mutation-testing-at-google/
