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

```bash
git clone git@github.com:lucrawford/dotfiles.git
cd dotfiles
./install.sh all
```

## Install Commands

```bash
./install.sh {backup|link|git|packages|shell|starship|python|dotnet|macos|all}
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
| `macos` | Apply macOS `defaults write` preferences |
| `all` | Run all of the above in order |

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
| `git-kill` | Delete branches locally and from all remotes |

## Directory Structure

```
├── bin/              # Scripts added to $PATH
├── config/           # Symlinked to ~/.config/
│   ├── git/          # Git config, aliases, ignore
│   ├── ripgrep/      # Ripgrep config
│   ├── starship/     # Starship prompt config (TOML)
│   └── wezterm/      # WezTerm terminal config (Lua)
├── scripts/          # Install helper scripts (apt-packages.sh)
├── zsh/              # Zsh config files
│   ├── aliases.zsh   # Shell aliases
│   ├── functions/    # Autoloaded zsh functions
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

