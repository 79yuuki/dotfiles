# Progressive Disclosure最適化

SKILL.mdのトークン消費を40-45%削減するための構造パターン。

## 原則
- **SKILL.md本体は軽量に:** 概要・ルーティング・判断ロジックのみ記載
- **詳細はreferences/に分離:** 手順・チェックリスト・テンプレートはオンデマンド読み込み
- **Troubleshootingセクション追加:** よくあるエラーと対処法を明記

## 構造

```
skills/<skill-name>/
├── SKILL.md          ← 軽量エントリーポイント
│   - 概要（何を・なぜ・いつ使うか）
│   - ルーティングロジック（タスク分類→参照先指定）
│   - 判断基準（いつどのreferencesを読むか）
│   - Troubleshooting（よくある問題と対処）
├── references/       ← 詳細（必要な時だけ読む）
│   ├── workflow-detail.md
│   ├── checklist.md
│   ├── templates.md
│   └── troubleshooting.md
└── scripts/          ← 実行スクリプト
```

## SKILL.mdでの参照指示の書き方

```markdown
## ワークフロー
1. データ収集 → 詳細: [references/data-collection.md](references/data-collection.md)
2. 分析実行 → 詳細: [references/analysis.md](references/analysis.md)
```

エージェントが必要な時だけreferencesを読み込む形にすることで、
初期読み込みのトークン消費を大幅に削減できる。

## チェック項目
- [ ] SKILL.md本体が200行以内に収まっているか
- [ ] 詳細な手順はreferences/に分離されているか
- [ ] 各references/ファイルへの参照パスが正しいか
- [ ] Troubleshootingセクションがあるか

## 参考
- Anthropic Skills構築ガイド
- @shocolt実測: references/分離でトークン40-45%削減
