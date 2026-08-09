-- ============================
-- Path resolvers
-- ============================
local function home()
  return vim.env.TERMUX_VERSION and "/data/data/com.termux/files/home" or vim.env.HOME or vim.fn.getcwd()
end

local function prefix()
  return vim.env.PREFIX or "/"
end

local function root()
  return vim.fs.root(0, { ".root", ".git" }) or vim.fn.getcwd()
end

local function config()
  return vim.fn.stdpath("config")
end

-- ============================
-- Perf: shared fast opts for big/unknown trees
-- ============================
local FAST_EXCLUDES = {
  "--exclude .git",
  "--exclude node_modules",
  "--exclude .cache",
  "--exclude __pycache__",
  "--exclude .venv",
  "--exclude venv",
  "--exclude .npm",
  "--exclude .cargo",
}

local FD_FILE_OPTS = "--color=never --type f --hidden " .. table.concat(FAST_EXCLUDES, " ")

local RG_EXTRA_OPTS = (function()
  local parts = {}
  for _, e in ipairs(FAST_EXCLUDES) do
    local dir = e:match("^%-%-exclude%s+(.+)$")
    if dir then
      table.insert(parts, string.format("--glob '!%s'", dir))
    end
  end
  return table.concat(parts, " ")
end)()

local RG_OPTS = "--column --line-number --no-heading --color=always --smart-case -g '!.git' " .. RG_EXTRA_OPTS

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
      -- table.unpack replaces the Lua 5.1/LuaJIT global `unpack`,
      -- which is deprecated/absent in Lua 5.4.
      fn(table.unpack(args))
      vim.defer_fn(function()
        switching = false
      end, 150)
    end)
  end
end

open_files = function(cwd, label)
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
-- Toggleable buffer diagnostics (split)
-- ============================
local function find_fzf_win()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "fzf" then
      return win, buf
    end
  end
  return nil, nil
end

local function toggle_diagnostics_split()
  local _, buf = find_fzf_win()

  if buf then
    -- Leave terminal-mode first, otherwise nvim_buf_delete can fail
    -- or leave the cursor/job in a weird state.
    if vim.fn.mode() == "t" then
      vim.cmd("stopinsert")
    end
    vim.api.nvim_buf_delete(buf, { force = true })
    return
  end

  require("fzf-lua").diagnostics_document({
    winopts = {
      -- split = "belowright new",
      -- preview = { hidden = true },
      -- height = 0.35,
    },
    diag_icons = true, -- show severity icons
    diag_source = true, -- show source, e.g. [lua_ls]
    diag_code = true, -- show diag code, e.g. [undefined-global]
    multiline = 2, -- wrap heading + message onto separate lines
    color_headings = true, -- color file/severity headings
    icon_padding = " ", -- breathing room next to icons
    fzf_opts = {
      ["--color"] = "fg+:regular,hl+:regular",
    },
    actions = {
      ["esc"] = false, -- disable default close-on-esc
    },
  })
end

-- Mapped in BOTH normal mode (to open) and terminal mode (to close
-- while focused inside the fzf picker itself).
vim.keymap.set({ "n", "t" }, "<S-End>", toggle_diagnostics_split, { desc = "Toggle buffer diagnostics (split)" })

-- ============================
-- Custom dir picker (fzf_exec — no fzf-lua pre-processing overhead)
-- ============================
local function termux_roots()
  return {
    HOME = os.getenv("HOME") or "/data/data/com.termux/files/home",
    PREFIX = os.getenv("PREFIX") or "/data/data/com.termux/files/usr",
  }
end

pick_dir = function()
  local roots = termux_roots()
  local cmd = string.format(
    [[{ fd --type d --hidden --exclude .git . %s 2>/dev/null | sed "s#^%s#~#"; ]]
      .. [[fd --type d --hidden --exclude .git . %s 2>/dev/null | sed "s#^%s#\$PREFIX#"; }]],
    vim.fn.shellescape(roots.HOME),
    roots.HOME,
    vim.fn.shellescape(roots.PREFIX),
    roots.PREFIX
  )

  require("fzf-lua").fzf_exec(cmd, {
    prompt = "Dir> ",
    actions = {
      ["default"] = function(selected, opts)
        local path = require("fzf-lua.path")
        for i, entry in ipairs(selected) do
          local file = path.entry_to_file(entry, opts).path
          -- `.path` is typed as `string?`; fnameescape/edit/vsplit all
          -- require a plain `string`, so skip any entry that resolves
          -- to nil instead of passing it through unchecked.
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
