// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Window
import "theme"
import "icons/IconCatalog.mjs" as Catalog

// Símbolo monocromo del catálogo de NovaShell (el mismo que usa el shell).
Item {
    id: icon
    property string name: "power"
    property color tint: Theme.color.text
    property real size: Theme.icons.normal
    readonly property int pixelSize: Math.min(Theme.icons.rasterLimit, Math.ceil(size * Screen.devicePixelRatio))
    implicitWidth: size
    implicitHeight: size
    Accessible.ignored: true
    Image {
        anchors.fill: parent
        source: Catalog.symbolSource(icon.name, icon.tint.toString(), Theme.icons.strokeWidth)
        sourceSize: Qt.size(icon.pixelSize, icon.pixelSize)
        fillMode: Image.PreserveAspectFit
    }
}
