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

    readonly property string customBackground: config.stringValue("background")
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    // Con el renderizador por software (sin shaders, p. ej. VM sin GPU) no
    // hay desenfoque ni recortes: se dibuja la imagen tal cual.
    readonly property bool effects: GraphicsInfo.api !== GraphicsInfo.Software

    LayoutMirroring.enabled: Qt.locale().textDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    // theme.conf → Theme. Valores desconocidos vuelven al predeterminado.
    Component.onCompleted: {
        const appearance = config.stringValue("appearance");
        Theme.mode = ["auto", "light", "dark"].indexOf(appearance) >= 0 ? appearance : "auto";
        // Acento Liquid Glass salvo que theme.conf pida un color.
        const accent = config.stringValue("accent");
        if (/^#[0-9a-fA-F]{6}$/.test(accent)) {
            Theme.accent = accent;
            Theme.glassAccent = false;
        }
        Theme.reduceMotion = config.boolValue("reduceMotion");
        // Intensidad del vidrio (0 = más opaco, 1 = más transparente).
        const amount = config.realValue("transparency");
        Theme.transparency = amount >= 0 && amount <= 1 && config.stringValue("transparency") !== "" ? amount : 0.5;
        enter.start();
    }

    // Fondo desenfocado una sola vez: la escena es estática y no cuesta GPU
    // mientras nadie escribe. Sin `background` usa el fondo NovaShell.
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
    // Velo vertical: asienta reloj y formulario sobre cualquier fondo.
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.color.scrimTop }
            GradientStop { position: 1; color: Theme.color.scrimBottom }
        }
    }

    Item {
        id: stage
        anchors.fill: parent
        opacity: 0
        transform: Translate { id: rise; y: Theme.reduceMotion ? 0 : Theme.metrics.loginEnterOffset }

        LoginClock {
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
            effects: root.effects
        }

        LoginFooter {
            id: footer
            visible: primaryScreen
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Theme.space.xl }
            sessionIndex: root.sessionIndex
            onSessionSelected: index => root.sessionIndex = index
        }
    }

    // Entrada breve (aparece y sube) y salida al entrar en la sesión.
    ParallelAnimation {
        id: enter
        NumberAnimation { target: stage; property: "opacity"; to: 1; duration: Theme.motion.slow; easing.type: Easing.OutCubic }
        NumberAnimation { target: rise; property: "y"; to: 0; duration: Theme.motion.slow; easing.type: Easing.OutCubic }
    }
    NumberAnimation {
        id: leave
        target: stage; property: "opacity"; to: 0
        duration: Theme.motion.normal; easing.type: Easing.InCubic
    }

    Connections {
        target: sddm
        function onLoginFailed() { card.failed(); }
        function onLoginSucceeded() { leave.start(); }
        function onInformationMessage(message) { card.inform(message); }
    }
}
