#!/usr/bin/env bash

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COLOR_GRAY="\033[1;38;5;243m"
COLOR_BLUE="\033[1;34m"
COLOR_GREEN="\033[1;32m"
COLOR_RED="\033[1;31m"
COLOR_PURPLE="\033[1;35m"
COLOR_YELLOW="\033[1;33m"
COLOR_NONE="\033[0m"

title() {
    echo -e "\n${COLOR_PURPLE}$1${COLOR_NONE}"
    echo -e "${COLOR_GRAY}==============================${COLOR_NONE}\n"
}

error() {
    echo -e "${COLOR_RED}Error: ${COLOR_NONE}$1"
    exit 1
}

warning() {
    echo -e "${COLOR_YELLOW}Warning: ${COLOR_NONE}$1"
}

info() {
    echo -e "${COLOR_BLUE}Info: ${COLOR_NONE}$1"
}

success() {
    echo -e "${COLOR_GREEN}$1${COLOR_NONE}"
}

is_macos() {
    [[ "$(uname)" == "Darwin" ]]
}

is_linux() {
    [[ "$(uname)" == "Linux" ]]
}

is_wsl() {
    is_linux && grep -qi microsoft /proc/version 2>/dev/null
}

get_linkables() {
    find -H "$DOTFILES" -maxdepth 3 -name '*.symlink'
}

backup() {
    BACKUP_DIR=$HOME/dotfiles-backup

    echo "Creating backup directory at $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"

    for file in $(get_linkables); do
        filename=".$(basename "$file" '.symlink')"
        target="$HOME/$filename"
        if [ -f "$target" ]; then
            echo "backing up $filename"
            cp "$target" "$BACKUP_DIR"
        else
            warning "$filename does not exist at this location or is a symlink"
        fi
    done
}


setup_symlinks() {
    title "Creating symlinks"

    for file in $(get_linkables) ; do
        target="$HOME/.$(basename "$file" '.symlink')"
        info "Checking existence of ~${target#$HOME}"
        if [ -e "$target" ]; then
            info "~${target#$HOME} already exists... Updating."            
        else
            info "Creating symlink for $file"
        fi
        ln -sfn "$file" "$target"
    done

    echo -e
    info "installing to ~/.config"
    if [ ! -d "$HOME/.config" ]; then
        info "Creating ~/.config"
        mkdir -p "$HOME/.config"
    fi

    config_files=$(find "$DOTFILES/config" -maxdepth 1 2>/dev/null)
    
    for config in $config_files; do
        target="$HOME/.config/$(basename "$config")"
        info "Checking existence of ~${target#$HOME}"
        if [ -e "$target" ]; then
            info "~${target#$HOME} already exists... Updating."
        else
            info "Creating symlink for $config"
        fi
        ln -sfn "$config" "$target"
    done
}

setup_git() {
    title "Setting up Git"

    defaultName=$(git config user.name)
    defaultEmail=$(git config user.email)
    defaultGithub=$(git config github.user)

    read -rp "Name [$defaultName] " name
    read -rp "Email [$defaultEmail] " email
    read -rp "Github username [$defaultGithub] " github

    git config -f ~/.gitconfig-local user.name "${name:-$defaultName}"
    git config -f ~/.gitconfig-local user.email "${email:-$defaultEmail}"
    git config -f ~/.gitconfig-local github.user "${github:-$defaultGithub}"

    if is_macos; then
        git config --global credential.helper "osxkeychain"
    else
        read -rn 1 -p "Save user and password to an unencrypted file to avoid writing? [y/N] " save
        if [[ $save =~ ^([Yy])$ ]]; then
            git config --global credential.helper "store"
        else
            git config --global credential.helper "cache --timeout 3600"
        fi
    fi
}

setup_packages() {
    title "Setting up packages"

    if is_macos; then
        info "Detected macOS — using Homebrew"

        if ! command -v brew &>/dev/null; then
            info "Homebrew not installed. Installing."
            curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | bash --login
        fi

        brew bundle --file="$DOTFILES/Brewfile"

        # install fzf key bindings and completion
        echo -e
        info "Installing fzf"
        "$(brew --prefix)"/opt/fzf/install --key-bindings --completion --no-update-rc --no-bash --no-fish

    elif is_linux; then
        info "Detected Linux — using apt"

        if ! command -v apt-get &>/dev/null; then
            error "apt-get not found. This script supports Ubuntu/Debian-based distributions."
        fi

        # Run the apt packages install script
        if [ -f "$DOTFILES/scripts/apt-packages.sh" ]; then
            bash "$DOTFILES/scripts/apt-packages.sh"
        else
            error "scripts/apt-packages.sh not found"
        fi
    fi
}

setup_shell() {
    title "Configuring shell"

    if is_macos && command -v brew &>/dev/null; then
        zsh_path="$(brew --prefix)/bin/zsh"
    else
        zsh_path="$(command -v zsh)"
    fi

    if ! grep -q "$zsh_path" /etc/shells; then
        info "adding $zsh_path to /etc/shells"
        echo "$zsh_path" | sudo tee -a /etc/shells
    fi

    if [[ "$SHELL" != "$zsh_path" ]]; then
        sudo chsh -s "$zsh_path" "$(whoami)"
        info "default shell changed to $zsh_path"
    fi
}

