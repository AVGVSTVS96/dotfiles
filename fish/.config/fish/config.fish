# Environment variables
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx XDG_CONFIG_HOME ~/.config
set -gx XDG_DATA_HOME ~/.local/share
set -gx XDG_CACHE_HOME ~/.cache

# Homebrew
eval (/opt/homebrew/bin/brew shellenv)

# Oh My Posh
oh-my-posh init fish --config ~/.config/oh-my-posh/tokyonight_storm-customized.omp.json | source

# fzf.fish plugin configuration (plugin installed via fisher)
# The plugin handles keybindings: Ctrl+Alt+F (files), Ctrl+Alt+L (git log),
# Ctrl+Alt+S (git status), Ctrl+R (history), Ctrl+Alt+P (processes)
set fzf_fd_opts --hidden --exclude .git
set fzf_preview_dir_cmd 'eza --tree --all --level=3 --color=always'
set -gx FZF_DEFAULT_COMMAND "fd --hidden --strip-cwd-prefix --exclude .git"

# NPM local modules (highest priority for project-specific tools)
fish_add_path -p ./node_modules/.bin

# User-local binaries
fish_add_path -p ~/.local/bin

# Node version management is handled by nvm.sh auto-use logic in conf.d.

# pnpm
set -gx PNPM_HOME $HOME/Library/pnpm
fish_add_path $PNPM_HOME

# Cargo (Rust)
fish_add_path $HOME/.cargo/bin

# Cursor Editor
fish_add_path "/Applications/Cursor.app/Contents/Resources/app/bin"

# Bun
fish_add_path "$HOME/.cache/.bun/bin"

# Additional environment variables
set -gx BAT_THEME tokyonight_night
set -gx LG_CONFIG_FILE $HOME/.config/lazygit/config.yml


# -- thefuck --
if type -q thefuck
    thefuck --alias | source
end

# -- zoxide (better cd) - disable in Claude Code environment --
if test "$CLAUDECODE" != "1"
    zoxide init fish --cmd cd | source
end

# -- OpenClaw --
set -gx OPENCLAW_IMAGE_BACKEND sips
# Source cached completions (regenerate with: openclaw completion --shell fish > ~/.cache/openclaw.fish)
test -f ~/.cache/openclaw.fish && source ~/.cache/openclaw.fish

# aliases and abbreviations

# terminal aliases
abbr zrc "nvim ~/.zshrc"
abbr szrc "source ~/.zshrc"
abbr exz "exec zsh"
abbr frc "nvim ~/.config/fish/config.fish"
abbr sfrc "source ~/.config/fish/config.fish"
abbr exf "exec fish"
abbr cl clear

# -- cd abbreviations --
abbr - "cd -"
abbr ... "cd ..."
abbr .... "cd ....."
abbr ..... "cd ......"

# -- git aliases --
abbr g git
abbr gs "git status"
abbr gss "git status -s"
abbr gc "git commit"
abbr gca "git commit -a"
abbr gcam "git commit -a --amend --no-edit"
abbr gf "git fetch"
abbr gpl "git pull"
abbr gp "git push"
abbr gpf "git push --force-with-lease origin"
abbr ga "git add -A"
abbr gd "git diff"
abbr gsm "git switch main"
abbr prc "gh pr create"

abbr conv-commit "zsh ~/commit.sh"
abbr yolo-commit "git commit -m "$(curl -s https://whatthecommit.com/index.txt)""
abbr update-last-commit "git commit -a --amend --no-edit && git push --force-with-lease origin"

# -- lazygit aliases --
abbr lg lazygit

# -- yazi aliases --
abbr yz yazi


set eza 'eza --git --icons=always --color=always'
set long '--long --no-user'
set cleaned '--no-permissions --no-filesize --no-time'

# -- eza for ls --
abbr l "$eza $long $cleaned"
abbr la "$eza $long $cleaned --all"
abbr ls "$eza $long $cleaned"
abbr lsa "$eza $long $cleaned --all"
abbr lsl "$eza $long"
abbr ll "$eza $long -all"
abbr lt "$eza $long -all --tree --level=2"
abbr lt2 "$eza $long -all --tree --level=3"
abbr lt3 "$eza $long -all --tree --level=4"
abbr ltg "$eza $long --tree --git-ignore"

# -- claude --
abbr c "claude --dangerously-skip-permissions"
abbr pbc "pbcopy"

# -- fastfetch --
#fastfetch
