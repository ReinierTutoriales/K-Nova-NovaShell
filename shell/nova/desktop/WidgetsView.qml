// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.nova.theme
import qs.nova.controls

ColumnLayout {
    id: widgets
    property date now: new Date()
    property var metrics: ({available: false})
    spacing: Theme.space.lg
    Text {
        text: widgets.now.toLocaleTimeString(Qt.locale(), "HH:mm")
        font.pixelSize: Theme.font.heading * 2
        font.family: Theme.font.family
        color: Theme.color.text
        Layout.alignment: Qt.AlignHCenter
    }
    Text { text: widgets.now.toLocaleDateString(Qt.locale(), Locale.LongFormat); color: Theme.color.text; font.pixelSize: Theme.font.title; Layout.alignment: Qt.AlignHCenter }
    Text {
        visible: widgets.metrics.available || false
        text: qsTr("CPU %1 % · RAM %2 / %3 GiB").arg(Math.round(widgets.metrics.cpuPercent || 0))
            .arg(((widgets.metrics.memoryUsed || 0) / 1073741824).toFixed(1))
            .arg(((widgets.metrics.memoryTotal || 0) / 1073741824).toFixed(1))
        color: Theme.color.textMuted
        font.pixelSize: Theme.font.body
        Layout.alignment: Qt.AlignHCenter
    }
    DayOfWeekRow { locale: Qt.locale(); Layout.fillWidth: true }
    MonthGrid {
        locale: Qt.locale()
        month: widgets.now.getMonth()
        year: widgets.now.getFullYear()
        Layout.fillWidth: true
        Layout.fillHeight: true
    }
}
