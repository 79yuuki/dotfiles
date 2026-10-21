import fcntl
import importlib.util
import json
import os
import shutil
import signal
import subprocess
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
SCRIPT = os.path.join(os.path.dirname(HERE), "ponytail-sweep.py")

_spec = importlib.util.spec_from_file_location("ponytail_sweep", SCRIPT)
sweep = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(sweep)

TODAY = "2026-01-15"
ME = "me@example.com"

GIT_ENV = dict(
    os.environ,
    GIT_CONFIG_GLOBAL=os.devnull,
    GIT_CONFIG_NOSYSTEM="1",
    GIT_TERMINAL_PROMPT="0",
)

FAKE_CLAUDE = """#!%s
import json, os, signal, sys
rec = os.environ["FAKE_RECORD"]
cwd = os.getcwd()
readme = os.path.join(cwd, "README.md")
entry = {
    "argv": sys.argv[1:],
    "cwd": cwd,
    "files": sorted(os.listdir(cwd)),
    "readme": open(readme).read() if os.path.exists(readme) else None,
}
with open(rec, "a") as f:
    f.write(json.dumps(entry) + "\\n")
kill_at = os.environ.get("FAKE_KILL_AT")
if kill_at and len(open(rec).read().splitlines()) == int(kill_at):
    os.kill(os.getppid(), signal.SIGKILL)  # 親（スイープ）を強制終了する
    sys.exit(1)
with open(os.environ["FAKE_OUT"]) as f:
    sys.stdout.write(f.read())
sys.exit(int(os.environ.get("FAKE_RC", "0")))
""" % sys.executable


def git(repo, *args, email=None, date=None):
    cmd = ["git"]
    if email:
        cmd += ["-c", "user.email=" + email]
    env = GIT_ENV
    if date:
        env = dict(GIT_ENV, GIT_AUTHOR_DATE=date, GIT_COMMITTER_DATE=date)
    r = subprocess.run(cmd + list(args), cwd=repo, capture_output=True, text=True, env=env)
    assert r.returncode == 0, r.stderr
    return r.stdout.strip()


def init_repo(path, commit=True):
    os.makedirs(path)
    git(path, "init", "-q")
    git(path, "config", "user.email", ME)
    git(path, "config", "user.name", "Me")
    git(path, "config", "commit.gpgsign", "false")
    if commit:
        write_commit(path, {"README.md": "committed\n"}, "init")


def write_commit(repo, files, msg="c", email=None, date=None):
    for name, content in files.items():
        full = os.path.join(repo, name)
        os.makedirs(os.path.dirname(full), exist_ok=True)
        mode = "wb" if isinstance(content, bytes) else "w"
        with open(full, mode) as f:
            f.write(content)
    git(repo, "add", "-A")
    git(repo, "commit", "-q", "-m", msg, email=email, date=date)
    return git(repo, "rev-parse", "HEAD")


def audit_json(must_fix=(), cost=0.5, **extra):
    so = {
        "repo_summary": "summary",
        "verdict": "VERDICT-TEXT",
        "must_fix": list(must_fix),
        "should_fix_count": 0,
        "nice_to_have_count": 0,
        "not_checked": "",
        "report_markdown": "# REPORT",
    }
    d = {"type": "result", "subtype": "success", "is_error": False, "total_cost_usd": cost,
         "result": "ok", "structured_output": so}
    d.update(extra)
    return json.dumps(d)


def mf(title, known_id="", tag=None):
    tag = tag or title
    return {"title": title, "location": "src/%s.py:1" % tag, "problem": "PROBLEM-" + tag,
            "fix": "FIX-" + tag, "if_skipped": "SKIP-" + tag, "known_id": known_id}


class Base(unittest.TestCase):
    def setUp(self):
        self.tmp = os.path.realpath(tempfile.mkdtemp(prefix="pts-"))
        self.addCleanup(shutil.rmtree, self.tmp, True)
        self.root = os.path.join(self.tmp, "root")
        self.sd = os.path.join(self.tmp, "state")
        os.makedirs(self.root)
        self.config = {"roots": [self.root]}
        self.cfg_path = os.path.join(self.tmp, "config.json")
        self.record = os.path.join(self.tmp, "record.jsonl")
        self.out = os.path.join(self.tmp, "fake_out.json")
        self.claude = os.path.join(self.tmp, "fake-claude")
        with open(self.claude, "w") as f:
            f.write(FAKE_CLAUDE)
        os.chmod(self.claude, 0o755)
        self.plugin = os.path.join(self.tmp, "plugin")
        os.makedirs(self.plugin)
        self.set_out(audit_json())
        self.rc = "0"

    def set_out(self, text):
        with open(self.out, "w") as f:
            f.write(text)

    def repo(self, name, commit=True):
        p = os.path.join(self.root, name)
        init_repo(p, commit)
        return p

    def run_sweep(self, *args, env=None, cfg=None):
        if cfg:
            self.config.update(cfg)
        with open(self.cfg_path, "w") as f:
            json.dump(self.config, f)
        e = dict(
            GIT_ENV,
            PONYTAIL_SWEEP_CONFIG=self.cfg_path,
            PONYTAIL_SWEEP_STATE_DIR=self.sd,
            PONYTAIL_SWEEP_CLAUDE=self.claude,
            PONYTAIL_SWEEP_PLUGIN_DIR=self.plugin,
            PONYTAIL_SWEEP_NOTIFY="0",
            PONYTAIL_SWEEP_TODAY=TODAY,
            FAKE_RECORD=self.record,
            FAKE_OUT=self.out,
            FAKE_RC=self.rc,
        )
        e.update(env or {})
        return subprocess.run([sys.executable, SCRIPT] + list(args), capture_output=True, text=True, env=e)

    def run_ok(self, *args, **kw):
        r = self.run_sweep("run", *args, **kw)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        return r

    def calls(self):
        if not os.path.exists(self.record):
            return []
        with open(self.record) as f:
            return [json.loads(line) for line in f if line.strip()]

    def state(self):
        with open(os.path.join(self.sd, "state.json")) as f:
            return json.load(f)

    def rs(self, repo):
        return self.state()["repos"][os.path.realpath(repo)]

    def digest(self):
        with open(os.path.join(self.sd, "digests", TODAY + ".md")) as f:
            return f.read()

    def baselined_repo(self, name="proj"):
        repo = self.repo(name)
        self.run_ok()
        return repo

    def add_own_test(self, repo, n=1, date=None):
        write_commit(repo, {"tests/test_%s.py" % git(repo, "rev-parse", "HEAD")[:8]: "".join(
            "def test_x%d():\n    pass\n" % i for i in range(n))}, "add test", date=date)


