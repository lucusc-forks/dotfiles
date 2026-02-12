#!/usr/bin/env bash
# Install packages on Ubuntu/Debian-based Linux distributions
# Called by install.sh setup_packages() on Linux

set -euo pipefail

# Prevent interactive prompts from apt (e.g. tzdata)
export DEBIAN_FRONTEND=noninteractive

COLOR_BLUE="\033[1;34m"
COLOR_GREEN="\033[1;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_NONE="\033[0m"

info() { echo -e "${COLOR_BLUE}Info: ${COLOR_NONE}$1"; }
success() { echo -e "${COLOR_GREEN}$1${COLOR_NONE}"; }
warning() { echo -e "${COLOR_YELLOW}Warning: ${COLOR_NONE}$1"; }

# ── Core apt packages ──────────────────────────────────────────────
APT_PACKAGES=(
    build-essential
    curl
    wget
    git
    zsh
    jq
    htop
    tree
    gnupg
    xclip
    python3
    python3-pip
    python3-venv
    unzip
    file
)

info "Updating apt package list..."
sudo apt-get update -y

info "Installing core packages..."
sudo apt-get install -y "${APT_PACKAGES[@]}"

# ── bat (installed as batcat on Ubuntu) ────────────────────────────
if ! command -v bat &>/dev/null && ! command -v batcat &>/dev/null; then
    info "Installing bat..."
    sudo apt-get install -y bat 2>/dev/null || sudo apt-get install -y batcat 2>/dev/null || warning "Could not install bat via apt"
    # Create symlink if installed as batcat
    if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
        mkdir -p "$HOME/.local/bin"
        ln -sfn "$(command -v batcat)" "$HOME/.local/bin/bat"
    fi
fi

# ── fd (installed as fd-find on Ubuntu) ────────────────────────────
if ! command -v fd &>/dev/null && ! command -v fdfind &>/dev/null; then
    info "Installing fd-find..."
    sudo apt-get install -y fd-find 2>/dev/null || warning "Could not install fd-find via apt"
    # Create symlink if installed as fdfind
    if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
        mkdir -p "$HOME/.local/bin"
        ln -sfn "$(command -v fdfind)" "$HOME/.local/bin/fd"
    fi
fi

# ── ripgrep ────────────────────────────────────────────────────────
if ! command -v rg &>/dev/null; then
    info "Installing ripgrep..."
    sudo apt-get install -y ripgrep 2>/dev/null || warning "Could not install ripgrep via apt"
fi

# ── fzf ────────────────────────────────────────────────────────────
if ! command -v fzf &>/dev/null; then
    info "Installing fzf..."
    sudo apt-get install -y fzf 2>/dev/null || {
        info "Installing fzf from git..."
        git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
        "$HOME/.fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
    }
fi

# ── eza (modern ls replacement) ────────────────────────────────────
if ! command -v eza &>/dev/null; then
    info "Installing eza..."
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg 2>/dev/null || true
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    sudo apt-get update -y
    sudo apt-get install -y eza 2>/dev/null || warning "Could not install eza"
fi

# ── zoxide ─────────────────────────────────────────────────────────
if ! command -v zoxide &>/dev/null; then
    info "Installing zoxide..."
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
fi

# ── git-delta ──────────────────────────────────────────────────────
if ! command -v delta &>/dev/null; then
    info "Installing git-delta..."
    DELTA_VERSION=$(curl -sL https://api.github.com/repos/dandavison/delta/releases/latest | jq -r '.tag_name')
    ARCH=$(dpkg --print-architecture)
    curl -fsSL "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_${ARCH}.deb" -o /tmp/git-delta.deb
    sudo dpkg -i /tmp/git-delta.deb
    rm -f /tmp/git-delta.deb
fi

# ── lazygit ────────────────────────────────────────────────────────
if ! command -v lazygit &>/dev/null; then
    info "Installing lazygit..."
    LAZYGIT_VERSION=$(curl -sL https://api.github.com/repos/jesseduffield/lazygit/releases/latest | jq -r '.tag_name' | sed 's/^v//')
    ARCH=$(dpkg --print-architecture)
    [[ "$ARCH" == "amd64" ]] && ARCH_NAME="Linux_x86_64" || ARCH_NAME="Linux_arm64"
    curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_${ARCH_NAME}.tar.gz" -o /tmp/lazygit.tar.gz
    tar -xzf /tmp/lazygit.tar.gz -C /tmp lazygit
    sudo install /tmp/lazygit /usr/local/bin/lazygit
    rm -f /tmp/lazygit.tar.gz /tmp/lazygit
fi

# ── GitHub CLI ─────────────────────────────────────────────────────
if ! command -v gh &>/dev/null; then
    info "Installing GitHub CLI..."
    (type -p wget >/dev/null || sudo apt-get install wget -y) \
        && sudo mkdir -p -m 755 /etc/apt/keyrings \
        && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
        && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
        && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
        && sudo apt-get update \
        && sudo apt-get install gh -y
fi

# ── btop ───────────────────────────────────────────────────────────
if ! command -v btop &>/dev/null; then
    info "Installing btop..."
    sudo apt-get install -y btop 2>/dev/null || warning "Could not install btop via apt (may need Ubuntu 22.10+)"
fi

# ── fnm (Fast Node Manager) ───────────────────────────────────────
if ! command -v fnm &>/dev/null; then
    info "Installing fnm..."
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
fi

success "All Linux packages installed successfully!"
