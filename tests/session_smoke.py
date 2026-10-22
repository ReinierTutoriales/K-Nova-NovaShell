#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Carga las pantallas de sesión desde una instalación real (cmake --install).

Comprueba la estructura instalada y que el QML carga sin avisos, como lo harían
ksplashqml y sddm-greeter-qt6 (este último con objetos de contexto simulados
que reproducen la API de SDDM 0.21). Guarda capturas session-*.png en el build
(o NOVA_SNAPSHOT_DIR).

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
from PySide6.QtCore import (QAbstractListModel, QByteArray, QModelIndex, QObject, Qt, QUrl, QtMsgType,
                            Property, Signal, Slot, qInstallMessageHandler)
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


class ListModel(QAbstractListModel):
    """Modelo con los roles y propiedades de UserModel/SessionModel de SDDM."""
    def __init__(self, roles, rows, last=0):
        super().__init__()
        self._roles, self._rows, self._last = roles, rows, last

    def rowCount(self, parent=QModelIndex()):
        return 0 if parent.isValid() else len(self._rows)

    def roleNames(self):
        return {Qt.UserRole + 1 + i: QByteArray(name.encode()) for i, name in enumerate(self._roles)}

    def data(self, index, role):
        name = self._roles[role - Qt.UserRole - 1] if role > Qt.UserRole else None
        return self._rows[index.row()].get(name) if name and index.isValid() else None

    lastIndex = Property(int, lambda self: self._last, constant=True)
    count = Property(int, lambda self: len(self._rows), constant=True)
    containsAllUsers = Property(bool, lambda self: True, constant=True)
    disableAvatarsThreshold = Property(int, lambda self: 7, constant=True)


class Greeter(QObject):
    """sddm (GreeterProxy): login y energía; rechaza contraseñas distintas de 'nova'."""
    loginFailed = Signal()
    loginSucceeded = Signal()
    informationMessage = Signal(str)

    def __init__(self):
        super().__init__()
        self.calls = []

    @Slot(str, str, int)
    def login(self, user, password, session):
        self.calls.append(("login", user, password, session))
        (self.loginSucceeded if password == "nova" else self.loginFailed).emit()

    @Slot()
    def powerOff(self): self.calls.append(("powerOff",))

    @Slot()
    def reboot(self): self.calls.append(("reboot",))

    @Slot()
    def suspend(self): self.calls.append(("suspend",))

    hostName = Property(str, lambda self: "nova", constant=True)
    canPowerOff = Property(bool, lambda self: True, constant=True)
    canReboot = Property(bool, lambda self: True, constant=True)
    canSuspend = Property(bool, lambda self: True, constant=True)


class Layout(QObject):
    def __init__(self, short, long):
        super().__init__()
        self._short, self._long = short, long
    shortName = Property(str, lambda self: self._short, constant=True)
    longName = Property(str, lambda self: self._long, constant=True)


class Keyboard(QObject):
    currentLayoutChanged = Signal()

    def __init__(self):
        super().__init__()
        self._layouts, self._current = [Layout("es", "Español"), Layout("us", "English (US)")], 0

    def _set_current(self, value):
        self._current = value
        self.currentLayoutChanged.emit()

    capsLock = Property(bool, lambda self: False, constant=True)
    numLock = Property(bool, lambda self: False, constant=True)
    enabled = Property(bool, lambda self: True, constant=True)
    layouts = Property("QVariantList", lambda self: self._layouts, constant=True)
    currentLayout = Property(int, lambda self: self._current, _set_current, notify=currentLayoutChanged)


class Config(QObject):
    """config (ThemeConfig): valores de theme.conf como texto."""
    def __init__(self, values):
        super().__init__()
        self._values = values

    @Slot(str, result=str)
    def stringValue(self, key): return str(self._values.get(key, ""))

    @Slot(str, result=bool)
    def boolValue(self, key): return str(self._values.get(key, "")).lower() == "true"

    @Slot(str, result=int)
    def intValue(self, key): return int(self._values.get(key, 0) or 0)

    @Slot(str, result=float)
    def realValue(self, key): return float(self._values.get(key, 0) or 0)


