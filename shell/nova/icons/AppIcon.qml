// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Window
import qs.nova.theme
import "IconCatalog.mjs" as Catalog

// Layered SVG rasterizes once per identity/appearance/scale.
Item {
    id: root
    property string name: "nova"
    property string appearance: Theme.effectiveIconMode
    property real size: Theme.icons.application
    readonly property var descriptor: Catalog.application(name)
    implicitWidth: size
    implicitHeight: size
    Image {
        anchors.fill: parent
        source: Catalog.applicationSource(root.name, root.appearance, {
            palette: Theme.icons.palette[root.descriptor.palette],
            ink: Theme.icons.ink,
            tile: Theme.icons.tile,
            tint: Theme.icons.tint,
            white: Theme.icons.white,
            darkTile: Theme.icons.darkTile,
            darkEdge: Theme.icons.darkEdge,
            lightEdge: Theme.icons.lightEdge,
            highlight: Theme.icons.glassHighlight,
            clearOpacity: Theme.icons.clearOpacity
        })
        sourceSize: Qt.size(Math.min(Theme.icons.rasterLimit, Math.ceil(root.size * Screen.devicePixelRatio)), Math.min(Theme.icons.rasterLimit, Math.ceil(root.size * Screen.devicePixelRatio)))
        fillMode: Image.PreserveAspectFit
        asynchronous: false
        cache: true
        smooth: true
    }
}
