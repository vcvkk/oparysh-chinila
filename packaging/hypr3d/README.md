# Hypr3D assets (Oparysh Chinila)

At ISO build time `builder/vendor-hypr3d.sh`:

1. Bakes a **360° skybox** tiled with real **Apple Color Emoji ✅** (U+2705).
2. Installs **window-overlay.png** from **local packaging only** (no network).

## Window overlay (local only)

Put one of these under `packaging/hypr3d/` before build:

| File | Role |
|------|------|
| `window-overlay.png` | Preferred |
| `window-overlay.jpg` | Converted to PNG at build |
| `window-overlay.jpg.b64` | Base64 of JPEG (decoded at build) |
| `window-overlay.b64.d/*.b64part` | Split base64 parts (concatenated then decoded) |

If none exist, the vendor script **fails** (no Drive / no placeholder).

## Optional skybox override

| File | Role |
|------|------|
| `telegram-checks-skybox.png` | Custom 360° panorama |

Live paths:

```
/usr/share/oparysh-chinila/hypr3d/telegram-checks-skybox.png
/usr/share/oparysh-chinila/hypr3d/window-overlay.png
```
