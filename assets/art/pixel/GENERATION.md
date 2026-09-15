# Chapter 1 background generation record

- Date: 2026-09-15
- Generator: Codex built-in image generation
- Runtime output: `chapter01_jerusalem_gate_world_2048.png`
- Preserved source: `source/chapter01_jerusalem_gate_world_2048.png`
- Processing: `tools/process_world_backgrounds.gd`
- Output contract: 2048×720 RGB PNG, nearest resize, adaptive 64-color palette
- Status: runtime-final; human camera and collision review pending

## Prompt

```text
Use case: historical-scene
Asset type: clean PC 2D narrative-adventure world background for Chapter 1 of a Godot pixel-art game
Primary request: A broad open square and converging roads immediately outside a first-century Jerusalem city gate during the triumphal-entry period. A monumental but historically restrained sandstone gate is centered in the upper band and remains the unmistakable destination. A wide main road rises from the lower center toward the gate, while a clearly readable side road enters from the right for a separate Jesus-and-donkey sprite. Low walls, distant Jerusalem buildings, sparse olive shrubs and roadside stones frame the space without blocking movement.
Style/medium: polished high-detail pixel art; crisp square pixels; deliberate clusters; 1-2 pixel outlines; controlled ordered dithering; no painterly smoothing
Composition/framing: exact 2048×720 horizontal world; consistent 3/4 top-down 25-30 degree view; gate base and wall collision around y=308; walkable roads and roadside lower area y=318…680; clear main path at least 220 pixels wide; right side road stays unobstructed; open staging areas for separate Jonah, Miriam, crowd, player, and Jesus/donkey sprites
Lighting/mood: warm late-afternoon light from upper left; ochre and apricot highlights with cool indigo-violet shadows
Constraints: static environment only; no people, player, crowd, Jesus, donkey, palm leaves, discarded cloak, footprints, interactable clues, UI, title, text, watermark, or modern objects; solid RGB background
Avoid: baked gameplay characters or objects, closed or hidden main gate, photorealism, smooth gradients, blurry pixels, anti-aliased edges, halos, random noise dithering, mixed pixel scales, strong isometric perspective
```

