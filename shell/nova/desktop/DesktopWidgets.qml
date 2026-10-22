// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.nova.theme
import qs.nova.controls
import qs.nova.services

// Widgets sobre el fondo (capa Bottom: debajo de las ventanas, encima del
// wallpaper). Sin teclado ni zona exclusiva; no tapan ni empujan nada.
PanelWindow {
    id: widgets
    required property var output
    screen: output
    visible: Platform.preferences.values.desktopWidgets ?? true
    anchors { top: true; left: true }
    margins { top: Theme.barHeight + Theme.space.lg; left: Theme.space.lg }
    implicitWidth: Theme.metrics.desktopWidgetWidth
    implicitHeight: column.implicitHeight
    color: Theme.color.transparent
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "novashell-widgets"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    BackgroundEffect.blurRegion: Theme.blurEnabled ? blurRegion : null
    Region {
        id: blurRegion
        Region { item: clockCard }
        Region { item: systemCard }
        Region { item: calendarCard }
    }

    // Métricas solo mientras los widgets existen; la frecuencia es baja.
    // Contador de pantallas con widgets visibles (una instancia por pantalla).
    Component.onCompleted: if (visible) ++Platform.desktopWidgetsActive
    Component.onDestruction: if (visible) Platform.desktopWidgetsActive = Math.max(0, Platform.desktopWidgetsActive - 1)
    onVisibleChanged: Platform.desktopWidgetsActive = Math.max(0, Platform.desktopWidgetsActive + (visible ? 1 : -1))

    SystemClock { id: clock; precision: SystemClock.Minutes }

    ColumnLayout {
        id: column
        width: parent.width
        spacing: Theme.space.md

        RowLayout {
            spacing: Theme.space.md
            GlassSurface {
                id: clockCard
                cornerRadius: Theme.radius.xl
                implicitWidth: Theme.metrics.clockSize + 2 * Theme.space.lg
                implicitHeight: implicitWidth
                AnalogClock { anchors.centerIn: parent; time: clock.date }
            }
            GlassSurface {
                id: systemCard
                cornerRadius: Theme.radius.xl
                Layout.fillWidth: true
                implicitHeight: clockCard.implicitHeight
                SystemCard {
                    anchors { fill: parent; margins: Theme.space.lg }
                    metrics: Platform.metrics
                }
            }
        }
        GlassSurface {
            id: calendarCard
            cornerRadius: Theme.radius.xl
            Layout.fillWidth: true
            implicitHeight: calendar.implicitHeight + 2 * Theme.space.lg
            CalendarCard {
                id: calendar
                anchors { fill: parent; margins: Theme.space.lg }
                now: clock.date
            }
        }
    }
}
