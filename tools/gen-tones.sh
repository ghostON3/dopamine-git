#!/usr/bin/env bash
# gen-tones.sh — regenerate the bundled default pack from pure synthesis.
#
# Every sound in packs/default is produced by this script, from sine waves and
# nothing else. No sampled audio, no downloads, no third-party clips — so the
# default pack has no licensing questions attached and can be MIT like the rest
# of the repo. Run it to change the palette; commit the result.
set -euo pipefail

command -v ffmpeg >/dev/null || { echo "need ffmpeg" >&2; exit 1; }

OUT="$(cd "$(dirname "$0")/.." && pwd)/packs/default"
mkdir -p "$OUT"

# tone <name> <freq1:ms> [freq2:ms ...]   — a little melody, gently enveloped
tone() {
  local name="$1"; shift
  local parts=() filters=() i=0 f d
  local tmp; tmp=$(mktemp -d); trap "rm -rf '$tmp'" RETURN

  for spec in "$@"; do
    f="${spec%%:*}"; d="${spec##*:}"
    local sec; sec=$(awk -v d="$d" 'BEGIN{printf "%.3f", d/1000}')
    ffmpeg -hide_banner -loglevel error -y \
      -f lavfi -i "sine=frequency=${f}:duration=${sec}:sample_rate=44100" \
      -af "afade=t=in:st=0:d=0.008,afade=t=out:st=$(awk -v s="$sec" 'BEGIN{printf "%.3f", s-0.05}'):d=0.05,volume=0.5" \
      "$tmp/p$i.wav"
    parts+=("$tmp/p$i.wav")
    i=$((i+1))
  done

  local inputs=() n=${#parts[@]}
  for p in "${parts[@]}"; do inputs+=(-i "$p"); done
  local concat=""
  for ((j=0; j<n; j++)); do concat+="[$j:a]"; done
  ffmpeg -hide_banner -loglevel error -y "${inputs[@]}" \
    -filter_complex "${concat}concat=n=${n}:v=0:a=1[out]" -map "[out]" \
    -c:a libvorbis -q:a 3 "$OUT/$name.ogg"
  echo "  ✓ $name.ogg"
}

echo "generating default pack → $OUT"

# Rising = something was created or moved forward.
tone commit          660:90 880:130
tone push            660:80 880:80 1175:160
tone add             880:60
tone pull            740:80 587:120
tone fetch           587:70
tone merge           523:90 659:90 784:170
tone rebase          784:80 659:80 587:80 659:140
tone checkout        698:70 932:110
tone branch          784:70 1046:110
tone worktree-add    659:80 880:80 1318:150
tone worktree-remove 880:80 659:110
tone stash           523:70 392:110
tone tag             1046:70 1318:130
tone clone           523:80 659:80 784:80 1046:160
tone revert          784:90 587:130

# Falling / dissonant = something went wrong.
tone reset           440:90 330:130
tone error           311:120 233:200
tone test-fail       415:130 311:220

# Reward.
tone test-pass       784:80 988:80 1318:180
tone celebration     784:70 988:70 1175:70 1568:220

echo "done — $(find "$OUT" -name '*.ogg' | wc -l) sounds"
