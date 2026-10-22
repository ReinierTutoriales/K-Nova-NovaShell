// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell.Services.Notifications
import "DesktopPolicy.mjs" as Policy

QtObject {
    id: backend
    property bool doNotDisturb: false
    property var history: []
    property var banners: []
    readonly property int unread: history.filter(entry => entry.unread).length
    property NotificationServer server: NotificationServer {
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        actionsSupported: true
        onNotification: notification => {
            notification.tracked = true;
            const entry = {id: notification.id, source: Policy.sourceKey(notification),
                name: String(notification.appName).slice(0, 128), icon: notification.appIcon,
                summary: String(notification.summary).slice(0, 256), body: String(notification.body).slice(0, 1024),
                desktopEntry: notification.desktopEntry, time: Date.now(), unread: true,
                timeout: notification.expireTimeout === 0 ? 0 : Math.max(2500, Math.min(10000, notification.expireTimeout > 0 ? notification.expireTimeout : 6000))};
            backend.history = [entry, ...backend.history.filter(item => item.id !== entry.id)].slice(0, 100);
            if (!backend.doNotDisturb) backend.banners = [entry, ...backend.banners.filter(item => item.id !== entry.id)].slice(0, 3);
            const live = server.trackedNotifications.values;
            if (live.length > 100) live[0].expire();
        }
    }
    function native(id) { return server.trackedNotifications.values.find(item => item.id === id) || null; }
    function dismiss(id) {
        const notification = native(id);
        if (notification) notification.dismiss();
        history = history.filter(item => item.id !== id);
        banners = banners.filter(item => item.id !== id);
    }
    function expire(id) {
        banners = banners.filter(item => item.id !== id);
        const notification = native(id);
        if (notification) notification.expire();
    }
    function invoke(id, actionIndex) {
        const notification = native(id);
        if (notification && notification.actions[actionIndex]) {
            notification.actions[actionIndex].invoke();
            if (!notification.resident) dismiss(id);
        }
    }
    function markRead() { history = history.map(item => Object.assign({}, item, {unread: false})); }
    function clear() {
        for (const entry of history.slice()) dismiss(entry.id);
    }
}
