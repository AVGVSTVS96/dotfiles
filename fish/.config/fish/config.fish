# Fish port of ~/.zshrc, for machines whose login shell is fish. Keep the two in step.

set -q XDG_CONFIG_HOME; or set -gx XDG_CONFIG_HOME ~/.config
set -q XDG_DATA_HOME; or set -gx XDG_DATA_HOME ~/.local/share
set -q XDG_CACHE_HOME; or set -gx XDG_CACHE_HOME ~/.cache

set -gx AGENT_BROWSER_CONFIG $XDG_CONFIG_HOME/agent-browser/config.json
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx BAT_THEME tokyonight_night
set -gx LG_CONFIG_FILE ~/.config/lazygit/config.yml

if test (uname) = Darwin
    set -gx PNPM_HOME ~/Library/pnpm
    set -gx OPENCLAW_IMAGE_BACKEND sips
else
    set -gx PNPM_HOME $XDG_DATA_HOME/pnpm
end

contains -- ./node_modules/.bin $PATH; or set -gx PATH $PATH ./node_modules/.bin
fish_add_path -P -a /Applications/Cursor.app/Contents/Resources/app/bin ~/.cargo/bin ~/.cache/.bun/bin ~/.maestro/bin
fish_add_path -P -m ~/.local/share/fnm/aliases/default/bin ~/.local/bin $PNPM_HOME

if status is-interactive
    oh-my-posh init fish --config ~/.config/oh-my-posh/tokyonight_storm-customized.omp.json | source

    # fzf: fd for candidates, bat/eza previews. Previews run under sh, whatever the login shell.
    set -gx FZF_DEFAULT_OPTS "--with-shell='sh -c'"
    set -gx FZF_DEFAULT_COMMAND "fd --hidden --strip-cwd-prefix --exclude .git"
    set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
    set -gx FZF_ALT_C_COMMAND "fd --type=d --hidden --strip-cwd-prefix --exclude .git"
    set -l show_file_or_dir_preview 'if [ -d {} ]; then eza --tree --all --level=3 --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi'
    set -gx FZF_CTRL_T_OPTS "--preview '$show_file_or_dir_preview'"
    set -gx FZF_ALT_C_OPTS "--preview 'eza --tree --color=always {} | head -200'"
    cached_source fzf fzf --fish

    # fzf.fish plugin (fish_plugins), when installed through fisher
    set fzf_fd_opts --hidden --exclude .git
    set fzf_preview_dir_cmd 'eza --tree --all --level=3 --color=always'

    cached_source thefuck thefuck --alias

    test "$CLAUDECODE" = 1; or zoxide init --cmd cd fish | source

    cached_source fnm fnm env --use-on-cd --shell fish
    cached_source openclaw openclaw completion --shell fish
    cached_source but-completions but completions fish
    cached_source pnpm-completions pnpm completion fish

    if test (uname) = Darwin
        abbr -a --position anywhere -- '~iCloud' "'$HOME/Library/Mobile Documents/com~apple~CloudDocs'"
        abbr -a pbc pbcopy
    else
        abbr -a pbc wl-copy
    end

    abbr -a br bun run
    abbr -a xr xpm run
    abbr -a pr pnpm run
    abbr -a xi xpm install
    abbr -a bi bun install
    abbr -a xd xpm run dev
    abbr -a pd pnpm run dev
    abbr -a bd bun run dev
    abbr -a zrc nvim ~/.zshrc
    abbr -a exz exec zsh
    abbr -a frc nvim ~/.config/fish/config.fish
    abbr -a sfrc source ~/.config/fish/config.fish
    abbr -a exf exec fish
    abbr -a cl clear
    abbr -a add-skill skills add -g -a universal claude-code -y

    abbr -a -- - cd -
    abbr -a ... cd ../..
    abbr -a .... cd ../../..
    abbr -a ..... cd ../../../..

    abbr -a g git
    abbr -a ga git add -A
    abbr -a gs git status
    abbr -a gss git status -s
    abbr -a gsm git switch main
    abbr -a gc git commit
    abbr -a gca git commit -a
    abbr -a gcam git commit -a --amend --no-edit
    abbr -a gf git fetch
    abbr -a gpl git pull
    abbr -a gp git push
    abbr -a gpf git push --force-with-lease origin
    abbr -a gd git diff
    abbr -a conv-commit zsh ~/commit.sh
    abbr -a yolo-commit 'git commit -m "$(curl -s https://whatthecommit.com/index.txt)"'
    abbr -a update-last-commit 'git commit -a --amend --no-edit && git push --force-with-lease origin'
    abbr -a prc gh pr create
    abbr -a list-servers devs

    abbr -a lg lazygit
    abbr -a yz yazi

    set -l eza 'eza --git --icons=always --color=always'
    set -l long '--long --no-user'
    set -l cleaned '--no-permissions --no-filesize --no-time'
    abbr -a l "$eza $long $cleaned"
    abbr -a la "$eza $long $cleaned --all"
    abbr -a ls "$eza $long $cleaned"
    abbr -a lsa "$eza $long $cleaned --all"
    abbr -a lsl "$eza $long"
    abbr -a ll "$eza $long -all"
    abbr -a lt "$eza $long -all --tree --level=2"
    abbr -a lt2 "$eza $long -all --tree --level=3"
    abbr -a lt3 "$eza $long -all --tree --level=4"
    abbr -a ltg "$eza $long --tree --git-ignore"

    abbr -a lspe "fzf --preview '$show_file_or_dir_preview'"
    abbr -a lsp "fd --max-depth 1 --hidden --follow --exclude .git | fzf --preview '$show_file_or_dir_preview'"

    alias claude 'claude --dangerously-skip-permissions'
    abbr -a c claude
    abbr -a cx codex
end
