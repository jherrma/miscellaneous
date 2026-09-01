#!/bin/bash
# Install Neovim on Arch and deploy the configuration stored in this repository.
# Any arguments are passed through to distro-independent/install-neovim-config.sh
# (e.g. --link to symlink the repo directory instead of copying it).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Installing Neovim and build dependencies"
# git: lazy.nvim clones itself and every plugin
# base-devel: nvim-treesitter compiles its parsers locally
sudo pacman -S --needed --noconfirm neovim git base-devel

# ZLS is the Zig language server this config wires up. It lives in the extra
# repository; skip it silently on systems where it is unavailable.
if ! command -v zls >/dev/null 2>&1; then
  echo "Installing zls (Zig language server)"
  sudo pacman -S --needed --noconfirm zls || \
    echo "zls could not be installed - install it manually if you write Zig."
fi

"$REPO_ROOT/distro-independent/install-neovim-config.sh" "$@"
