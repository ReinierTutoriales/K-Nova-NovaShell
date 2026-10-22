// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Effects
import "theme"

// Foto circular del usuario sobre un disco de vidrio; sin foto (o sin
// shaders para recortarla en círculo), su inicial sobre el vidrio.
Item {
    id: avatar
    readonly property bool effects: GraphicsInfo.api !== GraphicsInfo.Software
    readonly property bool photoShown: photo.status === Image.Ready && effects
    property string source: ""
    property string name: ""
    property bool current: false
    property int size: Theme.metrics.loginAvatar
    implicitWidth: size
    implicitHeight: size

    // Disco de vidrio transparente: base de la inicial y de las fotos con
    // transparencia (nunca un círculo blanco ni de color).
    LoginGlass {
        anchors.fill: parent
        strong: true
        Text {
            anchors.centerIn: parent
            visible: !avatar.photoShown
            text: avatar.name.length > 0 ? avatar.name.charAt(0).toUpperCase() : "?"
            color: Theme.color.text
            font.family: Theme.font.family
            font.pixelSize: Math.round(avatar.size * Theme.metrics.avatarInitialRatio)
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
        // Canto de luz del vidrio; el seleccionado lleva el anillo del acento.
        border.width: avatar.current ? Theme.metrics.focusWidth : Theme.space.hairline
        border.color: avatar.current ? Theme.color.focus : Theme.color.clearGlassRim
    }
}
