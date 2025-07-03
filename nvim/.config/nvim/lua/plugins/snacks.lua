return {
  "folke/snacks.nvim",
  keys = {
    {
      "<leader><space>",
      function()
        Snacks.picker.smart()
      end,
      desc = "Smart Find Files",
    },
  },
  opts = {
    zen = {
      toggles = {
        dim = false,
      },
    },
    picker = {
      sources = {
        explorer = {
          hidden = true,
          ignored = true,
          layout = {
            layout = {
              width = 30,
            },
          },
        },
      },
      matcher = {
        frecency = true,
        history_bonus = true,
        cwd_bonus = true,
      },
      formatters = {
        file = {
          truncate = 80,
          filename_first = true,
        },
      },
      win = {
        input = {
          keys = {
            ["<PageUp>"] = { "preview_scroll_up", mode = { "n", "i" } },
            ["<PageDown>"] = { "preview_scroll_down", mode = { "n", "i" } },
          },
        },
        list = {
          keys = {
            ["<PageUp>"] = { "preview_scroll_up", mode = { "n", "i" } },
            ["<PageDown>"] = { "preview_scroll_down", mode = { "n", "i" } },
          },
        },
      },
    },
  },
}
