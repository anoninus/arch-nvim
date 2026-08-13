-- ═══════════════════════════════════════════════════════════════════════
-- Adaptive "pure" statusline — flat, minimal, high-contrast text segments
-- on a single background, separated by a thin muted divider. No powerline
-- blocks/arrows.
--
-- Unlike a hardcoded palette, every color here is *resolved* from the
-- active colorscheme's own highlight groups (DiagnosticError, Function,
-- String, Comment, StatusLine, ...) at colorscheme-load time. Swap themes
-- and the statusline re-tints itself automatically — no palette to keep
-- in sync, and it always matches whatever theme is loaded.
-- ═══════════════════════════════════════════════════════════════════════

-- Nerd font glyphs
local icons = {
  lsp = "Lsp 󱁤",
  error = "󰅚",
  warn = "󰀪",
  hint = "󰌵",
  info = "󰋼",
  macro = "󰘳",
  search = "",
  session_saved = " 󰄬",
  session_unsaved = " 󰆓",
  cursor = "",
  divider = "/",
}

-- ── Color resolution ─────────────────────────────────────────────────
-- Read `attr` ("fg"/"bg") off highlight group `name`, following links.
-- Returns a "#rrggbb" string, or nil if the group has no such attr.
local function hl_attr(name, attr)
  local ok, h = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  if ok and h and h[attr] then
    return string.format("#%06x", h[attr])
  end
  return nil
end

-- Try a prioritized list of highlight groups, return the first hit.
local function resolve(attr, group_names)
  for _, name in ipairs(group_names) do
    local c = hl_attr(name, attr)
    if c then
      return c
    end
  end
  return nil
end

-- Which real highlight groups back each semantic color. These are
-- standard groups every colorscheme defines (or links), so this works
-- across themes without ever naming a literal hex value.
local fg_groups = {
  base = { "StatusLine", "Normal" },
  dim = { "Comment", "NonText" },
  divider = { "Comment", "NonText" },
  lsp = { "Function", "Identifier" },
  macro = { "DiagnosticError", "ErrorMsg", "Error" },
  error = { "DiagnosticError", "ErrorMsg", "Error" },
  warn = { "DiagnosticWarn", "WarningMsg" },
  hint = { "DiagnosticHint" },
  info = { "DiagnosticInfo", "Special" },
  search = { "Constant", "Special" },
  session_saved = { "String", "DiagnosticOk" },
  session_unsaved = { "DiagnosticWarn", "WarningMsg" },

  mode_normal = { "Function", "Identifier" },
  mode_insert = { "String" },
  mode_visual = { "Statement", "Keyword" },
  mode_select = { "Constant" },
  mode_replace = { "DiagnosticError", "ErrorMsg", "Error" },
  mode_command = { "PreProc", "Type" },
  mode_prompt = { "DiagnosticHint" },
  mode_shellterm = { "Special" },
}

local bg_groups = { "StatusLine", "Normal" }

-- Per-mode display: label + semantic color key + icon. Keys are vim.fn.mode().
local mode_map = {
  ["n"] = { "NORMAL", "mode_normal", "" },
  ["no"] = { "O-PENDING", "mode_normal", "" },
  ["nov"] = { "O-PENDING", "mode_normal", "" },
  ["noV"] = { "O-PENDING", "mode_normal", "" },
  ["no\22"] = { "O-PENDING", "mode_normal", "" },
  ["niI"] = { "NORMAL", "mode_normal", "" },
  ["niR"] = { "NORMAL", "mode_normal", "" },
  ["niV"] = { "NORMAL", "mode_normal", "" },
  ["v"] = { "VISUAL", "mode_visual", "" },
  ["vs"] = { "VISUAL", "mode_visual", "" },
  ["V"] = { "V-LINE", "mode_visual", "" },
  ["Vs"] = { "V-LINE", "mode_visual", "" },
  ["\22"] = { "V-BLOCK", "mode_visual", "" },
  ["\22s"] = { "V-BLOCK", "mode_visual", "" },
  ["s"] = { "SELECT", "mode_select", "" },
  ["S"] = { "S-LINE", "mode_select", "" },
  ["\19"] = { "S-BLOCK", "mode_select", "" },
  ["i"] = { "INSERT", "mode_insert", "" },
  ["ic"] = { "INSERT", "mode_insert", "" },
  ["ix"] = { "INSERT", "mode_insert", "" },
  ["R"] = { "REPLACE", "mode_replace", "" },
  ["Rc"] = { "REPLACE", "mode_replace", "" },
  ["Rx"] = { "REPLACE", "mode_replace", "" },
  ["Rv"] = { "V-REPLACE", "mode_replace", "" },
  ["Rvc"] = { "V-REPLACE", "mode_replace", "" },
  ["Rvx"] = { "V-REPLACE", "mode_replace", "" },
  ["c"] = { "COMMAND", "mode_command", "" },
  ["cv"] = { "EX", "mode_command", "" },
  ["ce"] = { "EX", "mode_command", "" },
  ["r"] = { "PROMPT", "mode_prompt", "" },
  ["rm"] = { "MORE", "mode_prompt", "" },
  ["r?"] = { "CONFIRM", "mode_prompt", "" },
  ["!"] = { "SHELL", "mode_shellterm", "" },
  ["t"] = { "TERMINAL", "mode_shellterm", "" },
}

