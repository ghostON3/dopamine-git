#!/usr/bin/env bash
# install.sh — put sfx and the git shim on your PATH.
#
# Installs symlinks, so `git pull` in this checkout updates your install.
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
BIN="${DOPAMINE_GIT_BIN:-$HOME/.local/bin}"

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

ln -sfn "$SRC/bin/sfx" "$BIN/sfx"
ln -sfn "$SRC/bin/git" "$BIN/git"
say "✓ installed to $BIN"

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
