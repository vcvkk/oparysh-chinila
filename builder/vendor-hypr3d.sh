#!/bin/bash
# Clone Hypr3D (0.5.0+: locations, physics); bake Apple ✅ skybox; local overlay.
set -euo pipefail

ROOT=$(realpath "${BASH_SOURCE[0]%/*}/..")
DEST="$ROOT/configs/airootfs/usr/src/Hypr3D"
ASSETS="$ROOT/configs/airootfs/usr/share/oparysh-chinila/hypr3d"
export ASSETS
REPO_URL="${HYPR3D_URL:-https://github.com/samine825/Hypr3D.git}"
# Prefer explicit ref: tag v0.5.0 if present, else main (0.5.0 landed 2026-10-01).
HYPR3D_REF="${HYPR3D_REF:-main}"
PKG="$ROOT/packaging/hypr3d"

echo "[vendor-hypr3d] Cloning $REPO_URL ($HYPR3D_REF) -> $DEST"
rm -rf "$DEST"
mkdir -p "$(dirname "$DEST")" "$ASSETS"

if ! git clone --depth 1 --branch "$HYPR3D_REF" "$REPO_URL" "$DEST"; then
  echo "[vendor-hypr3d] branch/tag $HYPR3D_REF failed, trying main" >&2
  rm -rf "$DEST"
  git clone --depth 1 --branch main "$REPO_URL" "$DEST"
fi
REV=$(git -C "$DEST" rev-parse HEAD)
REV_SHORT=$(git -C "$DEST" rev-parse --short HEAD)
echo "$REV" >"$ASSETS/hypr3d-source.rev"
echo "[vendor-hypr3d] source $REV_SHORT ($REV)"
rm -rf "$DEST/.git"

echo "[vendor-hypr3d] Fetching Apple ✅ (U+2705) + baking skybox"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

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
img = Image.new("RGBA", (W, H), (12, 14, 18, 255))

base = 88
for gy in range(0, H, base):
    for gx in range(0, W, base):
        stagger = ((gy // base) % 2) * (base // 2)
        size = 48 + ((gx * 17 + gy * 11) % 24)
        glyph = check.resize((size, size), Image.Resampling.LANCZOS)
        if ((gx + gy) // base) % 4 == 0:
            a = glyph.split()[3].point(lambda v: int(v * 0.75))
            glyph.putalpha(a)
        x = min(max(0, gx + stagger + (base - size) // 2), W - size)
        y = min(max(0, gy + (base - size) // 2), H - size)
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
PY

# --- window overlay: local packaging only ---
echo "[vendor-hypr3d] Window overlay (local only)"
if [[ -f $PKG/window-overlay.png ]]; then
  cp -f "$PKG/window-overlay.png" "$ASSETS/window-overlay.png"
  echo "[vendor-hypr3d] packaging/hypr3d/window-overlay.png"
elif [[ -d $PKG/window-overlay.b64.d ]]; then
  python3 - <<PY
import base64, glob, os
from PIL import Image
from io import BytesIO
parts = sorted(glob.glob("$PKG/window-overlay.b64.d/*.b64part"))
if not parts:
    raise SystemExit("no b64 parts")
b64 = "".join(open(p).read().strip() for p in parts)
raw = base64.b64decode(b64)
im = Image.open(BytesIO(raw)).convert("RGBA")
im.save("$ASSETS/window-overlay.png", "PNG")
print("overlay from b64.d", im.size, len(raw), "parts", len(parts))
PY
else
  echo "[vendor-hypr3d] ERROR: need packaging/hypr3d/window-overlay.png or window-overlay.b64.d/" >&2
  exit 1
fi

if [[ -f $PKG/telegram-checks-skybox.png ]]; then
  cp -f "$PKG/telegram-checks-skybox.png" "$ASSETS/telegram-checks-skybox.png"
fi

cat >"$ASSETS/README.txt" <<EOF
Oparysh Chinila / Hypr3D assets
Hypr3D source rev: $REV_SHORT (full: $REV)
Upstream: https://github.com/samine825/Hypr3D (0.5.0+ locations/physics)
window-overlay.png — from packaging/hypr3d/window-overlay.png or .b64.d parts
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
echo "[hypr3d] skybox=$SKY overlay=$OVERLAY"
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
