#!/bin/bash
# Download EBLAN Browser + Eblanity CLI into configs/airootfs.
# Eblanity is wrapped so first run does not try to pull multi-GB models.
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
src=$(find "$TMP/extract" -mindepth 1 -maxdepth 1 -type d | head -n1)
if [[ -z ${src:-} ]]; then
  echo "vendor-eblan: no top-level dir in zip" >&2
  exit 1
fi
cp -a "$src"/. "$OPT/"

log "Downloading Eblanity CLI from $EBLANITY_URL"
mkdir -p "$BIN" "$LIB"
curl -fsSL -o "$LIB/eblanity.bin" "$EBLANITY_URL"
chmod 755 "$LIB/eblanity.bin"

log "Writing offline eblanity wrapper"
cat >"$BIN/eblanity" <<'EOF'
#!/usr/bin/env bash
# Offline-first launcher. Real binary lives in /usr/local/lib/eblanity/.
# -no-update: never phone home for CLI updates.
# First-run model download is declined automatically (ISO has no 3GB model baked).
set -euo pipefail
REAL=/usr/local/lib/eblanity/eblanity.bin
if [[ ! -x $REAL ]]; then
  echo "eblanity: missing $REAL (vendor-eblan.sh not run at build?)" >&2
  exit 1
fi

# Skip interactive "download model now?" on first launch when no TTY answer expected.
if [[ ! -d ${HOME:-/root}/.eblanity/models ]] && [[ -t 0 ]]; then
  # Prefer local ollama if present instead of multi-GB eblama pull.
  if command -v ollama >/dev/null 2>&1; then
    echo "eblanity: models not vendored; use ollama for offline AI, or run once online to fetch eblangpt." >&2
  fi
fi

# Always refuse interactive download prompt by answering n when setup would ask.
if [[ ! -d ${HOME:-/root}/.eblanity ]]; then
  exec /usr/bin/script -qfc "$REAL -no-update $*" /dev/null <<'ANS'
n
ANS
fi

exec "$REAL" -no-update "$@"
EOF
chmod 755 "$BIN/eblanity"

log "Writing eblan launcher"
cat >"$BIN/eblan" <<'EOF'
#!/usr/bin/env bash
export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-wayland;xcb}"
if [[ ! -f /opt/eblan-browser/EBLAN.py ]]; then
  echo "eblan: /opt/eblan-browser/EBLAN.py missing" >&2
  exit 1
fi
exec /usr/bin/python /opt/eblan-browser/EBLAN.py "$@"
EOF
chmod 755 "$BIN/eblan"

log "Desktop entry + icons"
mkdir -p "$DESKTOP_DIR"
cat >"$DESKTOP_DIR/eblan-browser.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=EBLAN Browser
GenericName=EBLAN Browser
Comment=EBLAN Browser
Exec=/usr/local/bin/eblan %U
Icon=eblan-browser
Terminal=false
Categories=Network;WebBrowser;
MimeType=text/html;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
StartupWMClass=EBLAN Browser
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
ls -lh "$BIN/eblan" "$BIN/eblanity" "$LIB/eblanity.bin" "$OPT/EBLAN.py"
