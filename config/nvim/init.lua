-- ~/.config/nvim/init.lua
-- Lean Neovim setup for Zig. Native LSP (ZLS) + completion + treesitter.

-- Leader must be set before lazy loads anything that maps keys.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- nvim-tree replaces the built-in file explorer; disable netrw so the two
-- don't both try to handle directory arguments.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- ── Editor options ─────────────────────────────────────────────────────────
local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.expandtab = true        -- Zig uses spaces
opt.shiftwidth = 4
opt.tabstop = 4
opt.smartindent = true
opt.signcolumn = "yes"      -- stop the gutter from jumping when diagnostics appear
opt.termguicolors = true
opt.undofile = true         -- persistent undo
opt.ignorecase = true
opt.smartcase = true
opt.updatetime = 250        -- snappier diagnostics / CursorHold
opt.completeopt = "menu,menuone,noselect"
opt.scrolloff = 6
opt.clipboard = "unnamedplus"

-- ── Bootstrap lazy.nvim ──────────────────────────────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins")

-- ── Diagnostics presentation ─────────────────────────────────────────────────
vim.diagnostic.config({
  virtual_text = true,
  severity_sort = true,
  float = { border = "rounded", source = true },
})

-- ── LSP: ZLS via the native vim.lsp API (Neovim 0.11+) ───────────────────────
-- Merge nvim-cmp's completion capabilities so the server advertises snippets etc.
local ok_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
local capabilities = ok_cmp and cmp_lsp.default_capabilities() or vim.lsp.protocol.make_client_capabilities()

vim.lsp.config("zls", {
  cmd = { "zls" },
  filetypes = { "zig", "zon" },
  root_markers = { "build.zig", "build.zig.zon", ".git" },
  capabilities = capabilities,
  settings = {
    zls = {
      enable_build_on_save = true,
      -- Let ZLS surface compile errors from the build system, not just parse errors.
      build_on_save_step = "install",
    },
  },
})
vim.lsp.enable("zls")

-- ── LSP: Pyright (Python) ────────────────────────────────────────────────────
-- Binary comes from Mason (:Mason -> pyright). Use the absolute path because
-- Mason is lazy-loaded and its bin dir is not on PATH until it loads.
vim.lsp.config("pyright", {
  cmd = { vim.fn.stdpath("data") .. "/mason/bin/pyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "pyrightconfig.json", ".git" },
  capabilities = capabilities,
  settings = {
    python = { analysis = { autoSearchPaths = true, useLibraryCodeForTypes = true } },
  },
})
vim.lsp.enable("pyright")

-- ── LSP: JSON (vscode-json-language-server, Mason package `json-lsp`) ────────
vim.lsp.config("jsonls", {
  cmd = { vim.fn.stdpath("data") .. "/mason/bin/json-lsp", "--stdio" },
  filetypes = { "json", "jsonc" },
  root_markers = { ".git" },
  capabilities = capabilities,
  init_options = { provideFormatter = true },
})
vim.lsp.enable("jsonls")

-- ── LSP: YAML (yaml-language-server, Mason package `yaml-language-server`) ──
vim.lsp.config("yamlls", {
  cmd = { vim.fn.stdpath("data") .. "/mason/bin/yaml-language-server", "--stdio" },
  filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab" },
  root_markers = { ".git" },
  capabilities = capabilities,
  settings = {
    yaml = { format = { enable = true } },
  },
})
vim.lsp.enable("yamlls")

-- Buffer-local keymaps once a language server attaches.
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("zig-lsp-attach", { clear = true }),
  callback = function(args)
    local map = function(keys, fn, desc)
      vim.keymap.set("n", keys, fn, { buffer = args.buf, desc = "LSP: " .. desc })
    end
    map("gd", vim.lsp.buf.definition, "Goto definition")
    map("gD", vim.lsp.buf.declaration, "Goto declaration")
    map("gr", vim.lsp.buf.references, "References")
    map("gi", vim.lsp.buf.implementation, "Goto implementation")
    map("K", vim.lsp.buf.hover, "Hover docs")
    map("<leader>rn", vim.lsp.buf.rename, "Rename")
    map("<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("<leader>e", vim.diagnostic.open_float, "Line diagnostics")
    map("[d", function() vim.diagnostic.jump({ count = -1 }) end, "Prev diagnostic")
    map("]d", function() vim.diagnostic.jump({ count = 1 }) end, "Next diagnostic")
  end,
})

-- ── Formatting ───────────────────────────────────────────────────────────────
-- Format the current buffer with the attached LSP server's formatter. No
-- fallback: if no attached server can format this filetype, warn and do nothing.
local function has_formatter(bufnr)
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    if client.server_capabilities and client.server_capabilities.documentFormattingProvider then
      return true
    end
  end
  return false
end

local function format_buffer()
  if has_formatter(0) then
    vim.lsp.buf.format({ timeout_ms = 2000 })
  else
    vim.notify("No formatter available for this buffer", vim.log.levels.WARN)
  end
end

-- Manual format shortcut.
vim.keymap.set("n", "<leader>f", format_buffer, { desc = "Format buffer" })

-- Format on save for the filetypes that have a formatting server.
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("format-on-save", { clear = true }),
  pattern = { "*.zig", "*.zon", "*.json", "*.jsonc", "*.yaml", "*.yml" },
  callback = function(args)
    if has_formatter(args.buf) then
      vim.lsp.buf.format({ bufnr = args.buf, timeout_ms = 2000 })
    end
  end,
})
