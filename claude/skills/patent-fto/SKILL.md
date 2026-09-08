---
name: patent-fto
description: >-
  Run a structured, high-accuracy AI-assisted patent FTO (Freedom to Operate / 抵触調査) triage: decompose the
  invention into claim elements, design multi-faceted searches (keyword × CPC/IPC × citation), cross-search free
  patent databases, build element-by-element claim charts, verify every patent number and claim against primary
  sources, label confidence (verified/plausible/screening), and produce a patent-attorney handoff package. Japanese-
  law adapted (J-PlatPat primary, 均等論/間接侵害, 山本弁護士 review). Use when asked for FTO, freedom-to-operate,
  特許抵触調査, 特許侵害調査, prior-art screening, 特許クリアランス, patent clearance, or "can we operate without
  infringing". NOT an FTO opinion and NOT for drafting patent claims (that is attorney work); NOT for smart-contract
  security audits (use smart-contract-audit).
---

# Patent FTO Triage (AI支援・高精度・弁理士ハンドオフ前提)

This produces a **first-pass FTO triage**, never an FTO opinion. Adapted from Anthropic official
`claude-for-legal/ip-legal/fto-triage` plus an empirically-validated AI-FTO methodology (2-system convergence).

## Non-negotiable guardrails (put these in every output)

- **「これはFTO意見書ではない / This is NOT a freedom-to-operate opinion.」** Top of every output.
- **Never conclude "does not infringe" / 「侵害しない」と結論しない.** Possible verdicts only:
  「全要素を充足。弁理士レビュー必須」「1つ以上の要素が明確には存在しない。弁理士レビュー必須」「クレーム解釈が決定的。弁理士の解釈が必要」.
- **Willfulness note**: surfacing specific patents creates knowledge; proceeding without counsel can support willful
  infringement (35 U.S.C. §284 treble damages 等). Path forward must be documented by counsel.
- **No-DB fallback**: if a patent DB could not be searched, state literally **「No patent database search was run」**
  and proceed only on user-supplied/known patents.
- **Scope-out (route to counsel)**: 意匠(D)/再発行(RE)/植物特許(PP), claim construction, validity, damages,
  特許クレーム起案, trademark/trade-secret. Utility patents only here.
- **Jurisdiction**: US/EU claim charting (du Pont 等) does NOT transfer to JP/CN/EU-UPC. JP needs 均等論・間接侵害 review.
- **Risk–Confidence Gate（再発防止・必須）**: 独立クレーム原文を **verbatim 取得していない特許を High/Med と断定しない**。verbatim 未取得なら risk は `screening・要原本確認` に留め、危険・安全どちらにも断定しない（All-elements rule は両刃：読めなければ侵害も回避も確信できない）。あるクレーム限定が「必須か任意か」は**独立/従属を原文で読んで**確定し、**推測でリスクを上下させない**。敵対的検証がリスクを**上げてよいのはクレームを読んで実際の充足経路を見つけたときのみ**（「〜は任意かもしれない」という推測で High にしない）。サマリでは risk と confidence と verbatim可否を**常にセットで**出す。
- **失敗事例（2026-06-09）**: US11080687B2 を claim 1 未取得のまま「cross-chain bridge は任意かも」と推測し High と誤判定 → 逐語取得で必須要件と判明し Low（回避）に訂正。**原本未取得の推測でアラートを出さない。**
- **This project**: legal-judgment changes require **山本雄大弁護士 review** (CLAUDE.md 重要規律1).

## Workflow

Create a TodoWrite item per phase. Phases 0–5 are AI; phase 6 is the human handoff.

**Ordering rule (再発防止の核)**: 詳細調査（独立クレーム原文の逐語取得）を**判断より前**に必ず置く。Phase 2 を通過して
いない候補に対し、Phase 3 以降の charting・リスク判断・回避/抵触の結論を**一切出さない**。これは今回の失敗
（詳細を見ずに推測でリスク判定）を構造的に封じるための順序。

### Phase 0 — Scope & access
1. Restate the invention as **functional/technical units** (not just product names — product-name-only search misses
   reworded/abstracted claims). Capture: 構成要素 (claim elements), 法域 (jurisdictions), timing, known patents,
   競合企業/主要発明者.
2. Confirm which databases are actually fetchable now (see `references/databases.md`). If none → No-DB fallback.
3. Set jurisdiction priority for this run (default this project: **JP必須 / US・CN重点 / EP努力**).

