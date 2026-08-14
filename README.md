# nvim

![GitHub last commit](https://img.shields.io/badge/status-active-brightgreen)
![Neovim](https://img.shields.io/badge/Neovim-0.10%2B-57A143?logo=neovim&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-blue)
![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20WSL-lightgrey)

## About

[!Important]
> Though the project is matured and updates very soon, I still need your help.
> Do help test the `config` on different platforms.

This config aims to give you a full IDE-like experience in Neovim, without the bloat.

## Features

| # | Feature | Details |
|---|---------|---------|
| 1 | Indentation | Mini indentation + indent blankline |
| 2 | Autosave | Saves your file every 150ms |
| 3 | Manual format | `;f` |
| 4 | Fullscreen terminal | Toggle with `<C-t>` |
| 5 | Fzf-lua integration | `f` + `f` for files, `f` + `g` for grep. Grep motions: `gl`, `gd`, `gb`, `ge`, `gf` |
| 6 | Quit | `<C-q>` |
| 7 | Yazi integration | Triggered with `,` |
| 8 | Sessions | `<Space>s` + key |
| 9 | System clipboard | Yank to system, paste from system |
| 10 | Tabline | Built in |
| 11 | Statusline | Prebuilt and useful out of the box |
| 12 | Self-contained modules | No unnecessary downloads |
| 13 | Continuous updates | Actively maintained |
| 14 | Prebaked LSPs | No Mason, no binary installs — Neovim manages the LSPs directly (see below) |
| 15 | Fast startup | Smart lazy-loading, loads after `VimEnter`. Uses 50–90% less disk space than a typical plugin setup |
| 16 | Session reload | Easily reload stale sessions |
| 17 | Clean UI | No unneeded popups or animations |
| 18 | Diagnostics panel | `<Shift-End>` opens diagnostics in a smart horizontal split. `<C-S-End>` shows workspace diagnostics via Fzf-lua |
| 19 | Small footprint | `~/.local/share/nvim/` stays around 60–80 MB, depending on how many Treesitter parsers you install |
| 20 | Lazy Treesitter | The Treesitter plugin doesn't load until you run `:TSInstall`. Installed parsers load after `VimEnter` |
| 21 | Fast jump | `m` and `M` |
| 22 | Theme | Tokyonight Moon, preinstalled |
| 23 | Autocomplete | Blink cmp + friendly-snippets + ultimate-autopairs |
| 24 | Mini clue | A which-key style hint for your next keypress |
| 25 | Nerd Font support | Built in |
| 26 | Lazygit | `<C-g>` |
| 27 | Mini move | Move blocks, selections, or the current line with `<M-Up/Down/Left/Right>` |
| 28 | Default formatting | Linebreak, wrap, and 2-space indent. Change this in `lua/sys/options.lua` |
| 29 | Nvim-surround | See its docs for usage |
| 30 | Undotree | `<Space>ut` |
| 31 | Vim visual multi | See its docs for usage |
| 32 | Conform.nvim | Used for formatting files |
| 33 | Crates.nvim | For Rust development |

### Prebaked LSPs

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

> 📌 **Note:** [GUIDE.md]() is meant for new maintainers only.

- Keymaps: [KEYS.md]()
- Project guide: [GUIDE.md]()
