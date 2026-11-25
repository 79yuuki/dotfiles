# 隔離を弱める候補の、汚染の検査と検出力の確認

目次: 何が残るか / 汚すファイルを見つける / 仕組み / 分け方 / 検出力

## 何が次のファイルに残るか

同じ worker で A → B の順に流し、A が汚したものを B が見た。Vitest 5.1.1・jsdom 26.1.0・happy-dom 21.0.4・Node 26.12 で確かめた（2026-11-25）。「残る」= B から見えた。`isolate: true` の forks・threads と Browser Mode は、どれも残らない（Browser Mode の環境変数は対象外）。

| | global への代入・`vi.stubGlobal` | DOM の prototype（`HTMLElement.prototype`） | 言語の prototype（`Array.prototype`） | `process.env`・`vi.stubEnv` | Node 側の class と module（下の注） | fake timers | `vi.spyOn` |
|---|---|---|---|---|---|---|---|
| vmThreads / vmForks + node | 戻る | — | 戻る | **残る** | **残る** | 戻る | 戻る |
| vmThreads / vmForks + jsdom | 戻る | 戻る | 戻る | **残る** | **残る** | 戻る | 戻る |
| vmThreads / vmForks + happy-dom | 戻る | **残る** | 戻る | **残る** | **残る** | 戻る | 戻る |
| forks / threads の `isolate: false` | **残る** | **残る** | **残る** | **残る** | **残る** | **残る** | 戻る |
| Browser Mode の `isolate: false` | **残る** | **残る** | **残る** | — | — | **残る** | **残る** |

注: vm 系の pool で、context を作り直しても同じ物が渡される。`process`（listener を含む）、`node:fs` などの組み込み module、`Response`・`Headers`・`AbortController`・`TextEncoder`・`Buffer` などの prototype。node 環境では `crypto` と `performance` も同じ。どれが共有されるかは environment で変わる。

`vi.mock` と module の状態:

| | mock した module を直接 import | mock した module を使う別の module | module の変数（数え上げなど） |
|---|---|---|---|
| vmThreads / vmForks、`isolate: true` | 戻る | 戻る | 戻る |
| forks / threads の `isolate: false` | 戻る | **先に評価された版で固まる** | **残る** |
| Browser Mode の `isolate: false` | **固まる** | **固まる** | **残る** |

固まり方は順序で逆になる。mock するファイルが先なら、後のファイルは mock を見る。mock しないファイルが先なら、後のファイルの mock が効かない。後者は、mock が効かないまま通るテストがあれば気づけない。

ほかの版では結果が違いうる。使う版で、上と同じ 2 ファイルを作って流せば数分で確かめられる。

## 汚すファイルを見つける

今の設定（隔離あり）のまま 1 回流せばよい。各ファイルの始まりと終わりを比べるので、順序にも pool にもよらない。

1. 使い捨ての worktree に、[../assets/leak-probe.setup.mjs](../assets/leak-probe.setup.mjs) をプロジェクトのルートへ写し、一時設定を作る。probe は `setupFiles` の**先頭**に置く（後始末が最後に走る。`mergeConfig` に渡すと末尾に付く）。設定が関数なら先に呼んで値にする。`projects` がある設定では、project ごとの `setupFiles` の先頭に足す。

   ```ts
   import { mergeConfig } from "vitest/config";
   import base from "./vitest.config.ts";
   const config = mergeConfig(base, { test: {} });
   config.test.setupFiles = ["./leak-probe.setup.mjs", ...[config.test.setupFiles ?? []].flat()];
   export default config;
   ```

   既存の setup が足すものは、全ファイルに出る。共通の項目を除いて読む。

2. `LEAK_PROBE_OUT=/tmp/leaks.jsonl npx vitest run --config <一時設定>` を流し、`leaks` が空でないファイルを並べる。実行したファイル数と行数が合うことも見る。vm 系の pool に替える時に問題になるのは、上の表で「残る」もの（`env.`、`process`、`node:`、Node 側の class の prototype、happy-dom なら DOM の prototype）だけ。
3. 見えないものは別に見る。**probe が空でも、汚さない証拠にはならない。**
   - `vi.mock` / `vi.doMock` / `vi.resetModules` を使うファイル: grep で並べる。`isolate: false` のまとまりには入れない。
   - module の変数、object の中身の書き換え（`config.flag = true`）、probe の一覧に無い組み込み module: 順序を変えた繰り返しで見る。`isolate: false` では 3 回で足りると思わない。
   - 残った timer や handle: `--detectAsyncLeaks`（Vitest 4.1 以降）。
   - Browser Mode: probe は動かない。`isolate: false` は、`vi.mock`・spy・fake timers・global・prototype を触らないことを grep で確かめたファイルだけに限る。
   - `sequence.hooks` を既定（`stack`）から替えているプロジェクトでは、probe が最後に走らない。
