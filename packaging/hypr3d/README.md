# Hypr3D assets (Oparysh Chinila)

At ISO build time `builder/vendor-hypr3d.sh` generates a **Telegram double-check** equirectangular skybox and a placeholder window overlay.

## Override with your own files

Put files here before `bin/omarchy-rescue-make`:

| File | Role |
|------|------|
| `window-overlay.png` | Your image — intended blend on every 3D window quad |
| `telegram-checks-skybox.png` | Optional custom 360° panorama (equirectangular, e.g. 4096×2048) |
| `map.glb` / `map.gltf` | Optional 3D room model (wire via `map.path` later) |

They are copied into the live image as:

```
/usr/share/oparysh-chinila/hypr3d/telegram-checks-skybox.png
/usr/share/oparysh-chinila/hypr3d/window-overlay.png
```

Hypr3D config (no grid floor, panorama only):

```lua
hl.plugin.hypr3d.config({
  world = {
    panorama = "/usr/share/oparysh-chinila/hypr3d/telegram-checks-skybox.png",
    grid = false,
  },
  map = { path = "" },
})
```

Applied by `oparysh-hypr3d-apply-config` after the plugin loads.

**Note:** Window overlay blending needs a matching plugin build; the skybox works with upstream Hypr3D as soon as `panorama` is set.
