vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local bufnr = args.buf
    local fzf = require("fzf-lua")
    local opts = { async_or_timeout = true }

    vim.keymap.set("n", "grr", function()
      fzf.lsp_references(opts)
    end, { buffer = bufnr, desc = "LSP References (fzf-lua)" })

    vim.keymap.set("n", "gri", function()
      fzf.lsp_implementations(opts)
    end, { buffer = bufnr, desc = "LSP Implementations (fzf-lua)" })

    vim.keymap.set("n", "grt", function()
      fzf.lsp_typedefs(opts)
    end, { buffer = bufnr, desc = "LSP Type Definitions (fzf-lua)" })

    vim.keymap.set("n", "gra", function()
      fzf.lsp_code_actions(opts)
    end, { buffer = bufnr, desc = "LSP Code Actions (fzf-lua)" })


    vim.keymap.set("n", "grn", vim.lsp.buf.rename, { buffer = bufnr, desc = "LSP Rename" })
  end,
})
