-- ============================
-- OS / environment detection
-- ============================
local function is_windows()
  return vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
end

local function is_termux()
  -- TERMUX_VERSION is the reliable signal; fall back to inspecting
  -- $PREFIX in case the var isn't exported by the user's shell.
  return vim.env.TERMUX_VERSION ~= nil
    or (vim.env.PREFIX ~= nil and vim.env.PREFIX:match("com%.termux") ~= nil)
end

-- ============================
-- Path resolvers
-- ============================
local function home()
  -- vim.uv.os_homedir() asks the OS directly (via libuv) instead of
  -- trusting $HOME, which may be unset or wrong under some Windows
  -- shells/terminal emulators. Fall back gracefully if unavailable.
  local ok, dir = pcall(function()
    return vim.uv.os_homedir()
  end)
  if ok and dir and dir ~= "" then
    return dir
  end
  return vim.env.HOME or vim.fn.getcwd()
end

local function prefix()
  if vim.env.PREFIX and vim.env.PREFIX ~= "" then
    return vim.env.PREFIX
  end
  if is_windows() then
    return (vim.env.SystemDrive or "C:") .. "\\"
  end
  return "/"
end

local function root()
  -- vim.fs.root/vim.fs.* already normalize separators per-OS.
  return vim.fs.root(0, { ".root", ".git" }) or vim.fn.getcwd()
end

local function config()
  return vim.fn.stdpath("config")
end

-- ============================
-- Perf: shared fast opts for big/unknown trees
-- fd/ripgrep flag syntax is identical across OSes (they're static
-- binaries with a consistent CLI), so these lists don't need to
-- branch on platform.
-- ============================
local FAST_EXCLUDES = {
  ".git",
  "node_modules",
  ".cache",
  "__pycache__",
  ".venv",
  "venv",
  ".npm",
  ".cargo",
}

local function fd_exclude_args()
  local parts = {}
  for _, e in ipairs(FAST_EXCLUDES) do
    table.insert(parts, "--exclude " .. e)
  end
  return table.concat(parts, " ")
end

local function rg_glob_args()
  local parts = {}
  for _, e in ipairs(FAST_EXCLUDES) do
    -- Double quotes are honored by every shell fzf-lua may invoke
    -- (sh/bash/zsh on Unix, and PowerShell/cmd on Windows), unlike
    -- single quotes which cmd.exe treats as literal characters.
    table.insert(parts, string.format('--glob "!%s"', e))
  end
  return table.concat(parts, " ")
end

local FD_FILE_OPTS = "--color=never --type f --hidden " .. fd_exclude_args()

local RG_OPTS = '--column --line-number --no-heading --color=always --smart-case -g "!.git" ' .. rg_glob_args()

-- ============================
-- Tool availability guard
-- ============================
local function require_executable(name)
  if vim.fn.executable(name) ~= 1 then
    vim.notify(
      string.format("[fzf-files-grep] '%s' not found on PATH; this picker will not work.", name),
      vim.log.levels.WARN
    )
    return false
  end
  return true
end

-- ============================
-- files/grep opener with ctrl-r toggle + alt-r dir-picker
-- ============================
local open_files, open_grep, pick_dir

local switching = false
local function guard(fn)
  return function(...)
    if switching then
      return
    end
    switching = true
    local args = { ... }
    vim.schedule(function()
      -- keep it as `unpack(args)`
      -- `table.unpack(args)` directly would fail under plain Lua 5.1.
      fn(unpack(args))
      vim.defer_fn(function()
        switching = false
      end, 150)
    end)
  end
end

open_files = function(cwd, label)
  if not require_executable("fd") then
    return
  end
  require("fzf-lua").files({
    cwd = cwd,
    prompt = label,
    cwd_prompt = true,
    git_icons = true,
    file_icons = true,
    fd_opts = FD_FILE_OPTS,
    actions = {
      ["default"] = require("fzf-lua").actions.file_edit,
      ["ctrl-r"] = guard(function()
        open_grep(cwd, label)
      end),
      ["alt-r"] = guard(pick_dir),
    },
  })
end

open_grep = function(cwd, label)
  if not require_executable("rg") then
    return
  end
  require("fzf-lua").live_grep({
    cwd = cwd,
    prompt = label,
    cwd_prompt = true,
    git_icons = true,
    file_icons = true,
    rg_opts = RG_OPTS,
    actions = {
      ["default"] = require("fzf-lua").actions.file_edit,
      ["ctrl-r"] = guard(function()
        open_files(cwd, label)
      end),
      ["alt-r"] = guard(pick_dir),
    },
  })
