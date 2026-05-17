#!/bin/bash
# Testy Fazy 5: Pulpit XFCE
# Waliduje instalacje XFCE 4.x w rootfs Alpine

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

echo -e "${YELLOW}=== Testy XFCE CrystalOS - Faza 5 ===${NC}"
echo ""

# --- Test 1: startxfce4 binary ---
echo "Test 1: startxfce4"
if [[ -f "$ROOTFS/usr/bin/startxfce4" ]]; then
    pass "startxfce4 istnieje"
else
    fail "startxfce4 brak (oczekiwano /usr/bin/startxfce4)"
fi

# --- Test 2: .xinitrc uruchamia startxfce4 ---
echo ""
echo "Test 2: .xinitrc uruchamia startxfce4"
XINITRC="$ROOTFS/root/.xinitrc"
if [[ -f "$XINITRC" ]]; then
    pass ".xinitrc istnieje"
    if grep -q "startxfce4" "$XINITRC"; then
        pass ".xinitrc uruchamia startxfce4"
    else
        fail ".xinitrc nie uruchamia startxfce4"
    fi
else
    fail ".xinitrc brak"
fi

# --- Test 3: xfwm4 (menedzer okien) ---
echo ""
echo "Test 3: xfwm4 (menedzer okien)"
if [[ -f "$ROOTFS/usr/bin/xfwm4" ]]; then
    pass "xfwm4 istnieje"
else
    fail "xfwm4 brak (oczekiwano /usr/bin/xfwm4)"
fi

# --- Test 4: xfce4-panel ---
echo ""
echo "Test 4: xfce4-panel"
if [[ -f "$ROOTFS/usr/bin/xfce4-panel" ]]; then
    pass "xfce4-panel istnieje"
else
    fail "xfce4-panel brak (oczekiwano /usr/bin/xfce4-panel)"
fi

# --- Test 5: Panel config z pozycja bottom ---
echo ""
echo "Test 5: Panel config (pozycja bottom)"
PANEL_CONFIG="$ROOTFS/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"
if [[ -f "$PANEL_CONFIG" ]]; then
    pass "xfce4-panel.xml istnieje"
    if grep -qi "bottom" "$PANEL_CONFIG"; then
        pass "Panel ustawiony na bottom"
    else
        fail "Panel nie ma pozycji bottom w configu"
    fi
else
    fail "xfce4-panel.xml brak"
fi

# --- Test 6: xfdesktop4 (pulpit z tlem) ---
echo ""
echo "Test 6: xfdesktop4"
if [[ -f "$ROOTFS/usr/bin/xfdesktop" ]]; then
    pass "xfdesktop istnieje"
else
    fail "xfdesktop brak (oczekiwano /usr/bin/xfdesktop)"
fi

# --- Test 7: Domyślne tło pulpitu ---
echo ""
echo "Test 7: Tlo pulpitu"
DESKTOP_CONFIG="$ROOTFS/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfdesktop.xml"
if [[ -f "$DESKTOP_CONFIG" ]]; then
    pass "xfdesktop.xml istnieje"
    if grep -qi "image-style\|color-style\|backdrop" "$DESKTOP_CONFIG"; then
        pass "Konfiguracja tla pulpitu istnieje"
    else
        fail "Brak konfiguracji tla w xfdesktop.xml"
    fi
else
    fail "xfdesktop.xml brak"
fi

# --- Test 8: xfce4-appfinder (menu aplikacji) ---
echo ""
echo "Test 8: xfce4-appfinder (menu aplikacji)"
if [[ -f "$ROOTFS/usr/bin/xfce4-appfinder" ]]; then
    pass "xfce4-appfinder istnieje"
else
    fail "xfce4-appfinder brak (oczekiwano /usr/bin/xfce4-appfinder)"
fi

# --- Test 9: Obszary robocze >= 2 ---
echo ""
echo "Test 9: Obszary robocze (workspace >= 2)"
XFWM_CONFIG="$ROOTFS/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml"
if [[ -f "$XFWM_CONFIG" ]]; then
    pass "xfwm4.xml istnieje"
    WORKSPACE_COUNT=$(sed -n 's/.*workspace_count.*value="\([0-9]*\)".*/\1/p' "$XFWM_CONFIG" | head -1)
    if [[ -n "$WORKSPACE_COUNT" ]] && [[ "$WORKSPACE_COUNT" -ge 2 ]]; then
        pass "Obszary robocze: $WORKSPACE_COUNT (>= 2)"
    else
        fail "Obszary robocze: mniej niz 2 lub brak konfiguracji"
    fi
else
    fail "xfwm4.xml brak"
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
