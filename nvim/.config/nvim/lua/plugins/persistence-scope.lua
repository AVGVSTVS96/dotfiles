return {
  {
    "AVGVSTVS96/persistence-scope.nvim",
    dev = true,
    version = "*",
    dependencies = {
      "folke/persistence.nvim",
      "folke/snacks.nvim",
    },
    lazy = false,
    opts = {
      provider = "tmux_window_name",
      picker = "auto",
      branch = true,
    },
  },
}