class DiscoveryTest(Base):
    def test_discover(self):
        r = self.root
        for p in ["a", "b/c", "d1/d2/ok", "ex/skipme"]:
            init_repo(os.path.join(r, p))
        init_repo(os.path.join(r, "b/c/inner"))  # リポジトリの中には降りない
        init_repo(os.path.join(r, ".hidden/x"))
        init_repo(os.path.join(r, "node_modules/y"))
        init_repo(os.path.join(r, "d1/d2/d3/deep"))  # 深さ 4
        os.makedirs(os.path.join(r, "wt"))
        with open(os.path.join(r, "wt", ".git"), "w") as f:
            f.write("gitdir: /nonexistent\n")
        found = sweep.discover_repos([r, r], 3, ["*/skipme"])
        real = os.path.realpath(r)
        self.assertEqual(
            sorted(found),
            sorted(os.path.join(real, p) for p in ["a", "b/c", "d1/d2/ok"]),
        )

    def test_max_depth_one(self):
        init_repo(os.path.join(self.root, "a"))
        init_repo(os.path.join(self.root, "b/c"))
        found = sweep.discover_repos([self.root], 1, [])
        self.assertEqual([os.path.basename(p) for p in found], ["a"])

    def test_no_commit_repo_skipped_in_run(self):
        self.repo("empty", commit=False)
        r = self.run_ok("--dry-run")
        self.assertIn(" skip ", r.stdout)
        self.assertIn("コミットがありません", r.stdout)


class MetricsTest(Base):
    def test_count_tests(self):
        repo = self.repo("m")
        head = write_commit(repo, {
            "t.py": "def test_a():\n    pass\n\nasync def test_b():\n    pass\n\ndef helper():\n    pass\n",
            "a.test.ts": "it('x', () => {})\ntest(\"y\", () => {})\n",
            "s_spec.rb": "describe 'x' do\n  it 'works' do\n  end\nend\n",
            "foo_test.go": "func TestX(t *testing.T) {\n}\n",
            "lib.rs": "#[test]\nfn a() {}\n#[tokio::test]\nasync fn b() {}\n",
            "T.java": "class T {\n  @Test\n  void a() {}\n}\n",
            "T.t.sol": "contract T {\n  function test_foo() public {}\n}\n",
            "x.bats": "@test \"x\" {\n  true\n}\n",
            "w_test.exs": "defmodule W do\n  test \"works\" do\n  end\nend\n",
            "foo.cpp": "TEST(Foo, Bar) {\n}\nTEST_F(A, b) {\n}\nTEST_VALUE = 1\n",
            "plain.js": "const ok = re.test(s)\nfunction helper() {}\n",
            "node_modules/dep/t.py": "def test_ignored():\n    pass\n",
        })
        # py 2 + ts 2 + rb 1 + go 1 + rs 2 + java 1 + sol 1 + bats 1 + exs 1 + cpp 2
        self.assertEqual(sweep.count_tests(repo, head), 14)

    def test_count_tests_none(self):
        repo = self.repo("m")
        head = write_commit(repo, {"a.js": "const ok = re.test(s)\n"})
        self.assertEqual(sweep.count_tests(repo, head), 0)

    def test_net_code_lines(self):
        repo = self.repo("m")
        base = write_commit(repo, {
            "src/a.py": "".join("a%d = 1\n" % i for i in range(10)),
            "src/b.py": "".join("b%d = 1\n" % i for i in range(10)),
        })
        with open(os.path.join(repo, "src/a.py")) as fh:
            a = fh.read() + "".join("n%d = 1\n" % i for i in range(20))
        b = "".join("b%d = 1\n" % i for i in range(4))
        head = write_commit(repo, {
            "src/a.py": a,
            "src/b.py": b,
            "tests/test_a.py": "".join("x = %d\n" % i for i in range(50)),
            "src/foo_test.go": "".join("x := %d\n" % i for i in range(50)),
            "bin.py": b"\x00\x01\x02binary\x00",
            "dist/x.js": "".join("x = %d;\n" % i for i in range(100)),
        })
        self.assertEqual(sweep.net_code_lines(repo, base, head), 20 - 6)

    def test_net_code_lines_non_ascii_path(self):
        repo = self.repo("m")
        base = git(repo, "rev-parse", "HEAD")
        head = write_commit(repo, {
            "tests/日本語_test.py": "".join("x = %d\n" % i for i in range(40)),
            "tests/日本語.py": "".join("x = %d\n" % i for i in range(40)),
        })
        self.assertEqual(sweep.net_code_lines(repo, base, head), 0)

    def test_own_commits(self):
        repo = self.repo("m")
        base = git(repo, "rev-parse", "HEAD")
        write_commit(repo, {"a.txt": "1"}, email="Other@Example.com")
        write_commit(repo, {"a.txt": "2"}, email=" ME@example.com".strip())
        head = git(repo, "rev-parse", "HEAD")
        self.assertEqual(sweep.own_commits(repo, base, head), 1)


