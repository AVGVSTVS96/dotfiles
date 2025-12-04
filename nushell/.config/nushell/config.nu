# config.nu
#
# Installed by:
# version = "0.109.0"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# Nushell sets "sensible defaults" for most configuration settings,
# so your `config.nu` only needs to override these defaults if desired.
#
# You can open this file in your default editor using:
#     config nu
#
# You can also pretty-print and page through the documentation for configuration
# options using:
#     config nu --doc | nu-highlight | less -R

# ==================
# === Oh-My-Posh ===
# ==================
# Generate and source oh-my-posh config (per official docs)
oh-my-posh init nu --config ~/.config/oh-my-posh/tokyonight_storm-customized.omp.json

# ==============
# === Zoxide ===
# ==============
# Auto-loaded from ~/.local/share/nushell/autoload/zoxide.nu
# Regenerate with: zoxide init nushell | save -f ~/.local/share/nushell/autoload/zoxide.nu

# ======================
# === Shell Aliases ===
# ======================
alias cl = clear
alias nrc = nvim ~/.config/nushell/config.nu
alias nenv = nvim ~/.config/nushell/env.nu
# Note: Can't alias 'source' - use `source ~/.config/nushell/config.nu` directly
# or restart nushell with `exec nu`

# ===================
# === Git Aliases ===
# ===================
alias g = git
alias ga = git add -A
alias gs = git status
alias gss = git status -s
alias gsm = git switch main
alias gc = git commit
alias gca = git commit -a
alias gcam = git commit -a --amend --no-edit
alias gf = git fetch
alias gpl = git pull
alias gp = git push
alias gpf = git push --force-with-lease origin
alias gd = git diff
alias prc = gh pr create

# ====================
# === Tool Aliases ===
# ====================
alias lg = lazygit
alias yz = yazi

# =========================
# === eza (ls) Aliases ===
# =========================
# Commented out to use nushell's native ls
# Uncomment if you prefer eza

# # Short listing (no permissions, size, time)
# def l [...args] { ^eza --git --icons=always --color=always --long --no-user --no-permissions --no-filesize --no-time ...$args }
# def la [...args] { ^eza --git --icons=always --color=always --long --no-user --no-permissions --no-filesize --no-time --all ...$args }
# alias ls = l
# alias lsa = la

# # Long listing (with permissions, size, time)
# def lsl [...args] { ^eza --git --icons=always --color=always --long ...$args }
# def ll [...args] { ^eza --git --icons=always --color=always --long --all ...$args }

# # Tree listings
# def lt [...args] { ^eza --git --icons=always --color=always --long --all --tree --level=2 ...$args }
# def lt2 [...args] { ^eza --git --icons=always --color=always --long --all --tree --level=3 ...$args }
# def lt3 [...args] { ^eza --git --icons=always --color=always --long --all --tree --level=4 ...$args }
# def ltg [...args] { ^eza --git --icons=always --color=always --long --tree --git-ignore ...$args }

# =======================
# === Custom Commands ===
# =======================
# Clone and cd into a git repo
def --env gcl [repo: string] {
    git clone $repo
    let dir = ($repo | path basename | str replace ".git" "")
    cd $dir
}

# Create directory and cd into it
def --env mk [dir: string] {
    mkdir $dir
    cd $dir
}
