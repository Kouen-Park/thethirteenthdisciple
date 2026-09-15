# Chapter 2 generation record

- Date: 2026-09-15
- Generator: Codex built-in image generation
- Runtime output: `temple_market.png`
- Preserved source: `source/temple_market.png`
- Processing: `Godot --headless --path . --script tools/process_world_backgrounds.gd`
- Output contract: 2048×720 RGB PNG, nearest resize, adaptive 64-color palette
- Status: runtime-final; human camera and collision review pending

## Prompt

```text
Use case: historical-scene
Asset type: PC 2D narrative-adventure world background for Chapter 2 of a Godot pixel-art game
Primary request: A clean environment-only Jerusalem Second Temple outer market courtyard immediately after the merchants have left. The left half is a dusty market area with sandstone walls, empty wooden stall structures, stacked crates and pottery placed only as distant static scenery; the right half is a quieter temple prayer court with broad paving, columns, a shadowed doorway, and one clearly readable passage connecting both halves.
Style/medium: polished high-detail pixel art; crisp square pixels; deliberate clusters; 1-2 pixel outlines; controlled ordered dithering; no painterly smoothing
Composition/framing: exact 2048×720 horizontal world, consistent 3/4 top-down view around 25-30 degrees; walkable lower band y=385…680; at least 180 pixels of clear traversal corridor; architecture primarily above y=385; open staging areas for separate NPCs and gameplay objects
Lighting/mood: warm late-afternoon light from upper left; ochre and apricot sandstone highlights; cool indigo-violet shadows
Constraints: static environment only; no foreground characters, player, guards, Jesus, interactable coins, toppled or movable table, prayer cloth gameplay object, UI, dialogue panel, title card, text, watermark, or modern objects; solid RGB background
Avoid: baked gameplay objects, photorealism, smooth gradients, blurry pixels, anti-aliased edges, halos, random noise dithering, mixed pixel scales, isometric perspective
```

