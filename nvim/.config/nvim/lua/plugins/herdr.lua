local function in_herdr()
  return vim.env.HERDR_ENV == "1" or vim.env.HERDR_SOCKET_PATH ~= nil
end

return {
  {
    "AVGVSTVS96/vim-herdr-navigator",
    dev = true,
    build = "./install.sh",
    cond = in_herdr,
    lazy = false,
    opts = {
      -- Helper is resolved from PATH (~/.local/bin/vim-herdr-navigator -> the
      -- Rust release build). Omitting `helper` uses the same default.
      keymaps = {
        left = { "<C-h>", "<C-Left>" },
        down = { "<C-j>", "<C-Down>" },
        up = { "<C-k>", "<C-Up>" },
        right = { "<C-l>", "<C-Right>" },
      },
    },
  },
}
