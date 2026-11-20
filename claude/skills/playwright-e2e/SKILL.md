---
name: playwright-e2e
description: >-
  Implement and run Playwright end-to-end tests and browser UI verification efficiently. Use for web app flows, regression tests, screenshots, accessibility checks, 「E2E を書いて」「E2E が落ちた」「画面で確かめて」. Covers the step convention, what to do when a test fails, and three-valued results. Not for exploring an app without a script (exploratory-qa) or auditing unit tests (test-quality).
---

# playwright-e2e — Playwright CLI E2Eテスト

## なぜCLIか
- CLI はシェルから叩くので、ツールの定義を文脈に載せない。定型的な確認と E2E の下調べに向く。
- MCP は、ブラウザの状態を保ったまま探索的に考えさせる場面に向く。
- 文脈の消費の差は、測り方によってほとんど無いこともある。数字で選ばず、シェルとファイルが使えるなら CLI にする。

## セットアップ

```bash
npm install -g @playwright/cli@latest
npm install -D @playwright/test
npx playwright install chromium
```

`.gitignore` に追加:
```
.playwright-cli/
```

## ワークフロー

### Phase 1: 対話的フロー確認

```bash
# 1. セッション付きでブラウザを開く
playwright-cli -s=test open <URL>

# 2. スナップショットで要素ref取得
playwright-cli -s=test snapshot

# 3. 要素を操作（click/fill/type）
playwright-cli -s=test click <ref>
playwright-cli -s=test fill <ref> "テキスト"

# 4. 操作後のスナップショットで確認
playwright-cli -s=test snapshot

# 5. スクリーンショットで視覚確認（必要時のみ）
playwright-cli -s=test screenshot
```

### Phase 2: テストコード生成

Phase 1で確認したフローから `@playwright/test` のコードを実装。

```typescript
// e2e/example.spec.ts
import { test, expect } from "@playwright/test";

test("フロー名", async ({ page }) => {
  await page.goto("/");
  // Phase 1で取得したセレクタを使用
  await page.getByRole("button", { name: "ボタン名" }).click();
  await expect(page).toHaveURL(/expected-path/);
});
```

### Phase 3: 実行

```bash
npx playwright test --headed     # ブラウザ表示付き
npx playwright test              # ヘッドレス（CI用）
```

### Phase 4: Agentic UAT（AI実装の受け入れ検証）

AIエージェントが実装した機能は、通常のE2Eが通っても「ユーザーがUIから業務を完遂できない」漏れが残りやすい。重要フローでは、実装者視点の手順テストに加えて、擬似ユーザーとしてのUATを回す。

- ソースコード/API/既知URLを読ませず、ブラウザUIだけで操作させる
- 手順ではなく業務ゴールで指示する（例: 「新しいユーザーを登録し、有効状態にしてください」）
- ペルソナを分ける（初回担当者、熟練担当者、管理者など）
- 詰まった場所、迷ったUI、理解できないエラー、前工程からの引き継ぎ失敗を記録する
- 業務ゴールで指示しても、途中で見えた異常（想定と違う文言、表示の崩れ、エラー）は、完遂できたかどうかと別に報告させる。ゴールだけを指示すると、達成を優先して異常を報告しない
- 結果は「完遂可否 / 迷い / エラー / 改善提案」の表でPR・Issueに残す。残す前に、操作した側の報告を裏どりする（exploratory-qa の 6 節）

向いている場面: 登録・購入の導線、管理画面、申請フォームなど、業務ゴールの達成が重要な UI。観点の選び方（ツアー）と、操作した側の報告の裏どりは exploratory-qa にある。

## テストの決まり

### 書き方の決まり

E2E は「業務が最後までつながるか」だけを確かめる。金額の計算や入力の検証のように関数や API で確かめられるものは、unit test と API のテストに寄せる。

- **手順と期待値を `test.step` に書く。** 手順は「〜する」、期待値は「〜すること」。人がレビューするのは step の文だけで済むようにし、step の文と中の実装を常に合わせる。

  ```typescript
  await test.step("メールアドレスとパスワードでログインする", async () => {
    await page.getByLabel("メールアドレス").fill(user.email);
    await page.getByLabel("パスワード").fill(user.password);
    await page.getByRole("button", { name: "ログイン" }).click();
  });
  await test.step("ホーム画面が表示されること", async () => {
    await expect(page.getByRole("heading", { name: "ホーム" })).toBeVisible();
  });
  ```

