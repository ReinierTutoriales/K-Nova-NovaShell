// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.nova.services
import qs.nova.icons
import qs.nova.theme

RowLayout {
    id: tray
    required property var window
    spacing: Theme.space.xs
    Repeater {
        model: Platform.desktop.trayItems
        Button {
            required property var modelData
            implicitWidth: Theme.metrics.touchTarget
            implicitHeight: Theme.metrics.touchTarget
            hoverEnabled: true
            Accessible.name: modelData.title || modelData.id
            ToolTip.text: Accessible.name
            ToolTip.visible: hovered
            contentItem: SystemAppIcon { source: modelData.icon; size: Theme.icons.normal }
            onClicked: Platform.desktop.activateTray(modelData, tray.window)
            TapHandler { acceptedButtons: Qt.RightButton; onTapped: Platform.desktop.trayMenu(modelData, tray.window) }
        }
    }
}
