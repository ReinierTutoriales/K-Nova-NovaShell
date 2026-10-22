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
    // Síncrono por defecto (barra, botones: sin parpadeo); las galerías con
    // muchos iconos lo activan para no rasterizar en el hilo de la UI.
    property bool asynchronous: false
    // Rasteriza a la densidad real de la pantalla, con tope de memoria.
    readonly property int pixelSize: Math.min(Theme.icons.rasterLimit,
        Math.ceil(size * Screen.devicePixelRatio))
    implicitWidth: size
    implicitHeight: size
    Image {
        anchors.fill: parent
        source: Catalog.symbolSource(root.name, root.tint.toString(), Theme.icons.strokeWidth)
        sourceSize: Qt.size(root.pixelSize, root.pixelSize)
        fillMode: Image.PreserveAspectFit
        asynchronous: root.asynchronous
        cache: true
        smooth: true
    }
}
