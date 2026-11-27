# 確かめ方

目次: 1 白紙の AI で前後を比べる（本文を隠すテスト、分けて撮る）/ 2 限界 / 3 数える（snippet。縦の長さと最初の画面も）/ 4 人に見せる（ux-walkthrough 9 節、左右に並べた静止画）/ 5 流し読みの確かめ（Haiku・Sonnet で、直すたびに）

## 1. 白紙の AI で前後を比べる

直した本人は、画面の意味を知っているので初見を再現できない。この skill も diff も読んでいない別の agent に、画面だけを見せてタスクをさせ、直す前と後で比べる。

**用意する**

- 実行者: この skill・diff・仕様の文書を読んでいない別の agent（サブエージェントや別のワーカー）。1 回ごとに新しい agent にする。前と後で同じモデルを使う。
- 見せるもの: 画面の画像だけ。前の画像と後の画像は別々の agent に見せる（同じ agent に両方を見せない）。どちらが前か後かは伏せる（ファイル名やフォルダ名にも出さない）。
- 縦に長い画面: 1 枚で渡すと縮小されて文字が読めない。撮る幅のまま、縦に分けた画像を上から順に渡す（1 枚の高さはおおむね画面 1〜2 枚分。分け目で部品が切れないよう少し重ねる）。下の snippet で、撮る時に分けて撮れる。渡す前に、分けた画像を全部自分の目で見る。`fullPage` と下の snippet は、ページ全体のスクロールしか撮れない。中の箱でスクロールする画面は、その箱を少しずつスクロールしながら撮るか、撮る間だけ箱の高さの制限を外す（外した時は、そう書く）。
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

**本文を隠すテスト**: 人は画面の文を読まない、の代わりの試し。説明文（操作・見出し・ラベル・図・`keep` の外の文字）を透明にした画面（3 節の `uiRefineText` に `hide: true`）で、同じタスクをさせる。隠しても通るなら、見出し・ボタン・図・状態の表示で伝わっている。`keep` に説明文を入れて通りやすくしない（`keep` は値・状態の表示・HTML で組んだ図の短いラベル・C の表示・残す警告だけ）。

**合格の決め方**（先に決めて書いておく）: 判定は段ごとに行い、全体の割合でならさない。直した後の画面は、次を全部満たす。

1. 本文を隠した画面で、どの段も「正しい物を最初に押した」と「結果を正しく予測した」がそれぞれ 3 回のうち 2 回以上（既定の基準。緩めるのは人が決めた時だけ）。
2. 本文を隠した画面で、取り消せない結果やお金を読み違えた回が 0（`keep` に残した警告と値で伝わること）。
3. 通常の画面でも本文を隠した画面でも、どの段の成績も前より下がらない。

隠した時の成績の落ち方の差だけで判定しない（両方とも悪くなっても差は小さくなる）。

**回数が 1 回と決まっている時**: 観測したことだけを書き、合否は付けない。例:「最初に押す物は、前後とも、本文を隠した画面でも正解だった（各 1 回）。迷った所の数は前 7、後 5。1 回ずつなので、悪くしていないか・良くなったかは判定できない。合否は人の確認を待つ」。

**実行者に渡す文の雛形**

```md
あなたは <誰として: 例「初めてこのサービスで支払う人」> です。<目的: 例「お店で 1,250 円を払いたい」>。
画面の画像を順に見せます。説明書や仕様は無く、画面だけで判断してください。縦に長い画面は「画面 1（全 3 枚）」のように分けて渡すので、同じ画面の画像を全部見てから、その画面について答えてください。
各画面について、次の 5 つに答えてください。
1. 最初にどこを押しますか（場所と、書かれている名前）
2. 押すと何が起きると思いますか
3. この画面で分かったことは何ですか。取り消せないことがあれば、それは何ですか
4. 迷った所、読み返した所はどこですか
5. この画面の要点を 1 文で
推測で答えた所は「推測」と書いてください。
```

