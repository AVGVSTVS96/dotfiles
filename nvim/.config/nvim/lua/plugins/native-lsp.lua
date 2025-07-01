return {
  -- Configure diagnostics to use virtual lines
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- Disable LazyVim's virtual text to avoid duplication
      if opts.diagnostics then
        opts.diagnostics.virtual_text = false
      end

      -- Enable virtual lines and configure diagnostics
      vim.diagnostic.config({
        virtual_lines = true,
        virtual_text = false,

        -- Other diagnostic improvements
        severity_sort = true,
        float = {
          source = "if_many",
          border = "rounded",
        },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "󰅙",
            [vim.diagnostic.severity.WARN] = "󰀦",
            [vim.diagnostic.severity.INFO] = "󰋼",
            [vim.diagnostic.severity.HINT] = "󰌵",
          },
        },
      })

      return opts
    end,
  },

  -- Add diagnostic toggle functionality
  {
    "neovim/nvim-lspconfig",
    keys = {
      {
        "<leader>uv",
        function()
          local config = vim.diagnostic.config() or {}
          if config.virtual_lines then
            vim.diagnostic.config({
              virtual_lines = false,
              virtual_text = {
                spacing = 4,
                source = "if_many",
                prefix = "●",
              },
            })
            vim.notify("Switched to compact diagnostics", vim.log.levels.INFO)
          else
            vim.diagnostic.config({
              virtual_lines = true,
              virtual_text = false,
            })
            vim.notify("Switched to visual lines", vim.log.levels.INFO)
          end
        end,
        desc = "Toggle Virtual Lines/Compact Mode",
      },
    },
  },
}
