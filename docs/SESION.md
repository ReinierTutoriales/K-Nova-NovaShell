# Inicio de sesión, carga y bloqueo

NovaShell lleva la misma identidad (fondo, marca, tokens de `Theme`) a las
pantallas que rodean al escritorio. Cada una usa el mecanismo oficial de KDE o
del gestor de sesión; no se parchean binarios ni paquetes del sistema.

| Pantalla | Mecanismo oficial | Root | Estado |
| :--- | :--- | :--- | :--- |
| Carga al entrar (splash) | Paquete look-and-feel con `splash/Splash.qml`, leído por `ksplashqml` | No | 🟡 |
| Fondo claro/oscuro | Paquete de fondo de Plasma (`images/` e `images_dark/`) | No | 🟡 |
| Bloqueo | Fondo de `kscreenlocker` (`kscreenlockerrc`) | No | 🟡 (solo fondo) |
| Bienvenida de primer uso | Panel de NovaShell + preferencia `welcomeCompleted` del daemon | No | ✅ |
| Inicio de sesión | Tema SDDM 0.21+ con Qt 6 (`QtVersion=6`) | Solo para copiarlo al sistema | 🟡 |

✅ probado con Quickshell real · 🟡 probado con Qt real, falta la sesión
Plasma/SDDM real ([hoja de ruta](HOJA-DE-RUTA.md)).

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

## Inicio de sesión (SDDM)

![Pantalla de inicio de sesión NovaShell en oscuro con tres usuarios](images/inicio-sesion.png)

**Por qué SDDM.** Es el único gestor de sesión de Plasma que carga temas.
Plasma Login Manager (Plasma 6.6+, bifurcación de SDDM) compila su pantalla
dentro del programa (`qrc:/qt/qml/org/kde/plasma/login/Main.qml`) y solo deja
cambiar el fondo. `novactl doctor` indica qué gestor usa tu sistema.

**Diseño.** Fondo NovaShell desenfocado una vez (escena estática, sin coste
mientras nadie escribe), fecha en el formato largo del idioma y hora grande,
avatar circular (o inicial sobre el acento), campo de contraseña en cápsula
con botón de flecha, aviso de Bloq Mayús, sacudida breve si la contraseña es
incorrecta (desactivable) y, abajo, sesión, distribución de teclado y
suspender/reiniciar/apagar solo si SDDM informa de que el sistema lo permite.
Con varios usuarios aparece una fila de avatares; sin lista de usuarios, un
campo de nombre. Las pantallas secundarias muestran fondo y reloj. Con el
renderizador por software (VM sin GPU) se omiten desenfoque y recorte
circular en lugar de quedarse sin fondo. Comparte `Theme`, el catálogo de
símbolos y el fondo con el shell; no ejecuta nada: entrar y la energía son
llamadas al proxy de SDDM.

`theme.conf`: `appearance` (`auto`, `light`, `dark`), `background` (ruta
absoluta a una imagen; vacío usa el fondo NovaShell) y `reduceMotion`.

**Instalación.** `novactl install` prepara el tema en
`~/.local/share/novashell/sddm/novashell`. Desde ahí:

```sh
./tools/novactl login-theme preview     # ventana de prueba, sin root (sddm-greeter-qt6 --test-mode)
./tools/novactl login-theme install     # imprime la orden con sudo; novactl nunca usa root
./tools/novactl login-theme status      # gestor, tema instalado y tema efectivo
```

`packaging/sddm/install-theme.sh` es lo único de NovaShell que necesita root,
y lo ejecutas tú con `sudo` después de revisarlo. Valida que la carpeta es el
tema NovaShell para Qt 6 sin enlaces ni archivos especiales, lo copia a
`/usr/share/sddm/themes/novashell` (root, 0644/0755) y crea
`/etc/sddm.conf.d/zz-novashell.conf` con `[Theme] Current=novashell`. SDDM lee
`/usr/lib/sddm/sddm.conf.d`, después `/etc/sddm.conf.d` en orden alfabético
y por último `/etc/sddm.conf`: `zz-` queda detrás de `kde_settings.conf` (la
página de SDDM de Plasma) y el script avisa si `/etc/sddm.conf` fija otro
tema. `uninstall` borra solo esos dos elementos. No cambia el gestor de sesión;
si es Plasma Login Manager imprime cómo cambiar a SDDM y volver. Si falta
`sddm-greeter-qt6`, SDDM usa su tema integrado.

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

El tema SDDM se carga desde la instalación con objetos de contexto que
reproducen la API de SDDM 0.21 (`sddm`, `userModel`, `sessionModel`,
`keyboard`, `config`): contraseña incorrecta y correcta, cambio de usuario,
modo sin lista de usuarios, claro y oscuro, sin avisos de QML. Se ha
renderizado también con OpenGL en un compositor Wayland headless.
`sddm_install_test` comprueba la prioridad de configuración de SDDM y que el
script se niega sin root. Falta probarlo con `sddm-greeter-qt6` real.

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
- [SDDM: API del greeter](https://github.com/sddm/sddm/blob/633c1bf5c08d6c8e5b8435a70edb281b9f7b1550/src/greeter/GreeterApp.cpp),
  [`QtVersion` y greeter por versión de Qt](https://github.com/sddm/sddm/blob/633c1bf5c08d6c8e5b8435a70edb281b9f7b1550/src/daemon/Greeter.cpp)
  y [orden de configuración](https://github.com/sddm/sddm/blob/633c1bf5c08d6c8e5b8435a70edb281b9f7b1550/src/common/ConfigReader.cpp).
- [Plasma Login Manager: pantalla compilada](https://github.com/KDE/plasma-login-manager/blob/01cc484c4ced7a0e615d1b54027aa7624ea30eeb/src/frontend/greeter/main.cpp).
- [Apple HIG: Onboarding](https://developer.apple.com/design/human-interface-guidelines/onboarding).
- [kwriteconfig6: grupos anidados con `--group` repetido](https://github.com/KDE/kconfig/blob/75ca805bb010b6a55a0dfd1c5931eab334efeb6d/src/kreadconfig/kwriteconfig.cpp).
