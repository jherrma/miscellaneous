#!/bin/bash
# Install Neovim on Fedora and deploy the configuration stored in this repository.
# Any arguments are passed through to distro-independent/install-neovim-config.sh
# (e.g. --link to symlink the repo directory instead of copying it).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Installing Neovim and build dependencies"
# git: lazy.nvim clones itself and every plugin
# gcc/make: nvim-treesitter compiles its parsers locally
sudo dnf install -y neovim git gcc make

# ZLS (the Zig language server this config wires up) is not packaged in the
# Fedora repositories - fetch it from ziglang.org or install it via ziggy/zvm.
if ! command -v zls >/dev/null 2>&1; then
  echo "Note: zls is not in the Fedora repositories. Install it manually from"
  echo "      https://github.com/zigtools/zls/releases if you write Zig."
fi

# The Neovim config renders file-tree and git icons that need a Nerd Font.
"$REPO_ROOT/fedora/install-nerd-font.sh"

"$REPO_ROOT/distro-independent/install-neovim-config.sh" "$@"
