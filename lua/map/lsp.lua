vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local bufnr = args.buf
    vim.keymap.set("n", "grr", function()
      require("fzf-lua").lsp_references({ async_or_timeout = true })
    end, { buffer = bufnr, desc = "LSP References (fzf-lua)" })
  end,
})
