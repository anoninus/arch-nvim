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
  },
  config = function(_, opts)
    require("catppuccin").setup(opts)
  end,
}