```js
// 縦に長い画面を、上から分けて撮る（確かめ役の AI に順に渡す）。seg は 1 枚の高さ、overlap は重ねる高さ（px）
const shootInParts = async (page, prefix, { seg = 1600, overlap = 120 } = {}) => {
  if (![seg, overlap].every(Number.isFinite) || !(seg > 0 && overlap >= 0 && overlap < seg)) throw new Error("seg と overlap は数で、seg > 0、0 <= overlap < seg にする");
  const height = await page.evaluate(() => document.documentElement.scrollHeight);
  const { width } = page.viewportSize();
  const files = [];
  for (let y = 0, n = 1; y < height; y += seg - overlap, n++) {
    const path = `${prefix}-part${n}.png`;
    await page.screenshot({ path, fullPage: true, clip: { x: 0, y, width, height: Math.min(seg, height - y) } });
    files.push(path);
    if (y + seg >= height) break;
  }
  return files;
};
```

## 2. 限界

- LLM の利用者役は、人より協力しすぎ、反応が一様で、苛立ちや曖昧さが無く、評価が一律に良く出る（31 の LLM の利用者役と 451 人の比較。Zhou ほか 2026）。AI が分かったことは、人が分かる保証にならない。
- AI は画面の文字を全部読む。人は流し読みする。説明の多い画面ほど、AI では良く見えやすい（推論。出典なし）。説明を隠すテストと、安いモデルでの流し読みの確かめ（5 節）で補う。
- マルチモーダル LLM によるヒューリスティック評価は、経験のある評価者 5 人より多くの問題を見つけ、配置の問題にも強かった一方、UI 部品や慣習の見分けと、画面をまたぐ違反が苦手だった（Zhong ほか 2025。要旨で確認）。用語の統一や、同じ種類の画面の型の揃い方は、全画面を並べて自分の目で見る。
- 認知的ウォークスルー（段ごとに問う方法）は、実際の利用者を使わない。一般的な決済画面のような見慣れた型には効きにくい（NN/g）。
- ここでの比較で示せるのは、悪くしていないことと、明らかな改善まで。分かりやすくなったかは人で確かめる（4 節）。

## 3. 数える（snippet）

Playwright の `page.evaluate` に渡す。新しい依存は足さない。画像を撮る時に、同じ場面で数える。

