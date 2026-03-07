import urllib.request
import zipfile
import os
from PIL import Image, ImageDraw, ImageFont

os.makedirs('assets/images', exist_ok=True)

# Download Montserrat and Bricolage Grotesque or similar bold fonts
# Here we just use a default or download a true type font
url = 'https://github.com/google/fonts/raw/main/ofl/montserrat/Montserrat-ExtraBold.ttf'
urllib.request.urlretrieve(url, 'Montserrat-ExtraBold.ttf')

img = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0)) # transparent background
draw = ImageDraw.Draw(img)

# Draw rounded rectangle background (primary color, e.g., teal/mint)
bg_color = (38, 166, 154) # theme primary color
x0, y0, x1, y1 = 150, 250, 480, 520
# Pillow rounded_rectangle requires 8.2.0+, to be safe we'll use regular rect + ellipses or just a circle
# Since we want it like the PR vector which is a rounded rect padding PR...
def draw_rounded_rect(draw, bbox, radius, color):
    x0, y0, x1, y1 = bbox
    draw.rectangle([x0, y0+radius, x1, y1-radius], fill=color)
    draw.rectangle([x0+radius, y0, x1-radius, y1], fill=color)
    draw.pieslice([x0, y0, x0+2*radius, y0+2*radius], 180, 270, fill=color)
    draw.pieslice([x1-2*radius, y0, x1, y0+2*radius], 270, 360, fill=color)
    draw.pieslice([x0, y1-2*radius, x0+2*radius, y1], 90, 180, fill=color)
    draw.pieslice([x1-2*radius, y1-2*radius, x1, y1], 0, 90, fill=color)

draw_rounded_rect(draw, (80, 280, 430, 680), 80, bg_color)

font_pr = ImageFont.truetype('Montserrat-ExtraBold.ttf', 240)
font_note = ImageFont.truetype('Montserrat-ExtraBold.ttf', 250)

# "PR" inside the box
# Calculate position to center PR
# We'll just approximate
draw.text((120, 350), "PR", font=font_pr, fill=(255, 255, 255))

# "note" outside
draw.text((460, 350), "note", font=font_note, fill=(30, 30, 30))

img.save('assets/images/app_icon.png')
img.save('assets/images/splash_logo.png')
img.save('assets/images/logo_full.png')
print("Generated PRnote logo images without sparkles.")
