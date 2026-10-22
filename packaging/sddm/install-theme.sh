#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Instala o retira el tema SDDM de NovaShell en el sistema. Es lo ÚNICO de
# NovaShell que necesita root, por eso vive aparte de novactl (que nunca lo
# usa) y no se ejecuta solo: lo lanzas tú con sudo.
#
#   sudo packaging/sddm/install-theme.sh install <tema-preparado>
#   sudo packaging/sddm/install-theme.sh uninstall
#   packaging/sddm/install-theme.sh status
#
# <tema-preparado> es la carpeta que deja `novactl install`
# (~/.local/share/novashell/sddm/novashell). Solo toca:
#   /usr/share/sddm/themes/novashell        (copia del tema)
#   /etc/sddm.conf.d/zz-novashell.conf      ([Theme] Current=novashell)
# No cambia el gestor de sesión activo ni otros archivos de SDDM.
set -euo pipefail

readonly THEME_DIR="${NOVA_SDDM_THEMES:-/usr/share/sddm/themes}/novashell"
# SDDM lee /usr/lib/sddm/sddm.conf.d, luego /etc/sddm.conf.d (orden
# alfabético) y por último /etc/sddm.conf: "zz-" queda detrás de
# kde_settings.conf, el archivo que escribe la página de SDDM de Plasma.
readonly CONF_DIR="${NOVA_SDDM_CONFD:-/etc/sddm.conf.d}"
readonly CONF_FILE="$CONF_DIR/zz-novashell.conf"
readonly MAIN_CONF="${NOVA_SDDM_CONF:-/etc/sddm.conf}"
readonly SYSTEM_CONF_DIR="${NOVA_SDDM_SYSCONFD:-/usr/lib/sddm/sddm.conf.d}"

die() { printf '✘ %s\n' "$*" >&2; exit 1; }

display_manager() {
    local unit
    unit="$(readlink -e "${NOVA_DISPLAY_MANAGER_UNIT:-/etc/systemd/system/display-manager.service}" 2>/dev/null || true)"
    unit="${unit##*/}"
    printf '%s\n' "${unit%.service}"
}

# Tema efectivo y archivo que lo fija, en el mismo orden que SDDM.
effective_theme() {
    local files=() file
    for file in "$SYSTEM_CONF_DIR"/* "$CONF_DIR"/*; do [[ -f "$file" ]] && files+=("$file"); done
    [[ -f "$MAIN_CONF" ]] && files+=("$MAIN_CONF")
    (( ${#files[@]} )) || { printf '(predeterminado)\t-\n'; return; }
    awk '
        FNR == 1 { section = "" }
        /^[[:space:]]*\[/ { section = $0; gsub(/[][[:space:]]/, "", section); next }
        section == "Theme" && /^[[:space:]]*Current[[:space:]]*=/ {
            value = $0; sub(/^[^=]*=[[:space:]]*/, "", value); theme = value; origin = FILENAME
        }
        END { printf "%s\t%s\n", (theme == "" ? "(predeterminado)" : theme), (origin == "" ? "-" : origin) }
    ' "${files[@]}"
}

require_root() {
    [[ "$(id -u)" -eq 0 ]] || die "Hace falta root: sudo $0 $*"
}

validate_source() {
    local source="$1"
    [[ -d "$source" && ! -L "$source" ]] || die "No existe el tema preparado: $source (ejecuta antes: novactl install)"
    if [[ ! -f "$source/metadata.desktop" ]] || ! grep -qx 'Theme-Id=novashell' "$source/metadata.desktop"; then
        die "$source no es el tema SDDM de NovaShell"
    fi
    grep -qx 'QtVersion=6' "$source/metadata.desktop" || die "El tema debe declarar QtVersion=6"
    # Sin enlaces simbólicos ni archivos especiales: el greeter corre como
    # usuario del sistema y no debe seguir rutas fuera del tema.
    if [[ -n "$(find "$source" ! -type f ! -type d -print -quit)" ]]; then
        die "El tema contiene enlaces o archivos especiales; no se instala"
    fi
}

cmd_install() {
    require_root install
    local source="${1:-}"
    [[ -n "$source" ]] || die "Indica la carpeta del tema preparado (ver cabecera del script)"
    validate_source "$source"
    local staging="$THEME_DIR.new"
    rm -rf -- "$staging"
    mkdir -p -- "$(dirname -- "$THEME_DIR")"
    cp -R --no-dereference -- "$source" "$staging"
    chown -R root:root -- "$staging"
    find "$staging" -type d -exec chmod 0755 {} +
    find "$staging" -type f -exec chmod 0644 {} +
    rm -rf -- "$THEME_DIR"
    mv -- "$staging" "$THEME_DIR"
    mkdir -p -- "$(dirname -- "$CONF_FILE")"
    printf '# Creado por NovaShell; bórralo (o usa uninstall) para volver al tema anterior.\n[Theme]\nCurrent=novashell\n' > "$CONF_FILE"
    chmod 0644 -- "$CONF_FILE"
    printf '✔ Tema instalado en %s y activado en %s\n' "$THEME_DIR" "$CONF_FILE"
    local effective
    effective="$(effective_theme)"
    if [[ "${effective%%$'\t'*}" != "novashell" ]]; then
        printf '! %s fija otro tema ([Theme] Current=%s) y tiene prioridad; quita esa línea.\n' \
            "${effective#*$'\t'}" "${effective%%$'\t'*}"
    fi
    local manager
    manager="$(display_manager)"
    if [[ "$manager" != "sddm" ]]; then
        printf '! El gestor de sesión activo es "%s", no SDDM: el tema se verá cuando uses SDDM.\n' "${manager:-desconocido}"
        if [[ "$manager" == "plasmalogin" ]]; then
            printf '  Plasma Login Manager no admite temas. Para cambiar (y volver con los comandos inversos):\n'
            printf '    sudo systemctl disable plasmalogin && sudo systemctl enable sddm\n'
        fi
    fi
}

cmd_uninstall() {
    require_root uninstall
    rm -rf -- "$THEME_DIR" "$THEME_DIR.new"
    rm -f -- "$CONF_FILE"
    printf '✔ Tema retirado; SDDM vuelve a su configuración anterior.\n'
}

cmd_status() {
    local manager
    manager="$(display_manager)"
    printf 'Gestor de sesión: %s\n' "${manager:-desconocido}"
    if [[ -f "$THEME_DIR/metadata.desktop" ]]; then
        printf 'Tema instalado:   %s\n' "$THEME_DIR"
    else
        printf 'Tema instalado:   no\n'
    fi
    local effective
    effective="$(effective_theme)"
    printf 'Tema efectivo:    %s (%s)\n' "${effective%%$'\t'*}" "${effective#*$'\t'}"
}

case "${1:-}" in
    install) shift; cmd_install "$@" ;;
    uninstall) cmd_uninstall ;;
    status) cmd_status ;;
    *) die "Uso: $0 install <tema-preparado> | uninstall | status" ;;
esac
