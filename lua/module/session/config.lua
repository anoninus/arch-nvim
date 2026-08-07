-- ~/.config/nvim/lua/user/session.lua
--
-- Custom session manager built directly on Neovim's native
-- :mksession / :source API (no session plugin), with fzf-lua pickers.
--
-- Keymaps:
--   <leader>sf  Session Find   -> fuzzy pick + (re)load a session fresh
--   <leader>sc  Session Create -> new session, fails if name already exists
--   <leader>sd  Session Delete -> persistent fzf multi-delete (ctrl-x)
--
-- Autosave: whenever the buffer/split/tab layout CHANGES — a buffer,
-- split, or tab is added (BufAdd/WinNew/TabNew) or removed
-- (BufDelete/WinClosed/TabClosed) — the session is saved immediately,
-- synchronously, inline in the autocmd callback. mksession! is cheap
-- (just writes a small vimscript file), so there's no need to defer
-- or debounce it — and deferring via vim.schedule/vim.defer_fn means
-- waiting for the next main-loop tick, which in practice doesn't
-- happen until further input arrives (e.g. a cursor move), so a
-- closed split wouldn't actually be saved until you moved the cursor.
-- Saving inline avoids that entirely.
--
-- No zombies: LSP clients and terminal jobs are stopped both when
-- switching sessions and on VimLeavePre, so quitting nvim directly
-- (without switching sessions first) never leaves anything running.
--
-- Requires: fzf-lua (https://github.com/ibhagwan/fzf-lua)
--
-- Global state (exposed for use from other config files, e.g. statusline):
--   _G.PuSessionLoaded   -> false, or the loaded session's name (string)
--   _G.PuSessionUnsaved  -> true from the moment a join happens until
--                           the scheduled save lands (visible for at
--                           most one redraw in practice)
--   _G.PuSessionSnapshot -> kept only because it's read elsewhere
--                           (e.g. statusline). No longer backs any
--                           internal logic — just a truthy marker of
--                           "a session is loaded", set alongside
--                           PuSessionLoaded. Safe to delete this line
--                           (and its statusline usage) if unused.

local M = {}
local fzf = require("fzf-lua")

-- All sessions live here, one file per session, named by the user.
M.session_dir = vim.fn.stdpath("data") .. "/PuSession/"

-- Tracks the name of whatever session is currently "active" in this
-- editor instance (set on create/load).
M.current_session = nil

-- Global, cross-file accessible state. Initialize once up front so any
-- other file can safely read these even before a session is touched.
_G.PuSessionLoaded = false
_G.PuSessionUnsaved = false
_G.PuSessionSnapshot = nil

-- sessionoptions is the single biggest lever here:
--   - NO "curdir"/"sesdir"  -> Vim stores each buffer's *full absolute
--     path* in the session file instead of paths relative to a cwd
--     that may not exist/match next time you load it.
--   - NO "blank"/"terminal" -> no empty scratch buffers or dead
--     terminal jobs get "restored" as stale placeholders.
--   - buffers,tabpages,winsize,winpos -> full layout (splits, tabs,
--     window sizes/positions) is captured and restored exactly.
--   - NO "folds" -> fold state isn't reliably restored anyway, so it's
--     dropped rather than carrying dead weight in the session file.
vim.o.sessionoptions = "buffers,tabpages,winsize,winpos,localoptions,globals,help"

local function ensure_dir()
  if vim.fn.isdirectory(M.session_dir) == 0 then
    vim.fn.mkdir(M.session_dir, "p")
  end
end

local function session_path(name)
  return M.session_dir .. name .. ".vim"
end

local function file_exists(path)
  return vim.fn.filereadable(path) == 1
end

local function list_sessions()
  ensure_dir()
  local files = vim.fn.globpath(M.session_dir, "*.vim", false, true)
  local names = {}
  for _, f in ipairs(files) do
    table.insert(names, vim.fn.fnamemodify(f, ":t:r"))
  end
  table.sort(names)
  return names
end

-- Stop anything that could outlive the buffers/windows it's attached
-- to: LSP clients and running terminal jobs. Called both before
-- loading a different session (so nothing from the old one lingers)
-- and on VimLeavePre (so quitting nvim directly never leaves zombies).
local function kill_zombies()
  for _, client in ipairs(vim.lsp.get_clients()) do
    client:stop(true) -- force stop, don't wait for graceful shutdown
  end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "terminal" then
      local chan = vim.b[buf].terminal_job_id
      if chan then
        pcall(vim.fn.jobstop, chan)
      end
    end
  end
end

-- Nuke all buffers/windows/tabs before loading a session so what you
-- get is EXACTLY what's in the session file — never a merge with
-- whatever happened to already be open (i.e. always fresh, never stale).
local function reset_editor_state()
  kill_zombies()
  vim.cmd("silent! tabonly")
  vim.cmd("silent! only")
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end
end

-- Call this right after a successful create/load/save: marks the
-- session as loaded, records its name, clears the unsaved flag.
local function mark_loaded(name)
  M.current_session = name
  _G.PuSessionLoaded = name
  _G.PuSessionUnsaved = false
  _G.PuSessionSnapshot = true
end

-- Call this when there's no longer an active session (e.g. it was
-- deleted out from under us).
local function mark_unloaded()
  M.current_session = nil
  _G.PuSessionLoaded = false
  _G.PuSessionUnsaved = false
  _G.PuSessionSnapshot = nil
