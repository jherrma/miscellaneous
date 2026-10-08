# Language servers on a new machine

What to install so Zig, C# and Python get completion, diagnostics and hover in
this Neovim config. Plugins install themselves on first launch; the language
server binaries mostly do **not**.

Requires Neovim 0.11+ (tested on 0.12).

## What is automatic and what is not

| Part | Automatic? | Notes |
| --- | --- | --- |
| Plugins (lazy.nvim, Mason, roslyn.nvim, ...) | yes | lazy.nvim clones itself on first launch; needs `git` |
| Treesitter parsers (highlighting) | yes, on startup | needs the `tree-sitter` CLI and a C compiler (see below) |
| Roslyn (C#) server | **no** | `:MasonInstall roslyn-language-server` |
| Pyright (Python) server | **no** | `:MasonInstall pyright` |
| ZLS (Zig) server | **no** | install with your package manager / from GitHub |

The `arch/` and `fedora/` install scripts install Neovim, `git` and a C
compiler, and on Arch also `zls`. They do **not** install the `tree-sitter`
CLI, Node, the .NET SDK or the Mason servers - do those by hand as below.

## 1. Base tools (all languages)

| Tool | Why | macOS (Homebrew) | Arch | Fedora |
| --- | --- | --- | --- | --- |
| `neovim` 0.11+ | the editor | `brew install neovim` | `pacman -S neovim` | `dnf install neovim` |
| `git` | lazy.nvim clones plugins | preinstalled / `brew install git` | `pacman -S git` | `dnf install git` |
| C compiler + `make` | compile treesitter parsers | `xcode-select --install` | `pacman -S base-devel` | `dnf install gcc make` |
| `tree-sitter` CLI | nvim-treesitter (`main` branch) builds parsers with it | `brew install tree-sitter-cli` | `pacman -S tree-sitter-cli` | `npm i -g tree-sitter-cli` or `cargo install tree-sitter-cli` |
| Nerd Font | file-tree and git icons | `brew install --cask font-jetbrains-mono-nerd-font` | `pacman -S ttf-jetbrainsmono-nerd` | `fedora/install-nerd-font.sh` |

Select the Nerd Font in the terminal profile afterwards; Neovim has no font
setting.

Then start `nvim` once and wait until lazy.nvim and the parser installs finish
(`:Lazy` and `:messages` show progress).

## 2. Mason (installer for the C# and Python servers)

Mason is already in the plugin spec; it only loads on demand. Open the UI with
`:Mason`. Installed servers live in `~/.local/share/nvim/mason/`.

Both Mason servers are **not** installed by the config. Run once per machine:

```vim
:MasonInstall roslyn-language-server pyright
```

Keep them current with `:Mason` (select the package, press `u` to update). Mason
packages are not pinned by `lazy-lock.json`.

## 3. C# - Roslyn

| Need | Detail |
| --- | --- |
| .NET SDK | `dotnet` on `PATH` (`brew install --cask dotnet-sdk`, `pacman -S dotnet-sdk`, `dnf install dotnet-sdk-9.0`). Pick the major version your projects target. |
| Server | `:MasonInstall roslyn-language-server` |
| Plugin | `seblyng/roslyn.nvim`, loads only for `.cs` files |
| Parser | `c_sharp`, installed automatically |

Open files inside a project (a `.sln` or `.csproj` found upward); a loose `.cs`
file gets only limited analysis. The first open of a project is slow while
Roslyn loads it.

Check with `:LspInfo` (or `:checkhealth vim.lsp`) - `roslyn` should be listed.

**Gotcha:** `Client roslyn quit with exit code 1` together with
`'--daemon-mode' not recognized` in `~/.local/state/nvim/lsp.log` means the Mason
server is older than the `roslyn.nvim` plugin. Update the server in `:Mason`.

## 4. Python - Pyright

| Need | Detail |
| --- | --- |
| Node.js | `node` on `PATH` (Pyright is a Node program) |
| Server | `:MasonInstall pyright` |
| Config | `vim.lsp.config("pyright", ...)` in `init.lua`; uses `~/.local/share/nvim/mason/bin/pyright-langserver` |
| Parser | `python`, installed automatically |

Pyright resolves imports through the active virtualenv. Start `nvim` from inside
the venv, or add a `pyrightconfig.json` to the project, otherwise third-party
imports show as unresolved.

## 5. Zig - ZLS

| Need | Detail |
| --- | --- |
| Zig compiler | `zig` on `PATH` (`brew install zig`, `pacman -S zig`, or ziglang.org) |
| Server | `zls` on `PATH`: `brew install zls`, `pacman -S zls`; not packaged on Fedora - download from <https://github.com/zigtools/zls/releases> |
| Version match | ZLS must match the installed Zig version (same minor release) |
| Config | `vim.lsp.config("zls", ...)` in `init.lua`; runs `zls` from `PATH` |
| Parser | `zig`, installed automatically |

`<leader>f` falls back to `zig fmt` when no LSP formatter is attached.

## Verify everything

Open one file of each kind, then:

| Command | Shows |
| --- | --- |
| `:LspInfo` | which server is attached to the buffer |
| `:checkhealth vim.lsp` | server binaries found, config problems |
| `:checkhealth nvim-treesitter` | parser install status, missing CLI/compiler |
| `:Mason` | installed / outdated Mason packages |
| `:Inspect` | highlight group under the cursor (treesitter working?) |
| `~/.local/state/nvim/lsp.log` | server stderr when a server will not start |

## Troubleshooting

| Symptom | Likely cause |
| --- | --- |
| No highlighting | `tree-sitter` CLI or C compiler missing; run `:checkhealth nvim-treesitter` |
| `Query error ... Invalid node type "..."` | stale parser shadows the right one; look for old `*.so` under `~/.local/share/nvim/` (`site/parser`, `lazy/nvim-treesitter/parser`) and move it aside |
| `LSP[...]: ... cmd not executable` / server never attaches | binary missing - install it per the sections above |
| `K` errors in a markdown float | `markdown` / `markdown_inline` parsers not installed; restart nvim and let the installs finish |
