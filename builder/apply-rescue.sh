#!/bin/bash

# Layer Oparysh Chinila onto an iso checkout: rescue files, extra packages,
# and boot entries. By default the stock installer stays alongside rescue.
# With --rescue-only, installer boot entries are dropped.
#
#   builder/apply-rescue.sh [--rescue-only] <iso-checkout>

set -euo pipefail

RESCUE_ONLY=
if [[ ${1:-} == --rescue-only ]]; then
  RESCUE_ONLY=1
  shift
fi

RESCUE_ROOT=$(realpath "${BASH_SOURCE[0]%/*}/..")
ISO=$(realpath "${1:?usage: apply-rescue.sh [--rescue-only] <iso-checkout>}")
CONFIGS=$ISO/configs

RESCUE_ARGS="oparysh.rescue=kms cow_spacesize=50%"
RESCUE_BASIC_ARGS="oparysh.rescue=tty cow_spacesize=50% nomodeset"

fail() {
  echo "apply-rescue: $*" >&2
  exit 1
}

expect() {
  local file=$1 pattern=$2
  grep -qF -- "$pattern" "$file" || fail "expected '$pattern' in ${file#"$ISO"/} after patching"
}

# Files and packages.
cp -a "$RESCUE_ROOT/configs/airootfs/." "$CONFIGS/airootfs/"
cp "$RESCUE_ROOT/configs/rescue.packages" "$CONFIGS/rescue.packages"
mkdir -p "$CONFIGS/airootfs/usr/share/oparysh-chinila"
for mirror in stable rc edge; do
  if [[ -f $CONFIGS/pacman-online-$mirror.conf ]]; then
    cp "$CONFIGS/pacman-online-$mirror.conf" "$CONFIGS/airootfs/usr/share/oparysh-chinila/"
  fi
done
# keep legacy path if something still looks there
mkdir -p "$CONFIGS/airootfs/usr/share/omarchy-rescue" 2>/dev/null || true
for mirror in stable rc edge; do
  if [[ -f $CONFIGS/pacman-online-$mirror.conf ]]; then
    cp "$CONFIGS/pacman-online-$mirror.conf" "$CONFIGS/airootfs/usr/share/omarchy-rescue/" 2>/dev/null || true
  fi
done

build=$ISO/builder/build-iso.sh
anchor='printf '"'"'%s\n'"'"' "${arch_packages[@]}" >> "$build_cache_dir/packages.x86_64"'
expect "$build" "$anchor"
ANCHOR=$anchor awk '
  { print }
  $0 == ENVIRON["ANCHOR"] {
    print "grep -hv '"'"'^#\\|^$'"'"' /configs/rescue.packages >> \"$build_cache_dir/packages.x86_64\""
    print "sort -u -o \"$build_cache_dir/packages.x86_64\" \"$build_cache_dir/packages.x86_64\""
  }
' "$build" >"$build.new"
mv "$build.new" "$build"
chmod +x "$build"
expect "$build" "/configs/rescue.packages"

if ! grep -q 'apple-bcm-firmware-fetcher' "$build"; then
  sed -i "s|sed 's/^broadcom-wl\$/broadcom-wl-dkms/'|sed -e 's/^broadcom-wl\$/broadcom-wl-dkms/' -e 's/^apple-bcm-firmware\$/apple-bcm-firmware-fetcher/'|" "$build"
  expect "$build" "apple-bcm-firmware-fetcher"
fi

script=$CONFIGS/airootfs/root/.automated_script.sh
anchor='[[ $(tty) == /dev/tty1 ]] || exit 0'
expect "$script" "$anchor"
ANCHOR=$anchor awk '
  { print }
  $0 == ENVIRON["ANCHOR"] { print "grep -qwE '\''oparysh\\.rescue|omarchy\\.rescue'\'' /proc/cmdline && exit 0" }
' "$script" >"$script.new"
mv "$script.new" "$script"
expect "$script" "oparysh.rescue"

profile=$CONFIGS/profiledef.sh
if [[ -n $RESCUE_ONLY ]]; then
  iso_name=oparysh-chinila
  iso_application="Oparysh Chinila"
else
  iso_name=oparysh-chinila-with-installer
  iso_application="Oparysh Chinila + Installer"