setup_starship() {
    title "Setting up Starship prompt"

    if command -v starship &>/dev/null; then
        success "Starship is already installed."
    else
        info "Installing Starship..."
        curl -sS https://starship.rs/install.sh | sh -s -- --yes
    fi
}

setup_python() {
    title "Setting up Python tooling"

    if command -v pyenv &>/dev/null; then
        success "pyenv is already installed."
    else
        info "Installing pyenv..."
        curl -fsSL https://pyenv.run | bash
    fi

    if command -v pipx &>/dev/null; then
        success "pipx is already installed."
    elif command -v pip3 &>/dev/null; then
        info "Installing pipx..."
        pip3 install --user pipx
    elif command -v pip &>/dev/null; then
        info "Installing pipx..."
        pip install --user pipx
    else
        warning "pip not found, skipping pipx installation"
    fi
}

setup_dotnet() {
    title "Setting up .NET"

    if command -v dotnet &>/dev/null; then
        success ".NET is already installed."
    else
        info "Installing .NET SDK..."
        curl -fsSL https://dot.net/v1/dotnet-install.sh | bash -s -- --channel LTS
        info ".NET installed to ~/.dotnet"
    fi
}

setup_macos() {
    title "Configuring macOS"
    if is_macos; then

        echo "Finder: show all filename extensions"
        defaults write NSGlobalDomain AppleShowAllExtensions -bool true

        echo "show hidden files by default"
        defaults write com.apple.Finder AppleShowAllFiles -bool false

        echo "only use UTF-8 in Terminal.app"
        defaults write com.apple.terminal StringEncodings -array 4

        echo "expand save dialog by default"
        defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true

        echo "show the ~/Library folder in Finder"
        chflags nohidden ~/Library

        echo "Enable full keyboard access for all controls (e.g. enable Tab in modal dialogs)"
        defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

        echo "Enable subpixel font rendering on non-Apple LCDs"
        defaults write NSGlobalDomain AppleFontSmoothing -int 2

        echo "Use current directory as default search scope in Finder"
        defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

        echo "Show Path bar in Finder"
        defaults write com.apple.finder ShowPathbar -bool true

        echo "Show Status bar in Finder"
        defaults write com.apple.finder ShowStatusBar -bool true

        echo "Disable press-and-hold for keys in favor of key repeat"
        defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

        echo "Set a blazingly fast keyboard repeat rate"
        defaults write NSGlobalDomain KeyRepeat -int 1

        echo "Set a shorter Delay until key repeat"
        defaults write NSGlobalDomain InitialKeyRepeat -int 15

        echo "Enable tap to click (Trackpad)"
        defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

        echo "Enable Safari’s debug menu"
        defaults write com.apple.Safari IncludeInternalDebugMenu -bool true

        echo "Kill affected applications"

        for app in Safari Finder Dock Mail SystemUIServer; do killall "$app" >/dev/null 2>&1; done
    else
        warning "macOS not detected. Skipping."
    fi
}

setup_zinit() {
    title "Setting up Zinit plugin manager"

    ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
    if [[ ! -d "$ZINIT_HOME" ]]; then
        info "Installing Zinit..."
        mkdir -p "$(dirname "$ZINIT_HOME")"
        git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
        success "Zinit installed successfully!"
    else
        success "Zinit is already installed."
    fi
}

setup_systemd_ssh_agent() {
    if ! is_linux; then
        warning "systemd SSH agent setup is only supported on Linux. Skipping."
        return 0
    fi

    title "Setting up systemd SSH agent"

    SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
    mkdir -p "$SYSTEMD_USER_DIR"

    if [ -d "$DOTFILES/config/systemd/user" ]; then
        info "Symlinking systemd units"
        for unit in "$DOTFILES/config/systemd/user"/*; do
            target="$SYSTEMD_USER_DIR/$(basename "$unit")"
            ln -sfn "$unit" "$target"
        done
        
        info "Enabling SSH agent systemd user service"
        systemctl --user daemon-reload
        systemctl --user enable --now ssh-agent
        success "SSH agent service enabled"
    else
        warning "systemd/user directory not found in dotfiles"
    fi
}

case "$1" in
    backup)
        backup
        ;;
    link|symlink)
        setup_symlinks
        ;;
    git)
        setup_git
        ;;
    packages)
        setup_packages
        ;;
    shell)
        setup_shell
        ;;
    starship)
        setup_starship
        ;;
    python)
        setup_python
        ;;
    dotnet)
        setup_dotnet
        ;;
    macos)
        setup_macos
        ;;
    ssh-agent|systemd-ssh)
        setup_systemd_ssh_agent
        ;;
    all)
        setup_symlinks
        setup_systemd_ssh_agent
        setup_packages
        setup_shell
        setup_zinit
        setup_starship
        setup_python
        setup_dotnet
        setup_git
        if is_macos; then
            setup_macos
        fi
        ;;
    *)
        echo -e $"\nUsage: $(basename "$0") {backup|link|git|packages|shell|starship|python|dotnet|macos|ssh-agent|all}\n"
        exit 1
        ;;
esac

echo -e
success "Done."
