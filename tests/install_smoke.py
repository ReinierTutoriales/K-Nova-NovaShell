#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Instalación real de extremo a extremo: `novactl install` y `uninstall`
en un HOME vacío. Compila en una carpeta propia e instala todo lo que
instalaría un usuario (daemon, shell, iconos, paquetes de sesión, tema SDDM
preparado, servicios). systemctl se sustituye por un registro de llamadas
porque el contenedor de pruebas no tiene sesión systemd de usuario.

Uso: install_smoke.py   (como usuario normal; novactl rechaza root)
"""
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
NOVACTL = ROOT / "tools/novactl"


def fake_tool(directory, name, body):
    path = directory / name
    path.write_text("#!/bin/sh\n" + body + "\n")
    path.chmod(path.stat().st_mode | stat.S_IXUSR)
    return path


# KConfig en memoria (archivo JSON): permite probar el perfil nativo que
# install aplica y uninstall restaura sin tocar la configuración real.
FAKE_KCONFIG = r"""
import json, sys
from pathlib import Path
store = Path(sys.argv[1]); mode = sys.argv[2]; args = sys.argv[3:]
data = json.loads(store.read_text()) if store.exists() else {}
if mode == "scheme":
    data["kdeglobals|General|ColorScheme"] = args[-1]
else:
    path, groups, key, value, delete = None, [], None, None, False
    i = 0
    while i < len(args):
        a = args[i]
        if a == "--file": path = Path(args[i + 1]).name; i += 2
        elif a == "--group": groups.append(args[i + 1]); i += 2
        elif a == "--key": key = args[i + 1]; i += 2
        elif a == "--default": value = args[i + 1]; i += 2
        elif a == "--delete": delete = True; i += 1
        elif a == "--notify": i += 1
        elif a == "--": value = args[i + 1]; i += 2
        else: raise SystemExit("argumento inesperado " + a)
    name = "|".join([path, *groups, key])
    if mode == "read":
        print(data.get(name, value)); raise SystemExit(0)
    if delete: data.pop(name, None)
    else: data[name] = value
