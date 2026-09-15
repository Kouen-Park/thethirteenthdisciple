# Chapter 3 generation record

- Date: 2026-09-15
- Generator: Codex built-in image generation
- Runtime output: `courtyard.png`
- Preserved source: `source/courtyard.png`
- Processing: `tools/process_world_backgrounds.gd`
- Output contract: 2048×720 RGB PNG, nearest resize, adaptive 64-color palette
- Status: runtime-final neutral afternoon base; existing shader supplies dusk/night

## Prompt

```text
Use case: historical-scene
Asset type: PC 2D narrative-adventure world background for Chapter 3 of a Godot pixel-art game
Primary request: A clean environment-only Jerusalem outskirts courtyard connecting a village lane to a narrow road leading toward a distant court. The same background must support afternoon, dusk, and night tinting in-engine. Include low sandstone houses, restrained olive trees and cypresses, broad unobstructed ground, a clear empty circular patch for the separate well sprite, and an open dark doorway for the separate closed-door sprite.
Style/medium: polished high-detail pixel art; crisp square pixels; deliberate clusters; controlled ordered dithering
Composition/framing: exact 2048×720 horizontal world; 3/4 top-down view; walkable lower band y=385…680; clear left-to-right route
Lighting/mood: neutral warm late-afternoon base designed to accept indigo night tint
Constraints: static environment only; absolutely no baked well or well mechanism and no door panel; no people, player, NPCs, lantern, sandal, drag marks, cloth, bowl, gameplay items, UI, buttons, title, text, or watermark; solid RGB background
```

## Alignment edit

The first clean generation placed the open doorway too far right for the runtime
`closed_door` anchor at world x=811. The source was edited once, preserving the
environment while moving the open doorway to approximately x=820 and rebuilding
the former opening as continuous wall and foliage.

```text
Edit this existing wide pixel-art courtyard background while preserving its exact palette, lighting, composition, ground, well-placement clearing, trees, and architecture. Move the single OPEN DARK ARCHWAY / doorway from its current position near the right-center to approximately 40% of the image width (around x=820 on a 2048px-wide canvas), so it aligns with a separate runtime closed-door sprite at world x=811. Remove and seamlessly rebuild the old doorway location as continuous sandstone wall and foliage. Keep the new doorway open and empty: no wooden door, no door panel, no NPC, no character, no well, no props, no text, no UI, no watermark. Preserve a clear lower walkable band and crisp nearest-neighbor 16-bit pixel-art appearance. Output the same panoramic aspect ratio.
```
