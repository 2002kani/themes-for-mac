# Theme Switcher

A minimal macOS menu bar app to define system themes and switch between them with one click.

A theme can set:

- Appearance (Light / Dark)
- Wallpaper, per screen
- Menu bar (always visible / auto-hide)
- Icon & widget style (Standard / Dark / Transparent / Tinted, macOS 26)

Each property can also be left as "Unchanged".

## Build & Run

Requires only the Command Line Tools:

```bash
bash build.sh
open ThemeSwitcher.app
```

A palette icon appears in the menu bar (no Dock icon).

## Usage

- Click the icon to see your themes (checkmark = active). Clicking one applies it.
- "Themes bearbeiten..." opens the editor to create, edit, and delete themes.

Themes are stored at `~/Library/Application Support/ThemeSwitcher/themes.json`.

## Permissions

The first time you switch Appearance or the Menu bar, macOS asks once for Automation
access ("control System Events"). Allow it once. Changing the icon style briefly restarts
the Dock so it takes effect immediately.

## Status

Currently under development but feel free to use it and give feedback. Just dont expect me to put my heart into this project since it already does what I needed..
