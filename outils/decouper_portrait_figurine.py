"""Découpe une image « portrait + figurine » (méthode v0.59, PROMPTS_FIGURINES_3D.md) :
image paysage coupée en deux par un trait noir vertical.
  - moitié gauche : le portrait -> recadré en carré sur le haut -> assets/unites/<id>.png (384 px)
  - moitié droite : la figurine sur fond vert -> détourée, recadrée -> assets/figurines/<id>.png (1024 px de haut max)

Usage :  python3 outils/decouper_portrait_figurine.py image.png <identifiant> [--sans-portrait] [--sans-figurine] [--spectre]\n  --spectre : créature translucide (fantôme) : retire la teinte verte qui transparaît dans les voiles
"""
import os
import sys
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from decouper_miniatures import detourer  # noqa: E402

TAILLE_PORTRAIT = 384
HAUTEUR_FIGURINE = 1024
MARGE = 10


def trait_central(img: Image.Image) -> int:
    """Colonne du trait noir vertical, cherchée entre 40 et 60 % de la largeur."""
    gris = np.asarray(img.convert("L")).astype(float)
    profil = gris.mean(axis=0)
    w = img.width
    a, b = int(w * 0.4), int(w * 0.6)
    return a + int(np.argmin(profil[a:b]))


def bords_noirs(img: Image.Image) -> tuple:
    """Retire le cadre noir éventuel autour d'une moitié (lignes et colonnes presque noires)."""
    gris = np.asarray(img.convert("L")).astype(float)
    lignes = np.where(gris.mean(axis=1) > 25)[0]
    cols = np.where(gris.mean(axis=0) > 25)[0]
    if len(lignes) == 0 or len(cols) == 0:
        return (0, 0, img.width, img.height)
    return (int(cols[0]), int(lignes[0]), int(cols[-1]) + 1, int(lignes[-1]) + 1)


def sans_reflet_vert(img: Image.Image) -> Image.Image:
    """Créatures translucides (fantômes, voiles) : le vert du fond transparaît et rend les voiles
    bleus turquoise. On ramène le vert au niveau moyen du rouge et du bleu là où il dépasse."""
    a = np.asarray(img).astype(float)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    plafond = (r + b) / 2.0 + 8.0
    a[..., 1] = np.where(g > plafond, plafond + (g - plafond) * 0.15, g)
    return Image.fromarray(a.clip(0, 255).astype(np.uint8), "RGBA")


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if len(args) < 2:
        sys.exit(__doc__)
    chemin, ident = args[0], args[1]
    img = Image.open(chemin).convert("RGBA")
    x = trait_central(img)
    gauche = img.crop((MARGE, MARGE, x - MARGE, img.height - MARGE))
    droite = img.crop((x + MARGE, MARGE, img.width - MARGE, img.height - MARGE))

    if "--sans-portrait" not in sys.argv:
        gauche = gauche.crop(bords_noirs(gauche))
        cote = min(gauche.width, gauche.height)
        carre = gauche.crop((0, 0, cote, cote)).convert("RGB")
        carre = carre.resize((TAILLE_PORTRAIT, TAILLE_PORTRAIT), Image.LANCZOS)
        cible = f"assets/unites/{ident}.png"
        carre.save(cible, optimize=True)
        print(f"  portrait  -> {cible}")

    if "--sans-figurine" not in sys.argv:
        fond = Image.new("RGBA", droite.size, (0, 255, 0, 255))
        fond.alpha_composite(droite)
        fig = detourer(fond)
        boite = fig.getchannel("A").point(lambda v: 255 if v > 30 else 0).getbbox()
        if boite is None:
            sys.exit("figurine introuvable (fond vert ?)")
        fig = fig.crop(boite)
        if "--spectre" in sys.argv:
            fig = sans_reflet_vert(fig)
        if fig.height > HAUTEUR_FIGURINE:
            fig = fig.resize((round(fig.width * HAUTEUR_FIGURINE / fig.height), HAUTEUR_FIGURINE), Image.LANCZOS)
        cible = f"assets/figurines/{ident}.png"
        fig.save(cible, optimize=True)
        print(f"  figurine  -> {cible}  ({fig.width}x{fig.height})")


if __name__ == "__main__":
    main()
