-- vim thing
vim.o.mouse = ""
-- must load first
vim.loader.enable()
require("vim._core.ui2").enable()
require("startup")

-- your core
require("sys")
require("map")
require("plugin")

-- your local modules
require("module")

-- VimEnter Stuff
-- Load at last
require("server")
require("lazyc.mini.tabline_motion")

-- Lazy parsers
-- priority = last
require("treesitters.lazy")

-- lua/lazy/
require("lazyc.explore.oil")
require("lazyc.explore.fzf")
require("lazyc.mini.miniclues")
require("lazyc.mini.indent")

local state_file = vim.fn.stdpath('data') .. '/colorscheme_state'

local function pick_colorscheme(theme)
  vim.cmd.colorscheme(theme)
  local f = io.open(state_file, 'w')
  if f then f:write(theme); f:close() end
end

vim.api.nvim_create_user_command('pick', function(opts)
  pick_colorscheme(opts.args)
end, { nargs = 1, complete = 'color' })

-- restore saved theme on startup
local f = io.open(state_file, 'r')
if f then
  local theme = f:read('*l')
  f:close()
  if theme and theme ~= '' then
    pcall(vim.cmd.colorscheme, theme)
  end
end