```js
// 画面の文字を、説明文・名前（見出し・ラベル・図）・操作・残す物（keep）に分けて数え、主な操作を数える。
// root には数える範囲（導線の本文や区画）の CSS セレクタを渡す。省くと body 全体。
// keep には、隠すテストでも残す物（金額、宛先、状態の表示、取り消せない結果の警告など）の CSS セレクタを渡す。
// hide: true の時は、説明文を透明にする（DOM は書き換えない）。撮った後は再読み込みしてから通常の撮影に戻る。
//   const r = await page.evaluate(uiRefineText, { root: "main", keep: "[data-amount]", hide: false });
const uiRefineText = ({ root: rootSel = "", keep = "", hide = false } = {}) => {
  const root = rootSel ? document.querySelector(rootSel) : document.body;
  if (!root) throw new Error(`root が見つからない: ${rootSel}`);
  // 最初の画面（スクロールする前のビューポート）で測るため、スクロールしている箱（ページと中の箱）を全部頭へ戻し、最後に元へ戻す
  const all = [document.scrollingElement, ...document.querySelectorAll("*")].filter(Boolean);
  const saved = all.filter((el) => el.scrollTop > 0).map((el) => [el, el.scrollTop]);
  try {
    for (const [el] of saved) el.scrollTo({ top: 0, behavior: "instant" });
    const ACTION = 'button, a[href], input:not([type=hidden]), select, textarea, summary, [role=button], [role=link], [role=checkbox], [role=radio], [role=tab]';
    const NAME = 'h1, h2, h3, h4, h5, h6, [role=heading], legend, label, svg, [role=img]';
    const BUTTONISH = 'button, a[href], [role=button], input[type=submit], input[type=button]';
    const boxOf = (el) => { while (el && getComputedStyle(el).display === "contents") el = el.parentElement; return el; };
    // 読み上げ用に見えなくした文字（1px 以下で、はみ出しを切り抜いた箱）は、目に入らないので数えない
    const srOnly = (b) => { const r = b.getBoundingClientRect(), cs = getComputedStyle(b); return r.width <= 1 && r.height <= 1 && (cs.overflowX !== "visible" || cs.overflowY !== "visible" || cs.clip !== "auto" || cs.clipPath !== "none"); };
    const shown = (el) => { const b = boxOf(el); return !!b && getComputedStyle(el).visibility === "visible" && b.checkVisibility({ opacityProperty: true, visibilityProperty: true }) && !srOnly(b); };
    // 操作を先に判定する（keep にした表のセルの中のボタンも、操作として数える）
    const kindOf = (el) => (el.closest(ACTION) ? "action" : keep && el.closest(keep) ? "keep" : el.closest(NAME) ? "name" : "explanation");
    // 見える範囲 = 要素の箱を、はみ出しを切る祖先の箱とビューポートで切った残り
    const visible = (el, r) => {
      let top = Math.max(r.top, 0), bottom = Math.min(r.bottom, innerHeight);
      for (let c = el, a = el.parentElement; a && a !== document.documentElement; c = a, a = a.parentElement) {
        if (getComputedStyle(c).position === "fixed") break; // 固定の要素は、祖先の箱に切られない
        if (getComputedStyle(a).overflowY === "visible") continue;
        const ar = a.getBoundingClientRect();
        top = Math.max(top, ar.top); bottom = Math.min(bottom, ar.bottom);
      }
      return { top, bottom };
    };
    const inFirstView = (el, r) => { const v = visible(el, r); return v.bottom > v.top; };
    const chars = { explanation: 0, name: 0, action: 0, keep: 0 };
    const explanationNodes = [];
    let firstViewChars = 0;
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    for (let n; (n = walker.nextNode()); ) {
      const el = n.parentElement;
      const text = n.textContent.replace(/\s+/g, "");
      if (!text || el.closest("script, style, noscript, template") || !shown(el)) continue;
      const kind = kindOf(el);
      chars[kind] += [...text].length;
      if (kind !== "explanation") continue;
      explanationNodes.push(n);
      const range = new Range();
      range.selectNodeContents(n);
      if (inFirstView(el, range.getBoundingClientRect())) firstViewChars += [...text].length; // 一部だけ入る文も全部数える
    }
    const actions = [...(root.matches(ACTION) ? [root] : []), ...root.querySelectorAll(ACTION)].filter(shown);
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
    // 縦の長さ = ビューポート＋いちばん長いスクロールの距離。数える箱は、ページ、root を中に持つ箱、root の中の高さが画面の半分以上ある箱（左のメニューや規約の小さい箱は数えない）
    const scrollDistance = Math.max(0, ...all.filter((el) => el === document.scrollingElement || (/(auto|scroll)/.test(getComputedStyle(el).overflowY) && (el.contains(root) || (root.contains(el) && el.clientHeight >= innerHeight / 2)))).map((el) => el.scrollHeight - el.clientHeight));
    const labelOf = (el) => (el.matches("input") ? el.value : el.innerText.trim()) || el.getAttribute("aria-label") || el.title || "（名前なし）";
    const inView = primary.filter((el) => {
      const r = el.getBoundingClientRect(), v = visible(el, r);
      if (!(r.bottom > r.top && v.top <= r.top && v.bottom >= r.bottom)) return false;
      const hit = document.elementFromPoint((r.left + r.right) / 2, (r.top + r.bottom) / 2); // 固定の帯などに隠れていないか
      return !!hit && el.contains(hit);
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
      primaryLabels: primary.map(labelOf),
      firstViewChars,
      // 主な操作のどれか 1 つが、切られず・隠れずに、ボタン全体ごと最初の画面に見えるか（下に固定したボタンも見えれば true）。主な操作が 0 なら null
      primaryInFirstView: primary.length ? inView.length > 0 : null,
      firstViewPrimaryLabels: inView.map(labelOf),
      viewports: Math.round(((innerHeight + scrollDistance) / innerHeight) * 100) / 100,
      hidden: hide ? explanationNodes.length : 0,
    };
  } finally {
    for (const [el, top] of saved) el.scrollTo({ top, behavior: "instant" });
  }
};
```

読み方と注意:

