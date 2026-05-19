# デザインシステム別コンポーネント実装リファレンス

特定のコンポーネントの実装例を探す時、どのデザインシステムが最も参考になるかのガイド。

## Component Galleryの使い方

各コンポーネントページ（例: https://component.gallery/components/card/ ）には、95のデザインシステムからの実際のスクリーンショットとリンクが掲載されている。

### 調べ方
1. `https://component.gallery/components/{component-name}/` にアクセス
2. デザインシステムごとの実装例スクリーンショットを確認
3. リンク先で実際のコード・ガイドラインを参照

---

## デザインシステム選定ガイド

### Tailwind CSS / React プロジェクト向け
| 参照先 | 理由 |
|---|---|
| **Tailwind Headless UI** | Tailwind公式。アクセシビリティ対応。unstyled |
| **WorkOS Radix** | Radix Primitives。React + unstyled |
| **Vercel Geist** | Next.js / Vercel系のモダンUI |
| **Shopify Polaris** | 最も包括的なガイドライン+アクセシビリティ |

### Web Components / フレームワーク非依存
| 参照先 | 理由 |
|---|---|
| **Google Material Design** | 業界標準 |
| **Adobe Spectrum** | 包括的。Tone of voice まで |
| **IBM Carbon** | 6フレームワーク対応 |

### アクセシビリティ重視
| 参照先 | 理由 |
|---|---|
| **GOV.UK Design System** | 政府基準。最高レベルのa11y |
| **Twilio Paste** | アクセシビリティ+Tone of voice |
| **Hashicorp Helios** | Ember系だがa11yガイドラインが秀逸 |

### ダークテーマ / Developer向け
| 参照先 | 理由 |
|---|---|
| **GitHub Primer** | ダークテーマの実績 |
| **GitLab Pajamas** | Vue系 |
| **Stack Overflow Stacks** | Developer向けUI |

---

## コンポーネント別おすすめデザインシステム

| コンポーネント | 最良の参考先 | 理由 |
|---|---|---|
| Accordion | Shopify Polaris, GOV.UK | ガイドライン充実 |
| Card | Pinterest Gestalt | カード中心のUI |
| Table | IBM Carbon | 高機能データテーブル |
| Form | GOV.UK | フォーム設計の教科書 |
| Navigation | Adobe Spectrum | 大規模ナビ設計 |
| Modal | Radix | アクセシビリティ完璧 |
| Toast | Twilio Paste | 通知パターン豊富 |
| Empty State | Shopify Polaris | ガイドライン明確 |
| Stepper | Material Design | ステッパーの標準 |
| Search | Algolia InstantSearch | 検索特化 |