4. 汚すファイルは、後始末を足して直すか、隔離したまとまりに残す。`unstubGlobals: true`、`unstubEnvs: true`、`restoreMocks: true` は、書いた本人の後始末の漏れを減らすだけで、直接の代入は戻さない。

Jest は module の登録をファイルごとに作り直すので、`isolate: false` にあたる設定は無い。

## 仕組み

後から足されるテストが約束を破った時に、黙って通らないようにする。

- **vm 系の pool**: 落ち方の多くは目に見える。見えないのは `process.env` なので、次の setup をルートの `setupFiles` の先頭に足し、ファイルの終わりに自動で戻す（`extends: true` の project に書くと、ルートの setup の後ろに付き、最後に走らない）。

  ```ts
  import { beforeAll } from "vitest";
  const before = { ...process.env };
  // beforeAll が返す関数は、afterAll とほかの後始末の後に走る
  beforeAll(() => () => {
    for (const key of Object.keys(process.env)) if (!(key in before)) delete process.env[key];
    Object.assign(process.env, before);
  });
  ```

- **happy-dom + vm 系の pool**: DOM の prototype の書き換えは戻らない。prototype を触るファイルは forks に残すか、jsdom にする。
- **`isolate: false`**: 自動で戻す方法は無い。置き場所を決め、その中で `vi.mock`・`vi.doMock`・`process.env` への代入・prototype への代入を lint で禁じられる時だけ使う。

## 分け方

全体で外さず、外してよいファイルだけを `projects` で分ける。

- **`isolate: false`**: 外す側に入れる条件は、node 環境、`vi.mock` 系を使わない、probe で空、順序を変えて同じ結果。外す側を `include` で書く。`exclude` で残りを全部外す側にすると、後から足された汚すテストが黙って入る。
- **vm 系の pool**: file ごとの context は残るので、vm を残り全部の側にし、落ちるファイルを forks の側に並べてよい（[candidates.md](candidates.md) の「vm 系の pool」）。
- **environment**: 分からないものが落ちて気づく側を、残り全部の側にする。既定が jsdom なら、node の側を `include` で書く。
- 分けた後の集合が元と同じことを `ab.py` で確かめる。どちらにも入らないファイルは、黙って走らなくなる。JSON の報告には project の名前が無いので、ファイルがどちらの project で走ったかは `vitest list --filesOnly --project <名前>` で見る。

```ts
export default defineConfig({
  test: {
    projects: [
      { extends: true, test: { name: "pure", include: ["src/domain/**/*.test.ts"], isolate: false } },
      { extends: true, test: { name: "default", include: ["src/**/*.test.ts"], exclude: [...configDefaults.exclude, "src/domain/**"] } },
    ],
  },
});
```

## 検出力

速くなった設定でも、壊れたコードで同じように落ちることを見る。範囲は、替えた設定で走るテストが守る小さなファイル 1〜3 個、変異 20〜50 個でよい。mock を使うテストが守るファイルを 1 つ入れる。

- **environment を替えた時**（Vitest）: mutator を A・B の設定で 1 回ずつ回し、変異ごとの判定を比べる（コマンドの選び方と後片付けは `mutation-before-pr` skill）。

  ```bash
  mutator --include 'src/ui/dialog.ts' --config vitest.a.config.ts --reporter json --report-dir "$TMP/a"
  mutator --include 'src/ui/dialog.ts' --config vitest.b.config.ts --reporter json --report-dir "$TMP/b"
  ```

  A と B の間で `<root>/.mutator` を消す（残すと前の判定を使い回す）。合格は、変異の集合が A と B で同じで、Pending が無く、B で新しく Survived / NoCoverage になった変異が 0 件。
- **pool・isolate・変換を替えた時、Jest の時**: mutator は `pool: forks` と `isolate: true` を自分で指定し（0.5.3 のソースで確認）、CommonJS の Jest は扱えないので、変異を手で当てる。
  1. 変異を 10〜20 個選ぶ。mutator の報告（`mutation.json`）の Killed から取るか、条件の反転・境界・戻り値・呼び出しの削除を自分で書く。
  2. 変異を当てる前に、関係するテスト（`vitest related <file> --run`、Jest は `--findRelatedTests <file>`）が A・B の両方で通ることを見る。`vitest related` は複数ファイルを同じ worker で流すように `--maxWorkers` を絞る。
  3. 1 つずつ当てて A と B を流し、**両方とも assertion で落ちる**ことを見る（import や起動の失敗で落ちたものは数えない）。毎回ファイルを戻し、最後に `git status` で確かめる。
