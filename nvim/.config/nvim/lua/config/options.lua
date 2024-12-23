-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
local opt = vim.opt
local g = vim.g
local o = vim.o

opt.listchars = "eol:↲,tab:|->,lead:·,space: ,extends:→,precedes:←,nbsp:␣"
opt.breakindent = true
opt.linebreak = true

g.snacks_animate = false

-- MacOS specific options
if jit.os == "OSX" then
  o.mousescroll = "ver:1"
end