- **操作と期待値を分ける。** 1 つの step に両方を入れない。
- **画面の状態を待つ。** 固定の待ち時間（`waitForTimeout`）を使わず、`expect(...).toBeVisible()` のように状態を待つ assertion を使う。
- **ロケータは、利用者に見えるもので取る。** 優先する順に、`getByRole`、`getByText`、`getByLabel`、`getByPlaceholder`、`getByAltText`、`getByTitle`、`getByTestId`。CSS と XPath は最後の手段。`first()` と `nth()`、生成された class 名、DOM の位置には頼らない。
- **テストは単独で通るようにする。** 他のテストが先に走る前提にしない。`test.describe.serial` は使わない。データは、実行ごと・テストごとに一意な値（実行の識別子と `testInfo.testId` の組み合わせなど）で作り、終わったら消す。同じアカウントや同じ行を、複数のテストで書き換えない。消せないデータを作る時は、先に人に確かめる。
- **外部のサービスは、実物を試さない。** ブラウザから出る通信は `page.route` で応答を差し替える。アプリのサーバーから決済やメールのサービスへ出る通信は `page.route` では止まらないので、サーバー側をテスト用の設定か差し替えにする。差し替えた応答が本物とずれていないかは、別の手段で確かめる。差し替えられないものは判定不能にする。
- **パスキーは仮想の認証器で通す。** `context.credentials`（Playwright 1.61 以降）を、最初のページが WebAuthn を使う前に入れる。
- **ログインは使い回す。** setup のプロジェクトでログインして `storageState` を保存し、ログインそのものを試すテスト以外はそれを使う。サーバー側の状態を書き換えるテストは、並列の worker ごとに別のアカウントにする。保存先（`playwright/.auth/`）は gitignore に入れ、中身を報告やログに貼らない。
- **画面の構造は `toMatchAriaSnapshot` で確かめられる。** 色や配置はスクリーンショットの比較で見る。基準の画像は CI と同じ環境で作る。どちらも、基準を更新する（`-u`）のは、差分を人が見てからにする。
- **機能と E2E を同じ PR に入れる。**
- 同じ指摘を 2 回したら、lint のルールにする。書く前に読む決まり（この skill）と、書いた後に機械で止める決まり（lint）の両方で守る。

### 失敗した時

1. **1 回だけ再実行する。** 通ったら flaky として、名前と件数を報告する。失敗が続くものだけを調べる。通るまで繰り返さない。CI の再試行（`retries`）は、失敗の痕跡（trace）を取るために使う。再試行で通ったテストを合格に数えない設定が `failOnFlakyTests`（コマンドラインでは `--fail-on-flaky-tests`）。
2. **原因を分ける。** テストの問題（ロケータ、待ち方、データ）／アプリの不具合／環境（ネットワーク、外部サービス）／データの準備。直近の変更のせいと決めつけず、過去の失敗の記録と環境を先に見る。
3. **根因を調べてから直す。** 直してよいのはロケータと待ち方まで。期待値（assertion）を弱めない、消さない、`skip` にしない、`waitForTimeout` や再試行の回数を足して通さない。
4. **期待値を変える必要がある時は、止めて人に見せる。** 仕様が変わったのか、アプリが壊れたのかは、テストを直す側には決められない。
5. **自動の修復を使う時は、修復の後の差分を検査する。** Playwright の healer や、モデルによる修復は、通すためにテストを skip にしたり、assertion を弱めたりすることがある。`expect` が減った、`skip`・`fixme` が増えた、テストが消えた、のどれかがあれば、その修復を採らずに人に見せる。修復が skip を提案したら、アプリが壊れた疑いとして報告する。
6. flaky の原因が見つからない時は、隠さずに未解決として報告する。テストを消すかどうかは人が決める。消す時は、理由と、代わりに何で確かめるかを書く。

### 結果は 3 値で書く

合格／不合格／判定不能。人の鍵や認証が要る、外部サービスが応答しない、環境が用意できない、という理由で確かめられなかったものは判定不能とし、理由を書く。判定不能を合格にも不合格にも数えない。

### ブラウザの扱い

