#!/usr/bin/env bash

set -Eeuo pipefail

COLOR_BLUE="\033[1;34m"
COLOR_GREEN="\033[1;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_RED="\033[1;31m"
COLOR_NONE="\033[0m"

info() { echo -e "${COLOR_BLUE}Info:${COLOR_NONE} $1"; }
success() { echo -e "${COLOR_GREEN}$1${COLOR_NONE}"; }
warning() { echo -e "${COLOR_YELLOW}Warning:${COLOR_NONE} $1"; }
error() { echo -e "${COLOR_RED}Error:${COLOR_NONE} $1"; exit 1; }

INSTALL_RECOMMENDED=false

for arg in "$@"; do
    case "$arg" in
        --with-recommended)
            INSTALL_RECOMMENDED=true
            ;;
        -h|--help)
            cat <<'EOF'
Usage: scripts/install-dev-toolchain.sh [--with-recommended]

Installs on Ubuntu/Debian:
  - Node.js (via fnm, installs latest LTS)
  - Python 3 + venv + pip
  - uv
  - .NET SDK 8 and .NET SDK 10
  - Azure CLI (az)
  - Azure Developer CLI (azd)

Options:
  --with-recommended  Also install a recommended tooling set
EOF
            exit 0
            ;;
        *)
            error "Unknown argument: $arg"
            ;;
    esac
done

if [[ "$(uname)" != "Linux" ]]; then
    error "This script supports Linux only (Ubuntu/Debian apt-based distros)."
fi

if ! command -v apt-get >/dev/null 2>&1; then
    error "apt-get not found. This script supports apt-based distributions."
fi

if [[ -f /etc/os-release ]]; then
    # shellcheck source=/dev/null
    source /etc/os-release
else
    error "Could not read /etc/os-release"
fi

if [[ "${ID:-}" != "ubuntu" && "${ID:-}" != "debian" && "${ID_LIKE:-}" != *"debian"* ]]; then
    warning "Detected distro: ${PRETTY_NAME:-unknown}. Continuing, but only Debian-like distros are supported."
fi

if [[ "$(id -u)" -eq 0 ]]; then
    SUDO=""
else
    SUDO="sudo"
fi

APT_BASE_PACKAGES=(
    apt-transport-https
    ca-certificates
    curl
    gpg
    lsb-release
    software-properties-common
    unzip
    wget
)

APT_PYTHON_PACKAGES=(
    python3
    python3-dev
    python-is-python3
    python3-pip
    python3-venv
)

APT_RECOMMENDED_PACKAGES=(
    build-essential
    direnv
    git
    jq
    make
    pkg-config
    shellcheck
    zip
)

ensure_local_bin_path() {
    export PATH="$HOME/.local/bin:$PATH"

    if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.profile" 2>/dev/null; then
        info "Adding ~/.local/bin to PATH in ~/.profile"
        {
            echo
            echo '# Added by install-dev-toolchain.sh'
            echo 'export PATH="$HOME/.local/bin:$PATH"'
        } >>"$HOME/.profile"
    fi
}

ensure_dotnet_path() {
    export DOTNET_ROOT="$HOME/.dotnet"
    export PATH="$DOTNET_ROOT:$DOTNET_ROOT/tools:$PATH"

    if ! grep -q 'export DOTNET_ROOT="$HOME/.dotnet"' "$HOME/.profile" 2>/dev/null; then
        info "Adding DOTNET_ROOT to ~/.profile"
        {
            echo
            echo '# Added by install-dev-toolchain.sh'
            echo 'export DOTNET_ROOT="$HOME/.dotnet"'
            echo 'export PATH="$DOTNET_ROOT:$DOTNET_ROOT/tools:$PATH"'
        } >>"$HOME/.profile"
    fi
}

ensure_azd_path() {
    export PATH="$HOME/.azd/bin:$PATH"

    if ! grep -q 'export PATH="$HOME/.azd/bin:$PATH"' "$HOME/.profile" 2>/dev/null; then
        info "Adding ~/.azd/bin to PATH in ~/.profile"
        {
            echo
            echo '# Added by install-dev-toolchain.sh'
            echo 'export PATH="$HOME/.azd/bin:$PATH"'
        } >>"$HOME/.profile"
    fi
}

