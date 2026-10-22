// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Window
import qs.nova.theme

Item {
    id: root
    property string source: ""
    property real size: Theme.icons.application
    readonly property int rasterSize: Math.min(Theme.icons.rasterLimit, Math.ceil(size * Screen.devicePixelRatio))
    implicitWidth: size
    implicitHeight: size
    Image {
        id: image
        anchors.fill: parent
        source: root.source
        asynchronous: false
        fillMode: Image.PreserveAspectFit
        sourceSize: Qt.size(root.rasterSize, root.rasterSize)
        visible: status === Image.Ready
    }
    AppIcon { anchors.fill: parent; name: "application"; size: root.size; visible: !image.visible }
}
