#!/usr/bin/env fish

set img "/tmp/snip.png"
set img2 "/tmp/snip_clean.png"

set region (slurp)
if test -z "$region"
    exit 1
end

grim -g "$region" "$img"

# improve image for OCR
convert "$img" -colorspace Gray -contrast -sharpen 0x1 "$img2"

set code (zbarimg --raw "$img" ^/dev/null)

if test "$code" != ""
    echo -n "$code" | wl-copy
else
    tesseract "$img2" stdout --psm 6 | wl-copy
end

# Requirements:
# - slurp        → select region on screen
# - grim         → take screenshot (Wayland)
# - tesseract    → OCR (extract text from image)
# - tesseract-data-eng → English language data for OCR
# - zbar         → QR/barcode scanner (zbarimg)
# - wl-clipboard → clipboard tool (wl-copy)
# - imagemagick  → (optional) improves OCR accuracy (convert)
#
# Install (Arch):
# sudo pacman -S slurp grim tesseract tesseract-data-eng zbar wl-clipboard imagemagick
#
# What this script does:
# 1. Select screen region
# 2. Take screenshot
# 3. Try QR/barcode scan
# 4. If found → copy to clipboard
# 5. Else → run OCR and copy text