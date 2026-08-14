-- ============================
-- OS / environment detection
-- ============================
local function is_windows()
  return vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
end

local function is_termux()
  -- TERMUX_VERSION is the reliable signal; fall back to inspecting
  -- $PREFIX in case the var isn't exported by the user's shell.
  return vim.env.TERMUX_VERSION ~= nil or (vim.env.PREFIX ~= nil and vim.env.PREFIX:match("com%.termux") ~= nil)
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

local function config()
  return vim.fn.stdpath("config")
end

-- ============================
-- Root markers (user-editable)
--
-- Loaded once, at file-load time, from ~/.config/nvim/root_markers.json
-- (a plain JSON array of marker filenames, e.g.
-- [".git", ".root", "package.json", "Cargo.toml", "go.mod"]).
-- Editing that file requires a `:source` or nvim restart to take
-- effect since we don't watch it.
--
-- Deliberately ONE shared list for both launch_root() and
-- buffer_root() (not separate "wide" vs "narrow" lists) — since
-- vim.fs.root() stops at the *nearest* matching marker walking
-- upward, putting subproject markers (package.json, Cargo.toml,
-- go.mod, pyproject.toml, ...) alongside repo-level ones (.git,
-- .root) in the same file already gives buffer_root() natural
-- narrowing inside a monorepo, with zero extra code.
-- ============================
local function load_root_markers()
  local default_markers = { ".git", ".root" }
  local path = vim.fs.joinpath(vim.fn.stdpath("config"), "root_markers.json")
  local f = io.open(path, "r")
  if not f then
    return default_markers
  end
  local content = f:read("*a")
  f:close()
  local ok, decoded = pcall(vim.json.decode, content)
  if not ok or type(decoded) ~= "table" or vim.tbl_isempty(decoded) then
    vim.notify(
      "[fzf-files-grep] root_markers.json missing/invalid; falling back to default markers",
      vim.log.levels.WARN
    )
    return default_markers
  end
  return decoded
end

local ROOT_MARKERS = load_root_markers()

-- Root from where nvim was launched (pwd), walking upward for a
-- marker; falls back to pwd itself if none is found.
local function launch_root()
  return vim.fs.root(vim.fn.getcwd(), ROOT_MARKERS) or vim.fn.getcwd()
end

-- Root relative to the CURRENT BUFFER's file, walking upward for a
-- marker; falls back to the buffer's own directory if no marker is
-- found. Returns nil (caller should notify + no-op) if the buffer
-- isn't backed by a file on disk at all (scratch/terminal/etc).
local function buffer_root()
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname == "" then
    return nil
  end
  return vim.fs.root(0, ROOT_MARKERS) or vim.fn.fnamemodify(bufname, ":h")
end

local function notify_no_buffer_root()
  vim.notify("[fzf-files-grep] current buffer has no file on disk; can't resolve a buffer root", vim.log.levels.WARN)
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
--
-- Checked once at load time (vim.fn.executable() does a PATH walk)
-- rather than on every single keypress — small, but it's one less
-- synchronous filesystem op between "key pressed" and "window open".
-- ============================
local TOOL_AVAILABLE = {
  fd = vim.fn.executable("fd") == 1,
  rg = vim.fn.executable("rg") == 1,
}

local function require_executable(name)
  if not TOOL_AVAILABLE[name] then
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
local open_files, open_grep, pick_dir_files, pick_dir_grep

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

open_files = function(cwd, label, context)
  if not require_executable("fd") then
    return
  end
  require("fzf-lua").files({
    cwd = cwd,
    prompt = label,
    cwd_prompt = true,
    -- git_icons deliberately off: it makes fzf-lua shell out to `git
    -- status` and wait on it before painting results. file_icons is
    -- just a local extension lookup, no subprocess, kept on.
    git_icons = false,
    file_icons = true,
    fd_opts = FD_FILE_OPTS,
    winopts = {
      title = " Files: " .. context .. " ",
      title_pos = "center",
    },
    actions = {
      ["default"] = require("fzf-lua").actions.file_edit,
      ["ctrl-r"] = guard(function()
        open_grep(cwd, label, context)
      end),
      ["alt-r"] = guard(pick_dir_files),
    },
  })
