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
        changes = [key for key, value in PROFILE.profile("balanced").items() if value is not None]
        self.assertEqual(sorted(self.controller.preview("balanced")), sorted(changes))
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

    def test_look_follows_appearance_and_neutral_accent(self):
        self.store.values["look.accent"] = "61,174,233"
        self.store.values["look.accentWallpaper"] = "true"
        self.store.background = "32,33,36"
        self.store.window_background = lambda: self.store.background
        original = self.store.values.copy()
        self.controller.apply("balanced")
        self.assertEqual(self.store.values["look.icons"], "NovaGlass-dark")
        self.assertEqual(self.store.values["look.colors"], "NovaGlassDark")
        self.assertIsNone(self.store.values["look.accent"])
        self.assertEqual(self.store.values["look.accentWallpaper"], "false")
        self.controller.restore()
        self.assertEqual(self.store.values, original)
        self.assertEqual(PROFILE.profile("glass")["look.colors"], "NovaGlassLight")
        self.assertEqual(list(PROFILE.KEYS)[-1], "look.colors")  # palette last: accent first

    def test_keep_look_leaves_icons_accent_and_palette(self):
        self.store.values["look.colors"] = "BreezeDark"
        self.store.values["look.accent"] = "61,174,233"
        self.controller.apply("balanced", look=False)
        self.assertEqual(self.store.values["look.colors"], "BreezeDark")
        self.assertEqual(self.store.values["look.accent"], "61,174,233")
        self.assertIsNone(self.store.values["look.icons"])
        self.assertEqual(self.store.values["windows.blur"], "true")

    def test_dark_detection_is_bounded(self):
        self.assertTrue(PROFILE.is_dark("14,15,18"))
        self.assertFalse(PROFILE.is_dark("239,240,241"))
        for bad in (None, "", "a,b,c", "300,0,0", "1,2"):
            self.assertFalse(PROFILE.is_dark(bad))

    def test_reapply_after_upgrade_only_checks_owned_keys(self):
        # A v2 journal knew nothing of look keys; the user's palette is kept as "before".
        legacy = {key: None for key in PROFILE.KEYS_V2}
        applied = {key: value for key, value in PROFILE.profile("glass").items() if key in PROFILE.KEYS_V2}
        for key, value in applied.items():
            self.store.values[key] = value
        self.store.values["look.colors"] = "BreezeDark"
        self.controller.save({"version": 2, "profile": "glass", "phase": "active",
                              "before": legacy, "applied": applied})
        self.controller.apply("balanced")
        self.assertEqual(self.controller.load()["before"]["look.colors"], "BreezeDark")
        self.controller.restore()
        self.assertEqual(self.store.values["look.colors"], "BreezeDark")
        self.assertTrue(all(self.store.values[key] is None for key in PROFILE.KEYS_V2))

    def test_palette_restore_returns_to_plasma_default(self):
        store = object.__new__(PROFILE.KConfigStore)
        store.config = Path(self.directory.name)
        store.writer, store.reader = "/usr/bin/kwriteconfig6", "/usr/bin/kreadconfig6"
        store.colors, store.icons = "/usr/bin/plasma-apply-colorscheme", None
        with patch.object(store, "run", return_value="") as run, patch.object(store, "read", return_value=None):
            store.write("look.colors", None)
        self.assertEqual(run.call_args_list[0].args[0], [store.colors, "--", "BreezeLight"])
        self.assertIn("--delete", run.call_args_list[1].args[0])

    def test_terminal_profile_follows_appearance(self):
        self.store.window_background = lambda: "14,15,18"
        self.controller.apply("balanced")
        self.assertEqual(self.store.values["look.terminal"], "NovaShell Oscuro.profile")
        self.assertEqual(self.store.values["look.terminalSync"], "true")
        self.assertEqual((self.store.values["look.terminalLight"], self.store.values["look.terminalDark"]),
                         ("NovaShell Claro", "NovaShell Oscuro"))
        self.assertEqual(PROFILE.profile("reduced")["look.terminal"], "NovaShell Claro.profile")

    def test_version_3_journal_keeps_user_terminal(self):
        self.store.values["look.terminal"] = "Mio.profile"
        applied = {key: value for key, value in PROFILE.profile("glass").items() if key in PROFILE.KEYS_V3}
        before = {key: None for key in PROFILE.KEYS_V3}
        for key, value in applied.items():
            self.store.values[key] = value
        self.controller.save({"version": 3, "profile": "glass", "phase": "active", "before": before, "applied": applied})
        self.controller.restore()
        self.assertEqual(self.store.values["look.terminal"], "Mio.profile")

    def test_terminal_schemes_are_translucent_and_readable(self):
        def color(section):
            return tuple(int(part) for part in section["Color"].split(","))
        def luminance(rgb):
            linear = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in (v / 255 for v in rgb)]
            return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]
        def contrast(a, b):
            a, b = luminance(a), luminance(b)
            return (max(a, b) + 0.05) / (min(a, b) + 0.05)
        directory = ROOT / "packaging/konsole"
        for scheme in PROFILE.TERMINAL_SCHEMES:
            parser = configparser.ConfigParser(interpolation=None)
            parser.optionxform = str
            parser.read(directory / f"{scheme}.colorscheme")
            general = parser["General"]
            self.assertEqual(general["Blur"], "true")
            self.assertTrue(0.6 <= float(general["Opacity"]) < 1, scheme)
            background = color(parser["Background"])
            self.assertGreaterEqual(contrast(color(parser["Foreground"]), background), 12, scheme)
            for index in range(1, 8):  # Color0 is "black": unreadable on dark by convention
                self.assertGreaterEqual(contrast(color(parser[f"Color{index}"]), background), 4.5, (scheme, index))
                self.assertGreaterEqual(contrast(color(parser[f"Color{index}Intense"]), background), 3, (scheme, index))
            for group in parser.sections():
                if group != "General":
                    self.assertEqual(len(color(parser[group])), 3)
        for name, scheme in zip(PROFILE.TERMINAL_PROFILES.values(), PROFILE.TERMINAL_SCHEMES):
            parser = configparser.ConfigParser(interpolation=None)
            parser.optionxform = str
            parser.read(directory / f"{name}.profile")
            self.assertEqual(parser["General"]["Name"], name)
            self.assertEqual(parser["Appearance"]["ColorScheme"], scheme)


if __name__ == "__main__":
    unittest.main()
