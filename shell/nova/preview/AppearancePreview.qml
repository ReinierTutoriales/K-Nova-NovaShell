// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Window
import qs.nova.theme

Window {
    id: root
    title: qsTr("NovaShell · Apariencia")
    width: Math.min(Theme.metrics.panelWidth, Screen.width)
    height: Math.min(Theme.metrics.panelHeight, Screen.height)
    minimumWidth: Math.min(Theme.metrics.minimumPanelWidth, Screen.width)
    minimumHeight: Math.min(Theme.metrics.minimumPanelHeight, Screen.height)
    visible: false
    color: Theme.color.surface
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.color.previewTop }
            GradientStop { position: 1; color: Theme.color.previewBottom }
        }
    }
    // Unload the gallery when closed; hidden windows keep no icon delegates.
    Loader {
        anchors.fill: parent
        anchors.margins: Theme.space.xl
        active: root.visible
        sourceComponent: AppearancePanel {}
    }
}
