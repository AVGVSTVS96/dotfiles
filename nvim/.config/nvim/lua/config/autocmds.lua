-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
--   pattern = { "*" },
--   command = "silent! wall",
--   nested = true,
-- })

-- Disable autoformat for nix files
vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = { "nix" },
  callback = function()
    vim.b.autoformat = false
  end,
})

function OpenSnacksDashboard()
  vim.cmd("enew")
  require("snacks").dashboard()
end

-- Open the dashboard when running :Dashboard
vim.api.nvim_create_user_command("Dashboard", function()
  OpenSnacksDashboard()
end, {})
