# SPDX-License-Identifier: GPL-3.0-or-later
"""Render real desktop views with explicit data fixtures; no Quickshell stubs."""
import os
os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
os.environ.setdefault("QT_QUICK_BACKEND", "software")
os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")
from pathlib import Path
import tempfile
import unittest
from PySide6.QtCore import QUrl, Qt, QtMsgType, qInstallMessageHandler
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuick import QQuickWindow
from PySide6.QtTest import QTest

ROOT = Path(__file__).resolve().parents[1]
APP = QGuiApplication.instance() or QGuiApplication([])
WARNINGS = []
qInstallMessageHandler(lambda kind, context, message: WARNINGS.append(message)
                       if kind in (QtMsgType.QtWarningMsg, QtMsgType.QtCriticalMsg, QtMsgType.QtFatalMsg) else None)


def find(item, name):
    if item.objectName() == name:
        return item
    for child in item.childItems():
        result = find(child, name)
        if result is not None:
            return result
    return None


class DesktopSmoke(unittest.TestCase):
    def test_views_and_launcher_keyboard(self):
        cases = {
            "launcher": '''LauncherView { applications: [{id: "files.desktop", name: "Archivos", icon: "folder"}, {id: "terminal.desktop", name: "Terminal", icon: "terminal"}]; onLaunchRequested: id => window.launched = id }''',
            "preferences": '''SettingsView { connected: true; values: {"mode":"dark", "dockIconSize":56} }''',
            "overview": '''OverviewView { available: true; windows: [{id:"one",title:"Ventana real de prueba",appId:"demo",active:true}]; desktops:[{id:"desk",name:"Principal"}] }''',
            "notifications": '''NotificationView {}''',
            "clipboard": '''ClipboardView { enabledHistory: true; entries: ["Texto de prueba", "Otro texto"] }''',
            "widgets": '''WidgetsView {}''',
            "controls": '''ControlCenterView { backend: QtObject {
                property bool wifiEnabled: false; property bool wifiAvailable: false
                property bool bluetoothEnabled: false; property bool bluetoothAvailable: false
                property bool audioAvailable: false; property real volume: 0
                property var outputs: []; property bool batteryPresent: false; property real batteryPercent: 0
                property var networkDevices: []; property var bluetoothDevices: []; property var player: null
            } }'''
        }
        with tempfile.TemporaryDirectory(prefix="nova-desktop-ui-") as temporary:
            Path(temporary, "qs").symlink_to(ROOT / "shell", target_is_directory=True)
            for name, component in cases.items():
                with self.subTest(view=name):
                    WARNINGS.clear()
                    engine = QQmlApplicationEngine()
                    engine.addImportPath(temporary)
                    source = '''import QtQuick
import qs.nova.desktop
Window { id: window; width: 840; height: 680; visible: true; property string launched: ""
Loader { anchors.fill: parent; anchors.margins: 16; sourceComponent: Component { %s } }
}''' % component
                    engine.loadData(source.encode(), QUrl.fromLocalFile(str(ROOT / "tests/desktop-harness.qml")))
                    self.assertEqual(len(engine.rootObjects()), 1, "\n".join(WARNINGS))
                    window = engine.rootObjects()[0]
                    QTest.qWait(50)
                    if name == "launcher":
                        search = find(window.contentItem(), "launcherSearch")
                        self.assertIsNotNone(search)
                        search.setProperty("text", "terminal")
                        search.forceActiveFocus()
                        QTest.keyClick(window, Qt.Key.Key_Return)
                        self.assertEqual(window.property("launched"), "terminal.desktop")
                    image = window.grabWindow()
                    self.assertFalse(image.isNull())
                    (ROOT / "build").mkdir(exist_ok=True)
                    self.assertTrue(image.save(str(ROOT / "build" / f"desktop-{name}.png")))
                    self.assertEqual(WARNINGS, [], "\n".join(WARNINGS))
                    window.close()
                    del engine
                    APP.processEvents()


if __name__ == "__main__":
    unittest.main()
