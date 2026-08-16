# Neovim Keymaps

This table was created by Claude ai after reading 408 lines of keymapping (including blank lines).

The raw data was derived through this: [command](../get_all_keymaps.cmd).

| Mode(s) | Key | Job / Description |
|---|---|---|
| n | `fl` | Files: launch pwd/root |
| n | `fb` | Files: buffer root/dir |
| n | `fh` | Files: $HOME |
| n | `fc` | Files: nvimrc / config |
| n | `fo` | Files: oldfiles |
| n | `gl` | Grep: launch pwd/root |
| n | `gb` | Grep: buffer root/dir |
| n | `gf` | Grep: current buffer |
| n | `fd` | Files: pick dir from disk, find inside |
| n | `gd` | Grep: pick dir from disk, grep inside |
| n, t | `<C-k>` | Previous tab |
| n, t | `<C-j>` | Next tab |
| n | `<Leader>bs` | Buffer Save [Only for Oil etc buffers] |
| n | `<Leader>bc` | Buffer Remove data [!RISKY!] |
| n | `<Leader>bd` | Buffer Close [SAFE] |
| n | `<Leader>bb` | Pick buffer (FzfLua buffers) |
| n | `<Leader>rr` | Restart (Save & Restore Session) |
| n | `<Leader>rs` | Restart Safely (Fails if Unsaved) |
| n | `<Leader>rf` | Restart & Discard Unsaved Changes |
| n | `<Leader>qq` | Quit |
| n | `<Leader>qfq` | Force Quit |
| n | `<Leader>qfa` | Quit All |
| n | `<Leader>qfw` | Force Quit All |
| n | `<Leader>un` | Toggle Line Numbers |
| n | `<Leader>ur` | Toggle Relative Numbers |
| n | `<Leader>uw` | Toggle Word Wrap |
| n | `<Leader>uc` | Toggle Cursor Line |
| n | `<Leader>uh` | Toggle Highlight Search |
| n | `<Space>uc` | Clear search (register & highlight) |
| n | `<Leader>ws` | Save All |
| n | `<Leader>wq` | Save & Quit |
| n | `<Leader>wfs` | Force Save |
| n | `<Leader>wfS` | Force Save All |
| n | `<Leader>wfa` | Force Save & Quit All |
| n | `<Leader>ya` | Yank All (whole buffer to clipboard) |
| n | `<Leader>yp` | Yank File Path |
| n | `<Leader>lp` | Lazy: Profile |
| n | `<Leader>li` | Lazy: Install |
| n | `<Leader>lr` | Lazy: Restore |
| n | `<Leader>ls` | Lazy: Sync |
| n | `<Leader>lh` | Lazy: Home |
| n | `<Leader>lu` | Lazy: Update |
| n | `;li` | Open LSP log file |
| v, x | `<Leader>y` | Yank to Clipboard |
| n | `<M-Up>` | Previous diagnostic |
| n | `<M-Down>` | Next diagnostic |
| n (buffer, LSP) | `grr` | LSP References (fzf-lua) |
| n (buffer, LSP) | `gri` | LSP Implementations (fzf-lua) |
| n (buffer, LSP) | `grt` | LSP Type Definitions (fzf-lua) |
| n (buffer, LSP) | `gra` | LSP Code Actions (fzf-lua) |
| n (buffer, LSP) | `grn` | LSP Rename |
| n, v | `q` | Disabled (`<nop>`) |
| n | `<M-t>` | Disabled (`<nop>`), later reassigned below |
| n | `<M-r>` | Start macro recording (feeds `q` if not already recording) |
| n | `<M-t>` | Stop macro recording if recording, else send `<Esc>` |
| i, v | `<End>` | Go to end of display line (`g$`) |
| i | `<End>` | End of display line, insert mode (`<C-o>g$`) |
| i | `<Up>` | Move up a display line, insert mode (`<C-o>gk`) |
| i | `<Down>` | Move down a display line, insert mode (`<C-o>gj`) |
| n, v | `<Up>` | Move up a display line (`g<Up>`) |
| n, v | `<Down>` | Move down a display line (`g<Down>`) |
| n | `<C-q>` | Disabled (`<nop>`), then reassigned to Quit |
| n | `<C-q>` | Quit |
| n, i, v | `<M-,>` | Move current buffer tab left (MiniTabline) |
| n, i, v | `<M-.>` | Move current buffer tab right (MiniTabline) |
| n, i, v | `<PageDown>` | Go to previous tab, visual order (MiniTabline) |
| n, i, v | `<PageUp>` | Go to next tab, visual order (MiniTabline) |
| n (buffer, dynamic) | `lhs` (variable) | Dynamic buffer-local keymap set via config loop |
| n, i | `<S-End>` (or custom `opts.keymap`) | Toggle Diagnostic Panel |
| n | `<C-S-End>` | Workspace diagnostics (FzfLua) |
| n, i | `<M-d>` | Scroll diagnostics panel down |
| n, i | `<M-u>` | Scroll diagnostics panel up |
| n, i | `<M-CR>` | Jump into diagnostics panel |
| n | `<leader>zz` | [runner] Run current file. (Currently inactive)|
| n | `<leader>zx` | [runner] Toggle runner terminal |
| n | `<leader>sf` | Session: find/load |
| n | `<leader>sc` | Session: create |
| n | `<leader>sd` | Session: delete (ctrl-x) |
| n, t | `<C-t>` | Toggle listed terminal |
| t (buffer) | `<S-Tab>` | Exit terminal mode |
| v | `<C-s>` | Add surround (`nvim-surround-visual`) |
| n (special buffer) | `q` | Previous buffer (`<cmd>bprev<cr>`) |
| n | `;ll` | Toggle/open LSP log JSON file |
| n | `<C-f>` | Scroll hover down (falls back to `<C-f>` if no hover) |
| n | `<C-b>` | Scroll hover up (falls back to `<C-b>` if no hover) |
| n | `<leader>ui` | Toggle Inlay Hints |
| n (filetype: rust) | `<leader>zc` | Cargo check |
| n (filetype: rust) | `<leader>zC` | Cargo clean |
| n (filetype: rust) | `<leader>zz` | Cargo run |
| n (filetype: rust) | `<leader>zb` | Cargo build |
| n (filetype: rust) | `<leader>zu` | Cargo update |
| n (filetype: rust) | `<leader>zr` | Cargo reload |
| n (filetype: go) | `<leader>zz` | Go run (`go run .`) |
| n (filetype: go) | `<leader>zb` | Go build (`go build .`) |
| n (filetype: go) | `<leader>zt` | Go test (`go test .`) |
| n (filetype: go) | `<leader>zT` | Go test all (`go test ./...`) |
| n (filetype: go) | `<leader>zm` | Go mod tidy |
| n (filetype: go) | `<leader>zv` | Go vet |
| n | `<leader>yc` | Copy yank register to system clipboard |
| v | `<leader>yc` | Copy visual selection to system clipboard |
| n | `<leader>ym` | Copy motion to system clipboard (operator function) |
| n | `;` | Disabled (`<Nop>`) |
| n | `\|` | Disabled (`<Nop>`) |
| n | `=` | Disabled (`<Nop>`) |
| n | `,` | Disabled (`<Nop>`) |
| n | `<leader>pc` | Paste from system clipboard |

