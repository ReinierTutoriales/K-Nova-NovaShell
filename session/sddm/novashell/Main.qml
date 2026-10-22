// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Effects
import "theme"

// Pantalla de inicio de sesión NovaShell para SDDM 0.21+ (Qt 6).
// Contexto que inyecta sddm-greeter: sddm, userModel, sessionModel,
// keyboard, config y primaryScreen. SDDM crea una vista por pantalla: solo
// la principal muestra el formulario; las demás, fondo y reloj.
// No ejecuta nada: entrar, apagar o reiniciar son llamadas al proxy de SDDM.
Rectangle {
    id: root
    // SDDM ajusta la raíz a cada pantalla (SizeRootObjectToView).
    color: Theme.color.previewTop

    readonly property string appearance: config.stringValue("appearance")
    readonly property string customBackground: config.stringValue("background")
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0

    LayoutMirroring.enabled: Qt.locale().textDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    Component.onCompleted: {
        Theme.mode = ["auto", "light", "dark"].indexOf(appearance) >= 0 ? appearance : "auto";
        Theme.reduceMotion = config.boolValue("reduceMotion");
    }

    // Fondo desenfocado una sola vez: la escena es estática y no cuesta GPU
    // mientras nadie escribe. Sin `background` usa el fondo NovaShell. Con el
    // renderizador por software (sin shaders, p. ej. VM sin GPU) se dibuja
    // la imagen tal cual en lugar de quedarse sin fondo.
    readonly property bool effects: GraphicsInfo.api !== GraphicsInfo.Software
    Image {
        id: wallpaper
        anchors.fill: parent
        source: root.customBackground !== "" ? root.customBackground
            : (Theme.dark ? "images/nova-dark.jpg" : "images/nova-light.jpg")
        sourceSize: Qt.size(root.width, root.height)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: !root.effects
    }
    MultiEffect {
        visible: root.effects
        anchors.fill: parent
        source: wallpaper
        blurEnabled: true
        blurMax: Theme.metrics.loginBlurMax
        blur: Theme.metrics.loginBackdropBlur
        autoPaddingEnabled: false
    }

    LoginClock {
        id: clock
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * Theme.metrics.loginClockTop)
    }

    LoginCard {
        id: card
        visible: primaryScreen
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: footer.top
        anchors.bottomMargin: Math.round(root.height * Theme.metrics.loginCardBottom)
        sessionIndex: root.sessionIndex
        focus: primaryScreen
    }

    LoginFooter {
        id: footer
        visible: primaryScreen
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Theme.space.xl }
        sessionIndex: root.sessionIndex
        onSessionSelected: index => root.sessionIndex = index
    }

    Connections {
        target: sddm
        function onLoginFailed() { card.failed(); }
        function onInformationMessage(message) { card.inform(message); }
    }
}
