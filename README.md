## dotfiles with stow

Dotfiles are stored and managed within this repo using GNU Stow. The directory is structured such that each packages config lives in it's own directory in the repo. They are then stowed as packages, so the contents in the root of each package directory in dotfiles gets symlinked to root of the home directory. 

Config files in the `.config/` directory are stowed in dotfiles with a `.config/` directory at the root of the package in dotfiles, e.g. `nvim/.config/nvim`.


### Installation

```zsh
git clone https://github.com/AVGVSTVS96/dotfiles ~/dotfiles
~/dotfiles/bootstrap
```

`bootstrap` sets up a Mac or an Arch/CachyOS machine and is safe to rerun: anything already installed is skipped.

1. Packages: `brew/Brewfile` on macOS; `arch/pacman.txt` and `arch/aur.txt` on Arch, plus the self-updating installers of Claude Code, Codex, herdr, T3 Code and the Proton Pass CLI.
2. `./install` links the packages. Files already in the way are moved to `~/.local/state/dotfiles/backups/` first.
3. oh-my-zsh where zsh is the login shell, fnm's Node, the Graphite CLI, Rust's stable toolchain, Neovim plugins and herdr's drovr plugin.
4. `./install-agents` brings Claude Code and Codex in line with `agent-preferences/`; see [docs/agent-config.md](docs/agent-config.md).
5. Once the age key is at `~/.config/sops/age/key.txt` (Proton Pass item `SOPS / dotfiles — age key`, or `find-age-key` on a Mac): `restore-secrets` (see [docs/secrets.md](docs/secrets.md)) and the [fleet](https://github.com/AVGVSTVS96/fleet) repo with its machines skill.

`./install` stows the shared packages plus the current OS's; both lists live in the script, and stow flags pass through: `-nv` previews, `-R` restows, `-D` unlinks.

Each machine keeps its own login shell: zsh on the Mac, fish on Linux, where `fish/` is a port of `~/.zshrc` to keep in step with it. On Linux zsh only gets `.zshenv`, for agents' shell commands, and `~/.ssh/authorized_keys` stays each machine's own. Ghostty has its own look on each OS (`ghostty`, `ghostty-linux`), and `niri`, `noctalia` and `wallpapers` are the Linux desktop.
