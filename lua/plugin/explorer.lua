-- ===========================
-- File Exploration & Navigation
-- ===========================
return {
  {
    "mikavilpas/yazi.nvim",
    version = "*",
    lazy = true,
    dependencies = {
      { "nvim-lua/plenary.nvim", lazy = true },
    },
    keys = {
      { ",", mode = { "n", "v" }, "<cmd>Yazi<cr>", desc = "Open yazi at current file" },
    },
    opts = {
      yazi_floating_window_border = "none", -- see border types below
      yazi_floating_window_winblend = 0, -- 0-100 transparency
      floating_window_scaling_factor = 1, -- window size %
      yazi_floating_window_zindex = 100,
      highlight_groups = {
        hovered_buffer = nil, -- customize hover highlight
        hovered_buffer_in_same_directory = nil,
      },
    },
    init = function()
      vim.g.loaded_netrwPlugin = 1
    end,
  },
  {
    "ibhagwan/fzf-lua",
    lazy = true,
  },
  {
    url = "https://codeberg.org/andyg/leap.nvim",
    lazy = true,
    keys = {
      { "m", "<Plug>(leap-forward)", mode = { "n", "x", "o" }, desc = "Leap forward" },
      { "M", "<Plug>(leap-backward)", mode = { "n", "x", "o" }, desc = "Leap backward" },
      { "gm", "<Plug>(leap-from-window)", mode = { "n" }, desc = "Leap from window" },
    },
    config = function()
      require("leap").setup({
        max_phase_one_targets = nil,
        max_highlighted_traversal_targets = 10,
        case_sensitive = false,
        equivalence_classes = { " \t\r\n" },
        substitute_chars = {},
        safe_labels = "sfnut/SFNLHMUGTZ?",
        labels = "sfnjklhodweimbuyvrgtaqpcxz/SFNJKLHODWEIMBUYVRGTAQPCXZ?",
        special_keys = {
          repeat_search = "<enter>",
          next_phase_one_target = "<enter>",
          next_target = { "<enter>", ";" },
          prev_target = { "<tab>", "," },
          next_group = "<space>",
          prev_group = "<tab>",
          multi_accept = "<enter>",
          multi_revert = "<backspace>",
        },
      })

      -- Restore highlighting for unlabeled phase-one targets (replaces removed option)
      require("leap").opts.on_beacons = function(targets)
        for _, t in ipairs(targets) do
          if not t.label and not t.beacon and t.chars and t.is_previewable ~= false then
            t.beacon = { 0, { virt_text = { { table.concat(t.chars), "LeapMatch" } } } }
          end
        end
      end
    end,
  },
  {
    "kdheepak/lazygit.nvim",
    lazy = true,
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = {
      { "<C-g>", "<cmd>LazyGitCurrentFile<cr>", desc = "Open Repo of current file" },
    },
    config = function()
      vim.g.lazygit_floating_window_winblend = 0
      vim.g.lazygit_floating_window_scaling_factor = 1
      vim.g.lazygit_floating_window_border_chars = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" }
      vim.g.lazygit_use_neovim_remote = 0 -- fallback to 0 if neovim-remote not installed
    end,
  },
}
