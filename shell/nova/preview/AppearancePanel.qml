// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.nova.theme
import qs.nova.controls

GlassSurface {
    id: root
    cornerRadius: Theme.radius.xl
    ScrollView {
        id: scroll
        anchors.fill: parent
        anchors.margins: Theme.space.xl
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ColumnLayout {
            width: scroll.availableWidth
            spacing: Theme.space.lg
            Text {
                text: qsTr("NovaShell")
                color: Theme.color.text
                font.family: Theme.font.family
                font.pixelSize: Theme.font.heading
                font.weight: Font.DemiBold
            }
            Text {
                text: qsTr("Iconos por capas, superficies translúcidas y contraste adaptable.")
                color: Theme.color.textMuted
                font.family: Theme.font.family
                font.pixelSize: Theme.font.body
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            AppearanceOptions { Layout.fillWidth: true }
            IconGallery { Layout.fillWidth: true }
            Text {
                text: qsTr("Los cambios de esta ventana duran la sesión. El desenfoque real requiere soporte del compositor; la transparencia por sí sola no lo proporciona.")
                color: Theme.color.textMuted
                font.family: Theme.font.family
                font.pixelSize: Theme.font.small
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }
}