- `explanationChars` が説明文の文字数。見出し・ラベル・図の中の文字（`nameChars`）、ボタンやリンクの中の文字（`actionChars`）、`keep` に当たる文字（`keepChars`）は別に数える。空白は数えない。見えている文字だけを数えるので、閉じた 2 段目（`details` など）の中身は入らない。これが「画面に出ている本文」（閉じた 2 段目の中を除く。スクロールした先も含む）になる。
- `root` で数える範囲を絞る。導線の本文だけを数える時は、左のメニュー・ヘッダー・下のタブの外の要素を指す。文字の予算は、区画ごとに `root` を替えて数える（区画が本文の直下に並んでいる画面なら、`${本文} > :nth-child(i)` を、見出しの有無にかかわらず全部順に数える。見出しの無い導入文や補足も 1 つの区画として予算を当てる）。区画ごとの数の合計が本文全体の数と合うかを確かめ、合わなければ、どの区画にも入らない本文を別枠で数える。見つからないセレクタを渡すと止まる（黙って全体を数えない）。
- 判定の順は、操作 → `keep` → 名前 → 説明文。`keep` にした表のセルの中のボタンも、操作として数える。
- SVG の図の中の文字は名前として数え、隠すテストでも残す。`figcaption` などの図の説明文は本文として数える。HTML で組んだ図のラベル（ステッパーの段の名前など）は、短いラベルだけを `keep` に渡す。図の中に説明の文を入れて数から逃れない。
- 読み上げ用に見えなくした文字（1px 以下で、はみ出しを切り抜いた箱）は数えない。小さい箱からはみ出して見えている文字は数える。
- `keep` には、隠すテストでも消してはいけない物を全部渡す。金額・宛先・枚数や日付などの値、状態の表示（札・チップ・進み具合）、HTML で組んだ図の短いラベル、規約・法定の表示（C）、取り消せない結果の警告（重なっていれば残す 1 つ）。前後で同じ意味の物を指すセレクタにする。
- `primaryActions` が主な操作の数。1 が目標。ただし、やることが全部済んだ画面では 0 が正しい（済んだ物を変える操作を一番強く見せない）。2 以上なら、同じ強さの物が並んでいないかを画像で見る。`actions` は見えている操作の総数（押せない物も含む）。
- 縦の長さと最初の画面（[cognition.md](cognition.md) の 5 節の予算）:
  - `viewports`: 画面の縦がビューポートの何枚分か（375×667 で 1,334px なら 2.0。0.01 単位）。スクロールの距離は、ページ、`root` を中に持つ箱、`root` の中の高さが画面の半分以上ある箱のうち、いちばん長い物で測る（左のメニューや規約の小さい箱は数えない）。`root` を省くと高さいっぱいの左メニューを数えることがあるので、本文の `root` を渡す。
  - `primaryInFirstView`: 主な操作のどれか 1 つが、切られず（はみ出しを切る箱の外に出ていない）、固定の帯などに隠れず、ボタン全体ごとスクロールしないで見えるか。主な操作が 0 の画面は `null`（全部済んだ画面では正しい）。`firstViewPrimaryLabels` は、そうして見えた主な操作の名前（塗りの「戻る」だけが入っていないかを見る）。
  - `firstViewChars`: 最初の画面に見える説明文の文字数。はみ出しを切る箱の外の文は数えない。一部だけ見える文は全部数える。
  - 測る時に、スクロールしている箱を全部頭へ戻し、終わったら元の位置へ戻す。主な端末のビューポート（既定 375×667。320 幅は 320×568）で数え、`primaryInFirstView` は低い高さ（既定 550。ブラウザの帯の分）でももう一度測って、両方を書く。合否は主な端末の高さで付け、低い高さで入らない時は注記する。
  - `root` は 1 つの要素。複数の所を数える時は共通の祖先を渡す。`firstViewChars` と `primaryInFirstView` は `root` の中だけを見る。区画ごとに数える時も、この 2 つは本文全体を `root` にした回の値を使う。主な操作の帯が `root` の外にある時（下に固定した帯、portal で描く部品）は、帯も含む要素を `root` にした回を取り直し、主な操作の数・`primaryInFirstView`・`firstViewPrimaryLabels` はその回の値（本文と帯の外の物、左のメニューなどは除く）、`viewports`・説明文の数・`firstViewChars` は本文の回の値を書く。主な操作が 0 なのに全部済んだ画面でない時は、主な操作の見落とし（中の span に色を塗ったリンクなど）を疑い、画像で確かめる。
  - モーダルを開いた状態では、背景のボタンも主な操作に数える。モーダルの状態は、モーダルを `root` にして別に測る。
  - 数が合わないことがある画面は、画像で確かめる: 固定の帯が文の上に重なる、横に流れる、`root` を持つスクロールの箱が 2 つ以上ある、`root` の中に画面の半分以上の高さで中身だけが流れる箱（規約・一覧）がある、画面の外へ隠した引き出しがスクロールする。この時の縦の予算の合否は、撮った画像の高さで付けて、そう書く。
