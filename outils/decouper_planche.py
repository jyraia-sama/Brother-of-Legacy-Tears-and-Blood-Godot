"""Découpe une planche de portraits ChatGPT (grille séparée par des traits noirs)
en un fichier PNG par unité dans assets/unites/.

Usage :  python outils/decouper_planche.py planche_01.png brute_noire barbe_bleue ...
(les identifiants dans l'ordre des cases : gauche -> droite, haut -> bas)
Familiers : ajouter --familiers pour ranger les images dans assets/familiers/.
"""
import sys
import numpy as np
from PIL import Image

TAILLE = 384      # côté du portrait final (px)
MARGE = 4         # px retirés autour de chaque case (reste du trait noir)
SEUIL = 20        # luminosité moyenne max d'une ligne de séparation


def bandes(profil, seuil):
    """Renvoie les intervalles [début, fin[ qui ne sont PAS des traits noirs."""
    res, debut = [], None
    for i, v in enumerate(profil):
        if v >= seuil and debut is None:
            debut = i
        elif v < seuil and debut is not None:
            res.append((debut, i)); debut = None
    if debut is not None:
        res.append((debut, len(profil)))
    return [b for b in res if b[1] - b[0] > len(profil) * 0.1]  # ignore les miettes


def main():
    args = [a for a in sys.argv[1:] if a != "--familiers"]
    dossier = "assets/familiers" if "--familiers" in sys.argv else "assets/unites"
    chemin, ids = args[0], args[1:]
    img = Image.open(chemin).convert("RGB")
    gris = np.asarray(img.convert("L")).astype(float)
    cols = bandes(gris.mean(axis=0), SEUIL)
    rangs = bandes(gris.mean(axis=1), SEUIL)
    cases = [(x, y) for y in rangs for x in cols]
    print(f"Grille détectée : {len(cols)} colonnes x {len(rangs)} rangées")
    if len(cases) < len(ids):
        sys.exit(f"ERREUR : {len(cases)} cases trouvées pour {len(ids)} identifiants")
    for (x, y), uid in zip(cases, ids):
        x0, x1, y0, y1 = x[0] + MARGE, x[1] - MARGE, y[0] + MARGE, y[1] - MARGE
        c = min(x1 - x0, y1 - y0)                      # carré centré
        cx, cy = (x0 + x1) // 2, (y0 + y1) // 2
        boite = (cx - c // 2, cy - c // 2, cx - c // 2 + c, cy - c // 2 + c)
        img.crop(boite).resize((TAILLE, TAILLE), Image.LANCZOS).save(f"{dossier}/{uid}.png", optimize=True)
        print(f"  {uid}.png")


if __name__ == "__main__":
    main()
