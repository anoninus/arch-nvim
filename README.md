# nvim

![GitHub last commit](https://img.shields.io/badge/status-active-brightgreen)
![Neovim](https://img.shields.io/badge/Neovim-0.10%2B-57A143?logo=neovim&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-blue)
![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20WSL-lightgrey)

## About

> [!Important]
> Though the project is matured and updates very soon, I still need your help.
> Do help test the `config` on different platforms.

This config aims to give you a full IDE-like experience in Neovim, without the bloat.

## Features

| # | Feature | Details |
|---|---------|---------|
| 1 | Indentation | [mini.indentscope](https://github.com/echasnovski/mini.indentscope) + [indent-blankline.nvim](https://github.com/lukas-reineke/indent-blankline.nvim) |
| 2 | Autosave | Saves your file every 150ms |
| 3 | Manual format | `;f` via [conform.nvim](https://github.com/stevearc/conform.nvim) |
| 4 | Fullscreen terminal | Toggle with `<C-t>` |
| 5 | Fuzzy finder | [fzf-lua](https://github.com/ibhagwan/fzf-lua) — `f` + `f` for files, `f` + `g` for grep. Grep motions: `gl`, `gd`, `gb`, `ge`, `gf` |
| 6 | Quit | `<C-q>` |
| 7 | File manager | [yazi.nvim](https://github.com/mikavilpas/yazi.nvim), triggered with `,` |
| 8 | Sessions | `<Space>s` + key |
| 9 | System clipboard | Yank to system, paste from system |
| 10 | Tabline | Built in |
| 11 | Statusline | Prebuilt and useful out of the box |
| 12 | Self-contained modules | No unnecessary downloads |
| 13 | Continuous updates | Actively maintained |
| 14 | Prebaked LSPs | No Mason, no binary installs — Neovim manages the LSPs directly (see below) |
| 15 | Fast startup | Smart lazy-loading via [lazy.nvim](https://github.com/folke/lazy.nvim), loads after `VimEnter`. Uses 50–90% less disk space than a typical plugin setup |
| 16 | Session reload | Easily reload stale sessions |
| 17 | Clean UI | No unneeded popups or animations |
| 18 | Diagnostics panel | `<Shift-End>` opens diagnostics in a smart horizontal split. `<C-S-End>` shows workspace diagnostics via [fzf-lua](https://github.com/ibhagwan/fzf-lua) |
| 19 | Small footprint | `~/.local/share/nvim/` stays around 60–80 MB, depending on how many Treesitter parsers you install |
| 20 | Lazy Treesitter | [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) doesn't load until you run `:TSInstall`. Installed parsers load after `VimEnter` |
| 21 | Fast jump | `m` and `M` via [leap.nvim](https://github.com/ggandor/leap.nvim) |
| 22 | Theme | Tokyonight Moon, preinstalled |
| 23 | Autocomplete | [blink.cmp](https://github.com/Saghen/blink.cmp) + [friendly-snippets](https://github.com/rafamadriz/friendly-snippets) + [ultimate-autopair.nvim](https://github.com/altermo/ultimate-autopair.nvim) |
| 24 | Key hints | [mini.clue](https://github.com/echasnovski/mini.clue) — a which-key style hint for your next keypress |
| 25 | Nerd Font support | Via [mini.icons](https://github.com/echasnovski/mini.icons) |
| 26 | Lazygit | [lazygit.nvim](https://github.com/kdheepak/lazygit.nvim), `<C-g>` |
| 27 | Move lines/blocks | [mini.move](https://github.com/echasnovski/mini.move) — `<M-Up/Down/Left/Right>` in normal or visual mode |
| 28 | Default formatting | Linebreak, wrap, and 2-space indent. Change this in `lua/sys/options.lua` |
| 29 | Surround text | [nvim-surround](https://github.com/kylechui/nvim-surround) — see its docs for usage |
| 30 | Undo history | [undotree](https://github.com/mbbill/undotree), `<Space>ut` |
| 31 | Multi-cursor editing | [vim-visual-multi](https://github.com/mg979/vim-visual-multi) — see its docs for usage |
| 32 | Formatter engine | [conform.nvim](https://github.com/stevearc/conform.nvim) |
| 33 | Rust tooling | [crates.nvim](https://github.com/saecki/crates.nvim) |
| 34 | Auto-close tags | [nvim-ts-autotag](https://github.com/windwp/nvim-ts-autotag) for HTML/JSX/TSX |

## Plugins

21 plugins total, kept lean through lazy-loading.

| Plugin | Loads on |
|--------|----------|
| [blink.cmp](https://github.com/Saghen/blink.cmp) | `InsertEnter` |
| [friendly-snippets](https://github.com/rafamadriz/friendly-snippets) | with blink.cmp |
| [fzf-lua](https://github.com/ibhagwan/fzf-lua) | command / session config |
| [indent-blankline.nvim](https://github.com/lukas-reineke/indent-blankline.nvim) | with mini.indent |
| [lazy.nvim](https://github.com/folke/lazy.nvim) | startup |
| [lazygit.nvim](https://github.com/kdheepak/lazygit.nvim) | `<C-g>` |
| [mini.clue](https://github.com/echasnovski/mini.clue) | with mini clues module |
| [mini.icons](https://github.com/echasnovski/mini.icons) | startup |
| [mini.indentscope](https://github.com/echasnovski/mini.indentscope) | with mini.indent |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | `:TSInstall` / `:lua` |
| [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) | with lazygit.nvim |
| [ultimate-autopair.nvim](https://github.com/altermo/ultimate-autopair.nvim) | `InsertEnter` |
| [conform.nvim](https://github.com/stevearc/conform.nvim) | `;f` |
| [crates.nvim](https://github.com/saecki/crates.nvim) | `BufRead Cargo.toml` |
| [leap.nvim](https://github.com/ggandor/leap.nvim) | `m`, `M`, `gm` |
| [mini.move](https://github.com/echasnovski/mini.move) | `<A-h/j/k/l>` (normal & visual) |
| [nvim-surround](https://github.com/kylechui/nvim-surround) | `ys`, `ds`, `cs`, `<C-s>` (visual) |
| [nvim-ts-autotag](https://github.com/windwp/nvim-ts-autotag) | TypeScript, HTML, JavaScript files |
| [undotree](https://github.com/mbbill/undotree) | `<leader>ut` |
| [vim-visual-multi](https://github.com/mg979/vim-visual-multi) | `<C-n>`, `<C-Up>`, `<C-Down>` (normal & visual) |
| [yazi.nvim](https://github.com/mikavilpas/yazi.nvim) | `,` / `:Yazi` |

### Prebaked LSPs

> [!Important]
> Check docs about adding new server : [Servers]()

```lua
lua        = "server.HighLevel.lua_ls",
python     = "server.HighLevel.pyright",
c          = "server.LowLevel.clang",
cpp        = "server.LowLevel.clang",
rust       = "server.LowLevel.rust_analyzer",
zig        = "server.LowLevel.zls",
json       = "server.Utilities.jsonls",
css        = "server.Web.css_ls",
scss       = "server.Web.css_ls",
html       = "server.Web.html",
typescript = "server.Web.ts_ls",
javascript = "server.Web.ts_ls",
go         = "server.Web.gopls",
```

## Install

### Mirrors

| Host | Link |
|------|------|
| GitHub | https://github.com/syfos/nvim |
| GitLab | https://gitlab.com/pudep/nvim |

### Clone

**From GitHub:**
```bash
git clone --depth 1 git@github.com:pudep/nvim.git ~/.config/nvim
```

**From GitLab:**
```bash
git clone --depth 1 git@gitlab.com:pudep/nvim.git ~/.config/nvim
```

## Documentation

> 📌 **Note:** [GUIDE.md]() is meant for new maintainers  and those who will modify the `config`.

- Keymaps: [KEYS.md]()
- Project guide: [GUIDE.md]()
