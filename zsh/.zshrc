# ── cached eval ──
# Caches the output of a slow command and sources it.
# Refreshes in background if the cache is older than 1 day.
# Usage: cached_eval <cache-name> <command...>
zmodload zsh/stat 2>/dev/null
zmodload zsh/datetime 2>/dev/null

cached_eval() {
    local name="$1"
    shift

    local cache_file="$HOME/.cache/${name}.zsh"
    local lock_file="${cache_file}.lock"
    local log_file="${cache_file}.refresh.log"
    local max_age=86400
    local -a cache_stat
    local stale=1

    if [[ -r "$cache_file" ]]; then
        source "$cache_file"

        if zstat -A cache_stat +mtime -- "$cache_file" 2>/dev/null; then
            (( EPOCHSECONDS - cache_stat[1] <= max_age )) && stale=0
        fi
    fi

    (( stale )) || return

    [[ -d "${cache_file:h}" ]] || command mkdir -p -- "${cache_file:h}" || return
    : >> "$lock_file"

    (
        zmodload zsh/system || return
        zsystem flock -t 0 "$lock_file" 2>/dev/null || return

        # Another shell may have refreshed it between our stale check and lock.
        local -a current_stat
        if [[ -r "$cache_file" ]] &&
           zstat -A current_stat +mtime -- "$cache_file" 2>/dev/null &&
           (( EPOCHSECONDS - current_stat[1] <= max_age )); then
            return
        fi

        local tmp="${cache_file}.tmp.$$.${RANDOM}"
        trap 'command rm -f -- "$tmp" "$tmp.zwc"' EXIT

        "$@" >| "$tmp" || return
        zcompile "$tmp" || return

        # Atomic replacements keep readers from seeing partial cache files.
        command mv -f -- "$tmp" "$cache_file" || return
        command mv -f -- "$tmp.zwc" "$cache_file.zwc"
    ) >> "$log_file" 2>&1 &!
}

# --- Check OS ---
OS_TYPE="$(uname)"
darwin=false
linux=false

# Set variables based on OS type
if [[ "$OS_TYPE" == "Darwin" ]]; then
  darwin=true
elif [[ "$OS_TYPE" == "Linux" ]]; then
  linux=true
fi

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

export AGENT_BROWSER_CONFIG="$XDG_CONFIG_HOME/agent-browser/config.json"

# --- PATH ---
export PATH="$PATH:./node_modules/.bin"

# --- Cursor ---
export PATH="$PATH:/Applications/Cursor.app/Contents/Resources/app/bin"

# --- Cargo ---
export PATH="$PATH:$HOME/.cargo/bin"

# --- oh-my-zsh ---
export ZSH="$HOME/.oh-my-zsh"
ZSH_DISABLE_COMPFIX=false
ZSH_COMPDUMP="${ZDOTDIR:-$HOME}/.zcompdump-${HOST/.*/}-${ZSH_VERSION}"

# --- zsh plugins ---
plugins=(git)

for plugin in zsh-syntax-highlighting zsh-autosuggestions; do
  for dir in ${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/share} /usr/share/zsh/plugins; do
    [[ -r $dir/$plugin/$plugin.zsh ]] && source $dir/$plugin/$plugin.zsh && break
  done
done
unset plugin dir

# load oh-my-zsh
source $ZSH/oh-my-zsh.sh


# --- oh-my-posh ---
eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/tokyonight_storm-customized.omp.json)"

# --- bat ---
#  Install theme:
#   curl -O https://raw.githubusercontent.com/folke/tokyonight.nvim/main/extras/sublime/tokyonight_night.tmTheme
#   bat cache --build
export BAT_THEME=tokyonight_night


# --- lazygit ---
export LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml"


# --- fzf ---
cached_eval fzf fzf --zsh

# -- Use fd instead of fzf --
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# Use fd (https://github.com/sharkdp/fd) for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}

# -- fzf-git script --
[[ -f ~/fzf-git.sh ]] && source ~/fzf-git.sh

# -- fzf previews --
# Use bat for files, eza for directories
show_file_or_dir_preview='if [ -d {} ]; then eza --tree --all --level=3 --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi'

export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

# -- Advanced customization of fzf options via _fzf_comprun function --
# - The first argument to the function is the name of the command.
# - You should make sure to pass the rest of the arguments to fzf.
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;; 
    unalias)      fzf --preview "grep '^alias {}=' ~/.zshrc" "$@" ;;
    export|unset) fzf --preview "eval 'echo $'{}"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview "bat -n --color=always --line-range :500 {}" "$@" ;;
  esac
}


