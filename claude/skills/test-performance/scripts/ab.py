#!/usr/bin/env python3
"""Run two test commands alternately; compare time, CPU and the tests that ran.

  ab.py --a 'npx vitest run --reporter=json --outputFile={json}' \
        --b 'npx vitest run --pool=vmThreads --reporter=json --outputFile={json}'

{json} is replaced by a quoted temporary path; the command must write a Vitest or
Jest JSON report there (Jest: --json --outputFile={json}). Exit code: 0 same tests,
1 different or unstable results, 2 usage or environment error.
"""
import argparse
import collections
import ctypes
import json
import math
import os
import shlex
import signal
import statistics
import subprocess
import sys
import tempfile
import time

MAX_REPEATS = 20


def fail(message):
    print(f"error: {message}", file=sys.stderr)
    sys.exit(2)


def machine_cpu_seconds():
    """CPU seconds used by the whole machine since boot (Linux, macOS)."""
    if sys.platform == "linux":
        with open("/proc/stat") as f:
            user, nice, system, _idle, _iowait, irq, softirq = map(int, f.readline().split()[1:8])
        return (user + nice + system + irq + softirq) / os.sysconf("SC_CLK_TCK")
    if sys.platform == "darwin":
        libc = ctypes.CDLL(None)
        ticks, count = (ctypes.c_uint * 4)(), ctypes.c_uint(4)
        if libc.host_statistics(libc.mach_host_self(), 3, ticks, ctypes.byref(count)):  # 3 = HOST_CPU_LOAD_INFO
            fail("host_statistics failed")
        user, system, _idle, nice = ticks
        return (user + system + nice) / 100
    fail("--max-others works on Linux and macOS only")


def wait_for_quiet(limit, timeout):
    """Wait until the machine uses at most `limit` cores for two seconds in a row."""
    start = time.monotonic()
    while True:
        before = machine_cpu_seconds()
        time.sleep(2)
        if (machine_cpu_seconds() - before) / 2 <= limit:
            return
        if time.monotonic() - start > timeout:
            fail(f"other processes kept using more than {limit} cores for {timeout}s")
        time.sleep(3)


def read_report(path, cwd):
    """Multiset of (file, test path, status). The test path is () for the file itself."""
    with open(path) as f:
        report = json.load(f)
    root, seen = os.path.realpath(cwd), collections.Counter()
    for result in report["testResults"]:
        name = os.path.relpath(os.path.realpath(result["name"]), root)
        seen[(name, (), result["status"])] += 1
        for test in result["assertionResults"]:
            seen[(name, (*test["ancestorTitles"], test["title"]), test["status"])] += 1
    return seen


def run_group(command, cwd, output):
    """Run a shell command in its own process group; stop the whole group when interrupted."""
    child = subprocess.Popen(command, shell=True, cwd=cwd, stdin=subprocess.DEVNULL, stdout=output,
                             stderr=subprocess.STDOUT, start_new_session=True)
    try:
        _, status, usage = os.wait4(child.pid, 0)
    except BaseException:
        os.killpg(child.pid, signal.SIGKILL)
        child.wait()
        raise
    child.returncode = os.waitstatus_to_exitcode(status)  # reaped above
    return child.returncode, usage


def run_once(label, command, cwd, workdir, watch_others):
    report = os.path.join(workdir, "report.json")
    log = os.path.join(workdir, f"{label}.log")
    if os.path.exists(report):
        os.remove(report)
    machine = machine_cpu_seconds() if watch_others else 0
    with open(log, "wb") as out:
        start = time.monotonic()
        code, usage = run_group(command.replace("{json}", shlex.quote(report)), cwd, out)
        wall = time.monotonic() - start
    # shortcut: counts only descendants that were reaped; processes killed without a wait
    # (e.g. a browser) are missed. Use an OS profiler when that matters.
    cpu = usage.ru_utime + usage.ru_stime
    others = (machine_cpu_seconds() - machine - cpu) / wall if watch_others else None
    try:
        tests = read_report(report, cwd)
    except (OSError, ValueError, KeyError, TypeError) as error:
        with open(log, "rb") as f:
            tail = f.read()[-2000:].decode(errors="replace")
        fail(f"{label} wrote no usable JSON report ({error!r})\n{tail}")
    return {"wall": wall, "cpu": cpu, "others": others, "exit": code, "tests": tests}


def outcome(run):
    return run["exit"], run["tests"]


def totals(tests):
    count = collections.Counter()
    for (_, test, status), n in tests.items():
        count[status if test else "files"] += n
    return ", ".join(f"{k} {v}" for k, v in sorted(count.items()))


def summary(runs, key):
    values = [r[key] for r in runs]
    return f"{statistics.median(values):8.2f}s  ({min(values):.2f}-{max(values):.2f})"


