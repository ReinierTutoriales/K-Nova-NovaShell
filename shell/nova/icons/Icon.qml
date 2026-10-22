// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Window
import qs.nova.theme
import "IconCatalog.mjs" as Catalog

Item {
    id: root
    property string name: "settings"
    property color tint: Theme.color.text
    property real size: Theme.icons.normal
    implicitWidth: size
    implicitHeight: size
    Image {
        anchors.fill: parent
        source: Catalog.symbolSource(root.name, root.tint.toString(), Theme.icons.strokeWidth)
        sourceSize: Qt.size(Math.min(Theme.icons.rasterLimit, Math.ceil(root.size * Screen.devicePixelRatio)), Math.min(Theme.icons.rasterLimit, Math.ceil(root.size * Screen.devicePixelRatio)))
        fillMode: Image.PreserveAspectFit
        asynchronous: false
        cache: true
        smooth: true
    }
}
