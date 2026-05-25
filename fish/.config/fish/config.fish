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

    # =========================================================================
    # Git aliases (standard oh-my-zsh git plugin)
    # =========================================================================

    # Helper: get the current branch name
    function git_current_branch
        git rev-parse --abbrev-ref HEAD 2>/dev/null
    end

    # Core git
    alias g 'git'

    # Add
    alias ga 'git add'
    alias gaa 'git add --all'
    alias gapa 'git add --patch'
    alias gau 'git add --update'
    alias gav 'git add --verbose'

    # Apply
    alias gap 'git apply'
    alias gapt 'git apply --3way'

    # Branch
    alias gb 'git branch'
    alias gba 'git branch --all'
    alias gbd 'git branch --delete'
    alias gbD 'git branch --delete --force'
    alias gbm 'git branch --move'
    alias gbnm 'git branch --no-merged'
    alias gbr 'git branch --remote'

    # Checkout / Switch
    alias gco 'git checkout'
    alias gcb 'git checkout -b'
    alias gcB 'git checkout -B'
    alias gsw 'git switch'
    alias gswc 'git switch --create'

    # Cherry-pick
    alias gcp 'git cherry-pick'
    alias gcpa 'git cherry-pick --abort'
    alias gcpc 'git cherry-pick --continue'

    # Clean
    alias gclean 'git clean --interactive -d'

    # Clone
    alias gcl 'git clone --recurse-submodules'

    # Commit
    alias gc 'git commit --verbose'
    alias gca 'git commit --verbose --all'
    alias gcam 'git commit --all --message'
    alias gcmsg 'git commit --message'
    alias gcsm 'git commit --signoff --message'
    alias gcas 'git commit --all --signoff'
    alias gc! 'git commit --verbose --amend'
    alias gca! 'git commit --verbose --all --amend'
    alias gcan! 'git commit --verbose --all --no-edit --amend'
    alias gcn! 'git commit --verbose --no-edit --amend'
    alias gcf 'git config --list'

    # Diff
    alias gd 'git diff'
    alias gdca 'git diff --cached'
    alias gdcw 'git diff --cached --word-diff'
    alias gds 'git diff --staged'
    alias gdw 'git diff --word-diff'
    alias gdt 'git diff-tree --no-commit-id --name-only -r'

    # Fetch
    alias gf 'git fetch'
    alias gfa 'git fetch --all --tags --prune --jobs=10'
    alias gfo 'git fetch origin'

    # Log
    alias glo 'git log --oneline --decorate'
    alias glog 'git log --oneline --decorate --graph'
    alias gloga 'git log --oneline --decorate --graph --all'
    alias glgg 'git log --graph'
    alias glgga 'git log --graph --decorate --all'
    alias glol 'git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset"'
    alias glola 'git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --all'
    alias glg 'git log --stat'
    alias glgp 'git log --stat --patch'

    # Merge
    alias gm 'git merge'
    alias gma 'git merge --abort'
    alias gmc 'git merge --continue'
    alias gms 'git merge --squash'
    alias gmff 'git merge --ff-only'

    # Mergetool
    alias gmtl 'git mergetool --no-prompt'

    # Pull
    alias gl 'git pull'
    alias gpr 'git pull --rebase'
    alias gpra 'git pull --rebase --autostash'

    # Push
    alias gp 'git push'
    alias gpd 'git push --dry-run'
    alias gpf 'git push --force-with-lease --force-if-includes'
    alias gpf! 'git push --force'
    alias gpv 'git push --verbose'
    alias gpsup 'git push --set-upstream origin (git_current_branch)'
    alias gpoat 'git push origin --all; and git push origin --tags'
    alias gpod 'git push origin --delete'

    # Rebase
    alias grb 'git rebase'
    alias grba 'git rebase --abort'
    alias grbc 'git rebase --continue'
    alias grbi 'git rebase --interactive'
    alias grbo 'git rebase --onto'
    alias grbs 'git rebase --skip'

    # Reflog
    alias grf 'git reflog'

    # Remote
    alias gr 'git remote'
    alias grv 'git remote --verbose'
    alias gra 'git remote add'
    alias grrm 'git remote remove'
    alias grmv 'git remote rename'
    alias grset 'git remote set-url'
    alias grup 'git remote update'

    # Reset
    alias grh 'git reset'
    alias gru 'git reset --'
    alias grhh 'git reset --hard'
    alias grhk 'git reset --keep'
    alias grhs 'git reset --soft'
    alias gpristine 'git reset --hard; and git clean --force -dfx'
    alias gwipe 'git reset --hard; and git clean --force -df'

    # Restore
    alias grs 'git restore'
    alias grss 'git restore --source'
    alias grst 'git restore --staged'

    # Revert
    alias grev 'git revert'
    alias greva 'git revert --abort'
    alias grevc 'git revert --continue'

    # rm
    alias grm 'git rm'
    alias grmc 'git rm --cached'

    # Show
    alias gsh 'git show'
    alias gsps 'git show --pretty=short --show-signature'

    # Stash
    alias gsta 'git stash push'
    alias gstaa 'git stash apply'
    alias gstc 'git stash clear'
    alias gstd 'git stash drop'
    alias gstl 'git stash list'
    alias gstp 'git stash pop'
    alias gsts 'git stash show --patch'
    alias gstall 'git stash --all'
    alias gstu 'git stash push --include-untracked'

    # Status
    alias gst 'git status'
    alias gss 'git status --short'
    alias gsb 'git status --short --branch'

    # Submodule
    alias gsi 'git submodule init'
    alias gsu 'git submodule update'

    # Tag
    alias gta 'git tag --annotate'
    alias gts 'git tag --sign'
    alias gtv 'git tag | sort -V'

    # Worktree
    alias gwt 'git worktree'
    alias gwta 'git worktree add'
    alias gwtls 'git worktree list'
    alias gwtmv 'git worktree move'
    alias gwtrm 'git worktree remove'

    # Bisect
    alias gbs 'git bisect'
    alias gbsb 'git bisect bad'
    alias gbsg 'git bisect good'
    alias gbsr 'git bisect reset'
    alias gbss 'git bisect start'

    # Blame
    alias gbl 'git blame -w'

    # Other
    alias gcount 'git shortlog --summary --numbered'
    alias ghh 'git help'
    alias gignore 'git update-index --assume-unchanged'
    alias gunignore 'git update-index --no-assume-unchanged'
    alias gfg 'git ls-files | grep'
    alias grt 'cd (git rev-parse --show-toplevel || echo .)'
end
