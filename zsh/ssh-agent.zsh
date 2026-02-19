# SSH Agent setup for systemd user service
# Sets SSH_AUTH_SOCK to systemd-managed socket and auto-adds keys if needed

if [[ "$(uname)" != "Linux" ]]; then
  return 0
fi

export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

# Auto-add common SSH keys if none are loaded
if ! ssh-add -l >/dev/null 2>&1; then
  for key in ~/.ssh/github/id_personal ~/.ssh/github/id_microsoft; do
    [[ -f "$key" ]] && ssh-add "$key" 2>/dev/null
  done
fi
