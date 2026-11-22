#!/usr/bin/env python3
"""メイン導線を「人が見たか」の台帳。

  flows.py check  [--rev REV] [--config PATH] [--json]
      exit 0: 全部の導線が確認済み（または、一度見た後の変更について見送り済み）
      exit 1: 未確認・変更あり・要修正の導線がある
      exit 2: 設定か記録が読めない（合格にしない）
  flows.py record FLOW --result seen|fix|waived --by NAME [--rev REV] [--env ..] [--browser ..] [--findings N] [--note ..]
  flows.py --self-test

「見た」の単位は、導線の定義（利用者像・課題・入り口・paths）と、paths に一致するファイルの中身をまとめた指紋。
同じ指紋なら、squash や rebase でコミットの SHA が変わっても確認済みのまま。どちらかが変われば、未確認に戻る。
導線の一覧は、見る版のコミットに入っているものを読む（作業ツリーの書きかけは読まない）。
見送り（waived）は、一度は人が通して見た導線の、その後の変更にだけ使える。
記録は ~/.claude/state/ux-walkthrough/log.jsonl（UX_WALKTHROUGH_STATE_DIR で差し替え）。
"""
import argparse
import datetime
import hashlib
import json
import os
import re
import subprocess
import sys
import tomllib
from pathlib import Path

DEFAULT_CONFIG = ".github/main-flows.toml"
RESULTS = {"seen": "確認済み", "fix": "要修正", "waived": "見送り"}
LABELS = {**RESULTS, "changed": "変更あり", "unseen": "未確認", "dirty": "未コミット"}
PASSING = {"seen", "waived"}
DEFINITION_KEYS = ("persona", "task", "start", "paths")  # title は見出しなので、変えても未確認に戻さない


def die(msg):
    """設定・記録・使い方の誤りは exit 2。exit 1 は「未確認の導線がある」だけに使う。"""
    print(f"error: {msg}", file=sys.stderr)
    sys.exit(2)


def git(repo, *args, ok=False):
    p = subprocess.run(["git", "-C", str(repo), *args], capture_output=True, text=True)
    if p.returncode != 0:
        if ok:
            return None
        die(f"git {' '.join(args[:3])} が失敗した: {p.stderr.strip()}")
    return p.stdout


def parse_flows(text, where):
    try:
        flows = tomllib.loads(text).get("flow")
    except tomllib.TOMLDecodeError as e:
        die(f"{where} を読めない: {e}")
    if not isinstance(flows, list) or not flows:
        die(f"{where} に [[flow]] が 1 つも無い")
    seen = set()
    for f in flows:
        if not isinstance(f, dict):
            die(f"{where} の flow は [[flow]] の表で書く")
        fid, paths = f.get("id"), f.get("paths")
        if not isinstance(fid, str) or not re.fullmatch(r"[a-z0-9][a-z0-9-]*", fid) or fid in seen:
            die(f"flow の id は英小文字・数字・ハイフンで、重複させない: {fid!r}")
        if not isinstance(f.get("title"), str) or not f["title"].strip():
            die(f"flow {fid} に title が無い")
        if not isinstance(paths, list) or not paths or not all(isinstance(p, str) and p and p[0] not in ":-!" for p in paths):
            die(f"flow {fid} の paths は、空でない glob の一覧にする")
        seen.add(fid)
    return flows


def flows_at(repo, rev, config):
    text = git(repo, "show", f"{rev}:{config}", ok=True)
    if text is None:
        die(f"{rev[:7]} のコミットに {config} が無い（一覧はコミットしてから使う）")
    return parse_flows(text, f"{rev[:7]}:{config}")


def globs(flow):
    return [f":(glob){p}" for p in flow["paths"]]


def fingerprint(repo, rev, flow):
    """導線の定義と、rev の時点で paths に一致するファイルの（mode, blob, path）をまとめた指紋。"""
    empty = git(repo, "hash-object", "-t", "tree", "/dev/null").strip()
    out = git(repo, "diff", "--raw", "--no-abbrev", "--no-renames", empty, rev, "--", *globs(flow))
    definition = json.dumps({k: flow.get(k) for k in DEFINITION_KEYS}, sort_keys=True, ensure_ascii=False)
    return hashlib.sha256((definition + "\n" + out).encode()).hexdigest(), len(out.splitlines())


def norm_url(url):
    """origin の URL を「ホスト/名前空間/名前」にそろえる。ssh と https で同じ値になり、ホストや名前空間が違えば別の値になる。"""
    u = re.sub(r"^[a-z][a-z0-9+.-]*://", "", url.strip())
    u = re.sub(r"^[^@/]+@", "", u)
    if "://" not in url:
        u = re.sub(r"^([^/:]+):", r"\1/", u)  # scp 形式（host:path）
    return re.sub(r"\.git/?$", "", u).rstrip("/")


