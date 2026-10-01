# Oparysh Chinila: every interactive rescue login lands in the shared "rescue"
# tmux session, the same one oparysh-chinila-share serves to a phone.

if grep -qwE 'oparysh\.rescue|omarchy\.rescue' /proc/cmdline 2>/dev/null; then
  export OPARYSH_CHINILA=1
  export OMARCHY_RESCUE=1

  case $- in
  *i*)
    if [ -z "$TMUX" ]; then
      # Detaching returns 0 and logs out, so autologin brings the session back.
      tmux -f /usr/share/oparysh-chinila/tmux.conf new-session -A -s rescue && exit
    elif [ -z "$(tmux show-options -gqv @oparysh-chinila-welcomed)" ]; then
      tmux set-option -g @oparysh-chinila-welcomed 1
      oparysh-chinila welcome
    fi
    ;;
  esac
fi
