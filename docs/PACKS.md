# Sound packs

A pack is a folder of audio files named after events. There is no manifest to
write, no build step, and no registry to publish to.

```
my-pack/
  push.ogg              plays on a successful push
  commit.mp3            plays on a commit
  test-pass/            a folder = one clip picked at random
    win-a.wav
    win-b.wav
  merge-1.ogg           numbered variants also work
  merge-2.ogg
  pack.json             optional metadata, never required
```

Supported: `.ogg` `.oga` `.mp3` `.wav` `.opus` `.flac` `.m4a`

Anything you don't provide falls back to the default pack, so you can ship a pack
with three sounds and it still works everywhere.

## Events

| event | fires on | notes |
|---|---|---|
| `add` | `git add` | very frequent — keep it under 80ms, or leave it off |
| `commit` | `git commit` | your most-heard sound; make it short and pleasant |
| `push` | `git push` | the big one |
| `pull` / `fetch` | `git pull` / `git fetch` | |
| `merge` | `git merge` | |
| `rebase` | `git rebase` | |
| `checkout` | `git checkout` / `git switch` | frequent |
| `branch` | `git branch` | |
| `worktree-add` | `git worktree add` | |
| `worktree-remove` | `git worktree remove` / `prune` | |
| `stash` | `git stash` | |
| `tag` | `git tag` | |
| `clone` | `git clone` | rare — can afford a fanfare |
| `reset` / `revert` | `git reset` / `git revert` | |
| `error` | reserved for callers | not fired by the shim |
| `test-pass` / `test-fail` / `celebration` | call `sfx play` yourself | wire into CI, Makefiles, hooks |

Only successful commands make noise. A failed commit is silent.

## Design notes worth stealing

From building the default pack — see `tools/gen-tones.sh` for the full reasoning:

- **Timbre beats pitch.** People tell sounds apart by texture first, rhythm second,
  pitch last. Twenty sounds that differ only in pitch all read as the same blip.
- **Let the gesture carry the meaning.** Push flies away, pull arrives, merge
  converges two pitches into unison, branch splits one into two. Nobody should
  have to memorise your pack.
- **Frequency sets duration.** `add` fires hundreds of times a day and must be a
  tick. `clone` happens weekly and can sing.
- **Normalise your levels.** One clip 12 dB louder than the rest gets the whole
  pack uninstalled.

## Publishing yours

Host it in your own repo, then open a PR adding a row here.

**Please don't PR the audio itself.** Game, film and TV audio is copyrighted, and
this repo stays MIT-clean so anyone can fork it. Ripping clips for your own machine
is your business — `sfx add <event> <url> --start 0:12 --end 0:14` exists for
exactly that, and it keeps them local.

## Community packs

| pack | by | sounds like | install |
|---|---|---|---|
| _yours here_ | | | |

Install any pack by dropping it in:

```bash
git clone https://github.com/you/your-pack \
  "$(sfx pack dir default)/../your-pack"
sfx pack use your-pack
```
