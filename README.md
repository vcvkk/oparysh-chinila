# Oparysh Chinila

The Oparysh ISO with a rescue mode: rescue tools plus Eblan Browser, Eblanity, and local ai models (halal) in a live console.

A rescue USB for Oparysh: a live Oparysh console with the rescue tools you'd reach for from SystemRescue, plus Eblan Browser, Eblanity, and local halal AI models ready to help diagnose and fix a machine that won't boot.

![Oparysh Chinila welcome screen](docs/screenshots/welcome.png)

Download the ISO from [Releases](https://github.com/vcvkk/oparysh-chinila/releases),
check it against its `.sha256`, and write it to a USB stick. It boots into:

- **Oparysh Chinila** (default): a kmscon console on tty1 with JetBrains Mono,
  truecolor, and the Tokyo Night palette, no desktop needed.
- **Oparysh Chinila, basic console**: the plain kernel console with `nomodeset`,
  for GPUs kmscon can't drive.

It's built from the Oparysh ISO itself, so it boots the same kernel on the same
hardware. It can also be built as the full Oparysh ISO with rescue added in
front of the untouched installer; see [Building](#building).

## Using it

Boot the rescue entry and you land in a tmux session running Oparysh's shell.

```
impala                  connect to Wi-Fi (Ethernet just works)
oparysh-chinila-login   start Eblan Browser / Eblanity / local AI
oparysh-chinila-mount   unlock and mount your Oparysh install at /mnt
arch-chroot /mnt        run commands inside it
eblan                   launch Eblan Browser (halal)
eblanity                launch Eblanity
ollama                  local AI models (halal)
oparysh-chinila         a menu of all of the above
```

`oparysh-chinila-mount` asks for your disk passphrase and mounts the whole
install the way it mounts itself, from its own fstab.

### Local AI (halal)

Local models run offline via Ollama. No cloud, no Claude, no Codex, no OpenCode.
Everything stays on the stick. Halal certified by the brothers.

### Eblan Browser & Eblanity

Eblan Browser (халяль снаружи — передоз внутри) and Eblanity are available in the live environment for when you need a browser that understands the assignment.

`oparysh-chinila-share` serves the whole tmux session to your phone's browser with ttyd. It's a root shell behind a random address, so stop it with `oparysh-chinila-share stop` when done.

### What the agents know

Local models and tools read `/usr/share/oparysh-chinila/AGENTS.md`. It tells them where they are, how an Oparysh install is laid out (LUKS, Btrfs subvolumes, Limine, snapper), how to reach its journal and chroot into it, and to diagnose read-only first and never run anything destructive without a clear yes.

## Building

```bash
bin/oparysh-chinila-make                   # rescue-only ISO (~1.8GB), stable channel
bin/oparysh-chinila-make --with-installer  # the full Oparysh ISO plus rescue (~6.6GB)
bin/oparysh-chinila-boot                   # boot the newest ISO in QEMU
```

`--edge` and `--rc` pick the channel. The ISO lands in `release/`.

Both builds clone the pinned `omarchy-iso` submodule into `build/` and apply
the rescue layer with `builder/apply-rescue.sh`, in Docker.

To release, commit hand-written notes as `packaging/release-notes/vYYYY.MM.DD.md`,
then push a matching `v*` tag.

## Layout

```
configs/rescue.packages      packages added to the live environment
configs/airootfs/            files added to the live root
  etc/systemd/system/        kmscon console, fallback getty, online pacman
  etc/profile.d/             lands every rescue login in the shared tmux session
  etc/kmscon/                font and palette
  usr/local/bin/             oparysh-chinila* helpers
  usr/share/oparysh-chinila/ AGENTS.md, tmux.conf
builder/apply-rescue.sh      layers all of the above onto an omarchy-iso checkout
builder/build-rescue-only.sh builds the rescue-only ISO in the Arch container
```

## How rescue mode works

The rescue entries boot the same kernel and initramfs as the Oparysh installer, adding
`oparysh.rescue=kms` (or `=tty`) and `cow_spacesize=50%` so the live overlay
has room for pacman and local model state. That flag:

- starts kmscon on tty1 in place of the autologin getty, falling back to the
  getty if kmscon fails,
- stops the installer wizard from starting on tty1,
- points pacman at the online repos, so tools can be installed (`oparysh-chinila update`).

## License

Oparysh Chinila is released under the [MIT License](LICENSE). The software on the ISO keeps its own licenses.