class VerdictTest(Base):
    def test_baseline_then_unchanged_without_claude(self):
        repo = self.baselined_repo()
        st = self.rs(repo)
        self.assertEqual(st["audited_sha"], git(repo, "rev-parse", "HEAD"))
        self.assertEqual(st["next_id"], 1)
        self.assertIsNone(st["last_audit_at"])
        r = self.run_ok()
        self.assertIn(" unchanged ", r.stdout)
        self.assertEqual(self.calls(), [])

    def test_no_own_commits(self):
        repo = self.baselined_repo()
        before = self.rs(repo)
        write_commit(repo, {"tests/test_o.py": "def test_o():\n    pass\n"}, email="other@example.com")
        r = self.run_ok()
        self.assertIn(" no-own-commits ", r.stdout)
        self.assertEqual(self.rs(repo), before)
        self.assertEqual(self.calls(), [])

    def test_trigger_on_new_tests(self):
        repo = self.baselined_repo()
        self.add_own_test(repo)
        r = self.run_ok()
        self.assertIn("tests +1", r.stdout)
        self.assertEqual(len(self.calls()), 1)
        st = self.rs(repo)
        self.assertEqual(st["audited_sha"], git(repo, "rev-parse", "HEAD"))
        self.assertEqual(st["test_count"], 1)
        self.assertEqual(st["last_audit_at"], TODAY)

    def test_code_growth_trigger_and_below_threshold(self):
        repo = self.baselined_repo()
        write_commit(repo, {"src/small.py": "".join("x%d = 1\n" % i for i in range(5))})
        r = self.run_ok()
        self.assertIn(" below-threshold ", r.stdout)
        self.assertEqual(self.calls(), [])
        write_commit(repo, {"src/big.py": "".join("x%d = 1\n" % i for i in range(40))})
        r = self.run_ok()
        self.assertIn("code +45 lines without new tests", r.stdout)
        self.assertEqual(len(self.calls()), 1)

    def test_rebaseline(self):
        repo = self.baselined_repo()
        p = os.path.join(self.sd, "state.json")
        st = self.state()
        st["repos"][os.path.realpath(repo)]["audited_sha"] = "0" * 40
        with open(p, "w") as f:
            json.dump(st, f)
        r = self.run_ok()
        self.assertIn(" rebaseline ", r.stdout)
        self.assertEqual(self.rs(repo)["audited_sha"], git(repo, "rev-parse", "HEAD"))
        self.assertEqual(self.calls(), [])


