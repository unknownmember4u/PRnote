import urllib.request
import os
from PIL import Image, ImageDraw, ImageFont

def download_font(url, name):
    if not os.path.exists(name):
        urllib.request.urlretrieve(url, name)

download_font('https://raw.githubusercontent.com/google/fonts/main/ofl/poppins/Poppins-Black.ttf', 'poppins.ttf')

img = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0)) # transparent background
draw = ImageDraw.Draw(img)

bg_color = (38, 166, 154, 255) # #26A69A

font_size = 300
font_pr = ImageFont.truetype('poppins.ttf', font_size)
font_note = ImageFont.truetype('poppins.ttf', int(font_size * 1.1))

pad_x = int(font_size * 0.35)
pad_y = int(font_size * 0.15)
radius = int(font_size * 0.4)

x0 = 100
y0 = 350
x1 = 490
y1 = y0 + 300 + pad_y * 2

draw.rounded_rectangle([x0, y0, x1, y1], radius=radius, fill=bg_color)

draw.text((x0 + pad_x, y0 + pad_y - 20), "PR", font=font_pr, fill=(255, 255, 255, 255))
draw.text((x1 + int(font_size * 0.15), y0 + pad_y - 60), "note", font=font_note, fill=(30, 30, 30, 255))

bbox = img.getbbox()
if bbox:
    cropped = img.crop(bbox)
    new_img = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))
    new_w, new_h = cropped.size
    offset_x = (1024 - new_w) // 2
    offset_y = (1024 - new_h) // 2
    new_img.paste(cropped, (offset_x, offset_y))
    new_img.save('assets/images/app_icon.png')
    new_img.save('assets/images/splash_logo.png')
    new_img.save('assets/images/logo_full.png')
    new_img.save('web/favicon.png')
    print("Success")
