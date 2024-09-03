# Homebrew
eval (/opt/homebrew/bin/brew shellenv)

# Oh My Posh
oh-my-posh init fish --config $(brew --prefix oh-my-posh)/themes/tokyonight_storm.omp.json | source

# fzf
eval "$(fzf --fish)"

# Use bat for files, eza for directories
set show_file_or_dir_preview 'if [ -d {} ]; then eza --tree --all --level=3 --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi'

# -- zoxide instead of cd --
zoxide init fish | source

# aliases and abbreviations

# terminal aliases
abbr zrc "nvim ~/.zshrc"
abbr szrc "source ~/.zshrc"
abbr exz "exec zsh"
abbr frc "nvim ~/.config/fish/config.fish"
abbr sfrc "source ~/.config/fish/config.fish"
abbr exf "exec fish"

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

abbr conv-commit "zsh ~/commit.sh"
abbr yolo-commit "git commit -m "$(curl -s https://whatthecommit.com/index.txt)""
abbr update-last-commit "git commit -a --amend --no-edit && git push --force-with-lease origin"

# -- lazygit aliases --
abbr lg lazygit

# -- yazi aliases --
abbr yz yazi

# -- zoxide instead of cd --
abbr cd z

set eza 'eza --git --icons=always --color=always'
set long '--long --no-user'
set cleaned '--no-permissions --no-filesize --no-time'

# -- eza for ls --
abbr l "$eza $long $cleaned"
abbr la "$eza $long $cleaned --all"
abbr ls l
abbr lsa la
abbr lsl "$eza $long"
abbr ll "$eza $long -all"
abbr lt "$eza $long -all --tree --level=2"
abbr lt2 "$eza $long -all --tree --level=3"
abbr lt3 "$eza $long -all --tree --level=4"
abbr ltg "$eza $long --tree --git-ignore"

# -- fzf with bat and eza previews --
abbr lspe "fzf --preview '$show_file_or_dir_preview'"
abbr lsp "fd --max-depth 1 --hidden --follow --exclude .git | fzf --preview '$show_file_or_dir_preview'"
