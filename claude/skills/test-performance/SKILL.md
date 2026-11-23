---
name: test-performance
description: >-
  JS/TS リポジトリの単体・コンポーネントテスト（Vitest / Jest）の実行を、検出力を落とさずに速くする手順。測る → 内訳を分ける → 候補を1つずつ試す → 同じ正しさを確かめる → 残すか戻すか。「テストが遅い」「CI のテスト時間を短くしたい」「pool / isolate / environment / happy-dom / Browser Mode / ts-jest を替えて速くしたい」時に使う。テストが壊れを見つけるかの検品（test-quality）、PR 前の mutation testing（mutation-before-pr）、E2E を書く・回す（playwright-e2e）、落ちるテストや flaky の原因調査（evidence-driven-investigation）、アプリ本体や bundle の速度には使わない。
---

# テストの実行を、正しさを落とさずに速くする

成果物は「この差分を入れると、同じテストが同じ結果のまま、何秒から何秒になるか」の表と差分。効果が出なかった候補も、数字を付けて報告する。

## 合格の条件（先に決め、途中で緩めない）

1. **同じテストが走る。** 「ファイル・テスト名・結果」の集合が前後で一致する。件数だけの一致では足りない。
2. **新しい失敗と skip が 0。** 終了コードも同じ（全テストが通っても、未処理のエラーで落ちることがある）。
3. **順序を変えても安定。** 替えた設定で、seed を変えて 3 回以上通る。

テストや assertion を消す、skip / only / todo、retry や timeout を増やす、待ちの検証を弱めることで出た速さは、改善に数えない。テストのコードを変えた時は、その差分を報告に載せる。

## 手順

### 1. 測る場所を用意する

- 使い捨ての clone か worktree で測る。作業中のディレクトリの cache と設定を変えない。
- `uptime` を見る。load average が core 数を超えている間は測らない。ほかの仕事があるマシンでは `nice` と `--maxWorkers` で抑え、A と B で同じ値にする。
- プロジェクトの版を確かめる（Node、runner、environment のパッケージ）。設定の名前は版で変わる（[references/candidates.md](references/candidates.md) の対応表）。

### 2. 今の時間を分ける

Vitest は普通に 1 回流して `Duration` の行を見る。括弧の中は、worker で並列に進んだ時間の合計の割合で、実時間の割合ではない。

| 支配的な所 | 意味 | まず試すこと |
|---|---|---|
| `environment` | jsdom / happy-dom をファイルごとに作る | DOM を使わないファイルを node に分ける。vm 系の pool |
| `import`（3.x は `collect`） | テストと依存の評価。隔離ごとにやり直す | vm 系の pool。重い import を見つけて入口を狭める |
| `transform` | TS / JSX の変換 | cache（5.x は既定で有効）。cache を消した回と分けて見る |
| `setup` | `setupFiles` の実行 | DOM 用の setup を DOM のファイルだけにする |
| `worker`（3.x は `prepare`） | worker の起動 | ファイル数が多い時は、`threads` か vm 系の pool |
| `tests` | テスト本体 | 設定では縮まない。遅い上位のテストを見る（実時間の待ち、重い計算） |

あわせて、遅いファイルと遅いテストの上位を JSON の報告から出す。Vitest 5.x なら、終わりに出る hint と `vitest doctor` も候補選びに使える（下の Gotchas の限界を読んでから）。Jest は分解の行を出さないので、cache の有無の差（`--no-cache`）で変換の重さを、`--runInBand` との差で並列の効きを見る。

### 3. 候補を 1 つずつ、A/B を交互に測る

支配的な所から 1〜3 個だけ選ぶ。選び方、危険、版ごとの設定は [references/candidates.md](references/candidates.md)。**1 回に 1 つだけ変える**（environment と、その environment 用の setup のように、片方だけでは動かないものは 1 つと数える）。

実時間の下限は、一番遅いファイル 1 つの時間になる。下限に当たっている間は、ほかの候補の実時間が動かない。先にその 1 つを片付けるか、CPU 時間の差で選び、残した変更の上に次の候補を積んで測り直す。最後に、元の設定と最終形を直接比べる。

```bash
~/.claude/skills/test-performance/scripts/ab.py --max-others 2 \
  --a 'npx vitest run --maxWorkers=4 --reporter=json --outputFile={json}' \
  --b 'npx vitest run --maxWorkers=4 --reporter=json --outputFile={json} --pool=threads'
```

