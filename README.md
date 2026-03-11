# Dotfiles

Cross-platform dotfiles for **macOS**, **Linux (Ubuntu/Debian)**, and **WSL**. Shell is **Zsh** everywhere, prompt is **[Starship](https://starship.rs/)** with **Catppuccin Mocha** theming.

## Supported Platforms

| Platform | Package Manager | Status |
|----------|----------------|--------|
| macOS (arm64/Intel) | Homebrew | ✅ |
| Ubuntu/Debian Linux | apt | ✅ |
| WSL (Ubuntu) | apt | ✅ |
| Windows Terminal + PowerShell | — | 🗓️ Planned |

## Prerequisites

**macOS:**
```bash
xcode-select --install
```

**Linux/WSL:**
```bash
sudo apt-get update && sudo apt-get install -y git curl
```

## Quick Start

Full setup for a brand new system — from zero to working dev environment.

### 1. Generate SSH keys

Create separate SSH keys for personal and work GitHub accounts:

```bash
mkdir -p ~/.ssh/github

# Personal key
ssh-keygen -t ed25519 -C "your-personal@email.com" -f ~/.ssh/github/id_personal

# Work key
ssh-keygen -t ed25519 -C "your-work@email.com" -f ~/.ssh/github/id_work
```

### 2. Add keys to GitHub

Copy each public key and add it to the corresponding GitHub account under **Settings → SSH and GPG keys → New SSH key**:

```bash
cat ~/.ssh/github/id_personal.pub   # → add to personal GitHub account
cat ~/.ssh/github/id_work.pub       # → add to work GitHub account
```

### 3. Clone the dotfiles repo

Use the personal SSH Host alias (configured by the dotfiles) — but since it isn't set up yet, use the default host for the initial clone:

```bash
git clone git@github.com:lucrawford/dotfiles.git ~/src/personal/dotfiles
cd ~/src/personal/dotfiles
```

### 4. Run the installer

```bash
./install.sh all
```

This will:
- Create symlinks (`*.symlink` → `~/.*`, `config/*` → `~/.config/*`)
- Create `~/src/personal/` and `~/src/work/` directories
- Symlink SSH config to `~/.ssh/config` (with Host aliases for personal/work)
- Enable the systemd SSH agent (Linux)
- Install packages (Homebrew on macOS, apt on Linux)
- Set Zsh as default shell
- Install Starship, pyenv, pipx, .NET SDK
- Prompt for git name and GitHub username (written to `~/.gitconfig-local`)

### 5. Verify SSH connectivity

```bash
ssh -T github.com-personal   # Hi <username>! You've successfully authenticated...
ssh -T github.com-work        # Hi <username>! You've successfully authenticated...
```

### 6. Start cloning repos

```bash
# Personal repos
gcp user/repo                 # → clones to ~/src/personal/repo

# Work repos
gcw org/repo                  # → clones to ~/src/work/repo
```

### 7. (Optional) Add a client namespace

```bash
# Generate an SSH key for the client
ssh-keygen -t ed25519 -C "you@clienta.com" -f ~/.ssh/github/id_clienta

# Add the public key to the client's GitHub account
cat ~/.ssh/github/id_clienta.pub

# Scaffold the namespace (creates dir, git config, SSH alias, ssh-keys entry)
git ns add clienta --email you@clienta.com --key ~/.ssh/github/id_clienta

# Clone client repos
git clone-as clienta org/repo
```

## Install Commands

```bash
./install.sh {backup|link|git|packages|shell|starship|python|dotnet|macos|ssh-agent|ssh-config|dev-dirs|all}
```

| Command | Description |
|---------|-------------|
| `backup` | Back up existing dotfiles to `~/dotfiles-backup/` |
| `link` | Create symlinks: `*.symlink` → `~/.*`, `config/*` → `~/.config/*` |
| `packages` | Install packages (Homebrew on macOS, apt on Linux) |
| `shell` | Set Zsh as the default shell |
| `starship` | Install the Starship prompt |
| `python` | Install pyenv and pipx |
| `dotnet` | Install .NET SDK |
| `git` | Configure git identity (`~/.gitconfig-local`) |
| `ssh-agent` | Enable systemd SSH agent service (Linux only) |
| `ssh-config` | Symlink SSH config to `~/.ssh/config` |
| `dev-dirs` | Create `~/src/personal/` and `~/src/work/` directories |
| `macos` | Apply macOS `defaults write` preferences |
| `all` | Run all of the above in order |

## Git Multi-Identity Setup

Repos automatically use the correct git email based on which directory they're in — no manual switching needed.

### How it works

1. **Directory-based identity switching** — Git's `includeIf "gitdir:"` loads identity fragments per namespace:
   - Repos in `~/src/personal/` → `config/git/config-personal` (personal email)
   - Repos in `~/src/work/` → `config/git/config-work` (work email)

2. **SSH Host aliases** — Each namespace maps to an SSH Host alias in `~/.ssh/config` that routes to a specific SSH key:
   - `github.com-personal` → `~/.ssh/github/id_personal`
   - `github.com-work` → `~/.ssh/github/id_work`

3. **Pure SSH** — No credential manager needed. The SSH agent loads all keys on login, and Host aliases ensure the right key is used automatically.

### Verify identity per directory

```bash
cd ~/src/personal/some-repo
git config user.email   # → personal email

cd ~/src/work/some-repo
git config user.email   # → work email
```

### Clone helpers

| Command | Alias | Description |
|---------|-------|-------------|
| `git clone-as personal user/repo` | `gcp user/repo` | Clone to `~/src/personal/repo` using personal SSH key |
| `git clone-as work org/repo` | `gcw org/repo` | Clone to `~/src/work/repo` using work SSH key |

`git clone-as` supports additional flags:
- `--dir <path>` — Override destination directory
- `--bare` — Use bare clone for worktree workflows (delegates to `git-bare-clone`)
- `--host <hostname>` — Use a different Git host (default: `github.com`)

### Namespace management

Add new namespaces (e.g., a new client) with a single command:

```bash
git ns add clienta --email you@clienta.com
```

This creates:
- `~/src/clienta/` directory
- `config/git/config-clienta` identity fragment
- SSH Host alias `github.com-clienta` in SSH config
- Entry in `config/ssh-keys` for SSH agent auto-loading

```bash
git ns list   # Show all configured namespaces with their emails, SSH hosts, and keys
```

### Files involved

| File | Purpose |
|------|---------|
| `config/git/config` | Base git config with `includeIf` directives |
| `config/git/config-personal` | `[user] email` for personal repos |
| `config/git/config-work` | `[user] email` for work repos |
| `config/ssh/config` | SSH Host aliases (symlinked to `~/.ssh/config`) |
| `config/ssh-keys` | SSH key paths for agent auto-loading |
| `~/.gitconfig-local` | Machine-local git identity (`user.name`, `github.user`) |
| `~/.ssh/config.local` | Machine-local SSH overrides (not tracked) |

## SSH Agent Setup

On **Linux**, the installer configures a systemd user service to auto-start SSH agent on login. Keys are automatically added from `~/.config/ssh-keys`.

### Configuration

**Default keys** — Edit `config/ssh-keys` (symlinked to `~/.config/ssh-keys`):
```
~/.ssh/github/id_personal
~/.ssh/github/id_work
```

One key path per line. Lines starting with `#` are comments; empty lines are ignored. Tilde (`~`) expands to your home directory.

**Local overrides** — Create `~/.config/ssh-keys.local` (not tracked by git):
```
~/.ssh/local-only/id_rsa
```

Both files are processed on shell startup; keys are auto-added if none are in the agent.

### How It Works

1. `ssh-agent.service` (systemd) starts ssh-agent at login with socket at `$XDG_RUNTIME_DIR/ssh-agent.socket`
2. `zsh/ssh-agent.zsh` exports `SSH_AUTH_SOCK` and auto-loads keys from `ssh-keys` and `ssh-keys.local`
3. Git, SSH, and other tools automatically use the agent

**Check status:**
```bash
systemctl --user status ssh-agent
ssh-add -l  # List loaded keys
```

## What's Included

### Shell (Zsh)

- **Prompt:** Starship with Catppuccin Mocha Powerline theme
- **Plugins** (via Zinit): zsh-syntax-highlighting, zsh-autosuggestions, zsh-npm-scripts-autocomplete
- **Auto-sourcing:** Every `*.zsh` file in the repo is sourced by `.zshrc`
- **Functions:** `c` (cd to code dir), `h` (cd to home subdir), `g` (git shortcut), `md` (mkdir + cd)

### CLI Tools

| Tool | Purpose |
|------|---------|
| `bat` | Better `cat` with syntax highlighting |
| `eza` | Modern `ls` replacement |
| `fd` | Fast `find` alternative |
| `fzf` | Fuzzy finder |
| `ripgrep` | Fast `grep` alternative |
| `zoxide` | Smarter `cd` |
| `git-delta` | Better git diffs |
| `lazygit` | Git TUI |
| `gh` | GitHub CLI |
| `htop` / `btop` | Process viewers |
| `jq` | JSON processor |
| `fnm` | Fast Node version manager |
| `pyenv` / `pipx` | Python version & tool management |
| `starship` | Cross-shell prompt |

### Theming (Catppuccin Mocha)

Applied consistently across:
- **WezTerm** — `color_scheme = "Catppuccin Mocha"`
- **Starship** — Catppuccin palette colors in prompt segments
- **bat** — `BAT_THEME="Catppuccin Mocha"`
- **fzf** — Catppuccin color scheme via `FZF_DEFAULT_OPTS`

### Utility Scripts (`bin/`)

| Script | Description |
|--------|-------------|
| `extract` | Extract many archive formats (zip, tar.gz, etc.) |
| `jwt` | Decode a JWT body to JSON |
| `killport` | Kill the process listening on a given port |
| `wtfport` | Print the PID of the process on a given port |
| `git-bare-clone` | Clone as bare repo for worktree workflows |
| `git-clc` | Copy last commit SHA to clipboard (cross-platform) |
| `git-clone-as` | Clone repos using a specific namespace's SSH key |
| `git-kill` | Delete branches locally and from all remotes |
| `git-ns` | Add/list git identity namespaces (directory, SSH alias, config) |

## Directory Structure

```
├── bin/              # Scripts added to $PATH
├── config/           # Symlinked to ~/.config/
│   ├── git/          # Git config, aliases, ignore, identity fragments
│   │   ├── config              # Base git config (includeIf directives)
│   │   ├── config-personal     # [user] email for personal repos
│   │   ├── config-work         # [user] email for work repos
│   │   ├── aliases.zsh         # Git shell aliases (gs, glog, gcp, gcw)
│   │   └── ignore              # Global gitignore
│   ├── ripgrep/      # Ripgrep config
│   ├── ssh/          # SSH config (symlinked to ~/.ssh/config)
│   │   └── config              # Host aliases for multi-account GitHub
│   ├── ssh-keys      # SSH keys to auto-load on login
│   ├── starship/     # Starship prompt config (TOML)
│   ├── systemd/
│   │   └── user/     # Systemd user services (Linux)
│   │       └── ssh-agent.service  # SSH agent service
│   └── wezterm/      # WezTerm terminal config (Lua)
├── scripts/          # Install helper scripts (apt-packages.sh)
├── zsh/              # Zsh config files
│   ├── aliases.zsh   # Shell aliases
│   ├── functions/    # Autoloaded zsh functions
│   ├── ssh-agent.zsh # SSH agent setup (Linux)
│   ├── zshenv.symlink
│   ├── zprofile.symlink
│   └── zshrc.symlink
├── Brewfile          # macOS Homebrew packages
├── Dockerfile        # Linux install testing
└── install.sh        # Main installer
```

## Conventions

| To add... | Do this |
|-----------|---------|
| A shell alias or config | Create/edit any `*.zsh` file — auto-sourced by `.zshrc` |
| A bin script | Add an executable to `bin/` — on `$PATH` automatically |
| A zsh function | Add a file (no extension) to `zsh/functions/` |
| Completion for function `c` | Add `_c` to `zsh/functions/` with `#compdef c` |
| Config for a new tool | Create `config/<toolname>/` — symlinks to `~/.config/<toolname>/` |
| Machine-local overrides | Use `~/.zshrc.local`, `~/.localrc`, `~/.zshenv.local`, or `~/.gitconfig-local` |

## Testing (Docker)

```bash
docker build -t dotfiles .
docker run -it --rm dotfiles
# Inside container:
./dotfiles/install.sh all
```

## Roadmap

- **Windows Terminal + PowerShell:** Native Windows side config with Starship and Catppuccin theming

