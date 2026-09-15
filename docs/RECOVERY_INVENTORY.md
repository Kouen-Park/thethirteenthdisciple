# Recovery inventory · 2026-09-15

## Authority and baseline

- Verified gameplay baseline: `d54563d`
- Local recovery tag: `recovery-baseline-d54563d`
- Historical base: `39d5189`
- Selective donor commit: `da4ff71`
- Source of truth order: runtime code/tests → `AI_REBUILD_PROMPT.md` → `PROJECT_PLAN_ARCHIVE.md` → `ART_DIRECTION.md` → chapter notes.

The tracked contents of `d54563d` passed the complete regression suite in an isolated checkout before recovery work began.

## Duplicate-file recovery

The working tree contained 143 untracked Finder-style `" 2"` copies. Every differing primary script/document/config copy checked was byte-identical to its path in `39d5189`; same-content copies and duplicate UID sidecars were also present. They caused Godot to register the same `class_name` more than once.

The files were first moved out of the project for verification and then permanently deleted at the user's request. Their historical contents remain recoverable from `39d5189`.

## Selectively recovered from `da4ff71`

- Visual capture scripts under `tools/capture_*.gd`
- The `SceneArt` Chapter 2 method name was corrected from “supper” to “temple aftermath”.

The donor commit was not merged wholesale because it deletes the two recovery-planning documents and contains machine-specific import metadata churn.

## Recreated assets

The Chapter 1–6 and epilogue backgrounds were regenerated as clean environment-only images. Generated originals are stored in the corresponding `source/` directories; runtime copies are normalized to 2048×720 RGB and a 64-color adaptive palette by `tools/process_world_backgrounds.gd`.

Exact prompts and provenance are recorded in each asset folder's `GENERATION.md`.
