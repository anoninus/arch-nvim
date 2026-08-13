local disabled_filetypes = {
  "help",
  "alpha",
  "dashboard",
  "neo-tree",
  "lazy",
  "mason",
  "notify",
  "yazi",
  "fzf",
  "TelescopePrompt",
  "toggleterm",
}

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
      filetypes = disabled_filetypes,
      buftypes = { "terminal", "nofile", "quickfix", "prompt" },
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
  require("mini.indentscope").setup({
    symbol = "¦",
    options = {
      try_as_border = true,
    },
    mappings = {
      object_scope = "is",
      object_scope_with_border = "as",
    },
  })

  -- mini.indentscope has no native exclude list, so disable it manually
  vim.api.nvim_create_autocmd("FileType", {
    pattern = disabled_filetypes,
    callback = function()
      vim.b.miniindentscope_disable = true
    end,
  })

  -- Also catch terminal/prompt/nofile buffers (covers yazi.nvim & fzf-lua floats)
  vim.api.nvim_create_autocmd({ "TermOpen", "BufEnter" }, {
    callback = function(args)
      local buftype = vim.bo[args.buf].buftype
      if buftype == "terminal" or buftype == "nofile" or buftype == "prompt" then
        vim.b[args.buf].miniindentscope_disable = true
      end
    end,
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
