-- lua/plugins/tokyonight.lua
return {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    -- `style` intentionally omitted: the variant manager picks the concrete
    -- flavor via `:colorscheme tokyonight-<variant>`, not this option.
    styles = {
      comments = { italic = false },
      keywords = { italic = false },
      functions = { italic = false },
      variables = { italic = false },
      sidebars = "dark",
      floats = "dark",
    },
    transparent = false,
    terminal_colors = true,
    dim_inactive = false,
    -- No on_highlights here on purpose — that's exactly the "hard override
    -- hits every variant" problem. All hl overrides now live per-variant
    -- in lua/colors/variants/*.lua and are applied by lua/colors/init.lua.
  },
  config = function(_, opts)
    require("tokyonight").setup(opts)

    require("theme.tokyonight").setup({
      variants = {
        {
          name = "moon",
          background = "dark",
          colorscheme = "tokyonight-moon",
          overrides = require("theme.tokyonight.tokyonight_moon"),
        },
        {
          name = "storm",
          background = "dark",
          colorscheme = "tokyonight-storm",
          overrides = require("theme.tokyonight.tokyonight_storm"),
        },
        {
          name = "night",
          background = "dark",
          colorscheme = "tokyonight-night",
          overrides = require("theme.tokyonight.tokyonight_night"),
        },
        {
          name = "day",
          background = "light",
          colorscheme = "tokyonight-day",
          overrides = require("theme.tokyonight.tokyonight_day"),
        },
      },
      default = "moon", -- what loads on startup
      toggle_key = "<leader>bg", -- flips dark <-> light, remembers last variant per side
    })
  end,
}