- 主な操作の判定は見た目の近似。スタイルを当てていない既定のボタン（灰色）も数える。白いボタン、枠線だけのボタン、押せないボタン（`disabled`、無効な `fieldset` の中、`inert`、`aria-disabled`）は数えない。数え漏れと数えすぎは、画像で確かめて表に注記する。
- 数えられない文字がある: iframe の中、Shadow DOM の中、疑似要素（`::before` の `content`）、画像の中の文字。ある画面では注記する。
- 新しい Chromium で動かす（`checkVisibility` と CSS Custom Highlight を使う）。画面の外にある（スクロールした先の）要素も数える。
- 見た目を変えずにタグだけ替える（`div` を `h2` にする）と説明文の数は減るが、改善ではない。見出しにした物は、見出しとして見せたかを画像で確かめる。
- `hide: true` は文字の色だけを透明にする。`-webkit-text-fill-color` で文字を塗っている画面では隠れないことがあるので、撮った画像で確かめる。撮った後は再読み込みする。

結果は導線・画面・状態・幅ごとに表にし、前後を並べる。

| 画面 | 幅 | 説明文の文字数 前 → 後 | 最初の画面の説明文 前 → 後 | 縦（画面の枚数）前 → 後 | 主な操作が最初の画面に 前 → 後 | 主な操作の数 前 → 後 | 注記 |
|---|---|---|---|---|---|---|---|

## 4. 人に見せる（ux-walkthrough 9 節）

ux-walkthrough の 9 節の手順で、前と後の 2 本を録画し、2 つの確認のページを作る。

- **前**: 直す前の版で `recorder.mjs` の `record` を使って導線を通す。`review.json` の `findings` に見立てを書く（`kind` は `concern`。重さは `severity` に、誤操作 → 3〜4（お金や取り消せない操作は 4）、迷う → 2、見た目だけ → 1）。
- **後**: 直した版で、同じ場面の名前で録画する。直した所は `kind: "good"` にし、`what` に「前: … → 後: …」を書く。残った問題は `concern` のまま書く。`summary` に数の前後と白紙の AI の結果を、`notChecked` に確かめていないことを書く。
- `build-review.mjs` は 1 本の録画につき 1 つのページを作る。前後を左右に並べる機能は無いので、2 つのページの場所を並べて渡す。
- 静止画で見比べてもらう時は、同じ状態・同じ幅の画像を左右に並べた 1 枚を作る（下の snippet）。上に、何を変えたかを 1〜3 行書く。各列のラベルに数を入れる（例「大胆版　説明文 742 字・主な操作 1・縦 4,265px」）。並べるのは「前」と「今回作った版」。大胆版だけなら 2 枚、控えめ版だけなら 2 枚、両方なら 3 枚。本文を隠した画面の比較も 1 枚作る（図と段の一覧が残るか、のように違いが一目で分かる）。

