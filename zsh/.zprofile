# macOS's /etc/zprofile runs path_helper, which moves the system's directories ahead of the turn
# shims .zshenv put first, so a login shell (Terminal, an agent's) would run xcodebuild without
# taking a turn. Put the shims back in front.
path=(~/.local/share/turn ${path:#$HOME/.local/share/turn})

# Added by Obsidian
export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"
