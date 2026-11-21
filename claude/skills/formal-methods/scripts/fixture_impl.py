"""Synthetic implementations only; no I/O, clocks, real threads or services."""


class Reservation:
    """Two clients each call check then commit; capacity is one.

    split: checks a snapshot before commit.
    fixed: commit performs the check and update in one scheduler step.
    off-by-one: mutation of fixed's capacity guard.
    """

    def __init__(self, variant):
        if variant not in {"split", "fixed", "off-by-one"}:
            raise ValueError(variant)
        self.variant = variant
        self.used = 0
        self.ready = [False, False]

    def check(self, client):
        if self.variant == "split":
            self.ready[client] = self.used < 1
            return self.ready[client]
        return None

    def commit(self, client):
        if self.variant == "split":
            allow = self.ready[client]
        elif self.variant == "off-by-one":
            allow = self.used <= 1
        else:
            allow = self.used < 1
        if allow:
            self.used += 1
        return allow


def decide(outcome, inverse, variant):
    """Fixture contract: acquisition error always denies, even with inverse."""
    if outcome not in {"match", "miss", "error"}:
        raise ValueError(outcome)
    if variant == "fixed" and outcome == "error":
        return False
    if variant not in {"fixed", "drop-error-guard"}:
        raise ValueError(variant)
    return (outcome == "match") != inverse
