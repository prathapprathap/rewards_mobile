#!/usr/bin/env bash
# Installs the new Rupi Rewards app icon and regenerates all Android/iOS
# launcher icons.
#
# Usage:  ./install_new_icon.sh /path/to/new_icon.png
# The source image should be a square PNG, ideally 1024x1024.

set -euo pipefail

SRC="${1:-}"
if [[ -z "$SRC" || ! -f "$SRC" ]]; then
  echo "❌ Provide the path to the new icon PNG."
  echo "   e.g. ./install_new_icon.sh ~/Downloads/rupi_icon.png"
  exit 1
fi

ROOT="$(cd "$(dirname "$0")" && pwd)"
DEST="$ROOT/assets/images/app_icon.png"
DEST_FG="$ROOT/assets/images/app_icon_foreground.png"

echo "📥 Copying $SRC -> assets/images/app_icon.png"
cp "$SRC" "$DEST"
cp "$SRC" "$DEST_FG"

echo "🎨 Regenerating launcher icons via flutter_launcher_icons…"
cd "$ROOT"
flutter pub get
dart run flutter_launcher_icons

echo "✅ Done. Rebuild the app (flutter run / flutter build apk) to see the new icon."