```js
// 同じ状態・同じ幅の画像を左右に並べた 1 枚を作る。columns は [{ label: "直す前", path }, { label: "直した後", path }, …]
import { readFileSync } from "node:fs";
const sideBySide = async (browser, { title, notes = [], columns, out, scale = 1 }) => {
  const esc = (t) => String(t).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);
  const width = Math.round(readFileSync(columns[0].path).readUInt32BE(16) * scale); // PNG の幅（IHDR）
  const cols = columns.map(({ label, path }) => `<figure style="margin:0;width:${width}px"><figcaption style="font-weight:700;margin:0 0 8px">${esc(label)}</figcaption><img alt="${esc(label)}" style="width:100%;display:block;border:1px solid #ccc;background:#fff" src="data:image/png;base64,${readFileSync(path).toString("base64")}"></figure>`);
  const page = await browser.newPage({ viewport: { width: columns.length * (width + 24) + 48, height: 800 } });
  await page.setContent(`<!doctype html><meta charset="utf-8"><body style="margin:0;padding:16px 24px;background:#f3f4f6;font-family:sans-serif;color:#161616"><h1 style="font-size:20px;margin:0 0 8px">${esc(title)}</h1><ul style="margin:0 0 16px;padding-left:1.2em;line-height:1.7">${notes.map((n) => `<li>${esc(n)}</li>`).join("")}</ul><div style="display:flex;gap:24px;align-items:flex-start">${cols.join("")}</div></body>`);
  await page.waitForLoadState("load");
  await page.screenshot({ path: out, fullPage: true });
  await page.close();
};
```
- 見てもらった結果の記録（`flows.py record`）は、ux-walkthrough の決まりに従う。

## 5. 流し読みの確かめ（Haiku・Sonnet で、直すたびに）

頭の良いモデルは画面の文を全部読むので、説明の多い画面でも良く見える（2 節）。流し読みする人に近い答えを、安いモデルで何度も取る。オーナーの提案（2026-11-27）による手順で、安いモデルが人の流し読みに近いという研究の裏付けは見つけていない（試しの結果は節の終わり）。

**いつ**: 見立ての最初（直す前の画面）と、試作を直すたびに 1 巡（Haiku 3 回と Sonnet 3 回）。直した画面を前後の比較として人に見せる前に、下の合格の条件を満たすまで回す。同じ所が 3 回直しても通らなければ、方針を見直して人に聞く。

**実行者**: Haiku と Sonnet を、それぞれ 3 回以上。1 回ごとに新しい agent にし、この skill も diff も仕様も読ませない。頭の良いモデル（Opus など）は使わない。Agent ツールなら `model: "haiku"` と `model: "sonnet"`。effort（考える深さ）は前後で同じにし、記録する（高いと熟読寄りになるかもしれない。確かめていない）。Haiku や Sonnet を選べない環境では、選べるモデルのうち小さい物 2 つ（大きさの違う物）で代え、そう書く。前後を比べる時は、前も同じモデル・同じ回数で回す。

**見せる物**: 1 節と同じ。画像だけ、縦に長い画面は分けて渡す、前か後かを伏せる。はじめての人と前に使った人で最初に押す物が変わる画面は、役を変えて別々に回す（[cognition.md](cognition.md) の 7 節）。

**先に決めて書いておく**: 画面ごとに、q1 の正解（見立ての「誰が・何のために・何を決めるか」の 1 行）、q2 の正解（押す物）、q3 の正解（押した後に起きること）、読ませたい区画（金額、取り消せない結果、利用者がすること。画面ごとに 3 つまで）。

**問い**（画面ごと。雛形は下）: q1 最初の 3 秒で、何をする画面だと思ったか／q2 次にどこを押すか／q3 この先に何が起きるか／q4 長いと感じた所／q5 読まずに飛ばした所／q6 覚えていること（3 つまで）。q6 は、q4・q5 に出てこない区画が、読まれて問題なかったのか、見られていないのかを見分けるために聞く。

**集計**: 画面ごとに、回ごとの答えを表にする。q1〜q3 は先に決めた正解と比べる（お金・取り消せないことの読み違いは別に数える）。q4・q5 は、区画ごとに名前が出た回数を数える。q6 は、読ませたい区画が出てきた回数を数える。

