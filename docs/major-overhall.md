## Plan: Overhaul Dotfiles for Cross-Platform Dev Setup

This plan transforms the current macOS-centric dotfiles repo into a cross-platform setup supporting **macOS, Linux (Ubuntu/Debian), and WSL**, with a future path for Windows Terminal + PowerShell. The shell stays **Zsh** everywhere, but the prompt switches from Powerlevel10k to **Starship** (TOML-configured, cross-shell). Dead code (vim/nvim, terminfo, Kitty, AppleScript, macOS-only scripts) gets aggressively stripped. Package management splits to **Homebrew on macOS** and **apt on Linux/WSL**. The toolchain covers **Node.js (fnm), Python (pyenv + pipx), .NET (dotnet-install.sh)**, plus modern CLI replacements and Docker tooling. **Catppuccin** theming is applied consistently across WezTerm, Starship, bat, and fzf.

**Steps**

### Phase 1: Clean Up Dead Code

1. **Delete files that are no longer needed:**
   - tunes.js — Apple Music script, macOS-only
   - xterm-256color-italic.terminfo — terminfo you don't use
   - alacritty.yml — you're not using Alacritty
   - config/kitty/ — Catppuccin fetcher targets this but it doesn't exist; remove the fetcher function
   - p10k.zsh — Powerlevel10k config, replaced by Starship
   - zinit-installer.zsh — old installer script

2. **Delete unused bin/ scripts:**
   - battery — macOS `pmset` only
   - brew-why — niche Homebrew utility
   - colortest — terminal color test
   - confirm — unused helper
   - fromhex — hex-to-256 color util
   - git-clc — uses `pbcopy` (macOS-only)
   - git-modified, git-status, git-track — low-value git helpers
   - isdir, isfile — trivial test wrappers
   - manage — Docker test container manager
   - nerdwin — Nerd Font icon mapper
   - t — JS test runner (project-specific, not dotfiles)

3. **Keep these bin/ scripts** (update `git-clc` clipboard to use `xclip`/`wl-copy` on Linux):
   - extract, jwt, killport, wtfport, git-bare-clone, git-kill

4. **Remove the applescripts directory entirely** after deleting `tunes.js`.

5. **Remove or repurpose the Dockerfile** — evaluate if it's still useful for testing the Linux install path. If kept, update it to reflect the new setup.

### Phase 2: Restructure install.sh

6. **Refactor install.sh** to support multi-OS installs:
   - Remove `setup_terminfo()` function and its `case` entry
   - Remove `fetch_catppuccin_theme()` function and its `case` entry
   - Remove the global `*.zsh` sourcing block near the bottom (lines ~192-200) that runs on every invocation — this belongs in `.zshrc`, not the installer
   - Remove the `setup_zinit` call that also runs on every invocation
   - Update `setup_macos()` to keep the `defaults write` commands (those are still valuable)

7. **Add a new `setup_packages()` function** that replaces `setup_homebrew()` with OS-aware logic:
   - On macOS: run `brew bundle` with the Brewfile
   - On Linux/WSL (Ubuntu/Debian): run an `apt` install list for the equivalent packages, then install Starship, fnm, etc. via their official install scripts
   - Detect WSL via `grep -qi microsoft /proc/version`

8. **Add a `setup_starship()` function:**
   - Install Starship via `curl -sS https://starship.rs/install.sh | sh` (cross-platform)
   - Symlink the Starship config (see Phase 3)

9. **Add a `setup_python()` function:**
   - Install pyenv via `curl https://pyenv.run | bash` (cross-platform)
   - Install pipx via `pip install --user pipx` or via brew/apt

10. **Add a `setup_dotnet()` function:**
    - Download and run Microsoft's `dotnet-install.sh` script
    - Configure `DOTNET_ROOT` and add to PATH

11. **Update the `case` statement** to reflect new commands:
    - Add: `packages`, `starship`, `python`, `dotnet`
    - Remove: `terminfo`, `catppuccin`
    - Update `all` to call the new functions in order: `setup_symlinks` → `setup_packages` → `setup_shell` → `setup_starship` → `setup_python` → `setup_dotnet` → `setup_git` → `setup_macos` (if Darwin)