def compare(runs, key):
    a, b = ([r[key] for r in runs[k]] for k in "AB")
    base = statistics.median(a)
    delta = (statistics.median(b) / base - 1) * 100 if base else math.nan
    apart = max(b) < min(a) or max(a) < min(b)
    return f"{delta:+6.1f}%" + ("" if apart else "  (ranges overlap: treat as no difference)")


def differences(a, b):
    lines = []
    for sign, left, right in (("+", b, a), ("-", a, b)):
        for (name, test, status), n in sorted((left - right).items()):
            lines.append(f"{sign} {status:8} {name} {' > '.join(test)}" + (f" x{n}" if n > 1 else ""))
    return lines


def parse_args(argv):
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--a", required=True, help="baseline command, with {json}")
    p.add_argument("--b", required=True, help="candidate command, with {json}")
    p.add_argument("--cwd", default=".", help="working directory of both commands")
    p.add_argument("--cwd-b", help="working directory of B, when it is a separate worktree")
    p.add_argument("--rounds", type=int, default=3)
    p.add_argument("--warmup", type=int, default=1, help="unmeasured runs per side first (0 for cold measurements)")
    p.add_argument("--prepare", help="unmeasured command before every run, e.g. to clear a cache")
    p.add_argument("--max-others", type=float,
                   help="cores that other processes may use: wait until they use less, and repeat a run that shared more")
    p.add_argument("--max-wait", type=float, default=1800, help="give up waiting after this many seconds")
    args = p.parse_args(argv)
    if args.rounds < 1 or args.warmup < 0:
        p.error("--rounds must be at least 1 and --warmup at least 0")
    if args.max_others is not None and not 0 < args.max_others < math.inf:
        p.error("--max-others must be a positive number of cores")
    for side in ("a", "b"):
        if "{json}" not in getattr(args, side):
            p.error(f"--{side} must contain {{json}}")
    return args


def main(argv=None):
    args = parse_args(argv)
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(143))  # so that the running tests are stopped too
    commands = {"A": args.a, "B": args.b}
    cwds = {"A": args.cwd, "B": args.cwd_b or args.cwd}
    runs = {"A": [], "B": []}
    with tempfile.TemporaryDirectory() as workdir:
        for i in range(args.warmup + args.rounds):
            for label in ("AB", "BA")[i % 2]:
                for _ in range(MAX_REPEATS):
                    if args.prepare:
                        code, _ = run_group(args.prepare, cwds[label], None)
                        if code:
                            fail(f"--prepare exited with {code}")
                    if args.max_others:
                        wait_for_quiet(args.max_others, args.max_wait)
                    run = run_once(label, commands[label], cwds[label], workdir, args.max_others)
                    noisy = bool(args.max_others) and run["others"] > args.max_others
                    run["kind"] = "warmup" if i < args.warmup else "noisy" if noisy else "run"
                    runs[label].append(run)
                    print(f"{label} {run['kind']:6} wall {run['wall']:7.2f}s  cpu {run['cpu']:7.2f}s"
                          + (f"  others {run['others']:4.1f} cores" if args.max_others else "")
                          + f"  exit {run['exit']}  {totals(run['tests'])}", flush=True)
                    if run["kind"] != "noisy":
                        break
                else:
                    fail(f"{MAX_REPEATS} runs of {label} in a row shared more than {args.max_others} cores")

    print()
    measured = {label: [r for r in runs[label] if r["kind"] == "run"] for label in "AB"}
    for key in ("wall", "cpu"):
        print(f"{key:4}  A {summary(measured['A'], key)}   B {summary(measured['B'], key)}   {compare(measured, key)}")

    same = True
    for label in "AB":
        if any(outcome(r) != outcome(runs[label][0]) for r in runs[label]):
            same = False
            print(f"UNSTABLE: {label} gave different results between rounds")
    first_a, first_b = runs["A"][0], runs["B"][0]
    if not any(test for _, test, _ in first_a["tests"]):
        same = False
        print("EMPTY: no test ran")
    if first_a["exit"] != first_b["exit"]:
        same = False
        print(f"DIFFERENT exit code: A {first_a['exit']}, B {first_b['exit']}")
    changed = differences(first_a["tests"], first_b["tests"])
    if changed:
        same = False
        print(f"DIFFERENT tests ({len(changed)} lines, + only in B, - only in A):")
        print("\n".join(changed[:100]))
    if same:
        note = "" if first_a["exit"] == 0 else f"  (both exit {first_a['exit']}: the baseline is not green)"
        print(f"SAME tests: {totals(first_a['tests'])}{note}")
    return 0 if same else 1


if __name__ == "__main__":
    sys.exit(main())
