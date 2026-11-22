// メイン導線を通す様子を録画し、場面ごとのスクリーンショットと「どこの話か」の位置を残す。
// Playwright はプロジェクトのものを渡す（この skill には入れていない）。隔離したブラウザで、テスト用のデータだけで通す。
//
//   import { chromium } from "playwright";
//   import { record } from "<この skill のディレクトリ>/scripts/recorder.mjs";
//   await record({ chromium, out: "<出力先>", baseURL: "http://localhost:5173", viewport: { width: 390, height: 844 } }, async ({ page, step }) => {
//     await page.goto("/cart");
//     await step("カートを開いた", { total: page.getByText("合計"), next: page.getByRole("button", { name: "レジに進む" }) });
//     await page.getByRole("button", { name: "レジに進む" }).click();
//     await step("支払い方法の画面");
//   });
//   // <出力先>/video.webm, step-NN.png, steps.json。途中で例外が出ても、そこまでを残してから例外を投げ直す（steps.json の incomplete に理由）
//
//   node recorder.mjs --self-test <Playwright の index.mjs の path>
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

// URL の ? と # の後ろには、鍵や識別子が入りやすい。記録には残さない
const noQuery = (url) => String(url).split(/[?#]/)[0];
// 投げられた値が null や空文字でも、理由を必ず文字で残す
const reasonOf = (e) => String(e?.message ?? e).split("\n")[0].slice(0, 300) || "例外（理由なし）";

export async function startRecording({ chromium, out, baseURL, viewport = { width: 1280, height: 800 }, contextOptions = {}, launchOptions = {}, settleMs = 800, holdMs = 1800 }) {
  if (!chromium?.launch) throw new Error("startRecording: プロジェクトの Playwright の chromium を渡す");
  await fs.mkdir(out, { recursive: true });
  const browser = await chromium.launch(launchOptions);
  let context, page;
  try {
    context = await browser.newContext({ baseURL, viewport, ...contextOptions, recordVideo: { dir: out, size: viewport } });
    page = await context.newPage();
  } catch (e) {
    await browser.close().catch(() => {});
    throw e;
  }
  const t0 = Date.now();
  const steps = [];
  let logs = [];
  const log = (kind, text) => logs.push({ kind, text: String(text).slice(0, 400) });
  page.on("console", (m) => m.type() === "error" && log("console", m.text()));
  page.on("pageerror", (e) => log("pageerror", e));
  page.on("requestfailed", (r) => log("requestfailed", `${r.method()} ${noQuery(r.url())} ${r.failure()?.errorText ?? ""}`));
  page.on("response", (r) => r.status() >= 400 && log("http", `${r.status()} ${r.request().method()} ${noQuery(r.url())}`));

  // 1 つの場面を残す。marks は { 名前: locator }。見つからない locator は null になる（指摘は位置なしで出る）。
  async function step(title, marks = {}) {
    await page.waitForTimeout(settleMs); // 動画に、その場面が映っている時間を作る
    const boxes = {};
    for (const [name, locator] of Object.entries(marks)) {
      boxes[name] = await locator.first().boundingBox({ timeout: 1500 }).catch(() => null);
    }
    const n = steps.length + 1;
    const screenshot = `step-${String(n).padStart(2, "0")}.png`;
    const t = (Date.now() - t0) / 1000;
    await page.screenshot({ path: path.join(out, screenshot) });
    steps.push({ n, title, t, url: noQuery(page.url()), screenshot, viewport: page.viewportSize(), marks: boxes, logs });
    logs = [];
    await page.waitForTimeout(holdMs); // 見る人が場面を読めるだけ、動画の中で止まる
  }

  // 何度呼んでも 1 回だけ動く。動画の保存に失敗しても steps.json は書き、ブラウザは必ず閉じる。
  // reason は、途中で止まった理由の文字（最後まで通った時は渡さない）。
  let finished = null;
  const finish = (reason) => (finished ??= doFinish(reason));
  async function doFinish(reason) {
    const problems = [];
    let videoFile = null;
    const video = page.video();
    await context.close().catch((e) => problems.push(`context: ${e.message}`)); // 動画は、context を閉じた時に書き出される
    if (video) {
      try {
        await fs.rename(await video.path(), path.join(out, "video.webm"));
        videoFile = "video.webm";
      } catch (e) {
        problems.push(`video: ${e.message}`);
      }
    }
    await browser.close().catch(() => {});
    if (reason != null) problems.unshift(String(reason) || "例外（理由なし）");
    const file = path.join(out, "steps.json");
    const data = { recordedAt: new Date(t0).toISOString(), baseURL: baseURL == null ? null : noQuery(baseURL), viewport, video: videoFile, incomplete: problems.length ? problems.join(" / ") : null, steps, afterLastStep: logs };
    await fs.writeFile(file, JSON.stringify(data, null, 2) + "\n");
    return file;
  }

  return { page, context, step, finish };
}

// 通す処理を渡す形。途中で例外が出ても、そこまでの動画と steps.json を残してから、例外を投げ直す。
export async function record(options, run) {
  const rec = await startRecording(options);
  let failed = false;
  let error;
  try {
    await run(rec);
  } catch (e) {
    failed = true; // null や 0 が投げられても、止まったことを落とさない
    error = e;
  }
  const file = await rec.finish(failed ? reasonOf(error) : undefined);
  if (failed) throw error;
  return file;
}

async function selfTest(playwrightPath) {
  if (!playwrightPath) throw new Error("使い方: node recorder.mjs --self-test <Playwright の index.mjs の path>");
  const { chromium } = await import(pathToFileURL(path.resolve(playwrightPath)).href);
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), "ux-rec-"));
  const fast = { chromium, viewport: { width: 320, height: 240 }, settleMs: 50, holdMs: 50 };
  const read = async (d) => JSON.parse(await fs.readFile(path.join(d, "steps.json"), "utf8"));
  const check = (ok, what) => { if (!ok) throw new Error(`self-test: ${what}`); };
  try {
    const ok = path.join(dir, "ok");
    await record({ ...fast, out: ok }, async ({ page, step }) => {
      await page.setContent('<button id="a">押す</button>');
      await step("最初", { a: page.locator("#a"), gone: page.locator("#none") });
      await page.evaluate(() => setTimeout(() => { throw new Error("after the last step"); }, 0));
    });
    const a = await read(ok);
    check(a.incomplete === null && a.video === "video.webm" && a.steps.length === 1, "通常の録画");
    check(a.steps[0].marks.a?.width > 0 && a.steps[0].marks.gone === null, "見つかる要素と見つからない要素");
    check(a.afterLastStep.some((l) => l.text.includes("after the last step")), "最後の場面の後のエラーも残る");
    await fs.access(path.join(ok, "video.webm"));

    const broken = path.join(dir, "broken");
    let thrown = null;
    await record({ ...fast, out: broken }, async ({ page, step }) => {
      await page.setContent("<p>x</p>");
      await step("途中まで");
      throw new Error("click timeout\nsecond line");
    }).catch((e) => { thrown = e; });
    const b = await read(broken);
    check(thrown?.message.startsWith("click timeout"), "例外は投げ直す");
    check(b.incomplete === "click timeout" && b.steps.length === 1 && b.video === "video.webm", "途中で止まっても、そこまでを残す");

    const falsy = path.join(dir, "falsy");
    let caught = "nothing";
    await record({ ...fast, out: falsy, baseURL: "http://localhost:5173/?token=SECRET#PRIVATE" }, async ({ page, step }) => {
      await page.setContent("<p>x</p>");
      await step("途中");
      throw null;
    }).catch((e) => { caught = e; });
    const c = await read(falsy);
    check(caught === null && c.incomplete === "null" && c.steps.length === 1, "null が投げられても、途中で止まったと残す");
    check(c.baseURL === "http://localhost:5173/", "baseURL の ? と # の後ろは残さない");
    console.log("self-test ok");
  } finally {
    await fs.rm(dir, { recursive: true, force: true });
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url) && process.argv[2] === "--self-test") {
  await selfTest(process.argv[3]);
}
