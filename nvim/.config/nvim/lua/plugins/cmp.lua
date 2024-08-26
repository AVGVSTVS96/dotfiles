return {
  "hrsh7th/nvim-cmp",
  dependencies = {
    "supermaven-inc/supermaven-nvim",
  },
  opts = function(_, opts)
    -- Check if opts.sources exists, if not, initialize it as an empty table
    opts.sources = opts.sources or {}
    -- Add supermaven as a source for nvim-cmp
    table.insert(opts.sources, { name = "supermaven" })
  end,
}