store.write_text(json.dumps(data))
"""


def run(env, *arguments, check=True):
    result = subprocess.run([str(NOVACTL), *arguments], env=env, capture_output=True, text=True, timeout=1500)
    if check and result.returncode:
        raise AssertionError(f"novactl {' '.join(arguments)} falló:\n{result.stdout}\n{result.stderr}")
    return result


def leftovers(prefix):
    """Archivos o carpetas vacías de NovaShell que no deberían quedar."""
    found = []
    for path in prefix.rglob("*"):
        if path.is_dir() and not any(path.iterdir()):
            found.append(f"carpeta vacía {path}")
        elif path.is_file() or path.is_symlink():
            found.append(str(path))
    return found


def main():
    if os.geteuid() == 0:
        print("SKIP: novactl no se ejecuta como root")
        return 77
    with tempfile.TemporaryDirectory(prefix="nova-install-") as temporary:
        base = Path(temporary)
        home, tools = base / "home", base / "bin"
        home.mkdir()
        tools.mkdir()
        calls = base / "systemctl.log"
        fake_tool(tools, "systemctl", f'echo "$*" >> "{calls}"')
        quickshell = fake_tool(tools, "qs", 'echo "Quickshell: v0.3.2"')
        kconfig, kstore = base / "kconfig.py", base / "kconfig.json"
        kconfig.write_text(FAKE_KCONFIG)
        original = {"kdeglobals|General|ColorScheme": "BreezeDark", "kdeglobals|General|AccentColor": "61,174,233",
                    "kdeglobals|Colors:Window|BackgroundNormal": "32,33,36"}
        kstore.write_text(json.dumps(original))
        for name, mode in (("kreadconfig6", "read"), ("kwriteconfig6", "write"), ("plasma-apply-colorscheme", "scheme")):
            fake_tool(tools, name, f'exec "{sys.executable}" -I "{kconfig}" "{kstore}" {mode} "$@"')
        env = {
            "HOME": str(home), "PATH": f"{tools}:{os.environ['PATH']}", "LANG": "C.UTF-8",
            "NOVA_QS_BIN": str(quickshell), "NOVA_BUILD_DIR": str(base / "build"),
            "XDG_CONFIG_HOME": str(home / ".config"), "XDG_DATA_HOME": str(home / ".local/share"),
            "XDG_STATE_HOME": str(home / ".local/state"),
        }
        for key in ("CMAKE_PREFIX_PATH", "LD_LIBRARY_PATH", "Qt6_DIR", "QT_ROOT_DIR"):
            if key in os.environ:
                env[key] = os.environ[key]
        prefix = home / ".local"
        share = prefix / "share"

        run(env, "install")
        manifest = share / "novashell/install-manifest"
        entries = [Path(line) for line in manifest.read_text().splitlines() if line]
        missing = [str(path) for path in entries if not path.exists()]
        assert not missing, f"el manifiesto lista archivos inexistentes: {missing[:5]}"
        assert all(str(path).startswith(str(home)) for path in entries), "algo se instaló fuera de HOME"
        required = [
            prefix / "libexec/nova-platform",
            share / "plasma/look-and-feel/org.knova.novashell/contents/splash/Splash.qml",
            share / "plasma/look-and-feel/org.knova.novashell/contents/splash/theme/Theme.qml",
            share / "wallpapers/NovaShell/contents/images_dark/3840x2160.jpg",
            share / "novashell/sddm/novashell/metadata.desktop",
            share / "novashell/sddm/novashell/icons/IconCatalog.mjs",
            share / "color-schemes/NovaGlassDark.colors",
            share / "icons/NovaGlass/index.theme",
            home / ".config/quickshell/novashell/shell.qml",
            home / ".config/quickshell/novashell/nova/icons/nova-mark-light.svg",
        ]
        for path in required:
            assert path.exists(), f"falta {path}"
            assert path in entries or str(path).startswith(str(home / ".config/quickshell")), f"{path} no está en el manifiesto"
        for unit in ("nova-platform.service", "novashell.service"):
            text = (home / ".config/systemd/user" / unit).read_text()
            assert "@" not in text.replace("@.service", ""), f"{unit} sin sustituir: {text}"
            assert str(prefix / "libexec") in text or str(quickshell) in text, f"{unit} con rutas inesperadas"
        assert (share / "novashell/installed-version").read_text().strip() == (ROOT / "VERSION").read_text().strip()
        assert "daemon-reload" in calls.read_text()
        # Aspecto aplicado al instalar: sigue la paleta oscura actual y deja el acento neutro.
        applied = json.loads(kstore.read_text())
        assert applied["kdeglobals|General|ColorScheme"] == "NovaGlassDark", applied
        assert applied["kdeglobals|Icons|Theme"] == "NovaGlass-dark", applied
        assert "kdeglobals|General|AccentColor" not in applied, applied
        assert applied["ksplashrc|KSplash|Theme"] == "org.knova.novashell", applied
        assert applied["konsolerc|Desktop Entry|DefaultProfile"] == "NovaShell Oscuro.profile", applied
        assert (share / "konsole/NovaGlassTermDark.colorscheme").is_file()

        status = run(env, "login-theme", "status")
        assert "Tema preparado" in status.stdout, status.stdout
        assert "sudo" in run(env, "login-theme", "install").stdout

        settings = home / ".config/novashell/settings.json"
        settings.parent.mkdir(parents=True, exist_ok=True)
        settings.write_text('{"mode":"dark"}')
        run(env, "uninstall")
        assert settings.exists(), "uninstall sin --purge debe conservar los ajustes"
        assert json.loads(kstore.read_text()) == original, "uninstall debe restaurar la configuración de KDE"
        run(env, "install", "--no-profile")  # incremental: reutiliza la compilación
        assert json.loads(kstore.read_text()) == original, "--no-profile no debe tocar KDE"
        run(env, "uninstall", "--purge")
        assert not settings.parent.exists(), "--purge debe borrar los ajustes del daemon"
        remaining = leftovers(share) + leftovers(prefix / "libexec") if (prefix / "libexec").exists() else leftovers(share)
        assert not remaining, f"restos tras desinstalar: {remaining[:10]}"
        assert not (home / ".config/quickshell/novashell").exists()
        assert not list((home / ".config/systemd/user").glob("nova*.service"))
        print("novactl install/uninstall en HOME limpio: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
