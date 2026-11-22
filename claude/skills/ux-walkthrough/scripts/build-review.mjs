#!/usr/bin/env node
// 録画（steps.json）と、実装側の観察と提案（review.json）から、ブラウザで見る確認ページ（index.html）を作る。
//
//   node build-review.mjs <録画のディレクトリ>
//   node build-review.mjs --self-test
//
// review.json（このセッションが書く）:
//   { "flow": "checkout", "title": "商品を買う", "persona": "…", "task": "…",
//     "rev": "<録画した版のコミット。記録する時は、この値を flows.py record --rev に渡す>", "env": "<URL>",
//     "summary": "全体を 3 行以内で", "notChecked": ["確かめていないこと", "…"],
//     "findings": [ { "step": 2, "mark": "next", "kind": "concern|idea|gap|good", "severity": 0-4,
//                     "what": "何が気になるか", "why": "なぜ（誰の、何とずれるか）", "now": "いまの文言や見た目", "proposal": "具体的な直し方" } ] }
// step は steps.json の n。mark は、その場面で recorder に渡した名前（省くと、位置なしで出る）。
// good 以外は why・proposal・severity が要る。入力が形に合わなければ、ページを作らずに exit 2。
import { createHash } from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const KINDS = ["concern", "idea", "gap", "good"];
const here = path.dirname(fileURLToPath(import.meta.url));

class Invalid extends Error {}
const bad = (msg) => { throw new Invalid(msg); };
const isObj = (v) => v !== null && typeof v === "object" && !Array.isArray(v);
const isStr = (v) => typeof v === "string" && v.trim() !== "";
const isNum = (v) => typeof v === "number" && Number.isFinite(v);

function readJSON(file) {
  try {
    return JSON.parse(fs.readFileSync(file, "utf8"));
  } catch (e) {
    bad(`${file} を読めない: ${e.message}`);
  }
}

// 動画と画像は、録画のディレクトリにあるファイルだけ。外の URL や別の場所の path は受け付けない
function localFile(dir, name, at) {
  if (!isStr(name) || name !== path.basename(name) || !fs.existsSync(path.join(dir, name))) bad(`${at}: 録画のディレクトリにあるファイルの名前にする（${JSON.stringify(name)}）`);
}
function viewport(v, at) {
  if (!isObj(v) || !(isNum(v.width) && v.width > 0 && isNum(v.height) && v.height > 0)) bad(`${at}: viewport は正の width と height`);
}
function logs(v, at) {
  if (!Array.isArray(v) || !v.every((l) => isObj(l) && typeof l.kind === "string" && typeof l.text === "string")) bad(`${at}: logs は { kind, text } の配列`);
}

function checkRecording(dir, rec) {
  if (!isObj(rec) || !Array.isArray(rec.steps) || rec.steps.length === 0) bad("steps.json に場面が 1 つも無い");
  if (!isStr(rec.recordedAt) || Number.isNaN(Date.parse(rec.recordedAt))) bad("steps.json の recordedAt が日時でない");
  if (rec.video != null) localFile(dir, rec.video, "steps.json の video");
  if (rec.incomplete != null && !isStr(rec.incomplete)) bad("steps.json の incomplete は文字列か null");
  viewport(rec.viewport, "steps.json");
  logs(rec.afterLastStep ?? [], "steps.json の afterLastStep");
  const seen = new Set();
  let prev = 0;
  rec.steps.forEach((s, i) => {
    const at = `steps[${i}]`;
    if (!isObj(s)) bad(`${at}: 場面の形でない`);
    if (!Number.isInteger(s.n) || seen.has(s.n)) bad(`${at}: n は重複しない整数`);
    seen.add(s.n);
    if (!isStr(s.title)) bad(`${at}: title が無い`);
    if (!isNum(s.t) || s.t < prev) bad(`${at}: t は 0 以上で、前の場面より後の時刻`);
    prev = s.t;
    localFile(dir, s.screenshot, `${at} の screenshot`);
    viewport(s.viewport, at);
    if (!isObj(s.marks)) bad(`${at}: marks は { 名前: 位置 } の形`);
    for (const [name, b] of Object.entries(s.marks)) {
      if (b !== null && !(isObj(b) && ["x", "y", "width", "height"].every((k) => isNum(b[k])))) bad(`${at}: marks.${name} は位置（x, y, width, height）か null`);
    }
    logs(s.logs, at);
  });
}

function checkReview(rec, review) {
  if (!isObj(review)) bad("review.json の形が違う");
  for (const k of ["flow", "title", "persona", "task", "rev", "env"]) {
    if (!isStr(review[k])) bad(`review.json に ${k} が無い`);
  }
  if (!/^[0-9a-f]{7,64}$/.test(review.rev)) bad("review.json の rev は、録画した版のコミット（16 進の 7 文字以上）");
  if (review.summary != null && typeof review.summary !== "string") bad("review.json の summary は文字列");
  if (review.notChecked != null && !(Array.isArray(review.notChecked) && review.notChecked.every(isStr))) bad("review.json の notChecked は文字列の配列");
  if (!Array.isArray(review.findings)) bad("review.json の findings は配列にする（無ければ空の配列）");
  const byN = new Map(rec.steps.map((s) => [s.n, s]));
  review.findings.forEach((f, i) => {
    const at = `findings[${i}]`;
    if (!isObj(f)) bad(`${at}: 指摘の形でない`);
    const step = byN.get(f.step);
    if (!step) bad(`${at}: step ${JSON.stringify(f.step)} が steps.json に無い`);
    if (!KINDS.includes(f.kind)) bad(`${at}: kind は ${KINDS.join(" / ")} のどれか`);
    if (!isStr(f.what)) bad(`${at}: what（何が気になるか）が無い`);
    for (const k of ["why", "now", "proposal"]) {
      if (f[k] != null && typeof f[k] !== "string") bad(`${at}: ${k} は文字列`);
    }
    if (f.kind !== "good") {
      if (!isStr(f.why)) bad(`${at}: why（なぜ気になるか）が無い`);
      if (!isStr(f.proposal)) bad(`${at}: proposal（具体的な直し方）が無い`);
      if (!(Number.isInteger(f.severity) && f.severity >= 0 && f.severity <= 4)) bad(`${at}: severity は 0〜4 の整数`);
    }
    if (f.mark != null && !(typeof f.mark === "string" && Object.hasOwn(step.marks, f.mark))) bad(`${at}: mark ${JSON.stringify(f.mark)} は、場面 ${f.step} で recorder に渡していない`);
  });
}

