// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "theme"

// Campo de texto en cápsula. Con submitLabel muestra el botón de flecha.
FocusScope {
    id: field
    property alias text: input.text
    property string placeholder: ""
    property bool secret: false
    property string submitLabel: ""
    signal accepted()
    implicitWidth: Theme.metrics.loginFieldWidth
    implicitHeight: Theme.metrics.controlHeight
    opacity: enabled ? 1 : Theme.metrics.disabledOpacity

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.color.glassBottom
        border.width: input.activeFocus ? Theme.metrics.focusWidth : Theme.space.hairline
        border.color: input.activeFocus ? Theme.color.focus : Theme.color.border
    }
    TextInput {
        id: input
        anchors { left: parent.left; right: submit.visible ? submit.left : parent.right
            verticalCenter: parent.verticalCenter; leftMargin: Theme.space.lg; rightMargin: Theme.space.sm }
        focus: true
        clip: true
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
        onActivated: field.accepted()
    }

    component SubmitButton: Rectangle {
        id: button
        property string label: ""
        signal activated()
        width: Theme.metrics.controlHeight - Theme.space.sm
        height: width
        radius: width / 2
        color: tap.pressed ? Theme.color.accentFillPressed
            : hover.hovered ? Theme.color.accentFillHover : Theme.color.accentFill
        Accessible.role: Accessible.Button
        Accessible.name: label
        LoginIcon { anchors.centerIn: parent; name: "forward"; size: Theme.icons.small; tint: Theme.color.accentText }
        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
        TapHandler { id: tap; onTapped: button.activated() }
    }
}
