# Srodowisko Budowania CrystalOS

## Co jest zainstalowane

| Narzedzie | Opis |
|-----------|------|
| QEMU 11.x | Emulator - tworzy i uruchamia obrazy systemu |
| UTM 4.x | Alternatywny sposob testowania (interfejs graficzny) |
| alpine-make-rootfs | Tworzy system plikow Alpine Linux |

## Struktura katalogow

```
CrystalOS-Beta/
  build/     - Dysk wirtualny + pliki tymczasowe
  rootfs/    - System plikow Alpine (pliki systemowe)
  iso/       - Gotowe obrazy ISO (do bootowania)
  tools/     - Skrypty pomocnicze
  tests/     - Testy srodowiska
```

## Jak sprawdzic czy wszystko dziala

Wpisz w terminalu:
```bash
bash tests/test-env.sh
```

## Jak przetestowac CrystalOS - SPOSOB 1 (QEMU, prostszy)

Wpisz w terminalu:
```bash
bash tests/test-boot.sh
```

Skrypt automatycznie:
1. Stworzy dysk wirtualny 10GB (za pierwszym razem)
2. Znajdzie najnowsze ISO w folderze iso/
3. Uruchomi QEMU w oknie macOS
4. Zobaczysz ekran maszyny wirtualnej

Aby zamknac: zamknij okno QEMU lub nacisnij **Ctrl+C** w terminalu.

## Jak przetestowac CrystalOS - SPOSOB 2 (UTM, graficzny)

### Krok 1: Otworz UTM
Wypuknij UTM z Launchpada (ikona z niebieskim tlem i bialym kolkiem)

### Krok 2: Stworz nowa maszyne
1. Kliknij przycisk **"+"** na gorze (lub na dole po lewej)
2. Wybierz **"Emuluj"** (Emulate)
3. Wybierz **"Inne"** (Other)

### Krok 3: Ustawienia
1. Pamiec: wpisz **2048** (2 GB RAM)
2. Rdzenie CPU: wpisz **2**

### Krok 4: Dyski
1. Kliknij **"Nowy"** (New) → rozmiar: **10240** MB
2. Interfejs: **VirtIO**
3. Dodaj dysk CD: kliknij **"Importuj"** (Import) → wybierz ISO z folderu iso/

### Krok 5: Siec
Pozostaw domyslna (Shared Network / Wspoldzielona)

### Krok 6: Uruchom
Kliknij przycisk **Play** (trojkat) na gorze

### Krok 7: Logowanie
Gdy zobaczysz **crystalos login:** wpisz `root` i nacisnij Enter
