// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick

QtObject {
    id: state
    property string panel: ""
    property var screen: null
    function toggle(name, output) {
        if (panel === name && screen === output) close();
        else { screen = output; panel = name; }
    }
    function close() { panel = ""; }
}
