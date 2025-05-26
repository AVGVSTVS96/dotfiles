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

-- LazyVim
g.snacks_animate = true
g.lazyvim_picker = "snacks"

-- MacOS
if jit.os == "OSX" then
  o.mousescroll = "ver:1"
end
