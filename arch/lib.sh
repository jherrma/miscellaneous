# shellcheck shell=bash
# Shared helpers for the Arch scripts. Source this file, do not run it.

ARCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$ARCH_DIR")"

# Used by install-base.sh (live ISO mirror ranking) and tweaks.sh (reflector.timer).
MIRROR_COUNTRIES="${MIRROR_COUNTRIES:-Germany,Netherlands,Austria}"

die() {
  echo "Error: $*" >&2
  exit 1
}

require_root() {
  [ "$EUID" -eq 0 ] || die "run this as root."
}

require_user() {
  [ "$EUID" -ne 0 ] || die "run this as your normal user, not root (it calls sudo where needed)."
}

# load_packages ARRAY FILE: read the package names in FILE into the array named ARRAY.
# '#' starts a comment; blank lines are ignored; several names per line are fine.
# Dies if the file is missing, so a typo can't silently produce an empty install.
load_packages() {
  local -n _packages_out="$1"
  local file="$2"
  [ -r "$file" ] || die "package list not found: $file"
  mapfile -t _packages_out < <(sed 's/#.*//' "$file" | tr -s '[:space:]' '\n' | grep -v '^$' || true)
}

# Install every package named in a list file with pacman (idempotent).
pacman_install() {
  local -a pkgs
  load_packages pkgs "$1"
  [ "${#pkgs[@]}" -gt 0 ] || return 0
  sudo pacman -S --needed --noconfirm "${pkgs[@]}"
}
