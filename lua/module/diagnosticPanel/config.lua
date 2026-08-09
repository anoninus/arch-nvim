-- diagnostics_panel.lua
-- ~/.config/nvim/lua/diagnostics_panel.lua
-- require("diagnostics_panel").setup()
--
-- Hsplit-only diagnostics panel (botright split, height configurable).
--
-- While the panel is open:
--   <M-u>/<M-d>  scroll the panel without leaving your current window or
--                mode (works in normal AND insert mode)
--   <M-CR>       jump focus into the panel window
-- These three are global keymaps that simply no-op when the panel is closed.
--
-- The panel is IDE-like: it always lists diagnostics in ascending line
-- order (no reordering), and as you move the cursor it auto-scrolls to
-- keep the nearest diagnostic in view, marking its full block by
-- bolding the text (no background fill, no cursorline).
--
-- Requires a Nerd Font for the severity/marker glyphs below.

local M = {}

local SEV = vim.diagnostic.severity

local SEV_HL = {
  [SEV.ERROR] = "DiagnosticError",
  [SEV.WARN] = "DiagnosticWarn",
  [SEV.INFO] = "DiagnosticInfo",
  [SEV.HINT] = "DiagnosticHint",
}
local SEV_ICON = {
  [SEV.ERROR] = "",
  [SEV.WARN] = "",
  [SEV.INFO] = "",
  [SEV.HINT] = "",
}

-- Marker glyphs for the sector header: a filled chevron for the nearest
-- sector, a hollow one for everything else.
local CUR_MARKER = "󰮯"
local MARKER = "󰊠"

-- ── highlights ─────────────────────────────────────────────────────────────

local function setup_highlights()
  -- Header color for the nearest/current sector. Pick any hex you like,
  -- or swap back to `link = "Title"` (or another group) if you'd rather
  -- it track the colorscheme automatically. `bold = true` here is
  -- belt-and-suspenders — the whole sector already goes bold via
  -- DiagPanelActive in render() — but keeps the header bold on its own
  -- even if you ever strip that overlay.
  vim.api.nvim_set_hl(0, "DiagPanelCurLine", { fg = "#ffcc66", bold = true, default = true })
  -- Bright and distinct from DiagPanelCurLine on purpose: nearby/other
  -- sectors should still read clearly, not fade into Comment-gray.
  vim.api.nvim_set_hl(0, "DiagPanelHeading", { link = "Function", default = true })
  vim.api.nvim_set_hl(0, "DiagPanelMeta", { link = "Comment", default = true })
  -- Marks the nearest diagnostic block. Bold only, no bg/fg of its own,
  -- so it composites on top of whatever fg color (severity, heading,
  -- meta) is already on that text rather than replacing it.
  vim.api.nvim_set_hl(0, "DiagPanelActive", { bold = true, default = true })
  -- Thin divider between sectors.
  vim.api.nvim_set_hl(0, "DiagPanelSeparator", { link = "WinSeparator", default = true })
end

-- ── build ──────────────────────────────────────────────────────────────────
-- Plain layout, no box-drawing/tree connectors:
--    line 12
--        some message [lsp]
--        another message
--
-- Wrap is ON (see apply_win_opts): long messages are never cut off, they
-- just wrap onto extra visual rows. Entries are therefore never truncated
-- here any more — `width` is only used to size the separator rule.
-- breakindent (also set in apply_win_opts) keeps wrapped continuation
-- text lined up under the message instead of snapping back to col 0.
--
-- The nearest sector is marked by bolding its text (see render()), not a
-- background fill, which sidesteps the whole class of wrap/hl_eol edge
-- cases entirely: bold is a per-character attribute layered on top of
-- existing text, there's no "fill the rest of the row" step that can
-- come up short at a wrap point.

-- Finds the diagnostic line-group closest to cur_line (0 if cur_line has
-- diagnostics of its own, otherwise the nearest one above/below).
local function nearest_group(order, cur_line)
  local best, best_dist = nil, math.huge
  for _, ln in ipairs(order) do
    local dist = math.abs(ln - cur_line)
    if dist < best_dist then
      best, best_dist = ln, dist
    end
  end
  return best
end

