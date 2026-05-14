#!/bin/bash
# Kompiluje jadro CrystalOS w QEMU z Alpine Linux
# Pobiera Alpine ISO, uruchamia VM z serial console, kompiluje jadro

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
ALPINE_ISO="$BUILD_DIR/alpine-standard-3.21.3-x86_64.iso"
ALPINE_ISO_URL="https://dl-cdn.alpinelinux.org/alpine/v3.21/releases/x86_64/alpine-standard-3.21.3-x86_64.iso"
BZIMAGE="$PROJECT_ROOT/arch/x86/boot/bzImage"
BUILD_DISK="$BUILD_DIR/kernel-build-disk.qcow2"
EXPECT_SCRIPT="$BUILD_DIR/build-kernel.expect"
ALPINE_KERNEL="$BUILD_DIR/vmlinuz-lts"
ALPINE_INITRD="$BUILD_DIR/initramfs-lts"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== CrystalOS Kernel Builder ===${NC}"
echo ""

# --- [1/6] Sprawdz wymagania ---
echo "[1/6] Sprawdzam wymagania..."
for CMD in qemu-system-x86_64 expect curl; do
    if ! command -v "$CMD" &>/dev/null; then
        echo -e "${RED}Brak: $CMD${NC}"
        exit 1
    fi
done
if [[ ! -f "$PROJECT_ROOT/tools/crystalos.config" ]]; then
    echo -e "${RED}Brak: tools/crystalos.config${NC}"
    exit 1
fi
echo -e "${GREEN}OK${NC}"

# --- [2/6] Pobierz Alpine ISO ---
echo ""
echo "[2/6] Alpine ISO..."
mkdir -p "$BUILD_DIR"
if [[ ! -f "$ALPINE_ISO" ]]; then
    echo "Pobieram Alpine Standard ISO (~200MB)..."
    curl -L --progress-bar -o "$ALPINE_ISO" "$ALPINE_ISO_URL"
    echo -e "${GREEN}Pobrano${NC}"
else
    echo -e "${GREEN}ISO istnieje${NC}"
fi

# --- [3/6] Wypakuj kernel + initramfs z ISO (dla serial console) ---
echo ""
echo "[3/6] Wypakowuje kernel z ISO (dla serial console)..."
if [[ ! -f "$ALPINE_KERNEL" ]] || [[ ! -f "$ALPINE_INITRD" ]]; then
    MOUNT_POINT="/tmp/alpine-iso-$$"
    mkdir -p "$MOUNT_POINT"
    hdiutil attach -quiet "$ALPINE_ISO" -mountpoint "$MOUNT_POINT"
    cp "$MOUNT_POINT/boot/vmlinuz-lts" "$ALPINE_KERNEL"
    cp "$MOUNT_POINT/boot/initramfs-lts" "$ALPINE_INITRD"
    hdiutil detach -quiet "$MOUNT_POINT"
    echo -e "${GREEN}Wypakowano vmlinuz-lts i initramfs-lts${NC}"
else
    echo -e "${GREEN}Kernel juz wypakowany${NC}"
fi

# --- [4/6] Stworz dysk roboczy 5GB ---
echo ""
echo "[4/6] Dysk roboczy..."
if [[ ! -f "$BUILD_DISK" ]]; then
    qemu-img create -f qcow2 "$BUILD_DISK" 5G
    echo -e "${GREEN}Utworzono dysk 5GB${NC}"
else
    echo -e "${GREEN}Dysk istnieje${NC}"
fi

# --- [5/6] Stworz skrypt expect ---
echo ""
echo "[5/6] Przygotowuje automatyzacje..."

cat > "$EXPECT_SCRIPT" << 'EXPECT_EOF'
#!/usr/bin/expect -f

set timeout 120
log_user 1

# Uruchom QEMU z wypakowanym kernelem (serial console)
spawn qemu-system-x86_64 \
    -m 4096 \
    -smp 2 \
    -cpu max \
    -machine q35 \
    -kernel {ALPINE_KERNEL} \
    -initrd {ALPINE_INITRD} \
    -append {console=ttyS0,115200 modules=loop,squashfs,sd-mod,usb-storage,virtio_blk,virtio_net quiet} \
    -cdrom {ALPINE_ISO} \
    -drive file={BUILD_DISK},if=virtio,format=qcow2 \
    -virtfs local,path={PROJECT_ROOT},mount_tag=host0,security_model=none \
    -netdev user,id=net0 \
    -device virtio-net-pci,netdev=net0 \
    -nographic \
    -no-reboot

# Czekaj na login prompt (Alpine live boot)
expect {
    "login:" {}
    timeout { puts "\nTIMEOUT: Brak login prompt (system nie wystartowal)"; exit 1 }
}
sleep 2
send "root\r"

expect {
    "#" {}
    timeout { puts "\nTIMEOUT: Brak shell prompt"; exit 1 }
}
sleep 1

# --- Siec: DHCP bez interaktywnego setup ---
send "ifconfig eth0 up && udhcpc -i eth0\r"
expect {
    "#" {}
    timeout { puts "\nTIMEOUT: Siec nie dziala"; exit 1 }
}
sleep 3

# --- Przygotuj dysk roboczy ---
send "apk add e2fsprogs-extra\r"
set timeout 60
expect {
    "#" {}
    timeout { puts "\nTIMEOUT: apk add e2fsprogs"; exit 1 }
}
sleep 2

send "mkfs.ext4 -F /dev/vda\r"
expect {
    "#" {}
    timeout { puts "\nTIMEOUT: mkfs.ext4"; exit 1 }
}
sleep 2

