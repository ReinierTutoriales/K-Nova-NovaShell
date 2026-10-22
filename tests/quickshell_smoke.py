# SPDX-License-Identifier: GPL-3.0-or-later
"""Exercise the actual Quickshell services and daemon together, headlessly."""
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    if os.getuid() == 0:
        print("SKIP: run the daemon as an unprivileged user")
        return 77
    quickshell, daemon = map(str, sys.argv[1:3])
    with tempfile.TemporaryDirectory(prefix="nova-runtime-") as temporary:
        directory = Path(temporary)
        (directory / "nova").symlink_to(ROOT / "shell/nova", target_is_directory=True)
        (directory / "shell.qml").write_text('''//@ pragma UseQApplication
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import qs.nova.services
import qs.nova.desktop
import qs.nova.theme
ShellRoot {
    id: root
    property int attempts: 0
    property int phase: 0
    FloatingWindow {
        visible: true
        implicitWidth: 840
        implicitHeight: 680
        Loader { id: content; anchors.fill: parent; sourceComponent: launcher }
    }
    Component { id: launcher; LauncherView { applications: Platform.applications; iconResolver: name => Platform.iconUrl(name) } }
    Component { id: controls; ControlCenterView { backend: Platform.desktop } }
    Component { id: preferences; SettingsView { values: Platform.preferences.values; connected: Platform.connected } }
    Component { id: welcome; WelcomeView {
        values: Platform.preferences.values; connected: Platform.connected
        onPatchRequested: patch => Platform.preferences.patch(patch)
        onFinished: Platform.preferences.patch({welcomeCompleted: true})
    } }
    Timer {
        running: true
        repeat: true
        interval: 150
        onTriggered: {
            ++root.attempts;
            if (root.attempts > 100) { console.error("NOVA_RUNTIME_TIMEOUT"); Qt.quit(); return; }
            if (!Platform.connected || !Platform.preferences.values.mode || Platform.applicationsLoading) return;
            // Regresiones: el catálogo debe pedirse al conectar y las
            // preferencias deben llegar a Theme (Quickshell.env da null).
            if (root.phase === 0 && Platform._catalogGeneration === 0) { console.error("NOVA_CATALOG_NOT_REQUESTED"); Qt.quit(); return; }
            if (root.phase === 0 && Theme.mode !== Platform.preferences.values.mode) { console.error("NOVA_PREFERENCES_NOT_APPLIED " + Theme.mode); Qt.quit(); return; }
            if (root.phase === 0) content.sourceComponent = controls;
            else if (root.phase === 1) content.sourceComponent = preferences;
            else if (root.phase === 2) {
                // Bienvenida: pendiente en un perfil nuevo; recorrer y terminar la guarda.
                if (Platform.preferences.values.welcomeCompleted !== false) { console.error("NOVA_WELCOME_NOT_PENDING"); Qt.quit(); return; }
                content.sourceComponent = welcome;
                for (let page = 0; page <= content.item.lastPage; ++page) content.item.next();
            } else if (root.phase < 10 && Platform.preferences.values.welcomeCompleted !== true) { return; }
            else if (Platform.preferences.values.welcomeCompleted !== true) { console.error("NOVA_WELCOME_NOT_SAVED"); Qt.quit(); return; }
            else { console.log("NOVA_RUNTIME_OK"); Qt.quit(); }
            ++root.phase;
        }
    }
}
''')
        environment = dict(os.environ, QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software",
                           QT_QUICK_CONTROLS_STYLE="Basic", XDG_RUNTIME_DIR=temporary,
                           XDG_CONFIG_HOME=str(directory / "config"), QS_DISABLE_CRASH_HANDLER="1")
        process = subprocess.Popen([daemon, "--socket", str(directory / "novashell/platform.sock")],
                                   env=environment, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        try:
            result = subprocess.run([quickshell, "-p", str(directory / "shell.qml")], env=environment,
                                    capture_output=True, text=True, timeout=30)
            output = result.stdout + result.stderr
            errors = re.findall(r".*(?:ReferenceError|TypeError|Cannot assign|is not a type|is not installed|Binding loop|Failed to load configuration|NOVA_RUNTIME_TIMEOUT|NOVA_CATALOG_NOT_REQUESTED|NOVA_PREFERENCES_NOT_APPLIED|NOVA_WELCOME_[A-Z_]*|Duplicate property).*", output)
            if result.returncode or "NOVA_RUNTIME_OK" not in output or errors:
                raise RuntimeError(output)
            print("Actual Quickshell + daemon + native services + desktop views: OK")
        finally:
            process.terminate()
            try:
                process.communicate(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.communicate()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
