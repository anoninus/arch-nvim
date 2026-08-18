-- lua/colors/variants/tokyonight_moon.lua
-- Highlight overrides that ONLY apply when the "moon" variant is active.
-- Ported 1:1 from the original on_highlights() block.

return {
  NormalFloat = { bg = "#1a1b26" },
  FloatBorder = { fg = "#65bcff", bg = "#1a1b26", bold = true },
  FloatShadowThrough = { bg = "#222436" },
  FloatShadow = { bg = "#222436" },
  FloatTitle = { bg = "#65bcff", fg = "#000000" },
  FloatFooter = { bg = "#65bcff", fg = "#000000" },

  Comment = { fg = "#a9b1d6", italic = false },

  LineNr = { fg = "#6b7a8e" },
  LineNrAbove = { fg = "#6b7a8e" },
  LineNrBelow = { fg = "#6b7a8e" },

  MsgSeparator = { bg = "#809ab0" },
  Statusline = { bg = "#222436" },

  Search = { fg = "#1e2030", bg = "#e0a552", bold = true },
  IncSearch = { fg = "#1e2030", bg = "#e0555f", bold = true },
  CurSearch = { fg = "#1e2030", bg = "#e0754a", bold = true },

  Cursor = { fg = "#1e2030", bg = "#ffffff", bold = true },
  lCursor = { fg = "#1e2030", bg = "#ffffff", bold = true },

  WinSeparator = { fg = "#65bcff", bold = true },
  VertSplit = { fg = "#65bcff", bold = true },

  FzfLuaNormal = { bg = "#222436", fg = "#c8d3f5" },
  FzfLuaFzfNormal = { bg = "#222436" },
  FzfLuaFzfCursorLine = { bg = "#2f334d" },
  FzfLuaBorder = { fg = "#65bcff", bg = "#222436", bold = true },
  FzfLuaTitle = { fg = "#222436", bg = "#65bcff", bold = true },
  FzfLuaPreviewNormal = { bg = "#222436", fg = "#c8d3f5" },
  FzfLuaPreviewBorder = { fg = "#65bcff", bg = "#222436", bold = true },
  FzfLuaPreviewTitle = { fg = "#222436", bg = "#65bcff", bold = true },

  BlinkCmpMenu = { bg = "#1e2030", fg = "#c8d3f5" },
  BlinkCmpMenuBorder = { fg = "#65bcff", bg = "#1e2030", bold = true },
  BlinkCmpMenuSelection = { bg = "#2d3f76", bold = true },

  BlinkCmpLabel = { fg = "#c8d3f5" },
  BlinkCmpLabelMatch = { fg = "#65bcff", bold = true },
  BlinkCmpLabelDetail = { fg = "#545c7e" },
  BlinkCmpLabelDescription = { fg = "#545c7e" },
  BlinkCmpKind = { fg = "#65bcff" },

  BlinkCmpDoc = { bg = "#000000", fg = "#c8d3f5" },
  BlinkCmpDocBorder = { fg = "#545c7e", bg = "#000000", bold = true },
  BlinkCmpDocSeparator = { fg = "#545c7e" },

  BlinkCmpSignatureHelp = { bg = "#000000", fg = "#c8d3f5" },
  BlinkCmpSignatureHelpBorder = { fg = "#545c7e", bg = "#000000", bold = true },
}
