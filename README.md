# dotfiles

Managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Usage

```bash
git clone git@github.com:AlexBieg/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Install all packages
./install.sh

# Or install selectively
./install.sh zsh tmux
```

## Packages

| Package | Contents |
|---------|----------|
| `zsh`   | `.zshrc`, `.zshenv`, `.zprofile` — auto-installs Oh My Zsh if missing |
| `tmux`  | `.tmux.conf` |
| `helix` | `.config/helix/config.toml`, `.config/helix/languages.toml` |
| `zellij` | `.config/zellij/config.kdl` |

## How it works

Each package directory mirrors the `$HOME` directory structure. Stow creates
symlinks from `$HOME` back to the repo files. Existing files are backed up
with a `.backup` suffix before being replaced.
