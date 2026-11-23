# 確かめ方

目次: 1 白紙の AI で前後を比べる / 2 限界 / 3 数える（snippet）/ 4 人に見せる（ux-walkthrough 9 節）

## 1. 白紙の AI で前後を比べる

直した本人は、画面の意味を知っているので初見を再現できない。この skill も diff も読んでいない別の agent に、画面だけを見せてタスクをさせ、直す前と後で比べる。

**用意する**

- 実行者: この skill・diff・仕様の文書を読んでいない別の agent（サブエージェントや別のワーカー）。1 回ごとに新しい agent にする。前と後で同じモデルを使う。
- 見せるもの: 画面の画像だけ。前の画像と後の画像は別々の agent に見せる（同じ agent に両方を見せない）。
- タスク文: 使う人の目的の言葉で書く。画面のラベルを使わない（「『支払う』を押して」と書かない）。誰として使うかを 1 行で添える。
- 正解を先に決めて書いておく: 押すべき物、押した後に起きること、その画面で分かっているべきこと（特に、取り消せない結果やお金の損）。

**段ごとに聞く**

1. 最初にどこを押すか（場所と名前）
2. 押すと何が起きると思うか
3. この画面で分かったこと。取り消せない結果があれば、それは何か
4. 迷った所、読み返した所
5. この画面の要点を 1 文で

違う所を押した時は、その段を不合格として記録し、正しい次の画面を見せて最後まで続ける（途中で止めない）。

**採点**: 段ごとに二値で付ける。「正しい物を最初に押した」「結果を正しく予測した」「取り消せない結果を正しく言えた」。迷いは数だけ記録する。前後それぞれ 3 回以上回し、合格の割合で比べる（LLM の答えはばらつくので 1 回では決めない）。

**説明を隠すテスト**: 説明文（操作・見出し・ラベル・`keep` の外の文字）を透明にした画面（3 節の `uiRefineText` に `hide: true`）でも、同じタスクをさせる。隠しても通るなら、構造とラベルで伝わっている。

**合格の決め方**（先に決めて書いておく）: 直した後は、(1) 通常の画面での成績が前より下がらない、(2) 取り消せない結果やお金を読み違えた回が増えない、の 2 つを両方満たす。そのうえで、説明を隠した画面で目指す合格の割合も前もって書いておき、それに届いて前より上がっていれば、構造で伝わるようになったと言える。隠した時の成績の落ち方の差だけで判定しない（両方とも悪くなっても差は小さくなる）。

**実行者に渡す文の雛形**

```md
あなたは <誰として: 例「初めてこのサービスで支払う人」> です。<目的: 例「お店で 1,250 円を払いたい」>。
画面の画像を 1 枚ずつ見せます。説明書や仕様は無く、画面だけで判断してください。
各画面について、次の 5 つに答えてください。
1. 最初にどこを押しますか（場所と、書かれている名前）
2. 押すと何が起きると思いますか
3. この画面で分かったことは何ですか。取り消せないことがあれば、それは何ですか
4. 迷った所、読み返した所はどこですか
5. この画面の要点を 1 文で
推測で答えた所は「推測」と書いてください。
```

## 2. 限界

- LLM の利用者役は、人より協力しすぎ、反応が一様で、苛立ちや曖昧さが無く、評価が一律に良く出る（31 の LLM の利用者役と 451 人の比較。Zhou ほか 2026）。AI が分かったことは、人が分かる保証にならない。
- AI は画面の文字を全部読む。人は流し読みする。説明の多い画面ほど、AI では良く見えやすい（推論。出典なし）。説明を隠すテストで補う。
- マルチモーダル LLM によるヒューリスティック評価は、経験のある評価者 5 人より多くの問題を見つけ、配置の問題にも強かった一方、UI 部品や慣習の見分けと、画面をまたぐ違反が苦手だった（Zhong ほか 2025。要旨で確認）。用語の統一や、同じ種類の画面の型の揃い方は、全画面を並べて自分の目で見る。
- 認知的ウォークスルー（段ごとに問う方法）は、実際の利用者を使わない。一般的な決済画面のような見慣れた型には効きにくい（NN/g）。
- ここでの比較で示せるのは、悪くしていないことと、明らかな改善まで。分かりやすくなったかは人で確かめる（4 節）。

