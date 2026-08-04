#!/usr/bin/env bash
# install.sh — put sfx and the git shim on your PATH.
#
# COPIES by default. It is tempting to symlink into this checkout so `git pull`
# updates your install, but the shim IS your git: if you ever check out a branch
# where bin/git does not exist, the symlink dangles and git breaks machine-wide
# until you check it back out. That is a bad day, and it is not hypothetical --
# it happened while building this.
#
#   ./install.sh            copy (safe, recommended)
#   ./install.sh --link     symlink (for developing on dopamine-git itself)
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
BIN="${DOPAMINE_GIT_BIN:-$HOME/.local/bin}"
MODE="copy"
[[ "${1:-}" == "--link" ]] && MODE="link"

say() { printf '%s\n' "$*"; }

mkdir -p "$BIN"

# The shim only works if it is found BEFORE the real git.
real_git="$(PATH="${PATH//$BIN:/}" command -v git 2>/dev/null || true)"
[[ -z "$real_git" ]] && { say "✗ git is not installed"; exit 1; }

if [[ -e "$BIN/git" && ! -L "$BIN/git" ]]; then
  say "✗ $BIN/git exists and is not a symlink — refusing to overwrite it."
  say "  Move it aside and re-run."
  exit 1
fi

# Don't clobber an unrelated `sfx`; keep a copy if we find one.
if [[ -f "$BIN/sfx" && ! -L "$BIN/sfx" ]]; then
  cp -n "$BIN/sfx" "$BIN/sfx.pre-dopamine-git.bak"
  say "• backed up your existing sfx → $BIN/sfx.pre-dopamine-git.bak"
fi

if [[ "$MODE" == "link" ]]; then
  ln -sfn "$SRC/bin/sfx" "$BIN/sfx"
  ln -sfn "$SRC/bin/git" "$BIN/git"
  say "✓ linked into $BIN (dev mode — keep this checkout intact, or git breaks)"
else
  # Copy sfx first: the shim calls it, so it should never be the missing half.
  install -m 755 "$SRC/bin/sfx" "$BIN/sfx.tmp$$" && mv -f "$BIN/sfx.tmp$$" "$BIN/sfx"
  install -m 755 "$SRC/bin/git" "$BIN/git.tmp$$" && mv -f "$BIN/git.tmp$$" "$BIN/git"
  # Packs live beside the real script, so they have to come along.
  DATA="${XDG_DATA_HOME:-$HOME/.local/share}/dopamine-git"
  mkdir -p "$DATA/packs"
  cp -r "$SRC/packs/." "$DATA/packs/"
  say "✓ installed to $BIN (packs → $DATA/packs)"
fi

# Verify PATH order — a shim behind the real git is a silent no-op.
case ":$PATH:" in
  *":$BIN:"*) ;;
  *) say ""
     say "⚠ $BIN is not on your PATH. Add this to your shell rc:"
     say "    export PATH=\"$BIN:\$PATH\""
     exit 0 ;;
esac

resolved="$(command -v git)"
if [[ "$resolved" != "$BIN/git" ]]; then
  say ""
  say "⚠ '$resolved' comes before $BIN on your PATH, so the shim will not fire."
  say "  Move $BIN earlier in PATH, then run: sfx doctor"
  exit 0
fi

say ""
say "Try it:"
say "    sfx test commit     # confirm you can hear it"
say "    sfx events          # what fires, and how"
say "    sfx pack list       # swap the sounds"
say ""
say "Then just use git. Anything that runs git — including your agents — is heard."
