from PIL import Image, ImageDraw
import os

# Icon only. poster.png is the original hand-made art and is left alone.
# Rendered at 256 and downscaled to 32 with LANCZOS so the strokes stay
# clean at icon scale; PZ shows this next to the mod name in the mod list.
RENDER = 256
OUT = 32

BG = (30, 30, 35)
ORANGE = (220, 160, 40)
FRAME = (180, 180, 180)

img = Image.new("RGB", (RENDER, RENDER), BG)
draw = ImageDraw.Draw(img)

# --- Window: 2x2 panes, bold enough to survive the downscale ---
X0, Y0, X1, Y1 = 56, 40, 200, 216
STROKE = 12
draw.rectangle([X0, Y0, X1, Y1], outline=FRAME, width=STROKE)
midx = (X0 + X1) // 2
midy = (Y0 + Y1) // 2
draw.line([(midx, Y0), (midx, Y1)], fill=FRAME, width=STROKE)
draw.line([(X0, midy), (X1, midy)], fill=FRAME, width=STROKE)

# --- Arrow through the window, drawn over the frame ---
BAR_H = 40
HEAD_W = 52
HEAD_H = 96
tip = 248
draw.rectangle([8, midy - BAR_H // 2, tip - HEAD_W, midy + BAR_H // 2], fill=ORANGE)
draw.polygon(
    [(tip, midy), (tip - HEAD_W, midy - HEAD_H // 2), (tip - HEAD_W, midy + HEAD_H // 2)],
    fill=ORANGE,
)

icon = img.resize((OUT, OUT), Image.LANCZOS)
path = os.path.join(os.path.dirname(__file__), "icon.png")
icon.save(path)
print(f"Saved to {path}")
