# dotfiles

Managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Usage

```bash
git clone git@github.com:AlexBieg/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Install all packages with a profile
./install.sh --profile=personal

# Or install selectively
./install.sh --profile=work zsh tmux
```

## Packages

| Package    | Contents |
|------------|----------|
| `zsh`      | `.zshrc.d/`, `.zshenv`, `.zprofile` — modular zsh config |
| `tmux`     | `.tmux.conf` |
| `helix`    | `.config/helix/config.toml`, `.config/helix/languages.toml` |
| `zellij`   | `.config/zellij/config.kdl` |
| `yazi`     | `.config/yazi/yazi.toml` |
| `pi`       | `.pi/agent/settings.json`, `.pi/agent/extensions/helix-bridge.ts`, `.local/bin/helix-pi` |
| `starship` | `.config/starship.toml` |
| `git`      | `.gitconfig.local` — diffnav/delta pager config |

## Profiles

Profiles provide machine-specific overrides that are stowed on top of the base
packages. Each profile lives in `profiles/<name>/` and mirrors the stow package
directory structure.

| Profile    | Description |
|------------|-------------|
| `personal` | Personal laptop config |
| `work`     | Work (Headway) laptop config |

Profile-specific files:
- `profiles/<name>/zsh/.zshrc.d/90-local.zsh` — machine-specific shell setup

## How it works

Each package directory mirrors the `$HOME` directory structure. Stow creates
symlinks from `$HOME` back to the repo files. Existing files are backed up
with a `.backup` suffix before being replaced.

After base packages are stowed, the selected profile's overrides are stowed
on top, adding any machine-specific configuration.
