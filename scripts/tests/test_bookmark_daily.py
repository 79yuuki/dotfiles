import os
import subprocess
import tempfile
import time
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
SCRIPTS = os.path.dirname(HERE)
RUNNER = os.path.join(SCRIPTS, "bookmark-daily.sh")
INSTALLER = os.path.join(SCRIPTS, "install-bookmark-daily.sh")


def write_exe(path, body):
    with open(path, "w") as f:
        f.write("#!/bin/bash\n" + body)
    os.chmod(path, 0o755)


class BookmarkDailyTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        t = self.tmp.name
        self.home = os.path.join(t, "home")
        self.task = os.path.join(t, "task")
        self.bin = os.path.join(t, "bin")
        skill_dir = os.path.join(self.home, ".codex/skills/bookmark-skill-learning")
        for d in (skill_dir, self.task, self.bin):
            os.makedirs(d)
        open(os.path.join(skill_dir, "SKILL.md"), "w").close()
        open(os.path.join(self.task, "sources.json"), "w").write("{}")
        self.record = os.path.join(t, "codex-argv")
        write_exe(os.path.join(self.bin, "codex"), 'printf "%s\\n" "$@" > "$FAKE_RECORD"\n')
        self.env = dict(
            os.environ,
            HOME=self.home,
            PATH=self.bin + ":/usr/bin:/bin",
            BOOKMARK_DAILY_TASK_DIR=self.task,
            BOOKMARK_DAILY_STATE_DIR=os.path.join(t, "state"),
            FAKE_RECORD=self.record,
        )

    def tearDown(self):
        self.tmp.cleanup()

    def run_runner(self, *args):
        return subprocess.run(["bash", RUNNER, *args], env=self.env, capture_output=True, text=True)

    def test_runs_codex_with_sandbox_and_today(self):
        r = self.run_runner()
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        argv = open(self.record).read().splitlines()
        self.assertEqual(argv[0], "exec")
        self.assertIn("workspace-write", argv)
        self.assertIn("sandbox_workspace_write.network_access=true", argv)
        self.assertEqual(argv[argv.index("-C") + 1], self.task)
        self.assertIn(time.strftime("%Y-%m-%d"), argv[-1])

    def test_skips_when_today_completed(self):
        d = os.path.join(self.task, "reports", time.strftime("%Y-%m-%d"))
        os.makedirs(d)
        open(os.path.join(d, "progress.json"), "w").write('{"state":"completed_no_change"}')
        r = self.run_runner()
        self.assertEqual(r.returncode, 0)
        self.assertIn("skip", r.stdout)
        self.assertFalse(os.path.exists(self.record))

    def test_fails_without_sources(self):
        os.remove(os.path.join(self.task, "sources.json"))
        r = self.run_runner()
        self.assertEqual(r.returncode, 1)
        self.assertFalse(os.path.exists(self.record))

    def test_propagates_codex_failure(self):
        write_exe(os.path.join(self.bin, "codex"), "exit 3\n")
        self.assertEqual(self.run_runner().returncode, 3)

    def test_installer_writes_valid_plist_and_skips_broken_codex(self):
        broken = os.path.join(self.tmp.name, "broken")
        os.makedirs(broken)
        write_exe(os.path.join(broken, "codex"), "exit 127\n")
        write_exe(os.path.join(self.bin, "codex"), "echo codex-cli 0.0\n")
        out = os.path.join(self.tmp.name, "out.plist")
        env = dict(self.env, PATH=broken + ":" + self.bin + ":/usr/bin:/bin", BOOKMARK_DAILY_PLIST_OUT=out)
        r = subprocess.run(["bash", INSTALLER], env=env, capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stderr)
        plist = open(out).read()
        self.assertIn("<string>%s:" % self.bin, plist)
        self.assertNotIn(broken, plist)
        self.assertIn("<integer>19</integer>", plist)

    def test_installer_rejects_bad_hour(self):
        env = dict(self.env, BOOKMARK_DAILY_HOUR="24", BOOKMARK_DAILY_PLIST_OUT=os.path.join(self.tmp.name, "x.plist"))
        r = subprocess.run(["bash", INSTALLER], env=env, capture_output=True, text=True)
        self.assertEqual(r.returncode, 1)


if __name__ == "__main__":
    unittest.main()
