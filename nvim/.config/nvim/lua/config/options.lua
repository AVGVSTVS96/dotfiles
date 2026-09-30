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
g.snacks_animate = true
g.lazyvim_picker = "snacks"

-- Only run prettier in projects that have a prettier config file
g.lazyvim_prettier_needs_config = true

-- MDX: LazyVim's markdown extra maps mdx to markdown.mdx, but only at
-- VeryLazy (too late for argv/session buffers), and mdx.nvim's after/plugin
-- remaps the extension to plain `mdx`. A pattern outranks extension maps, so
-- this wins regardless of load order.
vim.filetype.add({ pattern = { [".*%.mdx"] = "markdown.mdx" } })
vim.treesitter.language.register("markdown", "markdown.mdx")

-- Visual
o.winborder = "rounded"

-- Terminal title (herdr popup borders, tmux, kitty): cwd with ~ for home and
-- distant parents abbreviated, e.g. ~/D/GitHub/nvim
function _G.pretty_cwd()
  local parts = vim.split(vim.fn.fnamemodify(vim.fn.getcwd(), ":~"), "/")
  for i = 1, #parts - 2 do
    parts[i] = parts[i]:sub(1, 1)
  end
  return table.concat(parts, "/")
end
o.title = true
o.titlestring = "%{v:lua.pretty_cwd()}"

-- MacOS
if jit.os == "OSX" then
  o.mousescroll = "ver:3"
end

-- Prefer nearest subproject first, then fall back to lsp -> monorepo git -> cwd
vim.g.root_spec = {
  { "package.json", "tsconfig.json", "biome.json", "eslint.config.*" },
  "lsp",
  ".git",
  "cwd",
}
