# 候補の選び方と、版ごとの設定

## 目次

1. 版の対応表（旧 → 現行）
2. 支配的な所ごとの候補
3. Browser Mode
4. Jest / ts-jest
5. 公開の数字と、手元で再現したもの
6. 出典

## 1. 版の対応表（旧 → 現行）

| 旧 | 現行 | 変わった版 |
|---|---|---|
| `environmentMatchGlobs` / `poolMatchGlobs` | `projects`（または `// @vitest-environment` のコメント） | Vitest 4 で削除 |
| `poolOptions.forks.isolate` など | 最上位の `isolate`・`execArgv`・`vmMemoryLimit` | Vitest 4 |
| `maxThreads` / `maxForks`、`VITEST_MAX_THREADS` / `VITEST_MAX_FORKS` | `maxWorkers`、`VITEST_MAX_WORKERS` | Vitest 4 |
| `singleThread` / `singleFork` | `maxWorkers: 1, isolate: false` | Vitest 4 |
| `experimental.fsModuleCache`（既定は無効） | `fsModuleCache`（既定は有効） | Vitest 5 |
| `browser.isolate` | 最上位の `isolate` | Vitest 5 で警告 |
| JSON reporter は標準出力 | `.vitest/json/output.json`（`--outputFile` を書けばその場所） | Vitest 5 |
| `Duration` の括弧は秒 | 括弧は割合（%） | Vitest 5 |
| `clearMocks: false` が既定 | `true` が既定 | Vitest 5 |
| ts-jest の config の `isolatedModules: true` | tsconfig の `isolatedModules: true`（テスト用の tsconfig を分けてもよい）。`transpilation` は 29.4.3 で入り、29.4.4 で撤回された | ts-jest 29.3 で非推奨 |

`vitest doctor`、実行後の hint、`vmThreads` / `vmForks` の大きな高速化は Vitest 5 から。5 は Vite 6.4 以上と Node 22.12 以上が要る。版を上げること自体を候補にする時は、他の候補と混ぜず、先に単独で測る。

## 2. 支配的な所ごとの候補

| 候補 | 効く場面 | 失うもの・確かめること |
|---|---|---|
| DOM を使わないファイルを node に分ける | `environment` が大きい。設定の既定が jsdom | `typeof window` で分岐するコードは、node では別の枝を通る。分けたファイルが DOM を触らないことを、落ちることで確かめる（既定を node にして、落ちたものだけ jsdom） |
| `setupFiles` を DOM のファイルだけに | `setup`・`import` が大きい | 拡張 matcher や global の後始末が、要るファイルから消えないか |
| 重い import を狭める | `import` が大きい | `--experimental.importDurations.print`（Vitest 4.1 以降）で重い module を見つける。barrel（`index.ts`）経由の import を直接の import に変える。ソースを変える時は通常の PR と同じ確認 |
| `pool: 'threads'` | 隔離を保ったまま、process の起動を減らす | `process.chdir()` が使えない。`process.env.TZ` の変更が効かない。native の addon が落ちることがある |
| `pool: 'vmForks'` / `'vmThreads'`（下の「vm 系の pool」） | `environment` と `import` が大きい。DOM のファイルが多い | file ごとの隔離は残るが、`process.env` と Node 側の class は worker で共有。realm の違いで落ちるテストがある。メモリが増え、上限（`vmMemoryLimit`）で worker が作り直される |
| `isolate: false` | node 環境で、純粋な関数のテストが多い | すべて共有。[isolation.md](isolation.md) の検査を通ったファイルだけに限る |
| happy-dom | `environment` が大きい。jsdom を使うファイルが多い | 同じ DOM ではない。有無の違いは両方向（jsdom に無くて happy-dom にある API に、テストが頼っていることもある）。どちらもレイアウトは無く、「押せるか」は確かめない |
| `maxWorkers` を減らす | 変換が 1 本の Vite server に集まって詰まる。core の少ない CI | 実時間と CPU の両方を見る |
| `NODE_COMPILE_CACHE` | 手元の繰り返し、cache を残す CI | 空の cache の 1 回目は遅い。v8 coverage では無効 |
| `tests` の中の実時間の待ち | 遅いテストの上位が `setTimeout` や retry の待ち。実時間の下限になる | fake timers に替え、待ちの長さを assertion で残す（終わる 1 ms 前に次が始まっていないことまで見る）。待ち自体を消すと、待つことの検証が消える |
| shard | 1 台で縮まず、CI の台数を増やせる | 合計の CPU は増える。時間は縮んでも費用は増える |

