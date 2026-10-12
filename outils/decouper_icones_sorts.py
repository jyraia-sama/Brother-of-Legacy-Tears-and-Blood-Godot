"""Découpe une planche d'icônes de sorts (grille 3 x 2 séparée par des traits noirs, fond vert)
en icônes carrées 256 px à fond transparent : assets/sorts/<nom>.png.

Usage :  python3 outils/decouper_icones_sorts.py planche.png nom1 nom2 nom3 nom4 nom5 nom6
         (ordre : ligne du haut de gauche à droite, puis ligne du bas ; « - » = case ignorée)
"""
import os
import sys
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from decouper_miniatures import detourer  # noqa: E402
from decouper_portrait_figurine import sans_reflet_vert  # noqa: E402

TAILLE = 256
MARGE = 8


def coupures(profil, n, total):
    """Positions des n-1 traits noirs (minimums du profil autour des fractions attendues)."""
    res = []
    for k in range(1, n):
        c = int(total * k / n)
        a, b = c - total // 12, c + total // 12
        res.append(a + int(np.argmin(profil[a:b])))
    return [0] + res + [total]


def main():
    args = sys.argv[1:]
    img = Image.open(args[0]).convert("RGBA")
    noms = args[1:]
    gris = np.asarray(img.convert("L")).astype(float)
    xs = coupures(gris.mean(axis=0), 3, img.width)
    ys = coupures(gris.mean(axis=1), 2, img.height)
    os.makedirs("assets/sorts", exist_ok=True)
    i = 0
    for r in range(2):
        for c in range(3):
            nom = noms[i] if i < len(noms) else "-"
            i += 1
            if nom == "-":
                continue
            case = img.crop((xs[c] + MARGE, ys[r] + MARGE, xs[c + 1] - MARGE, ys[r + 1] - MARGE))
            fond = Image.new("RGBA", case.size, (0, 255, 0, 255))
            fond.alpha_composite(case)
            ic = sans_reflet_vert(detourer(fond))
            boite = ic.getchannel("A").point(lambda v: 255 if v > 30 else 0).getbbox()
            ic = ic.crop(boite)
            cote = max(ic.size)
            carre = Image.new("RGBA", (cote, cote), (0, 0, 0, 0))
            carre.alpha_composite(ic, ((cote - ic.width) // 2, (cote - ic.height) // 2))
            carre = carre.resize((TAILLE, TAILLE), Image.LANCZOS)
            carre.save(f"assets/sorts/{nom}.png", optimize=True)
            print(f"  {nom}.png")


if __name__ == "__main__":
    main()
