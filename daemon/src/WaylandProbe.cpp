// SPDX-License-Identifier: GPL-3.0-or-later
#include "WaylandProbe.h"

#include <QJsonArray>

#include <wayland-client.h>

#include <cerrno>
#include <poll.h>

namespace nova {

namespace {

// Tope defensivo: un compositor real anuncia ~40-90 globals.
constexpr qsizetype MaxInterfaces = 256;

struct ProbeState {
    QStringList interfaces;
    bool done = false;
};

void onGlobal(void *data, wl_registry *, uint32_t, const char *interface, uint32_t)
{
    auto *state = static_cast<ProbeState *>(data);
    if (state->interfaces.size() < MaxInterfaces) {
        state->interfaces.append(QString::fromLatin1(interface));
    }
}

void onGlobalRemove(void *, wl_registry *, uint32_t) {}

const wl_registry_listener RegistryListener = {onGlobal, onGlobalRemove};

void onSyncDone(void *data, wl_callback *, uint32_t)
{
    static_cast<ProbeState *>(data)->done = true;
}

const wl_callback_listener SyncListener = {onSyncDone};

// Equivalente a wl_display_roundtrip pero con plazo: roundtrip bloquea sin límite.
bool dispatchUntilDone(wl_display *display, const ProbeState &state,
                       std::chrono::milliseconds timeout, QString *error)
{
    const auto deadline = std::chrono::steady_clock::now() + timeout;
    while (!state.done) {
        while (wl_display_prepare_read(display) != 0) {
            if (wl_display_dispatch_pending(display) < 0) {
                *error = QStringLiteral("error al despachar eventos");
                return false;
            }
            if (state.done) {
                return true;
            }
        }
        if (wl_display_flush(display) < 0 && errno != EAGAIN) {
            wl_display_cancel_read(display);
            *error = QStringLiteral("error al enviar al compositor");
            return false;
        }
        const auto remaining = std::chrono::duration_cast<std::chrono::milliseconds>(
            deadline - std::chrono::steady_clock::now());
        if (remaining.count() <= 0) {
            wl_display_cancel_read(display);
            *error = QStringLiteral("el compositor no respondió a tiempo");
            return false;
        }
        pollfd fd{wl_display_get_fd(display), POLLIN, 0};
        const int ready = ::poll(&fd, 1, static_cast<int>(remaining.count()));
        if (ready <= 0) {
            wl_display_cancel_read(display);
            if (ready < 0 && errno == EINTR) {
                continue;
            }
            *error = QStringLiteral("el compositor no respondió a tiempo");
            return false;
        }
        if (wl_display_read_events(display) < 0
            || wl_display_dispatch_pending(display) < 0) {
            *error = QStringLiteral("error al leer del compositor");
            return false;
        }
    }
    return true;
}

} // namespace

WaylandGlobals probeWaylandGlobals(std::chrono::milliseconds timeout)
{
    WaylandGlobals out;
    if (qEnvironmentVariableIsEmpty("WAYLAND_DISPLAY")) {
        out.error = QStringLiteral("WAYLAND_DISPLAY no está definido");
        return out;
    }
    wl_display *display = wl_display_connect(nullptr);
    if (!display) {
        out.error = QStringLiteral("no se pudo conectar al compositor");
        return out;
    }

    ProbeState state;
    wl_registry *registry = wl_display_get_registry(display);
    wl_registry_add_listener(registry, &RegistryListener, &state);
    wl_callback *sync = wl_display_sync(display);
    wl_callback_add_listener(sync, &SyncListener, &state);

    QString error;
    if (dispatchUntilDone(display, state, timeout, &error)) {
        state.interfaces.removeDuplicates();
        state.interfaces.sort();
        out.available = true;
        out.interfaces = std::move(state.interfaces);
    } else {
        out.error = error;
    }

    wl_callback_destroy(sync);
    wl_registry_destroy(registry);
    wl_display_disconnect(display);
    return out;
}

QJsonObject compositorCapabilities(const WaylandGlobals &globals)
{
    const auto has = [&](const char *name) {
        return globals.interfaces.contains(QLatin1String(name));
    };
    QJsonObject result{
        {QStringLiteral("available"), globals.available},
        // Protocolo estándar que usa Quickshell BackgroundEffect.
        {QStringLiteral("backgroundEffect"), has("ext_background_effect_manager_v1")},
        // Protocolo privado de KDE; informativo: Quickshell no lo usa.
        {QStringLiteral("kdeBlur"), has("org_kde_kwin_blur_manager")},
        {QStringLiteral("layerShell"), has("zwlr_layer_shell_v1")},
        {QStringLiteral("fractionalScale"), has("wp_fractional_scale_manager_v1")},
        {QStringLiteral("interfaces"), QJsonArray::fromStringList(globals.interfaces)},
    };
    if (!globals.available) {
        result.insert(QStringLiteral("reason"), globals.error);
    }
    return result;
}

} // namespace nova
