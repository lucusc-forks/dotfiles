# Copilot Instructions — Dotfiles

## Architecture

This is a personal dotfiles repo. Files are **not installed in-place** — `install.sh link` symlinks them into `$HOME`:

- `*.symlink` files (anywhere, up to 3 levels deep) → `~/.filename` (dot-prefixed, extension stripped)
- `config/<tool>/` directories → `~/.config/<tool>/` (entire directory symlinked)

The repo location is captured at runtime in `$DOTFILES` (resolved in `zsh/zshenv.symlink`).

## ZSH Startup Order

1. **`zshenv.symlink`** — Sets `$DOTFILES`, `$EDITOR`, `$BREW_PREFIX`, adds `zsh/functions/` to `fpath`
2. **`zprofile.symlink`** — Login shells only; detects Homebrew path across macOS (arm64/Intel) and Linux
3. **`zshrc.symlink`** — Interactive shells; loads Zinit plugins, completions, tools (fnm, fzf, zoxide), and **recursively sources every `*.zsh` file** in the repo via `$DOTFILES/**/*.zsh`

## Auto-Discovery Conventions

| To add...                  | Do this                                                                 |
|----------------------------|-------------------------------------------------------------------------|
| A shell alias or config    | Create/edit any `*.zsh` file in the repo — it's auto-sourced by zshrc  |
| A bin script               | Add an executable to `bin/` — it's on `$PATH` automatically            |
| A zsh function             | Add a file (no extension, no shebang) to `zsh/functions/`              |
| Completion for function `c`| Add `_c` to `zsh/functions/` with `#compdef c` as the first line       |
| Config for a new tool      | Create `config/<toolname>/` — it symlinks to `~/.config/<toolname>/`   |
| Machine-local overrides    | Use `~/.zshrc.local`, `~/.localrc`, `~/.zshenv.local`, or `~/.gitconfig-local` |

## `bin/` Script Conventions

- Shebang: always `#!/usr/bin/env bash`
- Naming: lowercase-with-hyphens; `git-*` scripts become `git` subcommands (e.g., `git-bare-clone` → `git bare-clone`)
- Two styles exist: (a) simple/minimal one-file scripts, (b) robust scripts with `set -Eeuo pipefail`, trap cleanup, `usage()`, flag parsing, and color helpers (see `bin/git-bare-clone` as the gold-standard template)
- Composability pattern: `killport` pipes through `wtfport` — prefer stdout/stderr separation for piping

## `install.sh` Subcommands

```
./install.sh {backup|link|homebrew|shell|terminfo|git|macos|all}
```

Each subcommand maps to a function. `all` runs: symlinks → terminfo → homebrew → shell → git → macos. The `backup` command must be run manually before `all`.

## Key Variables

| Variable     | Where Set  | Value                              |
|-------------|------------|------------------------------------|
| `$DOTFILES` | zshenv     | Absolute path to this repo         |
| `$BREW_PREFIX` | zprofile | Homebrew install prefix            |
| `$CODE_DIR` | zshrc      | `~/code` or `~/Development`        |
| `$EDITOR`   | zshenv     | `nano`                             |

## Active Overhaul (`docs/major-overhall.md`)

A 9-phase modernization is in progress. Key planned changes:

- Replace Powerlevel10k → Starship prompt
- Replace `exa` → `eza` in aliases
- Align `core.editor` in git config with `$EDITOR` (nano)
- Add multi-OS package support (apt alongside Homebrew)
- Catppuccin theming across all tools

Check `docs/major-overhall.md` before making structural changes — it may already be planned.

## Testing

Use the Dockerfile to test the Linux install path:

```bash
./bin/manage build   # builds the dotfiles Docker image
./bin/manage start   # runs an interactive shell in the container
```
