#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

AVAILABLE_PACKAGES=(zsh tmux helix zellij yazi)

usage() {
    cat <<EOF
Usage: $(basename "$0") [package...]

Install dotfile packages using GNU Stow.

Packages: ${AVAILABLE_PACKAGES[*]}
If no packages are specified, all are installed.

Examples:
  ./install.sh              # Install all packages
  ./install.sh zsh tmux     # Install only zsh and tmux
EOF
    exit 0
}

if [[ "$*" == *--help* ]] || [[ "$*" == *-h* ]]; then
    usage
fi

if [ $# -eq 0 ]; then
    PACKAGES=("${AVAILABLE_PACKAGES[@]}")
else
    PACKAGES=("$@")
fi

# ── Ensure GNU Stow ──────────────────────────────────────────────
if ! command -v stow &>/dev/null; then
    info "GNU Stow not found. Installing via Homebrew..."
    if ! command -v brew &>/dev/null; then
        error "Homebrew is required. Install it from https://brew.sh"
        exit 1
    fi
    brew install stow
fi

# ── Helpers ──────────────────────────────────────────────────────
backup_if_exists() {
    local target="$1"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        local backup="${target}.backup"
        warn "Backing up $target → $backup"
        mv "$target" "$backup"
    fi
}

stow_package() {
    local pkg="$1"
    local pkg_dir="$DOTFILES_DIR/$pkg"

    if [ ! -d "$pkg_dir" ]; then
        error "Package '$pkg' not found at $pkg_dir"
        return 1
    fi

    info "Stowing package: $pkg"

    while IFS= read -r file; do
        local relative="${file#$pkg_dir/}"
        local target="$HOME/$relative"
        backup_if_exists "$target"
    done < <(find "$pkg_dir" -type f)

    cd "$DOTFILES_DIR" && stow -v -t "$HOME" "$pkg"
}

# ── Per-package setup ────────────────────────────────────────────
setup_zsh() {
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        info "Installing Oh My Zsh..."
        export RUNZSH=no
        export CHSH=no
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        info "Oh My Zsh already installed."
    fi
    stow_package "zsh"
}

setup_tmux() {
    stow_package "tmux"
}

setup_helix() {
    stow_package "helix"
}

setup_zellij() {
    stow_package "zellij"
}

setup_yazi() {
    stow_package "yazi"
}

# ── Main ─────────────────────────────────────────────────────────
info "Setting up dotfiles from $DOTFILES_DIR"

for pkg in "${PACKAGES[@]}"; do
    case "$pkg" in
        zsh)   setup_zsh   ;;
        tmux)  setup_tmux  ;;
        helix) setup_helix ;;
        zellij) setup_zellij ;;
        yazi) setup_yazi ;;
        *)
            error "Unknown package: $pkg. Available: ${AVAILABLE_PACKAGES[*]}"
            exit 1
            ;;
    esac
done

info "Done! Dotfiles are set up."
