## dotfiles with stow

Dotfiles are stored and managed within this repo using GNU Stow. The directory is structured such that each packages config lives in it's own directory in the repo. They are then stowed as packages, so the contents in the root of each package directory in dotfiles gets symlinked to root of the home directory. 

Config files in the `.config/` directory are stowed in dotfiles with a `.config/` directory at the root of the package in dotfiles, e.g. `nvim/.config/nvim`.


### Installation

```zsh
git clone https://github.com/AVGVSTVS96/dotfiles ~/dotfiles
~/dotfiles/bootstrap
```

`bootstrap` sets up a Mac or an Arch/CachyOS machine and is safe to rerun: anything already installed is detected and skipped.

- Packages: `brew bundle` on macOS. On Arch, when something in `arch/pacman.txt` is missing, one synchronized full upgrade that installs it (`pacman -Syu --needed`); missing `arch/aur.txt` packages go through paru.
- On Linux, Claude Code, Codex, herdr and T3 Code come from their own self-updating installers, only when they aren't already on PATH.
- Linking. On Linux, a file already at a link's path is backed up to `~/.local/state/dotfiles/backups/` first; if it's still the distro's `/etc/skel` default the repo version replaces it, otherwise it's adopted into the repo and left for review in `git diff`.
- oh-my-zsh where zsh is the login shell, fnm's default Node, rustup's stable toolchain with rust-analyzer, Neovim plugins with the `vim-herdr-navigator` helper, and herdr's drovr plugin.
- `restore-secrets`, once the existing age key is at `~/.config/sops/age/key.txt` (Proton Pass item `SOPS / dotfiles — age key`, or `find-age-key` on a Mac). It restores the SSH key, the GitHub CLI token and the Graphite config and never overwrites them; see [docs/secrets.md](docs/secrets.md).

`./install` alone links the shared packages plus the current OS's; both lists live in the script. Stow flags pass through: `./install -nv` previews, `-R` restows after adding files, `-D` unlinks. Stow won't replace files that already exist, so move those aside and rerun. On Linux, `~/.ssh/authorized_keys` is never linked; each machine keeps its own. Each machine keeps its own login shell: zsh on the Mac with `~/.zshrc`, fish on Linux with `fish/.config/fish`, a port of `~/.zshrc` to keep in step with it. The macOS and Linux lists also differ where the machines do: Ghostty keeps its own look on each, and `niri`, `noctalia` and `wallpapers` are the Linux desktop.
