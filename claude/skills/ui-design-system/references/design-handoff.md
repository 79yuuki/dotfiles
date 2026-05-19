# DESIGN.md Handoff — 既存UI / 参考サイトから初速を出す

## 目的

既存サイト・参考サイト・スクリーンショット・実装コードから、
そのままコピーするのではなく **再利用可能なデザイン言語** を `DESIGN.md` に抽出する。

狙いは3つ。

- scan と improve を分離して、1回で全部やろうとして崩れるのを防ぐ
- どこを引き継ぎ、どこを作り直すかを artifact として残す
- 人間が最後に polish しやすい handoff を作る

## いつ使うか

これが刺さるのは、だいたいこの3パターン。

- 既存プロダクトのUIを整理してから改修したい
- 参考サイトの雰囲気を、要素分解して自分の文脈に持ち込みたい
- AIにいきなり実装させず、先に design language を固定したい

## 原則

- **scan と improve を混ぜない**
- まずは `observed` を作る。改善案はその次
- **`keep / rethink / discard` を分ける**
- 単なる感想で終わらず、layout / tokens / components / interaction まで落とす
- 最後の美意識は人間が持つ。AIは初速と整理を担当

`references/design-md-starter.md` に、`a11y assertions` と `acceptance checks` まで含む埋めるだけ版もある。
「まず叩き台を置きたい」時はそっちをそのまま `DESIGN.md` にコピーしてから埋める。

## `DESIGN.md` 最小テンプレ

```md
# DESIGN.md

## 1. Source
- URL / 画面名 / スクショ名
- 参照理由
- 対象ユーザー

## 2. Product intent
- 何を達成したいUIか
- 何を感じてほしいか
- primary CTA

## 3. Observed design language
### Layout
- 情報ヒエラルキー
- セクション構造
- グリッド / コンテナ幅

### Visual system
- 色の役割
- 背景レイヤー
- タイポグラフィ傾向
- 密度感 / 余白感

### Components
- 主役コンポーネント
- 繰り返し出るパターン
- CTAの置き方

### Interaction
- hover / focus / motion
- state変化
- feedbackの強さ

## 4. Keep / Rethink / Discard
### Keep
- 残したいもの

### Rethink
- 再設計したいもの

### Discard
- 持ち込まないもの

## 5. Proposed direction
- 今回のUIではどう翻訳するか
- 参照元から何を借りて、何を変えるか

## 6. Open questions
- 判断保留ポイント
- 人間レビューで決めること
```

## 作り方

### 1. まず source を固定する

対象は1つに絞るか、最大でも3つまで。
混ぜすぎると design language が濁る。

### 2. `observed` だけを書く

この段階では改善しない。
見えている事実だけを整理する。

悪い例:
- 「もっとこうした方がいい」
- 「このまま実装する」

良い例:
- 「Hero は左テキスト / 右ビジュアル」
- 「Primary CTA は各セクション下部に1個」
- 「余白は広め、情報密度は低め」

### 3. `keep / rethink / discard` を切る

ここで初めて判断を入れる。
観測と判断が分かれていると、後で見返しても迷いにくい。

### 4. Stage 1 に渡す

`ui-design-system` の Stage 1 では、`DESIGN.md` の要約と `keep / rethink / discard` を一緒に入れる。
これで layout 提案が暴れにくくなる。

### 5. Stage 2〜5 に分配する

- Layout → 情報ヒエラルキー / グリッド
- Color → 色の役割 / surface設計
- Typography → フォント階層 / tone
- Spacing → 密度 / rhythm
- Components → 主役UIパターン

### 6. Stage 9 で human polish 前提に締める

最後は「このまま実装して終わり」じゃなく、
**人間が見て直すべき論点** を1回出させる。

## 抽出プロンプトのたたき台

```md
以下の既存UI / 参考サイトから、実装指示ではなく `DESIGN.md` を作ってください。

条件:
- まず observed design language を整理する
- 改善案は `Proposed direction` に隔離する
- `keep / rethink / discard` を必ず分ける
- layout / visual system / components / interaction の4軸で書く
- そのまま模倣せず、自分のプロダクト文脈に翻訳する前提でまとめる

入力:
- source: [URL / スクショ / コード]
- product intent: [今回作りたいもの]
- audience: [誰向けか]
```

## 完了条件

これで終わり。

- `DESIGN.md` がある
- `observed` と `proposed` が分かれている
- `keep / rethink / discard` が埋まっている
- 次にどの Stage から始めるか決まっている
- 人間レビューで見る論点が残っている