### Phase 1 — Search design (multi-faceted; never keyword-only)
4. Collect **seed patents** by keyword, extract **CPC/IPC codes** from seeds, frequency-analyze them.
5. Build a search matrix: keywords × synonyms (JP/EN/特許用語/実装用語/競合製品名) × CPC/IPC/FI/Fターム × assignee ×
   citation × family × jurisdiction. OR the classification field with the claim field to catch non-keyword hits.
6. Run across **Google Patents + Espacenet + J-PlatPat(JP) + USPTO(PPUBS/ODP)**; iterate. **Log every search**
   (DB, URL, date, query string, hit count, accept/reject reason) — searches must be reproducible.

### Phase 2 — Claim acquisition gate (詳細調査・判断の前に必須) ★MUST run before any judgment
7. **Confirm every candidate patent exists in a primary DB.** A number you cannot open is dropped, not cited.
8. **Fetch the INDEPENDENT claim(s) verbatim for every candidate** before charting or any risk verdict. Try in order:
   `patents.google.com/patent/<番号>/en|ja|zh` (WebFetch) → if claims are dropped (JS/SPA), **fall back**: the Google
   Patents family page, Espacenet, J-PlatPat (JP), FPO, BigQuery `patents-public-data`, or `curl -L` the page and grep
   the claims block. Record `verbatim_obtained: true/false` per candidate.
9. **Separate independent vs dependent claims explicitly.** A limitation living in a dependent claim is OPTIONAL, not a
   mandatory element of the independent claim — never treat the two as equivalent.
10. **Gate**: any candidate whose independent claim could NOT be obtained verbatim is parked as
    `screening・要原本確認` and receives **NO risk verdict** (neither High/Med nor "cleared"). It only proceeds to
    Phase 3 once the verbatim claim is in hand. Do not chart or judge on abstracts/summaries.

### Phase 3 — Claim charting (only on Phase-2-cleared candidates)
11. Chart **independent claims by limitation** (all-elements rule: one missing element = no literal infringement). Do
    not over-weight dependent claims. See `references/claim-charting.md`.
12. Map each limitation to the invention; per element label **Disclosed / Suggested / None**.
13. Judge on the **actual claim scope, not the spec** (feature fallacy). Keep literal read separate from 均等論.

### Phase 4 — Adversarial verification (the precision core)
14. **Adversarial verification**: have an independent agent/Codex try to *refute* each "we avoid this patent"
    conclusion, re-reading the verbatim claim. Risk may be RAISED only when a real satisfied path is found in the
    claim text — never from speculation that "X might be optional". Keep the conclusion only if it survives.

### Phase 5 — Confidence labels & risk routing
15. Label each patent **screening / plausible / verified** (verified = independent claim text + legal status
    human-checked). **Risk–Confidence Gate (already enforced by Phase 2)**: no High/Med exists for any patent without a
    verbatim independent claim. Always present **risk × confidence × verbatim可否** together.
16. Route the most restrictive / highest-risk patents first to human review.

### Phase 6 — Handoff (human / 弁理士)
17. Build the handoff package: search log, search queries, candidate list, original claim PDFs/URLs, claim charts,
    open questions, design-around candidates, and the **`[人間必須]` list** from `references/claim-charting.md`.
18. Mark the deliverable **「FTO triage / research package」(NOT an opinion)** and route to 山本雄大弁護士.

## Running the two-system high-accuracy pass (recommended)

For a real FTO, run two independent systems and converge (this is what makes AI-FTO defensible):
- **System 1 (Claude)**: a `Workflow` pipeline where each candidate first passes the **Phase 2 claim-acquisition gate
  (fetch verbatim independent claim)**, then is charted, then an adversarial verifier (refute-by-default) re-reads the
  verbatim claim. Schema-force structured output; carry `verbatim_obtained` through every stage.
- **System 2 (Codex)**: dispatch the same scope to Codex CLI (see the `codex` skill) as an independent searcher, with
  the same instruction to fetch verbatim claims before judging.
- Merge: report **convergence vs divergence**; let the adversarial pass correct citation errors (a known failure mode
  — see methodology). Divergence between systems is a signal to re-verify, not to average.

## References
- `references/databases.md` — free patent DBs (JP/US/CN/EP), fetch capability & gotchas, cross-search order.
- `references/claim-charting.md` — claim-chart method, JP 均等論/間接侵害 notes, the `[人間必須]` handoff list,
  the boilerplate disclaimer block to paste into outputs.

## Hard limits (do not cross)
Do not issue FTO opinions, construe claims, adjudicate validity, draft patent claims, model damages, or tell anyone
they are "clear to launch". Those are registered patent counsel's calls.
