local wide_vertical = {
  layout = {
    preset = "vertical",
    layout = {
      width = 0.85,
      min_width = 120,
      height = 0.85,
      box = "vertical",
      border = "rounded",
      title = "{title} {live} {flags}",
      title_pos = "center",
      { win = "preview", title = "{preview}", height = 0.5, border = "bottom" },
      { win = "input", height = 1, border = "bottom" },
      { win = "list", border = "none" },
    },
  },
}

return {
  "folke/snacks.nvim",
  keys = {
    {
      "<leader><space>",
      LazyVim.pick("files", { root = true }),
      desc = "Find Files (Root Dir)",
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
        files = {
          hidden = true,
          ignored = false,
          frecency = true,
          history_bonus = true,
          cwd_bonus = true,
        },
        grep = {
          hidden = true,
          ignored = false,
        },
        grep_word = {
          hidden = true,
          ignored = false,
        },
        grep_buffers = {
          hidden = true,
          ignored = false,
        },
        explorer = {
          hidden = true,
          ignored = true,
          layout = {
            layout = {
              width = 30,
            },
          },
        },
        git_diff = wide_vertical,
        git_log = wide_vertical,
        git_log_file = wide_vertical,
        git_log_line = wide_vertical,
        git_status = wide_vertical,
        git_stash = wide_vertical,
        undo = wide_vertical,
      },
      matcher = {
        frecency = true,
        hidden = true,
        ignored = true,
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
