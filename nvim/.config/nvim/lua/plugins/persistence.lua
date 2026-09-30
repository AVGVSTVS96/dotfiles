-- Disabled while testing persistence-scope.nvim.
-- Original config is preserved below for easy rollback.
return {}

--[[
-- Custom persistence logic keyed by tmux window name.
--
-- Bassim often keeps several Neovim sessions in the same repo, separated by
-- named tmux windows. The window name is the stable identity; pane ids are not.

return {
  "folke/persistence.nvim",
  event = "BufReadPre",
  config = function()
    local persistence = require("persistence")
    local uv = vim.uv or vim.loop
    local base_dir = vim.fn.stdpath("state") .. "/sessions/"
    local recent_window_seconds = 4 * 60 * 60

    local function trim(value)
      return (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
    end

    local function sanitize(value)
      value = trim(value)
      value = value:gsub("[/\\:]", "_")
      value = value:gsub("%s+", "_")
      value = value:gsub("[^%w%._-]", "_")
      value = value:gsub("_+", "_")
      return value ~= "" and value or "window"
    end

    local function normalize_path(path)
      if not path or path == "" then
        return nil
      end

      path = trim(path)
      if vim.fs and vim.fs.normalize then
        local ok, normalized = pcall(vim.fs.normalize, path)
        if ok and normalized and normalized ~= "" then
          path = normalized
        end
      end

      local full = vim.fn.fnamemodify(path, ":p")
      full = full:gsub("[/\\]+$", "")
      if full == "" and path:match("^[/\\]") then
        return path:sub(1, 1)
      end
      return full
    end

    local function shell_unescape(value)
      return trim(value):gsub("\\(.)", "%1")
    end

    local function tmux_display(format)
      if not vim.env.TMUX then
        return nil
      end

      local cmd = { "tmux", "display-message", "-p" }
      if vim.env.TMUX_PANE and vim.env.TMUX_PANE ~= "" then
        vim.list_extend(cmd, { "-t", vim.env.TMUX_PANE })
      end
      cmd[#cmd + 1] = format

      local ok, lines = pcall(vim.fn.systemlist, cmd)
      if not ok or vim.v.shell_error ~= 0 or not lines or not lines[1] or lines[1] == "" then
        return nil
      end
      return lines[1]
    end

    local function tmux_context()
      local window_name = tmux_display("#{window_name}")
      if not window_name then
        return nil
      end

      return {
        raw_window_name = window_name,
        window_name = sanitize(window_name),
      }
    end

    local function newest(items)
      table.sort(items, function(a, b)
        if a.mtime == b.mtime then
          return a.session < b.session
        end
        return a.mtime > b.mtime
      end)
      return items[1]
    end

    local function count_recent(items)
      local now = os.time()
      local count = 0
      for _, item in ipairs(items) do
        if now - item.mtime <= recent_window_seconds then
          count = count + 1
        end
      end
      return count
    end

    local function reltime(ts)
      local seconds = math.max(0, os.time() - ts)
      if seconds < 60 then
        return "now"
      elseif seconds < 3600 then
        return ("%dm"):format(math.floor(seconds / 60))
      elseif seconds < 86400 then
        return ("%dh"):format(math.floor(seconds / 3600))
      elseif seconds < 604800 then
        return ("%dd"):format(math.floor(seconds / 86400))
      end
      return os.date("%Y-%m-%d", ts)
    end

    local function decode_session_name(file)
      local name = vim.fn.fnamemodify(file, ":t:r")
      if name == "" then
        return nil, nil
      end

      local parts = vim.split(name, "%%", { plain = true })
      local cwd_key = table.remove(parts, 1)
      local branch = #parts > 0 and table.concat(parts, "%%"):gsub("%%", "/") or nil
      local cwd = cwd_key and cwd_key ~= "" and cwd_key:gsub("%%", "/") or nil

      if cwd and jit and jit.os:find("Windows") then
        cwd = cwd:gsub("^(%w)/", "%1:/")
      end

      return normalize_path(cwd), branch
    end

    local function session_window(file)
      local dir = vim.fn.fnamemodify(file, ":h")
      if normalize_path(dir) == normalize_path(base_dir) then
        return nil
      end

      local name = vim.fn.fnamemodify(dir, ":t")
      return name:sub(1, 5) == "tmux-" and name:sub(6) or nil
    end

    local function make_absolute(path, cwd)
      if not path or path == "" or path:find("://") then
        return nil
      end

      path = shell_unescape(path)
      if path == "" or path:find("://") then
        return nil
      end

      if path:sub(1, 1) == "~" then
        return normalize_path(path)
      end
      if path:match("^[/\\]") or path:match("^%a:[/\\]") then
        return normalize_path(path)
      end
      return cwd and normalize_path(cwd .. "/" .. path) or path
    end

    local function parse_file_arg(line)
      local arg = line:match("^%s*badd%s+(.+)$")
      if arg then
        return (arg:gsub("^%+%d+%s+", ""))
      end

      arg = line:match("^%s*edit%s+(.+)$")
      if not arg then
        return nil
      end

      while arg:match("^%+%S+%s+") or arg:match("^%+%+%S+%s+") do
        arg = arg:gsub("^%+%S+%s+", "", 1)
        arg = arg:gsub("^%+%+%S+%s+", "", 1)
      end
      return arg
    end

    local function parse_session_file(file)
      local ok, lines = pcall(vim.fn.readfile, file)
      if not ok then
        return nil, {}
      end

      local cwd
      local raw_files = {}
      for _, line in ipairs(lines) do
        local cd = line:match("^%s*[lt]?cd%s+(.+)$")
        if cd then
          cwd = normalize_path(shell_unescape(cd))
        end

        local arg = parse_file_arg(line)
        if arg then
          raw_files[#raw_files + 1] = arg
        end
      end

      local files = {}
      local seen = {}
      for _, raw in ipairs(raw_files) do
        local path = make_absolute(raw, cwd)
        if path and not seen[path] then
          seen[path] = true
          files[#files + 1] = path
        end
      end

      return cwd, files
    end

    local function buffer_summary(files)
      if #files == 0 then
        return "no files"
      end

      local names = {}
      for i = 1, math.min(#files, 3) do
        names[#names + 1] = vim.fn.fnamemodify(files[i], ":t")
      end
      local summary = table.concat(names, ", ")
      if #files > 3 then
        summary = summary .. (" +%d"):format(#files - 3)
      end
      return summary
    end

    local function preview_text(item)
      local lines = {
        "# Session",
        "",
        ("Path: `%s`"):format(item.session),
        ("CWD: `%s`"):format(item.cwd or "unknown"),
        ("Branch: `%s`"):format(item.branch or "none"),
        ("Tmux window: `%s`"):format(item.tmux_window or "none"),
        ("Modified: `%s`"):format(os.date("%Y-%m-%d %H:%M:%S", item.mtime)),
        "",
        "Files:",
      }

      if #item.buffers == 0 then
        lines[#lines + 1] = "- none parsed"
      else
        for _, file in ipairs(item.buffers) do
          lines[#lines + 1] = "- `" .. file .. "`"
        end
      end

      return table.concat(lines, "\n")
    end

    local function glob_sessions()
      local files = {}
      local seen = {}
      for _, pattern in ipairs({ base_dir .. "*.vim", base_dir .. "**/*.vim" }) do
        for _, file in ipairs(vim.fn.glob(pattern, false, true)) do
          if not seen[file] and vim.fn.filereadable(file) == 1 then
            seen[file] = true
            files[#files + 1] = file
          end
        end
      end
      return files
    end

    function persistence.load_file(file)
      if not file or vim.fn.filereadable(file) == 0 then
        return false
      end

      persistence.fire("LoadPre")
      vim.cmd("silent! source " .. vim.fn.fnameescape(file))
      persistence.fire("LoadPost")
      return true
    end

    function persistence.session_items(opts)
      opts = opts or {}
      if opts.items then
        return opts.items
      end

      local want_cwd = normalize_path(opts.cwd)
      local want_window = opts.window and sanitize(opts.window) or nil
      local items = {}

      for _, file in ipairs(glob_sessions()) do
        local stat = uv.fs_stat(file)
        if stat then
          local name_cwd, branch = decode_session_name(file)
          local file_cwd, buffers = parse_session_file(file)
          local cwd = file_cwd or name_cwd
          local window = session_window(file)

          if cwd and (not want_cwd or cwd == want_cwd) and (not want_window or window == want_window) then
            local item = {
              session = file,
              cwd = cwd,
              branch = branch,
              tmux_window = window,
              mtime = stat.mtime.sec + ((stat.mtime.nsec or 0) / 1000000000),
              buffers = buffers,
            }
            item.age = reltime(item.mtime)
            item.buffer_summary = buffer_summary(buffers)
            item.text = table.concat({
              item.tmux_window or "no-tmux",
              item.cwd or "",
              item.branch or "",
              item.buffer_summary,
              table.concat(item.buffers, " "),
            }, " ")
            item.preview = {
              text = preview_text(item),
              ft = "markdown",
              loc = false,
            }
            items[#items + 1] = item
          end
        end
      end

      table.sort(items, function(a, b)
        if a.mtime == b.mtime then
          return a.session < b.session
        end
        return a.mtime > b.mtime
      end)
      return items
    end

    local function open_picker(items, title)
      persistence.select({
        items = items,
        title = title,
      })
    end

    function persistence.select(opts)
      opts = opts or {}
      local ok = pcall(require, "snacks")
      if ok and Snacks and Snacks.picker and Snacks.picker.sessions then
        return Snacks.picker.sessions(opts)
      end

      local items = persistence.session_items(opts)
      vim.ui.select(items, {
        prompt = opts.title or "Select Session",
        format_item = function(item)
          return ("%s  %s  %s"):format(item.age, item.tmux_window or "no tmux", item.cwd or item.session)
        end,
      }, function(item)
        if item then
          persistence.load_file(item.session)
        end
      end)
    end

    function persistence.load_tmux_fallback()
      local current_cwd = normalize_path(vim.fn.getcwd())
      local candidates = persistence.session_items({ cwd = current_cwd })
      local ctx = tmux_context()

      if ctx then
        local same_window = vim.tbl_filter(function(item)
          return item.tmux_window == ctx.window_name
        end, candidates)

        if #same_window > 0 then
          if count_recent(same_window) > 1 then
            open_picker(same_window, ("Recent sessions for %s"):format(ctx.raw_window_name))
            return
          end

          local item = newest(same_window)
          if persistence.load_file(item.session) then
            return
          end
        elseif #candidates > 0 then
          open_picker(candidates, "Sessions for this directory")
          return
        end
      elseif #candidates == 1 then
        if persistence.load_file(candidates[1].session) then
          return
        end
      elseif #candidates > 1 then
        if count_recent(candidates) > 1 then
          open_picker(candidates, "Sessions for this directory")
        else
          persistence.load_file(newest(candidates).session)
        end
        return
      end

      vim.notify("No saved session found for this tmux window or cwd", vim.log.levels.INFO)
    end

    local session_dir = base_dir
    local tmux = tmux_context()
    if tmux then
      session_dir = base_dir .. "tmux-" .. tmux.window_name .. "/"
    end

    persistence.setup({
      dir = session_dir,
      branch = true,
    })
  end,
}
--]]
