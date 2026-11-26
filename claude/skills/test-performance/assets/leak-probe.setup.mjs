// Diagnostic only: add to `setupFiles` for one run, never commit it to a project. Node-side pools only.
// For each test file, records what the file leaves behind (globals, prototypes, env, fake timers, DOM).
// It compares the start and end of the same file, so no special order is needed. Run it in the current isolated
// setup; in vm pools, restored fake timers show up as "changed globalThis.Temporal" and similar.
// Not seen: module state, vi.mock, pending timers, changes inside an object (config.flag = true),
// and anything in Browser Mode. See references/isolation.md.
import { appendFileSync } from "node:fs";
import { beforeAll, expect, vi } from "vitest";

const out = process.env.LEAK_PROBE_OUT;
if (!out) throw new Error("set LEAK_PROBE_OUT to a file path");

const targets = { globalThis };
for (const name of ["Object", "Array", "String", "Function", "Promise", "Date", "Map", "Set", "EventTarget", "Node",
  "Element", "HTMLElement", "HTMLDialogElement", "HTMLInputElement", "HTMLCanvasElement", "Document", "Window",
  "Storage", "Navigator", "Location", "Request", "Response", "Headers", "URL", "AbortController", "AbortSignal", "Event",
  "Blob", "TextEncoder", "Buffer", "WebSocket", "Crypto", "SubtleCrypto"]) {
  const value = globalThis[name];
  if (value) targets[name] = value;
  if (value?.prototype) targets[`${name}.prototype`] = value.prototype;
}
for (const name of ["Math", "JSON", "console", "performance", "process", "navigator", "location", "document", "crypto"]) {
  if (globalThis[name]) targets[name] = globalThis[name];
}
for (const name of ["fs", "fs/promises", "path", "os", "crypto", "child_process", "http", "https", "net", "dns", "timers"]) {
  const module = process.getBuiltinModule?.(`node:${name}`); // Node 22.3+
  if (module) targets[`node:${name}`] = module;
}

const symbols = new Map(); // two symbols may share a description
const label = (key) => {
  if (typeof key === "string") return key;
  if (!symbols.has(key)) symbols.set(key, `${String(key)}#${symbols.size}`);
  return symbols.get(key);
};

function take() {
  const state = new Map();
  for (const [name, object] of Object.entries(targets)) {
    for (const key of Reflect.ownKeys(object)) {
      state.set(`${name}.${label(key)}`, Object.getOwnPropertyDescriptor(object, key));
    }
  }
  const set = (key, value) => state.set(key, { value });
  for (const [key, value] of Object.entries(process.env)) set(`env.${key}`, value);
  for (const event of process.eventNames()) set(`process.on(${String(event)})`, process.listenerCount(event));
  set("fake timers", vi.isFakeTimers());
  if (globalThis.document?.documentElement) {
    set("document", document.documentElement.outerHTML);
    set("location.href", globalThis.location?.href);
    for (const name of ["localStorage", "sessionStorage"]) {
      try { set(name, JSON.stringify({ ...globalThis[name] })); } catch { /* opaque origin */ }
    }
  }
  return state;
}

const same = (a, b) => ["value", "get", "set", "writable", "enumerable", "configurable"].every((k) => Object.is(a[k], b[k]));

const before = take();
// The cleanup returned by the first beforeAll runs after every afterAll and every other cleanup
// (with the default `sequence.hooks: "stack"`).
beforeAll(() => () => {
  vi.restoreAllMocks(); // Vitest does this after every file, so a spy is not a leak
  const after = take();
  const leaks = [];
  for (const key of new Set([...before.keys(), ...after.keys()])) {
    const [a, b] = [before.get(key), after.get(key)];
    if (a && b && same(a, b)) continue;
    leaks.push(`${a ? (b ? "changed" : "deleted") : "added"} ${key}`);
  }
  appendFileSync(out, `${JSON.stringify({ file: expect.getState().testPath, leaks })}\n`);
});