-- Flat, fixed-color segments: bold colored text on the base bg — no
-- pill/background block, so it stays legible against any theme.
local seg_defs = {
  { key = "lsp", name = "Lsp" },
  { key = "macro", name = "Macro" },
  { key = "error", name = "Error" },
  { key = "warn", name = "Warn" },
  { key = "hint", name = "Hint" },
  { key = "info", name = "Info" },
  { key = "search", name = "Search" },
  { key = "session_saved", name = "SessionSaved" },
  { key = "session_unsaved", name = "SessionUnsaved" },
}

-- Populated by set_statusline_colors(): key -> ready "%#Group#" string.
local seg_hl = {}

-- (Re)define statusline highlight groups by resolving colors from the
-- currently active colorscheme. Runs once at load and again on every
-- ColorScheme event, so switching themes re-tints the bar automatically.
local function set_statusline_colors()
  local bg = resolve("bg", bg_groups)
  local fg = resolve("fg", fg_groups.base)
  local fg_dark = resolve("fg", fg_groups.dim)
  local divider_fg = resolve("fg", fg_groups.divider)

  vim.api.nvim_set_hl(0, "SLBase", { fg = fg, bg = bg })
  vim.api.nvim_set_hl(0, "SLDefault", { fg = fg_dark, bg = bg })
  vim.api.nvim_set_hl(0, "SLDivider", { fg = divider_fg, bg = bg })
  -- Rightmost item: no bg block at all — inherits the statusline bg.
  vim.api.nvim_set_hl(0, "SLCursor", { fg = fg, bold = true })

  for _, def in ipairs(seg_defs) do
    local hl_name = "SL" .. def.name
    local color = resolve("fg", fg_groups[def.key])
    vim.api.nvim_set_hl(0, hl_name, { fg = color, bg = bg, bold = true })
    seg_hl[def.key] = "%#" .. hl_name .. "#"
  end

  -- Mode: bold colored text, no background block — just a bright label.
  for _, entry in pairs(mode_map) do
    local label, color_key = entry[1], entry[2]
    local color = resolve("fg", fg_groups[color_key])
    local hl_name = "SLMode" .. label:gsub("[^%a]", "")
    vim.api.nvim_set_hl(0, hl_name, { fg = color, bg = bg, bold = true })
  end
end

-- Render `content` in the flat segment style identified by `key`.
local function seg(key, content)
  return seg_hl[key] .. content .. "%#SLDefault#"
end

-- Thin, muted divider placed between visible segments.
local function divider()
  return "%#SLDivider#" .. icons.divider .. "%#SLDefault#"
end

set_statusline_colors()
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = set_statusline_colors,
})

-- Current mode, rendered as plain bold colored text (no block).
_G.get_mode = function()
  local m = vim.fn.mode()
  local entry = mode_map[m] or { "UNKNOWN", "dim", "" }
  local label, _, icon = entry[1], entry[2], entry[3]
  local hl_name = "%#SLMode" .. label:gsub("[^%a]", "") .. "#"

  return hl_name .. icon .. " " .. label .. "%#SLDefault#"
end

-- Redraw the statusline on every mode change so the label stays in sync.
local mode_grp = vim.api.nvim_create_augroup("StatuslineModeRefresh", { clear = true })
vim.api.nvim_create_autocmd({ "ModeChanged" }, {
  group = mode_grp,
  callback = function()
    vim.cmd("redrawstatus")
  end,
})

-- Get count of LSP servers attached to the current buffer
_G.get_lsp_count = function()
  return #vim.lsp.get_clients({ bufnr = 0 })
end

-- Redraw the statusline whenever LSP clients attach/detach, since
-- there's no per-second timer driving redraws — the count in
-- get_lsp_count() would otherwise go stale until some other redraw fired.
local lsp_grp = vim.api.nvim_create_augroup("StatuslineLspRefresh", { clear = true })
vim.api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
  group = lsp_grp,
  callback = function()
    vim.cmd("redrawstatus")
  end,
})

