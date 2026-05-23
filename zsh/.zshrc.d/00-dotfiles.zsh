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
