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
