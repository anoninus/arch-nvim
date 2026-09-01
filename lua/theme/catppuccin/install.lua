return {
  "catppuccin/nvim",
  lazy = false,
  name = "catppuccin",
  priority = 900,
  opts = {
    flavour = "latte", -- latte, frappe, macchiato, mocha
    transparent_background = false,
    show_end_of_buffer = false,
    term_colors = true,
    dim_inactive = {
      enabled = false,
      shade = "dark",
      percentage = 0.15,
    },
    no_italic = true, -- forces no italics globally
    no_bold = false,
    no_underline = false,
    styles = {
      comments = {}, -- no italics on comments
      conditionals = {},
      loops = {},
      functions = {},
      keywords = {},
      strings = {},
      variables = {},
      numbers = {},
      booleans = {},
      properties = {},
      types = {},
      operators = {},
    },
    integrations = {
      cmp = true,
      gitsigns = true,
      nvimtree = true,
      treesitter = true,
      notify = false,
      mini = {
        enabled = true,
        indentscope_color = "",
      },
    },

    highlight_overrides = {
      latte = function(latte)
        return {
          MiniTablineCurrent = { bg = "#1e66f5", fg = "#eff1f5" },
          MiniTablineTabpagesection = { bg = "#fe640b", fg = "#eff1f5" },
          FloatTitle = { bg = "#1e66f5", fg = "#eff1f5" },
          Title = { bg = "#1e66f5", fg = "#eff1f5" },
          BlinkCmpMenuSelection = { bg = "#B9E1FF" },
          FzfLuaCursorLine = { bg = "#B9E1FF" },
          LeapBackdrop = { link = "Comment" },
        }
      end,
    },
  },
  config = function(_, opts)
    require("catppuccin").setup(opts)
  end,

  {
    "sainnhe/everforest",
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.everforest_background = "hard" -- "soft" | "medium" | "hard"
      vim.g.everforest_better_performance = 1

      -- disable italics globally
      vim.g.everforest_disable_italic_comment = 1

      vim.o.background = "dark"
      vim.cmd.colorscheme("everforest")
    end,
  },
}
