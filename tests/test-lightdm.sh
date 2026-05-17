#!/bin/bash
# Testy Fazy 6: Ekran Logowania (LightDM)
# Waliduje instalacje i konfiguracje LightDM w rootfs Alpine

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

echo -e "${YELLOW}=== Testy LightDM CrystalOS - Faza 6 ===${NC}"
echo ""

# --- Test 1: lightdm binary ---
echo "Test 1: lightdm binary"
if [[ -f "$ROOTFS/usr/sbin/lightdm" ]] || [[ -f "$ROOTFS/usr/bin/lightdm" ]]; then
    pass "lightdm binary istnieje"
else
    fail "lightdm binary brak (szukano /usr/sbin/lightdm, /usr/bin/lightdm)"
fi

# --- Test 2: lightdm-greeter (gtk) ---
echo ""
echo "Test 2: lightdm-gtk-greeter"
if [[ -f "$ROOTFS/usr/sbin/lightdm-gtk-greeter" ]] || [[ -f "$ROOTFS/usr/bin/lightdm-gtk-greeter" ]]; then
    pass "lightdm-gtk-greeter istnieje"
else
    fail "lightdm-gtk-greeter brak (szukano /usr/sbin/lightdm-gtk-greeter, /usr/bin/lightdm-gtk-greeter)"
fi

# --- Test 3: lightdm.conf istnieje ---
echo ""
echo "Test 3: lightdm.conf"
if [[ -f "$ROOTFS/etc/lightdm/lightdm.conf" ]]; then
    pass "lightdm.conf istnieje"
else
    fail "lightdm.conf brak (oczekiwano /etc/lightdm/lightdm.conf)"
fi

# --- Test 4: greeter-session ustawiony na gtk ---
echo ""
echo "Test 4: greeter-session w lightdm.conf"
if [[ -f "$ROOTFS/etc/lightdm/lightdm.conf" ]]; then
    if grep -q "greeter-session=lightdm-gtk-greeter" "$ROOTFS/etc/lightdm/lightdm.conf"; then
        pass "greeter-session ustawiony na lightdm-gtk-greeter"
    else
        fail "greeter-session nie jest ustawiony na lightdm-gtk-greeter"
    fi
else
    fail "lightdm.conf brak - nie mozna sprawdzic greeter-session"
fi

# --- Test 5: session ustawiona na xfce ---
echo ""
echo "Test 5: user-session w lightdm.conf"
if [[ -f "$ROOTFS/etc/lightdm/lightdm.conf" ]]; then
    if grep -q "user-session=xfce" "$ROOTFS/etc/lightdm/lightdm.conf"; then
        pass "user-session ustawiony na xfce"
    else
        fail "user-session nie jest ustawiony na xfce"
    fi
else
    fail "lightdm.conf brak - nie mozna sprawdzic user-session"
fi

# --- Test 6: branding CrystalOS (greeter tema lub sitename) ---
echo ""
echo "Test 6: Branding CrystalOS"
if [[ -f "$ROOTFS/etc/lightdm/lightdm.conf" ]]; then
    if grep -qi "crystalos\|CrystalOS" "$ROOTFS/etc/lightdm/lightdm.conf"; then
        pass "Branding CrystalOS znaleziony w lightdm.conf"
    else
        fail "Brak brandingu CrystalOS w lightdm.conf"
    fi
else
    fail "lightdm.conf brak - nie mozna sprawdzic brandingu"
fi

# --- Test 7: OpenRC serwis lightdm w default runlevel ---
echo ""
echo "Test 7: OpenRC serwis lightdm"
if [[ -L "$ROOTFS/etc/runlevels/default/lightdm" ]]; then
    pass "lightdm jest w default runlevel"
else
    fail "lightdm nie jest w default runlevel"
fi

# --- Test 8: sesja XFCE zarejestrowana w xsessions ---
echo ""
echo "Test 8: sesja XFCE w xsessions"
if ls "$ROOTFS"/usr/share/xsessions/xfce*.desktop &>/dev/null; then
    pass "xfce.desktop sesja istnieje w xsessions"
else
    fail "brak xfce.desktop w /usr/share/xsessions/"
fi

# --- Test 9: dbus zainstalowany i w runlevel ---
echo ""
echo "Test 9: dbus (wymagany przez LightDM)"
if [[ -f "$ROOTFS/usr/bin/dbus-daemon" ]] || [[ -f "$ROOTFS/usr/sbin/dbus-daemon" ]]; then
    pass "dbus-daemon istnieje"
else
    fail "dbus-daemon brak"
fi
if [[ -f "$ROOTFS/etc/machine-id" ]]; then
    pass "/etc/machine-id istnieje"
else
    fail "/etc/machine-id brak (dbus niezainicjalizowany)"
fi
if [[ -L "$ROOTFS/etc/runlevels/default/dbus" ]]; then
    pass "dbus jest w default runlevel"
else
    fail "dbus nie jest w default runlevel"
fi

# --- Test 10: elogind (session tracking) ---
echo ""
echo "Test 10: elogind (session tracking)"
if find "$ROOTFS/usr" "$ROOTFS/lib" -name "elogind*" -type f 2>/dev/null | grep -q .; then
    pass "elogind binary/pliki istnieja"
else
    fail "elogind binary brak"
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