coverage、`--reporter`、`globalSetup`（DB や server の起動）、`dir` / `include` の広すぎる探索が重いこともある。外して測り、差で重さを出す。

### vm 系の pool（試す価値が大きく、確かめることも多い）

jsdom と依存の読み込みが worker で 1 回になり、file ごとに新しい vm context を作る。Vitest 5 で大きく速くなった。大きい suite では、process ごと回収できる `vmForks` を先に試す（公式 docs の勧め）。

1. `--pool=vmForks` で 1 回流し、落ちたファイルを並べる。落ち方は多くが次の型（Vitest 5.1.1 で再現した）。
   - `vi.stubGlobal("location", …)` が `Cannot redefine property: location`
   - jsdom の `window` に `crypto.subtle` が無い（forks では Node の `crypto` が見えていた）
   - Node が投げた Error や `DOMException` が `instanceof Error`・`expect.any(Error)` にならない
   - `await response.json()` などの戻り値が `toStrictEqual` で一致しない
2. 落ちたファイルと、probe で Node 側の class や module を汚すと出たファイル（[isolation.md](isolation.md)）だけを、元の pool に残す。環境変数は、同じ reference の setup で戻す。テストは書き換えなくてよい。

   ```ts
   import { configDefaults, defineConfig } from "vitest/config";
   const needsOwnProcess = ["src/a.test.ts"]; // 理由を 1 行ずつ書く
   export default defineConfig({
     test: {
       setupFiles: ["./test/restore-env.ts"], // 既存の setup はこの後ろに並べる
       projects: [
         { extends: true, test: { name: "vm", pool: "vmForks", include: ["src/**/*.test.{ts,tsx}"], exclude: [...configDefaults.exclude, ...needsOwnProcess] } },
         { extends: true, test: { name: "process", pool: "forks", include: needsOwnProcess } },
       ],
     },
   });
   ```

3. 残すファイルが多い（目安は 1 割より多い）なら、`pool: 'threads'` だけにする。隔離を弱めずに済み、伸びは小さい。
4. メモリを前後で見る。`/usr/bin/time -l`（Linux は `-v`）の最大 RSS は、一番大きい process 1 つの値。forks 系ではおよそ worker 1 つの最大、threads 系では全 worker の合計になる。forks 系はこの値 × worker 数が、CI のメモリに収まること。

## 3. Browser Mode

Browser Mode の実時間は、CPU より待ち（iframe の準備、module の取得、入力ごとのフレーム待ち）が中心になりやすい。CPU 時間が同じくらいなのに実時間が長い時は、待ちを疑う。

- **Vitest 5.1.1 以降に上げる。** `vitest run` の間は、変換済みの module を browser の cache から読み、iframe ごとの 304 の確認が無くなる（vitest#11914）。watch、`persistentContext`、preview provider、request の横取りで mock する時は対象外。Playwright の Firefox では大きい suite が遅くなる、と同じ PR に書かれている。
- **入力の後の 1 フレーム待ちを外す（Chromium だけ）。** `launchOptions.args` に渡す。プロジェクトの設定だけで効かせ、ブラウザ全体の設定にしない。

  ```ts
  playwright({
    launchOptions: {
      args: ["--enable-features=CDPScreenshotNewSurface,DeferRendererTasksAfterInput:policy/minimal-types"],
    },
  })
  ```

  Chromium は同じ switch が複数あると最後の値だけを使うので、Playwright が自分で渡す feature（版で変わる。`chromiumSwitches.ts` を見る）を先に並べる。Chromium の内部の設定なので、版を上げる時に効き続けているかを測り直す。画面の更新の順序が利用者の環境と変わるので、入力の直後の表示を見るテストは結果を見比べる。
- 並列を増やすと待ちは隠れ、CPU の取り合いが表に出る。worker 1 と普段の worker 数の両方で測る。

## 4. Jest / ts-jest

Jest はファイルごとに vm context を作り、worker の process は使い回す。`isolate` にあたる設定は無い。

