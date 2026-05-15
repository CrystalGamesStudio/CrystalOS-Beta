#!/bin/bash
# Buduje Alpine minimal rootfs dla CrystalOS
# Uzycie: sudo tools/build-rootfs.sh
# Wymaga: apk-tools (Alpine) lub dziala na Linuxie z apk

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROOTFS="$PROJECT_ROOT/build/rootfs"
ALPINE_VERSION="3.21"
ALPINE_MIRROR="https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}"
ALPINE_REPO_MAIN="$ALPINE_MIRROR/main"
ALPINE_REPO_COMMUNITY="$ALPINE_MIRROR/community"
CACHEDIR="$PROJECT_ROOT/build/cache"

echo "=== Budowanie Alpine rootfs ==="

# Tworzy katalog rootfs
mkdir -p "$ROOTFS" "$CACHEDIR"

# --- Pobierz apk.static na Linuxie (potrzebny do instalacji pakietow) ---
APK_STATIC=""
if ! command -v apk &>/dev/null && [[ "$(uname -s)" == "Linux" ]]; then
    if [[ ! -x "$CACHEDIR/apk.static" ]]; then
        echo "Pobieranie apk.static..."
        APK_STATIC_PKG=$(curl -sL "${ALPINE_REPO_MAIN}/x86_64/" | \
            grep -oP 'apk-tools-static-[0-9][^"]+\.apk' | head -1)
        if [[ -n "$APK_STATIC_PKG" ]]; then
            curl -sL "${ALPINE_REPO_MAIN}/x86_64/${APK_STATIC_PKG}" | \
                tar -xz -C "$CACHEDIR" sbin/apk.static 2>/dev/null
            chmod +x "$CACHEDIR/sbin/apk.static" 2>/dev/null
            mv "$CACHEDIR/sbin/apk.static" "$CACHEDIR/apk.static" 2>/dev/null || true
        fi
    fi
    if [[ -x "$CACHEDIR/apk.static" ]]; then
        APK_STATIC="$CACHEDIR/apk.static"
        echo "Znaleziono apk.static"
    fi
fi
if command -v apk &>/dev/null; then
    echo "Znaleziono apk - uzywam alpine-make-rootfs"
    if [[ -x "$PROJECT_ROOT/tools/alpine-make-rootfs" ]]; then
        "$PROJECT_ROOT/tools/alpine-make-rootfs" "$ROOTFS" --mirror "$ALPINE_MIRROR" --version "$ALPINE_VERSION"
    else
        apk add --root "$ROOTFS" --initdb --allow-untrusted alpine-base
    fi
else
    echo "Brak apk - pobieram minirootfs tarball"
    TARBALL="alpine-minirootfs-${ALPINE_VERSION}.0-x86_64.tar.gz"
    URL="${ALPINE_MIRROR}/releases/x86_64/${TARBALL}"

    # Pobierz tarball (z cache jesli istnieje)
    CACHEDIR="$PROJECT_ROOT/build/cache"
    mkdir -p "$CACHEDIR"

    if [[ ! -f "$CACHEDIR/$TARBALL" ]]; then
        echo "Pobieranie $URL..."
        # Sprobuj z dokladna wersja, potem z -nostatic
        if ! curl -fL -o "$CACHEDIR/$TARBALL" "$URL" 2>/dev/null; then
            # Sprobuj z najnowszym dostepnym minor
            echo "Probuje alternatywny URL..."
            ACTUAL_URL=$(curl -sL "https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/releases/x86_64/" | \
                grep -oP 'alpine-minirootfs-[0-9]+\.[0-9]+\.[0-9]+-x86_64\.tar\.gz' | head -1)
            if [[ -n "$ACTUAL_URL" ]]; then
                curl -fL -o "$CACHEDIR/$TARBALL" \
                    "https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/releases/x86_64/$ACTUAL_URL"
            fi
        fi
    fi

    if [[ -f "$CACHEDIR/$TARBALL" ]]; then
        echo "Wypakowywanie minirootfs..."
        tar xzf "$CACHEDIR/$TARBALL" -C "$ROOTFS"
    else
        echo "BLAD: Nie udalo sie pobrac minirootfs. Buduj na Linuxie (CI) lub zainstaluj apk."
        exit 1
    fi
fi

# Tworzy wymagane katalogi
mkdir -p "$ROOTFS"/{dev,proc,sys,run,tmp,var/cache/apk}

# Konfiguruje hostname
echo "crystalos" > "$ROOTFS/etc/hostname"
echo "127.0.0.1 crystalos localhost" > "$ROOTFS/etc/hosts"

# Konfiguruje komunikat powitalny
cat > "$ROOTFS/etc/issue" << 'EOF'

  ██████╗██████╗ ███████╗ █████╗ ████████╗ ██████╗██╗  ██╗
 ██╔════╝██╔══██╗██╔════╝██╔══██╗╚══██╔══╝██╔════╝██║  ██║
 ██║     ██████╔╝█████╗  ███████║   ██║   ██║     ███████║
 ██║     ██╔══██╗██╔══╝  ██╔══██║   ██║   ██║     ██╔══██║
 ╚██████╗██║  ██║███████╗██║  ██║   ██║   ╚██████╗██║  ██║
  ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝

    CrystalOS Beta - Welcome!
    Zaloguj sie jako: root (bez hasla)

