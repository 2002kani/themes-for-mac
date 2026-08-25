# Theme Switcher

Eine schlanke macOS-Menu-Bar-App, mit der du **Themes** definierst und per Klick umschaltest.
Ein Theme bündelt:

- 🌓 **Erscheinungsbild** – Hell / Dunkel
- 🖼️ **Hintergrund** – eigenes Wallpaper **pro Bildschirm** (stabil über Display-UUID)
- 📏 **Menüleiste** – immer sichtbar / automatisch ausblenden
- 🎨 **Symbol- & Widget-Stil** – Standard / Dunkel / Transparent / Eingefärbt (macOS 26)

Jede Eigenschaft kann pro Theme auch auf *„Unverändert"* stehen bleiben.

## Bauen & Starten

Es wird nur die **Command Line Tools**-Toolchain benötigt (kein volles Xcode):

```bash
bash build.sh
open ThemeSwitcher.app
```

Danach erscheint ein Paletten-Icon 🎨 in der Menüleiste (kein Dock-Icon).

## Bedienung

- **Icon anklicken** → Liste der Themes (Häkchen = aktiv). Klick wendet das Theme an.
- **„Themes bearbeiten…"** → Editor zum Anlegen/Bearbeiten/Löschen.
  - „Sichern" speichert, „Jetzt anwenden" setzt das Theme sofort.

## Berechtigungen

Beim ersten Umschalten von **Erscheinungsbild** oder **Menüleiste** fragt macOS einmalig nach der
Automation-Berechtigung („Theme Switcher möchte *System Events* steuern"). Einmal erlauben – danach
läuft es ohne Rückfrage. Nachträglich änderbar unter
*Systemeinstellungen › Datenschutz & Sicherheit › Automation*.

Wallpaper und Symbol-/Widget-Stil brauchen keine Sonderberechtigung. Der Symbol-Stil wird über
`AppleIconAppearanceTheme` gesetzt; damit er sofort greift, startet die App kurz das **Dock** neu
(kurzes Flackern des Docks).

## Speicherort der Themes

```
~/Library/Application Support/ThemeSwitcher/themes.json
```

## Grenzen (v1)

- **Akzent-/Highlight-Farbe** ist nicht enthalten: macOS übernimmt diese bei laufenden Apps nicht
  zuverlässig live (oft erst nach Ab-/Anmelden).
- Beim **Symbol-/Widget-Stil** wird aktuell nur der Stil selbst gesetzt; eine **eigene Tint-Farbe**
  für „Eingefärbt" ist noch nicht angebunden (nutzt die Systemvorgabe).
- Der Symbol-Stil nutzt den privaten Schlüssel `AppleIconAppearanceTheme` (macOS 26) – kann sich mit
  künftigen macOS-Versionen ändern.
- Der lokale Build ist nur ad-hoc signiert. Falls Gatekeeper meckert: Rechtsklick auf die App →
  „Öffnen".
```
