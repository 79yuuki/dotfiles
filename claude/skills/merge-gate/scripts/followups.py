#!/usr/bin/env python3
"""What happened after merge: join merge-gate verdicts with later fixes and reverts.

  followups.py OWNER/REPO [--days 60] [--window-hours 48] [--config merge-gate.toml] [--json]
  followups.py --self-test

Read-only. Needs an authenticated `gh`. Fetches titles, merge times, head SHAs and file
paths only (no authors). With --config it also reports the rule-only ceiling of each PR,
so the rules can be scored against history without any verdicts.

shortcut: a follow-up is "a later fix/revert PR touching one of the same files within the
window". It does not prove the first PR caused it; read the pair before blaming the verdict.
Files that a large share of all PRs touch (translation tables, manifests) are left out of the
match, because two PRs sharing such a file says nothing; see --hub-share. A PR that touched only
such files is reported as undetermined, and a revert that names a PR always counts.
"""
import argparse
import collections
import datetime as dt
import json
import os
import re
import subprocess
import sys
import tomllib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from classify_diff import DEFAULT_PREFIXES, FILES_JQ, classify, matches, parse_files, title_kind  # noqa: E402

VERDICTS = os.path.expanduser("~/.claude/state/merge-gate/verdicts.jsonl")
DEFAULT_IGNORE = ["**/pnpm-lock.yaml", "**/package-lock.json", "**/yarn.lock", "**/Cargo.lock", "**/package.json"]
FOLLOWUP_KINDS = {"fix", "hotfix", "revert"}
VERDICT_VALUES = {"high", "medium", "low"}
PR_LIMIT = 1000


def ts(s):
    return dt.datetime.fromisoformat(s.replace("Z", "+00:00"))


def is_revert(title):
    return title.lower().startswith("revert") or title_kind(title)[0] == "revert"


def is_followup(title):
    return title_kind(title)[0] in FOLLOWUP_KINDS or is_revert(title)


def hub_files(prs, share, floor=5):
    """Files touched by at least `share` of the PRs (and at least `floor` PRs). share <= 0 turns it off."""
    if share <= 0:
        return set()
    counts = collections.Counter(f for p in prs for f in set(p["files"]))
    return {f for f, n in counts.items() if n >= max(floor, share * len(prs))}


def names(revert_title, pr):
    """Does a revert PR's title point at this PR (by number or by quoting its title)?"""
    numbers = {int(n) for n in re.findall(r"#(\d+)", revert_title)}
    return pr["number"] in numbers or pr["title"] in revert_title


def find_followups(prs, window_hours, prefixes, ignore, now, hubs=frozenset()):
    """prs: [{number,title,mergedAt,files:[path]}]. One row per PR whose kind is in prefixes.

    pending: merged less than window_hours ago, so the outcome is not known yet.
    followups: later fix/revert PRs sharing a file that is not a hub, or a revert naming this PR.
    hub_only: later fix/revert PRs sharing only hub files. Kept so a reader can check them.
    undetermined: the PR touched nothing but hub or ignored files and no revert names it, so
    file overlap cannot say anything about it. Counted apart, never as "no follow-up".
    """
    prs = sorted(prs, key=lambda p: p["mergedAt"])
    window = dt.timedelta(hours=window_hours)
    rows = []
    for i, p in enumerate(prs):
        if title_kind(p["title"])[0] not in prefixes:
            continue
        counted = {f for f in p["files"] if not matches(f, ignore)}
        mine, later, hub_only = counted - hubs, [], []
        for q in prs[i + 1:]:
            if ts(q["mergedAt"]) - ts(p["mergedAt"]) > window:
                break
            if not is_followup(q["title"]):
                continue
            if mine & set(q["files"]) or (is_revert(q["title"]) and names(q["title"], p)):
                later.append(q)
            elif counted & set(q["files"]):
                hub_only.append(q)
        rows.append({
            "number": p["number"],
            "head_sha": p.get("headRefOid"),
            "mergedAt": p["mergedAt"],
            "pending": now - ts(p["mergedAt"]) < window,
            "undetermined": not mine and not later,
            "followups": [q["number"] for q in later],
            "hub_only": [q["number"] for q in hub_only],
            "reverted": any(is_revert(q["title"]) for q in later),
        })
    return rows


