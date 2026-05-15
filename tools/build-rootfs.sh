#!/bin/bash
# Buduje Alpine minimal rootfs dla CrystalOS
# Uzycie: sudo tools/build-rootfs.sh
# Wymaga: apk-tools (Alpine) lub dziala na Linuxie z apk

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROOTFS="$PROJECT_ROOT/build/rootfs"
ALPINE_VERSION="3.21"
ALPINE_MIRROR="https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/releases/x86_64"

echo "=== Budowanie Alpine rootfs ==="

# Tworzy katalog rootfs
mkdir -p "$ROOTFS"

# Sprawdz czy mamy apk (jestesmy na Linuxie/Alpine) czy musimy uzyc tarballa
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
    URL="${ALPINE_MIRROR}/${TARBALL}"

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
cat > "$ROOTFS/etc/apk/repositories" << 'REPOS'
https://dl-cdn.alpinelinux.org/alpine/v3.21/main
https://dl-cdn.alpinelinux.org/alpine/v3.21/community
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

echo "=== Rootfs gotowy: $ROOTFS ==="