| 候補 | 効く場面 | 失うもの・確かめること |
|---|---|---|
| ts-jest を transpile のみにする（cache が温まっていても効くことがある） | cache の無い 1 回目（CI）が遅い。`--no-cache` の差が大きい | 型検査をしなくなる。`const enum` や型だけの re-export の扱いが変わる。`tsc --noEmit` がテストのファイルも含めて CI で走ることを確かめる |
| 変換の cache を CI に残す | 同上 | `jest --showConfig` の `cacheDirectory` を保存する。key に lockfile・設定・runner の版を入れる |
| `maxWorkers` | 既定は core 数 − 1 | 各 worker が ts-jest の language service を持つとメモリを使い切る。減らした方が速いことがある |
| `workerIdleMemoryLimit` | 後半だけ遅い・swap が出る | worker の作り直しの費用 |

ts-jest を swc や esbuild に替えるのは依存の追加で、decorator の metadata や `jest.mock` の巻き上げの扱いも変わる。transpile のみで足りるかを先に見る。

## 5. 公開の数字と、手元で再現したもの

資料は ypresto「The Cost of the DOM」（JSConf JP 2026、Apple M4 Pro 14 core、Vitest 5.1.x）。ここの数字は傾向の目安で、プロジェクトの見込みには使わない。**自分のプロジェクトで測る。** 手元は Apple M5（4 + 6 core）、Vitest 5.1.1、Node 26.12、Playwright 1.62.1、各 3 回以上の中央値（2026-11-25）。

空のテスト 32 ファイル・1 worker の実時間（秒）。起動の費用だけの比較で、テスト本体が重い suite では差の割合が小さくなる。

| environment | forks（既定） | threads | vmForks | vmThreads | forks `isolate: false` |
|---|---|---|---|---|---|
| node | 1.75 | 1.19 | 0.59 | 0.57 | 0.34 |
| happy-dom | 4.10 | 3.48 | 0.71 | 0.69 | 0.41 |
| jsdom | 4.85 | 4.19 | 0.75 | 0.72 | 0.45 |

資料の主張のうち、再現したもの。

| 主張 | 手元 |
|---|---|
| 隔離の費用が大きい（空のテスト 32 ファイルで、既定 8.94 秒・vmThreads 1.20 秒） | 上の表 |
| Browser Mode の同じ題材は isolate true 2.02 秒・false 1.38 秒 | 1.51 秒・0.77 秒 |
| happy-dom + vmThreads は DOM の prototype が残り、jsdom + vmThreads は残らない | 同じ。加えて、どちらも `process.env` と Node 側の class が残る |
| Browser Mode の `isolate: false` は `vi.mock` が最初の版で固まる | 同じ。加えて、forks / threads の `isolate: false` でも、間に挟まる module は固まる |
| Vitest 5.1.1 で module の再確認が無くなった | 253 module を import する 24 ファイル・2 worker で、5.1.0 の 1.77 秒 → 5.1.1 の 1.28 秒（CPU 5.4 → 3.3 秒） |
| `userEvent.click()` は約 50 ms、キー入力は約 1 フレーム（16.7 ms） | 50.4 ms・17.0 ms |
| `DeferRendererTasksAfterInput:policy/minimal-types` で入力の後の待ちが消える | click 33.8 ms・キー 1.4 ms。suite 全体での効果は自分で測る |

## 6. 出典

- 資料: <https://speakerdeck.com/ypresto/the-cost-of-the-dom>
- Vitest 5.1.1 docs: [Improving Performance](https://vitest.dev/guide/improving-performance)、[pool](https://vitest.dev/config/pool)、[isolate](https://vitest.dev/config/isolate)、[fsModuleCache](https://vitest.dev/config/fsmodulecache)、[vitest doctor](https://vitest.dev/guide/cli#vitest-doctor)、[migration](https://vitest.dev/guide/migration)
- Browser Mode の cache: [vitest#11914](https://github.com/vitest-dev/vitest/pull/11914)（5.1.1）
- Chromium: [features.cc](https://github.com/chromium/chromium/blob/main/third_party/blink/common/features.cc) の `kDeferRendererTasksAfterInput`（既定で有効、policy の既定は all-types）、[command_line.h](https://github.com/chromium/chromium/blob/main/base/command_line.h)（同じ switch は最後の値）
- Playwright: [chromiumSwitches.ts](https://github.com/microsoft/playwright/blob/main/packages/playwright-core/src/server/chromium/chromiumSwitches.ts)
- [ts-jest CHANGELOG](https://github.com/kulshekhar/ts-jest/blob/main/CHANGELOG.md)、[Jest CLI](https://jestjs.io/docs/cli)
