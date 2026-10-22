// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.nova.theme
import qs.nova.controls

ColumnLayout {
    id: widgets
    property date now: new Date()
    spacing: Theme.space.lg
    Text {
        text: widgets.now.toLocaleTimeString(Qt.locale(), "HH:mm")
        font.pixelSize: Theme.font.heading * 2
        font.family: Theme.font.family
        color: Theme.color.text
        Layout.alignment: Qt.AlignHCenter
    }
    Text { text: widgets.now.toLocaleDateString(Qt.locale(), Locale.LongFormat); color: Theme.color.text; font.pixelSize: Theme.font.title; Layout.alignment: Qt.AlignHCenter }
    DayOfWeekRow { locale: Qt.locale(); Layout.fillWidth: true }
    MonthGrid {
        locale: Qt.locale()
        month: widgets.now.getMonth()
        year: widgets.now.getFullYear()
        Layout.fillWidth: true
        Layout.fillHeight: true
    }
}