class AuditTest(Base):
    def test_argv_and_isolated_clone(self):
        repo = self.baselined_repo()
        self.add_own_test(repo)
        with open(os.path.join(repo, "README.md"), "w") as f:
            f.write("dirty\n")
        with open(os.path.join(repo, "dirty.txt"), "w") as f:
            f.write("untracked\n")
        self.run_ok()
        (call,) = self.calls()
        argv = call["argv"]
        for flag in ["-p", "/ponytail:ponytail-audit", "--restricted", "--strict-mcp-config", "--tools",
                     "Read,Glob,Grep", "--plugin-dir", "--json-schema", "--append-system-prompt",
                     "--no-session-persistence"]:
            self.assertIn(flag, argv)
        self.assertEqual(argv[argv.index("--plugin-dir") + 1], self.plugin)
        self.assertEqual(argv[argv.index("--tools") + 1], "Read,Glob,Grep")
        self.assertIn("--max-budget-usd", argv)
        work = os.path.realpath(os.path.join(self.sd, "work"))
        cwd = os.path.realpath(call["cwd"])
        self.assertTrue(cwd.startswith(work + os.sep), cwd)
        self.assertNotEqual(cwd, os.path.realpath(repo))
        self.assertFalse(os.path.exists(call["cwd"]))
        self.assertEqual(os.listdir(os.path.join(self.sd, "work")), [])
        self.assertEqual(call["readme"], "committed\n")
        self.assertNotIn("dirty.txt", call["files"])
        reports = os.path.join(self.sd, "reports", TODAY)
        names = sorted(os.listdir(reports))
        self.assertEqual(len(names), 2)
        md = [n for n in names if n.endswith(".md")][0]
        with open(os.path.join(reports, md)) as f:
            self.assertEqual(f.read(), "# REPORT")

    def test_dedup_across_runs(self):
        repo = self.baselined_repo()
        self.add_own_test(repo)
        self.set_out(audit_json([mf("first", ""), mf("second", "parse-price-decimal")]))
        self.run_ok()
        known = self.rs(repo)["known_must_fix"]
        self.assertEqual([k["id"] for k in known], ["PT-1", "PT-2"])
        self.assertIn("PROBLEM-first", self.digest())
        self.assertEqual(self.rs(repo)["next_id"], 3)

        self.add_own_test(repo)
        self.set_out(audit_json([mf("first-renamed", "PT-1", tag="first"), mf("third", "")]))
        self.run_ok()
        st = self.rs(repo)
        self.assertEqual([k["id"] for k in st["known_must_fix"]], ["PT-1", "PT-3", "PT-2"])
        self.assertEqual([k["missed"] for k in st["known_must_fix"]], [0, 0, 1])
        self.assertEqual(st["known_must_fix"][0]["title"], "first-renamed")
        self.assertEqual(st["known_must_fix"][0]["first_seen"], TODAY)
        second_run = self.digest().split("の実行")[-1]
        self.assertIn("[PT-3] third", second_run)
        self.assertIn("PROBLEM-third", second_run)
        self.assertIn("FIX-third", second_run)
        self.assertIn("SKIP-third", second_run)
        self.assertNotIn("PROBLEM-first", second_run)
        self.assertIn("継続中の Must fix 1 件", second_run)
        self.assertIn("今回出なかった: second", second_run)
        # 2 回目の呼び出しには以前の一覧が渡る
        prompt = self.calls()[1]["argv"]
        prompt = prompt[prompt.index("--append-system-prompt") + 1]
        self.assertIn('"PT-2"', prompt)

    def test_failures_and_failing(self):
        repo = self.baselined_repo()
        self.add_own_test(repo)
        base_sha = self.rs(repo)["audited_sha"]
        head = git(repo, "rev-parse", "HEAD")
        self.rc = "1"
        self.set_out("")
        self.run_ok(cfg={"failure_limit": 2})
        st = self.rs(repo)
        self.assertEqual((st["audited_sha"], st["consecutive_failures"], st["failed_sha"], st["last_error"]),
                         (base_sha, 1, head, "exit 1"))
        self.assertTrue(any(n.endswith(".json") for n in os.listdir(os.path.join(self.sd, "reports", TODAY))))
        self.run_ok()
        self.assertEqual(self.rs(repo)["consecutive_failures"], 2)
        self.assertEqual(len(self.calls()), 2)
        self.assertIn("--force で手動実行するまで監査しません", self.digest())
        r = self.run_ok()
        self.assertIn(" failing ", r.stdout)
        self.assertEqual(len(self.calls()), 2)
        # head が変わっても、手動の --force までは費用をかけない
        self.add_own_test(repo)
        r = self.run_ok()
        self.assertIn(" failing ", r.stdout)
        self.assertEqual(len(self.calls()), 2)
        self.rc = "0"
        self.set_out(audit_json())
        self.run_ok("--only", repo, "--force")
        self.assertEqual(len(self.calls()), 3)
        st = self.rs(repo)
        self.assertEqual((st["consecutive_failures"], st["failed_sha"], st["audited_sha"]),
                         (0, None, git(repo, "rev-parse", "HEAD")))

    def test_stale_work_dir_is_removed(self):
        repo = self.baselined_repo()
        stale = os.path.join(self.sd, "work", "tmpstale", "proj")
        os.makedirs(stale)
        self.run_ok()
        self.assertFalse(os.path.exists(os.path.join(self.sd, "work", "tmpstale")))
        self.assertEqual(self.rs(repo)["consecutive_failures"], 0)

    def test_invalid_json_and_is_error(self):
        repo = self.baselined_repo()
        self.add_own_test(repo)
        base_sha = self.rs(repo)["audited_sha"]
        self.set_out("this is not json")
        self.run_ok()
        st = self.rs(repo)
        self.assertEqual((st["audited_sha"], st["consecutive_failures"]), (base_sha, 1))
        self.assertEqual(st["last_error"], "invalid JSON")
        self.set_out(audit_json(is_error=True, subtype="error_max_budget_usd"))
        self.run_ok()
        st = self.rs(repo)
        self.assertEqual((st["audited_sha"], st["consecutive_failures"]), (base_sha, 2))
        self.assertEqual(st["last_error"], "is_error: error_max_budget_usd")
        self.set_out(json.dumps({"is_error": False, "structured_output": {"must_fix": "x"}}))
        self.run_ok()
        self.assertEqual(self.rs(repo)["last_error"], "invalid structured_output")
        self.assertIn("失敗", self.digest())

    def _three_triggered(self):
        repos = [self.repo("r%d" % i) for i in range(3)]
        self.run_ok()
        for r in repos:
            self.add_own_test(r)
        return repos

    def test_max_audits_per_day(self):
        self._three_triggered()
        r = self.run_ok(cfg={"max_audits_per_day": 1})
        self.assertEqual(len(self.calls()), 1)
        self.assertEqual(r.stdout.count(" deferred "), 2)
        self.assertIn("max_audits_per_day", r.stdout)
        self.assertIn("max_audits_per_day", self.digest())
        self.assertIn("見送り", self.digest())

    def test_budget_per_run(self):
        self._three_triggered()
        self.set_out(audit_json(cost=4))
        r = self.run_ok(cfg={"budget_usd_per_day": 7})
        self.assertEqual(len(self.calls()), 1)
        self.assertEqual(r.stdout.count(" deferred "), 2)
        self.assertIn("budget_usd_per_day", r.stdout)
        self.assertIn("budget_usd_per_day", self.digest())
        self.assertIn("$4.00", self.digest())

    def test_plugin_missing_is_failure_without_count(self):
        repo = self.baselined_repo()
        self.add_own_test(repo)
        self.run_ok(env={"PONYTAIL_SWEEP_PLUGIN_DIR": os.path.join(self.tmp, "nope")})
        self.assertEqual(self.calls(), [])
        st = self.rs(repo)
        self.assertEqual(st["consecutive_failures"], 0)
        self.assertNotEqual(st["audited_sha"], git(repo, "rev-parse", "HEAD"))
        self.assertIn("plugin が見つからない", self.digest())