### Phase 3: Starship Prompt Configuration

12. **Create `config/starship/starship.toml`** with a Catppuccin-themed Powerline configuration:
    - Use Catppuccin Mocha palette colors
    - Configure segments: directory, git branch/status, Node.js, Python, .NET, Docker, command duration, exit status
    - Use Powerline-style separators (`` / ``)
    - Set `format` and `right_format` for a two-sided prompt

13. **Update zshrc.symlink:**
    - Remove all Zinit plugin loading (Powerlevel10k, zsh-async)
    - Remove Powerlevel10k instant prompt block
    - Remove P10k source line
    - Add `eval "$(starship init zsh)"` 
    - Keep Zinit for zsh-syntax-highlighting, zsh-autosuggestions, and zsh-npm-scripts-autocomplete (still useful)
    - OR replace Zinit entirely with a simpler plugin approach if preferred

14. **Update zshenv.symlink:**
    - Remove `$VIM_TMP` directory creation
    - Add `export STARSHIP_CONFIG="$DOTFILES/config/starship/starship.toml"`
    - Keep `$EDITOR=nano` (since VS Code is GUI-only; nano works for quick terminal edits and git commit messages)
    - Add `export DOTNET_ROOT` and pyenv paths

### Phase 4: Update Package Lists

15. **Update Brewfile** (macOS only now):
    - Remove: `exa` (deprecated, replaced by `eza`), anything vim/neovim related (already commented)
    - Add: `eza`, `starship`, `pyenv`, `pipx`, `btop`
    - Keep: `bat`, `fd`, `fzf`, `gh`, `git`, `git-delta`, `lazygit`, `tree`, `zoxide`, `ripgrep`, `jq`, `htop`, `dive`, `fnm`, `yarn`, zsh
    - Keep all casks: VS Code, Raycast, Obsidian, Bitwarden, Spotify, OrbStack, HyperKey, ImageOptim, WezTerm
    - Keep all fonts (needed for Powerline/Starship)

16. **Create a new `scripts/apt-packages.sh`** (or an `apt-packages.txt` list) for Linux/WSL:
    - Install equivalents: `bat`, `fd-find`, `fzf`, `ripgrep`, `jq`, `htop`, `git`, zsh, `curl`, `wget`, `gnupg`, `xclip`, `python3`, `python3-pip`, `build-essential`
    - Note: some tools (eza, lazygit, starship, fnm, btop, git-delta, zoxide, gh) need custom repos or install scripts on Ubuntu — document/script those

### Phase 5: Catppuccin Theming

17. **Update wezterm.lua** to use Catppuccin Mocha:
    - Set `color_scheme = "Catppuccin Mocha"` (built into WezTerm)
    - WezTerm ships with Catppuccin; no need to download external files

18. **Configure bat Catppuccin theme:**
    - Add bat theme config via `export BAT_THEME="Catppuccin Mocha"` in zshenv or aliases
    - The theme may need to be installed via `bat cache --build` — add this to setup

19. **Configure fzf Catppuccin colors:**
    - Set `FZF_DEFAULT_OPTS` with Catppuccin Mocha color values in zshenv or aliases

20. **Delete the `fetch_catppuccin_theme()` function** from install.sh (Kitty themes no longer needed)

### Phase 6: Update Shell Config Files

21. **Update aliases.zsh:**
    - Replace `exa` references with `eza` (drop-in replacement, same flags)
    - Remove macOS-only aliases: `hidedesktop`/`showdesktop`, `ios` (Simulator), `cleanup` (.DS_Store)
    - Make clipboard aliases cross-platform: add `pbcopy`/`pbpaste` aliases that delegate to `xclip` on Linux
    - Keep: `..` navigation, `reload!`, `rmf`, `ll`/`l`

22. **Update aliases.zsh:** — review and keep useful git aliases, remove any that depend on removed scripts.

