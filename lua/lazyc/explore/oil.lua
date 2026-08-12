-- lua/config/oil.lua
local function setup_oil()
end

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    vim.defer_fn(setup_oil, 50)
  end,
})
