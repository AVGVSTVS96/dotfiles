# Tmux/Neovim Session Management

This setup enables working on multiple tasks within the same repository simultaneously while maintaining separate Neovim session state for each tmux window.

## How it works

- Each tmux session/window combination has its own isolated Neovim session
- Neovim sessions are automatically saved and restored based on the current tmux context
- **Git branch aware**: persistence.nvim saves sessions per tmux context AND git branch
- Allows context-switching between different features/tasks without losing editor state
- Sessions are stored in `~/.local/state/nvim/sessions/tmux-{session}_{window}/`

## Workflow

Open multiple tmux windows or sessions for the same repo, each maintaining independent:
- Buffer state
- Window layouts
- Cursor positions
- Undo history

Switch between tasks using tmux window/session navigation - Neovim state persists automatically for each context.

## TODO

- [ ] PR persistence.nvim to add fallback option: use sessions from other branches when no session exists for current branch
