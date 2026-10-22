# SPDX-License-Identifier: GPL-3.0-or-later
"""Reversible native look, Dolphin, KWin and session preferences through official KDE tools."""
import argparse
from contextlib import contextmanager
import fcntl
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

# Only these keys can be changed; journal content never supplies command paths.
# Value: (file, groups, key); several groups address nested KConfig groups.
KEYS = {
    "apps.motion": ("kdeglobals", "KDE", "AnimationDurationFactor"),
    "windows.motion": ("kwinrc", "KDE", "AnimationDurationFactor"),
    "windows.scale": ("kwinrc", "Plugins", "scaleEnabled"),
    "windows.fade": ("kwinrc", "Plugins", "fadeEnabled"),
    "windows.squash": ("kwinrc", "Plugins", "squashEnabled"),
    "windows.lamp": ("kwinrc", "Plugins", "magiclampEnabled"),
    "windows.inScale": ("kwinrc", "Effect-scale", "InScale"),
    "windows.outScale": ("kwinrc", "Effect-scale", "OutScale"),
    "windows.duration": ("kwinrc", "Effect-scale", "Duration"),
    # Stock KWin effects (enabled by default upstream; a user may have turned
    # them off): blur backs the glass, the rest are short spatial transitions.
    "windows.blur": ("kwinrc", "Plugins", "blurEnabled"),
    "windows.maximize": ("kwinrc", "Plugins", "maximizeEnabled"),
    "windows.desktops": ("kwinrc", "Plugins", "slideEnabled"),
    "windows.popups": ("kwinrc", "Plugins", "fadingpopupsEnabled"),
    "files.icons": ("dolphinrc", "IconsMode", "IconSize"),
    "files.details": ("dolphinrc", "DetailsMode", "IconSize"),
    "files.compact": ("dolphinrc", "CompactMode", "IconSize"),
    # Session: splash (ksplashqml reads [KSplash] Theme) and lock screen
    # wallpaper (kscreenlocker: [Greeter][Wallpaper][<plugin>][General] Image).
    "session.splash": ("ksplashrc", "KSplash", "Theme"),
    "session.lockPlugin": ("kscreenlockerrc", "Greeter", "WallpaperPlugin"),
    "session.lockImage": ("kscreenlockerrc", ("Greeter", "Wallpaper", "org.kde.image", "General"), "Image"),
    # Look: NovaGlass icons and palette with the neutral Liquid Glass accent.
    # A custom or wallpaper accent would tint the palette, so both are cleared
    # before the palette is applied (plasma-apply-colorscheme folds
    # [General] AccentColor in). The palette stays last: restore puts the
    # accent back first and then re-applies the previous palette.
    "look.icons": ("kdeglobals", "Icons", "Theme"),
    "look.accent": ("kdeglobals", "General", "AccentColor"),
    "look.accentWallpaper": ("kdeglobals", "General", "accentColorFromWallpaper"),
    "look.colors": ("kdeglobals", "General", "ColorScheme"),
}
LOOK_KEYS = [key for key in KEYS if key.startswith("look.")]
# Keys known to older journal versions; newer keys were never touched by them.
KEYS_V2 = [key for key in KEYS if not key.startswith("look.") and key not in
           ("windows.blur", "windows.maximize", "windows.desktops", "windows.popups")]
KEYS_V1 = [key for key in KEYS_V2 if not key.startswith("session.")]
JOURNAL_VERSION = 3
# Plasma's default palette (colorssettings.kcfg) when the key was absent.
DEFAULT_SCHEME = "BreezeLight"
SCHEMES = {False: "NovaGlassLight", True: "NovaGlassDark"}
ICON_THEMES = {False: "NovaGlass", True: "NovaGlass-dark"}
# plasma-changeicons lives in libexec, whose location depends on the distro.
LIBEXEC_DIRS = ("/usr/libexec", "/usr/lib/libexec", "/usr/lib64/libexec",
                "/usr/lib/x86_64-linux-gnu/libexec", "/usr/lib/aarch64-linux-gnu/libexec")
SPLASH_ID = "org.knova.novashell"
VALUE_LIMIT = 1024


