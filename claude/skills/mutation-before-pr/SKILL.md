---
name: mutation-before-pr
description: Vitest / Jest / Bun でテストする JS/TS リポジトリで、コードを変えた PR を出す前と、その PR に追加で push する前に、差分へ mutation testing（mizchi/mutator）を回す手順。コマンドの選び方、生き残りの対処と等価な変異の除外、PR 本文に書く1行、mutator を使っていないリポジトリでの後片付け。テスト群全体の検品には使わない。
---

# PR の前に差分へ mutation testing を回す

差分のコードをわざと書き換えた変種（変異）を作り、テストが落ちるかを見る。落ちない変異があれば、テストはその差分を守っていない。

対象は、Vitest / Jest / Bun でテストしている JS/TS のリポジトリで、コードを変えた PR。PR を出す前と、その PR に追加で push する前に毎回回し、PR 本文の1行も書き直す。

## コマンドを選ぶ

1. base を最新にする: `git fetch origin <base>`。
2. プロジェクトに専用の入口があれば、それを使う。package.json の `check:mutation` のような script、`mutator.config.*`、devDependencies の `@mizchi/mutator` が目印。使い方と判定の基準はプロジェクトの README に従う（例: `pnpm run check:mutation --since origin/main`）。
3. 無ければ、グローバルの `mutator --since origin/<base>` を、テストのあるパッケージのディレクトリで実行する（monorepo ならパッケージごと）。
   - 変異の対象は既定で `src/` 以下。ソースが別の場所なら `--include 'app/**/*.{ts,tsx}'` のように渡す。
   - テストだけを変えた PR では `--include-test-changes` を付け、変えたテストが守るコードの変異を回す（付けないと変異が 0 件で、score は 100% と出る）。
   - 生き残りの全件が要る時は `--reporter agent`（標準出力に JSON）。
   - 差分が大きい時は `--time-budget 600` で打ち切れる。打ち切って回さなかった変異は Pending になり、差分の score には入らない（Pending だけなら 100% と出る）。Pending が残ったら、片付けの前に同じコマンドをもう一度実行して続きを回す。
   - グローバルの `mutator` は dotfiles の `bin/mutator`。PATH の node が 24 以上ならそれを、足りなければ nvm で入れた一番新しい Node を使い、テストもその Node で走る。プロジェクトが Node の版を決めていれば、先に `nvm use` する。

## 動かない時

- mutator 0.5.3 のランナーが前提にする版は、Vitest 5.x（peer `^5.0.0`）、Jest 30 以上（実験的）、Bun（実験的）。Vitest 3.2.4 では baseline で `Cannot read properties of undefined (reading 'meta')` が出て止まった（exit 4）。この PR のためにプロジェクトの依存を上げない。
- exit 4 は「変異を入れなくてもテストが落ちる」。元から落ちるテストのせいなら、そのテストを外した設定をリポジトリの外（一時ディレクトリ）に作り、`--config`（Vitest）か `--jest-config` で渡す。外したテストは PR 本文に書く。
- 回せなかった時は、PR 本文に `mutation: 未実行（理由）` と書く。黙って省かない。

## 生き残りを片付ける

- 検出は Killed / Timeout / RuntimeError、未検出は Survived / NoCoverage。score は 検出 ÷（検出 + 未検出）で、CompileError と Ignored は数えない。
- 未検出の変異は、それを落とすテストを足して殺す。等価でない未検出の変異と Pending が 0 件になるまで、PR を出さない・push しない。殺せないと判断した時は、出す前に人に聞く。期待値は仕様から書き、いまのコードの出力から写さない。足したら同じコマンドで回し直し、その変異が Killed になったことを確かめる。
- 等価な変異（どの入力でも、外から観測できる結果が元と同じ）だけを、理由を付けて除外する。元と変種で結果が変わる入力が本当に無いかを、具体的な値で確かめてから等価と呼ぶ。
  - mutator を使っているリポジトリでは `mutator accept <key> --reason "<理由>"` で `mutator.accepted.json` に記録し、プロジェクトの決まりに従ってコミットする。
  - 使っていないリポジトリでは accept しない（リポジトリにファイルができる）。key と理由を PR 本文に書く。

## PR 本文に書く1行

```
mutation: score 92.3%・生き残り 0 件（差分の変異 26、等価で除外 1: <key> <理由>）`mutator --since origin/main`
```

## mutator を使っていないリポジトリの後片付け

mutator 0.5.3 がリポジトリに書くものは次の2つ（本体のコードで確認した）。`<root>` は `--root` の場所で、既定は実行したディレクトリ。

- `<root>/.mutator/`: キャッシュ（`snapshot.json`、`scopes/`、`*.resume.sqlite`）、報告（`report/`）、実行中のプロセスの記録（`processes/`）。`--report-dir` をリポジトリの外に向けても、このディレクトリはできる。
- `<root>/mutator.accepted.json`: `mutator accept` を使った時だけ。

手順:

1. 回す前に `git status --porcelain --ignored` の出力を控え、その中に `.mutator/` と `mutator.accepted.json` が無いことを確かめる。在れば前から在るものなので、3 の片付けはせずに報告する。
2. 報告のファイルが要る時は `--reporter text --reporter json --report-dir "$(mktemp -d)"` でリポジトリの外に出す（`--report-dir` だけでは、ファイルは書かれない）。
3. 回した後、同じディレクトリで `git clean -fdxq -- .mutator` を実行する。追跡されていないものだけが消える。`rm -rf` は使わない。
4. `git status --porcelain --ignored` を回す前と比べ、増えたものが無いことを確かめる。

キャッシュを消すので、追加の push の前に回すと最初から回り直す。差分だけを回すので、時間は短い。

## 関連

- テスト群全体の検出力を測って直す時は `test-quality`（あれば）。

確かめた版: `@mizchi/mutator` 0.5.3（2026-11-23）。
