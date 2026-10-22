# Aspecto nativo: iconos, paleta, Dolphin, transiciones y sesión

NovaShell usa Dolphin como explorador y los efectos que distribuye KWin 6.8.
El perfil nativo aplica preferencias de KDE con sus herramientas oficiales; no
añade plugins binarios ni una segunda implementación de las operaciones de
archivos. **`novactl install` lo aplica automáticamente** (perfil `balanced`)
para que el escritorio quede coherente nada más instalar; `novactl uninstall`
lo restaura. Para instalar sin tocar la configuración de KDE:
`novactl install --no-profile`.

## Aplicar y restaurar

```sh
./tools/novactl desktop-profile preview balanced
./tools/novactl desktop-profile apply balanced
./tools/novactl desktop-profile status
./tools/novactl desktop-profile restore
```

Requiere Python 3, `kreadconfig6` / `kwriteconfig6` (KConfig 6) y, para la
paleta, `plasma-apply-colorscheme` (Plasma). No necesita permisos de
administrador. Opciones:

| Opción | Efecto |
| :--- | :--- |
| `--appearance auto` (por defecto) | Variante clara u oscura según la luminancia de la paleta actual (`[Colors:Window] BackgroundNormal`) |
| `--appearance light\|dark` | Fuerza la variante |
| `--keep-look` | No cambia iconos, acento ni paleta; solo Dolphin, KWin y sesión |

## Qué aplica

| Área | Clave KDE | Valor |
| :--- | :--- | :--- |
| Iconos | `kdeglobals [Icons] Theme` | `NovaGlass` o `NovaGlass-dark` (recarga en vivo con `plasma-changeicons`) |
| Acento | `kdeglobals [General] AccentColor` y `accentColorFromWallpaper` | Se retiran: acento Liquid Glass neutro de la paleta |
| Paleta | `kdeglobals [General] ColorScheme` | `NovaGlassLight` o `NovaGlassDark` vía `plasma-apply-colorscheme` (KWin funde el cambio en 300 ms) |
| Terminal | `konsolerc [Desktop Entry] DefaultProfile` y `[LightDarkTheme]` | Perfil «NovaShell Claro» u «NovaShell Oscuro»; Konsole 26.08+ cambia solo con el sistema |
| Dolphin | `dolphinrc` | Iconos 64 px, detalles 24, compacto 32 |
| Animaciones | `AnimationDurationFactor` (apps y KWin) | 0,75: respuesta más ágil que el valor por defecto |
| Ventanas | `kwinrc [Plugins]` y `[Effect-scale]` | Ver tabla de perfiles |
| Sesión | `ksplashrc`, `kscreenlockerrc` | Splash y fondo de bloqueo NovaShell |

El acento se retira **antes** de aplicar la paleta: `plasma-apply-colorscheme`
funde `[General] AccentColor` en la paleta y un acento azul de Breeze la
teñiría. Al restaurar se devuelve primero el acento y después la paleta
anterior (si no había ninguna, la de Plasma por defecto, `BreezeLight`).

| Perfil | Apertura y cierre | Minimizar/restaurar | Maximizar, escritorios y menús | Duración KDE |
| :--- | :--- | :--- | :--- | :--- |
| `balanced` | Escala sutil 0,96 y opacidad, efecto Scale | Squash | Maximize, Slide y Fading Popups | Factor 0,75 |
| `glass` | Escala sutil 0,96 y opacidad, efecto Scale | Magic Lamp | Maximize, Slide y Fading Popups | Factor 0,75 |
| `reduced` | Sin animación | Sin animación | Desactivados | Factor 0 |

Blur queda activo en los tres: es el material del vidrio, no una animación.
Maximize, Slide, Fading Popups y Blur vienen activos en KWin; el perfil los
fija por si se desactivaron. Scale y Fade no se activan simultáneamente
(categoría exclusiva de KWin); tampoco Squash y Magic Lamp.
La duración de Scale permanece en modo automático para respetar el factor
global. Dolphin usa ese mismo factor y escucha sus cambios mediante KConfig.
Los tamaños base de iconos son 64 px en iconos, 24 en detalles y 32 en compacto.
Las propiedades guardadas por carpeta pueden prevalecer sobre esos valores.
No se cambian asociaciones, confirmaciones, papelera, pestañas ni vista previa.

Los tres perfiles activan también el splash NovaShell (`ksplashrc`) y el fondo
NovaShell en la pantalla de bloqueo (`kscreenlockerrc`); `apply` exige que
`novactl install` haya instalado esos paquetes. Ver [sesión](SESION.md).

La recarga usa `org.kde.KWin /KWin reconfigure`. Los cambios se notifican con
`kwriteconfig6 --notify`; algunas preferencias de vista de Dolphin requieren
abrir otra vista. No se cierran ventanas ni procesos de aplicaciones.

## Paletas para las aplicaciones KDE

La instalación incluye `NovaGlassLight` y `NovaGlassDark`; el perfil aplica
la que corresponde. Para cambiar de variante después:

```sh
./tools/novactl desktop-profile apply balanced --appearance dark   # o light
```

Las paletas cubren ventana, contenido, botones, selección, cabecera y tooltips;
las pruebas verifican contraste de texto normal de al menos 4,5:1.

## Terminal

Konsole abre un perfil NovaShell translúcido con desenfoque (Blur de KWin):

