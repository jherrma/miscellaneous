#!/bin/bash
# Deploy the Neovim configuration stored in this repository to ~/.config/nvim.
#
# Distro-independent: assumes Neovim is already installed. The arch/ and fedora/
# wrappers install Neovim first and then call this script.
#
# Usage:
#   ./install-neovim-config.sh            # symlink the repo directory (default)
#   ./install-neovim-config.sh --copy     # copy the files instead of linking
#   ./install-neovim-config.sh --force    # skip the confirmation prompt
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="$REPO_ROOT/config/nvim"
TARGET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

MODE="link"
FORCE=0
for arg in "$@"; do
  case "$arg" in
    --link)  MODE="link" ;;
    --copy)  MODE="copy" ;;
    --force) FORCE=1 ;;
    -h|--help)
      sed -n '2,10p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

if [ ! -d "$SOURCE_DIR" ]; then
  echo "Configuration not found at $SOURCE_DIR" >&2
  exit 1
fi

if ! command -v nvim >/dev/null 2>&1; then
  echo "Neovim is not installed. Run the arch/ or fedora/ installer first." >&2
  exit 1
fi

# The configuration uses vim.lsp.config() and vim.diagnostic.jump(), both of
# which need Neovim 0.11 or newer.
NVIM_VERSION="$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)"
NVIM_MAJOR="${NVIM_VERSION%%.*}"
NVIM_MINOR="${NVIM_VERSION##*.}"
if [ "$NVIM_MAJOR" -eq 0 ] && [ "$NVIM_MINOR" -lt 11 ]; then
  echo "Warning: Neovim $NVIM_VERSION found, but this config expects 0.11+."
  echo "         LSP setup and diagnostic keymaps will not work."
  echo
fi

TARGET_EXISTS=0
if [ -e "$TARGET_DIR" ] || [ -L "$TARGET_DIR" ]; then
  TARGET_EXISTS=1
fi

# Say exactly what is about to happen, then let the user confirm it.
echo "Neovim configuration deployment"
if [ "$MODE" = "link" ]; then
  echo "  mode:   SYMLINK"
else
  echo "  mode:   COPY"
fi
echo "  source: $SOURCE_DIR"
echo "  target: $TARGET_DIR"
if [ "$MODE" = "link" ]; then
  echo
  echo "  $TARGET_DIR will become a symlink to the repository."
  echo "  Edits made in Neovim therefore show up directly as changes in this repo."
else
  echo
  echo "  The files are copied. Later edits in Neovim will NOT reach this repo"
  echo "  until you sync them back manually."
fi
if [ "$TARGET_EXISTS" -eq 1 ]; then
  echo
  echo "  $TARGET_DIR already exists and will be moved aside to a timestamped backup."
fi
echo

if [ "$FORCE" -eq 0 ]; then
  read -r -p "Continue? [y/N] " reply
  case "$reply" in
    [yY]|[yY][eE][sS]) ;;
    *) echo "Aborted."; exit 1 ;;
  esac
fi

# Back up whatever is already there instead of clobbering it.
if [ "$TARGET_EXISTS" -eq 1 ]; then
  BACKUP="$TARGET_DIR.backup.$(date +%Y%m%d-%H%M%S)"
  mv "$TARGET_DIR" "$BACKUP"
  echo "Existing configuration moved to $BACKUP"
fi

mkdir -p "$(dirname "$TARGET_DIR")"

if [ "$MODE" = "link" ]; then
  ln -s "$SOURCE_DIR" "$TARGET_DIR"
  echo "Symlinked $TARGET_DIR -> $SOURCE_DIR"
else
  cp -r "$SOURCE_DIR" "$TARGET_DIR"
  echo "Copied $SOURCE_DIR -> $TARGET_DIR"
fi

echo
echo "Done. Start nvim once to let lazy.nvim bootstrap and install the plugins"
echo "pinned in lazy-lock.json (it clones itself on first launch)."
