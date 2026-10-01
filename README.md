# Oparysh Chinila

Rescue ISO: **Hyprland** desktop with Eblan Browser, Eblanity, Ollama, and a pile of recovery tools. Boots straight into a graphical session.

Download from [Releases](https://github.com/vcvkk/oparysh-chinila/releases) (or Actions artifacts), verify `.sha256`, write to USB.

## Boot entries

- **Oparysh Chinila / Omarchy Rescue** (default): **Hyprland** on tty1 (full Wayland stack).
- **basic console**: plain getty + `nomodeset` if graphics die.

## Desktop (Hyprland)

Shipped stack includes Hyprland, waybar, kitty, wofi, thunar, pipewire, portals, fonts, GPU userspace (mesa/vulkan), Firefox, Eblan, etc.

Config: `/root/.config/hypr/hyprland.conf`

| Bind | Action |
|------|--------|
| Super+Return | kitty |
| Super+B | eblan |
| Super+F | firefox |
| Super+E | thunar |
| Super+R | wofi |
| Super+F12 | Hypr3D toggle (if plugin loaded) |

### Hypr3D

Sources from [samine825/Hypr3D](https://github.com/samine825/Hypr3D) are vendored to `/usr/src/Hypr3D` at build time.

```bash
# Offline build against installed hyprland headers (best-effort; plugin pins 0.56.2)
oparysh-build-hypr3d
# then restart Hyprland or: hyprctl plugin load /usr/lib/hypr3d/hypr3d.so

# Online alternative
hyprpm add https://github.com/samine825/Hypr3D
hyprpm enable Hypr3D
```

## Offline Eblan stack

| Component | On ISO |
|-----------|--------|
| EBLAN Browser | `/opt/eblan-browser` + `eblan` |
| Eblanity CLI | `eblanity` |

## Using it

```
impala                  Wi-Fi TUI
oparysh-chinila-mount   unlock/mount install at /mnt
arch-chroot /mnt
eblan / eblanity / ollama
oparysh-chinila         text menu (in a terminal)
```

## Building

```bash
bin/omarchy-rescue-make                   # rescue-only ISO
bin/omarchy-rescue-make --with-installer  # installer + rescue
bin/omarchy-rescue-boot                   # QEMU
```

Build needs network once (Eblan, Hypr3D sources, Arch packages). ISO may exceed 2 GiB with the full desktop — use Actions artifacts if GitHub Releases rejects the upload.

## Layout

```
configs/rescue.packages              packages (Hyprland + Eblan + tools)
configs/airootfs/root/.config/hypr/  Hyprland config
configs/airootfs/usr/src/Hypr3D/     vendored plugin sources
builder/vendor-eblan.sh
builder/vendor-hypr3d.sh
```

## License

MIT for this repo packaging. Upstream licenses apply to software on the ISO.
