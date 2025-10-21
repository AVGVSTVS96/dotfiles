# ----------------
# --- Check OS ---
# ----------------
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

# -----------
# --- NPM ---
# -----------
export PATH="./node_modules/.bin:$PATH"


# -----------------------
# --- VSCode Insiders ---
# -----------------------
export PATH="$PATH:/Applications/Visual Studio Code - Insiders.app/Contents/Resources/app/bin"


# -------------
# --- Cargo ---
# -------------
export PATH="$PATH:/Users/bassimshahidy/.cargo/bin"


# ----------------
# --- Homebrew ---
# ----------------
$darwin && eval "$(/opt/homebrew/bin/brew shellenv)"
$linux && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" && export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"

# Add brew's zsh completions to fpath
FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"


# -----------------
# --- oh-my-zsh ---
# -----------------
export ZSH="$HOME/.oh-my-zsh"

# -------------------
# --- zsh plugins ---
# -------------------
plugins=(git)

source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# load oh-my-zsh
source $ZSH/oh-my-zsh.sh


# ------------------
# --- oh-my-posh ---
# ------------------
eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/tokyonight_storm-customized.omp.json)"

# -----------
# --- bat ---
# -----------
#  Install theme:
#   curl -O https://raw.githubusercontent.com/folke/tokyonight.nvim/main/extras/sublime/tokyonight_night.tmTheme
#   bat cache --build
export BAT_THEME=tokyonight_night


# ---------------
# --- lazygit ---
# ---------------
export LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml"


# -----------
# --- NVM ---
# -----------
# export PATH=$HOME/.nvm/versions/node/v21.6.1/bin:$PATH

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


# -----------
#
# --- fzf ---
#
# -----------
eval "$(fzf --zsh)"

# ---------------------------
# -- Use fd instead of fzf --
# ---------------------------
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

# --------------------
# -- fzf-git script --
# --------------------
source ~/fzf-git.sh

# ------------------
# -- fzf previews --
# ------------------
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
# ---------------
# --- end fzf ---
# ---------------


# ---------------
# --- thefuck ---
# ---------------
eval $(thefuck --alias)


# --------------------------
# --- Zoxide (better cd) ---
# --------------------------
if [[ "$CLAUDECODE" != "1" ]]; then
    eval "$(zoxide init --cmd cd zsh)"
fi


# ---------------
#
# --- Aliases ---
#
# ---------------
# For a full list of active aliases, run `alias`.

# -- zsh aliases --
alias zrc="nvim ~/.zshrc"
alias szrc="source ~/.zshrc"
alias exz="exec zsh"
alias cl="clear"

# -- git aliases --
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
alias yolo-commit="git commit -m "$(curl -s https://whatthecommit.com/index.txt)""
alias update-last-commit="git commit -a --amend --no-edit && git push --force-with-lease origin"
alias prc="gh pr create"
alias devs='lsof -nP -iTCP -sTCP:LISTEN | grep -E "(node|next|astro|vite|webpack|parcel)" | awk "{split(\$9, addr, \":\"); port = addr[length(addr)]; process = \$1; printf \"\\033[1;36m%-6s\\033[0m \\033[1;33m%s\\033[0m\\n\", process, port}" | sort -k2 -n'
alias list-servers="devs"

unalias gcb
unalias gcl
# -- lazygit aliases --
alias lg="lazygit"

# -- yazi aliases --
alias yz="yazi"

# -- zoxide instead of cd --
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

# -------------------
# --- end aliases ---
# -------------------

# -----------------
# --- Functions ---
# -----------------
#
# ── nvim config switcher ──
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

# ── helper to add git aliases in the correct location ──
add_git_alias(){
  local name=$1 cmd=$2 file="$HOME/dotfiles/zsh/.zshrc"

  sd \
    '(# -- git aliases --\n(?:alias .+\n)+)' \
    "\${1}alias ${name}=\"${cmd}\"\n" \
    "$file"

  echo "✔️  Added git alias ${name}"
  source "$HOME/.zshrc" || true
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
  cd /Users/bassimshahidy/dotfiles/brew
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


# -----------
# --- bun ---
# -----------
# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"


# ------------
# --- pnpm ---
# ------------
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

source ~/completion-for-pnpm.zsh
# ----------------
# --- end pnpm ---
# ----------------


# ----------------------------
# --- graphite completions ---
#-----------------------------
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
#---------------------------------
# --- end graphite completions ---
# --------------------------------



# ------------
# --- misc ---
# ------------
export EDITOR='nvim'
export VISUAL='nvim'

# -- fastfetch --
# fastfetch

# -----------------------------------------
# --- misc oh-my-zsh user configuration ---
# -----------------------------------------
# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"


. "$HOME/.local/share/../bin/env"

# Added by CodeRabbit CLI installer
export PATH="/Users/bassimshahidy/.local/bin:$PATH"
export CLAUDE_BASH_NO_LOGIN=1
