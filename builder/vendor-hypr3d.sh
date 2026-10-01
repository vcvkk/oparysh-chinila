#!/bin/bash
# Clone Hypr3D, generate Oparysh Chinila skybox (Telegram ✓✓), ship overlay slot.
set -euo pipefail

ROOT=$(realpath "${BASH_SOURCE[0]%/*}/..")
DEST="$ROOT/configs/airootfs/usr/src/Hypr3D"
ASSETS="$ROOT/configs/airootfs/usr/share/oparysh-chinila/hypr3d"
export ASSETS
REPO_URL="${HYPR3D_URL:-https://github.com/samine825/Hypr3D.git}"

echo "[vendor-hypr3d] Cloning $REPO_URL -> $DEST"
rm -rf "$DEST"
mkdir -p "$(dirname "$DEST")" "$ASSETS"
git clone --depth 1 "$REPO_URL" "$DEST"
rm -rf "$DEST/.git"

echo "[vendor-hypr3d] Generating telegram-checks-skybox.png"
python3 - <<'PY'
from PIL import Image, ImageDraw
import os

W, H = 4096, 2048
bg = (15, 20, 28)
check_color = (84, 172, 225)
check_dim = (50, 110, 150)

img = Image.new("RGB", (W, H), bg)
draw = ImageDraw.Draw(img)

def draw_double_check(d, x, y, s, color):
    w = max(2, int(s * 0.12))
    pts1 = [(x - 0.35 * s, y), (x - 0.1 * s, y + 0.35 * s), (x + 0.4 * s, y - 0.35 * s)]
    pts2 = [(x - 0.1 * s, y), (x + 0.15 * s, y + 0.35 * s), (x + 0.65 * s, y - 0.35 * s)]
    d.line(pts1, fill=color, width=w)
    d.line(pts2, fill=color, width=w)

cell = 96
for gy in range(0, H, cell):
    for gx in range(0, W, cell):
        ox = (gy // cell) % 2 * (cell // 2)
        cx = gx + ox + cell // 2
        cy = gy + cell // 2
        s = 28 + ((gx * 13 + gy * 7) % 17)
        col = check_color if ((gx + gy) // cell) % 3 else check_dim
        draw_double_check(draw, cx, cy, s, col)

pixels = img.load()
for y in range(H):
    t = abs(y - H / 2) / (H / 2)
    if t < 0.55:
        continue
    fade = (t - 0.55) / 0.45
    dark = int(40 * fade)
    for x in range(W):
        r, g, b = pixels[x, y]
        pixels[x, y] = (max(0, r - dark), max(0, g - dark), max(0, b - dark))

out = os.environ["ASSETS"]
os.makedirs(out, exist_ok=True)
img.save(os.path.join(out, "telegram-checks-skybox.png"), "PNG", optimize=True)

ov = Image.new("RGBA", (1024, 1024), (26, 27, 38, 100))
d2 = ImageDraw.Draw(ov)
for y in range(40, 1024, 80):
    for x in range(40, 1024, 80):
        draw_double_check(d2, x, y, 22, (84, 172, 225, 70))
d2.rectangle([8, 8, 1015, 1015], outline=(84, 172, 225, 140), width=4)
d2.text((120, 490), "REPLACE window-overlay.png", fill=(192, 202, 245, 200))
ov.save(os.path.join(out, "window-overlay.png"), "PNG")
print("assets ok", out)
PY

if [[ -f $ROOT/packaging/hypr3d/window-overlay.png ]]; then
  cp -f "$ROOT/packaging/hypr3d/window-overlay.png" "$ASSETS/window-overlay.png"
  echo "[vendor-hypr3d] Using packaging/hypr3d/window-overlay.png"
fi
if [[ -f $ROOT/packaging/hypr3d/telegram-checks-skybox.png ]]; then
  cp -f "$ROOT/packaging/hypr3d/telegram-checks-skybox.png" "$ASSETS/telegram-checks-skybox.png"
  echo "[vendor-hypr3d] Using packaging/hypr3d/telegram-checks-skybox.png"
fi

cat >"$ASSETS/README.txt" <<'EOF'
Oparysh Chinila / Hypr3D assets

telegram-checks-skybox.png  — equirectangular 360 skybox (Telegram double-check pattern)
window-overlay.png          — drop your image here (packaging/hypr3d/window-overlay.png at build)

Optional map: put a .glb here and set map.path in hypr3d-world.lua later.
EOF

mkdir -p "$ROOT/configs/airootfs/usr/local/bin" "$ROOT/configs/airootfs/usr/lib/hypr3d"

cat >"$ROOT/configs/airootfs/usr/local/bin/oparysh-hypr3d-apply-config" <<'EOF'
#!/bin/bash
set -euo pipefail
SKY=/usr/share/oparysh-chinila/hypr3d/telegram-checks-skybox.png
OVERLAY=/usr/share/oparysh-chinila/hypr3d/window-overlay.png
for _ in $(seq 1 30); do
  if hyprctl plugin list 2>/dev/null | grep -qi hypr3d; then
    break
  fi
  sleep 0.2
done
if hyprctl --help 2>&1 | grep -q eval; then
  hyprctl eval "
    if hl and hl.plugin and hl.plugin.hypr3d then
      hl.plugin.hypr3d.config({
        world = { panorama = [[$SKY]], grid = false },
        map = { path = [[]] },
      })
    end
  " 2>/dev/null || true
fi
mkdir -p /root/.config/hypr
cat >/root/.config/hypr/hypr3d-world.lua <<LUA
if hl and hl.plugin and hl.plugin.hypr3d then
  hl.plugin.hypr3d.config({
    world = { panorama = "$SKY", grid = false },
    map = { path = "" },
  })
end
LUA
echo "[hypr3d] skybox=$SKY overlay=$OVERLAY"
EOF
chmod +x "$ROOT/configs/airootfs/usr/local/bin/oparysh-hypr3d-apply-config"

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
  echo "Hyprland headers not found." >&2
  exit 1
fi
cmake -S "$SRC" -B "$SRC/build" -DHYPRLAND_HEADERS="$HEADERS"
cmake --build "$SRC/build" -j"$(nproc)"
so=$(find "$SRC/build" -maxdepth 1 -name '*.so' | head -n1)
[[ -n $so ]] || { echo "no .so" >&2; exit 1; }
install -Dm755 "$so" "$OUT"
echo "Installed $OUT"
oparysh-hypr3d-apply-config || true
EOF
chmod +x "$ROOT/configs/airootfs/usr/local/bin/oparysh-build-hypr3d"

echo "[vendor-hypr3d] Done."
ls -la "$ASSETS"