fi
sed -i \
  -e "s/^iso_name=.*/iso_name=\"$iso_name\"/" \
  -e "s/^iso_application=.*/iso_application=\"$iso_application\"/" \
  "$profile"
{
  echo
  echo "# Oparysh Chinila"
  echo "file_permissions+=("
  for bin in "$RESCUE_ROOT"/configs/airootfs/usr/local/bin/*; do
    echo "  [\"/usr/local/bin/${bin##*/}\"]=\"0:0:755\""
  done
  echo ")"
} >>"$profile"
expect "$profile" "iso_name=\"$iso_name\""

add_grub_entries() {
  local cfg=$1
  expect "$cfg" 'menuentry "Omarchy (%ARCH%, ${archiso_platform})"'
  awk -v rescue="$RESCUE_ARGS" -v basic="$RESCUE_BASIC_ARGS" -v rescue_only="$RESCUE_ONLY" '
    function emit(title, id, args, drop_splash,   i, line) {
      for (i = 1; i <= n; i++) {
        line = block[i]
        if (i == 1) {
          sub(/menuentry "Omarchy \(/, "menuentry \"" title " (", line)
          sub(/--id .archlinux./, "--id '"'"'" id "'"'"'", line)
        }
        if (line ~ /^[[:space:]]*linux /) {
          if (drop_splash) gsub(/ quiet splash/, "", line)
          line = line " " args
        }
        print line
      }
      print ""
    }
    /^menuentry "Omarchy \(/ && !done { collecting = 1 }
    rescue_only && /^menuentry "Omarchy with speakup/ { skipping = 1 }
    skipping { if (/^}/) { skipping = 0; getline } next }
    collecting { block[++n] = $0 }
    !collecting { print }
    collecting && /^}/ {
      collecting = 0; done = 1
      emit("Oparysh Chinila", "oparysh-rescue", rescue, 0)
      emit("Oparysh Chinila, basic console", "oparysh-rescue-basic", basic, 1)
      if (!rescue_only) for (i = 1; i <= n; i++) print block[i]
    }
  ' "$cfg" >"$cfg.new"
  mv "$cfg.new" "$cfg"
  sed -i \
    -e 's/^default=archlinux$/default=oparysh-rescue/' \
    -e 's/^timeout=0$/timeout=10/' \
    -e 's/^timeout_style=hidden$/timeout_style=menu/' \
    "$cfg"
  expect "$cfg" "--id 'oparysh-rescue'"
  expect "$cfg" "--id 'oparysh-rescue-basic'"
  expect "$cfg" "$RESCUE_ARGS"
  expect "$cfg" "default=oparysh-rescue"
  expect "$cfg" "timeout=10"
  if [[ -n $RESCUE_ONLY ]] && grep -q -- "--id 'archlinux" "$cfg"; then
    fail "installer entries left in ${cfg#"$ISO"/} for a rescue-only ISO"
  fi
}
add_grub_entries "$CONFIGS/grub/grub.cfg"
add_grub_entries "$CONFIGS/grub/loopback.cfg"

syslinux=$CONFIGS/syslinux/archiso_sys-linux.cfg
append=$(awk '/^LABEL arch64$/ { found = 1 } found && /^APPEND / { sub(/^APPEND /, ""); print; exit }' "$syslinux")
[[ -n $append ]] || fail "no APPEND line for LABEL arch64 in ${syslinux#"$ISO"/}"
kernel_lines=$(awk '/^LABEL arch64$/ { found = 1 } found && /^(LINUX|INITRD) / { print } found && /^APPEND / { exit }' "$syslinux")
{
  cat <<CFG
LABEL oparyshrescue
TEXT HELP
Boot Oparysh Chinila: live Hyprland with rescue tools.
ENDTEXT
MENU LABEL Oparysh ^Chinila (x86_64, BIOS)
$kernel_lines
APPEND $append $RESCUE_ARGS

LABEL oparyshrescuebasic
TEXT HELP
Boot Oparysh Chinila on the plain text console.
ENDTEXT
MENU LABEL Oparysh Chinila, ^basic console (x86_64, BIOS)
$kernel_lines
APPEND ${append/ quiet splash/} $RESCUE_BASIC_ARGS

CFG
  [[ -n $RESCUE_ONLY ]] || cat "$syslinux"
} >"$syslinux.new"
mv "$syslinux.new" "$syslinux"
sed -i 's/^DEFAULT arch64$/DEFAULT oparyshrescue/' "$CONFIGS/syslinux/archiso_sys.cfg"
expect "$syslinux" "LABEL oparyshrescuebasic"
expect "$CONFIGS/syslinux/archiso_sys.cfg" "DEFAULT oparyshrescue"

echo "Applied Oparysh Chinila to $ISO"
