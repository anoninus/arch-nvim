vim.pack.add({ "https://github.com/folke/tokyonight.nvim" })
require("tokyonight").setup({
  style = "moon",
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
  on_highlights = function(hl)
    hl.NormalFloat = { bg = "#1a1b26" }
    hl.FloatBorder = { fg = "#65bcff", bg = "#1a1b26", bold = true }
    hl.FloatShadowThrough = { bg = "#222436" }
    hl.FloatShadow = { bg = "#222436" }
    hl.FloatTitle = { bg = "#65bcff", fg = "#000000" }
    hl.FloatFooter = { bg = "#65bcff", fg = "#000000" }
    hl.Comment = { fg = "#809ab0", italic = false }
    hl.LineNr = { fg = "#6b7a8e" }
    hl.LineNrAbove = { fg = "#6b7a8e" }
    hl.LineNrBelow = { fg = "#6b7a8e" }
    hl.MsgSeparator = { bg = "#809ab0" }
    hl.Statusline = { bg = "#222436" }
    hl.Search = { fg = "#1e2030", bg = "#ffc777", bold = true }
    hl.Search = { fg = "#1e2030", bg = "#e0a552", bold = true }
    hl.IncSearch = { fg = "#1e2030", bg = "#e0555f", bold = true }
    hl.CurSearch = { fg = "#1e2030", bg = "#e0754a", bold = true }
    hl.Cursor = { fg = "#1e2030", bg = "#ffffff", bold = true }
    hl.lCursor = { fg = "#1e2030", bg = "#ffffff", bold = true }
    hl.WinSeparator = { fg = "#65bcff", bold = true }
    hl.VertSplit = { fg = "#65bcff", bold = true }

    hl.WinSeparator = { fg = "#65bcff", bold = true }
    hl.VertSplit = { fg = "#65bcff", bold = true }

    hl.FzfLuaNormal = { bg = "#222436", fg = "#c8d3f5" }
    hl.FzfLuaFzfNormal = {bg = "#222436"}
    hl.FzfLuaFzfCursorLine = {bg = "#3b3c40"}
    hl.FzfLuaBorder = { fg = "#65bcff", bg = "#222436", bold = true }
    hl.FzfLuaTitle = { fg = "#222436", bg = "#65bcff", bold = true }
    hl.FzfLuaPreviewNormal = { bg = "#222436", fg = "#c8d3f5" }
    hl.FzfLuaPreviewBorder = { fg = "#65bcff", bg = "#222436", bold = true }
    hl.FzfLuaPreviewTitle = { fg = "#222436", bg = "#65bcff", bold = true }

    hl.BlinkCmpMenu = { bg = "#1e2030", fg = "#c8d3f5" }
    hl.BlinkCmpMenuBorder = { fg = "#65bcff", bg = "#1e2030", bold = true }
    hl.BlinkCmpMenuSelection = { bg = "#2d3f76", bold = true }

    hl.BlinkCmpLabel = { fg = "#c8d3f5" }
    hl.BlinkCmpLabelMatch = { fg = "#65bcff", bold = true }
    hl.BlinkCmpLabelDetail = { fg = "#545c7e" }
    hl.BlinkCmpLabelDescription = { fg = "#545c7e" }
    hl.BlinkCmpKind = { fg = "#65bcff" }

    hl.BlinkCmpDoc = { bg = "#000000", fg = "#c8d3f5" }
    hl.BlinkCmpDocBorder = { fg = "#545c7e", bg = "#000000", bold = true }
    hl.BlinkCmpDocSeparator = { fg = "#545c7e" }

    hl.BlinkCmpSignatureHelp = { bg = "#000000", fg = "#c8d3f5" }
    hl.BlinkCmpSignatureHelpBorder = { fg = "#545c7e", bg = "#000000", bold = true }
  end,
})
vim.cmd.colorscheme("tokyonight-moon")
