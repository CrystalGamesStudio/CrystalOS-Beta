#!/bin/bash
# Testy ISO CrystalOS - Faza 3
# Waliduje rootfs, GRUB config i obraz ISO wg acceptance criteria

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
ISO_DIR="$PROJECT_ROOT/build/iso"
ISO_FILE="$PROJECT_ROOT/build/crystalos-beta.iso"
GRUB_CFG="$ISO_DIR/boot/grub/grub.cfg"

echo -e "${YELLOW}=== Testy ISO CrystalOS - Faza 3 ===${NC}"
echo ""

# --- Test 1: Rootfs ma podstawowa strukture katalogow ---
echo "Test 1: Struktura katalogow rootfs"
DIRS="bin etc dev proc sys usr sbin lib"
ALL_DIRS=true
for DIR in $DIRS; do
    if [[ -d "$ROOTFS/$DIR" ]]; then
        pass "$ROOTFS/$DIR/ istnieje"
    else
        fail "$ROOTFS/$DIR/ brak"
        ALL_DIRS=false
    fi
done

# --- Test 2: Hostname ustawiony na "crystalos" ---
echo ""
echo "Test 2: Hostname = crystalos"
if [[ -f "$ROOTFS/etc/hostname" ]]; then
    HOSTNAME_VAL=$(cat "$ROOTFS/etc/hostname" | tr -d '[:space:]')
    if [[ "$HOSTNAME_VAL" == "crystalos" ]]; then
        pass "hostname = crystalos"
    else
        fail "hostname = '$HOSTNAME_VAL' (oczekiwano 'crystalos')"
    fi
else
    fail "/etc/hostname nie istnieje"
fi

# --- Test 3: Komunikat powitalny (issue) ---
echo ""
echo "Test 3: Komunikat powitalny (/etc/issue)"
if [[ -f "$ROOTFS/etc/issue" ]] && grep -q "CrystalOS" "$ROOTFS/etc/issue"; then
    pass "/etc/issue zawiera CrystalOS"
else
    fail "/etc/issue brak lub nie zawiera CrystalOS"
fi

# --- Test 4: Uzytkownik root (logowanie bez hasla) ---
echo ""
echo "Test 4: Uzytkownik root"
if [[ -f "$ROOTFS/etc/shadow" ]]; then
    ROOT_LINE=$(grep '^root:' "$ROOTFS/etc/shadow")
    # root:: oznacza puste haslo (logowanie bez hasla)
    if echo "$ROOT_LINE" | grep -q '^root::'; then
        pass "root ma puste haslo (logowanie bez hasla)"
    else
        fail "root ma ustawione haslo (powinno byc puste)"
    fi
else
    fail "/etc/shadow nie istnieje"
fi

# --- Test 5: Konfiguracja sieci (dhcp) ---
echo ""
echo "Test 5: Konfiguracja sieci"
if [[ -f "$ROOTFS/etc/network/interfaces" ]] && grep -q "dhcp" "$ROOTFS/etc/network/interfaces"; then
    pass "eth0 skonfigurowane z dhcp"
else
    fail "brak konfiguracji dhcp dla eth0"
fi

# --- Test 6: APK repositories ---
echo ""
echo "Test 6: APK repositories"
if [[ -f "$ROOTFS/etc/apk/repositories" ]] && grep -q "alpinelinux.org" "$ROOTFS/etc/apk/repositories"; then
    pass "apk repositories skonfigurowane"
else
    fail "apk repositories brak"
fi

# --- Test 7: GRUB config zawiera CrystalOS Beta ---
echo ""
echo "Test 7: GRUB config"
if [[ -f "$GRUB_CFG" ]]; then
    if grep -q "CrystalOS Beta" "$GRUB_CFG"; then
        pass "grub.cfg zawiera 'CrystalOS Beta'"
    else
        fail "grub.cfg nie zawiera 'CrystalOS Beta'"
    fi
    if grep -q "vmlinuz\|bzImage" "$GRUB_CFG"; then
        pass "grub.cfg wskazuje na kernel"
    else
        fail "grub.cfg nie wskazuje na kernel"
    fi
else
    fail "grub.cfg nie istnieje"
fi

# --- Test 8: ISO istnieje i ma rozmiar < 500MB ---
echo ""
echo "Test 8: Obraz ISO"
if [[ -f "$ISO_FILE" ]]; then
    SIZE=$(stat -f%z "$ISO_FILE" 2>/dev/null || stat -c%s "$ISO_FILE" 2>/dev/null)
    SIZE_MB=$((SIZE / 1024 / 1024))
    if [[ $SIZE -lt 524288000 ]]; then
        pass "ISO istnieje i ma rozmiar ${SIZE_MB}MB (< 500MB)"
    else
        fail "ISO jest za duze: ${SIZE_MB}MB (limit: 500MB)"
    fi
else
    fail "ISO nie istnieje (build/crystalos-beta.iso)"
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