USER_ROLES = ["name", "realName", "homeDir", "icon", "needsPassword"]
SESSION_ROLES = ["directory", "file", "type", "name", "exec", "comment"]


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

    def sddm_view(self, users, appearance="auto"):
        theme = self.share / "novashell/sddm/novashell"
        context = {
            "sddm": Greeter(), "keyboard": Keyboard(), "config": Config({"appearance": appearance}),
            "userModel": ListModel(USER_ROLES, users, 0 if users else -1),
            "sessionModel": ListModel(SESSION_ROLES, [{"name": "Plasma (Wayland)", "file": "plasma.desktop"},
                                                     {"name": "Plasma (X11)", "file": "plasmax11.desktop"}]),
        }
        view = QQuickView()
        view.setResizeMode(QQuickView.SizeRootObjectToView)
        view.resize(1280, 800)
        for name, value in context.items():
            view.rootContext().setContextProperty(name, value)
        view.rootContext().setContextProperty("primaryScreen", True)
        view.setSource(QUrl.fromLocalFile(str(theme / "Main.qml")))
        self.assertEqual(view.status(), QQuickView.Ready, [e.toString() for e in view.errors()])
        view.show()
        QTest.qWait(300)
        return view, context

    def test_sddm_theme_is_installed_for_qt6(self):
        theme = self.share / "novashell/sddm/novashell"
        metadata = (theme / "metadata.desktop").read_text()
        self.assertIn("QtVersion=6", metadata)
        self.assertIn("MainScript=Main.qml", metadata)
        self.assertIn("Theme-API=2.0", metadata)
        for name in ("Main.qml", "theme.conf", "preview.png", "theme/qmldir", "icons/IconCatalog.mjs",
                     "images/nova-light.jpg", "images/nova-dark.jpg", "LICENSE", "THIRD_PARTY_NOTICES.md"):
            self.assertTrue((theme / name).is_file(), name)

    def test_sddm_login_flow_and_power(self):
        mark = str(self.share / "plasma/look-and-feel/org.knova.novashell/contents/splash/images/nova-mark.svg")
        users = [{"name": "reinier", "realName": "Reinier", "icon": "file://" + mark, "needsPassword": True},
                 {"name": "invitado", "realName": "", "icon": "", "needsPassword": True}]
        for scheme in ("light", "dark"):
            with self.subTest(scheme=scheme):
                WARNINGS.clear()
                view, context = self.sddm_view(users, scheme)
                card = view.rootObject().findChild(QObject, "loginCard")
                password = view.rootObject().findChild(QObject, "password")
                self.assertEqual(card.property("loginName"), "reinier")
                password.setProperty("text", "mal")
                card.submit()
                self.assertEqual(card.property("message"), "Contraseña incorrecta")
                self.assertEqual(password.property("text"), "")
                self.assertFalse(card.property("busy"))
                password.setProperty("text", "nova")
                QTest.qWait(400)
                snapshot(view, f"sddm-{scheme}.png")
                card.submit()
                self.assertEqual(context["sddm"].calls[-1], ("login", "reinier", "nova", 0))
                card.setProperty("userIndex", 1)
                QTest.qWait(50)
                self.assertEqual(card.property("loginName"), "invitado")
                view.close()
                self.assertEqual(WARNINGS, [], WARNINGS)

    def test_sddm_without_user_list_asks_for_name(self):
        view, context = self.sddm_view([])
        card = view.rootObject().findChild(QObject, "loginCard")
        self.assertTrue(card.property("manualUser"))
        card.submit()  # sin nombre no se intenta entrar
        self.assertEqual(context["sddm"].calls, [])
        view.close()
        self.assertEqual(WARNINGS, [], WARNINGS)


if __name__ == "__main__":
    if BUILD is None:
        sys.exit("uso: session_smoke.py <directorio-de-build>")
    unittest.main()
