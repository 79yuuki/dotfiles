#!/usr/bin/env python3
"""Rule-based ceiling for a merge-gate verdict. No model, no network.

Input: one JSON object per line, as produced from the GitHub pulls/N/files API
(see SKILL.md): filename, previous_filename, additions, deletions, status, has_patch.

  classify_diff.py --config merge-gate.toml --title "fix(api): ..." \
      --files files.jsonl --expect-files 6
  classify_diff.py --self-test

The verdict can never be higher than `ceiling`. Take the config from the base branch,
not from the change being judged. Anything the script cannot read exits non-zero:
no result means no verdict.

Glob syntax in the config: `*` (within one path segment), `**` (any depth), `?`.
Other glob syntax ([], {}) is rejected.
"""
import argparse
import json
import re
import sys
import tomllib

ORDER = ["low", "medium", "high"]
# A change must not be able to edit the rules or the CI that judge it.
ALWAYS_SENSITIVE = [".github/**"]
DEFAULT_PREFIXES = ["fix"]
# The same --jq is used in SKILL.md, so history scoring and live verdicts read identical records.
FILES_JQ = '.[] | {filename, previous_filename, additions, deletions, status, has_patch: has("patch")}'


def glob_re(pattern):
    if any(ch in pattern for ch in "[]{}"):
        sys.exit(f"unsupported glob syntax in {pattern!r}: only *, ** and ? are supported")
    out, i = "", 0
    while i < len(pattern):
        if pattern.startswith("**/", i):
            out, i = out + "(?:.*/)?", i + 3
        elif pattern.startswith("**", i):
            out, i = out + ".*", i + 2
        elif pattern[i] == "*":
            out, i = out + "[^/]*", i + 1
        elif pattern[i] == "?":
            out, i = out + "[^/]", i + 1
        else:
            out, i = out + re.escape(pattern[i]), i + 1
    return re.compile(out + r"\Z", re.DOTALL)


def matches(path, patterns):
    return any(glob_re(p).match(path) for p in patterns)


def title_kind(title):
    """('fix', breaking?) for a conventional-commit title, else (None, False)."""
    m = re.match(r"\s*([A-Za-z]+)(\([^)]*\))?(!)?:", title)
    return (m.group(1).lower(), bool(m.group(3))) if m else (None, False)


def parse_files(text, expect=None):
    """-> [(path, added, deleted, opaque)]. A renamed file yields its old path too."""
    rows, n_files = [], 0
    for n, line in enumerate(text.splitlines(), 1):
        if not line.strip():
            continue
        try:
            f = json.loads(line)
            path, added, deleted = f["filename"], int(f["additions"]), int(f["deletions"])
            if not isinstance(path, str) or not path:
                raise ValueError("filename")
        except (ValueError, KeyError, TypeError) as e:
            sys.exit(f"files line {n} is not a usable file record: {e!r}")
        # No patch means the API did not show the content: binary, or too large.
        # A pure rename has no patch either and is not opaque.
        pure_rename = f.get("status") == "renamed" and added + deleted == 0
        opaque = not f.get("has_patch", True) and not pure_rename
        rows.append((path, added, deleted, opaque))
        if f.get("previous_filename"):
            rows.append((f["previous_filename"], 0, 0, False))
        n_files += 1
    if expect is not None and n_files != expect:
        sys.exit(f"got {n_files} file records, the PR reports {expect}: the file list is incomplete")
    return rows


def validate_config(cfg):
    """Reject a config with a pattern this script cannot honour, before any matching happens."""
    paths = cfg.get("paths", {})
    groups = [paths.get(k, []) for k in ("sensitive", "tests", "size_ignore")]
    groups += [c.get("when") for c in cfg.get("checks", [])]
    for group in groups:
        if not isinstance(group, list) or not all(isinstance(p, str) for p in group):
            sys.exit(f"config: path patterns must be lists of strings, got {group!r}")
        for p in group:
            glob_re(p)
    if not all(isinstance(c.get("ask"), str) for c in cfg.get("checks", [])):
        sys.exit("config: every [[checks]] entry needs an `ask` string")


def classify(title, rows, cfg):
    validate_config(cfg)
    paths, simple = cfg.get("paths", {}), cfg.get("simple", {})
    prefixes = cfg.get("target", {}).get("title_prefixes", DEFAULT_PREFIXES)
    ceiling, reasons = "high", []

    def cap(level, reason):
        nonlocal ceiling
        if ORDER.index(level) < ORDER.index(ceiling):
            ceiling = level
        reasons.append(reason)

    kind, breaking = title_kind(title)
    in_scope = kind in prefixes
    if not in_scope:
        cap("low", f"対象外: 題名の種別が {kind or '不明'}（対象は {', '.join(prefixes)}）")
    if breaking:
        cap("low", "題名に破壊的変更の印（!）がある")
    if not rows:
        cap("low", "差分が空")

    sensitive = [p for p, *_ in rows if matches(p, ALWAYS_SENSITIVE + paths.get("sensitive", []))]
    if sensitive:
        cap("low", f"センシティブな path に触れている: {', '.join(sensitive[:5])}")

    counted = [r for r in rows if not matches(r[0], paths.get("size_ignore", []))]
    tests = [r for r in counted if matches(r[0], paths.get("tests", []))]
    code = [r for r in counted if r not in tests]
    files, lines = len(counted), sum(a + d for _, a, d, _ in counted)
    max_files, max_lines = simple.get("max_files", 5), simple.get("max_changed_lines", 150)
    if files > max_files:
        cap("medium", f"ファイル数 {files} が上限 {max_files} を超える")
    if lines > max_lines:
        cap("medium", f"変更行数 {lines} が上限 {max_lines} を超える")
    if code and not tests:
        cap("medium", "コードを変えているが、テストの変更が無い")
    opaque = [p for p, _, _, o in rows if o]
    if opaque:
        cap("medium", f"中身が見えない変更がある（バイナリか、差分が大きすぎる）: {', '.join(opaque[:5])}")

    checks = [c["ask"] for c in cfg.get("checks", []) if any(matches(p, c["when"]) for p, *_ in rows)]
    return {
        "in_scope": in_scope,
        "ceiling": ceiling,
        "reasons": reasons,
        "signals": {
            "kind": kind,
            "files": files,
            "changed_lines": lines,
            "sensitive_paths": sensitive,
            "test_files": [r[0] for r in tests],
            "test_lines_deleted": sum(d for _, _, d, _ in tests),
        },
        "checks": checks,
    }


