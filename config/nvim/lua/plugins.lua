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

  -- File tree -------------------------------------------------------------------
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },   -- needs a Nerd Font
    cmd = { "NvimTreeToggle", "NvimTreeOpen", "NvimTreeFocus", "NvimTreeFindFile", "NvimTreeFindFileToggle" },
    keys = {
      -- <C-n> is the nvim-tree convention. Deliberately NOT <C-w>, which is
      -- Vim's window prefix, nor <leader>e, already bound to diagnostics.
      { "<C-n>",     "<cmd>NvimTreeToggle<cr>",         desc = "File tree" },
      { "<leader>n", "<cmd>NvimTreeFindFileToggle<cr>", desc = "File tree (reveal current file)" },
    },
    config = function()
      require("nvim-tree").setup({
        hijack_cursor = true,             -- keep the cursor on the filename, not column 0
        sync_root_with_cwd = true,
        view = { width = 34 },
        renderer = {
          group_empty = true,             -- collapse a/b/c chains into one line
          -- Full icons: fedora/install-nerd-font.sh puts JetBrainsMono Nerd
          -- Font in place, so the devicon glyphs render properly.
          icons = {
            show = { file = true, folder = true, folder_arrow = true, git = true },
          },
          indent_markers = { enable = true },
        },
        filters = { dotfiles = false, custom = { "^\\.git$" } },
        git = { enable = true },
        actions = { open_file = { quit_on_open = false } },
      })
    end,
  },

  -- Git: inline hunk signs ------------------------------------------------------
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("gitsigns").setup({
        signs = {
          add       = { text = "│" },
          change    = { text = "│" },
          delete    = { text = "_" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
          untracked = { text = "┆" },
        },
        on_attach = function(bufnr)
          local gs = require("gitsigns")
          local map = function(mode, keys, fn, desc)
            vim.keymap.set(mode, keys, fn, { buffer = bufnr, desc = "Git: " .. desc })
          end

          -- Hunk navigation. Inside a real diff split ]c/[c already mean
          -- "next/prev change", so defer to the built-in motion there.
          map("n", "]c", function()
            if vim.wo.diff then vim.cmd.normal({ "]c", bang = true })
            else gs.nav_hunk("next") end
          end, "Next hunk")
          map("n", "[c", function()
            if vim.wo.diff then vim.cmd.normal({ "[c", bang = true })
            else gs.nav_hunk("prev") end
          end, "Prev hunk")

          map("n", "<leader>gp", gs.preview_hunk,            "Preview hunk")
          map("n", "<leader>gs", gs.stage_hunk,              "Stage hunk")
          map("n", "<leader>gr", gs.reset_hunk,              "Reset hunk")
          map("n", "<leader>gb", function() gs.blame_line({ full = true }) end, "Blame line")
        end,
      })
    end,
  },

  -- Git: full diff view and file history ----------------------------------------
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>",                    desc = "Git: diff view (working tree)" },
      { "<leader>gq", "<cmd>DiffviewClose<cr>",                   desc = "Git: close diff view" },
      { "<leader>gh", "<cmd>DiffviewFileHistory<cr>",             desc = "Git: repo history" },
      { "<leader>gf", "<cmd>DiffviewFileHistory --follow %<cr>",  desc = "Git: history of this file" },
    },
    opts = {
      use_icons = true,
      enhanced_diff_hl = true,
    },
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