def data_dir():
    return Path(os.environ.get("XDG_DATA_HOME") or Path.home() / ".local/share")


def wallpaper_url(data):
    return (Path(data) / "wallpapers/NovaShell").as_uri()


def profile(name, data=None, dark=False):
    if name not in ("balanced", "glass", "reduced"):
        raise ValueError("perfil desconocido")
    reduced = name == "reduced"
    motion = "false" if reduced else "true"
    return {"apps.motion": "0" if reduced else "0.75", "windows.motion": "0" if reduced else "0.75",
        "windows.scale": "false" if reduced else "true", "windows.fade": "false",
        "windows.squash": "true" if name == "balanced" else "false",
        "windows.lamp": "true" if name == "glass" else "false",
        "windows.inScale": "0.96", "windows.outScale": "0.96", "windows.duration": "0",
        "windows.blur": "true", "windows.maximize": motion, "windows.desktops": motion,
        "windows.popups": motion,
        "files.icons": "64", "files.details": "24", "files.compact": "32",
        "session.splash": SPLASH_ID, "session.lockPlugin": "org.kde.image",
        "session.lockImage": wallpaper_url(data or data_dir()),
        "look.icons": ICON_THEMES[dark], "look.accent": None, "look.accentWallpaper": "false",
        "look.colors": SCHEMES[dark]}


def is_dark(window_background):
    """Relative luminance of KConfig's "r,g,b" [Colors:Window] BackgroundNormal."""
    try:
        channels = [int(part) / 255 for part in (window_background or "").split(",")[:3]]
    except ValueError:
        return False
    if len(channels) != 3 or not all(0 <= channel <= 1 for channel in channels):
        return False
    return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2] < 0.5


class KConfigStore:
    def __init__(self, config):
        self.config = config
        self.reader = shutil.which("kreadconfig6")
        self.writer = shutil.which("kwriteconfig6")
        if not self.reader or not self.writer:
            raise RuntimeError("se requieren kreadconfig6 y kwriteconfig6 de KDE Frameworks 6")
        self.colors = shutil.which("plasma-apply-colorscheme")
        self.icons = next((str(Path(directory) / "plasma-changeicons") for directory in LIBEXEC_DIRS
                           if os.access(Path(directory) / "plasma-changeicons", os.X_OK)), None)

    def arguments(self, key):
        file, groups, entry = KEYS[key]
        groups = (groups,) if isinstance(groups, str) else groups
        arguments = ["--file", str(self.config / file)]
        for group in groups:
            arguments += ["--group", group]
        return arguments + ["--key", entry]

    @staticmethod
    def run(arguments):
        result = subprocess.run(arguments, capture_output=True, text=True, timeout=5, check=False)
        if result.returncode:
            raise RuntimeError("KConfig rechazó la operación; comprueba permisos o políticas inmutables")
        return result.stdout.rstrip("\n")

    def read(self, key):
        value = self.run([self.reader, *self.arguments(key), "--default", "__NOVA_ABSENT__"])
        if len(value.encode("utf-8")) > VALUE_LIMIT:
            raise RuntimeError("valor de configuración demasiado grande")
        return None if value == "__NOVA_ABSENT__" else value

    def window_background(self):
        return self.run([self.reader, "--file", str(self.config / "kdeglobals"), "--group", "Colors:Window",
                         "--key", "BackgroundNormal", "--default", ""])

    def write(self, key, value):
        if key == "look.colors":
            # The palette is many keys; only Plasma's tool writes them all and
            # notifies running apps. Absent before = Plasma's default palette.
            if not self.colors:
                raise RuntimeError("falta plasma-apply-colorscheme de Plasma")
            self.run([self.colors, "--", value or DEFAULT_SCHEME])
            if value is None:
                self.run([self.writer, *self.arguments(key), "--delete"])
            if self.read(key) != value:
                raise RuntimeError("Plasma no aplicó la paleta solicitada")
            return
        if key == "look.icons" and self.icons:
            # Reloads icons in running apps (KIconTheme::reconfigure).
            self.run([self.icons, "--", value or "breeze"])
        arguments = [self.writer, *self.arguments(key), "--notify"]
        arguments += ["--delete"] if value is None else ["--", value]
        self.run(arguments)
        if self.read(key) != value:
            raise RuntimeError("KConfig no conservó el valor solicitado")