## 3. 数える（snippet）

Playwright の `page.evaluate` に渡す。新しい依存は足さない。画像を撮る時に、同じ場面で数える。

```js
// 画面の文字を、説明文・名前（見出しとラベル）・操作・残す物（keep）に分けて数え、主な操作を数える。
// keep には、隠すテストでも残す物（金額、宛先、取り消せない結果の警告など）の CSS セレクタを渡す。
// hide: true の時は、説明文を透明にする（DOM は書き換えない）。撮った後は再読み込みしてから通常の撮影に戻る。
//   const r = await page.evaluate(uiRefineText, { keep: "[data-amount]", hide: false });
const uiRefineText = ({ keep = "", hide = false } = {}) => {
  const ACTION = 'button, a[href], input:not([type=hidden]), select, textarea, summary, [role=button], [role=link], [role=checkbox], [role=radio], [role=tab]';
  const NAME = 'h1, h2, h3, h4, h5, h6, [role=heading], legend, label';
  const BUTTONISH = 'button, a[href], [role=button], input[type=submit], input[type=button]';
  const boxOf = (el) => { while (el && getComputedStyle(el).display === "contents") el = el.parentElement; return el; };
  const shown = (el) => getComputedStyle(el).visibility === "visible" && !!boxOf(el)?.checkVisibility({ opacityProperty: true, visibilityProperty: true });
  const kindOf = (el) => (keep && el.closest(keep) ? "keep" : el.closest(ACTION) ? "action" : el.closest(NAME) ? "name" : "explanation");
  const chars = { explanation: 0, name: 0, action: 0, keep: 0 };
  const explanationNodes = [];
  const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
  for (let n; (n = walker.nextNode()); ) {
    const el = n.parentElement;
    const text = n.textContent.replace(/\s+/g, "");
    if (!text || el.closest("script, style, noscript, template") || !shown(el)) continue;
    const kind = kindOf(el);
    chars[kind] += [...text].length;
    if (kind === "explanation") explanationNodes.push(n);
  }
  const actions = [...document.querySelectorAll(ACTION)].filter(shown);
  for (const el of actions) if (el.matches("input[type=submit], input[type=button], input[type=reset]")) chars[kindOf(el)] += [...el.value.replace(/\s+/g, "")].length;
  // 色は canvas に塗って RGBA に直す（oklch() や color() で返る時もあるため）
  const ctx = document.createElement("canvas").getContext("2d", { willReadFrequently: true });
  const rgba = (c) => { ctx.clearRect(0, 0, 1, 1); ctx.fillStyle = "transparent"; ctx.fillStyle = c; ctx.fillRect(0, 0, 1, 1); return [...ctx.getImageData(0, 0, 1, 1).data]; };
  const near = (a, b) => a.every((v, i) => Math.abs(v - b[i]) < 8);
  const pageBg = rgba(getComputedStyle(document.body).backgroundColor);
  // 主な操作 = 押せる状態で、背景が塗られたボタン・リンク（近似。画像で確かめる）
  const primary = actions.filter((el) => {
    if (!el.matches(BUTTONISH) || el.matches(":disabled") || el.closest("[inert], [aria-disabled=true]")) return false;
    const bg = rgba(getComputedStyle(el).backgroundColor);
    return bg[3] > 127 && !near(bg, pageBg) && !near(bg, [255, 255, 255, 255]);
  });
  if (hide) {
    CSS.highlights.set("ui-refine-hide", new Highlight(...explanationNodes.map((n) => { const r = new Range(); r.selectNodeContents(n); return r; })));
    const style = document.createElement("style");
    style.textContent = "::highlight(ui-refine-hide) { color: transparent; text-shadow: none; }";
    document.head.append(style);
  }
  return {
    explanationChars: chars.explanation,
    nameChars: chars.name,
    actionChars: chars.action,
    keepChars: chars.keep,
    actions: actions.length,
    primaryActions: primary.length,
    primaryLabels: primary.map((el) => (el.matches("input") ? el.value : el.innerText.trim()) || el.getAttribute("aria-label") || el.title || "（名前なし）"),
    hidden: hide ? explanationNodes.length : 0,
  };
};
```

