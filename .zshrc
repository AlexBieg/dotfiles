# Load antigen
source ~/.dotfiles/antigen/antigen.zsh
antigen use oh-my-zsh

# Bundles from the default repo (robbyrussell's oh-my-zsh).
# antigen bundle pip
antigen bundle pyenv
antigen bundle colored-man-pages

# Load the theme.
antigen theme agnoster

# Syntax highlighting bundle.
antigen bundle zsh-users/zsh-syntax-highlighting

# Tell antigen that you're done.
antigen apply

# autoload -U zmv

export CLICOLOR="xterm-color"

# OS X / BSD colors for ls
export LSCOLORS="dxfxgxdxexcxGxxxxxxxxx"

# UNIX colors for ls
export LS_COLORS="di=1;34:fi=0:ln=31:pi=36:so=36:bd=36:cd=36:or=31:mi=33:ex=35:*.rpm=90"

# Always use color in grep
export GREP_OPTIONS='--color=auto'

# Vi-like mode
bindkey -v

bindkey '^r' history-incremental-search-backward
bindkey '^w' backward-kill-word

bindkey "^[[A" history-beginning-search-backward
bindkey "^[[B" history-beginning-search-forward

# Transition to Vi-mode set to 0.1s
export KEYTIMEOUT=1

##################################
### Begin Vi-mode cursor indicator
##################################

function print_dcs
{
  print -n -- "\EP$1;\E$2\E\\"
}

function set_cursor_shape
{
  if [ -n "$TMUX" ]; then
    # tmux will only forward escape sequences to the terminal if surrounded by
    # a DCS sequence
    print_dcs tmux "\E]50;CursorShape=$1\C-G"
  else
    print -n -- "\E]50;CursorShape=$1\C-G"
  fi
}

function zle-keymap-select zle-line-init
{
  case $KEYMAP in
    vicmd)
      set_cursor_shape 2 # flat cursor (normal)
      ;;
    viins|main)
      set_cursor_shape 0 # block cursor (insert)
      ;;
  esac
  zle reset-prompt
  zle -R
}

function zle-line-finish
{
  set_cursor_shape 0 # block cursor
}

zle -N zle-line-init
zle -N zle-line-finish
zle -N zle-keymap-select

################################
### End Vi-mode cursor indicator
################################

export EDITOR="vim"
export DISABLE_AUTO_TITLE="true"

# Tell ack to look for project-local ack configs
export ACKRC=".ackrc"

# Allow local customizations in the ~/.zshrc_local_after file
if [ -f ~/.zshrc_local_after ]; then
  source ~/.zshrc_local_after
fi
