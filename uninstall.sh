#!/usr/bin/env bash
# uninstall.sh — remove the shim and CLI. Leaves your packs and config alone.
set -euo pipefail

BIN="${DOPAMINE_GIT_BIN:-$HOME/.local/bin}"
say() { printf '%s\n' "$*"; }

# Remove the shim before the CLI: while the shim exists without sfx it still
# works (it swallows the failure), but never leave a shim pointing at nothing.
for f in git sfx; do
  if [[ -L "$BIN/$f" ]]; then
    target="$(readlink "$BIN/$f")"
    case "$target" in
      *dopamine-git*) rm -f "$BIN/$f"; say "✓ removed $BIN/$f (symlink)" ;;
      *) say "• left $BIN/$f alone (points at $target, not ours)" ;;
    esac
  elif [[ -f "$BIN/$f" ]]; then
    # Only delete a copy we can positively identify as ours.
    if grep -q 'dopamine-git' "$BIN/$f" 2>/dev/null; then
      rm -f "$BIN/$f"; say "✓ removed $BIN/$f"
    else
      say "• left $BIN/$f alone (not ours)"
    fi
  fi
done

if [[ -f "$BIN/sfx.pre-dopamine-git.bak" ]]; then
  say ""
  say "Your previous sfx is still at:"
  say "    $BIN/sfx.pre-dopamine-git.bak"
  say "Restore it with: mv '$BIN/sfx.pre-dopamine-git.bak' '$BIN/sfx'"
fi

say ""
say "Packs and config were left in place:"
say "    ${XDG_DATA_HOME:-$HOME/.local/share}/dopamine-git"
say "    ${XDG_CONFIG_HOME:-$HOME/.config}/dopamine-git"
say "Delete those too if you want it fully gone."