読み方と注意:

- `explanationChars` が説明文の文字数。見出しとラベル（`nameChars`）、ボタンやリンクの中の文字（`actionChars`）、`keep` に当たる文字（`keepChars`）は別に数える。空白は数えない。
- `keep` には、隠すテストでも消してはいけない物を全部渡す。金額・宛先・枚数や日付などの値、状態、規約・法定の表示（C）、取り消せない結果の警告（重なっていれば残す 1 つ）。前後で同じ意味の物を指すセレクタにする。
- `primaryActions` が主な操作の数。1 が目標。2 以上なら、同じ強さの物が並んでいないかを画像で見る。`actions` は見えている操作の総数（押せない物も含む）。
- 主な操作の判定は見た目の近似。スタイルを当てていない既定のボタン（灰色）も数える。白いボタン、枠線だけのボタン、押せないボタン（`disabled`、無効な `fieldset` の中、`inert`、`aria-disabled`）は数えない。数え漏れと数えすぎは、画像で確かめて表に注記する。
- 数えられない文字がある: iframe の中、Shadow DOM の中、疑似要素（`::before` の `content`）、画像の中の文字。ある画面では注記する。
- 新しい Chromium で動かす（`checkVisibility` と CSS Custom Highlight を使う）。画面の外にある（スクロールした先の）要素も数える。
- 見た目を変えずにタグだけ替える（`div` を `h2` にする）と説明文の数は減るが、改善ではない。見出しにした物は、見出しとして見せたかを画像で確かめる。
- `hide: true` は文字の色だけを透明にする。`-webkit-text-fill-color` で文字を塗っている画面では隠れないことがあるので、撮った画像で確かめる。撮った後は再読み込みする。

結果は導線・画面・状態・幅ごとに表にし、前後を並べる。

| 画面 | 幅 | 説明文の文字数 前 → 後 | 主な操作の数 前 → 後 | 注記 |
|---|---|---|---|---|

## 4. 人に見せる（ux-walkthrough 9 節）

ux-walkthrough の 9 節の手順で、前と後の 2 本を録画し、2 つの確認のページを作る。

- **前**: 直す前の版で `recorder.mjs` の `record` を使って導線を通す。`review.json` の `findings` に見立てを書く（`kind` は `concern`。重さは `severity` に、誤操作 → 3〜4（お金や取り消せない操作は 4）、迷う → 2、見た目だけ → 1）。
- **後**: 直した版で、同じ場面の名前で録画する。直した所は `kind: "good"` にし、`what` に「前: … → 後: …」を書く。残った問題は `concern` のまま書く。`summary` に数の前後と白紙の AI の結果を、`notChecked` に確かめていないことを書く。
- `build-review.mjs` は 1 本の録画につき 1 つのページを作る。前後を左右に並べる機能は無いので、2 つのページの場所を並べて渡す。
- 見てもらった結果の記録（`flows.py record`）は、ux-walkthrough の決まりに従う。

## 出典

- Zhou ほか「Mind the Sim2Real Gap in User Simulation for Agentic Tasks」（2026） https://arxiv.org/abs/2603.11245
- Zhong ほか「Synthetic Heuristic Evaluation: A Comparison between AI- and Human-Powered Usability Evaluation」（2025。要旨で確認） https://arxiv.org/abs/2507.02306
- NN/g「Cognitive Walkthroughs」 https://www.nngroup.com/articles/cognitive-walkthroughs/
- 段ごとに聞く問いは、認知的ウォークスルーの 4 問と、ファーストクリックテストの考え方を、画像だけで聞ける形にしたもの（この skill 独自の形）。
