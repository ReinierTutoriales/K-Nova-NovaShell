// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.nova.theme
import qs.nova.icons
import qs.nova.controls

Button {
    id: tile
    property string applicationName: ""
    property string iconName: ""
    property string iconSource: ""
    property bool showLabel: true
    property bool running: false
    property real iconSize: Theme.icons.application
    implicitWidth: Theme.metrics.launcherCellWidth
    implicitHeight: Theme.metrics.launcherCellHeight
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    Accessible.name: applicationName
    ToolTip.text: applicationName
    ToolTip.visible: hovered && !showLabel
    background: GlassSurface {
        interactive: true
        hovered: tile.hovered
        pressed: tile.down
        focused: tile.visualFocus
        visible: tile.hovered || tile.down || tile.visualFocus
    }
    contentItem: ColumnLayout {
        spacing: Theme.space.xs
        Artwork {
            source: tile.iconSource
            size: tile.iconSize
            Layout.alignment: Qt.AlignHCenter
        }
        Text {
            visible: tile.showLabel
            text: tile.applicationName
            textFormat: Text.PlainText
            color: Theme.color.text
            font.family: Theme.font.family
            font.pixelSize: Theme.font.body
            horizontalAlignment: Text.AlignHCenter
            maximumLineCount: 2
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
        Rectangle {
            visible: tile.running
            implicitWidth: Theme.metrics.statusSize
            implicitHeight: Theme.space.xs
            radius: Theme.radius.status
            color: Theme.color.text
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
