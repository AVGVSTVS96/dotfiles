# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Codebase Overview

This is a LazyVim-based Neovim configuration that extends the base LazyVim setup with custom plugins and settings. The configuration uses Lazy.nvim as the plugin manager and follows LazyVim's modular structure.

## Commands

### Code Formatting
- **Format Lua files**: `stylua <file>` (uses 2-space indentation, 120 column width)
- **Check Lua formatting**: `stylua --check .`

### Plugin Management
- Install/update plugins: Open Neovim and run `:Lazy sync`
- Check plugin status: `:Lazy`
- Update plugin lock file: `:Lazy update` then commit `lazy-lock.json`

### Neovim Commands
- Reload configuration: `:source %` (in the current file) or restart Neovim
- Open dashboard: `:Dashboard`

## Architecture

### Configuration Structure
- **Entry point**: `init.lua` bootstraps the entire configuration
- **Core settings**: `lua/config/` contains all base configurations
  - `lazy.lua`: Plugin manager setup and LazyVim initialization
  - `options.lua`: Vim options, Neovide settings, and UI preferences
  - `keymaps.lua`: Custom key bindings
  - `autocmds.lua`: Auto commands (notably disables autoformat)
- **Plugin configurations**: `lua/plugins/` contains individual plugin specs
- **LazyVim extras**: Defined in `lazyvim.json` for language support and features

### Key Customizations
1. **Snacks.nvim as default picker** (replacing telescope) with smart file finding and preview scrolling
2. **Mason locked to v1.x** to avoid compatibility issues
3. **Autoformat disabled** globally via autocmd
4. **AI tools integrated**: Avante.nvim and Supermaven for coding assistance
5. **macOS-specific optimizations** for mouse scrolling and Neovide GUI
6. **Enhanced LSP diagnostics** with virtual lines and toggle functionality (`<leader>uv`)
7. **LazyVim extras enabled**: Prettier, Biome formatting, Snacks explorer, and multiple language support

### Plugin System
- Plugins are loaded from LazyVim's built-in specs and custom `lua/plugins/` directory
- Each plugin file returns a table with plugin specifications
- Use `enabled = false` to disable plugins
- Lock file (`lazy-lock.json`) ensures reproducible installations

## Development Guidelines

When modifying this configuration:
1. Follow the existing plugin spec pattern in `lua/plugins/`
2. Test changes by reloading Neovim before committing
3. Update `lazy-lock.json` when adding/updating plugins
4. Maintain the stylua formatting for Lua files
5. Consider macOS compatibility for any system-specific settings