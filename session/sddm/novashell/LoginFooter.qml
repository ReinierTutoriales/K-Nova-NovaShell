// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import "theme"

// Sesión y teclado a la izquierda; suspender, reiniciar y apagar a la
// derecha, solo si SDDM informa de que el sistema lo permite.
Item {
    id: footer
    property int sessionIndex: 0
    signal sessionSelected(int index)
    implicitHeight: Theme.metrics.controlHeight

    Row {
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        spacing: Theme.space.sm
        LoginButton {
            id: sessionButton
            visible: sessionModel.count > 1
            symbol: "panel"
            text: sessionList.currentItem ? sessionList.currentItem.sessionName : qsTr("Sesión")
            Accessible.name: qsTr("Sesión: %1").arg(text)
            onClicked: sessions.open()
        }
        LoginButton {
            readonly property var layouts: keyboard.layouts || []
            visible: layouts.length > 1
            symbol: "keyboard"
            text: layouts.length > 0 && keyboard.currentLayout >= 0 && keyboard.currentLayout < layouts.length
                ? layouts[keyboard.currentLayout].shortName.toUpperCase() : ""
            Accessible.name: qsTr("Distribución de teclado: %1").arg(text)
            onClicked: keyboard.currentLayout = (keyboard.currentLayout + 1) % layouts.length
        }
    }

    Row {
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        spacing: Theme.space.sm
        LoginButton { visible: sddm.canSuspend; symbol: "sleep"; text: qsTr("Suspender"); onClicked: sddm.suspend() }
        LoginButton { visible: sddm.canReboot; symbol: "restart"; text: qsTr("Reiniciar"); onClicked: sddm.reboot() }
        LoginButton { visible: sddm.canPowerOff; symbol: "power"; text: qsTr("Apagar"); onClicked: sddm.powerOff() }
    }

    Popup {
        id: sessions
        parent: sessionButton
        y: -height - Theme.space.sm
        width: Math.max(sessionButton.width, Theme.metrics.loginFieldWidth)
        height: Math.min(sessionList.contentHeight, Theme.metrics.controlHeight * 8) + padding * 2
        padding: Theme.space.xs
        focus: true
        background: LoginGlass { menu: true; radius: Theme.radius.lg }
        enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.motion.fast } }
        exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.motion.fast } }
        contentItem: ListView {
            id: sessionList
            clip: true
            model: sessionModel
            currentIndex: footer.sessionIndex
            keyNavigationEnabled: true
            delegate: ItemDelegate {
                required property int index
                required property string name
                readonly property string sessionName: name
                width: ListView.view.width
                height: Theme.metrics.controlHeight
                highlighted: ListView.isCurrentItem
                onClicked: { footer.sessionSelected(index); sessions.close(); }
                background: Rectangle {
                    radius: Theme.radius.md
                    color: parent.highlighted ? Theme.color.selection
                        : parent.hovered ? Theme.color.hover : Theme.color.transparent
                }
                contentItem: Text {
                    text: name
                    color: Theme.color.text
                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.body
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
            }
        }
    }
}
