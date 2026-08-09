local function setup_ibl()
  require("ibl").setup({
    indent = {
      char = "¦",
    },
    scope = {
      enabled = false,
      show_start = false,
      show_end = false,
    },
    exclude = {
      filetypes = {
        "help",
        "alpha",
        "dashboard",
        "neo-tree",
        "lazy",
        "mason",
        "notify",
        "terminal",
      },
    },
  })
end

local function setup_indentscope()
  require("mini.indentscope").setup({
    symbol = "¦",
    options = {
      try_as_border = true,
    },
    mappings = {
      object_scope = "is", -- Inner scope (replaces 'ii')
      object_scope_with_border = "as", -- Around scope (replaces 'ai')
    },
  })

  -- Link the line color to NonText
  -- vim.api.nvim_set_hl(0, "MiniIndentscopeSymbol", { link = "NonText" })
end


vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    vim.defer_fn(function()
      setup_ibl()
      setup_indentscope()
    end, 50)
  end,
})
