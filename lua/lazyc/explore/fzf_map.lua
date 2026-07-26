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
-- Disabling git_icons/file_icons avoids extra `git status` + devicon
-- lookups per entry. The --exclude list keeps fd from descending into
-- huge dirs (node_modules, caches, venvs) that make $HOME/$PREFIX slow.
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

local function fd_file_opts()
  return "--color=never --type f --hidden " .. table.concat(FAST_EXCLUDES, " ")
end

local function rg_extra_opts()
  local parts = {}
  for _, e in ipairs(FAST_EXCLUDES) do
    -- convert "--exclude X" -> "--glob !X" for ripgrep
    local dir = e:match("^%-%-exclude%s+(.+)$")
    if dir then
      table.insert(parts, string.format("--glob '!%s'", dir))
    end
  end
  return table.concat(parts, " ")
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
      fn(unpack(args))
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
    fd_opts = fd_file_opts(),
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
    rg_opts = "--column --line-number --no-heading --color=always --smart-case -g '!.git' " .. rg_extra_opts(),
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
-- Keymaps
-- ============================
local map = vim.keymap.set

map("n", "<leader>fd", function()
  open_files(vim.fn.getcwd(), "Cwd/")
end, { desc = "Files: cwd" })
map("n", "<leader>fr", function()
  open_files(root(), "Root_Dir/")
end, { desc = "Files: project root" })
map("n", "<leader>fh", function()
  open_files(home(), "~/")
end, { desc = "Files: $HOME" })
map("n", "<leader>fp", function()
  open_files(prefix(), "$PREFIX/")
end, { desc = "Files: $PREFIX" })
map("n", "<leader>fc", function()
  open_files(config(), "Purc/")
end, { desc = "Files: nvim config" })

-- ============================
-- Custom dir picker (fzf_exec — no fzf-lua pre-processing overhead)
-- ============================
local function termux_roots()
  return {
    HOME = os.getenv("HOME") or "/data/data/com.termux/files/home",
    PREFIX = os.getenv("PREFIX") or "/data/data/com.termux/files/usr",
  }
end

local function expand_label(label)
  local roots = termux_roots()
  if label:sub(1, 1) == "~" then
    return roots.HOME .. label:sub(2)
  elseif label:sub(1, 8) == "$PREFIX/" or label == "$PREFIX" then
    return roots.PREFIX .. label:sub(8)
  end
  return label
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
        local actions = require("fzf-lua").actions
        local path = require("fzf-lua.path")
        for i, entry in ipairs(selected) do
          local file = path.entry_to_file(entry, opts).path
          if i == 1 then
            vim.cmd("edit " .. vim.fn.fnameescape(file))
          else
            vim.cmd("vsplit " .. vim.fn.fnameescape(file))
          end
        end
      end,
    },
  })
end

map("n", "<leader>ff", pick_dir, { desc = "Files: pick custom dir ($HOME/$PREFIX)" })