def self_test():
    def rec(path, a=1, d=0, **kw):
        return json.dumps(dict({"filename": path, "additions": a, "deletions": d, "status": "modified", "has_patch": True}, **kw))

    def exits(fn):
        try:
            fn()
        except SystemExit as e:
            return bool(e.code)
        return False

    assert matches("src/auth/guard.ts", ["**/auth/**"]) and matches("auth/x.ts", ["**/auth/**"])
    assert matches("infra/a/main.tf", ["**/*.tf"]) and not matches("infra/a/main.tf", ["*.tf"])
    assert not matches("src/author/x.ts", ["**/auth/**"])
    assert exits(lambda: matches("a", ["src/[ab].ts"]))  # unsupported glob syntax
    # ...also when an earlier pattern already matched, or the pattern sits in another list
    one = [("test.py", 1, 0, False)]
    assert exits(lambda: classify("fix: x", one, {"paths": {"tests": ["**", "src/[ab].py"]}}))
    assert exits(lambda: classify("fix: x", one, {"checks": [{"when": ["{a,b}"], "ask": "q"}]}))
    assert exits(lambda: classify("fix: x", one, {"paths": {"sensitive": "**/auth/**"}}))  # not a list
    assert title_kind("fix(api)!: x") == ("fix", True) and title_kind("Update readme") == (None, False)
    cfg = {
        "paths": {"sensitive": ["**/auth/**"], "tests": ["**/*.spec.ts"], "size_ignore": ["**/pnpm-lock.yaml"]},
        "simple": {"max_files": 3, "max_changed_lines": 50},
        "checks": [{"when": ["**/payment/**"], "ask": "金額の丸めは変わっていないか"}],
    }
    code, spec = rec("src/payment/a.ts", 5, 2), rec("src/payment/a.spec.ts", 9, 1)

    def run(title, *lines):
        return classify(title, parse_files("\n".join(lines)), cfg)

    ok = run("fix(payment): x", code, spec, rec("pnpm-lock.yaml", 900, 900))
    assert ok["ceiling"] == "high" and ok["signals"]["files"] == 2, ok
    assert ok["checks"] == ["金額の丸めは変わっていないか"] and ok["signals"]["test_lines_deleted"] == 1
    assert run("fix: x", code)["ceiling"] == "medium"  # no test change
    assert run("fix: x", code, spec, rec("src/auth/g.ts"))["ceiling"] == "low"
    assert run("fix: x", code, spec, rec(".github/workflows/ci.yml"))["ceiling"] == "low"
    # odd characters in a path must not hide it from the sensitive rule
    assert run("fix: x", code, spec, rec(".github/workflows/bad\tname.yml"))["ceiling"] == "low"
    assert run("fix: x", code, spec, rec(".github/workflows/日本\n語.yml"))["ceiling"] == "low"
    # a file renamed out of a sensitive directory still counts as touching it
    moved = rec("src/lib/g.ts", 0, 0, status="renamed", previous_filename="src/auth/g.ts", has_patch=False)
    assert run("fix: x", code, spec, moved)["ceiling"] == "low"
    assert run("fix: x", code, spec, rec("logo.png", 0, 0, has_patch=False))["ceiling"] == "medium"  # opaque
    assert run("feat: x", code, spec)["in_scope"] is False
    assert run("fix: x", rec("src/a.ts", 60, 0), spec)["ceiling"] == "medium"  # too many lines
    assert run("fix: x")["ceiling"] == "low"  # empty diff
    assert exits(lambda: parse_files("1\t0\tx.ts"))  # not JSON
    assert exits(lambda: parse_files('{"filename": "x.ts"}'))  # missing fields
    assert exits(lambda: parse_files(code, expect=2))  # incomplete file list
    assert len(parse_files(code + "\n" + spec, expect=2)) == 2
    print("self-test ok")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--config")
    ap.add_argument("--title")
    ap.add_argument("--files", help="JSON Lines file of changed files ('-' for stdin)")
    ap.add_argument("--expect-files", type=int, help="changedFiles reported by the PR; mismatch is an error")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()
    if args.self_test:
        return self_test()
    if not args.config or args.title is None or not args.files:
        ap.error("--config, --title and --files are required")
    with open(args.config, "rb") as f:
        cfg = tomllib.load(f)
    text = sys.stdin.read() if args.files == "-" else open(args.files).read()
    result = classify(args.title, parse_files(text, args.expect_files), cfg)
    result["stage"] = cfg.get("stage", "observe")
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
