-- ===========================
-- Completion (load on insert)
-- ===========================
return {
  {
    "saghen/blink.cmp",
    dependencies = { "rafamadriz/friendly-snippets" },
    event = { "InsertEnter", "CmdlineEnter" },
    version = "1.*",

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      keymap = {
        preset = "default",
      },

      appearance = {
        nerd_font_variant = "mono",
      },

      completion = {
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
          window = {
            max_width = 60,
            max_height = 12, -- caps height so it can't eat the whole screen
            -- border = "rounded", -- no padding/border = less wasted space
            winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder",
            direction_priority = {
              menu_north = { "n", "s" },
              menu_south = { "n", "s" },
            },
          },
        },

        menu = {
          max_height = 8, -- height of items to display
          -- border = "rounded",
          winhighlight = "Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None",
          draw = {
            columns = { { "kind_icon" }, { "label", gap = 1 } }, -- drop label_description
            components = {
              label = {
                width = { fill = true, max = 40 }, -- cap label width
                text = function(ctx)
                  -- show only the label, not the detail (signature body)
                  return ctx.label
                end,
              },
            },
          },
        },
      },

      sources = {
        default = { "lsp", "path" },
        per_filetype = {
          rust = { "lsp", "path" },
          zig = { "lsp", "path" },
          html = { "lsp", "path", "snippets" },
        },
      },

      fuzzy = { implementation = "prefer_rust" },

      cmdline = {
        keymap = { preset = "inherit" },
        completion = {
          menu = { auto_show = true },
        },
      },
    },

    opts_extend = { "sources.default" },

    config = function(_, opts)
      require("blink.cmp").setup(opts)

      -- now blink is loaded, safe to merge capabilities
      local base = vim.lsp.protocol.make_client_capabilities()
      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(base),
      })
    end,
  },
}
