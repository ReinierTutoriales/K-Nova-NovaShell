// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Effects
import "theme"

// Foto circular del usuario; sin foto (o sin shaders para recortarla en
// círculo, renderizador por software), su inicial sobre el acento.
Item {
    id: avatar
    readonly property bool photoShown: photo.status === Image.Ready && GraphicsInfo.api !== GraphicsInfo.Software
    property string source: ""
    property string name: ""
    property bool current: false
    property int size: Theme.metrics.loginAvatar
    implicitWidth: size
    implicitHeight: size

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Theme.color.accentFill
        visible: !avatar.photoShown
        Text {
            anchors.centerIn: parent
            text: avatar.name.length > 0 ? avatar.name.charAt(0).toUpperCase() : "?"
            color: Theme.color.accentText
            font.family: Theme.font.family
            font.pixelSize: Math.round(avatar.size * 0.42)
            font.weight: Font.DemiBold
        }
    }
    Image {
        id: photo
        anchors.fill: parent
        source: avatar.source
        sourceSize: Qt.size(avatar.size * 2, avatar.size * 2)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }
    Rectangle {
        id: mask
        anchors.fill: parent
        radius: width / 2
        visible: false
        layer.enabled: true
    }
    MultiEffect {
        anchors.fill: parent
        source: photo
        visible: avatar.photoShown
        maskEnabled: true
        maskSource: mask
    }
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Theme.color.transparent
        border.width: avatar.current ? Theme.metrics.focusWidth : Theme.space.hairline
        border.color: avatar.current ? Theme.color.focus : Theme.color.border
    }
}
