return {
  -- Override markdown extra to remove markdownlint-cli2
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      -- Remove markdownlint-cli2 from Mason auto-install
      opts.ensure_installed = opts.ensure_installed or {}
      opts.ensure_installed = vim.tbl_filter(function(tool)
        return tool ~= "markdownlint-cli2"
      end, opts.ensure_installed)
      return opts
    end,
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        -- Remove markdownlint-cli2 by setting empty linter list for markdown
        markdown = {},
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      -- Keep other formatters but remove markdownlint-cli2
      local function remove_markdownlint(formatters)
        if not formatters then
          return {}
        end
        return vim.tbl_filter(function(f)
          return f ~= "markdownlint-cli2"
        end, formatters)
      end
      opts.formatters_by_ft.markdown = remove_markdownlint(opts.formatters_by_ft.markdown)
      opts.formatters_by_ft["markdown.mdx"] = remove_markdownlint(opts.formatters_by_ft["markdown.mdx"])
      return opts
    end,
  },
}