class NativeProfile:
    def __init__(self, store, state, data=None):
        self.store, self.state, self.data = store, state, data

    @contextmanager
    def locked(self):
        self.state.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
        descriptor = os.open(str(self.state) + ".lock", os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600)
        with os.fdopen(descriptor, "w") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            yield

    def load(self):
        if self.state.is_symlink():
            raise ValueError("el registro no puede ser un enlace simbólico")
        if not self.state.exists():
            return None
        if self.state.stat().st_size > 65536:
            raise ValueError("registro demasiado grande")
        data = json.loads(self.state.read_text())
        if not isinstance(data, dict) or data.get("version") not in (1, 2, JOURNAL_VERSION):
            raise ValueError("registro no compatible")
        if data["version"] != JOURNAL_VERSION:
            data = self.upgrade(data)
        if data.get("phase", "active") not in ("active", "applying"):
            raise ValueError("fase del registro inválida")
        groups = ["before", "applied"] + (["rollback"] if data.get("phase") == "applying" else [])
        for group in groups:
            values = data.get(group)
            if not isinstance(values, dict) or set(values) != set(KEYS):
                raise ValueError("claves del registro inválidas")
            if any(value is not None and (not isinstance(value, str) or len(value.encode("utf-8")) > VALUE_LIMIT) for value in values.values()):
                raise ValueError("valores del registro inválidos")
        if data.get("profile") not in ("balanced", "glass", "reduced"):
            raise ValueError("perfil del registro inválido")
        return data

    @staticmethod
    def upgrade(data):
        # Older versions never wrote newer keys: before == applied == None
        # makes restore leave whatever the user has there untouched.
        known = KEYS_V1 if data["version"] == 1 else KEYS_V2
        for group in ("before", "applied", "rollback"):
            values = data.get(group)
            if isinstance(values, dict) and set(values) == set(known):
                values.update({key: None for key in KEYS if key not in known})
        data["version"] = JOURNAL_VERSION
        return data

    def save(self, data):
        self.state.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
        with tempfile.NamedTemporaryFile(mode="w", dir=self.state.parent, delete=False) as temporary:
            path = Path(temporary.name)
            try:
                os.chmod(path, 0o600)
                json.dump(data, temporary, ensure_ascii=False)
                temporary.flush()
                os.fsync(temporary.fileno())
                os.replace(path, self.state)
            finally:
                path.unlink(missing_ok=True)

    def snapshot(self):
        return {key: self.store.read(key) for key in KEYS}

    def desired(self, name, current, dark=None, look=True):
        if dark is None:
            reader = getattr(self.store, "window_background", None)
            dark = is_dark(reader()) if reader else False
        values = profile(name, self.data, dark)
        if not look:  # keep the user's icons, accent and palette untouched
            values.update({key: current[key] for key in LOOK_KEYS})
        return values

    def preview(self, name, dark=None, look=True):
        current = self.snapshot()
        desired = self.desired(name, current, dark, look)
        return {key: {"before": value, "after": desired[key]}
                for key, value in current.items() if value != desired[key]}

    def apply(self, name, dark=None, look=True):
        previous = self.load()
        current = self.snapshot()
        desired = self.desired(name, current, dark, look)
        if previous and previous.get("phase") == "applying":
            raise ValueError("la aplicación anterior se interrumpió; restaura primero")
        # Only keys the active profile owns matter; the rest belong to the user.
        owned = [key for key in KEYS if previous and previous["before"][key] != previous["applied"][key]]
        if any(current[key] != previous["applied"][key] for key in owned):
            raise ValueError("hay cambios posteriores; restaura primero para preservarlos")
        before = {key: previous["before"][key] if key in owned else current[key] for key in KEYS}
        # Journal first: an interrupted application retains the original values.
        journal = {"version": JOURNAL_VERSION, "profile": name, "phase": "applying", "rollback": current,
                   "before": before, "applied": desired}
        self.save(journal)
        try:
            for key in KEYS:
                if current[key] != desired[key]:
                    self.store.write(key, desired[key])
            journal["phase"] = "active"
            del journal["rollback"]
            self.save(journal)
        except Exception:
            rollback_failed = False
            for key in KEYS:
                try:
                    if self.store.read(key) == desired[key] and current[key] != desired[key]:
                        self.store.write(key, current[key])
                except Exception:
                    rollback_failed = True
            if not rollback_failed:
                if previous:
                    self.save(previous)
                else:
                    self.state.unlink(missing_ok=True)
            raise
        return {"profile": name, "changed": sum(current[key] != desired[key] for key in KEYS)}

    def restore(self):
        journal = self.load()
        if not journal:
            return {"restored": [], "preserved": []}
        restored, preserved = [], []
        for key in KEYS:
            current = self.store.read(key)
            if current == journal["before"][key]:
                continue
            if journal.get("phase") == "active" and journal["before"][key] == journal["applied"][key]:
                continue  # el perfil nunca cambió esta clave: lo actual es del usuario
            owned = [journal["applied"][key]]
            if journal.get("phase") == "applying":
                owned.append(journal["rollback"][key])
            if current in owned:
                self.store.write(key, journal["before"][key])
                restored.append(key)
            else:
                preserved.append(key)
        self.state.unlink()
        return {"restored": restored, "preserved": preserved}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("preview", "apply", "restore", "status"))
    parser.add_argument("profile", choices=("balanced", "glass", "reduced"), nargs="?", default="balanced")
    parser.add_argument("--data-dir", help="prefijo share/ donde novactl instaló los paquetes de sesión")
    parser.add_argument("--appearance", choices=("auto", "light", "dark"), default="auto",
                        help="variante de iconos y paleta; auto sigue la paleta actual")
    parser.add_argument("--keep-look", action="store_true",
                        help="no cambiar iconos, acento ni paleta")
    args = parser.parse_args()
    if os.geteuid() == 0:
        parser.exit(1, "No ejecutes el perfil como root.\n")
    config = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")
    state = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state") / "novashell/desktop-profile.json"
    try:
        if not config.is_absolute() or not state.is_absolute():
            raise ValueError("las rutas XDG deben ser absolutas")
        data = Path(args.data_dir) if args.data_dir else data_dir()
        if not data.is_absolute():
            raise ValueError("el directorio de datos debe ser absoluto")
        dark = None if args.appearance == "auto" else args.appearance == "dark"
        look = not args.keep_look
        if args.action == "apply":
            required = [data / "plasma/look-and-feel" / SPLASH_ID / "metadata.json",
                        data / "wallpapers/NovaShell/metadata.json"]
            if look:
                required += [data / "icons" / theme / "index.theme" for theme in ICON_THEMES.values()]
                required += [data / "color-schemes" / f"{scheme}.colors" for scheme in SCHEMES.values()]
            missing = [str(path) for path in required if not path.is_file()]
            if missing:
                raise ValueError("faltan los paquetes de sesión; ejecuta primero novactl install")
        controller = NativeProfile(KConfigStore(config), state, data)
        with controller.locked():
            result = controller.preview(args.profile, dark, look) if args.action == "preview" else (
                controller.apply(args.profile, dark, look) if args.action == "apply" else (
                controller.restore() if args.action == "restore" else controller.load()))
        print(json.dumps(result, ensure_ascii=False, indent=2))
        if args.action in ("apply", "restore"):
            bus = shutil.which("qdbus6") or shutil.which("qdbus")
            if bus:
                try:
                    reply = subprocess.run([bus, "org.kde.KWin", "/KWin", "reconfigure"],
                                           capture_output=True, timeout=5, check=False)
                    reloaded = reply.returncode == 0
                except (OSError, subprocess.SubprocessError):
                    reloaded = False
                if not reloaded:
                    print("KWin no recargó: aplica los efectos desde Preferencias del sistema.")
            else:
                print("Recarga los efectos desde Preferencias del sistema o al iniciar sesión.")
            print("Dolphin conserva sus ventanas abiertas; los tamaños se aplican al abrir una vista nueva.")
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        parser.exit(1, f"Perfil no completado: {error}\n")


if __name__ == "__main__":
    main()
