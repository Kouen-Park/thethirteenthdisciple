# Recovery milestone · 2026-09-15

## Changed

- Fixed `d54563d` as the recovery baseline with local tag
  `recovery-baseline-d54563d`.
- Removed 143 untracked Finder-style `" 2"` duplicates after historical
  comparison; no duplicate remains in the project.
- Selectively restored nine visual capture tools from `da4ff71` and corrected the
  Chapter 2 `SceneArt` method name without merging donor-branch document deletion.
- Rebuilt all seven runtime world backgrounds, including Chapter 1, as clean
  environment-only art.
- Added reproducible source/prompt records, deterministic processing, recovery
  preflight, strict background validation, sprite alpha audit, world-review
  captures, an asset status table, and a first-player protocol.
- Realigned the Chapter 3 architectural opening with the existing closed-door
  interaction anchor at world x=811.

## Verified environment

- macOS / Apple M2
- Godot 4.7.2 stable
- Metal Forward Mobile for visual captures
- Headless Godot for import, format validation, and regressions

Successful gates:

- Headless editor import
- Recovery preflight
- Seven 2048x720 RGB8 backgrounds, exactly 64 colors each
- Story and save migration
- Cutscenes and biblical event order
- Biblical revision / 39 field investigations
- Journal, pause, and input locking
- Traversal and presentation
- Chapter 2 and Chapter 3 complete playthroughs
- Chapters 4-6 nine-route playthrough matrix and epilogue
- `git diff --check`

The macOS headless process reports its known CA-certificate lookup warning and
cannot write the sandboxed global Godot editor settings file. Neither affects
project import or test results.

## Commit / push state

- Local commit: this milestone is committed locally; use `git show --stat HEAD`
  for the immutable commit identifier.
- Remote push: intentionally not performed without an explicit destination/push
  request.

## Remaining human-only sign-off

- Complete three first-time player rows in `PLAYTEST_PROTOCOL.md`.
- Complete headphone and speaker listening passes.
- Have a person approve the stored left/center/right captures at both aspect
  ratios and inspect the reported semi-transparent edges on the retained player
  walk sheets and fleeing-youth source.

These items require human perception or independent players. They are not marked
complete by automated test success.
