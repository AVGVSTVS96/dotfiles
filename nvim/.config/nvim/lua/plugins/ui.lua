return {
  {
    -- Highlight colors with tailwind, oklch, and LSP support
    -- "eero-lehtinen/oklch-color-picker.nvim",
    -- event = "LazyFile",
    -- opts = {},
  },
  {
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
      on_highlights = function(hl, c)
        -- Make virtual lines visible with transparent background
        hl.DiagnosticVirtualLinesError = { fg = c.error }
        hl.DiagnosticVirtualLinesWarn = { fg = c.warning }
        hl.DiagnosticVirtualLinesInfo = { fg = c.info }
        hl.DiagnosticVirtualLinesHint = { fg = c.hint }
      end,
    },
  },
}
