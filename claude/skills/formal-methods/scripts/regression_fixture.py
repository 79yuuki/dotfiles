"""Run the SAME behavioral assertions against selected synthetic variants.

Expected exits: fixed=0, split=1, off-by-one=1, drop-error-guard=1.
Intent here is explicitly defined for the fixture, not inferred from a model.
"""

import argparse
import unittest

from fixture_impl import Reservation, decide


def suite_for(variant):
    reservation_variant = variant if variant in {"split", "off-by-one"} else "fixed"
    predicate_variant = "drop-error-guard" if variant == "drop-error-guard" else "fixed"

    class Contract(unittest.TestCase):
        def test_one_slot_accepts_exactly_one_of_two_clients(self):
            subject = Reservation(reservation_variant)
            subject.check(0)
            subject.check(1)
            accepted = [subject.commit(0), subject.commit(1)]
            self.assertEqual(sum(accepted), 1, "capacity-one contract violated")
            self.assertEqual(subject.used, 1)

        def test_error_denies_even_when_inverse(self):
            self.assertFalse(decide("error", True, predicate_variant), "error guard violated")

    return unittest.defaultTestLoader.loadTestsFromTestCase(Contract)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--variant", choices=["fixed", "split", "off-by-one", "drop-error-guard"], default="fixed")
    result = unittest.TextTestRunner(verbosity=2).run(suite_for(parser.parse_args().variant))
    raise SystemExit(0 if result.wasSuccessful() else 1)