end

-- ============================
-- Keymaps (raw, no <leader> — user relies on leap.nvim)
-- ============================
local map = vim.keymap.set

map("n", "fd", function()
  open_files(vim.fn.getcwd(), "Cwd/")
end, { desc = "Files: cwd" })
map("n", "fr", function()
  open_files(root(), "Root_Dir/")
end, { desc = "Files: project root" })
map("n", "fh", function()
  open_files(home(), "~/")
end, { desc = "Files: $HOME" })
map("n", "fp", function()
  open_files(prefix(), "$PREFIX/")
end, { desc = "Files: $PREFIX" })
map("n", "fc", function()
  open_files(config(), "Purc/")
end, { desc = "Files: nvim config" })

-- ============================
-- Custom dir picker
--
-- Rewritten to avoid shelling out through `sed`/`{ ... ; }` POSIX
-- pipeline syntax, which silently breaks on Windows shells (cmd.exe,
-- PowerShell) and is brittle across different $SHELL configs on
-- Unix. `fd` is spawned via vim.system (libuv spawn, OS-agnostic
-- process handling); label rewriting happens in pure Lua.
--
-- IMPORTANT: results are streamed to fzf-lua as `fd` produces them
-- (async `stdout` callback), not collected with `:wait()` first. A
-- blocking prefetch of the whole $HOME tree is what caused the
-- "UI loads late" delay on `ff` — the fzf window couldn't open
-- until fd finished walking every directory. Streaming lets the
-- window open immediately and fill in as results arrive, matching
-- the original shell-pipe version's responsiveness.
-- ============================

-- Display roots: on Termux, both $HOME and $PREFIX are meaningful.
-- Elsewhere $PREFIX isn't really a "second root", so we only search
-- it when it differs from $HOME (e.g. it points to a real system
-- root) to avoid duplicate/irrelevant results.
local function display_roots()
  local h = home()
  local p = prefix()
  local roots = { { path = h, label = "~" } }
  if is_termux() and p ~= h then
    roots[#roots + 1] = { path = p, label = "$PREFIX" }
  end
  return roots
end

pick_dir = function()
  if not require_executable("fd") then
    return
  end

  local roots = display_roots()
  -- Shared across the async callbacks below and the `default`
  -- action, so it must live outside `contents` (a fresh closure per
  -- invocation would lose the mapping by the time a selection fires).
  local label_to_path = {}

  local function label_for(root_entry, full_path)
    if root_entry.label == "~" then
      -- fnamemodify(":~") is Vim's own OS-aware home-dir shortener.
      return vim.fn.fnamemodify(full_path, ":~")
    end
    return (full_path:gsub("^" .. vim.pesc(root_entry.path), root_entry.label, 1))
  end

  require("fzf-lua").fzf_exec(function(fzf_cb)
    label_to_path = {}

    local pending = 0
    for _, r in ipairs(roots) do
      if vim.fn.isdirectory(r.path) == 1 then
        pending = pending + 1
      end
    end
    if pending == 0 then
      fzf_cb(nil)
      return
    end

    local function on_root_done()
      pending = pending - 1
      if pending == 0 then
        -- Signals end-of-stream to fzf-lua.
        vim.schedule(function()
          fzf_cb(nil)
        end)
      end
    end

    for _, r in ipairs(roots) do
      if vim.fn.isdirectory(r.path) == 1 then
        vim.system({
          "fd",
          "--type",
          "d",
          "--hidden",
          "--exclude",
          ".git",
          ".",
          r.path,
        }, {
          text = true,
          stdout = function(_, data)
            if not data then
              return
            end
            for line in data:gmatch("[^\r\n]+") do
              local label = label_for(r, line)
              label_to_path[label] = line
              vim.schedule(function()
                fzf_cb(label)
              end)
            end
          end,
        }, function()
          on_root_done()
        end)
      end
    end
  end, {
    prompt = "Dir> ",
    actions = {
      ["default"] = function(selected)
        for i, label in ipairs(selected) do
          local file = label_to_path[label]
          if file then
            if i == 1 then
              vim.cmd("edit " .. vim.fn.fnameescape(file))
            else
              vim.cmd("vsplit " .. vim.fn.fnameescape(file))
            end
          end
        end
      end,
    },
  })
end

map("n", "ff", pick_dir, { desc = "Files: pick custom dir ($HOME/$PREFIX)" })

