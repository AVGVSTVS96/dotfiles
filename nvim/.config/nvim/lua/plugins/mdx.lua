-- MDX support, keyed to LazyVim's `markdown.mdx` filetype convention.
-- Filetype + treesitter language registration live in config/options.lua so
-- they apply before any buffer loads.

-- Workaround for nvim 0.12 + mdx-analyzer:
-- mdx-analyzer registers a watcher with the glob `**/*.{mdx}`, which nvim's
-- glob parser rejects (single-element brace expansion). Wrap to_lpeg so a
-- malformed glob no-ops instead of crashing the server.
do
  local ok, glob = pcall(require, "vim.glob")
  if ok and glob and glob.to_lpeg then
    local orig = glob.to_lpeg
    glob.to_lpeg = function(pattern)
      local success, result = pcall(orig, pattern)
      if success then
        return result
      end
      local cleaned = pattern:gsub("{([^,{}]+)}", "%1")
      local ok2, result2 = pcall(orig, cleaned)
      if ok2 then
        return result2
      end
      return orig("__never_match_glob__")
    end
  end
end

return {
  -- Treesitter query extensions (JSX/ESM injections) for MDX on top of the
  -- markdown parser. The plugin's own `mdx` filetype registration is outranked
  -- by the markdown.mdx pattern in config/options.lua.
  {
    "davidmh/mdx.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "markdown", "markdown_inline", "tsx" })
    end,
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- mdx-analyzer with embedded TypeScript support (via workspace tsdk)
        mdx_analyzer = {
          filetypes = { "markdown.mdx", "mdx" },
          init_options = {
            typescript = {
              enabled = true,
            },
          },
        },
        -- Tailwind class completion inside MDX
        tailwindcss = {
          filetypes_include = { "markdown.mdx" },
          settings = {
            tailwindCSS = {
              includeLanguages = {
                ["markdown.mdx"] = "html",
              },
            },
          },
        },
      },
    },
  },

  -- Format MDX with oxfmt (resolves to the project-local vite-plus wrapper,
  -- so it uses the fmt block in vite.config.ts). Appended last so it has the
  -- final say after prettier in projects where both apply.
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      local mdx = opts.formatters_by_ft["markdown.mdx"] or {}
      table.insert(mdx, "oxfmt")
      opts.formatters_by_ft["markdown.mdx"] = mdx
    end,
  },
}
