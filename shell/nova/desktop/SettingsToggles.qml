// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import qs.nova.theme
import qs.nova.controls

// Lista de interruptores booleanos: [{key, label, description?, fallback?}].
ColumnLayout {
    id: toggles
    property var values: ({})
    property var model: []
    signal toggled(string key, bool value)
    Layout.fillWidth: true
    spacing: Theme.space.xxs
    Repeater {
        model: toggles.model
        NovaSwitch {
            required property var modelData
            Layout.fillWidth: true
            text: modelData.label
            description: modelData.description || ""
            checked: toggles.values[modelData.key] ?? (modelData.fallback || false)
            onClicked: toggles.toggled(modelData.key, checked)
        }
    }
}
