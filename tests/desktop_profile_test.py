# SPDX-License-Identifier: GPL-3.0-or-later
"""Native profile transactions; no changes to the test machine's KDE settings."""
import importlib.util
import configparser
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("desktop_profile", ROOT / "tools/desktop_profile.py")
PROFILE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PROFILE)


class MemoryStore:
    def __init__(self):
        self.values = {key: None for key in PROFILE.KEYS}
        self.writes = 0
        self.fail_at = -1

    def read(self, key):
        return self.values[key]

    def write(self, key, value):
        self.writes += 1
        if self.writes == self.fail_at:
            raise RuntimeError("write rejected")
        self.values[key] = value


class ProfileTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.store = MemoryStore()
        self.controller = PROFILE.NativeProfile(self.store, Path(self.directory.name) / "nova/profile.json")

    def test_preview_does_not_write(self):
        self.assertEqual(len(self.controller.preview("balanced")), len(PROFILE.KEYS))
        self.assertEqual(self.store.writes, 0)
        self.assertFalse(self.controller.state.exists())

    def test_restored_values_cannot_become_cli_options(self):
        store = object.__new__(PROFILE.KConfigStore)
        store.config = Path(self.directory.name)
        store.writer = "/usr/bin/kwriteconfig6"
        value = "--file=/tmp/not-a-profile-target"
        with patch.object(store, "run", return_value="") as run, patch.object(store, "read", return_value=value):
            store.write("files.icons", value)
            arguments = run.call_args.args[0]
            self.assertEqual(arguments[-2:], ["--", value])
            self.assertEqual(arguments[arguments.index("--file") + 1], str(store.config / "dolphinrc"))

    def test_apply_and_restore_absent_and_custom_keys(self):
        self.store.values["files.icons"] = "48"
        original = self.store.values.copy()
        with self.controller.locked():
            self.controller.apply("glass")
        self.assertEqual(self.store.values, PROFILE.profile("glass"))
        self.assertEqual(self.controller.state.stat().st_mode & 0o777, 0o600)
        self.controller.restore()
        self.assertEqual(self.store.values, original)
        self.assertFalse(self.controller.state.exists())

    def test_effects_are_exclusive_and_reduced_disables_motion(self):
        for name in ("balanced", "glass", "reduced"):
            values = PROFILE.profile(name)
            self.assertFalse(values["windows.scale"] == values["windows.fade"] == "true")
            self.assertFalse(values["windows.squash"] == values["windows.lamp"] == "true")
        self.assertEqual(PROFILE.profile("reduced")["apps.motion"], "0")
        self.assertEqual(PROFILE.profile("reduced")["windows.motion"], "0")

    def test_failure_rolls_back(self):
        original = self.store.values.copy()
        self.store.fail_at = 5
        with self.assertRaises(RuntimeError):
            self.controller.apply("balanced")
        self.assertEqual(self.store.values, original)
        self.assertFalse(self.controller.state.exists())

    def test_switch_preserves_original_and_is_idempotent(self):
        self.store.values["apps.motion"] = "1.25"
        original = self.store.values.copy()
        self.controller.apply("glass")
        self.assertEqual(self.controller.apply("glass")["changed"], 0)
        self.controller.apply("reduced")
        self.controller.restore()
        self.assertEqual(self.store.values, original)

    def test_restore_preserves_changes_made_later(self):
        self.controller.apply("glass")
        self.store.values["files.icons"] = "96"
        with self.assertRaises(ValueError):
            self.controller.apply("balanced")
        result = self.controller.restore()
        self.assertEqual(result["preserved"], ["files.icons"])
        self.assertEqual(self.store.values["files.icons"], "96")

    def test_interrupted_switch_can_restore_original(self):
        self.controller.apply("balanced")
        original = self.controller.load()["before"]
        previous = self.store.values.copy()
        desired = PROFILE.profile("glass")
        self.controller.save({"version":1, "profile":"glass", "phase":"applying",
                              "before": original, "applied": desired, "rollback": previous})
        self.store.values["windows.squash"] = desired["windows.squash"]
        self.controller.restore()
        self.assertEqual(self.store.values, original)

    def test_untrusted_journal_cannot_supply_keys_or_paths(self):
        self.controller.apply("glass")
        data = self.controller.load()
        data["before"]["/tmp/other-file"] = "bad"
        self.controller.state.write_text(json.dumps(data))
        with self.assertRaises(ValueError):
            self.controller.restore()

    def test_overlapping_changes_are_locked(self):
        with self.controller.locked():
            with self.assertRaises(BlockingIOError):
                with self.controller.locked():
                    self.fail("a second writer acquired the lock")

    def test_session_keys_use_nested_groups_and_installed_packages(self):
        store = object.__new__(PROFILE.KConfigStore)
        store.config = Path(self.directory.name)
        self.assertEqual(store.arguments("session.lockImage"),
                         ["--file", str(store.config / "kscreenlockerrc"), "--group", "Greeter", "--group", "Wallpaper",
                          "--group", "org.kde.image", "--group", "General", "--key", "Image"])
        values = PROFILE.profile("balanced", Path("/home/u/.local/share"))
        self.assertEqual(values["session.splash"], "org.knova.novashell")
        self.assertEqual(values["session.lockImage"], "file:///home/u/.local/share/wallpapers/NovaShell")

    def test_version_1_journal_keeps_untouched_session_keys(self):
        self.store.values["session.splash"] = "org.kde.breeze.desktop"
        legacy = {key: None for key in PROFILE.KEYS_V1}
        applied = {key: value for key, value in PROFILE.profile("glass").items() if key in PROFILE.KEYS_V1}
        for key, value in applied.items():
            self.store.values[key] = value
        self.controller.save({"version": 1, "profile": "glass", "phase": "active",
                              "before": legacy, "applied": applied})
        result = self.controller.restore()
        self.assertEqual(self.store.values["session.splash"], "org.kde.breeze.desktop")
        self.assertNotIn("session.splash", result["restored"] + result["preserved"])
        self.assertTrue(all(self.store.values[key] is None for key in PROFILE.KEYS_V1))

    def test_native_palettes_have_readable_text(self):
        def luminance(value):
            channels = [int(channel) / 255 for channel in value.split(",")]
            self.assertEqual(len(channels), 3)
            self.assertTrue(all(0 <= channel <= 1 for channel in channels))
            linear = [channel / 12.92 if channel <= 0.04045 else ((channel + 0.055) / 1.055) ** 2.4 for channel in channels]
            return sum(channel * weight for channel, weight in zip(linear, [0.2126, 0.7152, 0.0722]))
        for variant in ("Light", "Dark"):
            palette = configparser.ConfigParser()
            palette.read(ROOT / f"packaging/color-schemes/NovaGlass{variant}.colors")
            for group in ("Window", "View", "Button", "Selection", "Tooltip", "Complementary", "Header"):
                colors = palette[f"Colors:{group}"]
                bg, fg = luminance(colors["BackgroundNormal"]), luminance(colors["ForegroundNormal"])
                self.assertGreaterEqual((max(bg, fg) + 0.05) / (min(bg, fg) + 0.05), 4.5, (variant, group))


if __name__ == "__main__":
    unittest.main()