end

-- ---------------------------------------------------------------------
-- Autosave: a buffer/split/tab joining or leaving the session saves
-- immediately, synchronously.
-- ---------------------------------------------------------------------

local function save_session()
  if not M.current_session then
    return
  end
  vim.cmd("mksession! " .. vim.fn.fnameescape(session_path(M.current_session)))
  _G.PuSessionUnsaved = false
end

-- Invoked from the structural add/remove events only — never plain
-- navigation (bufnext/bufprev/tabnext/tabprev, <C-w>w, etc.). No-ops
-- if no session is currently loaded.
local function on_change()
  if not M.current_session then
    return
  end
  _G.PuSessionUnsaved = true
  save_session()
end

--- Returns the loaded session's name (truthy string) if a session is
--- currently loaded, or `false` otherwise.
function M.is_session_loaded()
  return _G.PuSessionLoaded
end

--- Returns true only transiently — saves are synchronous now, so this
--- is effectively always false except for the instant inside a save.
--- Kept for API compatibility with anything reading it (e.g. statusline).
function M.is_unsaved()
  return _G.PuSessionUnsaved
end

--- <leader>sc — Session Create
-- Name must be unique; refuses (does not overwrite) if it exists.
-- Once created, the session becomes the autosave target.
function M.session_create()
  ensure_dir()
  vim.ui.input({ prompt = "New session name: " }, function(name)
    if not name or name == "" then
      vim.notify("Session create cancelled", vim.log.levels.WARN)
      return
    end
    if file_exists(session_path(name)) then
      vim.notify("Session '" .. name .. "' already exists", vim.log.levels.ERROR)
      return
    end
    vim.cmd("mksession! " .. vim.fn.fnameescape(session_path(name)))
    mark_loaded(name)
    vim.notify("Session created (autosave enabled): " .. name)
  end)
end

--- <leader>sf — Session Find / Load
-- Fuzzy-pick a session from PuSession/ and load it fresh (reset first).
-- Once loaded, the session becomes the autosave target.
function M.session_find()
  ensure_dir()
  local sessions = list_sessions()
  if #sessions == 0 then
    vim.notify("No sessions found in " .. M.session_dir, vim.log.levels.WARN)
    return
  end

  fzf.fzf_exec(sessions, {
    prompt = "Sessions❯ ",
    fzf_opts = { ["--no-multi"] = "" },
    actions = {
      ["default"] = function(selected)
        if not selected or #selected == 0 then
          return
        end
        local name = selected[1]
        local path = session_path(name)
        if not file_exists(path) then
          vim.notify("Session file missing: " .. path, vim.log.levels.ERROR)
          return
        end
        -- Detach autosave BEFORE tearing anything down, so the
        -- BufDelete/WinClosed/TabClosed events fired by
        -- reset_editor_state(), and the BufAdd/WinNew/TabNew events
        -- fired by sourcing the new session below, don't trigger
        -- on_change() -> save_session() against the OLD session's
        -- name (which would clobber the old session's file on disk
        -- with a half-torn-down or half-loaded layout).
        mark_unloaded()
        reset_editor_state()
        vim.cmd("silent! source " .. vim.fn.fnameescape(path))
        mark_loaded(name)
        vim.notify("Loaded session (autosave enabled): " .. name)
      end,
    },
  })
