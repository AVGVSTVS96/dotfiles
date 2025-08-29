-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set
local cmd = vim.cmd

-- Make some commands case insensitive
cmd("cabbrev W w")
cmd("cabbrev Q q")

-- Map Page Up and Down to behave like Ctrl-D and Ctrl-U
map("n", "<PageDown>", "<C-d>", { noremap = true, silent = true })
map("n", "<PageUp>", "<C-u>", { noremap = true, silent = true })

-- Map 'U' to redo
map("n", "U", ":redo<CR>", { noremap = true, silent = true })

-- Map <A-Up> and <A-Down> to move lines up and down
map("n", "<A-S-Down>", "<cmd>m .+1<cr>==", { desc = "Move Line Down" })
map("n", "<A-S-Up>", "<cmd>m .-2<cr>==", { desc = "Move Line Up" })
map("i", "<A-S-Down>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Line Down" })
map("i", "<A-S-Up>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Line Up" })
map("v", "<A-S-Down>", ":m '>+1<cr>gv=gv", { desc = "Move Line Down" })
map("v", "<A-S-Up>", ":m '<-2<cr>gv=gv", { desc = "Move Line Up" })

-- map <C-y> to yank to system register
map("n", "<C-y>", '"+y', { noremap = true, silent = true, desc = "Yank to system register" })
map("v", "<C-y>", '"+y', { noremap = true, silent = true, desc = "Yank to system register" })

-- Map bufferline tab picker
map("n", "<leader>bs", ":BufferLinePick<CR>", { silent = true, desc = "Quick Pick Buffers" })

-- Map Snacks buffers
map("n", "<leader>bt", function()
  Snacks.picker.buffers()
end, { silent = true, desc = "Browse Buffers" })

map("n", "<C-g>", "1<C-g>:let @+ = expand('%:p')<CR>", {
  noremap = true,
  silent = true,
  desc = "Show file info & copy abs path",
})