# --- thefuck ---
cached_eval thefuck thefuck --alias


# --- zoxide (better cd) ---
if [[ "$CLAUDECODE" != "1" ]]; then
    eval "$(zoxide init --cmd cd zsh)"
fi


# -- named directory --
# TODO maybe revert to symlink
hash -d iCloud="$HOME/Library/Mobile Documents/com~apple~CloudDocs"

# --- aliases ---
# -- zsh --
alias br="bun run"
alias xr="xpm run"
alias pr="pnpm run"
alias xi="xpm install"
alias bi="bun install"
alias xd="xpm run dev"
alias pd="pnpm run dev"
alias bd="bun run dev"
alias bd="bun run dev"
alias zrc="nvim ~/.zshrc"
alias szrc="source ~/.zshrc"
alias exz="exec zsh"
alias cl="clear"
alias add-skill="skills add -g -a universal claude-code -y"

# -- git --
alias aga="add_git_alias"
alias g="git"
alias ga="git add -A"
alias gs="git status"
alias gss="git status -s"
alias gsm="git switch main"
alias gc="git commit"
alias gca="git commit -a"
alias gcam="git commit -a --amend --no-edit"
alias gf="git fetch"
alias gpl="git pull"
alias gp="git push"
alias gpf="git push --force-with-lease origin"
alias gd="git diff"
alias bsy="git fetch -p | git branch -vv | grep ': gone]' | awk '{print }' | xargs -n 1 git branch -d"
alias conv-commit="zsh ~/commit.sh"
alias update-last-commit="git commit -a --amend --no-edit && git push --force-with-lease origin"
alias prc="gh pr create"
alias devs='lsof -nP -iTCP -sTCP:LISTEN | grep -E "(node|next|astro|vite|webpack|parcel)" | awk "{split(\$9, addr, \":\"); port = addr[length(addr)]; process = \$1; printf \"\\033[1;36m%-6s\\033[0m \\033[1;33m%s\\033[0m\\n\", process, port}" | sort -k2 -n'
alias list-servers="devs"
$darwin && alias pbc="pbcopy" || alias pbc="wl-copy"

unalias gcb
unalias gcl

# -- lazygit --
alias lg="lazygit"

# -- yazi --
alias yz="yazi"

# -- zoxide instead of cd --
# `zoxide init --cmd cd zsh` applies alias automatically
# alias cd="z"

eza='eza --git --icons=always --color=always'
long='--long --no-user'
cleaned='--no-permissions --no-filesize --no-time'

# -- eza for ls --
alias   l="$eza $long $cleaned"
alias  la="$eza $long $cleaned --all"
alias  ls="l"
alias lsa="la"
alias lsl="$eza $long"
alias  ll="$eza $long -all"
alias  lt="$eza $long -all --tree --level=2"
alias lt2="$eza $long -all --tree --level=3"
alias lt3="$eza $long -all --tree --level=4"
alias ltg="$eza $long --tree --git-ignore"

# -- fzf with bat and eza previews --
alias lspe="fzf --preview '$show_file_or_dir_preview'"
alias lsp="fd --max-depth 1 --hidden --follow --exclude .git | fzf --preview '$show_file_or_dir_preview'"

# -- claude --
alias claude="claude --dangerously-skip-permissions"
alias c="claude" # NO LONGER WORKS: in ~/.claude/settings.json → "permissions.defaultMode": "bypassPermissions"
alias cx="codex" # in ~/.codex/config.toml → approval_policy = "never", sandbox_mode = "danger-full-access"

# -- ai-tmux: my cli agent wrapper for tmux-based session persistence and restoration --
# WARN ai-tmux is flaky, my persistence startegy is more minmal and reliable now:
#   1. use tmux-resurrect with restore-pane-contents enabled
#   2. use tmux-continuum to auto-save tmux sessions every 5 minutes
#   3. set coding agent statuslines to display session-id
#
# when tmux server is killed or crashed, tmux-resurrect restores all panes, windows, and sessions.
# restore-pane-contents ensures each pane is restored with content intact --> copy session-id from statusline to restore
#
# alias oc="ai-tmux --agent opencode"
# alias cx="ai-tmux --agent codex"
# alias aic="ai-tmux -c"
# alias air="ai-tmux -s"
# alias aip="ai-tmux --pick"
#
# NOTE I now use Herdr as a multiplexer instead of tmux w/ custom agent persistence, Herdr does it better,
#      it's incredibly good software; fast, polished, capable, and oozes quality from the start.