install_apt_packages() {
    local -a packages=("$@")
    if [[ "${#packages[@]}" -eq 0 ]]; then
        return
    fi

    info "Installing apt packages: ${packages[*]}"
    DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y "${packages[@]}"
}

dotnet_sdk_installed() {
    local channel="$1"
    local major="${channel%%.*}"

    if ! command -v dotnet >/dev/null 2>&1; then
        return 1
    fi

    dotnet --list-sdks 2>/dev/null | awk '{print $1}' | grep -q "^${major}\\."
}

install_dotnet_sdks() {
    local -a apt_sdk_packages=()
    local -a fallback_channels=()
    local channel package

    for channel in 8.0 10.0; do
        package="dotnet-sdk-${channel}"
        if dotnet_sdk_installed "$channel"; then
            info ".NET SDK ${channel} already installed"
            continue
        fi

        if apt-cache show "$package" >/dev/null 2>&1; then
            apt_sdk_packages+=("$package")
        else
            fallback_channels+=("$channel")
        fi
    done

    if [[ "${#apt_sdk_packages[@]}" -gt 0 ]]; then
        install_apt_packages "${apt_sdk_packages[@]}"
    fi

    if [[ "${#fallback_channels[@]}" -gt 0 ]]; then
        local install_script
        install_script="/tmp/dotnet-install.sh"

        info "Installing missing .NET SDK channels via dotnet-install.sh: ${fallback_channels[*]}"
        curl -fsSL https://dot.net/v1/dotnet-install.sh -o "$install_script"
        chmod +x "$install_script"

        for channel in "${fallback_channels[@]}"; do
            if dotnet_sdk_installed "$channel"; then
                continue
            fi
            "$install_script" --channel "$channel" --install-dir "$HOME/.dotnet"
        done
    fi
}

cleanup_stale_azure_cli_repo() {
    # Old/unsupported azure-cli source entries can break apt update before we rewrite them.
    if [[ -f /etc/apt/sources.list.d/azure-cli.list || -f /etc/apt/sources.list.d/azure-cli.sources ]]; then
        info "Removing existing Azure CLI apt source files to avoid stale codename issues"
        $SUDO rm -f /etc/apt/sources.list.d/azure-cli.list /etc/apt/sources.list.d/azure-cli.sources
    fi
}

setup_dotnet_repo() {
    if dpkg -s packages-microsoft-prod >/dev/null 2>&1; then
        info "Microsoft package repo already configured"
        return
    fi

    local repo_pkg
    case "${ID:-}" in
        ubuntu)
            repo_pkg="https://packages.microsoft.com/config/ubuntu/${VERSION_ID}/packages-microsoft-prod.deb"
            ;;
        debian)
            repo_pkg="https://packages.microsoft.com/config/debian/${VERSION_ID}/packages-microsoft-prod.deb"
            ;;
        *)
            error "Unsupported distro ID for dotnet repo auto-config: ${ID:-unknown}"
            ;;
    esac

    info "Configuring Microsoft package repository"
    curl -fsSL "$repo_pkg" -o /tmp/packages-microsoft-prod.deb
    $SUDO dpkg -i /tmp/packages-microsoft-prod.deb
    rm -f /tmp/packages-microsoft-prod.deb
}

setup_azure_cli_repo() {
    local codename selected_codename test_url
    codename="${VERSION_CODENAME:-}"
    if [[ -z "$codename" ]]; then
        codename="$(lsb_release -cs)"
    fi

    selected_codename=""
    for candidate in "$codename" noble jammy focal; do
        test_url="https://packages.microsoft.com/repos/azure-cli/dists/${candidate}/Release"
        if curl -fsSLI "$test_url" >/dev/null 2>&1; then
            selected_codename="$candidate"
            break
        fi
    done

    if [[ -z "$selected_codename" ]]; then
        error "Could not find a supported Azure CLI apt distribution (tried: $codename, noble, jammy, focal)."
    fi

    if [[ "$selected_codename" != "$codename" ]]; then
        warning "Azure CLI repo does not yet support '$codename'; using '$selected_codename' instead."
    fi

    info "Configuring Azure CLI apt repository"
    $SUDO mkdir -p /etc/apt/keyrings
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | $SUDO tee /etc/apt/keyrings/microsoft.gpg >/dev/null
    $SUDO chmod go+r /etc/apt/keyrings/microsoft.gpg

    # Remove any previous source file to avoid stale/unsupported codenames.
    $SUDO rm -f /etc/apt/sources.list.d/azure-cli.sources
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ ${selected_codename} main" \
        | $SUDO tee /etc/apt/sources.list.d/azure-cli.list >/dev/null
}

