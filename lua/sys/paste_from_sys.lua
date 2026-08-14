-- ============================
-- System clipboard paste (cross-platform)
--
-- Picks the right paste tool for the current environment instead of
-- assuming Termux, and tells the user exactly what's missing (and
-- how to install it) if no candidate tool is found on $PATH.
-- ============================

local function is_windows()
  return vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
end

local function is_mac()
  return vim.fn.has("mac") == 1 or vim.fn.has("macunix") == 1
end

local function is_termux()
  return vim.env.TERMUX_VERSION ~= nil or (vim.env.PREFIX ~= nil and vim.env.PREFIX:match("com%.termux") ~= nil)
end

local function is_wayland()
  return vim.env.WAYLAND_DISPLAY ~= nil
end

-- Ordered candidates for the current platform. First one whose
-- executable is actually found on $PATH wins.
local function paste_candidates()
  if is_termux() then
    return {
      {
        cmd = { "termux-clipboard-get" },
        install = "install Termux:API (`pkg install termux-api`) and the Termux:API companion app",
      },
    }
  end

  if is_windows() then
    return {
      -- win32yank is binary-safe and handles line endings cleanly;
      -- prefer it, but PowerShell ships with Windows as a fallback.
      { cmd = { "win32yank.exe", "-o", "--lf" }, install = "install win32yank (`winget install win32yank`)" },
      {
        cmd = { "powershell.exe", "-NoProfile", "-Command", "Get-Clipboard" },
        install = "PowerShell (should already be on Windows)",
      },
    }
  end

  if is_mac() then
    return {
      { cmd = { "pbpaste" }, install = "pbpaste ships with macOS by default" },
    }
  end

  -- Linux / BSD: prefer the Wayland tool only in a Wayland session,
  -- otherwise fall through the X11 options.
  local candidates = {}
  if is_wayland() then
    table.insert(candidates, {
      cmd = { "wl-paste", "--no-newline" },
      install = "install wl-clipboard (e.g. `sudo apt install wl-clipboard`)",
    })
  end
  table.insert(candidates, {
    cmd = { "xclip", "-selection", "clipboard", "-o" },
    install = "install xclip (e.g. `sudo apt install xclip`)",
  })
  table.insert(candidates, {
    cmd = { "xsel", "--clipboard", "--output" },
    install = "install xsel (e.g. `sudo apt install xsel`)",
  })
  return candidates
end

local function resolve_paste_tool()
  for _, c in ipairs(paste_candidates()) do
    if vim.fn.executable(c.cmd[1]) == 1 then
      return c
    end
  end
  return nil
end

--- @param callback fun(text: string)
local function system_paste(callback)
  local tool = resolve_paste_tool()
  if not tool then
    local hints = vim.tbl_map(function(c)
      return c.install
    end, paste_candidates())
    vim.notify(
      "[paste] No clipboard tool available on $PATH for this system.\n"
        .. (#hints > 0 and ("Try: " .. table.concat(hints, "  OR  ")) or "No known tool for this platform."),
      vim.log.levels.ERROR
    )
    return
  end

  vim.system(tool.cmd, { text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 then
        vim.notify(
          string.format(
            "[paste] '%s' exited with code %d%s",
            tool.cmd[1],
            res.code,
            res.stderr and res.stderr ~= "" and (": " .. res.stderr) or ""
          ),
          vim.log.levels.ERROR
        )
        return
      end
      local text = (res.stdout or ""):gsub("\r\n", "\n"):gsub("\n$", "")
      callback(text)
    end)
  end)
end

-- <Leader>pc — Paste from system clipboard
vim.keymap.set("n", "<leader>pc", function()
  system_paste(function(text)
    if text and text ~= "" then
      if text:find("\n") then
        vim.api.nvim_put(vim.split(text, "\n", { plain = true }), "c", true, true)
      else
        vim.api.nvim_put({ text }, "c", true, true)
      end
      vim.notify("Pasted!", vim.log.levels.INFO)
    else
      vim.notify("Clipboard is empty", vim.log.levels.WARN)
    end
  end)
end, { desc = "Paste from system clipboard" })
