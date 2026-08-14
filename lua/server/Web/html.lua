vim.lsp.config("html", {
  cmd = { "vscode-html-language-server", "--stdio" },
  filetypes = { "html", "templ", "htmldjango", "jinja", "handlebars" },
  root_markers = { "package.json", ".git", ".editorconfig", "index.html" },

  capabilities = (function()
    local caps = vim.lsp.protocol.make_client_capabilities()
    caps.textDocument.completion.completionItem.snippetSupport = true
    caps.textDocument.completion.completionItem.preselectSupport = true
    caps.textDocument.completion.completionItem.insertReplaceSupport = true
    caps.textDocument.completion.completionItem.resolveSupport = {
      properties = { "documentation", "detail", "additionalTextEdits" },
    }
    caps.textDocument.completion.completionItem.labelDetailsSupport = true
    caps.textDocument.completion.completionItem.deprecatedSupport = true
    caps.textDocument.completion.completionItem.commitCharactersSupport = true
    caps.textDocument.completion.completionItem.tagSupport = {
      valueSet = { 1, 2 },
    }
    caps.textDocument.foldingRange = {
      dynamicRegistration = false,
      lineFoldingOnly = true,
    }
    return caps
  end)(),

  settings = {
    html = {
      hover = {
        documentation = true,
        references = true,
      },
      completion = {
        attributeDefaultValue = "doublequotes",
      },
      format = {
        enable = true,
        wrapLineLength = 120,
        unformatted = "wbr",
        contentUnformatted = "pre,code,textarea",
        indentInnerHtml = false,
        preserveNewLines = true,
        maxPreserveNewLines = nil,
        indentHandlebars = false,
        endWithNewline = true,
        extraLiners = "head, body, /html",
        wrapAttributes = "auto",
        wrapAttributesIndentSize = nil,
        templating = false,
        unformattedContentDelimiter = "",
      },
      validate = {
        scripts = true,
        styles = true,
      },
      autoClosingTags = true,
      autoCreateQuotes = true,
      mirrorCursorOnMatchingTag = true,
      suggest = {
        html5 = true,
      },
      customData = {},
    },
  },
})

vim.lsp.enable("html")
