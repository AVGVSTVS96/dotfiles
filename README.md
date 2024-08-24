## dotfiles with stow

Dotfiles are stored and managed within this repo using GNU Stow. The directory is structured such that each packages config lives in it's own directory in the repo. They are then stowed as packages, so the contents in the root of each package directory in dotfiles gets symlinked to root of the home directory. 

Config files in the `.config/` directory are stowed in dotfiles with a `.config/` directory at the root of the package in dotfiles, e.g. `nvim/.config/nvim`.


### Installation

```zsh
cd ~
gh repo clone AVGVSTVS96/dotfiles
cd dotfiles
stow */
```

When running `stow */`, each package's contents are symlinked to the root of the home directory.
