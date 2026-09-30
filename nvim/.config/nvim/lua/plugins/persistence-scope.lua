return {
  {
    "AVGVSTVS96/persistence-scope.nvim",
    -- Local dev: use the working copy. Drop `dir` (and restore `version`) to switch back to GitHub.
    dir = "/Users/bassimshahidy/Documents/GitHub/side-projects/persistence-scope.nvim",
    -- version = "*",
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