23. **Update zprofile.symlink:**
    - Keep Homebrew detection logic (already handles arm64/intel/Linux)
    - Remove OrbStack shell init if not needed on Linux
    - Add pyenv init (`eval "$(pyenv init --path)"`)
    - Add dotnet paths
    - Remove hardcoded `/Users/lucuscrawford/Library/pnpm` path — make conditional or remove pnpm if not used

24. **Update zshrc.symlink:**
    - Remove Powerlevel10k instant prompt block at the top
    - Remove `source $DOTFILES/zsh/p10k.zsh` line
    - Replace Zinit Powerlevel10k plugin with Starship init
    - Keep: completion config, keybindings, history settings, fzf integration, zoxide init, fnm init
    - Remove NVM lazy-loading (not using nvm)
    - Remove Azure CLI completion lazy-loading (unless you use Azure)

25. **Update functions:** — keep all current functions (`c`, `h`, `g`, `md`, `prepend_path`, `last_modified`), they're useful and cross-platform.

### Phase 7: Git Config Updates

26. **Update config:**
    - Change `core.editor` from `vim` to `nano` (consistent with `$EDITOR`)
    - Keep `delta` as the pager (it's cross-platform)
    - Keep `.gitconfig-local` include for machine-specific identity

27. **Update ignore:** — keep as-is, global ignore patterns are platform-agnostic.

### Phase 8: Documentation

28. **Rewrite README.md** to reflect the new setup:
    - Supported platforms: macOS, Ubuntu/Debian Linux, WSL
    - Prerequisites per platform
    - Quick start: `git clone` → `.install.sh all`
    - Individual commands documented
    - Tool list and what's configured
    - Note about future Windows Terminal + PowerShell support

29. **Update or remove Dockerfile:**
    - If kept: update to use Ubuntu, install apt packages, test `install.sh all` on Linux
    - If removed: rely on WSL for Linux testing

### Phase 9: Future — Windows Terminal + PowerShell (Planned, Not Implemented)

30. **Future additions (document in README as roadmap):**
    - `config/windows-terminal/settings.json` with Catppuccin Mocha theme
    - `config/powershell/Microsoft.PowerShell_profile.ps1` with Starship init (`Invoke-Expression (&starship init powershell)`)
    - A `setup_windows.ps1` script for the native Windows side
    - Consider a `setup_wsl.sh` helper that copies Windows Terminal settings to the correct AppData path

**Verification**

- Run `.install.sh all` on a fresh Ubuntu VM/container and verify: zsh is default shell, Starship prompt renders with Powerline glyphs, all CLI tools work (`bat`, `eza`, `fd`, `rg`, `fzf`, `zoxide`, `lazygit`, `gh`), fnm manages Node versions, pyenv/pipx work, dotnet CLI works
- Run `.install.sh all` on macOS and verify: Homebrew installs everything, all casks installed, WezTerm uses Catppuccin Mocha, Starship prompt works
- Verify in WSL: same as Linux, plus confirm clipboard integration works (`xclip`)
- Run `shellcheck install.sh` to validate no bash errors
- Confirm no vim/nvim/terminfo/Kitty references remain: `grep -r "vim\|nvim\|terminfo\|kitty" --include='*.sh' --include='*.zsh' --include='*.toml' --include='*.lua'`

**Decisions**

- **Starship over Powerlevel10k**: User changed preference to Starship only — simpler, cross-shell, TOML config, works identically in Zsh everywhere
- **Zinit kept (for now)**: Still useful for zsh-syntax-highlighting and zsh-autosuggestions turbo loading; can be replaced later if desired
- **Homebrew on macOS, apt on Linux**: No Linuxbrew — native package managers are faster and better integrated on Linux
- **nano as $EDITOR**: No vim/nvim, VS Code is GUI-only; nano is the terminal fallback
- **Aggressive cleanup**: All vim, terminfo, Kitty, AppleScript, and macOS-only utility scripts removed
- **WSL first, Windows later**: Start with WSL treated as Linux; Windows Terminal + PowerShell config is a documented future goal