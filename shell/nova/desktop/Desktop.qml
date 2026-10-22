// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.nova.services
import qs.nova.theme

Scope {
    id: desktop
    required property var output
    Dock { output: desktop.output }
    DesktopPanel {
        output: desktop.output; kind: "launcher"; title: qsTr("Aplicaciones")
        panelWidth: Theme.metrics.launcherWidth; panelHeight: Theme.metrics.launcherHeight
        content: Component { LauncherView {
            applications: Platform.applications; loading: Platform.applicationsLoading
            iconResolver: name => Platform.iconUrl(name)
            onLaunchRequested: id => { Platform.launch(id); ShellState.close(); }
            onPinRequested: id => Platform.preferences.togglePin(id)
            onRefreshRequested: Platform.reloadApplications()
        } }
    }
    DesktopPanel {
        output: desktop.output; kind: "controls"; title: qsTr("Centro de control")
        content: Component { ControlCenterView {
            backend: Platform.desktop
            doNotDisturb: Platform.preferences.values.doNotDisturb || false
            onDoNotDisturbRequested: value => Platform.preferences.patch({doNotDisturb: value})
            onSettingsRequested: ShellState.toggle("settings", desktop.output)
        } }
    }
    DesktopPanel {
        output: desktop.output; kind: "notifications"; title: qsTr("Notificaciones")
        content: Component { NotificationView { backend: Platform.notifications; iconResolver: name => Platform.iconUrl(name); onSettingsRequested: ShellState.toggle("settings", desktop.output) } }
    }
    DesktopPanel {
        output: desktop.output; kind: "settings"; title: qsTr("Preferencias")
        content: Component { SettingsView {
            values: Platform.preferences.values; connected: Platform.connected
            onPatchRequested: patch => Platform.preferences.patch(patch)
            onWallpaperRequested: url => Platform.call("wallpaper.set", {url: url, screen: Quickshell.screens.indexOf(desktop.output)})
        } }
    }
    DesktopPanel {
        output: desktop.output; kind: "overview"; title: qsTr("Ventanas y escritorios")
        panelWidth: Theme.metrics.launcherWidth
        content: Component { OverviewView {
            windows: Platform.windows; desktops: Platform.desktops
            currentDesktop: Platform.currentDesktop; available: Platform.windowBridgeAvailable
            onActionRequested: (action, id) => { Platform.windowAction(action, id); if (action === "activate") ShellState.close(); }
        } }
    }
    DesktopPanel {
        output: desktop.output; kind: "clipboard"; title: qsTr("Portapapeles")
        content: Component { ClipboardView {
            entries: Platform.desktop.clipboardHistory
            enabledHistory: Platform.desktop.clipboardEnabled
            onCopyRequested: text => Platform.desktop.copy(text)
            onClearRequested: Platform.desktop.clearClipboard()
        } }
    }
    DesktopPanel {
        output: desktop.output; kind: "widgets"; title: qsTr("Hoy")
        content: Component { WidgetsView { SystemClock { id: clock; precision: SystemClock.Minutes } now: clock.date; metrics: Platform.metrics } }
    }
    PanelWindow {
        id: banners
        screen: desktop.output
        visible: !!Platform.notifications && Platform.notifications.banners.length > 0 && ShellState.panel !== "notifications"
        anchors { top: true; right: true }
        margins { top: Theme.barHeight + Theme.space.md; right: Theme.space.md }
        implicitWidth: Theme.metrics.notificationWidth
        implicitHeight: notices.implicitHeight
        color: Theme.color.transparent
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "novashell-notifications"
        WlrLayershell.layer: WlrLayer.Overlay
        Column {
            id: notices
            width: parent.width
            spacing: Theme.space.md
            Repeater {
                model: Platform.notifications ? Platform.notifications.banners : []
                NotificationCard {
                    required property var modelData
                    entry: modelData
                    iconSource: Platform.iconUrl(modelData.icon)
                    width: notices.width
                    actions: Platform.notifications.native(entry.id)?.actions || []
                    onDismissRequested: Platform.notifications.dismiss(entry.id)
                    onActionRequested: index => Platform.notifications.invoke(entry.id, index)
                    Timer { interval: modelData.timeout || 6000; running: modelData.timeout !== 0; onTriggered: Platform.notifications.expire(modelData.id) }
                }
            }
        }
    }
}
