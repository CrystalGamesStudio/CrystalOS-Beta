#!/bin/bash
# Buduje bootowalne ISO CrystalOS z GRUB
# Uzycie: sudo tools/build-iso.sh
# Wymaga: grub-mkrescue, xorriso, mksquashfs (Linux)

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROOTFS="$PROJECT_ROOT/build/rootfs"
ISO_DIR="$PROJECT_ROOT/build/iso"
ISO_FILE="$PROJECT_ROOT/build/crystalos-beta.iso"
KERNEL="$PROJECT_ROOT/arch/x86/boot/bzImage"

echo "=== Budowanie ISO CrystalOS ==="

# Sprawdz zaleznosci
for CMD in grub-mkrescue xorriso mksquashfs; do
    if ! command -v "$CMD" &>/dev/null; then
        echo "BLAD: $CMD nie jest zainstalowane"
        echo "Zainstaluj: sudo apt install grub-pc-bin xorriso squashfs-tools"
        exit 1
    fi
done

# Sprawdz czy rootfs istnieje
if [[ ! -d "$ROOTFS/bin" ]]; then
    echo "BLAD: rootfs nie istnieje. Uruchom najpierw tools/build-rootfs.sh"
    exit 1
fi

# Sprawdz czy kernel istnieje
if [[ ! -f "$KERNEL" ]]; then
    echo "BLAD: bzImage nie istnieje. Uruchom najpierw make (lub pobierz z CI)"
    exit 1
fi

# Przygotuj strukture ISO
echo "Przygotowywanie struktury ISO..."
rm -rf "$ISO_DIR"
mkdir -p "$ISO_DIR/boot/grub"

# Kopiuj kernel do ISO
cp "$KERNEL" "$ISO_DIR/boot/vmlinuz"
echo "Kernel skopiowany: $(ls -lh "$ISO_DIR/boot/vmlinuz" | awk '{print $5}')"

# Tworzy initramfs z rootfs (cpio archive)
echo "Tworzenie initramfs..."
INITRD="$ISO_DIR/boot/initramfs"
(cd "$ROOTFS" && find . | cpio -o -H newc 2>/dev/null | gzip -9) > "$INITRD"
echo "Initramfs rozmiar: $(ls -lh "$INITRD" | awk '{print $5}')"

# Generuj GRUB config
cat > "$ISO_DIR/boot/grub/grub.cfg" << 'GRUBCFG'
set timeout=3
set default=0

menuentry "CrystalOS Beta" {
    linux /boot/vmlinuz root=/dev/ram0 init=/sbin/init console=ttyS0,115200 console=tty0
    initrd /boot/initramfs
}

menuentry "CrystalOS Beta (debug)" {
    linux /boot/vmlinuz root=/dev/ram0 init=/sbin/init console=ttyS0,115200 console=tty0 debug loglevel=7
    initrd /boot/initramfs
}
GRUBCFG

echo "GRUB config wygenerowany"

# Generuj ISO
echo "Generowanie ISO..."
grub-mkrescue -o "$ISO_FILE" "$ISO_DIR" -- -quiet 2>/dev/null || {
    # Fallback bez --quiet dla debugowania
    grub-mkrescue -o "$ISO_FILE" "$ISO_DIR"
}

echo "=== ISO gotowe: $ISO_FILE ==="
ls -lh "$ISO_FILE"
