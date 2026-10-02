# Hypr3D assets (Oparysh Chinila)

At ISO build time `builder/vendor-hypr3d.sh`:

1. Bakes a **360° skybox** tiled with real **Apple Color Emoji ✅** (U+2705).
2. Installs **window-overlay.png** (image for 3D window quads / panels).

## Window overlay priority

1. `packaging/hypr3d/window-overlay.png` (if present in the repo at build)
2. Else download from `WINDOW_OVERLAY_URL` (default: your Google Drive photo)
3. Else a small placeholder

Default Drive id is baked into the vendor script. Override at build:

```bash
export WINDOW_OVERLAY_URL='https://drive.google.com/uc?export=download&id=YOUR_FILE_ID'
bin/omarchy-rescue-make
```

## Optional local overrides

| File | Role |
|------|------|
| `window-overlay.png` | Your image on every 3D window quad |
| `telegram-checks-skybox.png` | Custom 360° panorama (e.g. 4096×2048 equirect) |
| `map.glb` / `map.gltf` | Optional room model (`map.path`) |

Live paths:

```
/usr/share/oparysh-chinila/hypr3d/telegram-checks-skybox.png
/usr/share/oparysh-chinila/hypr3d/window-overlay.png
```

Skybox is applied by `oparysh-hypr3d-apply-config` (`panorama`, `grid = false`).

**Note:** Overlay blending depends on the Hypr3D plugin build supporting the overlay texture slot; the panorama skybox works with upstream Hypr3D once `panorama` is set.
