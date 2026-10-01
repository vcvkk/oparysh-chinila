#!/bin/bash
# Clone Hypr3D; bake skybox from real Apple ✅ (U+2705) emoji bitmaps.
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

echo "[vendor-hypr3d] Fetching Apple ✅ (U+2705) bitmaps + baking skybox"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# Raster glyphs extracted from Apple Color Emoji (iamcal/emoji-data img-apple-*).
# Not a redraw — actual Apple platform art for CHECK MARK BUTTON.
for size in 160 64; do
  url="https://raw.githubusercontent.com/iamcal/emoji-data/master/img-apple-${size}/2705.png"
  if curl -fsSL -o "$WORK/2705-${size}.png" "$url"; then
    echo "[vendor-hypr3d] got img-apple-${size}/2705.png"
  fi
done
if [[ ! -f $WORK/2705-160.png && ! -f $WORK/2705-64.png ]]; then
  echo "[vendor-hypr3d] ERROR: could not download Apple ✅ PNG" >&2
  exit 1
fi

python3 - <<'PY'
from PIL import Image
import os

work = os.environ.get("WORK") or "/tmp"
# passed via env below
work = os.environ["HYPR3D_WORK"]
assets = os.environ["ASSETS"]

check_path = None
for name in ("2705-160.png", "2705-64.png"):
    p = os.path.join(work, name)
    if os.path.isfile(p):
        check_path = p
        break
if not check_path:
    raise SystemExit("no Apple check PNG")

check = Image.open(check_path).convert("RGBA")
# keep a single glyph sample in assets
check.save(os.path.join(assets, "apple-check-2705.png"), "PNG")

W, H = 4096, 2048
bg = (12, 14, 18, 255)
img = Image.new("RGBA", (W, H), bg)

