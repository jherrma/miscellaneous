# Neovim configuration

The tracked copy of `~/.config/nvim`. Lean setup aimed at Zig: native LSP (ZLS),
nvim-cmp completion, treesitter, tokyonight.

| File | Purpose |
| --- | --- |
| `init.lua` | options, lazy.nvim bootstrap, LSP/diagnostics, formatting |
| `lua/plugins.lua` | the lazy.nvim plugin spec |
| `lazy-lock.json` | pinned plugin commits, so a fresh machine gets the same versions |

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
