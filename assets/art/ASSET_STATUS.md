# Art asset status

Status terms:

- **runtime-final**: clean, source-backed asset currently used by the game.
- **runtime-support**: valid gameplay asset retained from the recovered build.
- **reference-only**: not loaded by the game.
- **needs-human-review**: technically valid but still requires an artist/player review.

| Asset family | Status | Notes |
| --- | --- | --- |
| Chapter 1 Jerusalem gate | runtime-final, needs-human-review | Regenerated without baked crowd, Jesus/donkey, UI, or clues. |
| Chapter 2 temple market | runtime-final, needs-human-review | Regenerated without baked UI, characters, coins, movable table, or prayer cloth. |
| Chapter 3 courtyard | runtime-final, needs-human-review | Regenerated neutral base for the existing time-of-day shader. |
| Chapter 4 trial courtyard | runtime-final, needs-human-review | Regenerated without baked witnesses or UI. |
| Chapter 5 Golgotha | runtime-final, needs-human-review | Regenerated without people or graphic content; distant empty crosses are static scenery. |
| Chapter 6 tomb | runtime-final, needs-human-review | Regenerated without witnesses, UI, or gameplay markers. |
| Epilogue dawn road | runtime-final, needs-human-review | Regenerated as an empty environment for overlay text. |
| Player 8-direction walk | runtime-support | Four frames per direction; runtime and traversal tests remain authoritative. |
| World NPCs | runtime-support, needs-human-review | Continuity registry is authoritative; moving-NPC sheet expansion remains a later art pass. |
| Biblical/cutscene cast | runtime-support, needs-human-review | Distinct role assets preserved; no original model metadata survived recovery. |

No capture containing game UI, dialogue, buttons, or baked foreground NPCs remains in a runtime background path.