def load_verdicts(path, repo):
    """-> ({(pr, head_sha): verdict} for this repo, number of unreadable lines)."""
    out, bad = {}, 0
    if os.path.exists(path):
        with open(path) as f:
            for line in f:
                if not line.strip():
                    continue
                try:
                    v = json.loads(line)
                except ValueError:
                    v = None
                usable = (isinstance(v, dict) and isinstance(v.get("repo"), str) and type(v.get("pr")) is int
                          and isinstance(v.get("head_sha"), str) and v["head_sha"]
                          and isinstance(v.get("verdict"), str) and v["verdict"] in VERDICT_VALUES)
                if not usable:
                    bad += 1
                elif v["repo"] == repo:
                    out[(v["pr"], v["head_sha"])] = v["verdict"]
    return out, bad


def rule_ceiling(repo, pr, cfg, run=subprocess.run):
    """Ceiling from the same file records a live verdict reads. 'unknown' when they cannot be read in full."""
    r = run(["gh", "api", f"repos/{repo}/pulls/{pr['number']}/files", "--paginate", "--jq", FILES_JQ],
            capture_output=True, text=True)
    if r.returncode != 0:
        return "unknown"
    try:
        return classify(pr["title"], parse_files(r.stdout, pr.get("changedFiles")), cfg)["ceiling"]
    except SystemExit:
        return "unknown"


def tally(rows, key):
    """Counts per value of rows[key]. Pending and undetermined rows are counted apart, not in n."""
    summary = {}
    for r in rows:
        s = summary.setdefault(r[key], {"n": 0, "with_followup": 0, "reverted": 0, "pending": 0, "undetermined": 0})
        if r["pending"]:
            s["pending"] += 1
            continue
        if r["undetermined"]:
            s["undetermined"] += 1
            continue
        s["n"] += 1
        s["with_followup"] += bool(r["followups"])
        s["reverted"] += r["reverted"]
    return summary


def attach_verdicts(rows, verdicts):
    for r in rows:
        # A verdict counts only if it was given for the commit that was merged.
        r["verdict"] = verdicts.get((r["number"], r["head_sha"]), "none") if r["head_sha"] else "none"


