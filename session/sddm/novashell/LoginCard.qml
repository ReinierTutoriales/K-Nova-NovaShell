// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "theme"

// Usuario y contraseña. Varios usuarios: fila de avatares para elegir.
// Sin lista de usuarios (o usuario oculto): campo de nombre.
FocusScope {
    id: card
    objectName: "loginCard"
    property int sessionIndex: 0
    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property string userName: ""
    property string realName: ""
    property string userIcon: ""
    property bool needsPassword: true
    property bool busy: false
    property string message: ""
    readonly property bool manualUser: userModel.count === 0
    readonly property string loginName: manualUser ? manualName.text : userName

    implicitWidth: Theme.metrics.loginFieldWidth + Theme.space.xxl * 2
    implicitHeight: content.implicitHeight

    function submit() {
        if (busy || loginName === "") return;
        busy = true;
        message = "";
        sddm.login(loginName, password.text, sessionIndex);
    }
    function failed() {
        busy = false;
        message = qsTr("Contraseña incorrecta");
        password.text = "";
        password.forceActiveFocus();
        shake.restart();
    }
    function inform(text) { message = text; }

    // La selección vive en la lista (teclado, puntero o userIndex desde fuera).
    onUserIndexChanged: users.currentIndex = userIndex
    Keys.onEscapePressed: { password.text = ""; message = ""; }

    Column {
        id: content
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Theme.space.md
        transform: Translate { id: offset }

        ListView {
            id: users
            objectName: "users"
            visible: userModel.count > 1
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(contentWidth, Theme.metrics.loginFieldWidth * 2)
            height: Theme.metrics.loginAvatarSmall
            orientation: ListView.Horizontal
            spacing: Theme.space.md
            model: userModel
            interactive: contentWidth > width
            // Tab llega a la fila; las flechas cambian de usuario.
            activeFocusOnTab: true
            keyNavigationEnabled: true
            Component.onCompleted: currentIndex = card.userIndex
            onCurrentIndexChanged: card.userIndex = currentIndex
            Keys.onReturnPressed: password.forceActiveFocus()
            KeyNavigation.tab: password
            delegate: LoginAvatar {
                id: entry
                required property int index
                required property var model
                readonly property bool selected: ListView.isCurrentItem
                readonly property string label: model.realName !== "" ? model.realName : model.name
                size: Theme.metrics.loginAvatarSmall
                source: model.icon
                name: label
                current: selected
                opacity: selected ? 1 : Theme.metrics.inactiveOpacity
                scale: selected ? 1 : Theme.metrics.inactiveScale
                Behavior on scale { NumberAnimation { duration: Theme.motion.fast; easing.type: Easing.OutCubic } }
                function choose() { card.pick(model.name, model.realName, model.icon, model.needsPassword); }
                onSelectedChanged: if (selected) choose()
                Component.onCompleted: if (selected) choose()
                Accessible.role: Accessible.Button
                Accessible.name: label
                TapHandler { onTapped: { users.currentIndex = index; password.forceActiveFocus(); } }
            }
        }

        LoginAvatar {
            visible: userModel.count <= 1
            anchors.horizontalCenter: parent.horizontalCenter
            source: card.manualUser ? "" : card.userIcon
            name: card.manualUser ? manualName.text : (card.realName !== "" ? card.realName : card.userName)
        }

        Text {
            visible: !card.manualUser
            anchors.horizontalCenter: parent.horizontalCenter
            text: card.realName !== "" ? card.realName : card.userName
            color: Theme.color.text
            font.family: Theme.font.family
            font.pixelSize: Theme.font.title
            font.weight: Font.DemiBold
        }

        LoginField {
            id: manualName
            anchors.horizontalCenter: parent.horizontalCenter
            visible: card.manualUser
            placeholder: qsTr("Usuario")
            focus: card.manualUser
            KeyNavigation.tab: password
            onAccepted: password.forceActiveFocus()
        }

        LoginField {
            id: password
            objectName: "password"
            anchors.horizontalCenter: parent.horizontalCenter
            visible: card.needsPassword
            secret: true
            placeholder: qsTr("Contraseña")
            enabled: !card.busy
            focus: !card.manualUser
            submitLabel: qsTr("Entrar")
            onAccepted: card.submit()
        }

        LoginButton {
            visible: !card.needsPassword
            anchors.horizontalCenter: parent.horizontalCenter
            text: qsTr("Entrar")
            prominent: true
            enabled: !card.busy
            onClicked: card.submit()
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Theme.metrics.loginFieldWidth
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: card.busy ? qsTr("Verificando…")
                : card.message !== "" ? card.message
                : keyboard.capsLock ? qsTr("Bloq Mayús está activado") : " "
            color: card.message !== "" && !card.busy ? Theme.color.error : Theme.color.textMuted
            font.family: Theme.font.family
            font.pixelSize: Theme.font.small
            Accessible.role: Accessible.StaticText
            Accessible.name: text
        }
    }

    function pick(name, real, icon, needs) {
        userName = name; realName = real; userIcon = icon; needsPassword = needs;
        message = "";
    }

    // Contraseña incorrecta: sacudida breve (sin ella con menos movimiento).
    SequentialAnimation {
        id: shake
        loops: Theme.reduceMotion ? 0 : 1
        NumberAnimation { target: offset; property: "x"; to: Theme.space.md; duration: Theme.motion.fast / 2 }
        NumberAnimation { target: offset; property: "x"; to: -Theme.space.md; duration: Theme.motion.fast }
        NumberAnimation { target: offset; property: "x"; to: 0; duration: Theme.motion.fast / 2 }
    }
}
