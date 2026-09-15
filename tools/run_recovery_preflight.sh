#!/bin/sh
set -eu
cd "$(dirname "$0")/.."

duplicate_files=$(find . -type f -name '* 2.*' -print)
if [ -n "$duplicate_files" ]; then
  echo "Recovery preflight failed: Finder-style duplicate files found:"
  echo "$duplicate_files"
  exit 1
fi

duplicate_classes=$(rg --no-filename '^class_name[[:space:]]+[A-Za-z0-9_]+' -g '*.gd' | awk '{print $2}' | sort | uniq -d)
if [ -n "$duplicate_classes" ]; then
  echo "Recovery preflight failed: duplicate GDScript class_name values:"
  echo "$duplicate_classes"
  exit 1
fi

missing=0
references=$(rg --no-filename -o 'res://[^" )]+\.(gdshader|tscn|tres|png|wav|ogg|gd)' scripts scenes story_data.gd scene_art.gd project.godot | sort -u || true)
for reference in $references; do
	case "$reference" in *'%'*|*'+'*) continue ;; esac
  path=${reference#res://}
  if [ ! -f "$path" ]; then
    echo "Missing resource: $reference"
    missing=1
  fi
done
[ "$missing" -eq 0 ] || exit 1

for document in \
	assets/art/pixel/GENERATION.md \
	assets/art/chapter02/GENERATION.md \
  assets/art/chapter03/GENERATION.md \
  assets/art/late_chapters/GENERATION.md \
  assets/art/pixel/npcs/GENERATION.md \
  assets/art/biblical_cast/GENERATION.md \
  assets/art/cutscene_cast/GENERATION.md \
  assets/art/player_walk/GENERATION.md; do
  if [ ! -f "$document" ]; then
    echo "Missing generation record: $document"
    exit 1
  fi
done

echo "Recovery preflight: PASS"