base = 88
for gy in range(0, H, base):
    for gx in range(0, W, base):
        stagger = ((gy // base) % 2) * (base // 2)
        size = 48 + ((gx * 17 + gy * 11) % 24)
        glyph = check.resize((size, size), Image.Resampling.LANCZOS)
        if ((gx + gy) // base) % 4 == 0:
            a = glyph.split()[3].point(lambda v: int(v * 0.75))
            glyph.putalpha(a)
        x = gx + stagger + (base - size) // 2
        y = gy + (base - size) // 2
        x = min(max(0, x), W - size)
        y = min(max(0, y), H - size)
        img.alpha_composite(glyph, (x, y))

px = img.load()
for y in range(H):
    t = abs(y - H / 2) / (H / 2)
    if t < 0.5:
        continue
    fade = (t - 0.5) / 0.5
    dark = int(50 * fade)
    for x in range(W):
        r, g, b, a = px[x, y]
        px[x, y] = (max(0, r - dark), max(0, g - dark), max(0, b - dark), a)

out = os.path.join(assets, "telegram-checks-skybox.png")
img.convert("RGB").save(out, "PNG", optimize=True)
print("skybox", out, os.path.getsize(out))

# Placeholder overlay (user can replace)
ov = Image.new("RGBA", (1024, 1024), (26, 27, 38, 100))
ov.paste(check.resize((128, 128), Image.Resampling.LANCZOS), (448, 448), check.resize((128, 128), Image.Resampling.LANCZOS))
ov.save(os.path.join(assets, "window-overlay.png"), "PNG")
PY

export HYPR3D_WORK="$WORK"
HYPR3D_WORK="$WORK" ASSETS="$ASSETS" python3 - <<'PY'
from PIL import Image
import os

work = os.environ["HYPR3D_WORK"]
assets = os.environ["ASSETS"]
os.makedirs(assets, exist_ok=True)

check_path = None
for name in ("2705-160.png", "2705-64.png"):
    p = os.path.join(work, name)
    if os.path.isfile(p):
        check_path = p
        break
if not check_path:
    raise SystemExit("no Apple check PNG")

check = Image.open(check_path).convert("RGBA")
check.save(os.path.join(assets, "apple-check-2705.png"), "PNG")

W, H = 4096, 2048
bg = (12, 14, 18, 255)
img = Image.new("RGBA", (W, H), bg)

base = 88
for gy in range(0, H, base):
    for gx in range(0, W, base):
        stagger = ((gy // base) % 2) * (base // 2)
        size = 48 + ((gx * 17 + gy * 11) % 24)
        glyph = check.resize((size, size), Image.Resampling.LANCZOS)
        if ((gx + gy) // base) % 4 == 0:
            a = glyph.split()[3].point(lambda v: int(v * 0.75))
            glyph.putalpha(a)
        x = gx + stagger + (base - size) // 2
        y = gy + (base - size) // 2
        x = min(max(0, x), W - size)
        y = min(max(0, y), H - size)
        img.alpha_composite(glyph, (x, y))

px = img.load()
for y in range(H):
    t = abs(y - H / 2) / (H / 2)
    if t < 0.5:
        continue
    fade = (t - 0.5) / 0.5
    dark = int(50 * fade)
    for x in range(W):
        r, g, b, a = px[x, y]
        px[x, y] = (max(0, r - dark), max(0, g - dark), max(0, b - dark), a)

out = os.path.join(assets, "telegram-checks-skybox.png")
img.convert("RGB").save(out, "PNG", optimize=True)
print("skybox", out, os.path.getsize(out))

g = check.resize((128, 128), Image.Resampling.LANCZOS)
ov = Image.new("RGBA", (1024, 1024), (26, 27, 38, 100))
ov.paste(g, (448, 448), g)
ov.save(os.path.join(assets, "window-overlay.png"), "PNG")
PY

if [[ -f $ROOT/packaging/hypr3d/window-overlay.png ]]; then
  cp -f "$ROOT/packaging/hypr3d/window-overlay.png" "$ASSETS/window-overlay.png"
fi
if [[ -f $ROOT/packaging/hypr3d/telegram-checks-skybox.png ]]; then
  cp -f "$ROOT/packaging/hypr3d/telegram-checks-skybox.png" "$ASSETS/telegram-checks-skybox.png"
fi

cat >"$ASSETS/README.txt" <<'EOF'
Oparysh Chinila / Hypr3D assets

telegram-checks-skybox.png  — 360 panorama tiled with Apple Color Emoji ✅ (U+2705)
                              bitmaps from iamcal/emoji-data img-apple-* (real Apple art)
apple-check-2705.png        — single glyph sample
window-overlay.png          — replace via packaging/hypr3d/window-overlay.png
EOF

mkdir -p "$ROOT/configs/airootfs/usr/local/bin" "$ROOT/configs/airootfs/usr/lib/hypr3d"

cat >"$ROOT/configs/airootfs/usr/local/bin/oparysh-hypr3d-apply-config" <<'EOF'
#!/bin/bash
set -euo pipefail
SKY=/usr/share/oparysh-chinila/hypr3d/telegram-checks-skybox.png
OVERLAY=/usr/share/oparysh-chinila/hypr3d/window-overlay.png
for _ in $(seq 1 30); do
  if hyprctl plugin list 2>/dev/null | grep -qi hypr3d; then break; fi
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
echo "[hypr3d] skybox=$SKY (Apple ✅) overlay=$OVERLAY"
EOF
chmod +x "$ROOT/configs/airootfs/usr/local/bin/oparysh-hypr3d-apply-config"

cat >"$ROOT/configs/airootfs/usr/local/bin/oparysh-build-hypr3d" <<'EOF'
#!/bin/bash
set -euo pipefail
SRC=/usr/src/Hypr3D
OUT=/usr/lib/hypr3d/hypr3d.so
HEADERS="${HYPRLAND_HEADERS:-}"
if [[ -z $HEADERS && -f /usr/include/hyprland/src/plugins/PluginAPI.hpp ]]; then
  HEADERS=/usr
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
oparysh-hypr3d-apply-config || true
echo "Installed $OUT"
EOF
chmod +x "$ROOT/configs/airootfs/usr/local/bin/oparysh-build-hypr3d"

echo "[vendor-hypr3d] Done."
ls -la "$ASSETS"
