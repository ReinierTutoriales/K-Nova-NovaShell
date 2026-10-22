# Arquitectura de NovaShell

## Piezas

```text
┌──────────────────────────────┐        ┌───────────────────────────┐
│ Quickshell (qs -c novashell) │ JSONL  │ nova-platform (C++/Qt6)   │
│  shell/nova/                 │◄──────►│  daemon/                  │
│   bar/      presentación     │ socket │   Protocol  parseo/límites│
│   theme/    tokens de diseño │  0600  │   Router    operaciones   │
│   services/ Platform (IPC)   │        │   Server    socket + UID  │
└──────────────────────────────┘        └─────────────┬─────────────┘
                                                      ▼
                                   KWin (DBus/scripts), NetworkManager,
                                   PipeWire, BlueZ, systemd… (futuro)
```

| Directorio | Responsabilidad | No hace |
| :--- | :--- | :--- |
| `shell/nova/theme` | Colores, radios, espacios, tipografía, duraciones. | Lógica. |
| `shell/nova/icons` | Catálogo vectorial, carga y fallbacks. | Lanzar aplicaciones. |
| `shell/nova/controls` | Materiales y controles compartidos. | Capturar el escritorio. |
| `shell/nova/preview` | Galería de apariencia; se crea al abrirla y se destruye al cerrarla (`LazyLoader`). | Simular funciones del sistema. |
| `shell/nova/CompositorBlur.qml` | Activa el blur solo si el compositor anuncia `ext-background-effect-v1`. | Forzar efectos no soportados. |
| `shell/nova/services` | Único cliente del daemon (`Platform`). | Dibujar UI. |
| `shell/nova/bar` | Barra: lanzador, indicadores de estado, bandeja, reloj. | Ejecutar comandos. |
| `shell/nova/desktop` | Dock, paneles (lanzador, centro de control, ajustes…) y widgets de escritorio. | Tocar archivos del sistema. |
| `daemon/` | Integración con el sistema detrás de operaciones acotadas. | UI. |
| `session/` | Pantallas fuera del escritorio: splash (`ksplashqml`), tema SDDM y paquetes de fondo y look-and-feel; reutilizan `shell/nova/theme`. | Sustituir la interfaz de bloqueo de Plasma. |
| `tools/novactl` | Compilar, instalar en `$HOME`, gestionar servicios, perfil nativo y tema SDDM. | Usar root. |
| `packaging/sddm/install-theme.sh` | Único paso con root (opcional): copiar y activar el tema SDDM. | Cambiar el gestor de sesión. |

## Reglas que no se negocian (las comprueba el CI)

1. **La UI no ejecuta procesos.** `Process {}` y `execDetached()` están
   prohibidos en QML (`tools/check-sources.py`). Si el shell necesita algo del
   sistema, se añade una operación al [contrato IPC](CONTRATO-IPC-v1.md).
2. **Contrato = código.** `ipc_smoke` compara `platform.capabilities` con la
   tabla del contrato; documentar e implementar van en el mismo commit.
3. **QML ≤ 400 líneas por archivo.** Un módulo grande se divide en
   componentes con estado separado de la vista.
4. **Sin root.** Ni el daemon ni `novactl` aceptan correr como root.
5. **Sin plugins KWin nativos en el núcleo.** Lo que requiera KWin se intenta
   primero con scripts KWin (JS) o DBus, que no dependen del ABI.
6. **Ningún literal de diseño en componentes.** Todo color/radio/duración sale
   de `Theme`.

## Seguridad del IPC

- Directorio `$XDG_RUNTIME_DIR/novashell/` en `0700`, verificado al arrancar
  (propietario y modo; se corrige o se aborta).
- Socket `0600` con `QLocalServer::UserAccessOption` **y** `chmod` explícito.
- `SO_PEERCRED`: se rechaza cualquier cliente con otro UID.
- Líneas ≤ 64 KiB, `requestId` ≤ 64, ≤ 32 clientes: un cliente roto no puede
  agotar memoria.
- Un manejador que lanza una excepción devuelve `internal`; el daemon sigue.
- Una segunda instancia detecta la primera y no le roba el socket.

## Atajos de teclado (IPC de Quickshell)

`qs ipc call novashell toggle <launcher|controls|notifications|settings|overview|clipboard|widgets|welcome>`,
`close` y `appearance`. Se asignan como comandos en Ajustes de KDE → Atajos.

## Consumo en reposo

- Sin temporizadores periódicos con el escritorio quieto: el reloj despierta
  una vez por minuto (`SystemClock`), la caducidad IPC solo corre con
  peticiones en vuelo y la reconexión solo mientras el daemon está caído.
- Las ventanas secundarias (apariencia) no existen hasta que se abren.
- Widgets de escritorio: el reloj despierta una vez por minuto y las métricas
  se piden cada 10 s solo mientras los widgets están visibles.
- El vidrio son nodos estáticos del scene graph; el blur lo hace el compositor.

## Cliente IPC del shell (`JsonlClient`)

- Lecturas idempotentes en cola (máx. 50) mientras el daemon no está;
  escrituras fallan al instante (nunca se "reproducen" tarde).
- Hasta 128 peticiones pendientes en total. Caducidad de 10 s desde que se
  solicitan, también sin conexión; fallo de todo lo pendiente al desconectar.
- Deshabilitar el cliente cierra su socket y cancela las peticiones; sin ruta
  de socket no arranca el temporizador de reconexión.
- El cliente rechaza peticiones mayores de 64 KiB UTF-8 antes de escribirlas,
  evitando que el daemon cierre una conexión con otras peticiones pendientes.
- Reconexión con espera exponencial 0,5 s → 8 s creando un `Socket` nuevo
  (aislamiento de eventos tardíos entre conexiones).

## Arranque (systemd de usuario)

- `nova-platform.service` y `novashell.service`, ambos `PartOf=graphical-session.target`.
- `After=plasma-kwin_wayland.service`: KDE activa `graphical-session.target`
  antes de que el socket Wayland exista.
- `novashell.service`: `KillMode=process` (reiniciar el shell no mata las apps
  lanzadas desde él), `QS_DISABLE_FILE_WATCHER=1` (sin recargas de QML a medio
  copiar), `MALLOC_ARENA_MAX=2`.
- La instalación del árbol QML es atómica (preparar al lado + `mv`).
