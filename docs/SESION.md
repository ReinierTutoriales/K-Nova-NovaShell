# Inicio de sesión, carga y bloqueo

NovaShell lleva la misma identidad (fondo, marca, tokens de `Theme`) a las
pantallas que rodean al escritorio. Cada una usa el mecanismo oficial de KDE o
del gestor de sesión; no se parchean binarios ni paquetes del sistema.

| Pantalla | Mecanismo oficial | Root | Estado |
| :--- | :--- | :--- | :--- |
| Carga al entrar (splash) | Paquete look-and-feel con `splash/Splash.qml`, leído por `ksplashqml` | No | ✅ |
| Fondo claro/oscuro | Paquete de fondo de Plasma (`images/` e `images_dark/`) | No | ✅ |
| Bloqueo | Fondo de `kscreenlocker` (`kscreenlockerrc`) | No | ✅ (solo fondo) |
| Bienvenida de primer uso | Panel de NovaShell + preferencia `welcomeCompleted` del daemon | No | ✅ |

## Fondo NovaShell

`tools/render-wallpapers.py` genera `assets/wallpapers/nova-{light,dark}.jpg`
(3840×2160, ~100 KiB, degradado con ruido determinista contra bandas) a partir
de los tokens `previewTop`/`previewBottom` y el acento. `novactl install` lo
instala como paquete de Plasma en `~/.local/share/wallpapers/NovaShell`: Plasma
elige la variante clara u oscura según el esquema de color y lo muestra en su
selector de fondos. Su metadato sugiere el acento `#3478f6`.

## Splash

`novactl install` instala `~/.local/share/plasma/look-and-feel/org.knova.novashell`
con un único componente: `contents/splash/Splash.qml` más una copia de
`shell/nova/theme` y sus imágenes. No incluye pantalla de bloqueo, disposición
de paneles ni esquema de color, así que activarlo no cambia el tema global.

Comportamiento comprobado en el código de `ksplashqml` (Plasma 6.8):

- Lee `[KSplash] Theme` de `ksplashrc`, carga el archivo `splashmainscript`
  del paquete y escribe la propiedad `stage` en la raíz.
- `stage` empieza en 1 y avanza cada 200 ms; al llegar a 6, o cuando
  plasmashell libera `org.kde.PlasmaLoading`, la ventana se cierra.
- Es una superficie layer-shell superpuesta, sin cursor, con tiempo máximo de
  30 s.

El splash muestra el fondo, la marca y una barra **determinada** que avanza con
`stage` (Apple HIG, *Progress indicators*): sin barrido indeterminado, con
entrada breve y salida al llegar a la última etapa. El fondo se decodifica al
tamaño de la pantalla (`sourceSize`), no a 4K.

## Bloqueo

**KWin no implementa `ext-session-lock-v1`**, el protocolo que usa
`WlSessionLock` de Quickshell; en Plasma solo bloquea `kscreenlocker_greet`.
En Plasma 6.8 ese proceso carga la interfaz de bloqueo desde el paquete de
shell (`org.kde.plasma.desktop`, archivo `lockscreenmainscript`), no desde el
tema global. Sustituir ese paquete rompería plasmashell, y la interfaz de
bloqueo es una frontera de seguridad: NovaShell **no** la reemplaza.

Lo oficial y reversible es su fondo: el perfil fija
`[Greeter] WallpaperPlugin=org.kde.image` y
`[Greeter][Wallpaper][org.kde.image][General] Image` al paquete NovaShell.

## Bienvenida de primer uso

Sigue Apple HIG (*Onboarding*): rápida, opcional y práctica. Cuatro pasos
(presentación, apariencia, escritorio y privacidad, listo); cada elección se
aplica al momento mediante `settings.patch`, de modo que se aprende usándola, y
los valores por defecto ya son razonables (portapapeles desactivado).

- Se abre sola, centrada, la primera vez que llegan las preferencias del
  daemon con `welcomeCompleted: false`.
- Terminarla, «Omitir», Esc o la X la marcan como vista y no vuelve a salir
  sola. Se reabre en Ajustes → Escritorio → «Ver la bienvenida otra vez» o con
  `qs ipc call novashell toggle welcome`.
- Quien actualice desde 0.1.0 la verá una vez (la preferencia es nueva).
- La acción principal usa el relleno `accentFill` (acento oscurecido): texto
  blanco a 4,8:1 con el acento por defecto (WCAG AA).

## Activar y deshacer

El splash y el fondo de bloqueo forman parte del perfil nativo
([detalles](ESCRITORIO-NATIVO.md)):

```sh
./tools/novactl install                    # instala los paquetes en ~/.local
./tools/novactl desktop-profile apply      # activa splash y fondo de bloqueo
./tools/novactl desktop-profile restore    # vuelve a los valores anteriores
```

`apply` se niega si los paquetes no están instalados. Ambos se aplican en el
siguiente inicio de sesión o bloqueo; no hay que recargar nada.

## Pruebas

`tests/session_smoke.py` instala con `cmake --install` en un prefijo temporal,
valida la estructura de los paquetes y carga el `Splash.qml` instalado, como
`ksplashqml`, en claro y oscuro recorriendo todas las etapas sin avisos de QML.
Guarda `session-splash-*.png` en el build (artefacto del CI). Falta validarlo
en una sesión Plasma real.

`tests/quickshell_smoke.py` comprueba con Quickshell y el daemon reales que la
bienvenida empieza pendiente en un perfil nuevo, se recorre entera y queda
guardada como completada; `tst_desktop` valida el tipo de la preferencia.

## Código oficial contrastado

- [ksplashqml: tema, etapas y cierre](https://github.com/KDE/plasma-workspace/blob/12d5da86ab603551e12d1e3a358754d329276e61/ksplash/ksplashqml/splashapp.cpp)
  y [ventana](https://github.com/KDE/plasma-workspace/blob/12d5da86ab603551e12d1e3a358754d329276e61/ksplash/ksplashqml/splashwindow.cpp).
- [Estructura Plasma/LookAndFeel](https://github.com/KDE/plasma-workspace/blob/12d5da86ab603551e12d1e3a358754d329276e61/shell/packageplugins/lookandfeel/lookandfeel.cpp)
  y [paquete de fondo con `images_dark`](https://github.com/KDE/plasma-workspace/blob/12d5da86ab603551e12d1e3a358754d329276e61/shell/packageplugins/wallpaperimages/wallpaperpackage.cpp).
- [kscreenlocker: paquete de shell y fallback](https://github.com/KDE/kscreenlocker/blob/2411b3f03ba5a4d005dfd87396df462e55e3dce0/greeter/greeterapp.cpp)
  y [grupo del fondo](https://github.com/KDE/kscreenlocker/blob/2411b3f03ba5a4d005dfd87396df462e55e3dce0/settings/wallpaper_integration.cpp).
- [Interfaz de bloqueo de Plasma 6.8](https://github.com/KDE/plasma-desktop/tree/71b7f850e0a54597e73dc1379bb013f26012aa71/desktoppackage/contents/lockscreen).
- [Quickshell `WlSessionLock`](https://quickshell.org/docs/v0.3.2/types/Quickshell.Wayland/WlSessionLock)
  (requiere `ext-session-lock-v1`).
- [Apple HIG: Onboarding](https://developer.apple.com/design/human-interface-guidelines/onboarding).
- [kwriteconfig6: grupos anidados con `--group` repetido](https://github.com/KDE/kconfig/blob/75ca805bb010b6a55a0dfd1c5931eab334efeb6d/src/kreadconfig/kwriteconfig.cpp).
