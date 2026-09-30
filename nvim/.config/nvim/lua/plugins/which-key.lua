return {
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        {
          mode = { "n", "v" },
          { "<leader>a", group = "avante", icon = { icon = "󱙺", color = "green" } },
          { "<leader>n", desc = "Notification History", icon = { icon = "󰈸", color = "orange" } },
        },
      },
    },
  },
}
