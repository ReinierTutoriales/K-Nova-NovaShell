<h1 align="center">K-Nova · NovaShell</h1>

<p align="center"><strong>Un escritorio Quickshell para KDE Plasma 6, con identidad propia y sin root.</strong></p>

<p align="center"><code>Plasma 6.8+ / Wayland</code> · <code>Quickshell 0.3.2+</code> · <code>Qt 6.12+</code></p>

Estado: base de desarrollo `0.1.0-dev`. Hay daemon IPC, barra por pantalla,
biblioteca visual, galería de apariencia, temas de iconos, instalador y CI.
Dock, lanzador, notificaciones y controles del sistema siguen en la
[hoja de ruta](docs/HOJA-DE-RUTA.md); la galería no simula esas funciones.

## Base visual

- 16 iconos de aplicación vectoriales por capas, con modos color, oscuro,
  transparente y teñido; símbolos semánticos compartidos por toda la interfaz.
- Colores, materiales, contraste, escalas y movimiento centralizados en `Theme`.
- Superficies cristal, esmeriladas y sólidas; controles con foco y teclado.
- Reducción de movimiento y transparencia, más alto contraste.
- Recursos locales, caché acotada y tamaño de rasterización ajustado a la pantalla.
  Sin fuentes de iconos, red, capturas continuas de pantalla ni shaders por icono.
- Biblioteca de sistema con 16.602 nombres de iconos: aplicaciones, acciones,
  carpetas, MIME, dispositivos, estados, categorías, emblemas y cursores.
  Tres variantes de sistema y cuatro temas `NovaGlass*`, instalados sin red.
  Los nombres estándar y los identificadores de aplicaciones resuelven mediante
  herencia freedesktop; Breeze/hicolor cubren las aplicaciones ausentes.

El acabado translúcido y el desenfoque de fondo son distintos. El núcleo utiliza
el protocolo Wayland estándar cuando se habilita explícitamente y el compositor
lo admite. No incluye plugins nativos de KWin ni promete refracción física.
Sin soporte confirmado mantiene un relleno de mayor opacidad para legibilidad.
[Contrato visual y uso](docs/APARIENCIA.md).

## Arquitectura

Un daemon C++/Qt6 integra el sistema mediante un
[contrato IPC versionado](docs/CONTRATO-IPC-v1.md). QML presenta los datos y nunca
ejecuta procesos. El socket es privado y verifica el UID del cliente.
Los componentes QML tienen un límite de 400 líneas.
[Arquitectura](docs/ARQUITECTURA.md).

## Requisitos

KDE Plasma 6.8+ Wayland, Quickshell 0.3.2+ y Qt 6.12.0+.
El daemon requiere CMake ≥ 3.21, Ninja, C++20 y Qt Core/Network.
Para SVG se necesita el plugin de imágenes Qt SVG;
Qt Quick Controls se usa en la galería.

| Distribución | Compilación y módulos de interfaz adicionales |
| :--- | :--- |
| Arch / CachyOS | `cmake ninja gcc pkgconf wayland qt6-base qt6-declarative qt6-svg qt6-imageformats` |
| Fedora | `cmake ninja-build gcc-c++ pkgconf wayland-devel qt6-qtbase-devel qt6-qtdeclarative qt6-qtsvg` |
| Debian / Ubuntu | `cmake ninja-build g++ pkg-config libwayland-dev qt6-base-dev libqt6svg6 qml6-module-qtquick-controls qml6-module-qtquick-layouts qml6-module-qtquick-window qml6-module-qtqml-workerscript` |

Instala esas dependencias con el gestor de tu distribución y Quickshell desde
su [guía oficial](https://quickshell.org/docs/guide/install-setup/).
Las recetas no acreditan validación de escritorio en todas las distribuciones.

## Empezar

```sh
git clone https://github.com/ReinierTutoriales/K-Nova-NovaShell.git
cd K-Nova-NovaShell
./tools/novactl doctor
./tools/novactl install
./tools/novactl start
./tools/novactl enable  # opcional
```

La barra incluye el acceso Apariencia. Los cambios de la galería duran la sesión.
Para abrirla al desarrollar:

```sh
NOVA_APPEARANCE_PREVIEW=1 ./tools/novactl dev
```

Otras órdenes: `stop`, `restart`, `status`, `logs`, `version`,
`uninstall [--purge]`. NovaShell convive con Plasma; no sustituye su shell
ni cambia automáticamente el tema global de iconos.

## Desarrollo y verificación

Para coordinar Dolphin y las transiciones de las aplicaciones con los efectos
incluidos en KWin, hay un [perfil nativo reversible](docs/ESCRITORIO-NATIVO.md)
(`novactl desktop-profile`) y paletas NovaGlass claras/oscuras para KDE.
La instalación conserva las preferencias actuales hasta que se aplique un perfil.

[Guía de desarrollo](docs/DESARROLLO.md):

```sh
cmake -S . -B build -G Ninja -DNOVA_WERROR=ON
cmake --build build
ctest --test-dir build --output-on-failure
python3 tools/check-sources.py
shellcheck -x tools/novactl
node --test tests/appearance.test.mjs
```

Node.js solo sirve para pruebas y regeneración de SVG; no es una dependencia
de instalación ni de ejecución. CI carga QML real y renderiza los recursos con Qt
6.12.0. El daemon también se compila con ese SDK. Eso no acredita el blur,
los controladores GPU ni una sesión Plasma real.

`packaging/runtime.env` fija los mínimos para usuarios (Qt, Quickshell,
Plasma). `tests/requirements-ci.txt` fija la última Qt estable con la que el CI
compila y prueba; subirla no eleva el mínimo exigido. Dependabot propone actualizaciones semanales de Qt/PySide y acciones;
CI semanal detecta nuevas versiones estables de Qt y Quickshell. Los cambios
requieren pruebas antes de integrarse. Quickshell debe recompilarse para la
versión exacta de Qt instalada, porque utiliza sus API privadas.
`packaging/runtime.env` fija los mínimos de Plasma y Quickshell, comprobados
por `novactl doctor`. El objetivo es la rama estable más reciente, sin betas.

## Licencias

[Licencia](LICENSE) y [avisos de terceros](THIRD_PARTY_NOTICES.md).
El código original usa GPL-3.0-or-later; las partes adaptadas están identificadas
por archivo y la distribución combinada cumple GPLv3.