- E2E は Playwright 同梱の Chromium で流す。ユーザーのログイン済みのブラウザを自動で操作しない。
- ブラウザの操作をサブエージェントに任せるのは、同梱の Chromium を隔離したプロファイルで使う時だけにする。人のブラウザを使う確認は exploratory-qa の「人と一緒に回すとき」に従う。
- 長い E2E はバックグラウンドで流し、出力の進み具合を見る。止まって見えても、報告する前に出力を確かめる。

## playwright.config.ts テンプレート

```typescript
import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  timeout: 30_000,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0, // 再試行は、失敗の痕跡（trace）を取るため
  failOnFlakyTests: !!process.env.CI, // 再試行で通ったテストを合格にしない
  use: {
    baseURL: process.env.BASE_URL || "http://localhost:3000",
    trace: "on-first-retry",
    screenshot: "only-on-failure",
    video: "retain-on-failure",
  },
  projects: [
    { name: "chromium", use: { browserName: "chromium" } },
  ],
});
```

## CLIコマンド一覧

現行の一覧は `playwright-cli --help` で確かめる。下は主なもの（2026-11-20 に公式ドキュメントで確認）。

| コマンド | 用途 |
|---|---|
| `open <url>` / `goto <url>` | ページを開く |
| `snapshot` | アクセシビリティツリー取得（ref付き） |
| `click <ref>` / `fill <ref> <text>` / `type <text>` / `press <key>` | 操作 |
| `screenshot [ref]` | スクリーンショット |
| `console` / `requests` | コンソールとネットワークの記録 |
| `route` / `unroute` | 応答の差し替え |
| `state-save` / `state-load` | ログイン状態などの保存と読み込み |
| `tracing-start` / `tracing-stop` | トレース記録 |
| `-s=<name>` | 名前付きセッション（環境変数 `PLAYWRIGHT_CLI_SESSION` でも指定できる） |
| `list` | セッションの一覧 |
| `close-all` / `kill-all` | 全ブラウザを閉じる／強制終了する |

## セッション終了

```bash
playwright-cli close-all
```

ヘッドレスのセッションは、1 時間操作が無いと自動で閉じる。出力先の `.playwright-cli/` を消す時は、自分のセッションが作ったものだけを消す。

## プロジェクト導入チェックリスト

1. [ ] `@playwright/cli` グローバルインストール
2. [ ] `@playwright/test` + `chromium` devDependencies
3. [ ] `playwright.config.ts` 作成
4. [ ] `e2e/` ディレクトリ作成
5. [ ] `.gitignore` に `.playwright-cli/` 追加
6. [ ] CI設定（GitHub Actions等）に `npx playwright test` 追加。件数が増えたら `--shard` で分け、blob reporter の結果を `merge-reports` でまとめる。失敗した時も、レポートと trace を成果物として残す

## 関連 skill

- exploratory-qa: スクリプトなしでアプリを操作して探す。人と一緒に回す進め方
- test-quality: E2E 以外のテストの型と、テストが壊れを見つけられるかの検品
- create-verification-skill: アプリの起動と操作の手順を、プロジェクトの skill として残す
- merge-gate: E2E の結果をマージの根拠に使う時の判定

## 出典

- Playwright 公式ドキュメント（2026-11-20 に確認。現行は 1.65）: Best Practices https://playwright.dev/docs/best-practices 、Locators https://playwright.dev/docs/locators 、Authentication https://playwright.dev/docs/auth 、Retries https://playwright.dev/docs/test-retries 、Test Agents https://playwright.dev/docs/test-agents 、CLI https://playwright.dev/docs/getting-started-cli 、Credentials https://playwright.dev/docs/api/class-credentials
- 「Practical Limits of Autonomous Test Repair」https://arxiv.org/abs/2605.01471 （自動の修復が、assertion を弱める・テストを消すことで見かけ上通す事例。1 件の事例報告）
- 小島 大周「E2E Test というハーネス — AI時代の自動テスト民主化」https://speakerdeck.com/daishukojima/ttf2026-e2e-test-harness （step の決まり、skill と lint の二段構え。2026-11-20 参照。独自に要約した）
- Addy Osmani「How the Claude Code team thinks about verification」https://claude.dev/blog/how-the-claude-code-team-thinks-about-verification/ （flaky の扱い）
