# Late chapters generation record

- Date: 2026-09-15
- Generator: Codex built-in image generation
- Runtime outputs: `trial.png`, `golgotha.png`, `tomb.png`, `dawn.png`
- Preserved originals: matching files under `source/`
- Processing: `tools/process_world_backgrounds.gd`
- Output contract: 2048×720 RGB PNG, nearest resize, adaptive 64-color palette
- Status: runtime-final; human camera review pending

## Shared constraints

All prompts required crisp square-pixel rendering, 3/4 top-down framing, a clear lower traversal band, warm upper-left lighting with indigo shadows, and no UI, text, watermark, foreground gameplay characters, or movable clues.

## Trial

```text
A clean environment-only outer courtyard and street before a Roman governor's Jerusalem praetorium at first light. A restrained sandstone civic facade and closed gate occupy the upper band, with a right side alley and low walls guiding a readable path. Cool indigo predawn shadows and warm early sunlight. Exact 2048×720. Open staging areas near the configured witness positions. No people, player, soldiers, herald, crowd, fire, labels, UI, buttons, text, or watermark.
```

## Golgotha

```text
A clean environment-only open area below Golgotha outside ancient Jerusalem in late afternoon. A rocky upper-right hill has three distant unoccupied wooden crosses; Jerusalem walls recede at upper left. Low sandstone walls, sparse olive trees, rocks, and a broad dusty foreground. Solemn and indirect. Exact 2048×720. No people, player, soldiers, bodies, blood, cloth, bowl, UI, text, or watermark.
```

## Tomb

```text
A clean environment-only first-century rock-cut tomb garden outside Jerusalem at early dawn. The open dark tomb entrance and rolled-aside round sealing stone are fixed architecture in the upper-right band. Terraced sandstone walls, olives, cypresses, a left path, and broad empty ground. Exact 2048×720. No people, angels, player, cloth, body, gameplay clues, UI, title, text, watermark, wings, halo, or fantasy glow.
```

## Dawn

```text
A clean environment-only empty dawn road leaving a first-century Jerusalem garden. The road opens toward a softly lit horizon with low sandstone walls, sparse olive trees, and distant city silhouettes. It echoes Chapter 1's warm palette while remaining quiet and open, with an uncluttered center for separately rendered epilogue panels. Exact 2048×720. No people, player, crosses, UI, text, credits, or watermark.
```

