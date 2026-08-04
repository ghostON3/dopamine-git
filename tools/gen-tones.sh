#!/usr/bin/env bash
# gen-tones.sh — synthesize the bundled default pack.
#
# DESIGN NOTES (read before changing a frequency)
#
# People tell sounds apart by timbre first, rhythm second, pitch last. A pack
# that varies only pitch produces twenty sounds that all read as "tudu" — which
# is exactly what v1 of this file did. So each event gets a distinct WAVEFORM
# and a distinct GESTURE, and pitch is the least of the three.
#
# The gesture encodes the meaning, the way game audio does:
#
#   push            flies away — rising chirp, energy leaving
#   pull / fetch    arrives    — falling, the mirror of push
#   merge           two pitches converge into one unison
#   branch          one pitch splits into two
#   commit          a short, satisfying pluck you can hear 200x/day
#   error           detuned minor 2nd, the universal "wrong"
#   test-pass       bright major arpeggio, the puzzle-solved idiom
#
# Frequency of use sets duration. `add` fires constantly, so it is a 50ms tick.
# `clone` happens rarely, so it can afford a fanfare.
#
# Everything here is synthesized from oscillator math — no sampled audio, no
# downloads. That keeps the default pack MIT-clean. Real game and movie audio
# belongs in a user-installed pack, never in this repo.
set -euo pipefail

command -v ffmpeg >/dev/null || { echo "need ffmpeg" >&2; exit 1; }

OUT="$(cd "$(dirname "$0")/.." && pwd)/packs/default"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

SR=44100

# osc <wave> <f0> <f1> <ms> <decay> <vol> -> prints a wav path
#   wave:  square | pulse | tri | sine | saw | fm | noise
#   f0→f1: glide (equal values = steady tone)
#   decay: exponential decay rate; 0 = flat, 30 = sharp pluck
osc() {
  local wave="$1" f0="$2" f1="$3" ms="$4" decay="$5" vol="$6"
  local dur; dur=$(awk -v m="$ms" 'BEGIN{printf "%.4f", m/1000}')
  # mktemp, not a counter: osc runs inside $(...), so any counter increments in
  # a subshell and resets. That silently made every note in a sequence write to
  # the same file, so each melody played its last note N times instead.
  local out; out="$(mktemp "$TMP/osc-XXXXXXXX.wav")"

  # Phase of a linear chirp: f0*t + (f1-f0)*t^2/(2*dur). Steady when f0 == f1.
  local ph="(${f0}*t+(${f1}-${f0})*t*t/(2*${dur}))"
  local expr
  case "$wave" in
    sine)   expr="sin(2*PI*$ph)" ;;
    square) expr="sgn(sin(2*PI*$ph))" ;;
    # 25% duty pulse — the thin, nasal NES lead.
    pulse)  expr="if(lt(mod($ph,1),0.25),1,-1)" ;;
    tri)    expr="2*asin(sin(2*PI*$ph))/PI" ;;
    saw)    expr="2*mod($ph,1)-1" ;;
    # 2-operator FM: bell/metallic, for tags and rewards.
    fm)     expr="sin(2*PI*$ph+3.0*sin(2*PI*$ph*2.01))" ;;
    noise)  expr="(random(0)*2-1)" ;;
    *) echo "bad wave: $wave" >&2; exit 1 ;;
  esac

  # Exponential decay + a 3ms attack so nothing clicks on onset.
  local env="exp(-${decay}*t)*min(1,t/0.003)"

  # exprs must be single-quoted: the expressions contain commas (min(1,x)),
  # which ffmpeg would otherwise read as filter-chain separators.
  ffmpeg -hide_banner -loglevel error -y \
    -f lavfi -i "aevalsrc=exprs='${vol}*(${expr})*(${env})':d=${dur}:s=${SR}" \
    -c:a pcm_s16le "$out"
  printf '%s' "$out"
}

# seq <name> <wav> [wav...]   — concatenate in time
seq_out() {
  local name="$1"; shift
  local inputs=() cat="" i=0
  for p in "$@"; do inputs+=(-i "$p"); cat+="[$i:a]"; i=$((i+1)); done
  if (( i == 1 )); then
    ffmpeg -hide_banner -loglevel error -y -i "$1" -c:a libvorbis -q:a 4 "$OUT/$name.ogg"
  else
    ffmpeg -hide_banner -loglevel error -y "${inputs[@]}" \
      -filter_complex "${cat}concat=n=${i}:v=0:a=1[a]" -map "[a]" \
      -c:a libvorbis -q:a 4 "$OUT/$name.ogg"
  fi
  echo "  ✓ $name"
}

