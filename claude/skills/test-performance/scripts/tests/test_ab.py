import importlib.util
import os
import subprocess
import sys
import tempfile
import time
import unittest

AB = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "ab.py")
spec = importlib.util.spec_from_file_location("ab", AB)
ab_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ab_module)

# Stands in for a test runner: writes a report built from its arguments.
# argv: report path, exit code, then "file:test:status" entries ("file::status" = file entry only;
# "a|b" as the test is a test b in a suite a)
FAKE = """
import json, os, sys, time
path, code, entries = sys.argv[1], int(sys.argv[2]), sys.argv[3:]
files = {}
for e in entries:
    name, test, status = e.split(":")
    f = files.setdefault(name, {"name": os.path.abspath(name), "status": "passed", "assertionResults": []})
    if test:
        *suites, title = test.split("|")
        f["assertionResults"].append({"ancestorTitles": suites, "title": title, "status": status,
                                      "fullName": " ".join([*suites, title])})
    else:
        f["status"] = status
json.dump({"testResults": list(files.values())}, open(path, "w"))
sys.exit(code)
"""


class AbTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.fake = os.path.join(self.tmp.name, "fake.py")
        with open(self.fake, "w") as f:
            f.write(FAKE)

    def command(self, *entries, code=0):
        quoted = " ".join(f"'{e}'" for e in entries)
        return f"{sys.executable} {self.fake} {{json}} {code} {quoted}"

    def ab(self, a, b, *extra):
        return subprocess.run([sys.executable, AB, "--a", a, "--b", b, "--cwd", self.tmp.name,
                               "--rounds", "2", "--warmup", "0", *extra], capture_output=True, text=True)

    def test_same_tests_pass(self):
        r = self.ab(self.command("x.test.ts:one:passed"), self.command("x.test.ts:one:passed"))
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertIn("SAME tests: files 1, passed 1", r.stdout)

    def test_order_of_tests_does_not_matter(self):
        r = self.ab(self.command("x:one:passed", "y:two:passed"), self.command("y:two:passed", "x:one:passed"))
        self.assertEqual(r.returncode, 0, r.stdout)

    def test_missing_test_is_reported(self):
        r = self.ab(self.command("x:one:passed", "x:two:passed"), self.command("x:one:passed"))
        self.assertEqual(r.returncode, 1)
        self.assertIn("- passed   x two", r.stdout)

    def test_same_count_with_different_names_is_reported(self):
        r = self.ab(self.command("x:one:passed"), self.command("x:renamed:passed"))
        self.assertEqual(r.returncode, 1)
        self.assertIn("+ passed   x renamed", r.stdout)

    def test_new_skip_is_reported(self):
        r = self.ab(self.command("x:one:passed"), self.command("x:one:skipped"))
        self.assertEqual(r.returncode, 1)
        self.assertIn("+ skipped  x one", r.stdout)

    def test_duplicate_names_are_counted(self):
        r = self.ab(self.command("x:one:passed", "x:one:passed"), self.command("x:one:passed"))
        self.assertEqual(r.returncode, 1)

    def test_file_that_fails_to_load_is_reported(self):
        r = self.ab(self.command("x:one:passed", "y::passed"), self.command("x:one:passed", "y::failed"))
        self.assertEqual(r.returncode, 1)
        self.assertIn("+ failed   y", r.stdout)

    def test_exit_code_difference_is_reported(self):
        # e.g. unhandled errors: every test passes but the run fails
        r = self.ab(self.command("x:one:passed"), self.command("x:one:passed", code=1))
        self.assertEqual(r.returncode, 1)
        self.assertIn("DIFFERENT exit code: A 0, B 1", r.stdout)

    def test_same_existing_failure_is_accepted_but_named(self):
        a = self.command("x:one:failed", code=1)
        r = self.ab(a, a)
        self.assertEqual(r.returncode, 0)
        self.assertIn("baseline is not green", r.stdout)

    def test_result_that_changes_between_rounds_is_unstable(self):
        marker = os.path.join(self.tmp.name, "seen")
        flaky = (f"if [ -e {marker} ]; then {self.command('x:one:failed')}; "
                 f"else touch {marker}; {self.command('x:one:passed')}; fi")
        r = self.ab(self.command("x:one:passed"), flaky)
        self.assertEqual(r.returncode, 1)
        self.assertIn("UNSTABLE: B", r.stdout)

    def test_same_full_name_in_different_suites_is_not_mixed_up(self):
        r = self.ab(self.command("x:a b|c:passed", "x:a|b c:skipped"),
                    self.command("x:a b|c:skipped", "x:a|b c:passed"))
        self.assertEqual(r.returncode, 1)
        self.assertIn("+ skipped  x a b > c", r.stdout)

    def test_empty_run_is_not_a_pass(self):
        for empty in (self.command(), self.command("x::passed")):  # no file; a file without tests
            r = self.ab(empty, empty)
            self.assertEqual(r.returncode, 1)
            self.assertIn("EMPTY", r.stdout)

    def test_malformed_report_is_an_environment_error(self):
        for report in ("null", '{"testResults": null}'):
            r = self.ab(f"echo '{report}' > {{json}}", self.command("x:one:passed"))
            self.assertEqual(r.returncode, 2, r.stdout + r.stderr)
            self.assertIn("A wrote no usable JSON report", r.stderr)

    def test_temporary_path_with_a_space_works(self):
        spaced = os.path.join(self.tmp.name, "with space")
        os.mkdir(spaced)
        cmd = self.command("x:one:passed")
        r = subprocess.run([sys.executable, AB, "--a", cmd, "--b", cmd, "--cwd", self.tmp.name, "--rounds", "1",
                            "--warmup", "0"], capture_output=True, text=True, env=dict(os.environ, TMPDIR=spaced))
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)

    def test_terminating_ab_stops_what_it_started(self):
        pid_file = os.path.join(self.tmp.name, "pid")
        sleeper = f"sleep 60 & echo $! > {pid_file}; wait; true {{json}}"
        ok = self.command("x:one:passed")
        for args in (["--a", sleeper, "--b", sleeper], ["--a", ok, "--b", ok, "--prepare", sleeper]):
            ab = subprocess.Popen([sys.executable, AB, "--cwd", self.tmp.name, *args],
                                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            deadline = time.monotonic() + 20
            while not (os.path.exists(pid_file) and os.path.getsize(pid_file)) and time.monotonic() < deadline:
                time.sleep(0.05)
            with open(pid_file) as f:
                grandchild = int(f.read())
            os.remove(pid_file)
            ab.terminate()
            self.assertEqual(ab.wait(timeout=20), 143)
            time.sleep(0.2)  # the orphan is reaped by init
            with self.assertRaises(ProcessLookupError):
                os.kill(grandchild, 0)

    def test_different_signals_are_different_results(self):
        a = self.command("x:one:passed") + "; kill -TERM $$"
        b = self.command("x:one:passed") + "; kill -KILL $$"
        r = self.ab(a, b)
        self.assertEqual(r.returncode, 1)
        self.assertIn("DIFFERENT exit code: A -15, B -9", r.stdout)

    def test_failing_prepare_is_an_environment_error(self):
        cmd = self.command("x:one:passed")
        r = self.ab(cmd, cmd, "--prepare", "exit 3")
        self.assertEqual(r.returncode, 2)
        self.assertIn("--prepare exited with 3", r.stderr)

    def test_zero_cpu_time_does_not_crash(self):
        self.assertIn("nan", ab_module.compare({"A": [{"cpu": 0.0}], "B": [{"cpu": 0.0}]}, "cpu"))

    def test_max_others_must_be_a_positive_number(self):
        cmd = self.command("x:one:passed")
        for value in ("0", "-1", "nan", "inf"):
            self.assertEqual(self.ab(cmd, cmd, f"--max-others={value}").returncode, 2, value)

    def test_stale_report_is_not_reused(self):
        r = self.ab(self.command("x:one:passed"), "echo boom; true {json}")
        self.assertEqual(r.returncode, 2)
        self.assertIn("B wrote no usable JSON report", r.stderr)
        self.assertIn("boom", r.stderr)

    def test_rounds_alternate_and_prepare_runs_before_each(self):
        log = os.path.join(self.tmp.name, "log")
        a = f"printf A >> {log}; " + self.command("x:one:passed")
        b = f"printf B >> {log}; " + self.command("x:one:passed")
        r = self.ab(a, b, "--prepare", f"printf p >> {log}")
        self.assertEqual(r.returncode, 0, r.stdout)
        with open(log) as f:
            self.assertEqual(f.read(), "pApBpBpA")

    def test_cpu_of_descendants_is_counted(self):
        burn = f"{sys.executable} -c 'import time\nwhile time.process_time() < 0.5: pass'"
        r = self.ab(f"({burn}); " + self.command("x:one:passed"), self.command("x:one:passed"))
        cpu = [line for line in r.stdout.splitlines() if line.startswith("cpu")][0]
        a, b = (float(part.split("s")[0]) for part in (cpu.split("A")[1], cpu.split("B")[1]))
        self.assertGreater(a - b, 0.4)

    def test_worktree_paths_compare_by_relative_name(self):
        other = os.path.join(self.tmp.name, "wt")
        os.mkdir(other)
        cmd = self.command("x:one:passed")
        r = self.ab(cmd, cmd, "--cwd-b", other)
        self.assertEqual(r.returncode, 0, r.stdout)

    def test_placeholder_is_required(self):
        r = self.ab("true", "true {json}")
        self.assertEqual(r.returncode, 2)

    def test_machine_that_never_gets_quiet_stops_with_an_error(self):
        cmd = self.command("x:one:passed")
        r = self.ab(cmd, cmd, "--max-others", "0.000001", "--max-wait", "0")
        self.assertEqual(r.returncode, 2)
        self.assertIn("other processes kept using", r.stderr)

    def test_cores_used_by_others_are_reported(self):
        cmd = self.command("x:one:passed")
        r = self.ab(cmd, cmd, "--max-others", "100000")
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertRegex(r.stdout, r"others +\d+\.\d cores")


if __name__ == "__main__":
    unittest.main()
