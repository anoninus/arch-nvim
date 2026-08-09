-- ===========================
-- File Exploration & Navigation
-- ===========================
return {
  {
    "stevearc/oil.nvim",
    lazy = true,
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
    "NeogitOrg/neogit",
    lazy = true,
    cmd = "Neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = {
      {
        "gg",
        function()
          require("neogit").open({ cwd = vim.fn.expand("%:p:h") })
        end,
        desc = "Open Neogit (current file's dir)",
      },
    },
    config = function()
      require("neogit").setup({
        graph_style = "unicode",
        disable_commit_confirmation = false,
        integrations = {
          diffview = true, -- set false if you don't install diffview.nvim
          telescope = true, -- set false if you don't install telescope
        },
      })
    end,
  },
}
