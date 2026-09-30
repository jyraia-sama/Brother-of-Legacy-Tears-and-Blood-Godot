"""Découpe la planche des miniatures du plateau (planche_38.png) : grille 3x3 séparée par des
traits noirs, chaque miniature sur un fond VERT uni. Le vert est rendu transparent, l'image est
recadrée au plus près et rangée dans assets/plateaux/cases/<nom>.png.

Usage :  python3 outils/decouper_miniatures.py planche_38.png
         (ordre par défaut : depart combat elite gardien boss coffre soin mystere piege)
         python3 outils/decouper_miniatures.py planche.png coffre soin   (autres noms / autre ordre)
Si la planche a un fond transparent au lieu de vert, ça marche aussi.
"""
import os
import sys
import numpy as np
from PIL import Image, ImageFilter

ORDRE = ["depart", "combat", "elite", "gardien", "boss", "coffre", "soin", "mystere", "piege"]
DOSSIER = "assets/plateaux/cases"
HAUTEUR = 240     # hauteur maxi de l'image finale (px)
MARGE = 6         # px retirés autour de chaque case (reste du trait noir)
SEUIL = 20        # luminosité moyenne max d'un trait de séparation


def bandes(profil, seuil):
    res, debut = [], None
    for i, v in enumerate(profil):
        if v >= seuil and debut is None:
            debut = i
        elif v < seuil and debut is not None:
            res.append((debut, i)); debut = None
    if debut is not None:
        res.append((debut, len(profil)))
    return [b for b in res if b[1] - b[0] > len(profil) * 0.1]


def detourer(case):
    """Fond vert -> transparent, avec adoucissement des bords et suppression du reflet vert."""
    a = np.asarray(case.convert("RGBA")).astype(float)
    r, g, b, al = a[..., 0], a[..., 1], a[..., 2], a[..., 3]
    exces = g - np.maximum(r, b)                  # à quel point le pixel est « vert »
    # 0 = fond (très vert), 1 = objet ; transition douce entre 40 et 90
    garde = np.clip((90 - exces) / 50.0, 0, 1)
    al = np.minimum(al, garde * 255)
    # Reflet vert sur les bords : on ramène le vert au niveau du rouge/bleu
    g = np.where(exces > 0, np.maximum(r, b) + exces * 0.15, g)
    out = np.dstack([r, g, b, al]).clip(0, 255).astype(np.uint8)
    img = Image.fromarray(out, "RGBA")
    # Ronge 1 px le contour (liseré vert restant)
    alpha = img.getchannel("A").filter(ImageFilter.MinFilter(3))
    img.putalpha(alpha)
    return img


def main():
    args = sys.argv[1:]
    if not args:
        sys.exit(__doc__)
    chemin, noms = args[0], (args[1:] or ORDRE)
    os.makedirs(DOSSIER, exist_ok=True)
    img = Image.open(chemin).convert("RGBA")
    # Les traits de séparation sont noirs ; le fond transparent compte comme clair
    fond = Image.new("RGBA", img.size, (0, 255, 0, 255))
    fond.alpha_composite(img)
    gris = np.asarray(fond.convert("L")).astype(float)
    cols = bandes(gris.mean(axis=0), SEUIL)
    rangs = bandes(gris.mean(axis=1), SEUIL)
    if len(cols) * len(rangs) < len(noms):
        # Pas de traits détectés : on coupe en parts égales (3 x 3)
        w, h = img.size
        cols = [(i * w // 3, (i + 1) * w // 3) for i in range(3)]
        rangs = [(i * h // 3, (i + 1) * h // 3) for i in range(3)]
    print(f"Grille : {len(cols)} colonnes x {len(rangs)} rangées")
    cases = [(x, y) for y in rangs for x in cols]
    for (x, y), nom in zip(cases, noms):
        case = fond.crop((x[0] + MARGE, y[0] + MARGE, x[1] - MARGE, y[1] - MARGE))
        mini = detourer(case)
        boite = mini.getchannel("A").point(lambda v: 255 if v > 30 else 0).getbbox()
        if boite is None:
            print(f"  {nom} : case vide, ignorée")
            continue
        mini = mini.crop(boite)
        if mini.height > HAUTEUR:
            mini = mini.resize((round(mini.width * HAUTEUR / mini.height), HAUTEUR), Image.LANCZOS)
        cible = f"{DOSSIER}/{nom}.png"
        mini.save(cible, optimize=True)
        print(f"  {cible}  ({mini.width}x{mini.height})")


if __name__ == "__main__":
    main()