**合格の条件**（既定。緩めるのは人が決めた時だけ）。どの画面も、次を全部満たす。1 と 2 はモデルごと（Haiku の回、Sonnet の回のそれぞれ）、3 と 4 は 2 つのモデルを合わせた回で数える。役を 2 つ（はじめての人・前に使った人）で回す画面は、役ごとに合否を付ける。回数は各 3 回（合わせて 6 回）の時の数で書く。回数を増やした時は、同じ割合で数える（3 分の 2、3 分の 1。端数は切り上げる。例: 8 回なら 3 分の 1 は 3 回）。

1. q1・q2・q3 が、3 回のうち 2 回以上正しい。
2. お金・取り消せないことを読み違えた回が 0。
3. 同じ区画が、6 回のうち 2 回以上「長い」（q4）と言われていない。言われた区画は直す所。
4. 読ませたい区画が、6 回のうち 2 回以上「飛ばした」（q5）と言われていない。読ませたい区画のうち、いちばん大事な 1 つ（お金・取り消せない結果。どちらも無い画面は利用者がすること。それも無ければこの部分は付けない）は、q6 に 6 回のうち 4 回以上出てくる。
5. 直した後は、1〜4 のうち前に満たしていたものを、後も満たす（回数の小さな揺れではなく、合否で比べる）。画面を分けた・まとめた版や、区画を組み直した版では、前後の画面・区画の対応を書いて比べる。

直せない区画（C の文言、確認中の画面など）で 3 か 4 を満たせない時は、理由を書いて聞く案に回し、その区画を 3・4 の数から除いて合否を付ける。除いた区画と理由は報告に書く。

**記録**: 回ごとの答えの全文と集計の表を残し、PR と報告に、回数（モデルごと）・effort・合格したか・通らなかった所を書く。

**限界**: 安いモデルも人ではない（2 節）。q4・q5 は AI の自己申告。聞かれると何かを挙げがちなので、「無ければ『なし』」と書いて聞く（試しでは、短い画面に 6 回中 4 回が「なし」と答えた）。合格しても、人で確かめる（4 節）。

**実行者に渡す文の雛形**

```md
あなたは <誰として: 例「スマホでネットショップの買い物をしていて、支払い方法に〇〇を選んだ人。はじめて使う」> です。説明を熟読するタイプではありません。ふだんのスマホと同じように、ざっと流し読みしてください。
画面の画像を順に見せます。手がかりは画像だけです。画像を開く以外のことはしないでください。縦に長い画面は分けてあるので、同じ画面の画像を全部見てから、その画面について答えてください。
<画面の一覧（流れの順）>
各画面について、短く答えてください。
- q1：最初の 3 秒で、何をする画面だと思ったか
- q2：次にどこを押すか（書かれている名前）
- q3：押した後、この先に何が起きると思うか
- q4：長いと感じた所（無ければ「なし」）
- q5：読まずに飛ばした所（無ければ「なし」）
- q6：画面を閉じた後に覚えていること（3 つまで）
答えは JSON だけで返してください。{"1":{"q1":"","q2":"","q3":"","q4":"","q5":"","q6":[]}, …}
```

**試しの結果**（2026-11-27。パスキーを作って払う流れの試作 4 画面、Haiku 3 回・Sonnet 3 回、effort は xhigh）: 次に押す物は、6 回とも全画面で正しかった。承認の画面の頭に残した緑の「できました」の箱と、直前の操作をなぞった区画は、6 回とも「長い」と言われた。緑の箱は 3 回が「飛ばした」と答えた。完了の画面で同じ注意をもう一度出した所は、Haiku の 3 回とも「前の画面と同じ内容」と気づいた。流し読みでも操作はできるが、長さは感じている。

## 出典

- Zhou ほか「Mind the Sim2Real Gap in User Simulation for Agentic Tasks」（2026） https://arxiv.org/abs/2603.11245
- Zhong ほか「Synthetic Heuristic Evaluation: A Comparison between AI- and Human-Powered Usability Evaluation」（2025。要旨で確認） https://arxiv.org/abs/2507.02306
- NN/g「Cognitive Walkthroughs」 https://www.nngroup.com/articles/cognitive-walkthroughs/
- 段ごとに聞く問いは、認知的ウォークスルーの 4 問と、ファーストクリックテストの考え方を、画像だけで聞ける形にしたもの（この skill 独自の形）。
