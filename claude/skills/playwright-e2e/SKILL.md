---
name: playwright-e2e
description: >-
  Implement and run Playwright end-to-end tests and browser UI verification efficiently. Use for web app flows, regression tests, screenshots, accessibility checks, and agentic QA when browser behavior must be verified.
---

# playwright-e2e — Playwright CLI E2Eテスト

## なぜCLIか
- MCP: コンテキスト約8%増加（ツール定義ロード）
- CLI: コンテキスト約1.3%（bashコマンドのみ）
- 定型的なE2Eテストには CLI + Skills が最適

## セットアップ

```bash
npm install -g @playwright/cli
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
playwright-cli --session=test open <URL>

# 2. スナップショットで要素ref取得
playwright-cli --session=test snapshot

# 3. 要素を操作（click/fill/type）
playwright-cli --session=test click <ref>
playwright-cli --session=test fill <ref> "テキスト"

# 4. 操作後のスナップショットで確認
playwright-cli --session=test snapshot

# 5. スクリーンショットで視覚確認（必要時のみ）
playwright-cli --session=test screenshot
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
- 結果は「完遂可否 / 迷い / エラー / 改善提案」の表でPR・Issueに残す

向いている場面: the product/the productの登録・購入・クリエイター導線、x402 Dashboard、管理画面、採用/査定フォームなど、業務ゴール達成が重要なUI。

## playwright.config.ts テンプレート

```typescript
import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  timeout: 30_000,
  use: {
    baseURL: process.env.BASE_URL || "http://localhost:3000",
    screenshot: "only-on-failure",
    video: "on",
  },
  projects: [
    { name: "chromium", use: { browserName: "chromium" } },
  ],
});
```

## CLIコマンド一覧

| コマンド | 用途 |
|---|---|
| `open <url>` | ページを開く |
| `snapshot` | アクセシビリティツリー取得（ref付き） |
| `click <ref>` | 要素クリック |
| `fill <ref> <text>` | テキスト入力 |
| `type <text>` | キーボード入力 |
| `screenshot [ref]` | スクリーンショット |
| `close` | ページを閉じる |
| `--session=<name>` | 名前付きセッション |
| `session-stop-all` | 全セッション停止 |
| `tracing-start/stop` | トレース記録 |
| `console [min-level]` | コンソールログ |

## セッション終了

```bash
playwright-cli session-stop-all
rm -rf .playwright-cli/
```

## プロジェクト導入チェックリスト

1. [ ] `@playwright/cli` グローバルインストール
2. [ ] `@playwright/test` + `chromium` devDependencies
3. [ ] `playwright.config.ts` 作成
4. [ ] `e2e/` ディレクトリ作成
5. [ ] `.gitignore` に `.playwright-cli/` 追加
6. [ ] CI設定（GitHub Actions等）に `npx playwright test` 追加
