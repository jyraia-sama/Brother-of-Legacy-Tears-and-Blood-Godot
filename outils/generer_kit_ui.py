"""Génère le KIT D'INTERFACE de secours (dessiné en code) dans assets/ui/kit/ :
boutons (normal / survol / appuyé / désactivé), onglets, coin ornemental, séparateur, glissière.
Ces images servent de StyleBox 9-slice au thème du jeu (scripts/theme_jeu.gd).
Le kit PEINT (PROMPTS_KIT_UI.md, découpé par outils/decouper_kit_ui.py) les remplace fichier par fichier.

Usage : python3 outils/generer_kit_ui.py
"""
import math
import os
from PIL import Image, ImageDraw, ImageFilter

D = "assets/ui/kit"
SS = 4  # suréchantillonnage (bords lisses)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))


def degrade_v(w, h, haut, bas):
    im = Image.new("RGBA", (w, h))
    px = im.load()
    for y in range(h):
        c = lerp(haut, bas, y / max(1, h - 1))
        for x in range(w):
            px[x, y] = c
    return im


def masque_arrondi(w, h, r):
    m = Image.new("L", (w, h), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, w - 1, h - 1), r, fill=255)
    return m


def bouton(nom, haut, bas, or_haut, or_bas, lueur=None, inverse=False, w=96, h=48, r=9):
    W, H, R = w * SS, h * SS, r * SS
    marge = 6 * SS if lueur else 0
    img = Image.new("RGBA", (W + 2 * marge, H + 2 * marge), (0, 0, 0, 0))
    if lueur:
        g = Image.new("RGBA", img.size, (0, 0, 0, 0))
        ImageDraw.Draw(g).rounded_rectangle((marge, marge, marge + W - 1, marge + H - 1), R, fill=lueur)
        g = g.filter(ImageFilter.GaussianBlur(4 * SS))
        img.alpha_composite(g)
    # contour sombre
    base = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(base).rounded_rectangle((0, 0, W - 1, H - 1), R, fill=(12, 6, 6, 255))
    # bordure dorée (dégradé métal)
    b = 1 * SS
    orr = degrade_v(W - 2 * b, H - 2 * b, or_bas if inverse else or_haut, or_haut if inverse else or_bas)
    base.paste(orr, (b, b), masque_arrondi(W - 2 * b, H - 2 * b, R - b))
    # fond
    e = 3 * SS
    fond = degrade_v(W - 2 * e, H - 2 * e, bas if inverse else haut, haut if inverse else bas)
    base.paste(fond, (e, e), masque_arrondi(W - 2 * e, H - 2 * e, R - e))
    # reflet en haut
    d = ImageDraw.Draw(base)
    if not inverse:
        refl = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ImageDraw.Draw(refl).rounded_rectangle((e + 2 * SS, e + 1 * SS, W - e - 2 * SS, e + (H - 2 * e) // 2), R - e,
                                               fill=(255, 235, 200, 26))
        base.alpha_composite(refl)
        d.line((e + R // 2, e + SS, W - e - R // 2, e + SS), fill=(255, 225, 170, 70), width=SS)
    else:
        d.line((e + R // 2, e + SS, W - e - R // 2, e + SS), fill=(0, 0, 0, 120), width=2 * SS)
    img.alpha_composite(base, (marge, marge))
    img = img.resize((img.width // SS, img.height // SS), Image.LANCZOS)
    img.save(f"{D}/{nom}.png")


def onglet(nom, haut, bas, or_c, actif):
    W, H, R = 96 * SS, 40 * SS, 9 * SS
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    m = Image.new("L", (W, H + R), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, W - 1, H + R), R, fill=255)
    m = m.crop((0, 0, W, H))
    bord = degrade_v(W, H, or_c, lerp(or_c, (40, 20, 10, 255), 0.6))
    img.paste(bord, (0, 0), m)
    e = 2 * SS
    m2 = Image.new("L", (W - 2 * e, H + R), 0)
    ImageDraw.Draw(m2).rounded_rectangle((0, 0, W - 2 * e - 1, H + R), R - e, fill=255)
    img.paste(degrade_v(W - 2 * e, H - e, haut, bas), (e, e), m2.crop((0, 0, W - 2 * e, H - e)))
    if actif:
        ImageDraw.Draw(img).line((R, e + SS, W - R, e + SS), fill=(255, 225, 160, 150), width=SS)
    img.resize((96, 40), Image.LANCZOS).save(f"{D}/{nom}.png")


def coin(nom="coin", t=48):
    """Ornement de coin (haut-gauche) : équerre dorée, losange, petites volutes."""
    T = t * SS
    img = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    or_c, or_f, ombre = (232, 188, 96, 255), (150, 98, 40, 255), (0, 0, 0, 170)
    for dec, coul, ep in [(SS, ombre, 5 * SS), (0, or_f, 5 * SS), (0, or_c, 3 * SS)]:
        o = 3 * SS + dec
        d.line((o, o, T * 0.86, o), fill=coul, width=ep)
        d.line((o, o, o, T * 0.86), fill=coul, width=ep)
        d.line((o + 7 * SS, o + 7 * SS, T * 0.55, o + 7 * SS), fill=coul, width=max(SS, ep // 2))
        d.line((o + 7 * SS, o + 7 * SS, o + 7 * SS, T * 0.55), fill=coul, width=max(SS, ep // 2))
    # losange central dans l'angle
    c = 9 * SS
    for coul, k in [(ombre, 8.5), (or_f, 8), (or_c, 6), ((255, 240, 200, 255), 2.5)]:
        k *= SS
        d.polygon([(c, c - k), (c + k, c), (c, c + k), (c - k, c)], fill=coul)
    # pointes au bout des branches
    for (x, y) in [(T * 0.86, 3 * SS), (3 * SS, T * 0.86)]:
        k = 4 * SS
        d.polygon([(x - k, y - k + 3 * SS), (x + k, y + 3 * SS), (x - k, y + k + 3 * SS)] if y < T / 2 else
                  [(x - k + 3 * SS, y - k), (x + 3 * SS, y + k), (x + k + 3 * SS, y - k)], fill=or_c)
    img.resize((t, t), Image.LANCZOS).save(f"{D}/{nom}.png")


def separateur():
    W, H = 512 * SS, 16 * SS
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = img.load()
    cy = H // 2
    for x in range(W):
        a = math.sin(math.pi * x / W) ** 1.2
        for dy in range(-SS // 2, SS // 2 + 1):
            px[x, cy + dy] = (220, 170, 80, int(170 * a))
    d = ImageDraw.Draw(img)
    for coul, k in [((60, 30, 10, 255), 5.5), ((232, 188, 96, 255), 4.5), ((255, 240, 200, 255), 1.8)]:
        k *= SS
        d.polygon([(W / 2, cy - k), (W / 2 + k * 1.6, cy), (W / 2, cy + k), (W / 2 - k * 1.6, cy)], fill=coul)
    img.resize((512, 16), Image.LANCZOS).save(f"{D}/separateur.png")


def plaque_titre():
    """Plaque derrière les titres d'écran : bande sombre, filets dorés haut et bas, losanges aux bouts."""
    W, H = 256 * SS, 56 * SS
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = img.load()
    for x in range(W):
        bord = min(x, W - 1 - x) / (W * 0.18)
        a = max(0.0, min(1.0, bord))
        for y in range(6 * SS, H - 6 * SS):
            px[x, y] = (18, 6, 8, int(200 * a))
        for y0 in (5 * SS, H - 6 * SS):
            for dy in range(SS):
                px[x, y0 + dy] = (226, 178, 92, int(230 * a))
    d = ImageDraw.Draw(img)
    for cx in (14 * SS, W - 14 * SS):
        for coul, k in [((60, 30, 10, 255), 7), ((232, 188, 96, 255), 5.5), ((255, 240, 200, 255), 2)]:
            k *= SS
            d.polygon([(cx, H / 2 - k), (cx + k, H / 2), (cx, H / 2 + k), (cx - k, H / 2)], fill=coul)
    img.resize((256, 56), Image.LANCZOS).save(f"{D}/plaque_titre.png")


def main():
    os.makedirs(D, exist_ok=True)
    OR, OR_F = (238, 196, 110, 255), (120, 74, 30, 255)
    bouton("bouton", (74, 30, 30, 255), (28, 10, 12, 255), OR, OR_F)
    bouton("bouton_survol", (112, 46, 38, 255), (46, 16, 16, 255), (255, 222, 150, 255), (160, 104, 44, 255),
           lueur=(255, 170, 70, 120))
    bouton("bouton_appui", (60, 22, 22, 255), (22, 8, 9, 255), OR, OR_F, inverse=True)
    bouton("bouton_inactif", (52, 46, 46, 255), (26, 23, 24, 255), (120, 112, 106, 255), (60, 55, 52, 255))
    bouton("champ", (12, 7, 8, 255), (24, 14, 15, 255), (150, 110, 60, 255), (90, 60, 30, 255), inverse=True)
    bouton("champ_actif", (14, 8, 9, 255), (28, 16, 17, 255), (255, 210, 120, 255), (170, 110, 40, 255), inverse=True)
    onglet("onglet_actif", (110, 44, 36, 255), (50, 18, 18, 255), (240, 200, 115, 255), True)
    onglet("onglet", (40, 22, 22, 255), (22, 12, 12, 255), (120, 90, 55, 255), False)
    onglet("onglet_survol", (70, 32, 28, 255), (34, 14, 14, 255), (200, 160, 90, 255), False)
    coin()
    separateur()
    plaque_titre()
    # glissière (barre de défilement) : rail sombre + poignée dorée
    bouton("glissiere_rail", (10, 6, 6, 255), (20, 12, 12, 255), (70, 50, 35, 255), (40, 28, 20, 255),
           inverse=True, w=16, h=48, r=7)
    bouton("glissiere_poignee", (210, 160, 80, 255), (130, 82, 34, 255), (255, 225, 150, 255), (90, 55, 20, 255),
           w=16, h=48, r=7)
    bouton("glissiere_poignee_survol", (245, 200, 110, 255), (170, 110, 45, 255), (255, 240, 190, 255),
           (110, 70, 25, 255), w=16, h=48, r=7)
    print("kit généré dans", D)


if __name__ == "__main__":
    main()