- A と B を交互に各 3 回（`--rounds`）、先に暖機を各 1 回（`--warmup`）流し、実時間と CPU 時間（user + sys）の中央値と幅、テストの集合の一致を出す。Jest は `--json --outputFile={json}`。
- 設定ファイルを変える候補は、一時設定を作って `--config` で渡すか、別の worktree に当てて `--cwd-b` で渡す。`{json}` は引用済みのパスに置き換わるので、引用符で囲まない。
- CI は cache が無いことが多い。`--warmup 0 --prepare '<cache を消すコマンド>'` の回を別に測り、暖機済みの数字と混ぜない。
- `--max-others N` は、測定中にほかのプロセスが平均 N core より多く使った回を捨てて測り直し、空くまで待つ（Linux と macOS）。N は「core 数 − worker 数 − 1」以下にする。load average は下がるのが遅く、短く空いた時間を逃す。同じ側の CPU 時間の幅が中央値の 1 割を超えたら、`--rounds 5` で測り直す。
- `projects` に分けた設定も、そのまま比べられる（照合はファイルとテスト名で行う）。
- **実時間と CPU 時間の両方で判断する。** 待ちは並列にすると隠れる。実時間だけ縮んで CPU が増える候補は、core の少ない CI で逆に遅くなりうる。CPU 時間は、親が終わりを待った子孫の分だけを数える。browser を別 process で動かして切る候補（Browser Mode など）は少なく出るので、CPU の減りを根拠にしない（数え漏れた分は「ほか」に入る）。

### 4. 同じ正しさを確かめる

`ab.py` の `SAME tests` は必要条件で、十分ではない。候補の種類ごとに足す。

- **全部の候補**: 順序を変えて 3 回。Vitest は `--sequence.shuffle.files --sequence.seed=<N>`、Jest は `--randomize --seed=<N>`（ファイルの中の順だけ）。元の設定でも同じ seed で流し、元から順序に弱いテストを候補のせいにしない。
- **隔離を弱める候補**（`isolate: false`、vm 系の pool、Browser Mode の `isolate: false`）: 汚染の検査を必ず付ける。何が残るかの表と、残すファイルを見つける道具は [references/isolation.md](references/isolation.md)。
- **environment・pool・変換（transpile）を替える候補**: 小さな範囲で、変異を落とせるかを前後で比べる（同じ reference の「検出力」）。
- **型検査を外す候補**（ts-jest の transpile のみなど）: 同じ範囲（テストのファイルを含む）を型検査する手順が CI にあることを確かめ、型エラーを 1 つ入れて落ちるところまで見る。

### 5. 残すか戻すか

残すのは、合格の条件をすべて満たし、実時間の幅が重ならず（`ab.py` が overlap と書かない）、CPU 時間が増えないもの。待ちを消す候補のように worker の詰まり方が変わって CPU が少し増える時は、最終形の CPU が元より減っていれば残してよい。改善が中央値で 10% に満たず、新しい設定やファイルの分け方を守る手間が増えるなら戻す（下限に当たっている時は、積んだ後の差で見る）。隔離を弱める候補は、後から足されるテストが約束を破った時に、落ちるか自動で戻る仕組み（[isolation.md](references/isolation.md) の「仕組み」）がある時だけ残す。

報告には、次の表を候補ごとに 1 行書く。

| 候補 | 実時間 A → B（幅） | CPU A → B（幅） | 件数・失敗・skip | 順序 3 回 | 検出力 | 判断と理由 |
|---|---|---|---|---|---|---|

測った条件（マシンと core 数、worker 数、版、cache の有無、ほかのプロセスが使った core 数）と、確かめなかったことも書く。測定用の worktree と一時ファイルを片付ける。

## Gotchas（実際に踏んだもの）

- **environment を読み込めないと、そのファイルは JSON の報告から消える**（`numFailedTests: 0`、`success: true`、終了コードだけが 1）。走っていない分だけ速く見える。ファイル数と終了コードを必ず比べる。
- 順序を変えない 4 回が全部通った `isolate: false` が、別の回で落ちた。`SAME tests` を汚染が無い証拠にしない。
- 順序を変えた 3 回が全部通っても、戻さない環境変数は見つからないことがある（合成プロジェクトでは、6 通りの seed のうち 1 つでだけ落ちた）。probe なら 1 回で見つかる。vm 系の pool では `process.env` が次のファイルに残る（`vi.stubEnv` も同じ）。
- `--no-isolate` の `vi.mock` は、mock した module を直接 import したファイルでは戻るが、**その module を使う別の module** は、最初に評価された版（本物か mock）で固まる。
- `vitest doctor`（5.x）は、終了コードと実時間の最小値だけで比べる。件数の一致と CPU 時間は見ず、順序を変える確認は `isolate: false` の候補だけ。候補は設定ファイルの `environment` から選ぶので、`// @vitest-environment jsdom` のコメントで指定しているリポジトリでは vm 系の pool を試さない。worker 数は子に渡らないので `VITEST_MAX_WORKERS=<n> vitest doctor` と書く。
- mutator は `pool: forks` と `isolate: true` を自分で指定する。pool や isolate を替えた影響は mutator では測れない。
- Playwright は自分でも `--enable-features=` を渡す。Chromium は同じ switch の最後の 1 つだけを使うので、Browser Mode の flag を足す時は Playwright の分も並べる。
- 高性能 core と高効率 core が混ざる Mac では、worker を増やすほど同じ仕事の CPU 時間が増える。A と B の worker 数を揃え、混んでいる時の値と空いている時の値を並べない。
- ts-jest の transpile のみは、cache が温まっていても効いた。効くのは 1 回目だけと決めつけない。
