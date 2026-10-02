#!/bin/bash
# Download EBLAN Browser + Eblanity CLI + eblangpt-coder model into airootfs.
# Model is ~3GB (HuggingFace EBLANSoft/eblangpt-coder model.safetensors).
set -euo pipefail

ROOT=$(realpath "${BASH_SOURCE[0]%/*}/..")
AIROOTFS=$ROOT/configs/airootfs
OPT=$AIROOTFS/opt/eblan-browser
BIN=$AIROOTFS/usr/local/bin
LIB=$AIROOTFS/usr/local/lib/eblanity
SHARE=$AIROOTFS/usr/share/eblanity
MODEL_NAME=eblangpt-coder
MODEL_SHARE=$SHARE/models/$MODEL_NAME
ROOT_HOME_MODELS=$AIROOTFS/root/.eblanity/models/$MODEL_NAME
DESKTOP_DIR=$AIROOTFS/usr/share/applications
ICON_BASE=$AIROOTFS/usr/share/icons/hicolor
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

ZIP_URL="${EBLAN_ZIP_URL:-https://update.riba.click/eb/r/lastest.zip}"
EBLANITY_URL="${EBLANITY_URL:-https://eblansoft.ru/upd/eblanityCLI/eblanity}"
HF_BASE="${EBLANITY_HF_BASE:-https://huggingface.co/EBLANSoft/eblangpt-coder/resolve/main}"
# Skip huge model with EBLANITY_SKIP_MODEL=1 (dev builds only).
SKIP_MODEL="${EBLANITY_SKIP_MODEL:-0}"

log() { printf '[vendor-eblan] %s\n' "$*"; }
need() { command -v "$1" >/dev/null 2>&1 || { echo "need $1" >&2; exit 1; }; }
need curl
need unzip

download() {
  local url=$1 dest=$2
  log "GET $url"
  curl -fL --retry 5 --retry-delay 5 --connect-timeout 30 \
    -o "$dest" "$url"
  [[ -s $dest ]] || { echo "empty download: $url" >&2; exit 1; }
}

log "Downloading EBLAN Browser from $ZIP_URL"
download "$ZIP_URL" "$TMP/lastest.zip"
rm -rf "$OPT"
mkdir -p "$OPT"
unzip -q "$TMP/lastest.zip" -d "$TMP/extract"
src=$(find "$TMP/extract" -mindepth 1 -maxdepth 1 -type d | head -n1)
[[ -n $src ]] || { echo "no top-level dir in zip" >&2; exit 1; }
cp -a "$src"/. "$OPT/"

log "Downloading Eblanity CLI"
mkdir -p "$BIN" "$LIB"
download "$EBLANITY_URL" "$LIB/eblanity.bin"
chmod 755 "$LIB/eblanity.bin"

if [[ $SKIP_MODEL != 1 ]]; then
  log "Downloading offline model $MODEL_NAME (~3GB) — this takes a while"
  mkdir -p "$MODEL_SHARE"
  # Weights + tokenizer/config so eblama can convert/run without network.
  for f in model.safetensors tokenizer.json tokenizer_config.json config.json generation_config.json chat_template.jinja; do
    if download "$HF_BASE/$f" "$MODEL_SHARE/$f"; then
      log "  ok $f ($(du -h "$MODEL_SHARE/$f" | cut -f1))"
    else
      # optional small files may 404
      rm -f "$MODEL_SHARE/$f"
      log "  skip $f (not on hub)"
    fi
  done
  [[ -s $MODEL_SHARE/model.safetensors ]] || {
    echo "vendor-eblan: model.safetensors missing after download" >&2
    exit 1
  }
  # Seed root home so first boot finds models without copying 3GB.
  mkdir -p "$(dirname "$ROOT_HOME_MODELS")"
  rm -rf "$ROOT_HOME_MODELS"
  ln -sfn "/usr/share/eblanity/models/$MODEL_NAME" "$ROOT_HOME_MODELS"
  # Marker so wrapper knows models are present.
  mkdir -p "$AIROOTFS/root/.eblanity"
  echo "$MODEL_NAME" >"$AIROOTFS/root/.eblanity/default-model"
  log "Model installed under /usr/share/eblanity/models/$MODEL_NAME"
else
  log "EBLANITY_SKIP_MODEL=1 — not baking weights"
fi

cat >"$BIN/eblanity" <<'EOF'
#!/usr/bin/env bash
# Offline-first eblanity: -no-update; wire vendored models into $HOME.
set -euo pipefail
REAL=/usr/local/lib/eblanity/eblanity.bin
[[ -x $REAL ]] || { echo "eblanity: missing $REAL" >&2; exit 1; }

HOME="${HOME:-/root}"
SHARE_MODELS=/usr/share/eblanity/models
mkdir -p "$HOME/.eblanity/models"

if [[ -d $SHARE_MODELS ]]; then
  for d in "$SHARE_MODELS"/*; do
    [[ -d $d ]] || continue
    name=$(basename "$d")
    target="$HOME/.eblanity/models/$name"
    if [[ ! -e $target ]]; then
      ln -sfn "$d" "$target"
    fi
  done
fi

# Prefer local model; never check for CLI updates.
exec "$REAL" -no-update -local-model eblangpt-coder "$@"
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
ls -lh "$BIN/eblan" "$BIN/eblanity" "$LIB/eblanity.bin" "$OPT/EBLAN.py" || true
if [[ -f $MODEL_SHARE/model.safetensors ]]; then
  ls -lh "$MODEL_SHARE/model.safetensors"
fi
