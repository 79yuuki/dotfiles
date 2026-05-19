---
marp: true
theme: default
paginate: true
backgroundColor: #0f172a
color: #e2e8f0
style: |
  section {
    font-family: 'Hiragino Mono', 'Courier New', monospace;
    font-size: 24px;
    background-color: #0f172a;
    color: #e2e8f0;
  }
  h1 { color: #38bdf8; border-bottom: 2px solid #38bdf8; }
  h2 { color: #38bdf8; }
  strong { color: #34d399; }
  code { background: #1e293b; color: #34d399; padding: 2px 6px; border-radius: 4px; }
  pre { background: #1e293b; border: 1px solid #334155; }
  table { font-size: 20px; }
  th { background: #1e40af; color: white; }
  td { background: #1e293b; }
  section.cover {
    text-align: center;
    background: linear-gradient(135deg, #0f172a 0%, #1e3a5f 100%);
  }
  blockquote { border-left: 4px solid #38bdf8; padding-left: 16px; color: #94a3b8; }
---

<!-- _class: cover -->

# [技術名 / システム名]

## [サブタイトル：何を説明するか]

<br>

対象: [エンジニア / CTO / 技術担当]
[発表者名] | YYYY年MM月DD日

---

## TL;DR

**3行まとめ**

1. **[技術的ポイント1]** → [数字・効果]
2. **[技術的ポイント2]** → [数字・効果]
3. **推奨**: [アクション]

<br>

> 詳細は以降のスライドで説明します

---

## 現状の技術課題

**現状システムの問題**

```
[現状アーキテクチャ図 or テキスト表現]
```

| 課題 | 影響 | 深刻度 |
|-----|-----|-------|
| [課題1] | [影響] | 🔴 高 |
| [課題2] | [影響] | 🟡 中 |
| [課題3] | [影響] | 🟡 中 |

---

## 提案アーキテクチャ

```
[Client]
    │
    ▼
[API Gateway] ─── [Auth Service]
    │
    ├── [Service A]
    ├── [Service B]
    └── [Service C]
            │
            ▼
       [Database]
```

**技術スタック**: [言語] / [インフラ] / [ミドルウェア]

---

## 技術詳細

**[コア技術名] の仕組み**

```python
# サンプルコード or 疑似コード
def process(input):
    # ステップ1: [説明]
    result = step1(input)
    # ステップ2: [説明]
    return step2(result)
```

**ポイント**
- [技術的なポイント1]
- [技術的なポイント2]

---

## 性能・セキュリティ

| 非機能要件 | 現状 | 提案後 |
|----------|-----|-------|
| スループット | [現状] | **[目標] req/s** |
| レイテンシ(P99) | [現状] | **[目標] ms** |
| 可用性 | [現状] | **[目標]%** |

**セキュリティ**
- 認証: `[方式]`
- 暗号化: `[方式]`
- 監査ログ: `[保存期間]`

---

## 技術選定の根拠

| 選択肢 | パフォーマンス | コスト | 保守性 |
|-------|------------|-------|-------|
| **案A（提案）** | **◎** | ○ | **◎** |
| 案B | ○ | ◎ | △ |
| 案C（現状） | △ | △ | ○ |

**採用理由**
- [理由1]
- [理由2]

**トレードオフ**: [デメリットと受容理由]

---

## 実装ロードマップ

```
Week 1-2:  [フェーズ1] ─── マイルストーン: [確認ポイント]
Week 3-4:  [フェーズ2] ─── マイルストーン: [確認ポイント]
Week 5-6:  [フェーズ3] ─── マイルストーン: 本番稼働
```

**移行戦略**: [ブルー/グリーン / カナリアリリース]

**ロールバック手順**:
1. [手順1]
2. [手順2]

---

<!-- _class: cover -->

## Q&A / 次のステップ

<br>

**確認事項**

□ [技術的確認事項1]
□ [技術的確認事項2]

**アクション**

→ [日付]: [アクション1]
→ [日付]: [アクション2]

<br>

[連絡先 / GitHub / team chat]
