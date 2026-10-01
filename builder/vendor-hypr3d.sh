#!/bin/bash
# Clone Hypr3D plugin sources into airootfs for offline presence + optional build.
set -euo pipefail

ROOT=$(realpath "${BASH_SOURCE[0]%/*}/..")
DEST="$ROOT/configs/airootfs/usr/src/Hypr3D"
REPO_URL="${HYPR3D_URL:-https://github.com/samine825/Hypr3D.git}"

echo "[vendor-hypr3d] Cloning $REPO_URL -> $DEST"
rm -rf "$DEST"
mkdir -p "$(dirname "$DEST")"
git clone --depth 1 "$REPO_URL" "$DEST"
rm -rf "$DEST/.git"

mkdir -p "$ROOT/configs/airootfs/usr/local/bin" "$ROOT/configs/airootfs/usr/lib/hypr3d"
cat >"$ROOT/configs/airootfs/usr/local/bin/oparysh-build-hypr3d" <<'EOF'
#!/bin/bash
set -euo pipefail
SRC=/usr/src/Hypr3D
OUT=/usr/lib/hypr3d/hypr3d.so
HEADERS="${HYPRLAND_HEADERS:-}"

if [[ -z $HEADERS ]]; then
  if [[ -f /usr/include/hyprland/src/plugins/PluginAPI.hpp ]]; then
    HEADERS=/usr
  fi
fi

if [[ -z ${HEADERS:-} ]]; then
  echo "Hyprland headers not found. Install hyprland and try again." >&2
  echo "Or online: hyprpm add https://github.com/samine825/Hypr3D && hyprpm enable Hypr3D" >&2
  exit 1
fi

echo "Building Hypr3D against HEADERS=$HEADERS"
cmake -S "$SRC" -B "$SRC/build" -DHYPRLAND_HEADERS="$HEADERS"
cmake --build "$SRC/build" -j"$(nproc)"
so=$(find "$SRC/build" -maxdepth 1 -name '*.so' | head -n1)
[[ -n $so ]] || { echo "no .so produced" >&2; exit 1; }
install -Dm755 "$so" "$OUT"
echo "Installed $OUT"
EOF
chmod +x "$ROOT/configs/airootfs/usr/local/bin/oparysh-build-hypr3d"

echo "[vendor-hypr3d] Done. Sources in $DEST"
