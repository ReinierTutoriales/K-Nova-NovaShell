# SPDX-License-Identifier: GPL-3.0-or-later
"""packaging/sddm/install-theme.sh: prioridad de configuración de SDDM y negativa sin root."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "packaging/sddm/install-theme.sh"


class InstallThemeTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        root = Path(self.directory.name)
        self.etc, self.system, self.main = root / "etc.d", root / "sys.d", root / "sddm.conf"
        self.etc.mkdir()
        self.system.mkdir()
        self.env = dict(os.environ, NOVA_SDDM_THEMES=str(root / "themes"), NOVA_SDDM_CONFD=str(self.etc),
                        NOVA_SDDM_CONF=str(self.main), NOVA_SDDM_SYSCONFD=str(self.system),
                        NOVA_DISPLAY_MANAGER_UNIT=str(root / "missing.service"))

    def run_script(self, *arguments):
        return subprocess.run(["bash", str(SCRIPT), *arguments], env=self.env, capture_output=True, text=True)

    def effective(self):
        result = self.run_script("status")
        self.assertEqual(result.returncode, 0, result.stderr)
        return next(line for line in result.stdout.splitlines() if line.startswith("Tema efectivo"))

    def test_status_follows_sddm_precedence(self):
        self.assertIn("(predeterminado)", self.effective())
        (self.system / "10-distro.conf").write_text("[Theme]\nCurrent=breeze\n")
        self.assertIn("breeze", self.effective())
        (self.etc / "kde_settings.conf").write_text("[General]\nNumlock=on\n[Theme]\nCurrent=maui\n")
        (self.etc / "zz-novashell.conf").write_text("[Theme]\nCurrent=novashell\n")
        self.assertIn("novashell", self.effective())
        self.main.write_text("[Theme]\nCurrent=elarun\n")
        self.assertIn("elarun", self.effective())
        self.assertIn("Gestor de sesión: desconocido", self.run_script("status").stdout)

    def test_changes_require_root(self):
        if os.geteuid() == 0:
            self.skipTest("se ejecuta como root")
        for action in ("install", "uninstall"):
            result = self.run_script(action, "/nonexistent")
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Hace falta root", result.stderr)
        self.assertFalse(Path(self.env["NOVA_SDDM_THEMES"]).exists())


if __name__ == "__main__":
    unittest.main()
