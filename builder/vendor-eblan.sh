#!/bin/bash
# Download EBLAN Browser + Eblanity CLI into configs/airootfs.
set -euo pipefail

ROOT=$(realpath "${BASH_SOURCE[0]%/*}/..")
AIROOTFS=$ROOT/configs/airootfs
OPT=$AIROOTFS/opt/eblan-browser
BIN=$AIROOTFS/usr/local/bin
LIB=$AIROOTFS/usr/local/lib/eblanity
DESKTOP_DIR=$AIROOTFS/usr/share/applications
ICON_BASE=$AIROOTFS/usr/share/icons/hicolor
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

ZIP_URL="${EBLAN_ZIP_URL:-https://update.riba.click/eb/r/lastest.zip}"
EBLANITY_URL="${EBLANITY_URL:-https://eblansoft.ru/upd/eblanityCLI/eblanity}"

log() { printf '[vendor-eblan] %s\n' "$*"; }
need() { command -v "$1" >/dev/null 2>&1 || { echo "need $1" >&2; exit 1; }; }
need curl
need unzip

log "Downloading EBLAN Browser from $ZIP_URL"
curl -fsSL -o "$TMP/lastest.zip" "$ZIP_URL"
rm -rf "$OPT"
mkdir -p "$OPT"
unzip -q "$TMP/lastest.zip" -d "$TMP/extract"
src=$(find "$TMP/extract" -mindepth 1 -maxdepth 1 -type d | head -n1)
[[ -n $src ]] || { echo "no top-level dir in zip" >&2; exit 1; }
cp -a "$src"/. "$OPT/"

log "Downloading Eblanity CLI"
mkdir -p "$BIN" "$LIB"
curl -fsSL -o "$LIB/eblanity.bin" "$EBLANITY_URL"
chmod 755 "$LIB/eblanity.bin"

cat >"$BIN/eblanity" <<'EOF'
#!/usr/bin/env bash
# Offline-first: never auto-update; refuse first-run multi-GB model download.
set -euo pipefail
REAL=/usr/local/lib/eblanity/eblanity.bin
[[ -x $REAL ]] || { echo "eblanity: missing $REAL" >&2; exit 1; }

# Decline interactive model download on first run (answers n to [Y/n]).
if [[ ! -d ${HOME:-/root}/.eblanity ]]; then
  printf 'n\n' | exec "$REAL" -no-update "$@"
fi
exec "$REAL" -no-update "$@"
EOF
chmod 755 "$BIN/eblanity"

cat >"$BIN/eblan" <<'EOF'
#!/usr/bin/env bash
export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-wayland;xcb}"
[[ -f /opt/eblan-browser/EBLAN.py ]] || { echo "eblan: missing EBLAN.py" >&2; exit 1; }
exec /usr/bin/python /opt/eblan-browser/EBLAN.py "$@"
EOF
chmod 755 "$BIN/eblan"

mkdir -p "$DESKTOP_DIR"
cat >"$DESKTOP_DIR/eblan-browser.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=EBLAN Browser
Exec=/usr/local/bin/eblan %U
Icon=eblan-browser
Terminal=false
Categories=Network;WebBrowser;
EOF

for size in 64 128 256; do
  src="$OPT/images/logo${size}.png"
  [[ -f $src ]] || continue
  mkdir -p "$ICON_BASE/${size}x${size}/apps"
  cp -f "$src" "$ICON_BASE/${size}x${size}/apps/eblan-browser.png"
done

log "Done"
ls -lh "$BIN/eblan" "$BIN/eblanity" "$LIB/eblanity.bin" "$OPT/EBLAN.py"