def self_test():
    now = ts("2026-01-10T00:00:00Z")
    prs = [
        {"number": 1, "title": "fix(a): x", "mergedAt": "2026-01-01T00:00:00Z", "files": ["a.ts", "pnpm-lock.yaml"], "headRefOid": "s1"},
        {"number": 2, "title": "fix(a): y", "mergedAt": "2026-01-01T10:00:00Z", "files": ["a.ts"], "headRefOid": "s2"},
        {"number": 3, "title": "feat: z", "mergedAt": "2026-01-01T11:00:00Z", "files": ["a.ts"], "headRefOid": "s3"},
        {"number": 4, "title": "fix(b): w", "mergedAt": "2026-01-02T00:00:00Z", "files": ["pnpm-lock.yaml"], "headRefOid": "s4"},
        {"number": 5, "title": 'Revert "fix(a): y"', "mergedAt": "2026-01-05T00:00:00Z", "files": ["a.ts"], "headRefOid": "s5"},
        {"number": 6, "title": "fix(c): fresh", "mergedAt": "2026-01-09T23:00:00Z", "files": ["c.ts"], "headRefOid": None},
    ]
    rows = {r["number"]: r for r in find_followups(prs, 48, ["fix"], DEFAULT_IGNORE, now)}
    assert rows[1]["followups"] == [2] and not rows[1]["reverted"], rows[1]
    assert rows[2]["followups"] == [] and 3 not in rows, rows  # the revert is outside the 48h window
    assert rows[4]["followups"] == []  # only the lockfile is shared
    assert rows[6]["pending"] and not rows[1]["pending"]
    wide = {r["number"]: r for r in find_followups(prs, 200, ["fix"], DEFAULT_IGNORE, ts("2026-02-01T00:00:00Z"))}
    assert wide[2]["followups"] == [5] and wide[2]["reverted"]
    # the follow-up kind does not depend on which kinds are being judged
    feat = {r["number"]: r for r in find_followups(prs, 48, ["feat"], DEFAULT_IGNORE, now)}
    assert list(feat) == [3] and feat[3]["followups"] == []
    feat2 = find_followups([prs[2], dict(prs[1], mergedAt="2026-01-01T12:00:00Z")], 48, ["feat"], DEFAULT_IGNORE, now)
    assert feat2[0]["followups"] == [2], feat2
    # a file most PRs touch is not evidence of a follow-up
    many = [{"number": i, "title": "fix: n%d" % i, "mergedAt": "2026-01-01T%02d:00:00Z" % i, "files": ["i18n/ja.ts", "f%d.ts" % i]}
            for i in range(10)]
    assert hub_files(many, 0.1) == {"i18n/ja.ts"} and hub_files(many, 0) == set() and hub_files(many[:3], 0.1) == set()
    assert all(r["followups"] for r in find_followups(many, 48, ["fix"], [], now)[:-1])
    assert not any(r["followups"] for r in find_followups(many, 48, ["fix"], [], now, hub_files(many, 0.1)))
    # ...but dropping hubs must not turn "cannot tell" into "nothing happened", and must not hide a revert
    hot = [{"number": i, "title": "fix: payment calculation" if i == 1 else "fix: p%d" % i,
            "mergedAt": "2026-01-01T%02d:00:00Z" % i, "files": ["payment.ts"]} for i in range(1, 5)]
    hot.append({"number": 5, "title": 'Revert "fix: payment calculation"', "mergedAt": "2026-01-01T05:00:00Z", "files": ["payment.ts"]})
    hubs = hub_files(hot, 0.1)
    assert hubs == {"payment.ts"}
    by = {r["number"]: r for r in find_followups(hot, 48, ["fix"], [], now, hubs)}
    assert by[1]["followups"] == [5] and by[1]["reverted"] and not by[1]["undetermined"], by[1]
    assert by[2]["undetermined"] and by[2]["followups"] == [] and by[2]["hub_only"] == [3, 4, 5], by[2]
    t = tally(list(by.values()), "pending")[False]
    assert (t["n"], t["with_followup"], t["reverted"], t["undetermined"]) == (1, 1, 1, 3), t
    # "Revert #10" names PR 10, not PR 1
    pair = [{"number": n, "title": "fix: n%d" % n, "mergedAt": "2026-01-01T%02d:00:00Z" % h, "files": ["payment.ts"]}
            for n, h in ((1, 1), (10, 2))]
    pair.append({"number": 20, "title": "Revert #10", "mergedAt": "2026-01-01T03:00:00Z", "files": ["other.ts"]})
    by = {r["number"]: r for r in find_followups(pair, 48, ["fix"], [], now, {"payment.ts"})}
    assert by[10]["reverted"] and by[10]["followups"] == [20], by[10]
    assert not by[1]["reverted"] and by[1]["followups"] == [] and by[1]["undetermined"], by[1]
    assert names('Revert "fix: n1" (#31)', pair[0]) and not names("Revert #100", pair[1])
    # verdicts: only for the merged commit, never on a missing SHA
    values = list(rows.values())
    attach_verdicts(values, {(1, "s1"): "high", (2, "old"): "high", (6, None): "high"})
    s = tally(values, "verdict")
    assert s["high"] == {"n": 1, "with_followup": 1, "reverted": 0, "pending": 0, "undetermined": 0}, s
    # #4 touched only a lockfile: file overlap cannot say anything about it
    assert (s["none"]["n"], s["none"]["pending"], s["none"]["undetermined"]) == (1, 1, 1), s
    import tempfile
    import types
    lines = [
        '{"repo":"o/r","pr":1,"head_sha":"s1","verdict":"low"}',
        "{broken",
        '{"repo":"o/r","pr":2}',
        '{"repo":"o/r","pr":3,"head_sha":"s3"}',                       # no verdict
        '{"repo":"o/r","pr":4,"head_sha":["s4"],"verdict":"high"}',    # SHA is not a string
        '{"repo":"o/r","pr":5,"head_sha":"s5","verdict":"great"}',     # unknown verdict value
        '{"repo":"o/r","pr":7,"head_sha":"s7","verdict":[]}',          # verdict is not a string
        '{"repo":"o/r","pr":8,"head_sha":"s8","verdict":{}}',
        '{"repo":["o/r"],"pr":9,"head_sha":"s9","verdict":"high"}',    # repo is not a string
        '[1, 2]',                                                      # not an object
        '{"repo":"other/r","pr":6,"head_sha":"s6","verdict":"high"}',  # another repo: fine, not ours
    ]
    with tempfile.NamedTemporaryFile("w", suffix=".jsonl", delete=False) as f:
        f.write("\n".join(lines) + "\n")
    v, bad = load_verdicts(f.name, "o/r")
    os.unlink(f.name)
    assert v == {(1, "s1"): "low"} and bad == 9, (v, bad)
    # rule ceilings read the same records as a live verdict: opaque files and old paths count
    cfg = {"paths": {"tests": ["*.spec.ts"]}}
    rec = '{"filename":"%s","previous_filename":%s,"additions":%d,"deletions":0,"status":"%s","has_patch":%s}'

    def fake(out, code=0):
        return lambda *a, **k: types.SimpleNamespace(returncode=code, stdout=out)

    pr = {"number": 9, "title": "fix: x", "changedFiles": 2}
    plain = rec % ("a.spec.ts", "null", 1, "modified", "true")
    assert rule_ceiling("o/r", pr, cfg, fake(plain + "\n" + rec % ("b.ts", "null", 1, "modified", "true"))) == "high"
    assert rule_ceiling("o/r", pr, cfg, fake(plain + "\n" + rec % ("logo.png", "null", 0, "added", "false"))) == "medium"
    moved = rec % ("a.spec.ts", '".github/a.spec.ts"', 0, "renamed", "false")
    assert rule_ceiling("o/r", dict(pr, changedFiles=1), cfg, fake(moved)) == "low"
    assert rule_ceiling("o/r", pr, cfg, fake(plain)) == "unknown"        # 1 record, the PR reports 2
    assert rule_ceiling("o/r", pr, cfg, fake("", code=1)) == "unknown"   # gh failed
    print("self-test ok")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("repo", nargs="?")
    ap.add_argument("--days", type=int, default=60)
    ap.add_argument("--window-hours", type=int, default=48)
    ap.add_argument("--hub-share", type=float, default=0.1,
                    help="leave out files touched by at least this share of the PRs (0 = keep all)")
    ap.add_argument("--config")
    ap.add_argument("--verdicts", default=VERDICTS)
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()
    if args.self_test:
        return self_test()
    if not args.repo:
        ap.error("OWNER/REPO is required")
    cfg = {}
    if args.config:
        with open(args.config, "rb") as f:
            cfg = tomllib.load(f)
    prefixes = cfg.get("target", {}).get("title_prefixes", DEFAULT_PREFIXES)
    ignore = DEFAULT_IGNORE
    since = (dt.date.today() - dt.timedelta(days=args.days)).isoformat()
    raw = subprocess.run(
        ["gh", "pr", "list", "-R", args.repo, "--state", "merged", "--limit", str(PR_LIMIT),
         "--search", f"merged:>={since}", "--json", "number,title,mergedAt,files,headRefOid,changedFiles"],
        check=True, capture_output=True, text=True).stdout
    fetched = json.loads(raw)
    # gh returns at most 100 files per PR here; such a PR may hide shared files.
    truncated = [p["number"] for p in fetched if len(p["files"]) < p.get("changedFiles", 0)]
    warnings = []
    if truncated:
        warnings.append(f"ファイル一覧が途中までの PR が {len(truncated)} 件ある（後続の判定が欠けうる）: {truncated[:10]}")
    if len(fetched) >= PR_LIMIT:
        warnings.append(f"PR が {PR_LIMIT} 件で打ち切られた。--days を短くする")
    prs = [dict(p, files=[f["path"] for f in p["files"]]) for p in fetched]
    hubs = hub_files(prs, args.hub_share)
    rows = find_followups(prs, args.window_hours, prefixes, ignore, dt.datetime.now(dt.timezone.utc), hubs)
    verdicts, bad = load_verdicts(args.verdicts, args.repo)
    if bad:
        warnings.append(f"判定の記録に読めない行が {bad} 行ある: {args.verdicts}")
    attach_verdicts(rows, verdicts)
    result = {"repo": args.repo, "since": since, "warnings": warnings, "summary": tally(rows, "verdict")}
    # The base rate: what you get without selecting anything. A ceiling or verdict that does
    # no better than this is not separating risky changes from safe ones.
    result["overall"] = tally([dict(r, _all="全体") for r in rows], "_all").get("全体", {})
    result["hubs"] = sorted(hubs)
    if cfg:
        by_number = {p["number"]: p for p in fetched}
        for r in rows:
            r["ceiling"] = rule_ceiling(args.repo, by_number[r["number"]], cfg)
        unknown = sum(1 for r in rows if r["ceiling"] == "unknown")
        if unknown:
            warnings.append(f"ルールの上限を決められなかった PR が {unknown} 件ある（ファイルの記録を全部は読めなかった）")
        result["by_ceiling"] = tally(rows, "ceiling")
    result["rows"] = rows
    if args.json:
        print(json.dumps(result, ensure_ascii=False))
        return
    for w in warnings:
        print(f"warning: {w}", file=sys.stderr)
    print(f"{args.repo}  merged since {since}  対象 {len(rows)} 件（種別 {', '.join(prefixes)}、後続は {args.window_hours} 時間以内）")

    def show(title, summary):
        print(title)
        for k, s in sorted(summary.items()):
            print(f"  {k:8} n={s['n']:<4} 後続の修正あり={s['with_followup']:<4} revert={s['reverted']:<3} "
                  f"観測中={s['pending']:<3} 判定不能={s['undetermined']}")

    if hubs:
        print(f"多くの PR が触るファイル {len(hubs)} 件を、後続の判定から除いた: " + ", ".join(sorted(hubs)[:6]) + (" …" if len(hubs) > 6 else ""))
        print("  そのファイルしか触っていない PR は「判定不能」に数える。除いた重なりは、各行の hub_only（--json）に残る")
    show("基準（何も選ばなかった時）:", {"全体": result["overall"]} if result["overall"] else {})
    show("判定ごと（マージされたコミットに付いた判定だけ）:", result["summary"])
    if cfg:
        show("ルールだけの上限ごと:", result["by_ceiling"])
    for r in rows:
        if r["followups"]:
            tag = "/".join(x for x in (r["verdict"], r.get("ceiling")) if x)
            print(f"  #{r['number']} [{tag}] -> " + ", ".join(f"#{n}" for n in r["followups"]) + ("  (revert)" if r["reverted"] else ""))


if __name__ == "__main__":
    main()
