from PIL import Image, ImageDraw, ImageFont

SIZE = 1024
bg_top = (14, 22, 14)      # #0e160e
bg_bottom = (8, 13, 8)     # #080d08
accent = (0, 230, 100)     # #00e664
accent_dark = (0, 184, 79) # #00b84f
text_color = (232, 245, 232)  # #e8f5e8
border_color = (30, 46, 30)   # #1e2e1e

img = Image.new('RGB', (SIZE, SIZE), bg_top)
draw = ImageDraw.Draw(img)

# Fond degrade diagonal simple
for y in range(SIZE):
    t = y / SIZE
    r = int(bg_top[0] + (bg_bottom[0] - bg_top[0]) * t)
    g = int(bg_top[1] + (bg_bottom[1] - bg_top[1]) * t)
    b = int(bg_top[2] + (bg_bottom[2] - bg_top[2]) * t)
    draw.line([(0, y), (SIZE, y)], fill=(r, g, b))

# Coins arrondis (masque)
radius = 220
mask = Image.new('L', (SIZE, SIZE), 0)
mdraw = ImageDraw.Draw(mask)
mdraw.rounded_rectangle([0, 0, SIZE - 1, SIZE - 1], radius=radius, fill=255)

rounded = Image.new('RGB', (SIZE, SIZE), (0, 0, 0))
rounded.paste(img, (0, 0), mask)
img = rounded
draw = ImageDraw.Draw(img)

# Bordure interieure fine
draw.rounded_rectangle([24, 24, SIZE - 25, SIZE - 25], radius=200, outline=border_color, width=6)

# Ballon de football stylise (cercle + pentagone central + lacets)
cx, cy, r = 512, 420, 230
draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=accent, width=16)

import math
pent_r = 95
pts = []
for i in range(5):
    angle = math.radians(-90 + i * 72)
    pts.append((cx + pent_r * math.cos(angle), cy + pent_r * math.sin(angle)))
draw.polygon(pts, fill=accent)

for px, py in pts:
    outer_x = cx + (px - cx) * 1.55
    outer_y = cy + (py - cy) * 1.55
    draw.line([(px, py), (outer_x, outer_y)], fill=accent, width=14)

# Monogramme PX
font = ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf', 220)
text = 'PX'
bbox = draw.textbbox((0, 0), text, font=font)
tw = bbox[2] - bbox[0]
th = bbox[3] - bbox[1]
draw.text((cx - tw / 2 - bbox[0], 790 - th / 2 - bbox[1] - 15), text, font=font, fill=text_color)

img.save('C:/Users/daveo/pronoxpert/flutter_app/assets/icon/icon.png')
print('icon.png genere:', img.size)
