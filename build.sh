#!/bin/bash
# Baut ThemeSwitcher und packt das Ergebnis zu einem .app-Bundle.
# Benötigt nur die Command Line Tools (kein volles Xcode).
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="ThemeSwitcher"
CONFIG="release"
BUILD_DIR=".build/${CONFIG}"
APP_BUNDLE="${APP_NAME}.app"

echo "==> Kompiliere (${CONFIG})…"
swift build -c "${CONFIG}"

BIN_PATH="${BUILD_DIR}/${APP_NAME}"
if [[ ! -f "${BIN_PATH}" ]]; then
    # Fallback: exakten Pfad über SwiftPM ermitteln.
    BIN_PATH="$(swift build -c "${CONFIG}" --show-bin-path)/${APP_NAME}"
fi

echo "==> Baue ${APP_BUNDLE}…"
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${BIN_PATH}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
cp "Resources/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"

# Ad-hoc-Signatur, damit die TCC-Automation-Berechtigung stabil zugeordnet wird.
codesign --force --sign - "${APP_BUNDLE}" 2>/dev/null || \
    echo "   (Hinweis: codesign übersprungen — App bleibt unsigniert.)"

echo ""
echo "Fertig: ${APP_BUNDLE}"
echo "Starten mit:  open ${APP_BUNDLE}"