end

--- <leader>sd — Session Delete
-- Persistent multi-select fzf deleter: ctrl-x deletes the highlighted
-- entry/entries and reloads the list IN PLACE — the fzf window never
-- closes, so you can keep bulk-deleting until you hit <Esc>.
function M.session_delete()
  ensure_dir()
  local sessions = list_sessions()
  if #sessions == 0 then
    vim.notify("No sessions to delete", vim.log.levels.INFO)
    return
  end

  fzf.fzf_exec(sessions, {
    prompt = "Delete Session(s) <C-x>❯ ",
    fzf_opts = { ["--multi"] = "" },
    actions = {
      ["default"] = false, -- disable enter; this picker is delete-only
      ["ctrl-x"] = function(selected)
        if not selected or #selected == 0 then
          return
        end
        for _, name in ipairs(selected) do
          local path = session_path(name)
          if file_exists(path) then
            if vim.uv.fs_unlink(path) then
              if M.current_session == name then
                mark_unloaded()
              end
              vim.notify("Deleted session: " .. name)
            else
              vim.notify("Failed to delete: " .. name, vim.log.levels.ERROR)
            end
          end
        end
        -- Re-open the picker with the refreshed list immediately, so
        -- bulk-deleting feels continuous even though fzf itself can't
        -- truly "reload in place" from a static-table contents source.
        vim.schedule(M.session_delete)
      end,
    },
  })
end

-- ---------------------------------------------------------------------
-- Autocmds: structural add/remove events only, never plain navigation.
--   BufAdd     -> buffer newly added to the buffer list (:edit a new
--                 file). Never fires when switching to an already-
--                 listed buffer (that's BufEnter, deliberately unhooked).
--   BufDelete  -> buffer removed from the buffer list (:bdelete,
--                 closing the last window showing it via :q, etc).
--   WinNew     -> a split/vsplit is created. Never fires on <C-w>w
--                 focus changes.
--   WinClosed  -> a split/vsplit is closed.
--   TabNew     -> a new tab is created. Never fires on tabnext/tabprev.
--   TabClosed  -> a tab is closed.
-- ---------------------------------------------------------------------
local aug = vim.api.nvim_create_augroup("PuSessionTracking", { clear = true })

vim.api.nvim_create_autocmd("BufAdd", { group = aug, callback = on_change })
vim.api.nvim_create_autocmd("BufDelete", { group = aug, callback = on_change })
vim.api.nvim_create_autocmd("WinNew", { group = aug, callback = on_change })
vim.api.nvim_create_autocmd("WinClosed", { group = aug, callback = on_change })
vim.api.nvim_create_autocmd("TabNew", { group = aug, callback = on_change })
vim.api.nvim_create_autocmd("TabClosed", { group = aug, callback = on_change })

-- Final safety net: kill LSP clients / terminal jobs on quit so
-- nothing outlives nvim. Saves no longer need flushing here since
-- every change is already saved synchronously the moment it happens.
vim.api.nvim_create_autocmd("VimLeavePre", {
  group = aug,
  callback = kill_zombies,
})

-- Keymaps
vim.keymap.set("n", "<leader>sf", M.session_find, { desc = "Session: find/load" })
vim.keymap.set("n", "<leader>sc", M.session_create, { desc = "Session: create" })
vim.keymap.set("n", "<leader>sd", M.session_delete, { desc = "Session: delete (ctrl-x)" })

return M