def repo_id(repo):
    url = git(repo, "remote", "get-url", "origin", ok=True)
    return norm_url(url) if url and url.strip() else str(Path(git(repo, "rev-parse", "--show-toplevel").strip()).resolve())


def log_path():
    return Path(os.environ.get("UX_WALKTHROUGH_STATE_DIR", "~/.claude/state/ux-walkthrough")).expanduser() / "log.jsonl"


def valid_row(r):
    if not isinstance(r, dict) or not all(isinstance(r.get(k), str) and r[k] for k in ("repo", "flow", "fingerprint", "by", "ts", "result")):
        return False
    return r["result"] in RESULTS and (r["result"] != "waived" or (isinstance(r.get("note"), str) and bool(r["note"].strip())))


def load_log(path):
    """形の正しい行と、読めなかった行の番号を返す。読めない行があれば、呼び出し側は合格にしない。"""
    rows, bad = [], []
    if not path.exists():
        return rows, bad
    for i, raw in enumerate(path.read_bytes().split(b"\n"), 1):
        if not raw.strip():
            continue
        try:
            r = json.loads(raw.decode("utf-8"))
        except ValueError:  # JSON として読めない行と、UTF-8 として読めない行
            r = None
        if valid_row(r):
            rows.append(r)
        else:
            bad.append(i)
    return rows, bad


def clean_log():
    rows, bad = load_log(log_path())
    if bad:
        die(f"記録 {log_path()} の {', '.join(map(str, bad))} 行目が読めない。古い記録で合格にしないよう、ここで止める。その行を直すか消してから、もう一度実行する")
    return rows


def changed_since(repo, old, new, flow):
    """前に見た版から変わったファイル。前の版が手元に無い時（squash の後など）は空で返す。"""
    if not isinstance(old, str) or not re.fullmatch(r"[0-9a-f]{7,64}", old):
        return []
    out = git(repo, "diff", "--name-only", old, new, "--", *globs(flow), ok=True)
    return out.splitlines() if out else []


def statuses(repo, rev, flows, rows, worktree):
    rid, out = repo_id(repo), []
    for f in flows:
        fp, n = fingerprint(repo, rev, f)
        if n == 0:
            die(f"flow {f['id']} の paths に一致するファイルが {rev[:7]} に 1 つも無い（一覧を直す）")
        mine = [r for r in rows if r["repo"] == rid and r["flow"] == f["id"]]
        same = [r for r in mine if r["fingerprint"] == fp]
        last = same[-1] if same else None
        ever_seen = any(r["result"] == "seen" for r in mine)
        if worktree and git(repo, "status", "--porcelain", "--", *globs(f)).strip():
            state, last = "dirty", None
        elif last and (last["result"] != "waived" or ever_seen):
            state = last["result"]
        else:
            state, last = ("changed" if ever_seen else "unseen"), None
        prev = mine[-1] if mine and state == "changed" else None
        out.append({"id": f["id"], "title": f["title"], "state": state, "fingerprint": fp, "files": n, "record": last,
                    "previous": prev, "changed_files": changed_since(repo, prev.get("rev"), rev, f) if prev else []})
    return out


def describe(s):
    r, day = s["record"], lambda x: x["ts"][:10]
    if s["state"] == "seen":
        return f"{day(r)} に {r['by']} が見た"
    if s["state"] == "fix":
        return f"{day(r)} に {r['by']} が見て、出す前に直す問題が残っている"
    if s["state"] == "waived":
        return f"{day(r)} に {r['by']} が、前に見た後の変更について見送りを決めた: {r['note']}"
    if s["state"] == "dirty":
        return "導線のファイルに未コミットの変更がある。コミットしてから見る"
    if s["state"] == "changed":
        p, files = s["previous"], s["changed_files"]
        what = f"変わったのは {len(files)} ファイル: {', '.join(files[:5])}{' ほか' if len(files) > 5 else ''}" if files else "その後、導線のファイルか定義が変わった"
        return f"最後の記録は {day(p)}（{str(p.get('rev', ''))[:7]}）。{what}"
    return "人が通して見た記録が無い"


def resolve(repo, rev):
    return git(repo, "rev-parse", "--verify", f"{rev or 'HEAD'}^{{commit}}").strip()


