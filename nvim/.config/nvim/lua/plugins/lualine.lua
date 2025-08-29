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

      -- Get LazyVim utils
      local LazyVim = require("lazyvim.util")
      local icons = require("lazyvim.config").icons

      -- Move root_dir to section b to prevent truncation
      opts.sections.lualine_b = {
        {
          "branch",
          fmt = function(name)
            if name == "gitbutler/workspace" then
              return "gitbutler"
            end
            return name
          end,
          color = function()
            if vim.b.gitsigns_head == "gitbutler/workspace" then
              return { fg = colors.green }
            end
            return nil
          end,
        },
        LazyVim.lualine.root_dir(),
      }

      -- Override section c without root_dir
      opts.sections.lualine_c = {
        {
          "diagnostics",
          symbols = {
            error = icons.diagnostics.Error,
            warn = icons.diagnostics.Warn,
            info = icons.diagnostics.Info,
            hint = icons.diagnostics.Hint,
          },
        },
        { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
        { LazyVim.lualine.pretty_path() },
      }

      return opts
    end,
  },
}
