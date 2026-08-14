vim.lsp.config("cssls", {
  cmd = { "vscode-css-language-server", "--stdio" },
  filetypes = { "css", "scss", "less" },
  root_markers = { "package.json", ".git", ".editorconfig" },

  capabilities = (function()
    local caps = vim.lsp.protocol.make_client_capabilities()
    caps.textDocument.completion.completionItem.snippetSupport = true
    caps.textDocument.completion.completionItem.resolveSupport = {
      properties = { "documentation", "detail", "additionalTextEdits" },
    }
    caps.textDocument.foldingRange = {
      dynamicRegistration = false,
      lineFoldingOnly = true,
    }
    return caps
  end)(),

  settings = {
    css = {
      validate = true,
      hover = { documentation = true, references = true },
      completion = {
        triggerPropertyValueCompletion = true,
        completePropertyWithSemicolon = true,
      },
      lint = {
        unknownProperties = "warning",
        unknownAtRules = "warning",
        duplicateProperties = "warning",
        emptyRules = "warning",
        importStatement = "warning",
        boxModel = "warning",
        universalSelector = "warning",
        zeroUnits = "warning",
        fontFaceProperties = "warning",
        hexColorLength = "error",
        argumentsInColorFunction = "error",
        unknownVendorSpecificProperties = "ignore",
        propertyIgnoredDueToDisplay = "warning",
        important = "warning",
        float = "warning",
        idSelector = "warning",
        vendorPrefix = "warning",
      },
    },
    scss = {
      validate = true,
      hover = { documentation = true, references = true },
      completion = {
        triggerPropertyValueCompletion = true,
        completePropertyWithSemicolon = true,
      },
      lint = {
        unknownProperties = "warning",
        unknownAtRules = "ignore", -- scss uses custom at-rules
        duplicateProperties = "warning",
        emptyRules = "warning",
        importStatement = "ignore", -- scss imports are valid
        boxModel = "warning",
        universalSelector = "warning",
        zeroUnits = "warning",
        fontFaceProperties = "warning",
        hexColorLength = "error",
        argumentsInColorFunction = "error",
        unknownVendorSpecificProperties = "ignore",
        propertyIgnoredDueToDisplay = "warning",
        important = "warning",
        float = "warning",
        idSelector = "warning",
        vendorPrefix = "warning",
      },
    },
    less = {
      validate = true,
      hover = { documentation = true, references = true },
      completion = {
        triggerPropertyValueCompletion = true,
        completePropertyWithSemicolon = true,
      },
      lint = {
        unknownProperties = "warning",
        unknownAtRules = "ignore",
        duplicateProperties = "warning",
        emptyRules = "warning",
        importStatement = "ignore",
        boxModel = "warning",
        universalSelector = "warning",
        zeroUnits = "warning",
        fontFaceProperties = "warning",
        hexColorLength = "error",
        argumentsInColorFunction = "error",
        unknownVendorSpecificProperties = "ignore",
        propertyIgnoredDueToDisplay = "warning",
        important = "warning",
        float = "warning",
        idSelector = "warning",
        vendorPrefix = "warning",
      },
    },
  },
})

vim.lsp.enable("cssls")
