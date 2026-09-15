#!/bin/sh
# Run sequentially because the existing test suites share the Godot user directory.
set -eu
cd "$(dirname "$0")/.."
sh tools/run_recovery_preflight.sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tools/validate_art_assets.gd --log-file /tmp/disciple-art-validation.log
for suite in run_story_tests run_cutscene_tests run_biblical_revision_tests run_polish_tests run_pause_tests run_traversal_tests run_presentation_tests run_chapter02_playthrough_tests run_chapter03_playthrough_tests run_late_chapter_playthrough_tests; do
  suite_log="/tmp/disciple-polish-$suite.log"
  /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script "tests/$suite.gd" --log-file "$suite_log"
  if rg -q 'SCRIPT ERROR:|Parse Error:' "$suite_log"; then exit 1; fi
done