send "mkdir -p /build && mount /dev/vda /build\r"
expect {
    "#" {}
    timeout { puts "\nTIMEOUT: mount"; exit 1 }
}
sleep 2

# --- Zainstaluj zaleznosci kompilacji ---
set timeout 180
send "setup-apkrepos -1\r"
expect {
    "#" {}
    timeout { puts "\nTIMEOUT: apk repos"; exit 1 }
}
sleep 2

send "apk update\r"
expect {
    "#" {}
    timeout { puts "\nTIMEOUT: apk update"; exit 1 }
}
sleep 5

send "apk add build-base gcc make perl flex bison bc openssl-dev elfutils-dev xz patch\r"
expect {
    "#" {}
    timeout { puts "\nTIMEOUT: apk add build tools"; exit 1 }
}
sleep 5

# --- Zamontuj zrodlo jadra przez 9p ---
send "mkdir -p /src\r"
expect "#"
sleep 1

send "mount -t 9p -o trans=virtio,version=9p2000.L,msize=131072 host0 /src\r"
expect {
    "#" {}
    timeout { puts "\nTIMEOUT: mount 9p (moze nie wspierane)"; exit 1 }
}
sleep 3

# --- Kopiuj zrodlo na lokalny dysk (szybciej niz kompilowac na 9p) ---
puts "\n\n*** Kopiuje zrodlo jadra na dysk lokalny... ***\n"
set timeout -1
send "echo COPY_START && cp -a /src /build/src && echo COPY_DONE\r"
expect {
    "COPY_DONE" {}
    "COPY_START" { exp_continue }
    timeout { puts "\nTIMEOUT: kopiowanie zrodla"; exit 1 }
}
sleep 2

# --- Przygotuj config ---
send "cd /build/src\r"
expect "#"
sleep 1

set timeout 60
send "make allnoconfig\r"
expect {
    "#" {}
    timeout { puts "\nTIMEOUT: make allnoconfig"; exit 1 }
}
sleep 3

send "scripts/kconfig/merge_config.sh .config tools/crystalos.config\r"
expect {
    "#" {}
    timeout { puts "\nTIMEOUT: merge_config"; exit 1 }
}
sleep 3

send "make olddefconfig\r"
expect {
    "#" {}
    timeout { puts "\nTIMEOUT: make olddefconfig"; exit 1 }
}
sleep 5

# Kopiuj wygenerowany config na host
send "cp .config /src/.config\r"
expect "#"
sleep 2

# --- Kompiluj jadro ---
puts "\n\n=========================================="
puts "***   ROZPOCZYNAM KOMPILACJE JADRA   ***"
puts "***   To potrwa 30-120 minut...      ***"
puts "==========================================\n"
set timeout -1
send "echo BUILD_START && make -j2 && echo BUILD_OK || echo BUILD_FAIL\r"
expect {
    "BUILD_OK" { puts "\n*** KOMPILACJA UDANA ***\n" }
    "BUILD_FAIL" { puts "\n*** KOMPILACJA NIEUDANA ***"; exit 1 }
    timeout { puts "\nTIMEOUT: kompilacja"; exit 1 }
}
sleep 2

# --- Sprawdz wynik ---
send "ls -lh arch/x86/boot/bzImage\r"
expect "#"
sleep 1

# --- Kopiuj bzImage na host ---
send "cp arch/x86/boot/bzImage /src/arch/x86/boot/bzImage\r"
expect "#"
sleep 3

# --- Wylacz VM ---
send "poweroff\r"
expect {
    eof {}
    "reboot: System halted" {}
    "reboot: Power down" {}
    timeout {}
}

puts "\n\n=========================================="
puts "***   KOMPILACJA ZAKONCZONA          ***"
puts "==========================================\n"
exit 0
EXPECT_EOF

# Zamien zmienne w skrypcie expect
sed -i '' \
    -e "s|{ALPINE_KERNEL}|$ALPINE_KERNEL|g" \
    -e "s|{ALPINE_INITRD}|$ALPINE_INITRD|g" \
    -e "s|{ALPINE_ISO}|$ALPINE_ISO|g" \
    -e "s|{BUILD_DISK}|$BUILD_DISK|g" \
    -e "s|{PROJECT_ROOT}|$PROJECT_ROOT|g" \
    "$EXPECT_SCRIPT"

chmod +x "$EXPECT_SCRIPT"
echo -e "${GREEN}OK${NC}"

# --- [6/6] Uruchom kompilacje ---
echo ""
echo "[6/6] Uruchamiam QEMU z Alpine..."
echo ""
echo -e "${YELLOW}============================================================${NC}"
echo -e "${YELLOW}  Kompilacja w QEMU (emulacja x86_64 na ARM) potrwa dlugo! ${NC}"
echo -e "${YELLOW}  Szacowany czas: 30-120 minut                               ${NC}"
echo -e "${YELLOW}  Nie zamykaj tego terminala!                                ${NC}"
echo -e "${YELLOW}============================================================${NC}"
echo ""

expect "$EXPECT_SCRIPT"
EXPECT_EXIT=$?

# --- Weryfikacja ---
echo ""
echo "=== Weryfikacja ==="
if [[ -f "$BZIMAGE" ]]; then
    SIZE=$(stat -f%z "$BZIMAGE" 2>/dev/null || stat -c%s "$BZIMAGE" 2>/dev/null)
    SIZE_MB=$((SIZE / 1024 / 1024))
    echo -e "${GREEN}bzImage gotowy: ${SIZE_MB}MB${NC}"
    echo "Sciezka: $BZIMAGE"
    echo ""
    echo "Uruchom testy:"
    echo "  bash tests/test-kernel.sh"
else
    echo -e "${RED}bzImage nie znaleziony!${NC}"
    exit 1
fi
