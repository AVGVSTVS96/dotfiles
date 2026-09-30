return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      -- Vite+ projects keep oxlint config in vite.config.ts, which the default
      -- root markers (.oxlintrc.json etc.) never match. Also attach on
      -- vite.config.ts, but only when a project-local oxlint bin exists (the
      -- vite-plus wrapper) so plain Vite projects don't get the global oxlint.
      oxlint = {
        root_dir = function(bufnr, on_dir)
          local fname = vim.api.nvim_buf_get_name(bufnr)
          local root = vim.fs.root(fname, { ".oxlintrc.json", ".oxlintrc.jsonc", "oxlint.config.ts" })
            or vim.fs.root(fname, function(name, path)
              return name == "vite.config.ts" and vim.fn.executable(path .. "/node_modules/.bin/oxlint") == 1
            end)
          if root then
            on_dir(root)
          end
        end,
      },
      cssls = {
        settings = {
          css = {
            lint = {
              unknownAtRules = "ignore",
            },
          },
        },
      },
    },
  },
}
