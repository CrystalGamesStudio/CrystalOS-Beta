#!/bin/bash
# Testy Fazy 4: Serwer Graficzny (Xorg)
# Waliduje instalacje Xorg w rootfs Alpine

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

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROOTFS="$PROJECT_ROOT/build/rootfs"

echo -e "${YELLOW}=== Testy Xorg CrystalOS - Faza 4 ===${NC}"
echo ""

# --- Test 1: xorg-server binarka ---
echo "Test 1: Serwer Xorg"
if [[ -f "$ROOTFS/usr/bin/Xorg" ]] || [[ -f "$ROOTFS/usr/libexec/Xorg" ]]; then
    pass "Xorg binary istnieje"
else
    fail "Xorg binary brak (oczekiwano /usr/bin/Xorg)"
fi

# --- Test 2: xinit + startx ---
echo ""
echo "Test 2: xinit i startx"
for BIN in xinit startx; do
    if [[ -f "$ROOTFS/usr/bin/$BIN" ]]; then
        pass "$BIN istnieje"
    else
        fail "$BIN brak"
    fi
done

# --- Test 3: xterm ---
echo ""
echo "Test 3: xterm"
if [[ -f "$ROOTFS/usr/bin/xterm" ]]; then
    pass "xterm istnieje"
else
    fail "xterm brak"
fi

# --- Test 4: Sterownik input (libinput) ---
echo ""
echo "Test 4: Sterownik input"
if find "$ROOTFS/usr/lib/xorg" -name "libinput_drv.so" 2>/dev/null | grep -q .; then
    pass "libinput_drv.so znaleziony"
else
    fail "libinput_drv.so brak"
fi

# --- Test 5: Sterownik graficzny (fbdev, vesa lub modesetting) ---
echo ""
echo "Test 5: Sterownik graficzny"
if find "$ROOTFS/usr/lib/xorg" \( -name "modesetting_drv.so" -o -name "vesa_drv.so" -o -name "fbdev_drv.so" \) 2>/dev/null | grep -q .; then
    pass "Sterownik graficzny (fbdev/modesetting/vesa) znaleziony"
else
    fail "Sterownik graficzny brak"
fi

# --- Test 6: xorg.conf istnieje ---
echo ""
echo "Test 6: Konfiguracja xorg.conf"
XORG_CONF="$ROOTFS/etc/X11/xorg.conf"
if [[ -f "$XORG_CONF" ]]; then
    pass "xorg.conf istnieje"
    if grep -q "virtio\|modesetting\|fbdev" "$XORG_CONF"; then
        pass "xorg.conf ma wpis graficzny (virtio/modesetting/fbdev)"
    else
        fail "xorg.conf brak wpisu graficznego"
    fi
else
    fail "xorg.conf brak (oczekiwano /etc/X11/xorg.conf)"
fi

# --- Test 7: Kernel framebuffer support ---
echo ""
echo "Test 7: Kernel framebuffer"
KERNEL_CONFIG="$PROJECT_ROOT/tools/crystalos.config"
for OPT in CONFIG_FB CONFIG_FB_VESA CONFIG_FB_SIMPLE; do
    if grep -q "^${OPT}=y" "$KERNEL_CONFIG"; then
        pass "$OPT=y"
    else
        fail "$OPT nie włączone w kernel config (ustawiane przez CI)"
    fi
done

# --- Test 8: .xinitrc uruchamia xterm lub startxfce4 ---
echo ""
echo "Test 8: .xinitrc"
XINITRC="$ROOTFS/root/.xinitrc"
if [[ -f "$XINITRC" ]]; then
    pass ".xinitrc istnieje"
    if grep -q "xterm" "$XINITRC" || grep -q "startxfce4" "$XINITRC"; then
        pass ".xinitrc uruchamia xterm lub startxfce4"
    else
        fail ".xinitrc nie uruchamia xterm ani startxfce4"
    fi
else
    fail ".xinitrc brak"
fi

# --- Test 9: xrandr ---
echo ""
echo "Test 9: xrandr"
if [[ -f "$ROOTFS/usr/bin/xrandr" ]]; then
    pass "xrandr istnieje"
else
    fail "xrandr brak"
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
