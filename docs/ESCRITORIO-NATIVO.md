# Dolphin, transiciones de ventanas y sesión

NovaShell usa Dolphin como explorador y los efectos que distribuye KWin 6.8.
El perfil nativo aplica preferencias de KDE; no añade plugins binarios ni una
segunda implementación de las operaciones de archivos.

## Aplicar y restaurar

```sh
./tools/novactl desktop-profile preview balanced
./tools/novactl desktop-profile apply balanced
./tools/novactl desktop-profile status
./tools/novactl desktop-profile restore
```

Requiere Python 3 y las herramientas `kreadconfig6` / `kwriteconfig6` de
KConfig 6. No necesita permisos de administrador. La instalación de NovaShell
no aplica el perfil automáticamente.

| Perfil | Apertura y cierre | Minimizar/restaurar | Duración KDE |
| :--- | :--- | :--- | :--- |
| `balanced` | Escala sutil 0,96 y opacidad, efecto Scale | Squash | Factor 0,75 |
| `glass` | Escala sutil 0,96 y opacidad, efecto Scale | Magic Lamp | Factor 0,75 |
| `reduced` | Sin animación | Sin animación | Factor 0 |

Scale y Fade no se activan simultáneamente; tampoco Squash y Magic Lamp.
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

La instalación incluye `NovaGlassLight` y `NovaGlassDark` en los esquemas de
color KDE. Pueden elegirse desde Preferencias del sistema → Colores o con la
herramienta oficial:

```sh
plasma-apply-colorscheme NovaGlassDark
# Para claro: plasma-apply-colorscheme NovaGlassLight
```

Las paletas cubren ventana, contenido, botones, selección, cabecera y tooltips;
las pruebas verifican contraste de texto normal de al menos 4,5:1. El tema de
iconos global se elige por separado en KDE; los temas NovaGlass ya instalados
incluyen herencia y fallbacks para Dolphin y otras aplicaciones.

El material del shell no cambia por sí solo el estilo Qt Widgets de Dolphin.
Habilitar Blur en KWin no vuelve translúcidas todas las aplicaciones: cada una
debe solicitarlo y dibujar una superficie compatible. No se fuerza opacidad
global en ventanas, vídeos, menús o contenido de archivos.

## Recuperación y coste

El registro privado `$XDG_STATE_HOME/novashell/desktop-profile.json` conserva
solo las quince claves gestionadas, incluidos valores ausentes. Se escribe de
forma atómica antes de aplicar cambios. Un bloqueo impide dos escritores.
Los fallos de escritura intentan rollback; si no puede completarse, se conserva
el registro para `restore`. Una aplicación interrumpida también es recuperable.

Restaurar preserva los valores que el usuario cambió después. Los registros
de la versión 0.1.0 (sin claves de sesión) se migran al leerlos sin tocar el
splash ni el bloqueo que el usuario tenga. Cambiar de perfil
mantiene la copia original; si hay cambios externos, se requiere restaurar antes
de aplicar otro. `novactl uninstall` restaura un perfil activo antes de retirar
los componentes. La selección manual de paleta sigue siendo una preferencia KDE.

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
- [KConfig: herramientas y notificación](https://github.com/KDE/kconfig/tree/master/src/kreadconfig).

Las pruebas automatizadas cubren transacciones, rollback, recuperación,
conflictos, bloqueo y paletas. Falta aceptación en Dolphin y KWin con GPU real;
las pruebas de NovaShell sin pantalla no acreditan sus efectos externos.