def cmd_check(a):
    rev = resolve(a.repo, a.rev)
    flows = flows_at(a.repo, rev, a.config)
    st = statuses(a.repo, rev, flows, clean_log(), worktree=a.rev is None)
    failing = [s for s in st if s["state"] not in PASSING]
    if a.json:
        print(json.dumps({"repo": repo_id(a.repo), "rev": rev, "flows": st}, ensure_ascii=False, indent=2))
    else:
        print(f"メイン導線の確認（{repo_id(a.repo)} @ {rev[:7]}）")
        for s in st:
            print(f"  {LABELS[s['state']]}\t{s['id']}\t{s['title']} — {describe(s)}")
        print(f"人が見ていない、または直す問題が残っている導線: {len(failing)} 本 / {len(st)} 本" if failing else "全部の導線が、この中身で確認済みか見送り済み")
    return 1 if failing else 0


def cmd_record(a):
    rev = resolve(a.repo, a.rev)
    flows = {f["id"]: f for f in flows_at(a.repo, rev, a.config)}
    f = flows.get(a.flow) or die(f"{rev[:7]} の {a.config} に flow {a.flow} が無い（ある id: {', '.join(flows)}）")
    if not a.by.strip():
        die("--by に、見た人（見送りを決めた人）の名前を書く")
    rows, rid = clean_log(), repo_id(a.repo)
    if a.result == "waived":
        if not (a.note or "").strip():
            die("見送り（waived）には --note で理由を書く")
        if not any(r["repo"] == rid and r["flow"] == a.flow and r["result"] == "seen" for r in rows):
            die("人が一度も通して見ていない導線は、見送れない。最初の 1 回は通して見る")
    # 版を名指ししない時は手元の HEAD を見たことにする。未コミットの変更があると、見た画面と記録がずれる
    if a.rev is None and git(a.repo, "status", "--porcelain", "--", *globs(f)).strip():
        die("この導線のファイルに未コミットの変更がある。コミットしてから記録するか、見た版を --rev で名指しする")
    fp, n = fingerprint(a.repo, rev, f)
    if n == 0:
        die(f"flow {a.flow} の paths に一致するファイルが {rev[:7]} に無い")
    row = {"ts": datetime.datetime.now().astimezone().isoformat(timespec="seconds"), "repo": rid, "flow": a.flow,
           "result": a.result, "by": a.by.strip(), "rev": rev, "fingerprint": fp, "files": n, "env": a.env or "",
           "browser": a.browser or "", "findings": a.findings, "note": (a.note or "").strip()}
    path = log_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a") as fh:
        fh.write(json.dumps(row, ensure_ascii=False) + "\n")
    print(f"記録した: {a.flow} = {RESULTS[a.result]}（{rev[:7]}、{n} ファイル、{path}）")
    return 0


