# Harness Engineering リファレンス
> Source: @gyakuse「Claude Code / Codex ユーザーのための誰でもわかるHarness Engineeringベストプラクティス」(2026-03)

## コアコンセプト

**ハーネス = Coding Agentの補助輪。** 同じモデルでもハーネスを変えるだけでSWE-benchスコアが22pt変動する（モデル交換は1pt）。プロンプトではなく仕組みで品質を強制する。

## 1. Claude Code Hooks テンプレート

### PostToolUse: 自動リント（ファイル編集のたびに実行）
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'FILE=$(jq -r \".tool_input.file_path // .tool_input.path\" <<< \"$(cat)\"); case \"$FILE\" in *.ts|*.tsx|*.js|*.jsx) npx biome format --write \"$FILE\" 2>/dev/null; npx oxlint --fix \"$FILE\" 2>&1 | head -20;; *.py) ruff format \"$FILE\" 2>/dev/null; ruff check --fix \"$FILE\" 2>&1 | head -20;; *.go) gofumpt -w \"$FILE\" 2>/dev/null; golangci-lint run --fix \"$FILE\" 2>&1 | head -20;; esac'"
          }
        ]
      }
    ]
  }
}
```

### PreToolUse: リンター設定保護（エージェントのルール改竄防止）
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'FILE=$(jq -r \".tool_input.file_path // .tool_input.path\" <<< \"$(cat)\"); PROTECTED=\".eslintrc eslint.config biome.json pyproject.toml .prettierrc tsconfig.json lefthook.yml .golangci.yml Cargo.toml .swiftlint.yml .pre-commit-config.yaml\"; for p in $PROTECTED; do case \"$FILE\" in *$p*) echo \"BLOCKED: $FILE is a protected config file. Fix the code, not the linter config.\" >&2; exit 2;; esac; done'"
          }
        ]
      }
    ]
  }
}
```

### Stop: Completion Gate（テスト通過を完了条件に）
```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'if [ -f package.json ]; then npm test 2>&1 | tail -30; elif [ -f pyproject.toml ] || [ -f setup.py ]; then pytest 2>&1 | tail -30; elif [ -f go.mod ]; then go test ./... 2>&1 | tail -30; elif [ -f Cargo.toml ]; then cargo test 2>&1 | tail -30; fi'"
          }
        ]
      }
    ]
  }
}
```

## 2. AGENTS.md / CLAUDE.md 設計原則

### 書くもの（ポインタのみ、50行以下が理想）
- ビルド・テスト・デプロイの最低限コマンド
- 禁止事項一覧（各項目にADR/リンタールール参照）
- スキル・MCP接続へのポインタ

### 書かないもの
- システムの現状説明（コードとテストが真実）
- 技術スタック解説（package.json/go.modを読める）
- 冗長なコーディングスタイルガイド（リンターに委ねる）

### なぜ短く？
- 150指示超でprimacy bias発生、性能劣化（IFScale研究）
- Claude Codeのシステムプロンプト自体が約50指示 → CLAUDE.md 100行で計150指示 → 限界域

## 3. リポジトリ衛生

### 置くべきもの
- 実行可能なアーティファクト（コード、テスト、リンター設定、型定義、スキーマ、CI設定）
- ADR（Architecture Decision Records）— 不変、ステータス明示

### 置くべきでないもの
- 「現在のシステムはこう」な説明文書（必ず腐敗する）
- 手書きのAPI説明、アーキテクチャ概要テキスト

### テスト > ドキュメント
テストは嘘をつけない。仕様・期待動作・制約はテストとして表現する。エージェントのミスが起きるたびに、それを防ぐテストを追加する。

## 4. フィードバック速度の階層

| 速度 | レイヤー | 手法 |
|------|---------|------|
| ms | PostToolUse Hook | フォーマッター自動実行 |
| s | プリコミットフック | リンター・型チェック |
| min | CI/CD | 全テストスイート |
| h〜day | 人間レビュー | マージ後 |

**目標:** できるだけ多くのチェックをより速いレイヤーに移動させる。

## 5. 言語別推奨リンタースタック（2026年3月）

| 言語 | PostToolUse (ms) | プリコミット (s) | CI (min) |
|------|-----------------|-----------------|----------|
| TS/JS | Biome format → Oxlint | Lefthook → Oxlint + tsc | ESLint(カスタム) + テスト |
| Python | Ruff check --fix → format | Lefthook → Ruff + mypy | Ruff + mypy + pytest |
| Go | gofumpt + golangci-lint | Lefthook → golangci-lint --fix | golangci-lint(フル) + go test |
| Rust | rustfmt | cargo clippy (pedantic) | cargo clippy + cargo test |

## 6. AI生成コードのアンチパターン（要警戒）

- **any乱用:** 型推論失敗→anyに逃げる。`no-explicit-any` error強制
- **コード重複:** 既存コード検索せず新規生成。jscpd等で検知
- **ゴーストファイル:** 既存ファイル修正の代わりに似た名前の新ファイル作成
- **コメント洪水:** AI生成リポの90-100%で観察
- **セキュリティ脆弱性:** AI生成コードの36-40%に含まれる（Snyk調査）

## 7. エラーメッセージ = 修正指示

カスタムリンターのエラーメッセージには修正方法を含める：
```
ERROR: [何が間違っているか]
  [ファイル:行番号]
WHY: [なぜこのルールがあるか、ADR参照]
FIX: [具体的な修正手順、コード例]
```

## 8. Codex vs Claude Code ハーネス差分

| | Claude Code | Codex |
|---|---|---|
| フック | PreToolUse/PostToolUse/Stop（毎アクション介入） | notifyのみ（完了時のみ） |
| 実行環境 | ローカル（作業場型） | クラウドサンドボックス（密室型） |
| 並列 | Agent Teams（実験的） | 非同期タスクキュー（本番対応） |
| 最適用途 | 品質重視（Hooksで決定論的ゲート） | スループット重視（並列サンドボックス） |

**ハイブリッド:** Claude Codeで計画・設計 → Codexで並列実行 → Claude Codeでレビュー

## 9. MVH（最小実行可能ハーネス）段階的導入

### Week 1
- AGENTS.md作成（50行以下、ポインタのみ）
- プリコミットフック（Lefthook）でリンター実行
- PostToolUse Hookで自動フォーマット

### Week 2-4
- エージェントのミス → テスト/リンタールール追加
- 計画→承認→実行ワークフロー確立
- Stop Hookでテスト通過を完了条件に

### Month 2-3
- カスタムリンター構築（エラーメッセージに修正指示）
- ADR導入、リンタールールとの紐づけ
- 記述的ドキュメント → テスト+ADRに置換
