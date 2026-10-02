# oparysh chinila ✅

da. ✅

rescue iso с hyprland. eblan. eblanity. ollama. куча тулз для восстановления. ✅

загрузка сразу в графон. ✅

**это не вайбкод.** ✅

**все сам.** ✅

никаких клаудов. никаких кодексов. никаких «сгенерируй репо». ☝️

качал. правил. вендорил. собирал. ✅

---

## скачать ✅

[releases](https://github.com/vcvkk/oparysh-chinila/releases) или actions artifacts. ✅

проверь `.sha256`. ✅

запиши на флешку. ✅

---

## бут ✅

- **oparysh chinila / omarchy rescue** (дефолт) — hyprland на tty1. полный wayland. ✅
- **basic console** — getty + `nomodeset` если видео умерло. ✅

---

## десктоп ✅

hyprland. waybar. kitty. wofi. thunar. pipewire. порталы. шрифты. mesa/vulkan. firefox. eblan. ✅

конфиг: `/root/.config/hypr/hyprland.conf` ✅

| бинд | что |
|------|-----|
| super+return | kitty ✅ |
| super+b | eblan ✅ |
| super+f | firefox ✅ |
| super+e | thunar ✅ |
| super+r | wofi ✅ |
| super+f12 | hypr3d toggle ✅ |

### hypr3d ✅

сорцы с [samine825/hypr3d](https://github.com/samine825/Hypr3D) кладутся в `/usr/src/hypr3d` на билде. ✅

скайбокс из apple ✅. оверлей окон — своя картинка. ✅

```bash
oparysh-build-hypr3d
# потом рестарт hyprland или:
hyprctl plugin load /usr/lib/hypr3d/hypr3d.so
```

онлайн вариант:

```bash
hyprpm add https://github.com/samine825/Hypr3D
hyprpm enable Hypr3D
```

---

## оффлайн eblan ✅

| что | где |
|-----|-----|
| eblan browser | `/opt/eblan-browser` + `eblan` ✅ |
| eblanity cli | `eblanity` ✅ |

без интернета после бута. ✅

---

## как юзать ✅

```
impala                  # wifi tui ✅
oparysh-chinila-mount   # unlock/mount в /mnt ✅
arch-chroot /mnt        # ✅
eblan / eblanity / ollama  # ✅
oparysh-chinila         # текстовое меню ✅
```

---

## сборка ✅

```bash
bin/omarchy-rescue-make                   # только rescue ✅
bin/omarchy-rescue-make --with-installer  # installer + rescue ✅
bin/omarchy-rescue-boot                   # qemu ✅
```

на билде нужен инет один раз (eblan. hypr3d. arch пакеты). ✅

iso может быть >2gb. тогда бери из actions. ✅

broadcom-wl-dkms + linux-headers уже в пакетах. ✅

---

## раскладка ✅

```
configs/rescue.packages              # пакеты ✅
configs/airootfs/root/.config/hypr/  # hyprland ✅
configs/airootfs/usr/src/Hypr3D/     # плагин ✅
builder/vendor-eblan.sh              # ✅
builder/vendor-hypr3d.sh             # ✅
packaging/hypr3d/                    # оверлей / скайбокс ✅
```

---

## лицензия ✅

mit на упаковку репо. ✅

на софт внутри iso — лицензии апстрима. ✅

---

не вайбкод. ✅

все сам. ✅

да. ✅
