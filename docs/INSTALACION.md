# Instalación paso a paso

Esta guía deja NovaShell funcionando en tu usuario y, si quieres, la pantalla
de inicio de sesión. Todo se instala en tu `$HOME` sin root; la única
excepción opcional es copiar el tema de inicio de sesión al sistema.

## 1. Requisitos

| Componente | Versión | Cómo comprobarlo |
| :--- | :--- | :--- |
| KDE Plasma en **Wayland** | 6.8 o posterior | `plasmashell --version` y `echo $XDG_SESSION_TYPE` (debe decir `wayland`) |
| Qt | 6.12.0 o posterior | `qtpaths6 --qt-version` |
| Quickshell | 0.3.2 o posterior, **compilado para tu misma versión de Qt** | `qs --version -v` |
| Compilación | CMake ≥ 3.21, Ninja, compilador C++20, Qt Core/Network/DBus, GLib/GIO ≥ 2.80, cabeceras de Wayland | `novactl doctor` |
| Perfil nativo (opcional) | `kreadconfig6`/`kwriteconfig6` (KConfig 6), Python 3 | — |
| Inicio de sesión (opcional) | SDDM 0.21+ con `sddm-greeter-qt6` | `command -v sddm-greeter-qt6` |

Las versiones mínimas están en `packaging/runtime.env`. Si tu distribución aún
no ofrece Plasma 6.8 y Qt 6.12, NovaShell no funcionará: `novactl doctor` lo dice.

### Paquetes de compilación

| Distribución | Orden |
| :--- | :--- |
| Arch / CachyOS | `sudo pacman -S --needed cmake ninja gcc pkgconf glib2 wayland qt6-base qt6-declarative qt6-svg qt6-imageformats` |
| Fedora | `sudo dnf install cmake ninja-build gcc-c++ pkgconf glib2-devel wayland-devel qt6-qtbase-devel qt6-qtdeclarative qt6-qtsvg` |
| Debian / Ubuntu | `sudo apt install cmake ninja-build g++ pkg-config libglib2.0-dev libwayland-dev qt6-base-dev libqt6svg6 qml6-module-qtquick-controls qml6-module-qtquick-layouts qml6-module-qtquick-window qml6-module-qtqml-workerscript` |

### Quickshell

