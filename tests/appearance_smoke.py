#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Load real portable QML and render every SVG with Qt; no Quickshell stubs."""
import os
os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
os.environ.setdefault("QT_QUICK_BACKEND", "software")
os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")

import pathlib
import subprocess
import tempfile
import unittest
from PySide6.QtCore import Qt, QUrl, qInstallMessageHandler, QtMsgType
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuick import QQuickWindow
from PySide6.QtSvg import QSvgRenderer
from PySide6.QtTest import QTest

ROOT = pathlib.Path(__file__).resolve().parent.parent
APP = QGuiApplication.instance() or QGuiApplication([])
WARNINGS = []


def log_message(kind, _context, message):
    if kind in (QtMsgType.QtWarningMsg, QtMsgType.QtCriticalMsg, QtMsgType.QtFatalMsg):
        WARNINGS.append(message)


qInstallMessageHandler(log_message)


def visual_item(item, name):
    if item.objectName() == name:
        return item
    for child in item.childItems():
        found = visual_item(child, name)
        if found is not None:
            return found
    return None


def visual_items(item):
    yield item
    for child in item.childItems():
        yield from visual_items(child)


class AppearanceSmoke(unittest.TestCase):
    def setUp(self):
        WARNINGS.clear()

    def test_portable_qml_modes_and_resource_loading(self):
        with tempfile.TemporaryDirectory(prefix="nova-qml-") as directory:
            pathlib.Path(directory, "qs").symlink_to(ROOT / "shell", target_is_directory=True)
            engine = QQmlApplicationEngine()
            engine.addImportPath(directory)
            engine.loadData(b"""
import QtQuick
import qs.nova.theme
import qs.nova.preview
AppearancePreview {
    property QtObject themeObject: Theme
    visible: true
}
""", QUrl.fromLocalFile(str(ROOT / "tests/appearance-harness.qml")))
            self.assertEqual(len(engine.rootObjects()), 1, "\n".join(WARNINGS))
            window = engine.rootObjects()[0]
            self.assertIsInstance(window, QQuickWindow)
            theme = window.property("themeObject")
            QTest.qWait(30)
            self.assertEqual(
                [item.property("text") for item in visual_items(window.contentItem())
                 if item.property("truncated") is True], [])
            # Exercise the real button through keyboard focus, not only setters.
            button = visual_item(window.contentItem(), "appearance-mode-dark")
            self.assertIsNotNone(button)
            button.forceActiveFocus()
            QTest.keyClick(window, Qt.Key.Key_Space)
            self.assertEqual(theme.property("effectiveMode"), "dark")
            QTest.keyClick(window, Qt.Key.Key_Space)
            self.assertEqual(theme.property("effectiveMode"), "dark")
            for mode in ("light", "dark"):
                theme.setProperty("mode", mode)
                for material in ("liquid", "frosted", "solid"):
                    theme.setProperty("material", material)
                    for icons in ("default", "dark", "clear", "tinted"):
                        theme.setProperty("iconMode", icons)
                        QTest.qWait(15)
                        self.assertGreaterEqual(theme.property("surfaceAlpha"), 0.88)
                theme.setProperty("material", "frosted")
                theme.setProperty("iconMode", "default")
                QTest.qWait(15)
                image = window.grabWindow()
                self.assertFalse(image.isNull(), mode)
                output = ROOT / "build"
                output.mkdir(exist_ok=True)
                self.assertTrue(image.save(str(output / ("appearance-" + mode + ".png"))))
            toggle = visual_item(window.contentItem(), "appearance-reduce-transparency")
            toggle.forceActiveFocus()
            QTest.keyClick(window, Qt.Key.Key_Space)
            self.assertTrue(theme.property("reduceTransparency"))
            QTest.keyClick(window, Qt.Key.Key_Space)
            self.assertFalse(theme.property("reduceTransparency"))
            for option in ("reduceTransparency", "highContrast"):
                theme.setProperty(option, True)
                self.assertEqual(theme.property("surfaceAlpha"), 1)
                theme.setProperty(option, False)
            theme.setProperty("mode", "invalid")
            theme.setProperty("material", "invalid")
            theme.setProperty("iconMode", "invalid")
            self.assertEqual(theme.property("effectiveMode"), "auto")
            self.assertEqual(theme.property("effectiveMaterial"), "liquid")
            self.assertEqual(theme.property("effectiveIconMode"), "default")
            window.setVisible(False)
            QTest.qWait(10)
            window.setVisible(True)
            QTest.qWait(10)
            window.close()
            engine.deleteLater()
            APP.processEvents()
            self.assertEqual(WARNINGS, [], "\n".join(WARNINGS))

    def test_qt_can_render_every_exported_svg(self):
        with tempfile.TemporaryDirectory(prefix="nova-svg-") as directory:
            subprocess.run(["node", str(ROOT / "tools/export-icons.mjs"), directory], check=True)
            paths = list(pathlib.Path(directory).rglob("*.svg"))
            self.assertGreater(len(paths), 100)
            for path in paths:
                renderer = QSvgRenderer(str(path))
                self.assertTrue(renderer.isValid(), str(path))
            self.assertEqual(WARNINGS, [], "\n".join(WARNINGS))


if __name__ == "__main__":
    unittest.main()