class IsolationTest(Base):
    def test_global_filter_not_run_on_checkout(self):
        marker = os.path.join(self.tmp, "marker")
        gcfg = os.path.join(self.tmp, "gitconfig")
        subprocess.run(["git", "config", "--file", gcfg, "filter.evil.smudge",
                        'sh -c "touch %s; cat"' % marker], check=True, env=GIT_ENV)
        subprocess.run(["git", "config", "--file", gcfg, "filter.evil.required", "false"], check=True, env=GIT_ENV)
        repo = self.repo("proj")
        env = {"GIT_CONFIG_GLOBAL": gcfg, "GIT_CONFIG_COUNT": "1", "GIT_CONFIG_KEY_0": "core.hooksPath",
               "GIT_CONFIG_VALUE_0": "/nonexistent"}
        self.run_ok(env=env)
        write_commit(repo, {".gitattributes": "* filter=evil\n"})  # GIT_ENV にはフィルター設定が無い
        self.add_own_test(repo)
        self.run_ok(env=env)
        self.assertEqual(len(self.calls()), 1)
        self.assertFalse(os.path.exists(marker))

    def test_isolated_env(self):
        os.environ["GIT_CONFIG_KEY_0"] = "x.y"
        os.environ["GIT_CONFIG_PARAMETERS"] = "'x.y=z'"
        self.addCleanup(os.environ.pop, "GIT_CONFIG_KEY_0", None)
        self.addCleanup(os.environ.pop, "GIT_CONFIG_PARAMETERS", None)
        env = sweep.isolated_git_env()
        self.assertNotIn("GIT_CONFIG_KEY_0", env)
        self.assertNotIn("GIT_CONFIG_PARAMETERS", env)
        self.assertEqual((env["GIT_CONFIG_GLOBAL"], env["GIT_CONFIG_NOSYSTEM"], env["GIT_LFS_SKIP_SMUDGE"]),
                         ("/dev/null", "1", "1"))


class BaseSelectionTest(Base):
    def test_feature_branch_triggers_on_new_test(self):
        repo = self.repo("proj")
        self.add_own_test(repo, 2)
        main = git(repo, "rev-parse", "--abbrev-ref", "HEAD")
        prev = git(repo, "rev-parse", "HEAD")
        self.add_own_test(repo, 1)
        self.run_ok()  # main の先頭（テスト 3 件）で baseline
        self.assertEqual(self.rs(repo)["test_count"], 3)
        git(repo, "checkout", "-q", "-b", "feature", prev)
        self.add_own_test(repo, 1, date="2030-01-01T00:00:00")  # main 側のコミットと同一にならないよう日時を変える
        r = self.run_ok()
        self.assertIn("tests +1", r.stdout)
        self.assertEqual(len(self.calls()), 1)
        git(repo, "checkout", "-q", main)

    def test_rewind_is_no_own_commits(self):
        repo = self.baselined_repo()
        self.add_own_test(repo)
        self.run_ok()
        git(repo, "reset", "-q", "--hard", "HEAD~1")
        r = self.run_ok()
        self.assertIn(" no-own-commits ", r.stdout)
        self.assertEqual(len(self.calls()), 1)

    def test_orphan_branch_rebaselines(self):
        repo = self.baselined_repo()
        git(repo, "checkout", "-q", "--orphan", "other")
        head = write_commit(repo, {"a.txt": "1"})
        r = self.run_ok()
        self.assertIn(" rebaseline ", r.stdout)
        self.assertEqual(self.rs(repo)["audited_sha"], head)
        self.assertEqual(self.calls(), [])


class DailyLimitTest(Base):
    def test_daily_counts_across_runs(self):
        self._two_triggered()
        self.run_ok(cfg={"max_audits_per_day": 1})
        self.assertEqual(self.state()["daily"], {"date": TODAY, "audits": 1, "cost": 0.5})
        r = self.run_ok()  # 同じ日の 2 回目の実行は残りがあれば続きをやる
        self.assertEqual(len(self.calls()), 1)
        self.assertIn("deferred", r.stdout)
        self.assertEqual(r.stdout.count(" deferred "), 1)
        r = self.run_ok(cfg={"max_audits_per_day": 2})
        self.assertEqual(len(self.calls()), 2)
        self.assertEqual(self.state()["daily"]["audits"], 2)
        self.add_own_test(os.path.join(self.root, "r0"))
        self.run_ok(env={"PONYTAIL_SWEEP_TODAY": "2026-01-16"})
        self.assertEqual(self.state()["daily"], {"date": "2026-01-16", "audits": 1, "cost": 0.5})

    def _two_triggered(self):
        repos = [self.repo("r%d" % i) for i in range(2)]
        self.run_ok()
        for r in repos:
            self.add_own_test(r)
        return repos

    def test_budget_daily_cost_uses_actual(self):
        self._two_triggered()
        self.set_out(audit_json(cost=1.25))
        self.run_ok(cfg={"budget_usd_per_day": 100})
        self.assertEqual(self.state()["daily"], {"date": TODAY, "audits": 2, "cost": 2.5})
        self.assertIn("今回の費用 $2.50（今日の累計 $2.50、1 日の上限の目安 $100）", self.digest())

    def test_max_audits_flag_overrides_daily_limit(self):
        self._two_triggered()
        self.run_ok("--max-audits", "1")
        self.run_ok("--max-audits", "1")
        self.assertEqual(len(self.calls()), 1)

    def test_force_ignores_limit_but_counts(self):
        repo = self.repo("a")
        self.run_ok("--only", repo, "--force", cfg={"max_audits_per_day": 0})
        self.assertEqual(len(self.calls()), 1)
        self.assertEqual(self.state()["daily"]["audits"], 1)

    def test_in_progress_reserved_before_claude(self):
        repo = self.baselined_repo()
        self.add_own_test(repo)
        head = git(repo, "rev-parse", "HEAD")
        # claude 起動時点の state を偽 claude が記録する代わりに、起動後に親を kill して残りを確かめる
        self.run_sweep("run", env={"FAKE_KILL_AT": "1"})
        st = self.rs(repo)
        self.assertEqual(st["in_progress"], head)
        self.assertEqual(self.state()["daily"], {"date": TODAY, "audits": 1, "cost": 5.0})
        # plugin 不在にして、再監査で last_error が上書きされないようにする
        r = self.run_ok(env={"PONYTAIL_SWEEP_PLUGIN_DIR": os.path.join(self.tmp, "nope")})
        self.assertIn(" interrupted ", r.stdout)
        # 中断分は失敗として数え、同じ日に予約済みの件数と費用はそのまま残る
        st = self.rs(repo)
        self.assertNotIn("in_progress", st)
        self.assertEqual(st["last_error"], "interrupted")
        self.assertEqual(st["failed_sha"], head)
        self.assertEqual(st["consecutive_failures"], 1)

    def test_pending_since_prevents_starvation(self):
        a = self.repo("a")
        b = self.repo("b")
        self.run_ok()
        self.add_own_test(b, date="2026-01-01T00:00:00")
        self.add_own_test(a, date="2026-01-02T00:00:00")
        self.run_ok(cfg={"max_audits_per_day": 1})
        self.assertEqual(self.rs(a)["last_audit_at"], TODAY)
        self.assertEqual(self.rs(b)["pending_since"], TODAY)
        b_head = git(b, "rev-parse", "HEAD")
        self.assertNotEqual(self.rs(b)["audited_sha"], b_head)
        day2 = {"PONYTAIL_SWEEP_TODAY": "2026-01-16"}
        self.add_own_test(a, date="2026-01-17T00:00:00")
        self.run_ok(env=day2)
        self.assertEqual(self.rs(b)["audited_sha"], b_head)
        self.assertIsNone(self.rs(b)["pending_since"])


