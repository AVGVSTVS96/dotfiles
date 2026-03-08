-- Define nav keys once at module level
local nav_keys = {
  { "<c-h>", "Left" },
  { "<c-j>", "Down" },
  { "<c-k>", "Up" },
  { "<c-l>", "Right" },
  { "<M-Left>", "Left" },
  { "<M-Down>", "Down" },
  { "<M-Up>", "Up" },
  { "<M-Right>", "Right" },
}

return {
  "christoomey/vim-tmux-navigator",
  enabled = true,
  cmd = {
    "TmuxNavigateLeft",
    "TmuxNavigateDown",
    "TmuxNavigateUp",
    "TmuxNavigateRight",
    "TmuxNavigatePrevious",
    "TmuxNavigatorProcessList",
  },
  keys = function()
    local keys = { { "<c-\\>", "<cmd>TmuxNavigatePrevious<cr>" } }
    for _, k in ipairs(nav_keys) do
      table.insert(keys, { k[1], "<cmd>TmuxNavigate" .. k[2] .. "<cr>" })
    end
    return keys
  end,
  config = function()
    -- Handle floating windows (like Snacks explorer) which break vim-tmux-navigator
    -- wincmd from floating windows goes to parent, not spatially
    local function setup_floating_nav()
      if not vim.bo.filetype:match("^snacks_picker") then
        return
      end
      for _, k in ipairs(nav_keys) do
        vim.keymap.set("n", k[1], function()
          local win_config = vim.api.nvim_win_get_config(0)
          if win_config.relative ~= "" and vim.env.TMUX then
            -- Floating window: left goes to tmux, others go to parent window
            if k[2] == "Left" then
              vim.fn.system("tmux select-pane -L")
            else
              vim.cmd("wincmd " .. ({ Right = "l", Up = "k", Down = "j" })[k[2]])
            end
          else
            vim.cmd("TmuxNavigate" .. k[2])
          end
        end, { buffer = true, silent = true })
      end
    end

    -- Set up for snacks_picker on BufEnter (fires every time we enter buffer)
    vim.api.nvim_create_autocmd("BufEnter", {
      callback = setup_floating_nav,
    })
    -- Also set up immediately if we're already in a snacks_picker
    setup_floating_nav()

    -- Edge navigation + snacks picker focus fix
    vim.api.nvim_create_autocmd("FocusGained", {
      callback = function()
        if not vim.env.TMUX then
          return
        end

        vim.schedule(function()
          local result = vim.fn.system("tmux show-environment TMUX_NAV_ENTRY 2>/dev/null")
          local dir = result:match("TMUX_NAV_ENTRY=(%w)")

          if dir and vim.tbl_contains({ "h", "j", "k", "l" }, dir) then
            vim.fn.system("tmux set-environment -u TMUX_NAV_ENTRY")
            vim.cmd("999wincmd " .. dir)
          end

          -- Re-activate snacks picker if we landed on one (floating windows need WinEnter)
          if vim.bo.filetype:match("^snacks_picker") then
            vim.cmd("wincmd p | wincmd p")
          end
        end)
      end,
    })
  end,
}
