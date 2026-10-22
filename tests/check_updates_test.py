#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Offline tests for tools/check-updates.py version logic (no network)."""
import importlib.util
from pathlib import Path
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "tools" / "check-updates.py"
spec = importlib.util.spec_from_file_location("check_updates", SCRIPT)
check_updates = importlib.util.module_from_spec(spec)
spec.loader.exec_module(check_updates)


class LatestStable(unittest.TestCase):
    def test_picks_highest_tag_not_first_or_lexical(self):
        tags = ["v0.3.0", "v0.10.0", "v0.3.2", "v0.2.1", "v0.3.1"]
        self.assertEqual(check_updates.latest_stable(tags), "0.10.0")

    def test_ignores_prereleases_and_noise(self):
        tags = ["v0.3.2", "v0.4.0-rc1", "nightly", "0.3.3-beta"]
        self.assertEqual(check_updates.latest_stable(tags), "0.3.2")

    def test_no_stable_release_is_an_error(self):
        with self.assertRaises(RuntimeError):
            check_updates.latest_stable(["nightly"])


class Evaluate(unittest.TestCase):
    def test_equal_versions_are_up_to_date(self):
        _, outdated = check_updates.evaluate([("Quickshell", "0.3.2", "0.3.2")])
        self.assertEqual(outdated, [])

    def test_newer_upstream_is_outdated(self):
        _, outdated = check_updates.evaluate([("Qt", "6.12.0", "6.12.1")])
        self.assertEqual(outdated, ["Qt 6.12.0 -> 6.12.1"])

    def test_stale_source_is_not_reported_as_update(self):
        # Regression: the mirror's "latest release" was v0.3.0 while the
        # configured (and tagged) version was 0.3.2.
        with self.assertRaises(RuntimeError):
            check_updates.evaluate([("Quickshell", "0.3.2", "0.3.0")])


if __name__ == "__main__":
    unittest.main()