local function build(diags, cur_line, width)
  local by_lnum, order = {}, {}
  for _, d in ipairs(diags) do
    local ln = d.lnum
    if not by_lnum[ln] then
      by_lnum[ln] = {}
      table.insert(order, ln)
    end
    table.insert(by_lnum[ln], d)
  end

  table.sort(order, function(a, b)
    return a < b
  end)

  local lines, hls, ranges = {}, {}, {}

  local function hl(row, cs, ce, grp)
    table.insert(hls, { row = row, col_s = cs, col_e = ce, grp = grp })
  end

  if #order == 0 then
    table.insert(lines, "  no diagnostics")
    hl(0, 0, #lines[1], "DiagPanelMeta")
    return lines, hls, ranges, nil
  end

  local sep = string.rep("─", width and width > 0 and width or 40)
  local nearest = nearest_group(order, cur_line)

  for i, ln in ipairs(order) do
    local is_nearest = ln == nearest
    local hdr = (is_nearest and CUR_MARKER or MARKER) .. " line " .. tostring(ln + 1)
    local start_row = #lines
    table.insert(lines, hdr)
    hl(start_row, 0, #hdr, is_nearest and "DiagPanelCurLine" or "DiagPanelHeading")

    for _, d in ipairs(by_lnum[ln]) do
      local msg = d.message:gsub("\n", " ")
      local src = d.source and ("  [" .. d.source .. "]") or ""
      local icon = SEV_ICON[d.severity] or "?"
      -- No truncate(): with wrap on, the full message just flows onto
      -- extra visual rows instead of being cut off.
      local entry = "    " .. icon .. " " .. msg .. src
      local erow = #lines
      table.insert(lines, entry)

      -- Nerd Font glyphs are multi-byte; size the highlight range off
      -- the icon's actual byte length rather than assuming 1 byte.
      hl(erow, 4, 4 + #icon, SEV_HL[d.severity] or "Normal")
      local src_s = #entry - #src
      if src ~= "" and src_s >= 0 and src_s <= #entry then
        hl(erow, src_s, #entry, "DiagPanelMeta")
      end
    end

    ranges[ln] = { start_row, #lines - 1 } -- {header_row, last_entry_row}

    if i < #order then
      local srow = #lines
      table.insert(lines, sep)
      hl(srow, 0, #sep, "DiagPanelSeparator")
    end
  end

  return lines, hls, ranges, nearest
end

-- ── panel state ────────────────────────────────────────────────────────────

local ns = vim.api.nvim_create_namespace("diag_panel")

local S = {
  bufnr = nil,
  winid = nil,
  src_winid = nil,
  diag_autocmd_id = nil, -- CursorMoved/DiagnosticChanged, scoped to current src buffer
  buf_watch_id = nil, -- BufEnter/BufWinEnter, watches src window for buffer switches
}

local function is_open()
  return S.bufnr and vim.api.nvim_buf_is_valid(S.bufnr) and S.winid and vim.api.nvim_win_is_valid(S.winid)
end

local function render(diags, cur_line)
  local width = is_open() and vim.api.nvim_win_get_width(S.winid) or nil
  local lines, hls, ranges, nearest = build(diags, cur_line, width)

  vim.bo[S.bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(S.bufnr, 0, -1, false, lines)
  vim.bo[S.bufnr].modifiable = false

  vim.api.nvim_buf_clear_namespace(S.bufnr, ns, 0, -1)
  for _, h in ipairs(hls) do
    vim.api.nvim_buf_add_highlight(S.bufnr, ns, h.grp, h.row, h.col_s, h.col_e)
  end

  if not (nearest and ranges[nearest]) then
    return
  end

  local start_row, end_row = ranges[nearest][1], ranges[nearest][2]

  -- Mark the nearest sector (header + every diagnostic on that line) by
  -- bolding its text — no background fill, no cursorline. DiagPanelActive
  -- only sets `bold`, so this composites on top of whatever fg color is
  -- already on that text (severity color, heading color, meta gray)
  -- instead of replacing it. Full line width (col 0 to end) so the whole
  -- row goes bold, including any part that wraps onto extra visual rows.
  for row = start_row, end_row do
    vim.api.nvim_buf_add_highlight(S.bufnr, ns, "DiagPanelActive", row, 0, -1)
  end

  -- Auto-scroll the panel to keep the nearest diagnostic in view,
  -- without stealing focus from wherever the user currently is.
  if is_open() then
    pcall(vim.api.nvim_win_set_cursor, S.winid, { start_row + 1, 0 })
    pcall(vim.api.nvim_win_call, S.winid, function()
      vim.cmd("normal! zz")
    end)
  end
end

local function refresh()
  if not is_open() then
    return
  end
  if not S.src_winid or not vim.api.nvim_win_is_valid(S.src_winid) then
    return
  end
  local src_buf = vim.api.nvim_win_get_buf(S.src_winid)
  local cur_line = vim.api.nvim_win_get_cursor(S.src_winid)[1] - 1
  local diags = vim.diagnostic.get(src_buf)
  table.sort(diags, function(a, b)
    if a.lnum ~= b.lnum then
      return a.lnum < b.lnum
    end
    return a.severity < b.severity
  end)
  render(diags, cur_line)
end

-- Rebinds the CursorMoved/DiagnosticChanged watcher to whatever buffer is
-- currently in the source window. Safe to call repeatedly.
local function attach_src_autocmds(src_buf)
  if S.diag_autocmd_id then
    pcall(vim.api.nvim_del_autocmd, S.diag_autocmd_id)
  end
  S.diag_autocmd_id = vim.api.nvim_create_autocmd({ "CursorMoved", "DiagnosticChanged" }, {
    buffer = src_buf,
    callback = refresh,
  })
end

-- ── shared buffer/window setup ────────────────────────────────────────────

local function make_buf()
  local bufnr = vim.api.nvim_create_buf(false, true) -- unlisted, scratch
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].filetype = "diagnostics_panel"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  return bufnr
end

local function apply_win_opts(winid)
  vim.wo[winid].number = false
  vim.wo[winid].relativenumber = false
  vim.wo[winid].signcolumn = "no"
  -- wrap/linebreak ON: long messages wrap onto extra visual rows instead
  -- of being cut off (see build(), which no longer truncates). linebreak
  -- wraps at word boundaries rather than mid-word. breakindent keeps the
  -- wrapped continuation lined up under the entry's own indent instead
  -- of restarting at column 0. None of this needs special-casing for the
  -- sector marker any more since it's just bold text (see render()).
  vim.wo[winid].wrap = true
  vim.wo[winid].linebreak = true
  vim.wo[winid].breakindent = true
  vim.wo[winid].breakindentopt = "shift:2"
  vim.wo[winid].cursorline = false
end

-- ── close ──────────────────────────────────────────────────────────────────

local function close()
  if S.diag_autocmd_id then
    pcall(vim.api.nvim_del_autocmd, S.diag_autocmd_id)
    S.diag_autocmd_id = nil
  end
  if S.buf_watch_id then
    pcall(vim.api.nvim_del_autocmd, S.buf_watch_id)
    S.buf_watch_id = nil
  end

  if S.winid and vim.api.nvim_win_is_valid(S.winid) then
    vim.api.nvim_win_close(S.winid, true)
  end

  if S.bufnr and vim.api.nvim_buf_is_valid(S.bufnr) then
    pcall(vim.api.nvim_buf_delete, S.bufnr, { force = true })
  end

  S.bufnr = nil
  S.winid = nil
  S.src_winid = nil
end

-- ── open ───────────────────────────────────────────────────────────────────

local function open(height)
  local src_win = vim.api.nvim_get_current_win()
  local src_buf = vim.api.nvim_get_current_buf()

  S.src_winid = src_win
  S.bufnr = make_buf()

  vim.cmd("botright " .. height .. "split")
  S.winid = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(S.winid, S.bufnr)

  apply_win_opts(S.winid)
  vim.wo[S.winid].winfixheight = true

  local km = function(lhs, rhs)
    vim.keymap.set("n", lhs, rhs, { buffer = S.bufnr, silent = true })
  end
  km("q", close)
  km("<Esc>", close)

  attach_src_autocmds(src_buf)

  -- Watches the source window (not a specific buffer) so that switching
  -- buffers there (:bnext, jumping to a file, etc.) re-syncs the panel
  -- to whatever buffer is now showing, instead of going stale.
  S.buf_watch_id = vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
    callback = function()
      if not is_open() then
        return
      end
      if vim.api.nvim_get_current_win() ~= S.src_winid then
        return
      end
      attach_src_autocmds(vim.api.nvim_win_get_buf(S.src_winid))
      refresh()
    end,
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(src_win),
    once = true,
    callback = close,
  })

  vim.api.nvim_set_current_win(src_win)
  refresh() -- initial render + auto-scroll to the nearest diagnostic
end

-- ── panel-scroll / jump-in helpers ──────────────────────────────────────────
-- Scroll the panel window in place via nvim_win_call so focus/mode never
-- changes on the caller's end (works while typing in insert mode too).

local function scroll(key)
  if not is_open() then
    return
  end
  local termkey = vim.api.nvim_replace_termcodes(key, true, false, true)
  vim.api.nvim_win_call(S.winid, function()
    vim.cmd("normal! " .. termkey)
  end)
end

local function jump_in()
  if not is_open() then
    return
  end
  if vim.fn.mode() == "i" then
    vim.cmd("stopinsert")
  end
  vim.api.nvim_set_current_win(S.winid)
end

-- ── setup ──────────────────────────────────────────────────────────────────

function M.setup(opts)
  opts = opts or {}
  local height = opts.height or 10

  setup_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_highlights })
  vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
    callback = function()
      if is_open() then
        refresh()
      end
    end,
  })

  vim.keymap.set("n", opts.keymap or "<S-End>", function()
    if is_open() then
      close()
    else
      open(height)
    end
  end, { silent = true, desc = "Toggle Diagnostic Panel" })

  vim.keymap.set("n", "<C-S-End>", "<cmd>FzfLua diagnostics_workspace<cr>", { desc = "Workspace diagnostics" })

  -- Conditional: these are always bound, but only do anything while the
  -- panel is open. Bound in both normal and insert mode.
  vim.keymap.set({ "n", "i" }, "<M-d>", function()
    scroll("<C-e>")
  end, { silent = true, desc = "Scroll diagnostics panel down" })

  vim.keymap.set({ "n", "i" }, "<M-u>", function()
    scroll("<C-y>")
  end, { silent = true, desc = "Scroll diagnostics panel up" })

  -- Note: Alt+Enter is <M-CR> in Neovim's keycode notation, not <M-Enter>.
  vim.keymap.set({ "n", "i" }, "<M-CR>", jump_in, { silent = true, desc = "Jump into diagnostics panel" })
end

return M

