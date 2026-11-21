"""Finite model -> implementation replay -> regression -> mutation self-check.

Only synthetic code. Fixed finite scope: capacity=1, two clients, one request
each, four scheduler steps; three acquisition outcomes and a Boolean inverse.
No proof about actual threads, DB atomicity, crashes, retries, liveness or I/O.
No writes/network/dependencies beyond Python's standard library.
"""

from itertools import permutations, product
import io
import json
import unittest

from fixture_impl import Reservation, decide
from regression_fixture import suite_for


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def schedules():
    actions = ((0, "check"), (0, "commit"), (1, "check"), (1, "commit"))
    return [order for order in permutations(actions)
            if all(order.index((c, "check")) < order.index((c, "commit")) for c in (0, 1))]


def model_trace(order, variant):
    # Tuple state is independent from the mutable implementation.
    occupied, permits = 0, frozenset()
    history = []
    for client, action in order:
        if action == "check":
            result = None
            if variant == "split":
                result = occupied == 0
                if result:
                    permits = permits | {client}
        else:
            if variant == "split":
                result = client in permits
            else:
                result = occupied in ({0, 1} if variant == "off-by-one" else {0})
            occupied += int(result)
        history.append((occupied, result))
    return history


def replay(order, variant):
    subject = Reservation(variant)
    history = []
    for client, action in order:
        result = getattr(subject, action)(client)
        history.append((subject.used, result))
    return history


def main():
    orders = schedules()
    require(len(orders) == 6 and len(set(orders)) == 6, "schedule enumeration incomplete")
    counts = {}
    witnesses = {}
    for variant in ("split", "fixed", "off-by-one"):
        bad = []
        for order in orders:
            model = model_trace(order, variant)
            actual = replay(order, variant)
            require(model == actual, f"model/code gap: {variant} {order}")
            # Named intent: no more than one accepted reservation, with progress
            # for this completed no-failure two-request scenario.
            if any(used > 1 for used, _ in actual) or actual[-1][0] != 1:
                bad.append(order)
        counts[variant] = len(bad)
        if bad:
            witnesses[variant] = bad[0]
    require(counts == {"split": 4, "fixed": 0, "off-by-one": 6}, "unexpected safety results")

    # Independent truth table is the AGREED synthetic intent, not output copied
    # from the implementation: error must deny even under inversion.
    allowed = {("match", False), ("miss", True)}
    inputs = list(product(("match", "miss", "error"), (False, True)))
    predicate_bad = {}
    for variant in ("fixed", "drop-error-guard"):
        predicate_bad[variant] = [case for case in inputs
                                 if decide(*case, variant) != (case in allowed)]
    require(predicate_bad == {"fixed": [], "drop-error-guard": [("error", True)]},
            "predicate oracle did not distinguish the error mutation")

    regressions = {}
    for variant in ("fixed", "split", "off-by-one", "drop-error-guard"):
        result = unittest.TextTestRunner(stream=io.StringIO()).run(suite_for(variant))
        require(result.testsRun == 2 and not result.errors, f"invalid test execution: {variant}")
        expected_failures = 0 if variant == "fixed" else 1
        require(len(result.failures) == expected_failures, f"oracle ineffective for {variant}")
        regressions[variant] = {"tests": result.testsRun, "assertion_failures": len(result.failures)}

    print(json.dumps({
        "status": "PASS", "schedules": len(orders), "predicate_inputs": len(inputs),
        "reservation_violations": counts, "counterexamples": witnesses,
        "predicate_violations": predicate_bad, "regressions": regressions,
        "mutations_killed": 2, "mutations_total": 2,
        "scope": "Synthetic capacity=1; 2 clients x check/commit; 3 outcomes x inverse.",
        "not_verified": ["real threads", "database atomicity", "crashes", "retries", "liveness", "production"]
    }, indent=2))


if __name__ == "__main__":
    main()
