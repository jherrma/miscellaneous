-- ~/.config/nvim/lua/plugins.lua
-- Lazy plugin spec. Kept deliberately small.

return {
  -- Colorscheme (Treesitter-aware) ----------------------------------------------
  {
    "folke/tokyonight.nvim",
    lazy = false,      -- load on startup, not on demand
    priority = 1000,   -- load before other plugins so highlights are set first
    config = function()
      require("tokyonight").setup({
        style = "day",            -- light theme; others: "storm" | "night" | "moon"
        on_highlights = function(hl, c)
          -- The light theme's default comment grey is very faint on white;
          -- darken it so comments stay legible in daylight.
          hl.Comment = { fg = "#616587", italic = true }
        end,
      })
      vim.cmd.colorscheme("tokyonight")
    end,
  },

  -- Completion engine + sources -------------------------------------------------
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",   -- LSP completions (ZLS)
      "hrsh7th/cmp-buffer",     -- words from current buffer
      "hrsh7th/cmp-path",       -- filesystem paths
      "L3MON4D3/LuaSnip",       -- snippet engine
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
            else fallback() end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then luasnip.jump(-1)
            else fallback() end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },

  -- Syntax-aware highlighting / indentation ------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",            -- stable API; `main` is the in-progress rewrite
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "zig", "lua", "vimdoc" },
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },
}
