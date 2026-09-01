#!/bin/bash
# Install a Nerd Font on Fedora.
#
# Fedora does not package the Nerd Fonts, so this pulls the release archive
# from GitHub into ~/.local/share/fonts (a per-user install - no root needed
# for the font itself). On Arch the equivalent is simply:
#   sudo pacman -S ttf-jetbrainsmono-nerd
#
# A Nerd Font supplies the glyphs used by the Neovim file tree / diff view and
# by the powerlevel10k prompt.
#
# Idempotent - skips the download if the font is already installed.
#
# Usage:
#   ./install-nerd-font.sh                # install JetBrainsMono
#   ./install-nerd-font.sh MesloLGS       # install a different one
#   ./install-nerd-font.sh --force        # reinstall even if present
set -euo pipefail

# Release asset name without the .zip - see github.com/ryanoasis/nerd-fonts.
FONT="JetBrainsMono"
# Pinned so a fresh machine gets a known-good build; bump deliberately.
NERD_FONTS_VERSION="v3.5.1"

FORCE=0
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    -h|--help)
      sed -n '2,17p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    -*) echo "Unknown option: $arg" >&2; exit 1 ;;
    *) FONT="$arg" ;;
  esac
done

FONT_DIR="$HOME/.local/share/fonts/${FONT}NerdFont"
URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONTS_VERSION}/${FONT}.zip"

# NB: no 'grep -q' in these pipelines. It exits at the first match, fc-list
# then dies of SIGPIPE, and 'set -o pipefail' reports the whole pipeline as
# failed - turning a successful match into a false negative.
font_installed() { fc-list 2>/dev/null | grep -i "$FONT Nerd Font" >/dev/null; }

if [ "$FORCE" -eq 0 ] && font_installed; then
  echo "$FONT Nerd Font is already installed - nothing to do."
  exit 0
fi

echo "Installing $FONT Nerd Font ($NERD_FONTS_VERSION)"
echo "  from: $URL"
echo "  into: $FONT_DIR"
echo

# curl and unzip are not guaranteed on a minimal install; fontconfig provides
# fc-cache, which is what actually makes the font visible to applications.
MISSING=()
for c in curl unzip fc-cache; do command -v "$c" >/dev/null 2>&1 || MISSING+=("$c"); done
if [ ${#MISSING[@]} -gt 0 ]; then
  echo "Installing missing tools: ${MISSING[*]}"
  sudo dnf install -y curl unzip fontconfig
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Downloading"
if ! curl -fsSL --retry 3 -o "$TMP/font.zip" "$URL"; then
  echo "Download failed. Check that '$FONT' is a valid asset name for" >&2
  echo "release $NERD_FONTS_VERSION at github.com/ryanoasis/nerd-fonts." >&2
  exit 1
fi

echo "Extracting"
mkdir -p "$FONT_DIR"
# Extract everything, then prune. Filtering with unzip patterns instead would
# make it exit 11 ("nothing matched") whenever an archive lacks one of the
# extensions - JetBrainsMono, for instance, ships .ttf only.
unzip -qo "$TMP/font.zip" -d "$FONT_DIR"
# The archives also carry READMEs and licences, and a Windows-compatible copy
# of every style that would otherwise double each entry in the font picker.
find "$FONT_DIR" -type f ! -iname '*.ttf' ! -iname '*.otf' -delete
find "$FONT_DIR" -type f -iname '*Windows*' -delete
find "$FONT_DIR" -mindepth 1 -type d -empty -delete

echo "Rebuilding the font cache"
fc-cache -f "$FONT_DIR" >/dev/null

echo
if font_installed; then
  echo "Installed. Available families:"
  fc-list : family | tr ',' '\n' | grep -i "$FONT Nerd Font" | sort -u | sed 's/^/  /'
  echo
  echo "Now select it as the font in your terminal profile - Neovim and"
  echo "powerlevel10k pick it up from there, they have no font setting of"
  echo "their own."
else
  echo "Font files were extracted but fontconfig does not report them." >&2
  exit 1
fi
