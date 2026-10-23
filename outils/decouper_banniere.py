"""Bannière d'événement d'invocation : garde la bande horizontale centrale d'une image ChatGPT
(1536x1024) et la range dans assets/invocation/evenements/<id>.png (1600 x 320).

Usage :  python3 outils/decouper_banniere.py image.png <id_evenement> [--haut=0.34]
  --haut : où commence la bande (fraction de la hauteur, 0.34 par défaut ; la bande fait 31 % de la hauteur)
"""
import os
import sys
from PIL import Image

args = [a for a in sys.argv[1:] if not a.startswith("--")]
haut = 0.34
for a in sys.argv[1:]:
    if a.startswith("--haut="):
        haut = float(a.split("=", 1)[1])
img = Image.open(args[0]).convert("RGB")
w, h = img.size
bande = int(h * 0.3125)
y = int(h * haut)
y = max(0, min(h - bande, y))
out = img.crop((0, y, w, y + bande)).resize((1600, 320), Image.LANCZOS)
os.makedirs("assets/invocation/evenements", exist_ok=True)
cible = "assets/invocation/evenements/%s.png" % args[1]
out.save(cible, optimize=True)
print(" ", cible, out.size)
