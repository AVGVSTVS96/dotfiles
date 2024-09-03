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

# -----------
# --- NPM ---
# -----------
export PATH="./node_modules/.bin:$PATH"


# -----------------------
# --- VSCode Insiders ---
# -----------------------
export PATH="$PATH:/Applications/Visual Studio Code - Insiders.app/Contents/Resources/app/bin"


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
# eval "$(oh-my-posh init zsh --config ~/Documents/GitHub/dotfiles/Mac/jblab_2021.omp.json)"
eval "$(oh-my-posh init zsh --config $(brew --prefix oh-my-posh)/themes/tokyonight_storm.omp.json)"


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
eval "$(zoxide init zsh)"


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
alias g="git"
alias gs="git status"
alias gss="git status -s"
alias gc="git commit"
alias gca="git commit -a"
alias gcam="git commit -a --amend --no-edit"
alias gf="git fetch"
alias gpl="git pull"
alias gp="git push"
alias gpf="git push --force-with-lease origin"

alias conv-commit="zsh ~/commit.sh"
alias yolo-commit="git commit -m "$(curl -s https://whatthecommit.com/index.txt)""
alias update-last-commit="git commit -a --amend --no-edit && git push --force-with-lease origin"

# -- lazygit aliases --
alias lg="lazygit"

# -- yazi aliases --
alias yz="yazi"

# -- zoxide instead of cd --
alias cd="z"

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
export VISUAL='code'


# -----------------------------------------
#
# --- misc oh-my-zsh user configuration ---
#
# -----------------------------------------
# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# ZSH_CUSTOM=/path/to/new-custom-folder

