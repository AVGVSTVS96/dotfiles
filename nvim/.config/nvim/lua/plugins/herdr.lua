local function in_herdr()
  return vim.env.HERDR_ENV == "1" or vim.env.HERDR_SOCKET_PATH ~= nil
end

return {
  {
    dir = "~/Documents/GitHub/side-projects/herdr-vim-navigator.nvim",
    name = "herdr-vim-navigator.nvim",
    cond = in_herdr,
    lazy = false,
    opts = {
      helper = "~/Documents/GitHub/side-projects/herdr-vim-navigator/bin/herdr-vim-navigator",
      keymaps = {
        left = { "<C-h>", "<C-Left>" },
        down = { "<C-j>", "<C-Down>" },
        up = { "<C-k>", "<C-Up>" },
        right = { "<C-l>", "<C-Right>" },
      },
    },
  },
}
