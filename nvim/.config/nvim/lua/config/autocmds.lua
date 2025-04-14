-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
--   pattern = { "*" },
--   callback = function()
--     if vim.bo.filetype ~= "lua" then
--       vim.cmd("silent! wall")
--     end
--   end,
--   nested = true,
-- })

-- Disable autoformat for all files
-- vim.api.nvim_create_autocmd({ "FileType" }, {
--   pattern = { "*" },
--   callback = function()
--     vim.b.autoformat = false
--   end,
-- })

-- Create command to open dashboard
vim.api.nvim_create_user_command("Dashboard", function()
  vim.cmd("enew")
  require("snacks").dashboard()
end, {})
