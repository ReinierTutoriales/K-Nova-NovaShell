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



def type_text(window, text):
    for character in text:
        QTest.keyClick(window, getattr(Qt.Key, "Key_" + character.upper()))

class DesktopSmoke(unittest.TestCase):
    def test_progress_stops_when_hidden_and_respects_reduced_motion(self):
        with tempfile.TemporaryDirectory(prefix="nova-progress-") as temporary:
            Path(temporary, "qs").symlink_to(ROOT / "shell", target_is_directory=True)
            WARNINGS.clear()
            engine = QQmlApplicationEngine()
            engine.addImportPath(temporary)
            engine.loadData(b'''import QtQuick
import qs.nova.theme
import qs.nova.desktop
Window {
    width: 840; height: 680; visible: true
    property bool reduced: false
    onReducedChanged: Theme.reduceMotion = reduced
    Component.onCompleted: Theme.reduceMotion = reduced
    property alias loading: launcher.loading
    property alias progress: launcher.progress
    LauncherView { id: launcher; anchors.fill: parent }
}''', QUrl.fromLocalFile(str(ROOT / "tests/progress-harness.qml")))
            self.assertEqual(len(engine.rootObjects()), 1, "\n".join(WARNINGS))
            window = engine.rootObjects()[0]
            progress = find(window.contentItem(), "catalogProgress")
            self.assertFalse(progress.property("animating"))
            # Carga rápida (< progressDelay): la barra nunca llega a mostrarse.
            window.setProperty("loading", True)
            QTest.qWait(30)
            self.assertFalse(progress.property("visible"))
            self.assertFalse(progress.property("animating"))
            window.setProperty("loading", False)
            QTest.qWait(400)
            self.assertFalse(progress.property("visible"))
            # Carga larga: aparece tras el retardo y el barrido corre.
            window.setProperty("loading", True)
            QTest.qWait(400)
            self.assertTrue(progress.property("visible"))
            self.assertTrue(progress.property("indeterminate"))
            self.assertTrue(progress.property("animating"))
            window.setProperty("progress", 0.5)
            APP.processEvents()
            self.assertFalse(progress.property("indeterminate"))
            self.assertFalse(progress.property("animating"))
            self.assertEqual(progress.property("position"), 0.5)
            window.setProperty("progress", 2)
            APP.processEvents()
            self.assertEqual(progress.property("position"), 1)
            window.setProperty("progress", -1)
            window.setProperty("reduced", True)
            APP.processEvents()
            self.assertTrue(progress.property("indeterminate"))
            self.assertFalse(progress.property("animating"))
            window.setProperty("reduced", False)
            window.setProperty("loading", False)
            APP.processEvents()
            self.assertFalse(progress.property("animating"))
            self.assertEqual(WARNINGS, [], "\n".join(WARNINGS))
            window.close()
            del engine
            APP.processEvents()

    def test_panel_transition_lifecycle_and_reduced_motion(self):
        with tempfile.TemporaryDirectory(prefix="nova-panel-lifecycle-") as temporary:
            Path(temporary, "qs").symlink_to(ROOT / "shell", target_is_directory=True)
            WARNINGS.clear()
            engine = QQmlApplicationEngine()
            engine.addImportPath(temporary)
            engine.loadData(b'''import QtQuick
import qs.nova.controls
import qs.nova.theme
import qs.nova.desktop
Window {
    id: window; width: 840; height: 680; visible: reveal.visible
    property alias opened: reveal.opened
    property bool reduced: false
    onReducedChanged: Theme.reduceMotion = reduced
    Component.onCompleted: Theme.reduceMotion = reduced
    property bool contentAlive: content.item !== null
    property bool animating: reveal.animating
    PanelTransition {
        id: reveal; anchors.fill: parent
        Loader {
            id: content; anchors.fill: parent; active: reveal.visible; focus: reveal.opened
            sourceComponent: Component { LauncherView {} }
            onLoaded: if (reveal.opened) item.focusInitial()
        }
    }
}''', QUrl.fromLocalFile(str(ROOT / "tests/panel-lifecycle-harness.qml")))
            self.assertEqual(len(engine.rootObjects()), 1, "\n".join(WARNINGS))
            window = engine.rootObjects()[0]
            self.assertFalse(window.property("contentAlive"))
            window.setProperty("opened", True)
            QTest.qWait(250)
            self.assertTrue(window.property("contentAlive"))
            search = find(window.contentItem(), "launcherSearch")
            self.assertTrue(search.hasActiveFocus())
            window.setProperty("opened", False)
            QTest.qWait(250)
            self.assertFalse(window.property("contentAlive"))
            self.assertFalse(window.property("animating"))
            window.setProperty("reduced", True)
            window.setProperty("opened", True)
            APP.processEvents()
            self.assertTrue(window.property("contentAlive"))
            self.assertFalse(window.property("animating"))
            window.setProperty("opened", False)
            APP.processEvents()
            self.assertFalse(window.property("contentAlive"))
            self.assertEqual(WARNINGS, [], "\n".join(WARNINGS))
            window.close()
            del engine
            APP.processEvents()

    def test_launcher_theme_and_keyboard(self):
        with tempfile.TemporaryDirectory(prefix="nova-launcher-theme-") as temporary:
            Path(temporary, "qs").symlink_to(ROOT / "shell", target_is_directory=True)
            WARNINGS.clear()
            engine = QQmlApplicationEngine()
            engine.addImportPath(temporary)
            engine.loadData(b'''import QtQuick
import qs.nova.theme
import qs.nova.desktop
Window {
    id: window; width: 840; height: 680; visible: true
    property string mode: "light"
    onModeChanged: Theme.mode = mode
    Component.onCompleted: Theme.mode = mode
    property string launched: ""
    color: Theme.color.surface
    LauncherView {
        anchors.fill: parent; anchors.margins: 16
        applications: [{id:"files.desktop",name:"Archivos",icon:"folder"}, {id:"terminal.desktop",name:"Terminal",icon:"terminal"},
            {id:"thunderbird.desktop",name:"Thunderbird",icon:"mail",genericName:"Correo"}, {id:"firefox.desktop",name:"Firefox",icon:"firefox",genericName:"Navegador web"}]
        onLaunchRequested: id => window.launched = id
    }
}''', QUrl.fromLocalFile(str(ROOT / "tests/launcher-theme-harness.qml")))
            self.assertEqual(len(engine.rootObjects()), 1, "\n".join(WARNINGS))
            window = engine.rootObjects()[0]
            search = find(window.contentItem(), "launcherSearch")
            grid = find(window.contentItem(), "launcherGrid")
            background = search.property("background")
            for mode, expected, foreground in [("dark", "#1c1d21", "#f5f6fa"), ("light", "#f4f5f8", "#17191e")]:
                window.setProperty("mode", mode)
                QTest.qWait(30)
                self.assertEqual(background.property("color").name(), expected)
                self.assertEqual(search.property("color").name(), foreground)
                self.assertGreater(background.property("radius"), 0)
                (ROOT / "build").mkdir(exist_ok=True)
                self.assertTrue(window.grabWindow().save(str(ROOT / "build" / f"desktop-launcher-{mode}.png")))
            search.setProperty("text", "terminal")
            search.forceActiveFocus()
            QTest.keyClick(window, Qt.Key.Key_Down)
            self.assertTrue(grid.hasActiveFocus())
            QTest.keyClick(window, Qt.Key.Key_Enter)
            self.assertEqual(window.property("launched"), "terminal.desktop")
            QTest.keyClick(window, Qt.Key.Key_Up)
            self.assertTrue(search.hasActiveFocus())
            # Relevancia: Intro abre el mejor resultado aunque haya varios.
            search.setProperty("text", "")
            search.forceActiveFocus()
            type_text(window, "fi")
            QTest.keyClick(window, Qt.Key.Key_Return)
            self.assertEqual(window.property("launched"), "firefox.desktop")
            # Nombre genérico, Esc borra la búsqueda sin cerrar.
            search.setProperty("text", "correo")
            QTest.keyClick(window, Qt.Key.Key_Return)
            self.assertEqual(window.property("launched"), "thunderbird.desktop")
            QTest.keyClick(window, Qt.Key.Key_Escape)
            self.assertEqual(search.property("text"), "")
            # Escribir con la rejilla enfocada vuelve a la búsqueda.
            QTest.keyClick(window, Qt.Key.Key_Down)
            self.assertTrue(grid.hasActiveFocus())
            type_text(window, "ter")
            self.assertTrue(search.hasActiveFocus())
            self.assertEqual(search.property("text"), "ter")
            search.setProperty("text", "no-results")
            window.setProperty("launched", "")
            QTest.keyClick(window, Qt.Key.Key_Return)
            self.assertEqual(window.property("launched"), "")
            self.assertEqual(WARNINGS, [], "\n".join(WARNINGS))
            window.close()
            del engine
            APP.processEvents()

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