# layer <name> <wav> [wav...]  — stack simultaneously (chords, convergence)
layer_out() {
  local name="$1"; shift
  local inputs=() mix="" i=0
  for p in "$@"; do inputs+=(-i "$p"); mix+="[$i:a]"; i=$((i+1)); done
  ffmpeg -hide_banner -loglevel error -y "${inputs[@]}" \
    -filter_complex "${mix}amix=inputs=${i}:duration=longest:normalize=0[a]" -map "[a]" \
    -c:a libvorbis -q:a 4 "$OUT/$name.ogg"
  echo "  ✓ $name"
}

silence() { osc sine 0 0 "$1" 0 0; }

echo "synthesizing default pack → $OUT"

# ── staging: tiny, dry, unobtrusive. Heard hundreds of times a day. ──────────
seq_out add        "$(osc tri 440 440 50 22 0.30)"
seq_out stash      "$(osc tri 523 523 60 20 0.30)" "$(osc tri 392 392 80 20 0.30)"

# ── commit: the signature pluck. Rising 5th, pulse wave, short and sweet. ────
seq_out commit     "$(osc pulse 523 523 70 14 0.42)" "$(osc pulse 784 784 110 11 0.42)"

# ── push: energy leaving. Arpeggio + a chirp that flies upward and out. ──────
seq_out push       "$(osc square 523 523 60 16 0.36)" \
                   "$(osc square 659 659 60 16 0.36)" \
                   "$(osc square 784 784 60 16 0.36)" \
                   "$(osc square 1046 1568 200 7 0.36)"

# ── pull / fetch: arrival. The mirror image of push. ─────────────────────────
seq_out pull       "$(osc square 1046 784 120 10 0.34)" "$(osc square 659 659 130 12 0.34)"
seq_out fetch      "$(osc tri 784 587 90 16 0.26)"

# ── merge: two voices converge into unison. The gesture IS the meaning. ─────
layer_out merge    "$(osc square 523 784 260 5 0.30)" \
                   "$(osc square 1046 784 260 5 0.30)"

# ── branch / worktree: one voice splits into two. Inverse of merge. ──────────
layer_out branch   "$(osc pulse 784 587 200 7 0.30)" \
                   "$(osc pulse 784 988 200 7 0.30)"
layer_out worktree-add "$(osc square 659 494 280 5 0.30)" \
                       "$(osc square 659 988 280 5 0.30)" \
                       "$(osc square 659 659 280 6 0.22)"
seq_out worktree-remove "$(osc tri 988 988 70 18 0.30)" "$(osc tri 494 494 130 14 0.30)"

# ── checkout: a neutral two-tick "moved". No emotional colour. ───────────────
seq_out checkout   "$(osc pulse 698 698 55 20 0.32)" "$(osc pulse 932 932 75 18 0.32)"

# ── rebase: history rewritten — a descending run that resolves upward. ──────
seq_out rebase     "$(osc saw 880 880 55 18 0.24)" "$(osc saw 740 740 55 18 0.24)" \
                   "$(osc saw 622 622 55 18 0.24)" "$(osc square 784 784 150 9 0.34)"

# ── tag / clone: FM bell = "this is a marker". Rare, so allowed to ring. ─────
seq_out tag        "$(osc fm 1046 1046 320 6 0.30)"
seq_out clone      "$(osc square 523 523 70 14 0.34)" "$(osc square 659 659 70 14 0.34)" \
                   "$(osc square 784 784 70 14 0.34)" "$(osc fm 1046 1046 380 5 0.32)"

# ── undo family: falling, minor, a little sour. ─────────────────────────────
seq_out revert     "$(osc square 622 622 110 12 0.32)" "$(osc square 466 466 190 9 0.32)"
seq_out reset      "$(osc saw 440 440 100 13 0.28)" "$(osc saw 330 330 170 10 0.28)"

# ── error: detuned minor 2nd — the universal "wrong". Two clashing saws. ────
layer_out error    "$(osc saw 233 233 340 6 0.26)" \
                   "$(osc saw 247 247 340 6 0.26)"

# ── tests: the clearest good/bad pair in the pack. ──────────────────────────
seq_out test-pass  "$(osc square 784 784 70 14 0.36)" "$(osc square 988 988 70 14 0.36)" \
                   "$(osc square 1318 1318 220 7 0.36)"
layer_out test-fail "$(osc saw 415 415 300 7 0.28)" \
                    "$(osc saw 293 293 300 7 0.28)"

# ── celebration: the 1-up idiom. Fast ascending run, unmistakably a reward. ──
seq_out celebration "$(osc pulse 523 523 55 12 0.34)" "$(osc pulse 659 659 55 12 0.34)" \
                    "$(osc pulse 784 784 55 12 0.34)" "$(osc pulse 1046 1046 55 12 0.34)" \
                    "$(osc pulse 1318 1318 55 12 0.34)" "$(osc pulse 1568 1568 300 5 0.36)"

echo "done — $(find "$OUT" -name '*.ogg' | wc -l) sounds"
