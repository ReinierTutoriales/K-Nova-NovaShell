// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell.Widgets
import qs.nova.theme

// Keep application identities. Provider icons stay on KDE's GUI thread.
Item {
    id: root
    property string source: ""
    property real size: Theme.icons.application
    implicitWidth: size
    implicitHeight: size
    IconImage {
        id: artwork
        anchors.fill: parent
        source: root.source
        asynchronous: false
        visible: root.source !== "" && backer.status === Image.Ready
    }
    AppIcon {
        anchors.fill: parent
        name: "application"
        size: root.size
        visible: !artwork.visible
    }
}
