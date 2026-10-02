# Hypr3D assets (Oparysh Chinila)

`builder/vendor-hypr3d.sh` at ISO build:

1. Bakes **360° skybox** with Apple Color Emoji ✅ (U+2705).
2. Copies **only** `packaging/hypr3d/window-overlay.png` into the image.

No Google Drive, no URL fallbacks.

## Required

```
packaging/hypr3d/window-overlay.png
```

If missing, the build fails.

## Optional

```
packaging/hypr3d/telegram-checks-skybox.png   # custom panorama
```

Live paths:

```
/usr/share/oparysh-chinila/hypr3d/telegram-checks-skybox.png
/usr/share/oparysh-chinila/hypr3d/window-overlay.png
```
