-- =====================
-- (1) Bootstrap lazy.nvim
-- =====================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
-- =====================
-- Plugins (lazy.nvim)
-- =====================
require("lazy").setup({
  spec = {
    { import = "theme.tokyonight.install" },
    { import = "plugin.snippets" },
    { import = "plugin.completion" },
    { import = "plugin.formatting" },
    { import = "plugin.treesitter" },
    { import = "plugin.explorer" },
    { import = "plugin.editor" },
    { import = "plugin.utility" },
    { import = "plugin.mini" },
    { import = "plugin.autopairs" },
  },

  -- ============================
  -- Configuration
  -- ============================
  concurrency = 5,

  git = {
    timeout = 300,
    url_format = "https://github.com/%s.git",
  },

  install = {
    missing = true,
  },

  rocks = {
    enabled = false,
    hererocks = false,
  },

  checker = {
    enabled = false,
    notify = false,
    frequency = 3600,
  },

  change_detection = {
    enabled = false,
    notify = false,
  },

  performance = {
    cache = {
      enabled = true,
    },
    reset_packpath = true,
    rtp = {
      reset = true,
      paths = {},
    },
  },

  defaults = {
    lazy = true,
    version = false,
  },

  ui = {
    size = { width = 1, height = 1 },
    wrap = true,
    title = "   Lazy Plugin Manager ",
    backdrop = 70,
    icons = {
      cmd = "󰘳 ",
      config = "󰒓 ",
      event = "󰚌 ",
      ft = "󰈙 ",
      init = "󰒓 ",
      import = "󰋺 ",
      keys = "󰌌 ",
      lazy = "󰒲 ",
      loaded = "󰄬 ",
      not_loaded = "󰄱 ",
      plugin = "󰂖 ",
      runtime = "󰆦 ",
      source = "󰉋 ",
      start = "󰐊 ",
      task = "󰆕 ",
      list = { "󰬪", "󰬜", "󰬐", "󰬅" },
    },
  },
})