# --- functions ---
# -- nvim config switcher --
function nvims() {
  items=("default" "kickstart" "LazyVim" "NvChad" "AstroNvim")
  config=$(printf "%s\n" "${items[@]}" | fzf --prompt=" Neovim Config  " --height=~50% --layout=reverse --border --exit-0)
  if [[ -z $config ]]; then
    echo "Nothing selected"
    return 0
  elif [[ $config == "default" ]]; then
    config=""
  fi
  NVIM_APPNAME=$config nvim $@
}

vv() {
  local config=$(fd --max-depth 1 --glob '{nvim*,LazyVim*}' ~/.config | fzf --prompt="Neovim Configs > " --height=~50% --layout=reverse --border --exit-0)
  [[ -z $config ]] && echo "No config selected" && return
  NVIM_APPNAME=$(basename $config) nvim $@
}

# -- add brewfile creation commands to brew --
# brew() {
#   if [[ $1 == brewfile || $1 == dump || $1 == sync ]]; then
#     shift
#     local current_dir="$PWD"
#     cd /Users/bassimshahidy/dotfiles/brew
#     command brew bundle dump --formula --cask --tap --mas --force "$@"
#     cd "$current_dir"
#   else
#     command brew "$@"
#   fi
# }

# -- brewfile creation function --
brewfile() {
  local current_dir="$PWD"
  cd ~/dotfiles/brew
  brew bundle dump --formula --cask --tap --mas --force "$@"
  cd "$current_dir"
}

# -- git commit browser with fzf --
gcb() {
  git log --graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
    fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
    --bind "ctrl-m:execute:
      (grep -o '[a-f0-9]\{7\}' | head -1 |
        xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
              {}
              FZF-EOF"
            }

# -- git diff browser with fzf --
gdb() {
  local preview
  preview="git diff $@ --color=always -- {}"
  git diff "$@" --name-only | \
    fzf -m --ansi --preview "$preview"
}

# -- clone and cd into a git repo --
gcl() {
  git clone "$1" && cd "$(basename "$1" .git)"
}

# -- create a new directory and cd into it --
mk() {
  mkdir -p "$1" && cd "$1"
}

# -- find and kill process by name --
fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
  if [ "x$pid" != "x" ]; then
    echo $pid | xargs kill -${1:-9}
  fi
}

# --- bun ---
export PATH="$PATH:$HOME/.cache/.bun/bin"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"


# --- pnpm ---
$darwin && export PNPM_HOME="$HOME/Library/pnpm" || export PNPM_HOME="$XDG_DATA_HOME/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

[[ -f ~/completion-for-pnpm.zsh ]] && source ~/completion-for-pnpm.zsh


# --- graphite completions ---
# yargs command completion script
#
# Installation: gt completion >> ~/.zshrc
#    or gt completion >> ~/.zprofile on OSX.
#
_gt_yargs_completions()
{
  local reply
  local si=$IFS
  IFS=$'
' reply=($(COMP_CWORD="$((CURRENT-1))" COMP_LINE="$BUFFER" COMP_POINT="$CURSOR" gt --get-yargs-completions "${words[@]}"))
  IFS=$si
  _describe 'values' reply
}
compdef _gt_yargs_completions gt


# --- misc ---
export EDITOR='nvim'
export VISUAL='nvim'

# -- fastfetch --
# fastfetch

# --- misc oh-my-zsh user configuration ---
# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Added by cargo-dist installers (uv): puts ~/.local/bin on PATH
[[ -r "$HOME/.local/share/../bin/env" ]] && . "$HOME/.local/share/../bin/env"

# Added by CodeRabbit CLI installer
export PATH="$HOME/.local/bin:$PATH"

# OpenClaw
$darwin && export OPENCLAW_IMAGE_BACKEND=sips
cached_eval openclaw openclaw completion --shell zsh
cached_eval but-completions but completions zsh

# Vite+ bin (https://viteplus.dev)
[[ -r "$HOME/.vite-plus/env" ]] && . "$HOME/.vite-plus/env"

# --- fnm ---
export PATH="$HOME/.local/share/fnm/aliases/default/bin:$PATH"
cached_eval fnm fnm env --use-on-cd --shell zsh
export PATH=$PATH:$HOME/.maestro/bin
