# 無料一次特許DB — アクセス能力・落とし穴・横断順序

2系統(Claude+Codex)調査で検証済み。「無料か / キー要否 / AIエージェントがクレーム原文を機械取得できるか」を実装視点で整理。

## DB一覧

| DB | 無料 | キー/登録 | クレーム原文の機械取得 | 役割・カバレッジ |
|---|---|---|---|---|
| Google Patents | ○ | 不要 | △ JSレンダリング依存で**欠落しうる** | 初動スクリーニング最速。120M+件・100+庁・機械翻訳横断。URL構造 `patents.google.com/patent/US########B2/en` |
| Espacenet | ○ | UI閲覧不要 | UI閲覧（bulk/robot不可） | 120M+件・100+国・1836年〜。Global Dossier/CCDでファイルラッパー・引用・法的ステータス |
| EPO OPS | ○ | **必須(OAuth)** | ○ claims/description原文取得可 | **プログラム的に最も堅牢**。REST/XML。無料枠**週3.5GB**（要 Fair Use Charter 確認） |
| J-PlatPat | ○ | UI閲覧不要 | UI閲覧 | **JP公報の原本確定**。FI/Fターム/IPC検索。提供元 INPIT |
| JPO 特許情報取得API | ○ | 要登録 | API | 試行提供。日本特許/意匠/商標+OPD五庁情報の一部。OPD-APIは2024-08-09に新規申込終了 |
| USPTO PPUBS | ○ | UI不要 | UI（SPA） | Patent Public Search。Boolean/truncation/近接/L番号履歴 |
| USPTO ODP (Open Data Portal) | ○ | **要登録** | REST/JSON | US公式推奨経路。PatentSearch APIはODP移行で中断中・再開未定（クレーム全文返すか要確認） |
| Google BigQuery (patents-public-data) | 従量 | **GCP必須** | ○ SQLでクレーム抽出 | 大量プログラム解析・クレーム原文の堅牢取得に最有力 |

## 横断の定石順序（JP/US/CN/EP）
1. **Google Patents** で広く拾う（無料・キー不要・機械翻訳横断、family/CPC/引用を把握）
2. **Espacenet / 各庁** で原本と法的ステータスを確定
3. **JP → J-PlatPat**、**US → USPTO PPUBS/ODP**、**CN → CNIPA**（最終確認）で原本確定
4. 大量解析 → **BigQuery (patents-public-data)**

## AIエージェント実装上の落とし穴
- **キーレスで即WebFetchできる**のは Google Patents（**クレーム欠落リスクあり**）と Espacenet/J-PlatPat の一部UI。
- **クレーム原文の堅牢取得**は EPO OPS（要キー）か BigQuery（要GCP）。それが無い環境では Google Patents の `/patent/<番号>/en` を fetch しつつ「クレームが落ちていないか」を必ず目視確認する。
- data.uspto.gov系・Espacenet・PPUBS は bot対策/SPA のため**単純WebFetchで本文が取れないことがある** → 取れなければ「No patent database search was run」相当の限定を明示。
- **CN（中国）**: Espacenet/Global Dossier で入口確認できるが、存続・補正・権利者は CNIPA 公式で要確認。CN特許の権利は JP/US に直接効かない（属地主義）が、**CNで事業するなら CN を独立に調べる**。

## 検索フィールド要点
- 分類: CPC（EPO/USPTO共同・約25万分類）/ IPC（WIPO・言語非依存）/ FI・Fターム（JP固有・J-PlatPatで強力）。
- 分類フィールドとクレーム/タイトル/要約フィールドを **OR** で結ぶと、キーワードに出ない関連特許を拾える。
- assignee（competitor名）・inventor（主要発明者）・citation（前方/後方引用）も独立軸として回す。
