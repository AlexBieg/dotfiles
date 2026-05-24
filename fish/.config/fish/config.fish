set fish_greeting

if status is-interactive
    # =========================================================================
    # PATH setup (from .zshenv)
    # =========================================================================
    fish_add_path -g "$HOME/.cargo/bin"
    # $HOME/.local/bin is handled by ~/.local/bin/env.fish (sourced in conf.d)

    # =========================================================================
    # Homebrew (from .zprofile)
    # =========================================================================
    /opt/homebrew/bin/brew shellenv | source

    # =========================================================================
    # Editor (from 00-dotfiles.zsh)
    # =========================================================================
    if set -q SSH_CONNECTION
        set -gx EDITOR vim
    else
        set -gx EDITOR hx
    end

    # =========================================================================
    # Aliases (from 00-dotfiles.zsh)
    # =========================================================================
    alias python=python3
    alias lz=lazygit

    # eza overrides for ls and related commands
    alias ls='eza --icons=auto'
    alias ll='eza -l --icons=auto --git'
    alias la='eza -la --icons=auto --git'
    alias l='eza -l --icons=auto --git'
    alias lt='eza -T --icons=auto --git'
    alias lta='eza -Ta --icons=auto --git'
    alias lsa='eza -la --icons=auto --git'
    alias tree='eza -T --icons=auto'

    # =========================================================================
    # zoxide (cd replacement)
    # =========================================================================
    zoxide init fish | source

    # =========================================================================
    # Starship prompt
    # =========================================================================
    starship init fish | source

    # =========================================================================
    # fzf key bindings
    # =========================================================================
    set -gx FZF_DEFAULT_OPTS "$FZF_DEFAULT_OPTS --bind='alt-j:down,alt-k:up'"
    # Enable fzf key bindings for fish if fzf is installed
    if type -q fzf
        fzf --fish | source 2>/dev/null
    end
end
