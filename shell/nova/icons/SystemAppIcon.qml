// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.nova.theme

// Keep application identities. Provider icons stay on KDE's GUI thread.
Item {
    id: root
    property string iconName: ""
    property string source: iconName ? Quickshell.iconPath(iconName, true) : ""
    property real size: Theme.icons.application
    implicitWidth: size
    implicitHeight: size
    IconImage {
        id: artwork
        anchors.fill: parent
        source: root.source
        asynchronous: false
        visible: root.source !== "" && status === Image.Ready
    }
    AppIcon {
        anchors.fill: parent
        name: "application"
        size: root.size
        visible: !artwork.visible
    }
}
