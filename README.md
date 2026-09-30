## dotfiles with stow

Dotfiles are stored and managed within this repo using GNU Stow. The directory is structured such that each packages config lives in it's own directory in the repo. They are then stowed as packages, so the contents in the root of each package directory in dotfiles gets symlinked to root of the home directory. 

Config files in the `.config/` directory are stowed in dotfiles with a `.config/` directory at the root of the package in dotfiles, e.g. `nvim/.config/nvim`.


### Installation

```zsh
cd ~
gh repo clone AVGVSTVS96/dotfiles
cd dotfiles
./install
```

`./install` stows the shared packages plus the ones for the current OS; both lists live in the script. Stow flags pass through: `./install -nv` previews, `-R` restows after adding files, `-D` unlinks. Stow won't replace files that already exist, so move those aside and rerun.

Secrets need the existing age key at `~/.config/sops/age/key.txt` (Proton Pass item `SOPS / dotfiles — age key`, or `find-age-key` on a Mac). Then `restore-secrets` restores the SSH key, the GitHub CLI token and the Graphite config; see [docs/secrets.md](docs/secrets.md).

#### macOS

```zsh
brew bundle --file brew/Brewfile
./install
```

#### Arch / CachyOS

```zsh
sudo pacman -S --needed - < arch/pacman.txt
paru -S --needed - < arch/aur.txt
./install
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
fnm install --lts && fnm default lts-latest
rustup default stable && rustup component add rust-analyzer
chsh -s /usr/bin/zsh
```

Claude Code, Codex and herdr use their own self-updating installers (they live in `~/.local/bin`), and oh-my-zsh updates itself. The first `nvim` launch installs plugins, including the `vim-herdr-navigator` helper; `herdr plugin install AVGVSTVS96/herdr-drovr` adds drovr.
