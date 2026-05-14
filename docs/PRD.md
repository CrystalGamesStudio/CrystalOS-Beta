# PRD: CrystalOS Beta

## Problem Statement

Użytkownik chce własny system operacyjny bazujący na Linuxie, który będzie lekki, nowoczesny wizualnie (animacje, przejrzystość, minimalizm) i zoptymalizowany pod kątem zarządzania energią. Nie istnieje gotowa dystrybucja, która spełnia dokładnie te wymagania z brandingiem CrystalOS. Dodatkowo użytkownik jest nowicjuszem i potrzebuje pełnego prowadzenia przez proces budowy, testowania i dostosowywania systemu.

## Solution

CrystalOS Beta — własna dystrybucja Linuxa zbudowana na bazie Alpine Linux z modyfikowanym jądrem Linux, środowiskiem graficznym XFCE z kompozytorem Picom (animacje i przejrzystość), własną przeglądarką na bazie Chromium oraz spersonalizowanym brandingiem. System jest testowany na Macu w wirtualizatorze UTM. Claude Code pełni rolę głównego programisty i prowadzącego.

## User Stories

### Jądro systemu

1. Jako użytkownik CrystalOS, chcę żeby system uruchamiał się na moim komputerze stacjonarnym, żeby móc z niego korzystać
2. Jako użytkownik CrystalOS, chcę żeby jądro było skompilowane tylko z niezbędnymi sterownikami, żeby system był jak najlżejszy
3. Jako użytkownik CrystalOS, chcę zoptymalizowane zarządzanie energią w jądrze, żeby komputer zużywał mniej prądu
4. Jako użytkownik CrystalOS, chcę żeby jądro obsługiwało sprzętową akcelerację grafiki, żeby animacje działały płynnie
5. Jako użytkownik CrystalOS, chcę żeby jądro działało poprawnie w UTM (qemu), żeby móc testować system na Macu

### System bazowy

6. Jako użytkownik CrystalOS, chcę żeby system bazował na Alpine Linux, żeby był minimalny i bezpieczny
7. Jako użytkownik CrystalOS, chcę menedżer pakietów (apk), żeby móc doinstalowywać dodatkowe programy
8. Jako użytkownik CrystalOS, chcę działającą sieć (WiFi/Ethernet), żeby mieć dostęp do internetu
9. Jako użytkownik CrystalOS, chcę system dźwięku (ALSA/PulseAudio), żeby odtwarzać dźwięk
10. Jako użytkownik CrystalOS, chcę automatyczne wykrywanie i montowanie dysków USB, żeby łatwo przesyłać pliki
11. Jako użytkownik CrystalOS, chcę system plików gotowy do użycia po instalacji, żeby nie musiał go ręcznie konfigurować

### Środowisko graficzne

12. Jako użytkownik CrystalOS, chcę środowisko graficzne XFCE, żeby mieć wygodny pulpit
13. Jako użytkownik CrystalOS, chcę animacje i efekty przejrzystości (picom), żeby system wyglądał nowocześnie
14. Jako użytkownik CrystalOS, chcę panel zadań na dole ekranu, żeby mieć szybki dostęp do programów
15. Jako użytkownik CrystalOS, chcę menu aplikacji z podziałem na kategorie, żeby łatwo znaleźć programy
16. Jako użytkownik CrystalOS, chcę obsługę wielu obszarów roboczych (virtual desktops), żeby organizować okna
17. Jako użytkownik CrystalOS, chcę powiadomienia systemowe, żeby nie przegapić ważnych informacji

### Ekran logowania

18. Jako użytkownik CrystalOS, chcę ekran logowania z brandingiem CrystalOS, żeby system wyglądał profesjonalnie od startu
19. Jako użytkownik CrystalOS, chcę mieć możliwość ustawienia hasła lub logowania bez hasła, żeby wybrać poziom bezpieczeństwa
20. Jako użytkownik CrystalOS, chcę wybór użytkownika na ekranie logowania (jeśli jest wielu), żeby szybko się zalogować

### Aplikacje

