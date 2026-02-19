# SSH Agent setup for systemd user service
# Sets SSH_AUTH_SOCK to systemd-managed socket and auto-adds keys if needed
# Key list is read from ~/.config/ssh-keys (or ~/.config/ssh-keys.local for local overrides)

if [[ "$(uname)" != "Linux" ]]; then
  return 0
fi

export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

# Auto-add SSH keys if none are loaded
if ! ssh-add -l >/dev/null 2>&1; then
  # Load keys from config file(s)
  local ssh_keys_file="$HOME/.config/ssh-keys"
  local ssh_keys_local="$HOME/.config/ssh-keys.local"
  
  for keysfile in "$ssh_keys_file" "$ssh_keys_local"; do
    [[ -f "$keysfile" ]] || continue
    
    while IFS= read -r keypath; do
      # Skip empty lines and comments
      [[ -z "$keypath" || "$keypath" =~ ^[[:space:]]*# ]] && continue
      
      # Expand ~ to home directory
      keypath="${keypath/#\~/$HOME}"
      
      [[ -f "$keypath" ]] && ssh-add "$keypath" 2>/dev/null
    done < "$keysfile"
  done
fi
