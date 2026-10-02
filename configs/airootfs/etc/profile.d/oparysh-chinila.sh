# Oparysh Chinila interactive login

if grep -qwE 'oparysh\.rescue|omarchy\.rescue' /proc/cmdline 2>/dev/null; then
  export OPARYSH_CHINILA=1

  # Kill leftover OMARCHY marks from packages (logo, issue, motd).
  command -v oparysh-rebrand >/dev/null 2>&1 && oparysh-rebrand

  case $- in
  *i*)
    if [ -z "${TMUX:-}" ]; then
      # On pure tty (basic console): show welcome, then optional tmux.
      if [ -z "${WAYLAND_DISPLAY:-}" ] && [ -z "${DISPLAY:-}" ]; then
        oparysh-chinila welcome 2>/dev/null || true
      fi
      if command -v tmux >/dev/null 2>&1; then
        tmux -f /usr/share/oparysh-chinila/tmux.conf new-session -A -s rescue && exit
      fi
    elif [ -z "$(tmux show-options -gqv @oparysh-chinila-welcomed 2>/dev/null)" ]; then
      tmux set-option -g @oparysh-chinila-welcomed 1
      oparysh-chinila welcome
    fi
    ;;
  esac
fi