install_fnm_and_node() {
    local fnm_cmd=""
    local node_bin node_dir

    if command -v fnm >/dev/null 2>&1; then
        fnm_cmd="$(command -v fnm)"
    else
        info "Installing fnm"
        curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
        if [[ -x "$HOME/.local/share/fnm/fnm" ]]; then
            fnm_cmd="$HOME/.local/share/fnm/fnm"
        fi
    fi

    if [[ -z "$fnm_cmd" ]]; then
        warning "fnm was not found after installation; skipping Node.js installation"
        return
    fi

    mkdir -p "$HOME/.local/bin"
    if [[ "$fnm_cmd" != "$HOME/.local/bin/fnm" ]]; then
        ln -sfn "$fnm_cmd" "$HOME/.local/bin/fnm"
    fi

    info "Installing latest Node.js LTS with fnm"
    eval "$($fnm_cmd env --shell bash)"
    "$fnm_cmd" install --lts
    "$fnm_cmd" default lts-latest

    # Ensure node/npm/npx are callable even before shell init picks up `fnm env`.
    if node_bin="$($fnm_cmd which lts-latest 2>/dev/null)" && [[ -n "$node_bin" ]]; then
        node_dir="$(dirname "$node_bin")"
        for bin in node npm npx corepack; do
            if [[ -x "$node_dir/$bin" ]]; then
                ln -sfn "$node_dir/$bin" "$HOME/.local/bin/$bin"
            fi
        done
    fi
}

install_uv() {
    if command -v uv >/dev/null 2>&1; then
        info "uv already installed"
        return
    fi

    info "Installing uv"
    UV_INSTALL_DIR="$HOME/.local/bin" curl -LsSf https://astral.sh/uv/install.sh | sh
}

install_azd() {
    if command -v azd >/dev/null 2>&1 || [[ -x "$HOME/.azd/bin/azd" ]]; then
        info "Azure Developer CLI already installed"
        return
    fi

    info "Installing Azure Developer CLI"
    curl -fsSL https://aka.ms/install-azd.sh | bash
}

print_versions() {
    echo
    success "Installed versions"
    command -v node >/dev/null 2>&1 && echo "node:    $(node --version)"
    command -v python3 >/dev/null 2>&1 && echo "python3: $(python3 --version)"
    command -v uv >/dev/null 2>&1 && echo "uv:      $(uv --version)"
    command -v dotnet >/dev/null 2>&1 && echo "dotnet:  $(dotnet --version)"
    command -v az >/dev/null 2>&1 && echo "az:      $(az version --query '"azure-cli"' -o tsv 2>/dev/null || echo 'installed')"
    command -v azd >/dev/null 2>&1 && echo "azd:     $(azd version 2>/dev/null | head -n1 || echo 'installed')"
}

cleanup_stale_azure_cli_repo

info "Refreshing apt indexes"
DEBIAN_FRONTEND=noninteractive $SUDO apt-get update -y

install_apt_packages "${APT_BASE_PACKAGES[@]}"
install_apt_packages "${APT_PYTHON_PACKAGES[@]}"

if [[ "$INSTALL_RECOMMENDED" == true ]]; then
    install_apt_packages "${APT_RECOMMENDED_PACKAGES[@]}"
fi

setup_dotnet_repo
setup_azure_cli_repo

info "Refreshing apt indexes after adding repositories"
DEBIAN_FRONTEND=noninteractive $SUDO apt-get update -y

install_apt_packages azure-cli
ensure_dotnet_path
install_dotnet_sdks
install_fnm_and_node
ensure_local_bin_path
install_uv
install_azd
ensure_azd_path

print_versions

echo
success "Toolchain installation complete. Open a new shell so PATH updates are active."