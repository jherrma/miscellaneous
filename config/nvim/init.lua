-- ~/.config/nvim/init.lua
-- Lean Neovim setup for Zig. Native LSP (ZLS) + completion + treesitter.

-- Leader must be set before lazy loads anything that maps keys.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

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
-- Format the current buffer: use the LSP formatter when a server with
-- formatting support is attached; otherwise fall back to `zig fmt` for Zig.
local function format_buffer()
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    if client.server_capabilities and client.server_capabilities.documentFormattingProvider then
      vim.lsp.buf.format({ timeout_ms = 2000 })
      return
    end
  end
  local ft = vim.bo.filetype
  if ft == "zig" or ft == "zon" then
    vim.cmd("silent write")                 -- zig fmt rewrites the file on disk
    vim.fn.system({ "zig", "fmt", vim.api.nvim_buf_get_name(0) })
    vim.cmd("silent edit")                  -- reload the formatted result
  else
    vim.notify("No formatter available for this buffer", vim.log.levels.WARN)
  end
end

-- Manual format shortcut.
vim.keymap.set("n", "<leader>f", format_buffer, { desc = "Format buffer" })

-- Format on save too.
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("zig-format", { clear = true }),
  pattern = { "*.zig", "*.zon" },
  callback = function()
    -- Only the LSP path is safe in BufWritePre; the zig-fmt fallback writes
    -- the file itself, so leave that to the manual <leader>f shortcut.
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
      if client.server_capabilities and client.server_capabilities.documentFormattingProvider then
        vim.lsp.buf.format({ timeout_ms = 2000 })
        return
      end
    end
  end,
})
