// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "theme"

// Pantalla de carga al iniciar sesión (ksplashqml, Plasma 6).
// ksplashqml escribe `stage` (1…5; al llegar a 6 o cuando plasmashell
// termina de cargar, cierra la ventana). El progreso refleja esas etapas:
// determinado y continuo (Apple HIG, Progress indicators), sin barrido.
// Solo QtQuick: no depende de Quickshell ni de Kirigami.
Rectangle {
    id: root
    property int stage: 0
    readonly property int lastStage: 5
    readonly property real progress: Math.max(0, Math.min(1, (stage - 1) / (lastStage - 1)))

    color: Theme.color.previewTop

    Image {
        id: wallpaper
        anchors.fill: parent
        source: Theme.dark ? "images/nova-dark.jpg" : "images/nova-light.jpg"
        // Decodifica al tamaño de la pantalla, no a 4K: menos memoria y arranque.
        sourceSize: Qt.size(root.width, root.height)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
    }

    Column {
        id: content
        anchors.centerIn: parent
        spacing: Theme.space.lg
        opacity: 0
        scale: Theme.metrics.panelClosedScale

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            source: Theme.dark ? "images/nova-mark-dark.svg" : "images/nova-mark-light.svg"
            width: Theme.metrics.splashMark
            height: width
            sourceSize: Qt.size(width, height)
            Accessible.ignored: true
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "K-Nova"
            color: Theme.color.text
            font.family: Theme.font.family
            font.pixelSize: Theme.font.heading
            font.weight: Font.DemiBold
        }
        Rectangle {
            id: track
            anchors.horizontalCenter: parent.horizontalCenter
            width: Theme.metrics.splashProgressWidth
            height: Theme.metrics.sliderTrack
            radius: height / 2
            color: Theme.color.sliderTrack
            Accessible.role: Accessible.ProgressBar
            Accessible.name: qsTr("Iniciando sesión")
            Rectangle {
                height: parent.height
                radius: parent.radius
                width: parent.width * root.progress
                color: Theme.color.accent
                Behavior on width {
                    enabled: !Theme.reduceMotion
                    NumberAnimation { duration: Theme.motion.slow; easing.type: Easing.OutCubic }
                }
            }
        }
    }

    // Entrada breve al aparecer; salida cuando la sesión ya está casi lista.
    states: [
        State { name: "shown"; when: root.stage >= 1 && root.stage < root.lastStage
            PropertyChanges { content.opacity: 1; content.scale: 1 } },
        State { name: "leaving"; when: root.stage >= root.lastStage
            PropertyChanges { content.opacity: 0; content.scale: 1 } }
    ]
    transitions: [
        Transition { to: "shown"
            NumberAnimation { properties: "opacity,scale"; duration: Theme.motion.slow; easing.type: Easing.OutCubic } },
        Transition { to: "leaving"
            NumberAnimation { property: "opacity"; duration: Theme.motion.normal; easing.type: Easing.InCubic } }
    ]
}
