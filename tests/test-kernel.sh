#!/bin/bash
# Testy jądra CrystalOS - Faza 2
# Waliduje .config i bzImage wg acceptance criteria

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASS++))
}

fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAIL++))
}

# Sprawdza czy opcja jest wlaczona (=y) w .config
config_enabled() {
    grep -q "^CONFIG_$1=y" "$CONFIG"
}

# Sprawdza czy opcja jest wylaczona (nie jest =y, moze byc =n lub brak)
config_disabled() {
    ! grep -q "^CONFIG_$1=y" "$CONFIG"
}

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$PROJECT_ROOT/.config"
BZIMAGE="$PROJECT_ROOT/arch/x86/boot/bzImage"

echo -e "${YELLOW}=== Testy jądra CrystalOS - Faza 2 ===${NC}"
echo ""

# --- Test 1: .config istnieje ---
echo "Test 1: Plik .config istnieje"
if [[ -f "$CONFIG" ]]; then
    LINES=$(grep -c '.' "$CONFIG")
    pass ".config istnieje ($LINES linii)"
else
    fail ".config nie istnieje"
fi

# --- Test 2: Wymagane opcje - podstawowe (64-bit, SMP, PCI) ---
echo ""
echo "Test 2: Podstawowe opcje (64BIT, SMP, PCI)"
BASIC_OPTS="64BIT SMP PCI PCI_GOANY"
ALL_BASIC=true
for OPT in $BASIC_OPTS; do
    if config_enabled "$OPT"; then
        pass "CONFIG_$OPT=y"
    else
        fail "CONFIG_$OPT brak (wymagane)"
        ALL_BASIC=false
    fi
done

# --- Test 3: Virtio (dysk, siec, grafika) ---
echo ""
echo "Test 3: Sterowniki Virtio (dysk, siec, grafika)"
VIRTIO_OPTS="VIRTIO VIRTIO_MENU VIRTIO_PCI VIRTIO_BLK VIRTIO_NET VIRTIO_GPU"
ALL_VIRTIO=true
for OPT in $VIRTIO_OPTS; do
    if config_enabled "$OPT"; then
        pass "CONFIG_$OPT=y"
    else
        fail "CONFIG_$OPT brak (wymagane dla QEMU)"
        ALL_VIRTIO=false
    fi
done

# --- Test 4: System plikow ext4 ---
echo ""
echo "Test 4: System plikow ext4"
EXT4_OPTS="EXT4_FS BLOCK"
ALL_EXT4=true
for OPT in $EXT4_OPTS; do
    if config_enabled "$OPT"; then
        pass "CONFIG_$OPT=y"
    else
        fail "CONFIG_$OPT brak (wymagane)"
        ALL_EXT4=false
    fi
done

# --- Test 5: Framebuffer i konsola ---
echo ""
echo "Test 5: Framebuffer i konsola"
FB_OPTS="FB VT VT_CONSOLE TTY FRAMEBUFFER_CONSOLE DRM"
ALL_FB=true
for OPT in $FB_OPTS; do
    if config_enabled "$OPT"; then
        pass "CONFIG_$OPT=y"
    else
        fail "CONFIG_$OPT brak (wymagane dla wyswietlania)"
        ALL_FB=false
    fi
done

# --- Test 6: Input (klawiatura, mysz) ---
echo ""
echo "Test 6: Input (klawiatura, mysz, USB)"
INPUT_OPTS="INPUT INPUT_KEYBOARD KEYBOARD_ATKBD INPUT_MOUSE MOUSE_PS2 SERIO"
ALL_INPUT=true
for OPT in $INPUT_OPTS; do
    if config_enabled "$OPT"; then
        pass "CONFIG_$OPT=y"
    else
        fail "CONFIG_$OPT brak (wymagane dla input)"
        ALL_INPUT=false
    fi
done

# --- Test 7: USB (dla QEMU usb-mouse/usb-kbd) ---
echo ""
echo "Test 7: USB"
USB_OPTS="USB USB_HID HID HID_GENERIC"
ALL_USB=true
for OPT in $USB_OPTS; do
    if config_enabled "$OPT"; then
        pass "CONFIG_$OPT=y"
    else
        fail "CONFIG_$OPT brak (wymagane dla USB)"
        ALL_USB=false
    fi
done

# --- Test 8: Niepotrzebne subsystemy wylaczone ---
echo ""
echo "Test 8: Niepotrzebne subsystemy wylaczone"
DISABLED_OPTS="SOUND WLAN BT PRINTER"
ALL_DISABLED=true
for OPT in $DISABLED_OPTS; do
    if config_disabled "$OPT"; then
        pass "CONFIG_$OPT wylaczone"
    else
        fail "CONFIG_$OPT wlaczone (powinno byc wylaczone)"
        ALL_DISABLED=false
    fi
done

# --- Test 9: bzImage istnieje i ma rozsądny rozmiar ---
echo ""
echo "Test 9: bzImage (skompilowane jadro)"
if [[ -f "$BZIMAGE" ]]; then
    SIZE=$(stat -f%z "$BZIMAGE" 2>/dev/null || stat -c%s "$BZIMAGE" 2>/dev/null)
    SIZE_MB=$((SIZE / 1024 / 1024))
    if [[ $SIZE -lt 20971520 ]]; then
        pass "bzImage istnieje i ma rozmiar ${SIZE_MB}MB (< 20MB)"
    else
        fail "bzImage istnieje ale jest za duzy: ${SIZE_MB}MB (limit: 20MB)"
    fi
else
    fail "arch/x86/boot/bzImage nie istnieje (jadro nie skompilowane)"
fi

# --- Podsumowanie ---
echo ""
echo -e "${YELLOW}=== Podsumowanie ===${NC}"
echo "Przeszlo: $PASS"
echo "Nie przeszlo: $FAIL"
TOTAL=$((PASS + FAIL))
if [[ $FAIL -eq 0 ]]; then
    echo -e "${GREEN}Wszystkie testy przechodza!${NC}"
    exit 0
else
    echo -e "${RED}$FAIL z $TOTAL testow nie przechodzi${NC}"
    exit 1
fi