export function build(dir) {
  const rec = readJSON(path.join(dir, "steps.json"));
  const review = readJSON(path.join(dir, "review.json"));
  checkRecording(dir, rec);
  checkReview(rec, review);
  // id は、録画と指摘の中身から作る。ページが覚えた判断は、中身が 1 文字でも変われば引き継がれない
  const id = createHash("sha256").update(JSON.stringify({ rec, review })).digest("hex").slice(0, 16);
  // ページの文字は全部 textContent で入れる。ここでは、script を閉じる並びだけを避ける
  const data = JSON.stringify({ id, rec, review }).replace(/</g, "\\u003c");
  const template = fs.readFileSync(path.join(here, "..", "assets", "review-template.html"), "utf8");
  if (!template.includes("__DATA__")) bad("review-template.html に __DATA__ が無い");
  const out = path.join(dir, "index.html");
  fs.writeFileSync(out, template.replace("__DATA__", () => data));
  return out;
}

function selfTest() {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "ux-review-"));
  const write = (name, v) => fs.writeFileSync(path.join(dir, name), JSON.stringify(v));
  const step = () => ({ n: 1, title: "t", t: 1, url: "u", screenshot: "step-01.png", viewport: { width: 100, height: 100 }, marks: { a: { x: 1, y: 2, width: 3, height: 4 }, gone: null }, logs: [] });
  const recording = () => ({ recordedAt: "2026-01-01T00:00:00Z", video: null, incomplete: null, viewport: { width: 100, height: 100 }, steps: [step()], afterLastStep: [] });
  const finding = () => ({ step: 1, mark: "a", kind: "concern", severity: 3, what: "</script><b>x", why: "w", proposal: "p" });
  const reviewOf = (findings) => ({ flow: "f", title: "t", persona: "p", task: "k", rev: "abc1234", env: "e", findings });
  const ok = (cond, what) => { if (!cond) throw new Error(`self-test: ${what}`); };
  const rejects = (what, mutate) => {
    const rec = recording();
    const review = reviewOf([finding(), { step: 1, mark: "gone", kind: "good", what: "g" }]);
    mutate(rec, review);
    write("steps.json", rec);
    write("review.json", review);
    try {
      build(dir);
    } catch (e) {
      if (e instanceof Invalid) return;
      throw e;
    }
    throw new Error(`self-test: 受け付けてはいけない入力を通した: ${what}`);
  };
  try {
    fs.writeFileSync(path.join(dir, "step-01.png"), "");
    write("steps.json", recording());
    write("review.json", reviewOf([finding(), { step: 1, mark: "gone", kind: "good", what: "g" }]));
    const first = fs.readFileSync(build(dir), "utf8");
    ok(!first.includes("__DATA__") && !first.includes("</script><b>x") && first.includes("\\u003c/script>\\u003cb>x"), "文字を安全に埋め込む");
    const idOf = (html) => /"id":"([0-9a-f]{16})"/.exec(html)?.[1];
    write("review.json", reviewOf([{ ...finding(), what: "別の指摘", severity: 4 }]));
    ok(idOf(first) && idOf(first) !== idOf(fs.readFileSync(build(dir), "utf8")), "中身が変われば id が変わる");

    rejects("場面の viewport が無い", (r) => delete r.steps[0].viewport);
    rejects("logs が配列でない", (r) => { r.steps[0].logs = "bad"; });
    rejects("場面の番号が重複", (r) => r.steps.push(step()));
    rejects("時刻が負", (r) => { r.steps[0].t = -2; });
    rejects("marks が無いのに mark を指す", (r, v) => { delete r.steps[0].marks; v.findings[0].mark = "toString"; });
    rejects("mark が継承された名前", (_, v) => { v.findings[0].mark = "toString"; });
    rejects("mark が文字列でない", (_, v) => { v.findings[0].mark = ["a"]; });
    rejects("why が文字列でない", (_, v) => { v.findings[0].why = { bad: 1 }; });
    rejects("why が無い", (_, v) => delete v.findings[0].why);
    rejects("存在しない場面", (_, v) => { v.findings[0].step = 9; });
    rejects("動画が外の URL", (r) => { r.video = "https://example.invalid/track.webm"; });
    rejects("画像が別の場所", (r) => { r.steps[0].screenshot = "../step-01.png"; });
    rejects("rev がコミットでない", (_, v) => { v.rev = "main"; });
    rejects("指摘が指摘の形でない", (_, v) => { v.findings[0] = "x"; });
    console.log("self-test ok");
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const arg = process.argv[2];
  try {
    if (arg === "--self-test") selfTest();
    else if (!arg) bad("使い方: node build-review.mjs <録画のディレクトリ>");
    else console.log(build(arg));
  } catch (e) {
    if (!(e instanceof Invalid)) throw e;
    console.error(`error: ${e.message}`);
    process.exit(2);
  }
}
