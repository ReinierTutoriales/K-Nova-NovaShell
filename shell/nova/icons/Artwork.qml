// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Window
import qs.nova.theme

Item {
    id: root
    property string source: ""
    property real size: Theme.icons.application
    readonly property int rasterSize: Math.max(1, Math.min(Theme.icons.rasterLimit, Math.ceil(size * Screen.devicePixelRatio)))
    implicitWidth: size
    implicitHeight: size
    Image {
        id: image
        anchors.fill: parent
        source: root.source
        // Files can load off-thread; theme providers keep their GUI-thread
        // contract (QIcon/platform theme engines may not be thread-safe).
        asynchronous: !root.source.startsWith("image:")
        fillMode: Image.PreserveAspectFit
        sourceSize: Qt.size(root.rasterSize, root.rasterSize)
        visible: status === Image.Ready
    }
    // El icono genérico solo existe si no hay icono real o falla al cargar;
    // mientras carga no se crea (sin parpadeo ni objetos de ida y vuelta).
    Loader {
        anchors.fill: parent
        active: root.source === "" || image.status === Image.Error
        sourceComponent: Component { AppIcon { name: "application"; size: root.size } }
    }
}
