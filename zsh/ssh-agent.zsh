# SSH Agent setup
#
# Ubuntu's openssh-client ships a working user-scope systemd ssh-agent
# (`/usr/lib/systemd/user/ssh-agent.{socket,service}`). The socket unit sets
# SSH_AUTH_SOCK=%t/openssh_agent in the systemd user environment, so most
# shells inherit it automatically.
#
# This file:
#   1. On Linux, makes sure SSH_AUTH_SOCK points at the systemd socket if it
#      somehow isn't already set (e.g. non-PAM shells, containers).
#   2. Starts gnome-keyring's `secrets` component (used by Copilot CLI,
#      Azure CLI, etc.) without letting it hijack SSH.
#   3. Auto-loads keys listed in ~/.config/ssh-keys[.local] into the agent.
#
# All ssh-add calls are wrapped in `timeout` so a wedged agent can never
# freeze interactive shell startup.

if [[ "$(uname)" != "Linux" ]]; then
  return 0
fi

# gnome-keyring secrets (no SSH component — we use the systemd ssh-agent).
if command -v gnome-keyring-daemon &>/dev/null; then
  if [ ! -e "$XDG_RUNTIME_DIR/keyring" ]; then
    eval $(gnome-keyring-daemon --start --components=secrets) >/dev/null 2>&1
  fi
fi

# Fallback: SSH_AUTH_SOCK is normally set by ssh-agent.socket's ExecStartPost.
# In contexts that don't inherit the systemd user env (some containers, raw
# `su`, etc.), point at the standard socket path if it exists.
if [[ -z "$SSH_AUTH_SOCK" && -n "$XDG_RUNTIME_DIR" && -S "$XDG_RUNTIME_DIR/openssh_agent" ]]; then
  export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/openssh_agent"
fi

# Bail fast if there's no socket or no `timeout` binary.
if [[ -z "$SSH_AUTH_SOCK" || ! -S "$SSH_AUTH_SOCK" ]] || ! command -v timeout >/dev/null 2>&1; then
  return 0
fi

# Probe the agent with a hard 2s ceiling so a broken/restarting agent can
# never block the prompt.
timeout 2 ssh-add -l >/dev/null 2>&1
_agent_status=$?

# Exit codes:
#   0   agent responding, keys already loaded — nothing to do
#   1   agent responding, no keys             — auto-add from config
#   2   agent not reachable                   — skip silently
#   124 timeout fired (agent wedged)          — skip silently
if [[ $_agent_status -eq 1 ]]; then
  for keysfile in "$HOME/.config/ssh-keys" "$HOME/.config/ssh-keys.local"; do
    [[ -f "$keysfile" ]] || continue
    while IFS= read -r keypath; do
      [[ -z "$keypath" || "$keypath" =~ ^[[:space:]]*# ]] && continue
      keypath="${keypath/#\~/$HOME}"
      [[ -f "$keypath" ]] || continue
      # Force non-interactive mode so startup never blocks on a passphrase prompt.
      SSH_ASKPASS=/bin/false SSH_ASKPASS_REQUIRE=force DISPLAY=none \
        timeout 2 ssh-add "$keypath" </dev/null >/dev/null 2>&1
    done < "$keysfile"
  done
fi
unset _agent_status
