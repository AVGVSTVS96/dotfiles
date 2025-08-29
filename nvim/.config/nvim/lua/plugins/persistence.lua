return {
  "folke/persistence.nvim",
  event = "BufReadPre",
  config = function()
    local persistence = require("persistence")
    local base_dir = vim.fn.stdpath("state") .. "/sessions/"
    local session_dir = base_dir

    -- Check for tmux-specific directory
    if vim.env.TMUX then
      local handle = io.popen("tmux display-message -p '#S_#W'")
      if handle then
        local tmux_info = handle:read("*a"):gsub("\n", ""):gsub("[^%w%-_]", "_")
        handle:close()

        if tmux_info ~= "" then
          local tmux_dir = base_dir .. "tmux-" .. tmux_info .. "/"
          -- Use tmux dir if it exists and has sessions
          if vim.fn.isdirectory(tmux_dir) == 1 and #vim.fn.glob(tmux_dir .. "*.vim", false, true) > 0 then
            session_dir = tmux_dir
          end
        end
      end
    end

    persistence.setup({
      dir = session_dir,
    })
  end,
}
