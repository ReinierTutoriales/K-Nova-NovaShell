// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import qs.nova.theme

// Uso de CPU y memoria (system.metrics del daemon) en barras simples.
ColumnLayout {
    id: card
    property var metrics: ({available: false})
    readonly property real memoryRatio: metrics.memoryTotal ? metrics.memoryUsed / metrics.memoryTotal : 0
    spacing: Theme.space.sm
    component Meter: ColumnLayout {
        property string label: ""
        property string detail: ""
        property real ratio: 0
        spacing: Theme.space.xxs
        Layout.fillWidth: true
        RowLayout {
            Text { text: parent.parent.label; color: Theme.color.text; font.pixelSize: Theme.font.small; Layout.fillWidth: true }
            Text { text: parent.parent.detail; color: Theme.color.textMuted; font.pixelSize: Theme.font.small; font.features: { "tnum": 1 } }
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Theme.metrics.sliderTrack
            radius: height / 2
            color: Theme.color.sliderTrack
            Rectangle {
                // Redondeado al 2 %: una variación mínima de memoria no repinta
                // el widget. Sin animación: cada 10 s basta un fotograma.
                width: parent.width * Math.round(Math.max(0, Math.min(1, parent.parent.ratio)) * Theme.metrics.metricSteps) / Theme.metrics.metricSteps
                height: parent.height
                radius: height / 2
                color: parent.parent.ratio > 0.85 ? Theme.color.warn : Theme.color.accent
            }
        }
    }
    Text {
        visible: !card.metrics.available
        text: qsTr("Uso del sistema no disponible")
        color: Theme.color.textMuted
        font.pixelSize: Theme.font.small
    }
    Meter {
        visible: card.metrics.available || false
        label: qsTr("CPU")
        detail: qsTr("%1 %").arg(Math.round(card.metrics.cpuPercent || 0))
        ratio: (card.metrics.cpuPercent || 0) / 100
    }
    Meter {
        visible: card.metrics.available || false
        label: qsTr("Memoria")
        detail: qsTr("%1 / %2 GiB").arg(((card.metrics.memoryUsed || 0) / 1073741824).toFixed(1))
            .arg(((card.metrics.memoryTotal || 0) / 1073741824).toFixed(1))
        ratio: card.memoryRatio
    }
}
