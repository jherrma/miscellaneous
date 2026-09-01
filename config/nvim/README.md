# Neovim configuration

The tracked copy of `~/.config/nvim`. Lean setup aimed at Zig: native LSP (ZLS),
nvim-cmp completion, treesitter, tokyonight.

| File | Purpose |
| --- | --- |
| `init.lua` | options, lazy.nvim bootstrap, LSP/diagnostics, formatting |
| `lua/plugins.lua` | the lazy.nvim plugin spec |
| `lazy-lock.json` | pinned plugin commits, so a fresh machine gets the same versions |

## Keymaps

See **[rusty-memory-refresher.md](rusty-memory-refresher.md)** - the full cheat
sheet for this config, from `$` and `gg` up through LSP, the file tree and the
git diff view. The essentials:

| Key | Action |
| --- | --- |
| `<C-n>` / `<leader>n` | toggle file tree / reveal current file |
| `<leader>gd` / `<leader>gq` | open / close the git diff view |
| `gd` `gi` `<C-o>` | goto definition, goto implementation, go back |
| `<leader>f` | format buffer (also on save for Zig) |

The tree and diff view render Nerd Font icons. Fedora does not package the
Nerd Fonts, so `fedora/install-nerd-font.sh` fetches JetBrainsMono into
`~/.local/share/fonts`; `fedora/install-neovim.sh` calls it automatically. On
Arch the equivalent is `pacman -S ttf-jetbrainsmono-nerd`. Select the font in
your terminal profile afterwards - Neovim has no font setting of its own.

`<C-w>` is left alone as Vim's window prefix, and `<leader>e` stays bound to
diagnostics, so the tree uses `<C-n>` (the nvim-tree convention).

Requires **Neovim 0.11+** (`vim.lsp.config()`, `vim.diagnostic.jump()`).

## Install on a new machine

```bash
./arch/install-neovim.sh            # or: ./fedora/install-neovim.sh
```

Each wrapper installs Neovim plus `git` and a C toolchain (lazy.nvim clones
plugins, treesitter compiles parsers) and then runs
`distro-independent/install-neovim-config.sh`, which prints what it is about to
do and asks for confirmation before touching anything.

**By default the config is deployed as a symlink**: `$XDG_CONFIG_HOME/nvim`
(default `~/.config/nvim`) points at this directory, so edits made in Neovim
show up directly as changes in this repository. Any existing config is moved
aside to `nvim.backup.<timestamp>` first.

Pass `--copy` to copy the files instead, and `--force` to skip the confirmation
prompt (for unattended runs):

```bash
./fedora/install-neovim.sh --copy
./fedora/install-neovim.sh --force
```

Start `nvim` once afterwards: lazy.nvim bootstraps itself and installs the
plugins at the commits recorded in `lazy-lock.json`.

## Updating the tracked copy

With the default symlink there is nothing to do - just commit. After a `--copy`
install, sync the changes back before committing:

```bash
rsync -a --delete ~/.config/nvim/ config/nvim/ --exclude README.md
```