21. Jako użytkownik CrystalOS, chcę własną przeglądarkę internetową (CrystalBrowser na bazie Chromium), żeby przeglądać internet
22. Jako użytkownik CrystalOS, chcę terminal, żeby wykonywać komendy tekstowe
23. Jako użytkownik CrystalOS, chcę menedżer plików, żeby wygodnie zarządzać plikami i folderami
24. Jako użytkownik CrystalOS, chcę panel ustawień graficzny, żeby zmieniać konfigurację systemu bez terminala
25. Jako użytkownik CrystalOS, chcę podgląd obrazów, żeby przeglądać zdjęcia i grafiki
26. Jako użytkownik CrystalOS, chcę podgląd wideo, żeby oglądać filmy
27. Jako użytkownik CrystalOS, chcę możliwość doinstalowania dodatkowych programów przez apk, żeby rozszerzać funkcjonalność

### Branding i wygląd

28. Jako użytkownik CrystalOS, chcę własną tapetę z logo CrystalOS, żeby system miał unikalny wygląd
29. Jako użytkownik CrystalOS, chcę spójny motyw kolorystyczny (GTK theme), żeby cały system wyglądał jednolicie
30. Jako użytkownik CrystalOS, chcę własny zestaw ikon, żeby ikony pasowały do motywu CrystalOS
31. Jako użytkownik CrystalOS, chcę ekran boot (splash screen) z logo CrystalOS, żeby system wyglądał profesjonalnie przy uruchamianiu
32. Jako użytkownik CrystalOS, chcę własny motyw kursora, żeby kursor pasował do reszty designu

### Budowanie i testowanie

33. Jako deweloper CrystalOS, chcę skrypt automatycznie budujący ISO z systemem, żeby nie musiał robić tego ręcznie
34. Jako deweloper CrystalOS, chcę instrukcję krok po kroku jak przetestować ISO w UTM, żeby szybko weryfikować zmiany
35. Jako deweloper CrystalOS, chcę skrypt czyszczący środowisko budowania, żeby nie zaśmiecać dysku
36. Jako deweloper CrystalOS, chcę dokumentację projektu, żeby rozumieć jak system jest zbudowany

## Implementation Decisions

### Architektura systemu

- **Baza dystrybucji:** Alpine Linux — minimalny (~130MB bazowy), bezpieczny, z menedżerem pakietów apk
- **Jądro:** Modyfikowane jądro Linux z repozytorium CrystalOS-Beta, skompilowane z minimalną konfiguracją
- **Init system:** OpenRC (domyślny w Alpine) — lekki i szybki
- **Bootloader:** GRUB — niezawodny, szeroko wspierany
- **System plików:** ext4 — stabilny, sprawdzony

### Stos graficzny

- **Serwer wyświetlania:** Xorg (X11) — stabilny, dobrze wspierany przez XFCE
- **Środowisko:** XFCE 4.x — lekkie (~300-500MB RAM), konfigurowalne, nowoczesne
- **Kompozytor:** Picom — animacje, przejrzystość, cienie okien
- **Menedżer logowania:** LightDM z motywem CrystalOS — ekran logowania z brandingiem
- **Motyw GTK:** Niestandardowy motyw CrystalOS (kolory, widgety)
- **Motyw ikon:** Dostosowany zestaw ikon z brandingiem CrystalOS

### Aplikacje

- **Przeglądarka:** CrystalBrowser — Chromium z rebrandingiem (nazwa, ikony, strona startowa)
- **Terminal:** xfce4-terminal — lekki, z zakładkami, konfigurowalny
- **Menedżer plików:** Thunar — domyślny w XFCE, lekki i szybki
- **Podgląd obrazów:** Ristretto — lekka przeglądarka obrazów z XFCE
- **Podgląd wideo:** mpv — minimalny, potężny odtwarzacz wideo
- **Ustawienia:** xfce4-settings — graficzny panel konfiguracji

### Optymalizacja jądra

- Minimalna konfiguracja — tylko sterowniki potrzebne dla desktop i QEMU/UTM
- Włączone funkcje oszczędzania energii (CPU frequency scaling, ASPM)
- Optymalizacja schedulerów (CFS lub EEVDF) pod desktop
- Wsparcie dla systemów plików: ext4, vfat, tmpfs
- Modułowa budowa — niepotrzebne subsystemy wyłączone

### Budowanie

- Skrypty bash do automatyzacji całego procesu
- Generowanie obrazu ISO bootowalnego
- Obraz dysku QEMU (qcow2) gotowy do załadowania w UTM
- Cały proces reprodukowalny z jednego polecenia

### Testowanie

