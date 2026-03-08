-- Custom persistence logic based on tmux pane/window context
--
-- Sessions are keyed with tmux context allowing restoration of multiple
--   sessions with the same CWD based on the tmux pane/window
--
-- Fallback Rules:
--   Restore latest session for current TMUX pane if exists, else:
--   Restore latest session for current TMUX window if exists, else:
--   Restore latest session for CWD
--
-- Architecture:
-- 

return {
  "folke/persistence.nvim",
  event = "BufReadPre",
  config = function()
    local persistence = require("persistence")
    local uv = vim.uv or vim.loop
    local base_dir = vim.fn.stdpath("state") .. "/sessions/"
    local session_dir = base_dir
    local function sanitize(value)
      return value:gsub("[^%w%-_]", "_")
    end

    local function tmux_display(format)
      local cmd = "tmux display-message -p"
      if vim.env.TMUX_PANE and vim.env.TMUX_PANE ~= "" then
        cmd = cmd .. " -t " .. vim.fn.shellescape(vim.env.TMUX_PANE)
      end
      local value = vim.fn.systemlist(cmd .. " '" .. format .. "'")[1]
      if vim.v.shell_error ~= 0 or not value or value == "" then
        return nil
      end
      return value
    end

    local function tmux_context()
      if not vim.env.TMUX then
        return nil
      end

      local session = tmux_display("#{session_name}")
      local window_id = tmux_display("#{window_id}")
      local pane_id = tmux_display("#{pane_id}")
      if not session or not window_id or not pane_id then
        return nil
      end

      return {
        session = sanitize(session),
        window_id = sanitize(window_id),
        pane_id = sanitize(pane_id),
        window_index = sanitize(tmux_display("#{window_index}") or ""),
        pane_index = sanitize(tmux_display("#{pane_index}") or ""),
      }
    end

    local function file_buffer_count()
      local n = 0
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= "" then
          n = n + 1
        end
      end
      return n
    end

    local function newest_files(files)
      table.sort(files, function(a, b)
        local sa = uv.fs_stat(a)
        local sb = uv.fs_stat(b)
        if not sa then
          return false
        end
        if not sb then
          return true
        end
        if sa.mtime.sec == sb.mtime.sec then
          return (sa.mtime.nsec or 0) > (sb.mtime.nsec or 0)
        end
        return sa.mtime.sec > sb.mtime.sec
      end)

      return files[1]
    end

    local function newest_globs(patterns)
      local files = {}
      local seen = {}
      for _, pattern in ipairs(patterns) do
        for _, file in ipairs(vim.fn.glob(pattern, false, true)) do
          if not seen[file] and vim.fn.filereadable(file) == 1 then
            seen[file] = true
            files[#files + 1] = file
          end
        end
      end
      return newest_files(files)
    end

    local function load_file(file)
      if not file then
        return false
      end
      local before_cwd = vim.fn.getcwd()
      local before_count = file_buffer_count()
      local before_buf = vim.api.nvim_buf_get_name(0)
      persistence.fire("LoadPre")
      pcall(vim.cmd, "silent! source " .. vim.fn.fnameescape(file))
      persistence.fire("LoadPost")
      local after_count = file_buffer_count()
      local after_buf = vim.api.nvim_buf_get_name(0)
      return after_count > before_count or vim.fn.getcwd() ~= before_cwd or (after_buf ~= "" and after_buf ~= before_buf)
    end

    local function latest_for_dir(dir)
      local key = dir:gsub("[\\/:]+", "%%")
      local files = {}
      local seen = {}
      for _, pattern in ipairs({ base_dir .. "*.vim", base_dir .. "**/*.vim" }) do
        for _, file in ipairs(vim.fn.glob(pattern, false, true)) do
          if not seen[file] and vim.fn.filereadable(file) == 1 then
            seen[file] = true
            local name = vim.fn.fnamemodify(file, ":t")
            if name == key .. ".vim" or name:sub(1, #key + 1) == key .. "%" then
              files[#files + 1] = file
            end
          end
        end
      end
      return newest_files(files)
    end

    local tmux = tmux_context()
    if tmux then
      session_dir = base_dir .. "tmux-" .. tmux.session .. "_" .. tmux.window_id .. "_" .. tmux.pane_id .. "/"
    end

    persistence.setup({ dir = session_dir })

    function persistence.load_tmux_fallback()
      local ctx = tmux_context()

      if ctx then
        local pane_file = newest_globs({
          base_dir .. "tmux-" .. ctx.session .. "_" .. ctx.window_id .. "_" .. ctx.pane_id .. "/*.vim",
          base_dir .. "tmux-" .. ctx.session .. "_" .. ctx.window_index .. "_" .. ctx.pane_index .. "/*.vim",
        })
        if load_file(pane_file) then
          return
        end

        local window_file = newest_globs({
          base_dir .. "tmux-" .. ctx.session .. "_" .. ctx.window_id .. "_*/*.vim",
          base_dir .. "tmux-" .. ctx.session .. "_" .. ctx.window_index .. "_*/*.vim",
        })
        if load_file(window_file) then
          return
        end
      end

      if load_file(latest_for_dir(vim.fn.getcwd())) then
        return
      end

      vim.notify("No saved session found for this pane, window, or cwd", vim.log.levels.INFO)
    end
  end,
}
