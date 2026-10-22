// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Shapes
import "theme"

// Campo en cápsula de vidrio transparente (LoginGlass): claro en modo claro,
// negro translúcido en oscuro, con brillo superior y canto de luz. Con
// submitLabel muestra el botón de flecha, que gira mientras se verifica.
FocusScope {
    id: field
    property alias text: input.text
    property string placeholder: ""
    property bool secret: false
    property string submitLabel: ""
    property bool busy: false
    signal accepted()
    implicitWidth: Theme.metrics.loginFieldWidth
    implicitHeight: Theme.metrics.controlHeight
    opacity: enabled || busy ? 1 : Theme.metrics.disabledOpacity

    LoginGlass {
        anchors.fill: parent
        focused: input.activeFocus
    }
    TextInput {
        id: input
        anchors { left: parent.left; right: submit.visible ? submit.left : parent.right
            verticalCenter: parent.verticalCenter; leftMargin: Theme.space.lg; rightMargin: Theme.space.sm }
        focus: true
        clip: true
        enabled: !field.busy
        echoMode: field.secret ? TextInput.Password : TextInput.Normal
        passwordCharacter: "●"
        color: Theme.color.text
        selectionColor: Theme.color.selection
        selectedTextColor: Theme.color.text
        font.family: Theme.font.family
        font.pixelSize: Theme.font.body
        inputMethodHints: field.secret ? Qt.ImhSensitiveData | Qt.ImhNoPredictiveText : Qt.ImhNoAutoUppercase
        Accessible.role: Accessible.EditableText
        Accessible.name: field.placeholder
        Accessible.passwordEdit: field.secret
        onAccepted: field.accepted()
        Text {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            visible: input.text === "" && !input.preeditText
            text: field.placeholder
            color: Theme.color.textMuted
            font: input.font
        }
    }
    SubmitButton {
        id: submit
        visible: field.submitLabel !== ""
        anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: Theme.space.xs }
        label: field.submitLabel
        busy: field.busy
        onActivated: if (!field.busy) field.accepted()
    }

    component SubmitButton: Rectangle {
        id: button
        property string label: ""
        property bool busy: false
        signal activated()
        width: Theme.metrics.controlHeight - Theme.space.sm
        height: width
        radius: width / 2
        color: tap.pressed ? Theme.color.accentFillPressed
            : hover.hovered ? Theme.color.accentFillHover : Theme.color.accentFill
        border.width: Theme.space.hairline
        border.color: Theme.color.accentFillRim
        Behavior on color { ColorAnimation { duration: Theme.motion.fast } }
        Accessible.role: Accessible.Button
        Accessible.name: busy ? qsTr("Verificando") : label
        LoginIcon {
            anchors.centerIn: parent
            visible: !button.busy
            name: "forward"
            size: Theme.icons.small
            tint: Theme.color.accentFillText
        }
        // Indicador indeterminado mientras SDDM verifica: un arco que gira en
        // el hilo de render (RotationAnimator); con menos movimiento, quieto.
        Shape {
            id: spinner
            visible: button.busy
            anchors.centerIn: parent
            width: Theme.icons.small
            height: width
            antialiasing: true
            ShapePath {
                strokeColor: Theme.color.accentFillText
                strokeWidth: Theme.metrics.spinnerStroke
                fillColor: Theme.color.transparent
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: spinner.width / 2; centerY: spinner.height / 2
                    radiusX: spinner.width / 2 - Theme.metrics.spinnerStroke
                    radiusY: radiusX
                    startAngle: -90; sweepAngle: 270
                }
            }
            RotationAnimator on rotation {
                running: spinner.visible && !Theme.reduceMotion
                from: 0; to: 360
                duration: Theme.motion.progressCycle
                loops: Animation.Infinite
            }
        }
        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
        TapHandler { id: tap; onTapped: button.activated() }
    }
}
