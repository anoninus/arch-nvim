-- ============================
-- PATH augmentation
--
-- Ensures common per-tool bin dirs (rustup/cargo, npm global, go)
-- are reachable from Neovim even when it's launched in an
-- environment that didn't source your shell's rc files (GUI
-- launchers, tmux without login shell, systemd units, Termux
-- widgets, etc). No-op if everything's already on $PATH.
-- ============================
do
  local function is_windows()
    return vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
  end

  local function is_termux()
    return vim.env.TERMUX_VERSION ~= nil or (vim.env.PREFIX ~= nil and vim.env.PREFIX:match("com%.termux") ~= nil)
  end

  local ok, home = pcall(function()
    return vim.uv.os_homedir()
  end)
  if not ok or not home or home == "" then
    home = vim.env.HOME
  end

  if home and home ~= "" then
    local sep = is_windows() and ";" or ":"

    local candidates = {}
    if is_termux() then
      table.insert(candidates, "/data/data/com.termux/files/usr/bin")
    end
    vim.list_extend(candidates, {
      vim.fs.joinpath(home, ".cargo", "bin"),
      vim.fs.joinpath(home, ".npm-global", "bin"),
      vim.fs.joinpath(home, "go", "bin"),
    })

    local path = vim.env.PATH or ""

    -- Index what's already present so re-sourcing this file (config
    -- reload, multiple init files, etc) never duplicates entries.
    local existing = {}
    for entry in path:gmatch("[^" .. sep .. "]+") do
      existing[entry] = true
    end

    local to_add = {}
    for _, dir in ipairs(candidates) do
      -- Only add dirs that actually exist and aren't already there;
      -- keeps $PATH clean instead of accumulating dead entries.
      if not existing[dir] and vim.fn.isdirectory(dir) == 1 then
        table.insert(to_add, dir)
      end
    end

    if #to_add > 0 then
      vim.env.PATH = table.concat(to_add, sep) .. sep .. path
    end
  end
end