Según la [guía oficial de Quickshell](https://quickshell.org/docs/v0.3.0/guide/install-setup):

| Distribución | Orden |
| :--- | :--- |
| Arch | `sudo pacman -S quickshell` |
| Fedora | `sudo dnf copr enable errornointernet/quickshell && sudo dnf install quickshell` |
| Debian testing/unstable | `sudo apt install quickshell` |
| Ubuntu | PPA `avengemedia/danklinux`: `sudo add-apt-repository ppa:avengemedia/danklinux && sudo apt install quickshell` |
| NixOS | paquete `quickshell` de Nixpkgs |
| Gentoo | overlay GURU, `gui-apps/quickshell` |

Quickshell debe estar compilado para la Qt exacta con la que se ejecuta. Tras
una actualización de Qt, si `novactl doctor` informa de versiones distintas,
reinstala Quickshell.

## 2. Obtener NovaShell

```sh
git clone --branch v0.3.0 https://github.com/ReinierTutoriales/K-Nova-NovaShell.git
cd K-Nova-NovaShell
```

`--branch` fija una versión publicada ([releases](https://github.com/ReinierTutoriales/K-Nova-NovaShell/releases)).
Sin él obtienes `main`, la versión en desarrollo.

## 3. Comprobar el entorno

```sh
./tools/novactl doctor
```

Cada línea es ✔ (bien), ! (aviso) o ✘ (bloqueante). Corrige todo lo marcado
con ✘ antes de seguir. El aviso del gestor de sesión solo afecta a la pantalla
de inicio de sesión (paso 7).

## 4. Instalar

```sh
./tools/novactl install
```

Compila en modo Release (sin las pruebas, para tardar menos), instala y
aplica el **aspecto nativo** (paso 6). Con `--no-profile` no toca la
configuración de KDE.

| Qué | Dónde |
| :--- | :--- |
| Daemon `nova-platform` | `~/.local/libexec/` |
| Shell QML | `~/.config/quickshell/novashell/` |
| Servicios de usuario | `~/.config/systemd/user/{nova-platform,novashell}.service` |
| Iconos NovaGlass y paletas de color | `~/.local/share/icons/`, `~/.local/share/color-schemes/` |
| Fondo NovaShell (claro/oscuro) | `~/.local/share/wallpapers/NovaShell/` |
| Splash (pantalla de carga) | `~/.local/share/plasma/look-and-feel/org.knova.novashell/` |
| Tema de inicio de sesión preparado | `~/.local/share/novashell/sddm/novashell/` |
| Lista de archivos instalados | `~/.local/share/novashell/install-manifest` |

No ejecutes `novactl` con `sudo`: lo rechaza. Deja el prefijo por defecto
(`~/.local`); KDE solo encuentra el splash y el fondo en tu carpeta de datos.

## 5. Arrancar

```sh
./tools/novactl start      # ahora
./tools/novactl enable     # también al iniciar sesión
```

La primera vez aparece la **bienvenida**: dos ajustes rápidos que se aplican
al momento. Puedes omitirla; se reabre en Ajustes → Escritorio. NovaShell
convive con el panel de Plasma y no cambia tu tema global (Plasma Style ni
decoraciones de ventana).

## 6. Aspecto nativo (automático, reversible)

`install` ya aplicó el perfil `balanced`: iconos y carpetas NovaGlass
monocromas, paleta NovaGlass clara u oscura según la que tenías (también la
usa la pantalla de bloqueo), acento Liquid Glass neutro, tamaños de Dolphin,
transiciones de KWin, splash y fondo de bloqueo. Para ajustarlo:

```sh
./tools/novactl desktop-profile status                   # qué hay aplicado
./tools/novactl desktop-profile apply glass              # Magic Lamp al minimizar
./tools/novactl desktop-profile apply reduced            # sin animaciones
./tools/novactl desktop-profile apply balanced --appearance dark   # forzar oscuro
./tools/novactl desktop-profile apply balanced --keep-look         # sin iconos ni paleta
./tools/novactl desktop-profile restore                  # deshace exactamente lo aplicado
```

Iconos y paleta cambian al momento; el splash y el fondo de bloqueo, en el
siguiente inicio de sesión o bloqueo. La interfaz de bloqueo sigue siendo la de Plasma por seguridad
([por qué](SESION.md#bloqueo)). El fondo también aparece en Preferencias del
sistema → Fondo de pantalla.

## 7. Pantalla de inicio de sesión (opcional)

Requiere **SDDM** con `sddm-greeter-qt6` y los módulos QML de efectos y
formas de Qt (en Debian/Ubuntu: `qml6-module-qtquick-effects` y
`qml6-module-qtquick-shapes`; en Arch y Fedora vienen con qt6-declarative).
Plasma Login Manager no admite temas ([detalles](SESION.md#inicio-de-sesión-sddm)).

```sh
./tools/novactl login-theme status     # gestor, tema instalado y tema efectivo
./tools/novactl login-theme preview    # vista previa en una ventana, sin root
./tools/novactl login-theme install    # imprime la orden con sudo
```

Revisa `packaging/sddm/install-theme.sh` y ejecuta la orden que imprime
`install` (es lo único de NovaShell que necesita root). Copia el tema a
`/usr/share/sddm/themes/novashell` y lo activa en
`/etc/sddm.conf.d/zz-novashell.conf`. Se verá al cerrar sesión o reiniciar.

Si tu gestor es Plasma Login Manager y quieres este tema, cambia a SDDM
(y vuelve cuando quieras invirtiendo la orden):

```sh
sudo systemctl disable plasmalogin && sudo systemctl enable sddm   # cambiar
sudo systemctl disable sddm && sudo systemctl enable plasmalogin   # volver
```

Ajustes del tema en `/usr/share/sddm/themes/novashell/theme.conf`:
`appearance` (`auto|light|dark`), `accent` (vacío = Liquid Glass; `#rrggbb`
para un acento de color), `transparency` (`0`–`1`), `background` (ruta absoluta a una imagen) y
`reduceMotion` (`true|false`).

## 8. Atajos de teclado

En Preferencias del sistema → Teclado → Atajos → Añadir orden:

| Acción | Orden |
| :--- | :--- |
| Lanzador | `qs ipc call novashell toggle launcher` |
| Centro de control | `qs ipc call novashell toggle controls` |
| Ventanas | `qs ipc call novashell toggle overview` |
| Portapapeles | `qs ipc call novashell toggle clipboard` |
| Cerrar panel | `qs ipc call novashell close` |

## 9. Actualizar

```sh
git fetch --tags
git checkout vX.Y.Z          # la versión nueva
./tools/novactl install
./tools/novactl restart
```

Si usas el tema de inicio de sesión, vuelve a ejecutar la orden de
`novactl login-theme install` para copiar la versión nueva.

## 10. Desinstalar

```sh
sudo packaging/sddm/install-theme.sh uninstall   # solo si instalaste el tema SDDM
./tools/novactl uninstall                         # restaura el perfil y borra lo instalado
./tools/novactl uninstall --purge                 # además borra tus ajustes
```

`uninstall` borra solo lo que figura en la lista de archivos instalados y las
carpetas que quedan vacías. Tus ajustes (`~/.config/novashell`) se conservan
salvo con `--purge`.

## Solución de problemas

| Síntoma | Causa probable | Qué hacer |
| :--- | :--- | :--- |
| `novactl install` falla al configurar | Faltan paquetes o Qt es anterior a 6.12 | `novactl doctor`; instala los paquetes del paso 1 |
| No aparece la barra | El servicio no arrancó | `novactl status` y `novactl logs` |
| `doctor`: Qt de Quickshell distinta | Qt se actualizó y Quickshell no | Reinstala Quickshell |
| Hay dos barras | `novactl dev` y el servicio a la vez | `novactl stop` antes de `dev` |
| No hay desenfoque | El compositor no anuncia `ext-background-effect-v1` | Ajustes → Estado de integración; la superficie queda opaca y legible |
| No sale la bienvenida | El daemon no responde o ya se completó | `novactl status`; Ajustes → Escritorio → «Ver la bienvenida otra vez» |
| `desktop-profile apply` dice que faltan paquetes | No se ejecutó `novactl install` | Instala y repite |
| `install`: «Perfil nativo no aplicado» | Cambiaste una clave gestionada tras aplicar el perfil, o falta `plasma-apply-colorscheme` | `novactl desktop-profile preview`; `restore` y repite, o `--keep-look` |
| Las apps abiertas no cambian de iconos | Falta `plasma-changeicons` en libexec | Se aplican al reabrirlas o al iniciar sesión |
| El splash es el de Plasma | Perfil no aplicado o prefijo distinto de `~/.local` | `novactl desktop-profile status`; reinstala con el prefijo por defecto |
| El inicio de sesión sigue con Breeze | Otro archivo fija el tema, falta `sddm-greeter-qt6` o el gestor no es SDDM | `novactl login-theme status`: muestra el tema efectivo y quién lo fija |
| Error o pantalla rota en el inicio de sesión | — | Desde otra consola (Ctrl+Alt+F3): `sudo packaging/sddm/install-theme.sh uninstall` y reinicia SDDM |

Para informar de un problema adjunta la salida de `novactl doctor`,
`novactl version` y `novactl logs 200`.
