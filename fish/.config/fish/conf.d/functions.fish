# Custom utility functions

function cached_source --description "Source a command's cached output; refresh it in the background once a day"
    set -l cache ~/.cache/$argv[1].fish
    command -q $argv[2]; or return
    test -r $cache; and source $cache
    if not test -r $cache; or test (math (date +%s) - (path mtime -- $cache)) -gt 86400
        command mkdir -p ~/.cache
        nohup fish --no-config -c '$argv[3..] > $argv[1]; and command mv -f $argv[1] $argv[2]; or command rm -f $argv[1]' \
            $cache.(random) $cache $argv[2..] &>/dev/null &
        disown
    end
end

function mk --description "Create directory and cd into it"
    mkdir -p $argv[1]; and cd $argv[1]
end

function gcl --description "Clone repo and cd into it"
    git clone $argv[1]; and cd (basename $argv[1] .git)
end

function fkill --description "Find and kill process with fzf"
    set -l signal 9
    set -q argv[1]; and set signal $argv[1]
    set -l pid (ps -ef | sed 1d | fzf -m | awk '{print $2}')
    if test -n "$pid"
        echo $pid | xargs kill -$signal
    end
end

function devs --description "Show listening dev server ports"
    lsof -nP -iTCP -sTCP:LISTEN | grep -E "(node|next|astro|vite|webpack|parcel)" |
        awk '{split($9, addr, ":"); port = addr[length(addr)]; process = $1; printf "\033[1;36m%-6s\033[0m \033[1;33m%s\033[0m\n", process, port}' |
        sort -k2 -n
end

function bsy --description "Delete local branches gone from remote"
    git fetch -p
    for branch in (git branch -vv | grep ': gone]' | awk '{print $1}')
        git branch -d $branch
    end
end

function brewfile --description "Generate Brewfile in dotfiles/brew"
    set -l current_dir $PWD
    cd ~/dotfiles/brew
    brew bundle dump --formula --cask --tap --mas --force $argv
    cd $current_dir
end

function nvims --description "Switch between Neovim configs with fzf"
    set -l items default kickstart LazyVim NvChad AstroNvim
    set -l config (printf '%s\n' $items | fzf --prompt=" Neovim Config  " --height=~50% --layout=reverse --border --exit-0)

    if test -z "$config"
        echo "Nothing selected"
        return 0
    else if test "$config" = "default"
        set config ""
    end

    NVIM_APPNAME=$config nvim $argv
end

function vv --description "Select Neovim config from ~/.config with fzf"
    set -l config (fd --max-depth 1 --glob '{nvim*,LazyVim*}' ~/.config | fzf --prompt="Neovim Configs > " --height=~50% --layout=reverse --border --exit-0)

    if test -z "$config"
        echo "No config selected"
        return
    end

    NVIM_APPNAME=(basename $config) nvim $argv
end

function gcb --description "Git commit browser with fzf"
    git log --graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" $argv |
        fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
            --bind "ctrl-m:execute:
      (grep -o '[a-f0-9]\{7\}' | head -1 |
        xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
              {}
              FZF-EOF"
end

function gdb --description "Git diff browser with fzf"
    set -l preview "git diff $argv --color=always -- {}"
    git diff $argv --name-only | fzf -m --ansi --preview "$preview"
end
