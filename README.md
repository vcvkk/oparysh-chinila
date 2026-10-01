# Oparysh Chinila

The Oparysh ISO with a rescue mode: rescue tools plus Eblan Browser, Eblanity, and local ai models (halal) in a live console.

A rescue USB for Oparysh: a live Oparysh console with the rescue tools you'd reach for from SystemRescue, plus **Eblan Browser**, **Eblanity CLI**, and local halal AI models ready **offline** — no internet needed after the ISO is built.

![Oparysh Chinila welcome screen](docs/screenshots/welcome.png)

Download the ISO from [Releases](https://github.com/vcvkk/oparysh-chinila/releases),
check it against its `.sha256`, and write it to a USB stick. It boots into:

- **Oparysh Chinila** (default): a kmscon console on tty1 with JetBrains Mono,
  truecolor, and the Tokyo Night palette, no desktop needed.
- **Oparysh Chinila, basic console**: the plain kernel console with `nomodeset`,
  for GPUs kmscon can't drive.

## Offline Eblan stack

At build time `builder/vendor-eblan.sh` downloads:

| Component | Source | On ISO |
|-----------|--------|--------|
| **EBLAN Browser** | `https://update.riba.click/eb/r/lastest.zip` | `/opt/eblan-browser` + `/usr/local/bin/eblan` |
| **Eblanity CLI** | `https://eblansoft.ru/upd/eblanityCLI/eblanity` | `/usr/local/bin/eblanity` |

System deps (PyQt6, WebEngine, ffmpeg, xcb, …) come from Arch packages in `configs/rescue.packages`. After the ISO is written you can run `eblan` and `eblanity` with **no network**.

Upstream installers (normal installed system only):

```bash
curl -sSL https://eblanbrowser.ru/sh/installeblan.sh | sudo bash
curl -sSfL https://eblansoft.ru/upd/eblanityCLI/install.sh | bash
```

## Using it

Boot the rescue entry and you land in a tmux session running Oparysh's shell.

```
impala                  connect to Wi-Fi (Ethernet just works)
oparysh-chinila-mount   unlock and mount your Oparysh install at /mnt
arch-chroot /mnt        run commands inside it
eblan                   Eblan Browser (halal, offline)
eblanity                Eblanity CLI (offline)
ollama                  local AI models (halal)
oparysh-chinila         a menu of all of the above
```

`oparysh-chinila-mount` asks for your disk passphrase and mounts the whole
install the way it mounts itself, from its own fstab.

### Local AI (halal)

Local models run offline via Ollama. No cloud, no Claude, no Codex, no OpenCode.

### What the agents know

Local models and tools read `/usr/share/oparysh-chinila/AGENTS.md`.

## Building

```bash
bin/omarchy-rescue-make                   # rescue-only ISO, stable channel
bin/omarchy-rescue-make --with-installer  # full Oparysh ISO plus rescue
bin/omarchy-rescue-boot                   # boot the newest ISO in QEMU
```

Build needs network **once** (vendor Eblan/Eblanity + Arch packages). The resulting ISO is offline-capable for those tools.

`--edge` and `--rc` pick the channel. The ISO lands in `release/`.

## Layout

```
configs/rescue.packages         Arch packages (incl. PyQt6 stack for Eblan)
configs/airootfs/
  opt/eblan-browser/            vendored browser (via vendor-eblan.sh)
  usr/local/bin/eblan           browser launcher
  usr/local/bin/eblanity        Eblanity CLI binary (vendored)
  usr/local/bin/oparysh-chinila*
builder/vendor-eblan.sh         downloads browser + eblanity into airootfs
builder/apply-rescue.sh         layers rescue onto omarchy-iso checkout
```

## License

Oparysh Chinila is released under the [MIT License](LICENSE). The software on the ISO keeps its own licenses. EBLAN Browser / Eblanity remain under their upstream terms.
