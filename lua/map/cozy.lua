vim.keymap.set('n', '<M-Up>', function()
  vim.diagnostic.jump({ count = -1, float = false })
end, { desc = 'Previous diagnostic' })

vim.keymap.set('n', '<M-Down>', function()
  vim.diagnostic.jump({ count = 1, float = false })
end, { desc = 'Next diagnostic' })
