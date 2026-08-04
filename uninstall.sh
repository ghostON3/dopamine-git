#!/usr/bin/env bash
# uninstall.sh — remove the shim and CLI. Leaves your packs and config alone.
set -euo pipefail

BIN="${DOPAMINE_GIT_BIN:-$HOME/.local/bin}"
say() { printf '%s\n' "$*"; }

for f in git sfx; do
  if [[ -L "$BIN/$f" ]]; then
    target="$(readlink "$BIN/$f")"
    case "$target" in
      *dopamine-git*) rm -f "$BIN/$f"; say "✓ removed $BIN/$f" ;;
      *) say "• left $BIN/$f alone (points at $target, not ours)" ;;
    esac
  elif [[ -e "$BIN/$f" ]]; then
    say "• left $BIN/$f alone (not a symlink we created)"
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
