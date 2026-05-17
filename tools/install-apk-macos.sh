#!/bin/bash
# Instaluje pakiety Alpine do rootfs na macOS bez Docker/chroot
# Pakiety .apk to po prostu archiwa tar.gz
# Uzycie: bash tools/install-apk-macos.sh

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROOTFS="$PROJECT_ROOT/build/rootfs"
CACHEDIR="$PROJECT_ROOT/build/cache/apk-pkgs"
ALPINE_VERSION="3.21"
REPO_MAIN="https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/main/x86_64"
REPO_COMM="https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/community/x86_64"

mkdir -p "$CACHEDIR"

# Pakiety XFCE do zainstalowania
PACKAGES="xfce4 xfwm4 xfce4-panel xfdesktop xfce4-session xfce4-settings xfce4-appfinder"

echo "=== Instalacja pakietow XFCE na macOS ==="
echo ""

# Pobierz i wypakuj APKINDEX z obu repozytoriow
fetch_index() {
    local repo_url="$1"
    local name="$2"
    local idx="$CACHEDIR/APKINDEX-$name"
    if [[ ! -f "$idx" ]]; then
        echo "Pobieranie indeksu $name..."
        curl -sL "$repo_url/APKINDEX.tar.gz" | tar xz -O APKINDEX > "$idx" 2>/dev/null
    fi
}

fetch_index "$REPO_MAIN" "main"
fetch_index "$REPO_COMM" "community"

# Znajdz nazwe pliku pakietu w indeksie
find_package() {
    local pkg="$1"
    for idx in "$CACHEDIR/APKINDEX-main" "$CACHEDIR/APKINDEX-community"; do
        local line=$(grep -A10 "^P:${pkg}$" "$idx" | grep "^V:" | head -1)
        if [[ -n "$line" ]]; then
            local ver="${line#V:}"
            echo "${pkg}-${ver}.apk"
            return 0
        fi
    done
    return 1
}

# Pobierz i rozpakuj jeden pakiet
install_package() {
    local pkg="$1"
    local filename

    if ! filename=$(find_package "$pkg"); then
        echo "  POMIJAM: $pkg (nie znaleziono w indeksie)"
        return 0
    fi

    # Najpierw sprobuj community, potem main
    local cached="$CACHEDIR/$filename"
    if [[ ! -f "$cached" ]]; then
        echo "  Pobieranie: $filename"
        curl -sL "$REPO_COMM/$filename" -o "$cached" 2>/dev/null || \
        curl -sL "$REPO_MAIN/$filename" -o "$cached" 2>/dev/null || {
            echo "  BLAD pobierania: $filename"
            return 1
        }
    fi

    # Rozpakuj do rootfs (apk = tar.gz)
    tar xzf "$cached" -C "$ROOTFS" 2>/dev/null || true
    echo "  OK: $pkg"
}

# Kluczowe zaleznosci XFCE (bez nich XFCE sie nie uruchomi)
DEPENDENCIES="libxfce4util libxfce4ui xfconf libwnck3 exo garcon thunar-volman \
    dbus dbus-glib intltool gtk+3.0 pango atk harfbuzz cairo gdk-pixbuf \
    libx11 libxext libxrandr libxfixes libxdamage libxcomposite \
    libxinerama libxcursor libxi libxrender libxtst \
    fontconfig freetype shared-mime-info hicolor-icon-theme \
    adwaita-icon-theme desktop-file-utils \
    polkit polkit-libs accountsservice \
    gnome-keyring libsecret"

echo "Instalacja zaleznosci..."
for pkg in $DEPENDENCIES; do
    install_package "$pkg"
done

echo ""
echo "Instalacja pakietow XFCE..."
for pkg in $PACKAGES; do
    install_package "$pkg"
done

echo ""
echo "=== Pakiety rozpakowane do $ROOTFS ==="