class MissedTest(Base):
    def test_missed_then_found_again(self):
        repo = self.baselined_repo()
        self.add_own_test(repo)
        self.set_out(audit_json([mf("one")]))
        self.run_ok()
        self.add_own_test(repo)
        self.set_out(audit_json())
        self.run_ok()
        (k,) = self.rs(repo)["known_must_fix"]
        self.assertEqual((k["id"], k["missed"]), ("PT-1", 1))
        self.assertIn("今回出なかった: one", self.digest().split("の実行")[-1])
        self.add_own_test(repo)
        self.set_out(audit_json([mf("one", "PT-1")]))
        self.run_ok()
        st = self.rs(repo)
        self.assertEqual([(k["id"], k["missed"]) for k in st["known_must_fix"]], [("PT-1", 0)])
        self.assertEqual(st["next_id"], 2)
        self.assertIn("継続中の Must fix 1 件", self.digest().split("の実行")[-1])

    def test_dropped_after_three_misses(self):
        repo = self.baselined_repo()
        self.add_own_test(repo)
        self.set_out(audit_json([mf("one")]))
        self.run_ok()
        self.set_out(audit_json())
        for n in (1, 2):
            self.add_own_test(repo)
            self.run_ok(cfg={"max_audits_per_day": 10})
            self.assertEqual(self.rs(repo)["known_must_fix"][0]["missed"], n)
        # 以前の一覧には missed > 0 の項目も渡る
        prompt = self.calls()[-1]["argv"]
        self.assertIn('"PT-1"', prompt[prompt.index("--append-system-prompt") + 1])
        self.add_own_test(repo)
        self.run_ok()
        self.assertEqual(self.rs(repo)["known_must_fix"], [])
        self.assertIn("3 回続けて出なかったので解消とみなした: one", self.digest().split("の実行")[-1])


