#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Carga las pantallas de sesión desde una instalación real (cmake --install).

Comprueba la estructura instalada y que el QML carga sin avisos, como lo haría
ksplashqml. Guarda capturas session-*.png en el build (o NOVA_SNAPSHOT_DIR).

Uso: session_smoke.py <directorio-de-build>
"""
import os
os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
os.environ.setdefault("QT_QUICK_BACKEND", "software")

import json
import pathlib
import subprocess
import sys
import tempfile
import unittest
from PySide6.QtCore import QUrl, QtMsgType, qInstallMessageHandler
from PySide6.QtGui import QGuiApplication
from PySide6.QtQuick import QQuickView
from PySide6.QtTest import QTest

BUILD = pathlib.Path(sys.argv.pop(1)).resolve() if len(sys.argv) > 1 else None
APP = QGuiApplication.instance() or QGuiApplication([])
WARNINGS = []
qInstallMessageHandler(lambda kind, _c, message: WARNINGS.append(message)
                       if kind != QtMsgType.QtDebugMsg and kind != QtMsgType.QtInfoMsg else None)


def snapshot(view, name):
    target = os.environ.get("NOVA_SNAPSHOT_DIR") or BUILD
    view.grabWindow().save(str(pathlib.Path(target, f"session-{name}")))


class SessionSmoke(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temporary = tempfile.TemporaryDirectory(prefix="nova-session-")
        cls.prefix = pathlib.Path(cls.temporary.name)
        subprocess.run(["cmake", "--install", str(BUILD), "--prefix", str(cls.prefix)],
                       check=True, capture_output=True)
        cls.share = cls.prefix / "share"

    @classmethod
    def tearDownClass(cls):
        cls.temporary.cleanup()

    def setUp(self):
        WARNINGS.clear()

    def test_packages_are_valid_kpackages(self):
        lnf = self.share / "plasma/look-and-feel/org.knova.novashell"
        meta = json.loads((lnf / "metadata.json").read_text())
        self.assertEqual(meta["KPackageStructure"], "Plasma/LookAndFeel")
        self.assertEqual(meta["KPlugin"]["Id"], lnf.name)
        self.assertGreaterEqual(int(meta["X-Plasma-APIVersion"]), 2)
        for name in ("Splash.qml", "theme/qmldir", "images/nova-mark.svg",
                     "images/nova-light.jpg", "images/nova-dark.jpg"):
            self.assertTrue((lnf / "contents/splash" / name).is_file(), name)
        wallpaper = self.share / "wallpapers/NovaShell"
        self.assertEqual(json.loads((wallpaper / "metadata.json").read_text())["KPlugin"]["Id"], "NovaShell")
        for folder in ("images", "images_dark"):
            self.assertTrue((wallpaper / "contents" / folder / "3840x2160.jpg").is_file(), folder)

    def test_splash_runs_every_stage_without_warnings(self):
        splash = self.share / "plasma/look-and-feel/org.knova.novashell/contents/splash/Splash.qml"
        for scheme in ("light", "dark"):
            with self.subTest(scheme=scheme):
                WARNINGS.clear()
                view = QQuickView()
                view.setResizeMode(QQuickView.SizeRootObjectToView)
                view.resize(1280, 720)
                # Mismo singleton Theme que Splash.qml (importación de directorio).
                wrapper = splash.with_name(f"Preview-{scheme}.qml")
                wrapper.write_text('import QtQuick\nimport "theme"\n'
                                   f'Splash {{ Component.onCompleted: Theme.mode = "{scheme}" }}\n')
                view.setSource(QUrl.fromLocalFile(str(wrapper)))
                self.assertEqual(view.status(), QQuickView.Ready, [e.toString() for e in view.errors()])
                root = view.rootObject()
                view.show()
                # ksplashqml: etapa inicial 1 y avance cada 200 ms hasta cerrar.
                for stage in range(1, 6):
                    root.setProperty("stage", stage)
                    QTest.qWait(60)
                    expected = max(0.0, min(1.0, (stage - 1) / 4))
                    self.assertAlmostEqual(root.property("progress"), expected)
                    if stage == 3:
                        QTest.qWait(400)
                        snapshot(view, f"splash-{scheme}.png")
                view.close()
                self.assertEqual(WARNINGS, [], WARNINGS)


if __name__ == "__main__":
    if BUILD is None:
        sys.exit("uso: session_smoke.py <directorio-de-build>")
    unittest.main()