end

open_grep = function(cwd, label, context)
  if not require_executable("rg") then
    return
  end
  require("fzf-lua").live_grep({
    cwd = cwd,
    prompt = label,
    cwd_prompt = true,
    git_icons = false,
    file_icons = true,
    rg_opts = RG_OPTS,
    winopts = {
      title = " Grep: " .. context .. " ",
      title_pos = "center",
    },
    actions = {
      ["default"] = require("fzf-lua").actions.file_edit,
      ["ctrl-r"] = guard(function()
        open_files(cwd, label, context)
      end),
      ["alt-r"] = guard(pick_dir_files),
    },
  })
end

-- ============================
-- Keymaps (raw, no <leader> — user relies on leap.nvim)
-- ============================
local map = vim.keymap.set

-- ---- Find files ----
map("n", "fl", function()
  open_files(launch_root(), "Launch/", "launch pwd/root")
end, { desc = "Files: launch pwd/root" })

map("n", "fb", function()
  local dir = buffer_root()
  if not dir then
    notify_no_buffer_root()
    return
  end
  open_files(dir, "BufRoot/", "buffer root/dir")
end, { desc = "Files: buffer root/dir" })

map("n", "fh", function()
  open_files(home(), "~/", "$HOME")
end, { desc = "Files: $HOME" })

map("n", "fc", function()
  open_files(config(), "Config/", "nvim config")
end, { desc = "Files: nvimrc / config" })

map("n", "fo", function()
  require("fzf-lua").oldfiles({
    prompt = "Old/",
    winopts = {
      title = " Files: oldfiles ",
      title_pos = "center",
    },
  })
end, { desc = "Files: oldfiles" })

-- fd is mapped below, after pick_dir_files is defined.

-- ---- Grep ----
map("n", "gl", function()
  open_grep(launch_root(), "Launch/", "launch pwd/root")
end, { desc = "Grep: launch pwd/root" })

map("n", "gb", function()
  local dir = buffer_root()
  if not dir then
    notify_no_buffer_root()
    return
  end
  open_grep(dir, "BufRoot/", "buffer root/dir")
end, { desc = "Grep: buffer root/dir" })

map("n", "gf", function()
  if not require_executable("rg") then
    return
  end
  require("fzf-lua").lgrep_curbuf({
    prompt = "Buf/",
    rg_opts = RG_OPTS,
    winopts = {
      title = " Grep: current buffer ",
      title_pos = "center",
    },
  })
end, { desc = "Grep: current buffer" })

-- gd is mapped below, after pick_dir_grep is defined.

-- ============================
-- Custom dir pickers (fd / gd)
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
-- "UI loads late" delay previously — the fzf window couldn't open
-- until fd finished walking every directory. Streaming lets the
-- window open immediately and fill in as results arrive.
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

-- Shared async dir-streaming helper: walks `display_roots()` with fd
-- and feeds fzf-lua as results arrive. `on_select(dir)` is called
-- with the chosen absolute path when the user picks one.
local function run_dir_picker(prompt, title, on_select)
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
    prompt = prompt,
    winopts = {
      title = " " .. title .. " ",
      title_pos = "center",
    },
    actions = {
      ["default"] = function(selected)
        local label = selected[1]
        local dir = label and label_to_path[label]
        if dir then
          on_select(dir)
        end
      end,
    },
  })
end

-- fd: pick a directory from disk, then open a FILES picker scoped
-- to it (previously this used to `:edit` the directory path itself,
-- which wasn't actually useful — fixed here).
pick_dir_files = function()
  run_dir_picker("Dir> ", "Files: pick dir from disk, find inside", function(dir)
    open_files(dir, "Sel/", "selected dir")
  end)
end

-- gd: pick a directory from disk, then open a GREP picker scoped to it.
pick_dir_grep = function()
  run_dir_picker("Grep Dir> ", "Grep: pick dir from disk, grep inside", function(dir)
    open_grep(dir, "Sel/", "selected dir")
  end)
end

map("n", "fd", pick_dir_files, { desc = "Files: pick dir from disk, find inside" })
map("n", "gd", pick_dir_grep, { desc = "Grep: pick dir from disk, grep inside" })
