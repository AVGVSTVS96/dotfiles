return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options.component_separators = "|"
      opts.options.section_separators = { left = "", right = "" }

      local colors = require("tokyonight.colors").setup()
      local tokyonight_custom = require("lualine.themes.tokyonight")

      -- Change section b (branch and time blocks) colors
      tokyonight_custom.normal.b.bg = colors.bg_dark1
      tokyonight_custom.insert.b.bg = colors.bg_dark1
      tokyonight_custom.visual.b.bg = colors.bg_dark1
      tokyonight_custom.replace.b.bg = colors.bg_dark1
      tokyonight_custom.command.b.bg = colors.bg_dark1

      opts.options.theme = tokyonight_custom

      return opts
    end,
  },
}
