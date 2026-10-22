// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.nova.theme

// Fecha grande y mes actual con el día de hoy resaltado.
RowLayout {
    id: card
    property date now: new Date()
    spacing: Theme.space.lg
    ColumnLayout {
        spacing: Theme.space.xxs
        Layout.alignment: Qt.AlignTop
        Text {
            text: card.now.getDate()
            color: Theme.color.text
            font.family: Theme.font.family
            font.pixelSize: Theme.font.display
            font.weight: Font.DemiBold
        }
        Text {
            text: card.now.toLocaleDateString(Qt.locale(), "dddd")
            color: Theme.color.textMuted
            font.family: Theme.font.family
            font.pixelSize: Theme.font.small
        }
    }
    ColumnLayout {
        spacing: Theme.space.xxs
        Text {
            text: card.now.toLocaleDateString(Qt.locale(), "MMMM yyyy")
            color: Theme.color.text
            font.family: Theme.font.family
            font.pixelSize: Theme.font.body
            font.weight: Font.DemiBold
            Layout.alignment: Qt.AlignHCenter
        }
        DayOfWeekRow {
            locale: Qt.locale()
            Layout.fillWidth: true
            delegate: Text {
                required property string shortName
                text: shortName
                color: Theme.color.textMuted
                font.family: Theme.font.family
                font.pixelSize: Theme.font.small
                horizontalAlignment: Text.AlignHCenter
            }
        }
        MonthGrid {
            locale: Qt.locale()
            month: card.now.getMonth()
            year: card.now.getFullYear()
            Layout.fillWidth: true
            delegate: Rectangle {
                required property var model
                readonly property bool today: model.today
                implicitWidth: Theme.metrics.calendarCell
                implicitHeight: Theme.metrics.calendarCell
                radius: width / 2
                color: today ? Theme.color.accent : Theme.color.transparent
                opacity: model.month === card.now.getMonth() ? 1 : 0
                Text {
                    anchors.centerIn: parent
                    text: parent.model.day
                    color: parent.today ? Theme.color.accentText : Theme.color.text
                    font.family: Theme.font.family
                    font.pixelSize: Theme.font.small
                    font.features: { "tnum": 1 }
                }
            }
        }
    }
}
