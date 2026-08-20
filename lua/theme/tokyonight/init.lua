-- lua/colors/init.lua
--
-- A tiny, colorscheme-agnostic "variant manager".
--
-- Problem it solves:
--   Tokyonight (and similar themes) expose ONE `on_highlights` callback for
--   the whole plugin. Any hex you hardcode there applies to every style
--   (moon/storm/night/day), so "fixing" moon quietly breaks day.
--
-- Fix:
--   Each *variant* (e.g. "moon", "storm", "night", "day") is just:
--     { background = "dark"|"light", colorscheme = "tokyonight-moon", overrides = {...} }
--   `overrides` is a plain table of { GroupName = {fg=..., bg=..., ...} },
--   the same shape `nvim_set_hl` takes. It is applied with nvim_set_hl
--   *after* the colorscheme loads, and ONLY when that variant is active.
--   No plugin-specific API, no bleed-through between variants.
--
-- Usage: see lua/plugins/tokyonight.lua for a full example.

local M = {}

---@class ColorVariant
---@field name string
---@field background "dark"|"light"
---@field colorscheme string            -- what `:colorscheme` to run
---@field overrides table<string, table>? -- hl group name -> nvim_set_hl spec
---@field setup fun()?                  -- optional extra hook run after overrides

M.variants = {} ---@type table<string, ColorVariant>
M.current = nil ---@type string?
M.default_dark = nil ---@type string?
M.default_light = nil ---@type string?

local last = { dark = nil, light = nil } ---@type table<string, string?>

--- Apply a registered variant by name: sets background, loads the
--- colorscheme, then stamps on the variant's own highlight overrides.
---@param name string
function M.apply_variant(name)
  local v = M.variants[name]
  if not v then
    vim.notify(("colors: unknown variant '%s'"):format(name), vim.log.levels.ERROR)
    return
  end

  vim.o.background = v.background
  vim.cmd.colorscheme(v.colorscheme)

  if v.overrides then
    for group, spec in pairs(v.overrides) do
      vim.api.nvim_set_hl(0, group, spec)
    end
  end

  if v.setup then
    v.setup()
  end

  M.current = name
  last[v.background] = name

  vim.g.colors_variant = name
end

--- Switch background, reusing whichever variant was last active for that
--- background (falling back to the registered default).
---@param bg "dark"|"light"
function M.set_background(bg)
  local name = last[bg] or (bg == "dark" and M.default_dark or M.default_light)
  if not name then
    vim.notify(("colors: no variant registered for background=%s"):format(bg), vim.log.levels.WARN)
    return
  end
  M.apply_variant(name)
end

--- Flip between dark and light.
function M.toggle()
  local cur = M.variants[M.current]
  local next_bg = (cur and cur.background == "dark") and "light" or "dark"
  M.set_background(next_bg)
end

---@class ColorsSetupOpts
---@field variants ColorVariant[]
---@field default string?       -- variant name to activate on setup
---@field toggle_key string|false? -- default "<leader>bg", pass false to disable

---@param opts ColorsSetupOpts
function M.setup(opts)
  opts = opts or {}

  for _, v in ipairs(opts.variants or {}) do
    assert(v.name and v.background and v.colorscheme, "colors: variant needs name, background, colorscheme")
    M.variants[v.name] = v
    if v.background == "dark" and not M.default_dark then
      M.default_dark = v.name
    end
    if v.background == "light" and not M.default_light then
      M.default_light = v.name
    end
  end

  vim.api.nvim_create_user_command("ColorVariant", function(cmdopts)
    M.apply_variant(cmdopts.args)
  end, {
    nargs = 1,
    complete = function()
      return vim.tbl_keys(M.variants)
    end,
    desc = "Switch to a specific registered color variant",
  })

  local toggle_key = opts.toggle_key
  if toggle_key == nil then
    toggle_key = "<leader>bg"
  end
  if toggle_key then
    vim.keymap.set("n", toggle_key, M.toggle, { desc = "Toggle light/dark background" })
  end

  local start = opts.default or M.default_dark or M.default_light
  if start then
    M.apply_variant(start)
  end
end

return M
