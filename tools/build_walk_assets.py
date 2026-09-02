from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / "assets" / "art" / "pixel"
NAMES = ["down", "down_right", "right", "up_right", "up"]
OUT_SIZE = 256
PADDING = 18

for name in NAMES:
    source = Image.open(ROOT / f"walk_{name}_sheet_clean.png").convert("RGBA")
    frame_w = source.width // 2
    frames = []
    for index in range(2):
        frame = source.crop((index * frame_w, 0, (index + 1) * frame_w, source.height))
        alpha = frame.getchannel("A")
        bbox = alpha.getbbox()
        if bbox is None:
            raise RuntimeError(f"No visible pixels in {name} frame {index}")
        cropped = frame.crop(bbox)
        scale = min((OUT_SIZE - PADDING * 2) / cropped.width, (OUT_SIZE - PADDING * 2) / cropped.height)
        resized = cropped.resize((max(1, round(cropped.width * scale)), max(1, round(cropped.height * scale))), Image.Resampling.NEAREST)
        canvas = Image.new("RGBA", (OUT_SIZE, OUT_SIZE), (0, 0, 0, 0))
        x = (OUT_SIZE - resized.width) // 2
        y = OUT_SIZE - PADDING - resized.height
        canvas.alpha_composite(resized, (x, y))
        frames.append(canvas)
    strip = Image.new("RGBA", (OUT_SIZE * 2, OUT_SIZE), (0, 0, 0, 0))
    strip.paste(frames[0], (0, 0))
    strip.paste(frames[1], (OUT_SIZE, 0))
    strip.save(ROOT / f"walk_{name}_game.png")
    if name != "down":
        strip.transpose(Image.Transpose.FLIP_LEFT_RIGHT).save(ROOT / f"walk_{name}_left_game.png")