- Wirtualizacja UTM na macOS (Apple Silicon / Intel)
- QEMU jako backend UTM
- Testy: boot, GUI, aplikacje, sieć, dźwięk, zarządzanie energią

### Limity zasobów

- Maksymalny rozmiar ISO: poniżej 2GB (idealnie ~1GB)
- Maksymalny rozmiar po instalacji: poniżej 10GB
- Zużycie RAM na biegu jałowym: poniżej 1GB (z XFCE i Picom)
- Maksymalne zużycie RAM: 4GB (z otwartymi aplikacjami)

## Validation Strategy

### Komponent: Jądro systemu
- **Kryterium:** System bootuje się w UTM i wyświetla bootloader
- **Test:** Uruchomienie maszyny w UTM z wygenerowanym ISO, weryfikacja boot
- **Done:** Jądro bootuje, wykrywa sprzęt, montuje system plików

### Komponent: System bazowy
- **Kryterium:** Alpine Linux działa z siecią, dźwiękiem i menedżerem pakietów
- **Test:** `apk update`, `ping`, odtworzenie dźwięku
- **Done:** Wszystkie usługi bazowe działają poprawnie

### Komponent: Środowisko graficzne
- **Kryterium:** XFCE uruchamia się z Picom, animacje i przejrzystość działają
- **Test:** Otwarcie/zamknięcie okien, menu, panel zadań — płynne animacje
- **Done:** GUI responsywny, animacje płynne, brak tearing

### Komponent: Ekran logowania
- **Kryterium:** LightDM wyświetla ekran z brandingiem CrystalOS
- **Test:** Uruchomienie systemu, weryfikacja ekranu logowania, test z hasłem i bez
- **Done:** Ekran logowania wygląda jak CrystalOS, logowanie działa w obu trybach

### Komponent: Aplikacje
- **Kryterium:** Każda aplikacja uruchamia się i pełni swoją funkcję
- **Test:** CrystalBrowser ładuje stronę, Thunar otwiera pliki, terminal wykonuje komendy, Ristretto wyświetla obrazy, mpv odtwarza wideo
- **Done:** Wszystkie 5 aplikacji działa bez błędów

### Komponent: Branding
- **Kryterium:** Spójny wygląd CrystalOS we wszystkich miejscach
- **Test:** Weryfikacja tapety, ikon, motywu, ekranu boot, ekranu logowania
- **Done:** Brak elementów "Alpine" lub "XFCE" widocznych dla użytkownika — wszędzie CrystalOS

### Komponent: Potok budowania
- **Kryterium:** Jedno polecenie buduje kompletne ISO
- **Test:** Uruchomienie skryptu budowania od zera na czystym środowisku
- **Done:** ISO jest generowane, bootuje w UTM, system jest w pełni funkcjonalny

### Komponent: Wydajność
- **Kryterium:** System mieści się w limitach zasobów
- **Test:** Pomiar RAM (idle), rozmiaru ISO, rozmiaru po instalacji
- **Done:** RAM < 1GB idle, ISO < 2GB, zainstalowany < 10GB

## Out of Scope

- Wsparcie dla innych architektur niż x86_64 (na razie)
- Instalator graficzny (na razie instalacja przez skrypt)
- Większość języków — na razie tylko angielski i polski
- Szyfrowanie dysku (może w przyszłych wersjach)
- Aktualizacje automatyczne systemu
- Obsługa WiFi na etapie Beta (tylko Ethernet)
- Własne aplikacje natywne (poza CrystalBrowser)
- Dokumentacja dla użytkowników końcowych (na razie tylko deweloperska)
- Serwer (SSH, Apache, itp.) — system jest desktop-only
- Wsparcie dla Bluetooth
- Integracja z kontami online

## Further Notes

- **Użytkownik jest nowicjuszem** — wszystkie kroki muszą być dokładnie wyjaśnione
- **Claude Code pisze cały kod** — użytkownik akceptuje decyzje i testuje
- **Grafiki brandingowe** (tapeta PNG 1920x1080, logo PNG 256x256) — użytkownik dostarczy w odpowiednim momencie
- **Repozytorium:** github.com/CrystalGamesStudio/CrystalOS-Beta
- **Upstream jądra:** github.com/torvalds/linux
- **Testowanie:** UTM na macOS (Darwin)
- **Podejście iteracyjne** — budujemy krok po kroku, testujemy na bieżąco, poprawiamy co nie działa