def self_test():
    import tempfile
    assert {norm_url(u) for u in ("https://github.com/acme/shop.git", "git@github.com:acme/shop.git", "ssh://git@github.com/acme/shop")} == {"github.com/acme/shop"}
    assert len({norm_url(u) for u in ("https://github.com/acme/shop.git", "https://gitlab.com/acme/shop.git",
                                      "https://gitlab.com/one/acme/shop.git", "https://gitlab.com/two/acme/shop.git")}) == 4
    assert not valid_row({"repo": "r", "flow": "f", "fingerprint": "x", "by": "h", "ts": "t", "result": []})
    assert not valid_row({"repo": "r", "flow": "f", "fingerprint": "x", "by": "h", "ts": "t", "result": "waived"})
    saved = dict(os.environ)
    with tempfile.TemporaryDirectory() as d:
        repo = Path(d) / "r"
        os.environ["UX_WALKTHROUGH_STATE_DIR"] = str(Path(d) / "state")
        run = lambda *c: subprocess.run(["git", "-C", str(repo), "-c", "user.name=t", "-c", "user.email=t@example.com", *c], check=True, capture_output=True)
        me = lambda *c: subprocess.run([sys.executable, __file__, *c, "--repo", str(repo)], capture_output=True, text=True)
        rec = lambda *c: me("record", "pay", "--by", "h", *c).returncode
        cfg = repo / ".github/main-flows.toml"
        flow = lambda fid, persona="初めての客", paths="app/pay/**": f'[[flow]]\nid = "{fid}"\ntitle = "t"\npersona = "{persona}"\npaths = ["{paths}"]\n'
        repo.mkdir(); run("init", "-q")
        cfg.parent.mkdir(); (repo / "app/pay").mkdir(parents=True)
        cfg.write_text(flow("pay")); (repo / "app/pay/a.ts").write_text("1\n"); (repo / "other.ts").write_text("1\n")
        run("add", "-A"); run("commit", "-qm", "c1")
        r = me("check"); assert r.returncode == 1 and "未確認" in r.stdout, r.stdout + r.stderr
        assert rec("--result", "waived") == 2                                   # 理由の無い見送り
        assert rec("--result", "waived", "--note", "忙しい") == 2               # 一度も見ていない導線は見送れない
        assert me("record", "nope", "--result", "seen", "--by", "h").returncode == 2
        assert rec("--result", "seen") == 0
        r = me("check"); assert r.returncode == 0 and "確認済み" in r.stdout, r.stdout
        run("commit", "-q", "--amend", "-m", "c1 reworded")                      # SHA だけ変わる
        assert me("check").returncode == 0
        (repo / "other.ts").write_text("2\n"); run("commit", "-qam", "outside the flow")
        assert me("check").returncode == 0
        (repo / "app/pay/a.ts").write_text("2\n")
        r = me("check"); assert r.returncode == 1 and "未コミット" in r.stdout, r.stdout   # 書きかけは確認済みにしない
        assert rec("--result", "seen") == 2
        run("commit", "-qam", "inside the flow")
        r = me("check"); assert r.returncode == 1 and "変更あり" in r.stdout and "1 ファイル: app/pay/a.ts" in r.stdout, r.stdout
        assert rec("--result", "fix") == 0
        r = me("check"); assert r.returncode == 1 and "要修正" in r.stdout, r.stdout
        assert rec("--result", "waived", "--note", "文言だけの変更") == 0        # 一度見た後の変更は見送れる
        r = me("check"); assert r.returncode == 0 and "見送り" in r.stdout, r.stdout
        cfg.write_text(flow("pay", persona="会員")); run("commit", "-qam", "persona changed")
        r = me("check"); assert r.returncode == 1 and "変更あり" in r.stdout, r.stdout     # 導線の定義が変われば未確認に戻る
        assert rec("--result", "seen") == 0 and me("check").returncode == 0
        cfg.write_text(flow("pay", persona="会員") + flow("refund", paths="other.ts")); run("commit", "-qam", "second flow")
        assert me("check").returncode == 1
        cfg.write_text(flow("pay", persona="会員"))                              # 手元で一覧から外しても、コミットの一覧で判定する
        r = me("check"); assert r.returncode == 1 and "refund" in r.stdout, r.stdout
        run("checkout", "-q", "--", ".github/main-flows.toml")
        good = log_path().read_text()
        log_path().write_text(good + '{"repo": "x", "flow": "pay", "result": "fix"\n')
        r = me("check"); assert r.returncode == 2 and "行目が読めない" in r.stderr, r.stderr  # 壊れた記録で古い合格を生かさない
        broken = log_path().read_bytes()
        assert rec("--result", "seen") == 2 and log_path().read_bytes() == broken    # 壊れた記録には書き足さない
        log_path().write_bytes(good.encode() + b"\xff\n")
        r = me("check"); assert r.returncode == 2 and "行目が読めない" in r.stderr, r.stderr  # UTF-8 として読めない行
        # 一度も見ていない導線の見送りを記録に直接書いても、未確認のまま
        direct = dict(json.loads(good.splitlines()[-1]), flow="refund", result="waived", note="直接書いた")
        direct["fingerprint"] = fingerprint(repo, "HEAD", flows_at(repo, "HEAD", DEFAULT_CONFIG)[1])[0]
        log_path().write_text(good + json.dumps(direct, ensure_ascii=False) + "\n")
        r = me("check"); assert r.returncode == 1 and "未確認\trefund" in r.stdout, r.stdout + r.stderr
        log_path().write_text(good)
        cfg.write_text("flow = [1]\n"); run("commit", "-qam", "bad list")
        assert me("check").returncode == 2
        cfg.write_text(flow("pay", paths="nothing/**")); run("commit", "-qam", "bad paths")
        r = me("check"); assert r.returncode == 2 and "1 つも無い" in r.stderr, r.stderr  # 空振りを合格にしない
    os.environ.clear(); os.environ.update(saved)
    print("self-test ok")


def main():
    if "--self-test" in sys.argv:
        return self_test()
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--repo", default=".")
    common.add_argument("--config", default=DEFAULT_CONFIG, help="一覧の path（リポジトリの直下から）")
    common.add_argument("--rev", default=None, help="見る版（既定は HEAD。HEAD の時は、未コミットの変更も確かめる）")
    c = sub.add_parser("check", parents=[common])
    c.add_argument("--json", action="store_true")
    r = sub.add_parser("record", parents=[common])
    r.add_argument("flow")
    r.add_argument("--result", required=True, choices=sorted(RESULTS))
    r.add_argument("--by", required=True, help="見た人（見送りを決めた人）")
    r.add_argument("--env")
    r.add_argument("--browser")
    r.add_argument("--note")
    r.add_argument("--findings", type=int, default=0)
    a = ap.parse_args()
    return (cmd_check if a.cmd == "check" else cmd_record)(a)


if __name__ == "__main__":
    sys.exit(main())