-- Get diagnostic counts (only shows items > 0)
_G.get_diagnostics = function()
  local s = vim.diagnostic.severity
  local e = #vim.diagnostic.get(0, { severity = s.ERROR })
  local w = #vim.diagnostic.get(0, { severity = s.WARN })
  local h = #vim.diagnostic.get(0, { severity = s.HINT })
  local i = #vim.diagnostic.get(0, { severity = s.INFO })

  local parts = {}
  if e > 0 then
    table.insert(parts, seg("error", icons.error .. " " .. e))
  end
  if w > 0 then
    table.insert(parts, seg("warn", icons.warn .. " " .. w))
  end
  if h > 0 then
    table.insert(parts, seg("hint", icons.hint .. " " .. h))
  end
  if i > 0 then
    table.insert(parts, seg("info", icons.info .. " " .. i))
  end

  if #parts == 0 then
    return ""
  end
  return table.concat(parts, " ")
end

-- Current macro recording register
_G.get_macro_recording = function()
  local reg = vim.fn.reg_recording()
  if reg == "" then
    return ""
  end
  return seg("macro", icons.macro .. " REC @" .. reg)
end

-- Force redraw on macro state changes
local macro_grp = vim.api.nvim_create_augroup("StatuslineMacroRefresh", { clear = true })
vim.api.nvim_create_autocmd({ "RecordingEnter", "RecordingLeave" }, {
  group = macro_grp,
  callback = function()
    vim.cmd("redrawstatus")
  end,
})

-- Session segment: reads the globals set by the separate session
-- manager module (lua/user/session.lua) —
--   _G.PuSessionLoaded  : false, or the loaded session's name (string)
--   _G.PuSessionUnsaved : true/false
-- Only ever renders anything when a session is actually loaded; an
-- unloaded state (PuSessionLoaded == false, or the global not yet
-- defined at all, e.g. session.lua hasn't been required yet) yields "".
_G.get_session = function()
  local name = _G.PuSessionLoaded
  if not name then
    return ""
  end

  local unsaved = _G.PuSessionUnsaved
  local key = unsaved and "session_unsaved" or "session_saved"
  local icon = unsaved and icons.session_unsaved or icons.session_saved

  return seg(key, "Session: " .. name .. icon .. " ")
end

-- Current search match count (e.g. 3/12), only shown while hlsearch
-- is active and a search pattern actually exists.
_G.get_search = function()
  if vim.v.hlsearch == 0 or vim.fn.getreg("/") == "" then
    return ""
  end
  local ok, result = pcall(vim.fn.searchcount, { maxcount = 999, timeout = 100 })
  if not ok or not result or result.total == 0 then
    return ""
  end
  return seg("search", icons.search .. " " .. result.current .. "/" .. result.total)
end

-- Smart indicator: the moment a "/" or "?" search is actually
-- triggered (not aborted), remove "S" from shortmess so Vim's native
-- "search hit BOTTOM, continuing at TOP" / count messages show too.
-- Left off by default so it doesn't clutter :messages otherwise.
local search_grp = vim.api.nvim_create_augroup("StatuslineSearchRefresh", { clear = true })
vim.api.nvim_create_autocmd("CmdlineLeave", {
  group = search_grp,
  pattern = { "/", "?" },
  callback = function()
    if vim.fn.getcmdline() ~= "" then
      vim.opt.shortmess:remove("S")
    end
    vim.cmd("redrawstatus")
  end,
})

-- Keep the count fresh as you jump between matches with n/N.
vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
  group = search_grp,
  callback = function()
    if vim.v.hlsearch == 1 then
      vim.cmd("redrawstatus")
    end
  end,
})

-- Build the full statusline string
_G.build_statusline = function()
  local mode = _G.get_mode()
  local macro = _G.get_macro_recording()
  local lsp = seg("lsp", icons.lsp .. " " .. _G.get_lsp_count())
  local diag = _G.get_diagnostics()
  local search = _G.get_search()
  local session = _G.get_session()
  local cursor = "%#SLCursor#" .. icons.cursor .. " %l:%c"

  local left = { mode }
  if macro ~= "" then
    table.insert(left, macro)
  end
  table.insert(left, lsp)
  if diag ~= "" then
    table.insert(left, diag)
  end
  if search ~= "" then
    table.insert(left, search)
  end
  if session ~= "" then
    table.insert(left, session)
  end

  local left_str = table.concat(left, " " .. divider() .. " ")

  return "%#SLBase# " .. left_str .. "%=" .. cursor .. " "
end

vim.o.statusline = "%!v:lua.build_statusline()"