class DigestTest(Base):
    def test_report_files_not_overwritten(self):
        repo = self.baselined_repo()
        self.add_own_test(repo)
        self.run_ok()
        self.add_own_test(repo)
        self.run_ok()
        names = os.listdir(os.path.join(self.sd, "reports", TODAY))
        self.assertEqual(len([n for n in names if n.endswith(".md")]), 2)
        self.assertEqual(len([n for n in names if n.endswith(".json")]), 2)
        for n in names:
            if n.endswith(".md"):
                self.assertIn(n, self.digest())

    def test_digest_survives_kill(self):
        for i in range(2):
            self.repo("r%d" % i)
        self.run_ok()
        for i in range(2):
            self.add_own_test(os.path.join(self.root, "r%d" % i))
        r = self.run_sweep("run", env={"FAKE_KILL_AT": "2"})
        self.assertEqual(r.returncode, -signal.SIGKILL)
        digest = self.digest()
        self.assertIn("の実行", digest)
        self.assertEqual(digest.count("### "), 1)  # 1 件目の節だけ残る
        stuck = [p for p, rs in self.state()["repos"].items() if rs.get("in_progress")]
        self.assertEqual(len(stuck), 1)
        self.assertNotIn(os.path.basename(stuck[0]), digest)
        r = self.run_ok()
        self.assertEqual(r.stdout.count(" interrupted "), 1)
        self.assertIn("interrupted=1", r.stdout)

    def test_digest_failure_does_not_mark_audited(self):
        repo = self.baselined_repo()
        base_sha = self.rs(repo)["audited_sha"]
        self.add_own_test(repo)
        self.set_out(audit_json([mf("lost")]))
        ddir = os.path.join(self.sd, "digests")
        with open(ddir, "w") as f:  # digests をファイルにして追記を失敗させる
            f.write("")
        r = self.run_sweep("run")
        self.assertNotEqual(r.returncode, 0)
        st = self.rs(repo)
        self.assertEqual((st["audited_sha"], st["known_must_fix"]), (base_sha, []))
        self.assertTrue(st.get("in_progress"))
        os.remove(ddir)
        r = self.run_ok()
        self.assertIn(" interrupted ", r.stdout)
        # 載らなかった指摘は、次の監査で新規として digest に載る
        self.assertIn("PROBLEM-lost", self.digest())
        self.assertEqual([k["id"] for k in self.rs(repo)["known_must_fix"]], ["PT-1"])

    def test_forced_new_repo_digest_failure_is_retried(self):
        repo = self.repo("fresh")  # state に無いリポジトリを手動で監査する
        self.set_out(audit_json([mf("lost")]))
        ddir = os.path.join(self.sd, "digests")
        os.makedirs(self.sd)
        with open(ddir, "w") as f:
            f.write("")
        self.assertNotEqual(self.run_sweep("run", "--only", repo, "--force").returncode, 0)
        os.remove(ddir)
        # 変化が無くても、中断した監査は次の定期実行でやり直す
        r = self.run_ok()
        self.assertIn(" interrupted ", r.stdout)
        self.assertEqual(len(self.calls()), 2)
        self.assertIn("PROBLEM-lost", self.digest())
        st = self.rs(repo)
        self.assertEqual((st["retry"], st["consecutive_failures"]), (False, 0))
        self.run_ok()
        self.assertEqual(len(self.calls()), 2)

    def test_failed_audit_is_retried_without_new_commits(self):
        repo = self.baselined_repo()
        self.add_own_test(repo)
        self.rc = "1"
        self.set_out("")
        self.run_ok(cfg={"failure_limit": 2})
        self.assertTrue(self.rs(repo)["retry"])
        self.rc = "0"
        self.set_out(audit_json())
        r = self.run_ok()
        self.assertIn("retry", r.stdout)
        self.assertEqual(len(self.calls()), 2)
        self.assertEqual(self.rs(repo)["audited_sha"], git(repo, "rev-parse", "HEAD"))

    def test_invalid_cost_keeps_reservation(self):
        for bad in (float("nan"), -10):
            with self.subTest(cost=bad):
                shutil.rmtree(self.sd, ignore_errors=True)
                repo = os.path.join(self.root, "c%s" % ("nan" if bad != bad else "neg"))
                init_repo(repo)
                self.run_ok("--only", repo)
                self.add_own_test(repo)
                self.set_out(audit_json(cost=bad))
                self.run_ok("--only", repo)
                self.assertEqual(self.state()["daily"]["cost"], 5.0)

    def test_every_run_has_header_and_summary_last(self):
        repo = self.baselined_repo()
        self.add_own_test(repo)
        self.set_out(audit_json([mf("one")]))
        self.run_ok()
        d = self.digest()
        self.assertTrue(d.startswith("## "))
        self.assertLess(d.index("### "), d.index("監査 1 件 / 新しい Must fix 1 件"))

    def test_failing_listed_in_summary(self):
        repo = self.baselined_repo()
        self.add_own_test(repo)
        self.rc = "1"
        self.run_ok(cfg={"failure_limit": 1})
        self.add_own_test(repo)
        other = self.repo("other")
        self.run_ok()
        self.add_own_test(other)
        self.run_ok()
        d = self.digest()
        self.assertIn("停止中（failing）", d)

    def test_notify_failed_is_logged(self):
        repo = self.baselined_repo()
        self.add_own_test(repo)
        self.set_out(audit_json([mf("one")]))
        bindir = os.path.join(self.tmp, "bin")
        os.makedirs(bindir)
        fake = os.path.join(bindir, "osascript")
        with open(fake, "w") as f:
            f.write("#!/bin/sh\nexit 3\n")
        os.chmod(fake, 0o755)
        r = self.run_ok(env={"PONYTAIL_SWEEP_NOTIFY": "1", "PATH": bindir + os.pathsep + os.environ["PATH"]})
        self.assertIn("notify-failed", r.stdout)

    def test_invalid_structured_output_fields(self):
        repo = self.baselined_repo()
        self.add_own_test(repo)
        self.set_out(json.dumps({"is_error": False, "structured_output": {"must_fix": []}}))
        self.run_ok()
        self.assertEqual(self.rs(repo)["last_error"], "invalid structured_output")
        d = json.loads(audit_json())
        d["structured_output"]["should_fix_count"] = "1"
        self.set_out(json.dumps(d))
        self.run_ok()
        self.assertEqual(self.rs(repo)["consecutive_failures"], 2)


