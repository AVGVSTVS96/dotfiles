return {
  "folke/tokyonight.nvim",
  opts = {
    transparent = not vim.g.neovide,
    styles = {
      sidebars = "transparent",
      floats = "transparent",
    },
    on_colors = function(colors)
      colors.border = "#565f89"
    end,
  },
}
