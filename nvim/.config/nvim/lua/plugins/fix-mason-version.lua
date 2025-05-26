-- Fix for Mason v2.0.0 breaking changes
-- This forces Lazy to use v1.x versions
return {
  {
    "williamboman/mason.nvim",
    version = "^1.0.0", -- This will use latest v1.x (currently v1.11.0)
  },
  {
    "williamboman/mason-lspconfig.nvim",
    version = "^1.0.0", -- This will use latest v1.x (currently v1.32.0)
  },
}