EOF

# Konfiguruje profil powitalny
cat > "$ROOTFS/etc/profile.d/crystalos-welcome.sh" << 'WELCOME'
echo ""
echo "Witaj w CrystalOS Beta!"
echo "Dostepne komendy: ls, cat, pwd, dmesg, mount, df"
echo ""
WELCOME
chmod +x "$ROOTFS/etc/profile.d/crystalos-welcome.sh"

# Ustawia haslo root na puste (logowanie bez hasla)
# Usuwa stare haslo jesli istnieje
if [[ -f "$ROOTFS/etc/shadow" ]]; then
    sed -i.bak 's|^root:[^:]*:|root::|' "$ROOTFS/etc/shadow" && rm -f "$ROOTFS/etc/shadow.bak"
fi

# Konfiguruje console i serial
cat > "$ROOTFS/etc/inittab" << 'INITTAB'
# /etc/inittab
::sysinit:/sbin/openrc sysinit
::sysinit:/sbin/openrc boot
::wait:/sbin/openrc default

# Set up a couple of getty's
tty1::respawn:/sbin/getty 38400 tty1
tty2::respawn:/sbin/getty 38400 tty2
ttyS0::respawn:/sbin/getty 115200 ttyS0

# Stuff to do for the 3-finger salute
::ctrlaltdel:/sbin/reboot

# Stuff to do before rebooting
::shutdown:/sbin/openrc shutdown
INITTAB

# Konfiguruje siec (dhcp na eth0)
mkdir -p "$ROOTFS/etc/network"
cat > "$ROOTFS/etc/network/interfaces" << 'NET'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
NET

# Konfiguruje apk repositories
cat > "$ROOTFS/etc/apk/repositories" << REPOS
${ALPINE_REPO_MAIN}
${ALPINE_REPO_COMMUNITY}
REPOS

# Tworzy /init - punkt wejscia dla initramfs boot
cat > "$ROOTFS/init" << 'INITSCRIPT'
#!/bin/sh
# CrystalOS init - uruchamiany przez kernel z initramfs

# Montuj wirtualne filesystems
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev
mkdir -p /dev/pts
mount -t devpts devpts /dev/pts
mount -t tmpfs tmpfs /run
mount -t tmpfs tmpfs /tmp

# Ustaw hostname
hostname crystalos

# Uruchom init
exec /sbin/init
INITSCRIPT
chmod +x "$ROOTFS/init"

# Instaluje Xorg i sterowniki graficzne
echo "Instalacja Xorg..."
XORG_PACKAGES="xorg-server xinit xrandr xterm \
    xf86-input-keyboard xf86-input-mouse xf86-input-libinput \
    xf86-video-modesetting"

if command -v apk &>/dev/null; then
    apk --root "$ROOTFS" --allow-untrusted --no-cache \
        --repository "$ALPINE_REPO_MAIN" add $XORG_PACKAGES
elif [[ -n "$APK_STATIC" ]]; then
    $APK_STATIC --root "$ROOTFS" --allow-untrusted --no-cache \
        --repository "$ALPINE_REPO_MAIN" \
        --repository "$ALPINE_REPO_COMMUNITY" add $XORG_PACKAGES
elif [[ -x "$ROOTFS/sbin/apk" ]]; then
    mount -t proc proc "$ROOTFS/proc" 2>/dev/null || true
    mount -t sysfs sysfs "$ROOTFS/sys" 2>/dev/null || true
    mount -o bind /dev "$ROOTFS/dev" 2>/dev/null || true
    chroot "$ROOTFS" apk add --no-cache $XORG_PACKAGES
    umount "$ROOTFS/dev" 2>/dev/null || true
    umount "$ROOTFS/sys" 2>/dev/null || true
    umount "$ROOTFS/proc" 2>/dev/null || true
else
    echo "UWAGA: Nie mozna zainstalowac Xorg - brak apk."
    echo "Na Linuxie: skrypt automatycznie pobierze apk.static"
    echo "Na macOS: buduj przez CI lub na Linuxie"
fi

# Tworzy xorg.conf dla virtio-gpu + modesetting
echo "Konfiguracja xorg.conf..."
mkdir -p "$ROOTFS/etc/X11"
cat > "$ROOTFS/etc/X11/xorg.conf" << 'XORGCONF'
Section "Device"
    Identifier "Virtio-GPU"
    Driver "modesetting"
    BusID "auto"
EndSection

Section "Screen"
    Identifier "Default Screen"
    Device "Virtio-GPU"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
        Modes "1920x1080" "1024x768"
    EndSubSection
EndSection

Section "InputClass"
    Identifier "Keyboard"
    MatchIsKeyboard "yes"
    Driver "libinput"
EndSection

Section "InputClass"
    Identifier "Mouse"
    MatchIsPointer "yes"
    Driver "libinput"
EndSection
XORGCONF

# Tworzy .xinitrc - uruchamia xterm po starcie X
echo "Konfiguracja .xinitrc..."
cat > "$ROOTFS/root/.xinitrc" << 'XINITRC'
#!/bin/sh
xterm -geometry 80x24+0+0 &
exec xterm -geometry 80x24+0+400
XINITRC
chmod +x "$ROOTFS/root/.xinitrc"

echo "=== Rootfs gotowy: $ROOTFS ==="
