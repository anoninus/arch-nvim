-- ============================
-- Fzf-lua setup
-- ============================
local function setup_fzf()
  require("fzf-lua").setup({
    file_icon_padding = " ",
    winopts = {
      height = 0.85,
      width = 0.80,
      row = 0.35,
      col = 0.50,
      border = "rounded",
      wrap = true,
      preview = {
        delay = 0,
        border = "rounded",
        wrap = "wrap",
        hidden = "nohidden",
        vertical = "down:45%",
        horizontal = "right:60%",
        layout = "flex",
        flip_columns = 120,
      },
    },
    fzf_opts = {
      ["--wrap"] = true,
    },
    fzf_colors = {
      true,
    },
    files = {
      prompt = " ",
      multiprocess = true,
      git_icons = true,
      file_icons = true,
      color_icons = true,
    },
    grep = {
      prompt = " ",
      input_prompt = "Grep  ",
      multiprocess = true,
      git_icons = true,
      file_icons = true,
      color_icons = true,
    },
  })
end

-- Setup fzf-lua on VimEnter
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    vim.schedule(setup_fzf)
  end,
})

require("lazyc.explore.fzf_map")