class CliTest(Base):
    def test_dry_run_writes_nothing(self):
        repo = self.baselined_repo()
        self.add_own_test(repo)
        with open(os.path.join(self.sd, "state.json"), "rb") as f:
            before = f.read()
        r = self.run_ok("--dry-run")
        self.assertIn(" trigger ", r.stdout)
        self.assertEqual(self.calls(), [])
        with open(os.path.join(self.sd, "state.json"), "rb") as f:
            self.assertEqual(f.read(), before)
        self.assertFalse(os.path.exists(os.path.join(self.sd, "digests")))

    def test_dry_run_fresh_state_dir(self):
        self.repo("a")
        r = self.run_ok("--dry-run")
        self.assertIn(" baseline ", r.stdout)
        self.assertFalse(os.path.exists(self.sd))

    def test_force_requires_only(self):
        self.repo("a")
        r = self.run_sweep("run", "--force")
        self.assertEqual(r.returncode, 2)
        self.assertEqual(self.calls(), [])

    def test_force_only_audits_unknown_repo(self):
        repo = self.repo("a")
        r = self.run_ok("--only", repo, "--force")
        self.assertIn("forced", r.stdout)
        self.assertEqual(len(self.calls()), 1)
        self.assertEqual(self.rs(repo)["last_audit_at"], TODAY)

    def test_only_outside_roots(self):
        outside = os.path.join(self.tmp, "outside")
        init_repo(outside)
        r = self.run_ok("--only", outside)
        self.assertIn(" baseline ", r.stdout)
        self.assertEqual(list(self.state()["repos"]), [os.path.realpath(outside)])

    def test_max_audits_flag(self):
        repos = [self.repo("r%d" % i) for i in range(2)]
        self.run_ok()
        for r in repos:
            self.add_own_test(r)
        self.run_ok("--max-audits", "1")
        self.assertEqual(len(self.calls()), 1)

    def test_max_audits_flag_negative(self):
        self.repo("a")
        self.assertEqual(self.run_sweep("run", "--max-audits", "-1").returncode, 2)

    def test_lock_held(self):
        self.repo("a")
        os.makedirs(self.sd)
        with open(os.path.join(self.sd, "lock"), "a+") as fh:
            fcntl.flock(fh, fcntl.LOCK_EX | fcntl.LOCK_NB)
            r = self.run_ok()
        self.assertIn("別の実行が進行中", r.stdout)
        self.assertFalse(os.path.exists(os.path.join(self.sd, "state.json")))

    def test_config_type_error(self):
        self.repo("a")
        for bad in [{"max_depth": "3"}, {"max_audits_per_day": True}, {"notify": 1}, {"roots": "x"},
                    {"max_depth": 2.5}, {"max_depth": 0}, {"failure_limit": 0}, {"audit_timeout_sec": 0},
                    {"max_audits_per_day": -1}, {"code_growth_min_lines": -1}, {"budget_usd_per_day": 0},
                    {"budget_usd_per_audit": float("nan")}, {"budget_usd_per_day": float("inf")},
                    {"budget_usd_per_audit": True}, {"roots": []}, {"roots": [""]}]:
            self.config = {"roots": [self.root]}
            r = self.run_sweep("run", cfg=bad)
            self.assertEqual(r.returncode, 2, bad)

    def test_config_numeric_compat_and_unknown_key(self):
        self.repo("a")
        r = self.run_sweep("run", cfg={"budget_usd_per_audit": 2.5, "max_depth": 2, "bogus": 1})
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("bogus", r.stderr)

    def test_corrupt_state(self):
        self.repo("a")
        os.makedirs(self.sd)
        p = os.path.join(self.sd, "state.json")
        with open(p, "w") as f:
            f.write("{broken")
        r = self.run_sweep("run")
        self.assertEqual(r.returncode, 2)
        with open(p) as f:
            self.assertEqual(f.read(), "{broken")
        self.assertEqual(self.run_sweep("status").returncode, 2)

    def test_invalid_state_shapes(self):
        self.repo("a")
        good = {"audited_sha": "x", "test_count": 0, "known_must_fix": [], "next_id": 1, "consecutive_failures": 0}
        item = {"id": "PT-1", "title": "t", "location": "l", "first_seen": "d", "last_seen": "d"}
        cases = {
            "null repo": {"version": 1, "repos": {"/x": None}},
            "version": {"version": 2, "repos": {}},
            "version bool": {"version": True, "repos": {}},
            "repos list": {"version": 1, "repos": []},
            "missing key": {"version": 1, "repos": {"/x": {k: v for k, v in good.items() if k != "next_id"}}},
            "bad int": {"version": 1, "repos": {"/x": dict(good, test_count="1")}},
            "bad item": {"version": 1, "repos": {"/x": dict(good, known_must_fix=[dict(item, id=1)])}},
            "bad missed": {"version": 1, "repos": {"/x": dict(good, known_must_fix=[dict(item, missed="1")])}},
            "bad optional": {"version": 1, "repos": {"/x": dict(good, in_progress=5)}},
            "bad daily": {"version": 1, "repos": {}, "daily": {"date": "d", "audits": 1}},
            "negative cost": {"version": 1, "repos": {}, "daily": {"date": "d", "audits": 1, "cost": -1}},
            "nan cost": {"version": 1, "repos": {}, "daily": {"date": "d", "audits": 1, "cost": float("nan")}},
            "negative audits": {"version": 1, "repos": {}, "daily": {"date": "d", "audits": -1, "cost": 0}},
        }
        os.makedirs(self.sd)
        p = os.path.join(self.sd, "state.json")
        for name, st in cases.items():
            text = json.dumps(st)
            with open(p, "w") as f:
                f.write(text)
            r = self.run_sweep("run")
            self.assertEqual(r.returncode, 2, name)
            with open(p) as f:
                self.assertEqual(f.read(), text, name)
        with open(p, "w") as f:
            json.dump({"version": 1, "repos": {"/x": dict(good, known_must_fix=[item])},
                       "daily": {"date": "d", "audits": 1, "cost": 0}}, f)
        self.assertEqual(self.run_sweep("status").returncode, 0)

    def test_status(self):
        repo = self.baselined_repo()
        r = self.run_sweep("status")
        self.assertEqual(r.returncode, 0)
        self.assertIn(os.path.realpath(repo), r.stdout)
        self.assertIn(git(repo, "rev-parse", "HEAD")[:12], r.stdout)
        self.assertIn("latest digest", r.stdout)


if __name__ == "__main__":
    unittest.main()
