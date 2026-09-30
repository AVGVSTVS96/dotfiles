-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
local opt = vim.opt
local g = vim.g
local o = vim.o

opt.termguicolors = true

-- Neovide
if vim.g.neovide then
  g.neovide_transparency = 0.8
  g.neovide_normal_opacity = 0.8
  g.neovide_window_blurred = true
  o.guifont = "MonaspiceKr Nerd Font Propo:h14"
end

-- Wrapping and Indentation
opt.listchars = "eol:↲,tab:|->,lead:·,space: ,extends:→,precedes:←,nbsp:␣"
opt.breakindent = true
opt.linebreak = true

-- Disable swap files
opt.swapfile = false

-- LazyVim
g.snacks_animate = false
g.lazyvim_picker = "snacks"

-- MDX: LazyVim's markdown extra maps mdx to markdown.mdx, but only at
-- VeryLazy (too late for argv/session buffers), and mdx.nvim's after/plugin
-- remaps the extension to plain `mdx`. A pattern outranks extension maps, so
-- this wins regardless of load order.
vim.filetype.add({ pattern = { [".*%.mdx"] = "markdown.mdx" } })
vim.treesitter.language.register("markdown", "markdown.mdx")

-- Visual
o.winborder = "rounded"

-- MacOS
if jit.os == "OSX" then
  o.mousescroll = "ver:1"
end

-- Prefer nearest subproject first, then fall back to lsp -> monorepo git -> cwd
vim.g.root_spec = {
  { "package.json", "tsconfig.json", "biome.json", "eslint.config.*" },
  "lsp",
  ".git",
  "cwd",
}
