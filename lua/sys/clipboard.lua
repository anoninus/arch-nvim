-- ================================================
-- Clipboard (smart cross-platform copy, with Termux fallback)
-- ================================================

local function is_termux()
  return vim.env.TERMUX_VERSION ~= nil or (vim.env.PREFIX ~= nil and vim.env.PREFIX:match("com%.termux") ~= nil)
end

local function is_windows()
  return vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
end

local function is_mac()
  return vim.fn.has("mac") == 1 or vim.fn.has("macunix") == 1
end

local function is_wayland()
  return vim.env.WAYLAND_DISPLAY ~= nil
end

local function is_ssh()
  return vim.env.SSH_TTY ~= nil or vim.env.SSH_CONNECTION ~= nil
end

-- Ordered {cmd, install} candidates for writing to the *local*
-- clipboard via a native CLI tool (text piped over stdin).
local function copy_candidates()
  if is_windows() then
    return {
      { cmd = { "win32yank.exe", "-i", "--crlf" }, install = "install win32yank (`winget install win32yank`)" },
    }
  end
  if is_mac() then
    return { { cmd = { "pbcopy" }, install = "pbcopy ships with macOS by default" } }
  end
  -- Linux / BSD
  local candidates = {}
  if is_wayland() then
    table.insert(candidates, {
      cmd = { "wl-copy" },
      install = "install wl-clipboard (e.g. `sudo apt install wl-clipboard`)",
    })
  end
  table.insert(candidates, {
    cmd = { "xclip", "-selection", "clipboard" },
    install = "install xclip (e.g. `sudo apt install xclip`)",
  })
  table.insert(candidates, {
    cmd = { "xsel", "--clipboard", "--input" },
    install = "install xsel (e.g. `sudo apt install xsel`)",
  })
  return candidates
end

local function resolve_copy_tool()
  for _, c in ipairs(copy_candidates()) do
    if vim.fn.executable(c.cmd[1]) == 1 then
      return c
    end
  end
  return nil
end

local function osc52_copy(lines)
  local ok, osc52 = pcall(require, "vim.ui.clipboard.osc52")
  if not ok then
    vim.notify("[copy] OSC52 fallback unavailable on this Neovim build.", vim.log.levels.ERROR)
    return
  end
  osc52.copy("+")(lines)
end

local function native_copy(tool, lines)
  local text = table.concat(lines, "\n")
  vim.system(tool.cmd, { stdin = text }, function(res)
    if res.code ~= 0 then
      vim.schedule(function()
        vim.notify(
          string.format(
            "[copy] '%s' exited with code %d%s",
            tool.cmd[1],
            res.code,
            res.stderr and res.stderr ~= "" and (": " .. res.stderr) or ""
          ),
          vim.log.levels.ERROR
        )
      end)
    end
  end)
end

local function smart_copy_lines(lines)
  local text = table.concat(lines, "\n")
  local text_size = #text

  if is_termux() then
    if vim.fn.executable("termux-clipboard-set") ~= 1 then
      vim.notify(
        "[copy] 'termux-clipboard-set' not found. Install Termux:API (`pkg install termux-api`) "
          .. "and the Termux:API companion app.",
        vim.log.levels.ERROR
      )
      return
    end
    if text_size > 800000 then
      local size_mb = string.format("%.2f", text_size / 1024 / 1024)
      vim.notify(
        "Yanked " .. size_mb .. "MB. Too large for Android clipboard. Kept inside Neovim.",
        vim.log.levels.WARN
      )
    elseif text_size > 6000 then
      vim.fn.system("termux-clipboard-set", text)
    else
      osc52_copy(lines)
    end
    return
  end

  -- Over SSH there's no local clipboard to write to — OSC52 asks
  -- the terminal emulator to relay the payload to the *client*
  -- machine's clipboard, which is the only thing that can work here.
  if is_ssh() then
    osc52_copy(lines)
    return
  end

  local tool = resolve_copy_tool()
  if tool then
    native_copy(tool, lines)
    return
  end

  -- No native tool found locally; best-effort OSC52, but tell the
  -- user what to install for a more reliable native copy.
  local hints = vim.tbl_map(function(c)
    return c.install
  end, copy_candidates())
  vim.notify(
    "[copy] No native clipboard tool found. Falling back to OSC52 (not all terminals support it).\n"
      .. (#hints > 0 and ("For a reliable copy, " .. table.concat(hints, "  OR  ")) or ""),
    vim.log.levels.WARN
  )
  osc52_copy(lines)
end

local function smart_copy_register(reg)
  local lines = vim.fn.getreg(reg, 1, 1)
  smart_copy_lines(lines)
end

-- Normal mode: copy default yank register
vim.keymap.set("n", "<leader>yc", function()
  smart_copy_register('"')
end, { desc = "Copy yank register to system clipboard" })

-- Visual mode: yank selection into temp register, then copy it
vim.keymap.set("v", "<leader>yc", function()
  vim.cmd('normal! "zy')
  local lines = vim.fn.getreg("z", 1, 1)
  if not lines or #lines == 0 or (#lines == 1 and lines[1] == "") then
    vim.notify("Empty selection", vim.log.levels.WARN)
    return
  end
  smart_copy_lines(lines)
end, { desc = "Copy visual selection to system clipboard" })

-- The operatorfunc for motion yank
_G._clipboard_motion_copy = function(motion_type)
  local regs = { line = "'[V']", char = "`[v`]", block = "`[\022`]" }
  local sel = regs[motion_type]
  if not sel then
    return
  end
  vim.cmd("normal! " .. sel .. '"vy')
  smart_copy_register("v")
end

-- Normal mode: operator-pending — yank with motion, then copy it
vim.keymap.set("n", "<leader>ym", function()
  vim.o.operatorfunc = "v:lua._clipboard_motion_copy"
  vim.api.nvim_feedkeys("g@", "n", false)
end, { desc = "Copy motion to system clipboard" })

-- Desktop: use system clipboard natively via Neovim's built-in
-- provider (which itself picks pbcopy/xclip/wl-copy/win32yank).
-- Warn instead of silently setting an option that won't do anything.
if not is_termux() then
  if vim.fn.has("clipboard") == 1 then
    vim.opt.clipboard = "unnamedplus"
  elseif not is_ssh() then
    vim.notify(
      "[copy] No clipboard provider detected; 'unnamedplus' won't sync with the system clipboard. "
        .. "<leader>yc/<leader>ym will still work via OSC52/native fallback.",
      vim.log.levels.WARN
    )
  end
end
