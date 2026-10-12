"""Découpe les planches du KIT D'INTERFACE PEINT (PROMPTS_KIT_UI.md) et range les pièces dans
assets/ui/kit/ (elles remplacent le kit dessiné en code, mêmes noms, mêmes tailles).

Usage :  python3 outils/decouper_kit_ui.py 1 planche1.png   (boutons et onglets, grille 3 x 2)
         python3 outils/decouper_kit_ui.py 2 planche2.png   (champ, coin, plaque, séparateur, grille 2 x 2)
         python3 outils/decouper_kit_ui.py 3 planche3.png   (grand cadre de panneau, image entière)

Les pièces sont réduites en gardant leurs extrémités intactes : on retire une bande au MILIEU
(là où le décor est uni) au lieu d'écraser l'image, pour que les coins restent nets en 9-slice.
"""
import os
import sys
import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from decouper_miniatures import detourer  # noqa: E402
from decouper_portrait_figurine import sans_reflet_vert  # noqa: E402

D = "assets/ui/kit"
MARGE = 8

PLANCHES = {
    "1": (3, 2, [("bouton", 96, 48), ("bouton_survol", 96, 48), ("bouton_appui", 96, 48),
                 ("bouton_inactif", 96, 48), ("onglet_actif", 96, 40), ("onglet", 96, 40)]),
    "2": (2, 2, [("champ", 96, 48), ("coin", 48, 48), ("plaque_titre", 256, 56), ("separateur", 512, 16)]),
    "3": (1, 1, [("cadre", 128, 128)]),
}


def coupures(profil, n, total):
    res = []
    for k in range(1, n):
        c = int(total * k / n)
        a, b = c - total // 12, c + total // 12
        res.append(a + int(np.argmin(profil[a:b])))
    return [0] + res + [total]


def retirer_milieu(img, w, h):
    """Met l'image à la taille w x h : mise à l'échelle sur l'axe le plus contraint, puis on retire
    une bande au milieu de l'autre axe (les extrémités ornées restent intactes)."""
    k = max(w / img.width, h / img.height)
    img = img.resize((max(w, round(img.width * k)), max(h, round(img.height * k))), Image.LANCZOS)
    if img.width > w:
        g = w // 2
        out = Image.new("RGBA", (w, img.height))
        out.paste(img.crop((0, 0, g, img.height)), (0, 0))
        out.paste(img.crop((img.width - (w - g), 0, img.width, img.height)), (g, 0))
        img = out
    if img.height > h:
        g = h // 2
        out = Image.new("RGBA", (img.width, h))
        out.paste(img.crop((0, 0, img.width, g)), (0, 0))
        out.paste(img.crop((0, img.height - (h - g), img.width, img.height)), (0, g))
        img = out
    return img


def lueur(img, marge=6, couleur=(255, 170, 70)):
    """Ajoute une lueur dorée autour (bouton survolé) : l'image grandit de « marge » px de chaque côté."""
    big = Image.new("RGBA", (img.width + 2 * marge, img.height + 2 * marge), (0, 0, 0, 0))
    a = img.getchannel("A")
    halo = Image.new("RGBA", big.size, couleur + (0,))
    m = Image.new("L", big.size, 0)
    m.paste(a, (marge, marge))
    m = m.filter(ImageFilter.GaussianBlur(4)).point(lambda v: int(v * 0.55))
    halo.putalpha(m)
    big.alpha_composite(halo)
    big.alpha_composite(img, (marge, marge))
    return big


def eclaircir(img, k=1.25):
    a = np.asarray(img).astype(float)
    a[..., :3] = np.clip(a[..., :3] * k, 0, 255)
    return Image.fromarray(a.astype(np.uint8), "RGBA")


def main():
    num, chemin = sys.argv[1], sys.argv[2]
    cols, lignes, pieces = PLANCHES[num]
    img = Image.open(chemin).convert("RGBA")
    gris = np.asarray(img.convert("L")).astype(float)
    xs = coupures(gris.mean(axis=0), cols, img.width) if cols > 1 else [0, img.width]
    ys = coupures(gris.mean(axis=1), lignes, img.height) if lignes > 1 else [0, img.height]
    os.makedirs(D, exist_ok=True)
    i = 0
    for r in range(lignes):
        for c in range(cols):
            nom, w, h = pieces[i]
            i += 1
            case = img.crop((xs[c] + MARGE, ys[r] + MARGE, xs[c + 1] - MARGE, ys[r + 1] - MARGE))
            fond = Image.new("RGBA", case.size, (0, 255, 0, 255))
            fond.alpha_composite(case)
            p = sans_reflet_vert(detourer(fond))
            boite = p.getchannel("A").point(lambda v: 255 if v > 30 else 0).getbbox()
            p = retirer_milieu(p.crop(boite), w, h)
            if nom == "bouton_survol":
                p = lueur(p)
            p.save(f"{D}/{nom}.png", optimize=True)
            print(f"  {nom}.png  {p.size}")
            # pièces dérivées
            if nom == "onglet":
                eclaircir(p, 1.3).save(f"{D}/onglet_survol.png", optimize=True)
                print("  onglet_survol.png (dérivé)")
            if nom == "champ":
                eclaircir(p, 1.4).save(f"{D}/champ_actif.png", optimize=True)
                print("  champ_actif.png (dérivé)")


if __name__ == "__main__":
    main()