| Perfil | Fondo | Opacidad | Colores |
| :--- | :--- | :--- | :--- |
| NovaShell Claro | Perla `#f7f8fa` | 72 % | Intensos y saturados; texto normal ≥ 4,5:1 sobre el fondo |
| NovaShell Oscuro | Grafito `#0e0f12` | 64 % | Neón (verde menta, cian, ámbar, rosa); ≥ 4,5:1 |

Ambos usan cursor en I parpadeante, margen de 14 px centrado, 2 px de
interlineado y 10 000 líneas de historial; la fuente es la monoespaciada del
sistema. El panel de terminal de Dolphin (F4), Kate y Yakuake sin perfil
propio usan el mismo perfil porque lo leen de `konsolerc`. Konsole 26.08 o
posterior pasa de claro a oscuro con el sistema (`SyncProfileWithSystemTheme`,
`LightThemeProfile`, `DarkThemeProfile`); las versiones anteriores ignoran
esas claves y usan el perfil de la variante aplicada. Los archivos están en
`~/.local/share/konsole/` y se pueden editar desde Konsole → Configuración →
Perfiles.

## Carpetas

Las carpetas NovaGlass son vidrio monocromo: perla en claro, grafito en
oscuro, sin tinte de color (una prueba exige croma ≤ 16 en todos los colores).
Los 13 roles propios cubren además 73 sinónimos que usan Dolphin, KIO y la
biblioteca heredada (`folder-downloads`, `folder-images`, `folder-cloud`,
`user-desktop`…) mediante enlaces relativos, sin duplicar dibujos. Las
carpetas de color elegidas a propósito en Dolphin (`folder-red`,
`folder_color_*`) y los estados (`folder-locked`, `folder-encrypted`,
papelera) conservan su dibujo.

El material del shell no cambia por sí solo el estilo Qt Widgets de Dolphin.
Habilitar Blur en KWin no vuelve translúcidas todas las aplicaciones: cada una
debe solicitarlo y dibujar una superficie compatible. No se fuerza opacidad
global en ventanas, vídeos, menús o contenido de archivos.

## Recuperación y coste

El registro privado `$XDG_STATE_HOME/novashell/desktop-profile.json` conserva
solo las 27 claves gestionadas, incluidos valores ausentes. Se escribe de
forma atómica antes de aplicar cambios. Un bloqueo impide dos escritores.
Los fallos de escritura intentan rollback; si no puede completarse, se conserva
el registro para `restore`. Una aplicación interrumpida también es recuperable.

Restaurar preserva los valores que el usuario cambió después. Los registros
de versiones anteriores se migran al leerlos: las claves nuevas quedan como
«no tocadas» y conservan lo que el usuario tenga. Cambiar de perfil (o
reinstalar, que reaplica el perfil activo) mantiene la copia original; solo
bloquea si el usuario cambió después una clave que el perfil gestiona, y
entonces se restaura antes de aplicar otro. `novactl uninstall` restaura el
perfil antes de retirar los componentes.

La herramienta solo trabaja al invocarse y termina: no instala servicios,
temporizadores ni filtros de eventos permanentes. Las animaciones las ejecuta
KWin y las operaciones de archivos siguen a cargo de Dolphin/KIO.

## Documentación y código oficial contrastados

- [Configuración de Dolphin](https://docs.kde.org/stable_kf6/es/dolphin/dolphin/configuring-dolphin.html).
- [KConfig](https://develop.kde.org/docs/features/configuration/introduction/) y
  [configuración de scripts KWin](https://develop.kde.org/docs/plasma/kwin/).
- [Dolphin: factor de animación y KConfigWatcher](https://github.com/KDE/dolphin/blob/07b75935dcb36e602d81d27fb9c5c87235a09962/src/global.cpp).
- [Dolphin: preferencias de vista](https://github.com/KDE/dolphin/tree/07b75935dcb36e602d81d27fb9c5c87235a09962/src/settings).
- [KWin: parámetros de Scale](https://github.com/KDE/kwin/blob/fabe499f3f49b4c0e04a21b548921a17ed87eb21/src/plugins/scale/package/contents/config/main.xml).
- [KWin: efectos y valores por defecto](https://github.com/KDE/kwin/tree/master/src/plugins) (`metadata.json` de cada efecto).
- [Plasma: `plasma-apply-colorscheme` y acento](https://github.com/KDE/plasma-workspace/tree/master/kcms/colors) (`colorsapplicator.cpp`, `colorssettings.kcfg`).
- [Konsole: claves de perfil, esquema (`Opacity`, `Blur`) y cambio claro/oscuro](https://github.com/KDE/konsole/tree/master/src) (`profile/Profile.cpp`, `colorscheme/ColorScheme.cpp`, `settings/konsole.kcfg`, `MainWindow.cpp`).
- [Plasma: `plasma-changeicons`](https://github.com/KDE/plasma-workspace/tree/master/kcms/icons).
- [KConfig: herramientas y notificación](https://github.com/KDE/kconfig/tree/master/src/kreadconfig).

Las pruebas automatizadas cubren transacciones, rollback, recuperación,
conflictos, bloqueo y paletas. Falta aceptación en Dolphin y KWin con GPU real;
las pruebas de NovaShell sin pantalla no acreditan sus efectos externos.
