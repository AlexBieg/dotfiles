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

AVAILABLE_PACKAGES=(zsh tmux helix zellij yazi pi starship git fish)
AVAILABLE_PROFILES=(personal work)
PROFILE=""

usage() {
    cat <<EOF
Usage: $(basename "$0") [--profile=PROFILE] [package...]

Install dotfile packages using GNU Stow.

Packages: ${AVAILABLE_PACKAGES[*]}
Profiles: ${AVAILABLE_PROFILES[*]}

If no packages are specified, all are installed.
If --profile is given, profile-specific overrides are stowed on top.

Examples:
  ./install.sh --profile=personal         # Install all packages with personal profile
  ./install.sh --profile=work zsh tmux    # Install only zsh and tmux with work profile
  ./install.sh zsh tmux                   # Install only zsh and tmux (no profile)
EOF
    exit 0
}

if [[ "$*" == *--help* ]] || [[ "$*" == *-h* ]]; then
    usage
fi

# ── Parse arguments ──────────────────────────────────────────────
PACKAGES=()
for arg in "$@"; do
    if [[ "$arg" == --profile=* ]]; then
        PROFILE="${arg#--profile=}"
    else
        PACKAGES+=("$arg")
    fi
done

if [ ${#PACKAGES[@]} -eq 0 ]; then
    PACKAGES=("${AVAILABLE_PACKAGES[@]}")
fi

# Validate profile
if [ -n "$PROFILE" ]; then
    if [ ! -d "$DOTFILES_DIR/profiles/$PROFILE" ]; then
        error "Unknown profile: $PROFILE. Available: ${AVAILABLE_PROFILES[*]}"
        exit 1
    fi
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
        if [ -f "$target" ]; then
            local backup="${target}.backup"
            warn "Backing up $target → $backup"
            mv "$target" "$backup"
        fi
    fi
}

# Ensure target directories exist so --no-folding works
ensure_dirs() {
    local pkg_dir="$1"
    while IFS= read -r dir; do
        local relative="${dir#$pkg_dir/}"
        local target="$HOME/$relative"
        mkdir -p "$target"
    done < <(find "$pkg_dir" -type d -mindepth 1)
}

stow_package() {
    local pkg="$1"
    local pkg_dir="$DOTFILES_DIR/$pkg"

    if [ ! -d "$pkg_dir" ]; then
        error "Package '$pkg' not found at $pkg_dir"
        return 1
    fi

    info "Stowing package: $pkg"

    ensure_dirs "$pkg_dir"

    while IFS= read -r file; do
        local relative="${file#$pkg_dir/}"
        local target="$HOME/$relative"
        backup_if_exists "$target"
    done < <(find "$pkg_dir" -type f)

    cd "$DOTFILES_DIR" && stow --no-folding -v -t "$HOME" "$pkg"
}

stow_profile() {
    local profile="$1"
    local profile_dir="$DOTFILES_DIR/profiles/$profile"

    info "Applying profile: $profile"

    # Directly symlink profile files into $HOME (avoids stow conflicts
    # when base packages already own parent directories)
    while IFS= read -r file; do
        local relative="${file#$profile_dir/}"
        # Strip the package prefix (e.g., zsh/.zshrc.d/90-local.zsh -> .zshrc.d/90-local.zsh)
        local pkg="${relative%%/*}"
        local inner="${relative#$pkg/}"
        local target="$HOME/$inner"

        mkdir -p "$(dirname "$target")"
        backup_if_exists "$target"

        if [ -L "$target" ]; then
            rm "$target"
        fi

        ln -sv "$file" "$target"
    done < <(find "$profile_dir" -type f)
}

# ── Per-package setup ────────────────────────────────────────────
setup_zsh() {
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

setup_pi() {
    stow_package "pi"
}

setup_starship() {
    stow_package "starship"
}

setup_git() {
    stow_package "git"
}

setup_fish() {
    stow_package "fish"
}

# ── Main ─────────────────────────────────────────────────────────
info "Setting up dotfiles from $DOTFILES_DIR"

for pkg in "${PACKAGES[@]}"; do
    case "$pkg" in
        zsh)      setup_zsh      ;;
        tmux)     setup_tmux     ;;
        helix)    setup_helix    ;;
        zellij)   setup_zellij   ;;
        yazi)     setup_yazi     ;;
        pi)       setup_pi       ;;
        starship) setup_starship ;;
        git)      setup_git      ;;
        fish)     setup_fish     ;;
        *)
            error "Unknown package: $pkg. Available: ${AVAILABLE_PACKAGES[*]}"
            exit 1
            ;;
    esac
done

# ── Apply profile overrides ──────────────────────────────────────
if [ -n "$PROFILE" ]; then
    stow_profile "$PROFILE"
fi

info "Done! Dotfiles are set up."
