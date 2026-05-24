export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"

if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='hx'
fi

alias python=python3
alias lz=lazygit

eval "$(zoxide init zsh)"
eval "$(starship init zsh)"

export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --bind='alt-j:down,alt-k:up'"

# eza overrides for ls and related commands
alias ls='eza --icons=auto'
alias ll='eza -l --icons=auto --git'
alias la='eza -la --icons=auto --git'
alias l='eza -l --icons=auto --git'
alias lt='eza -T --icons=auto --git'
alias lta='eza -Ta --icons=auto --git'
alias lsa='eza -la --icons=auto --git'
alias tree='eza -T --icons=auto'
