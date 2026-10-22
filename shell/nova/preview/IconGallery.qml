// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import qs.nova.theme
import qs.nova.icons
import "../icons/IconCatalog.mjs" as Catalog

ColumnLayout {
    id: root
    spacing: Theme.space.lg
    Text {
        text: qsTr("Aplicaciones")
        color: Theme.color.text
        font.family: Theme.font.family
        font.pixelSize: Theme.font.title
        font.weight: Font.DemiBold
    }
    Flow {
        Layout.fillWidth: true
        spacing: Theme.space.sm
        Repeater {
            model: Catalog.applicationNames
            Column {
                required property string modelData
                width: Theme.metrics.iconCell
                spacing: Theme.space.xs
                AppIcon {
                    name: parent.modelData
                    size: Theme.icons.preview
                    anchors.horizontalCenter: parent.horizontalCenter
                    Accessible.role: Accessible.Graphic
                    Accessible.name: Catalog.application(name).label
                }
                Text {
                    width: parent.width
                    text: Catalog.application(parent.modelData).label
                    color: Theme.color.text
                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.small
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
    Text {
        text: qsTr("Símbolos del sistema")
        color: Theme.color.text
        font.family: Theme.font.family
        font.pixelSize: Theme.font.title
        font.weight: Font.DemiBold
    }
    Flow {
        Layout.fillWidth: true
        spacing: Theme.space.sm
        Repeater {
            model: Catalog.symbolNames
            Icon {
                required property string modelData
                name: modelData
                size: Theme.icons.large
                Accessible.role: Accessible.Graphic
                Accessible.name: name
            }
        }
    }
}
