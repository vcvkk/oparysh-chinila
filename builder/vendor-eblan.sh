#!/bin/bash
# Download EBLAN Browser + Eblanity CLI into configs/airootfs so the ISO is
# fully offline for both tools once built. Run from repo root before apply-rescue.
#
#   builder/vendor-eblan.sh
#
# Sources:
#   Browser zip: https://update.riba.click/eb/r/lastest.zip
#   Eblanity:    https://eblansoft.ru/upd/eblanityCLI/eblanity

set -euo pipefail

ROOT=$(realpath "${BASH_SOURCE[0]%/*}/..")
AIROOTFS=$ROOT/configs/airootfs
OPT=$AIROOTFS/opt/eblan-browser
BIN=$AIROOTFS/usr/local/bin
DESKTOP_DIR=$AIROOTFS/usr/share/applications
ICON_BASE=$AIROOTFS/usr/share/icons/hicolor
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

ZIP_URL="${EBLAN_ZIP_URL:-https://update.riba.click/eb/r/lastest.zip}"
EBLANITY_URL="${EBLANITY_URL:-https://eblansoft.ru/upd/eblanityCLI/eblanity}"

log() { printf '[vendor-eblan] %s\n' "$*"; }

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "vendor-eblan: need $1" >&2
    exit 1
  }
}
need curl
need unzip

log "Downloading EBLAN Browser from $ZIP_URL"
curl -fsSL -o "$TMP/lastest.zip" "$ZIP_URL"

log "Extracting into $OPT"
rm -rf "$OPT"
mkdir -p "$OPT"
unzip -q "$TMP/lastest.zip" -d "$TMP/extract"
# zip has a single top-level dir (R3/ etc.)
src=$(find "$TMP/extract" -mindepth 1 -maxdepth 1 -type d | head -n1)
if [[ -z ${src:-} ]]; then
  echo "vendor-eblan: no top-level dir in zip" >&2
  exit 1
fi
cp -a "$src"/. "$OPT/"

log "Downloading Eblanity CLI from $EBLANITY_URL"
mkdir -p "$BIN"
curl -fsSL -o "$BIN/eblanity" "$EBLANITY_URL"
chmod 755 "$BIN/eblanity"

log "Writing eblan launcher"
cat > "$BIN/eblan" <<'EOF'
#!/usr/bin/env bash
# Offline launcher for EBLAN Browser (vendored into the ISO).
export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-xcb}"
if [[ ! -f /opt/eblan-browser/EBLAN.py ]]; then
  echo "eblan: /opt/eblan-browser/EBLAN.py missing (vendor-eblan.sh not run at build?)" >&2
  exit 1
fi
exec /usr/bin/python /opt/eblan-browser/EBLAN.py "$@"
EOF
chmod 755 "$BIN/eblan"

log "Desktop entry + icons"
mkdir -p "$DESKTOP_DIR"
cat > "$DESKTOP_DIR/eblan-browser.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=EBLAN Browser
GenericName=EBLAN Browser
Comment=EBLAN Browser - халяль снаружи, передоз внутри
Exec=/usr/local/bin/eblan %U
Icon=eblan-browser
Terminal=false
Categories=Network;WebBrowser;
MimeType=text/html;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
StartupWMClass=EBLAN Browser
Keywords=browser;internet;web;eblan;
EOF

for size in 64 128 256; do
  src="$OPT/images/logo${size}.png"
  dst_dir="$ICON_BASE/${size}x${size}/apps"
  if [[ -f $src ]]; then
    mkdir -p "$dst_dir"
    cp -f "$src" "$dst_dir/eblan-browser.png"
  fi
done

log "Done. Browser -> $OPT , eblanity -> $BIN/eblanity"
ls -lh "$BIN/eblan" "$BIN/eblanity" "$OPT/EBLAN.py"
