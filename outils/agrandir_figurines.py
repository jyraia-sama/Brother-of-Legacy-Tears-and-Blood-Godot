"""AGRANDIR LES FIGURINES (x2, Real-ESRGAN, sur processeur, sans carte graphique).

Les figurines découpées par decouper_miniatures.py font 420 px de haut : trop peu pour les combats 3D.
Cet outil les double (840 px) avec le modèle Real-ESRGAN « realesr-animevideov3-x2 » (environ 6 s par image).

Préparation (une fois) : télécharger realesrgan-ncnn-vulkan-20220424-ubuntu.zip (ou -windows.zip) sur
https://github.com/xinntao/Real-ESRGAN/releases (v0.2.5.0) et le décompresser ; seul le dossier models/ sert.
Dépendances : python3, numpy, pillow, opencv-python.

Usage :  python3 outils/agrandir_figurines.py <dossier>/models/realesr-animevideov3-x2 assets/figurines/x.png assets/figurines/x.png 2
(modèle sans extension, image source, image de sortie, facteur final)
"""
import numpy as np
import sys, time
from PIL import Image


def lire_modele(param, binf):
    lignes = open(param).read().split("\n")
    data = open(binf, "rb").read()
    pos = 0
    couches = []
    for l in lignes[2:]:
        t = l.split()
        if not t:
            continue
        typ, nom, ni, no = t[0], t[1], int(t[2]), int(t[3])
        ins = t[4:4 + ni]
        outs = t[4 + ni:4 + ni + no]
        p = {}
        for kv in t[4 + ni + no:]:
            k, v = kv.split("=")
            k = int(k)
            if k <= -23300:
                vals = v.split(",")
                p[-k - 23300] = [float(x) for x in vals[1:]]
            else:
                p[k] = float(v) if ("." in v or "e" in v) else int(v)
        c = {"type": typ, "in": ins, "out": outs, "p": p}
        if typ == "Convolution":
            n = p[6]
            tag = int.from_bytes(data[pos:pos + 4], "little")
            pos += 4
            if tag == 0x01306B47:
                w = np.frombuffer(data, np.float16, n, pos).astype(np.float32)
                pos += n * 2
                pos = (pos + 3) // 4 * 4
            elif tag == 0:
                w = np.frombuffer(data, np.float32, n, pos).copy()
                pos += n * 4
            else:
                raise Exception("tag %x" % tag)
            co = p[0]
            k = p.get(1, 1)
            ci = n // (co * k * k)
            c["w"] = w.reshape(co, ci, k, k)
            if p.get(5, 0):
                c["b"] = np.frombuffer(data, np.float32, co, pos).copy()
                pos += co * 4
        elif typ == "PReLU":
            n = p.get(0, 1)
            c["slope"] = np.frombuffer(data, np.float32, n, pos).copy()
            pos += n * 4
        couches.append(c)
    assert pos == len(data), (pos, len(data))
    return couches


def conv(x, w, b, pad):
    # x: C,H,W ; w: O,C,k,k
    C, H, W = x.shape
    O, _, k, _ = w.shape
    if k == 1:
        y = (w.reshape(O, C) @ x.reshape(C, H * W)).reshape(O, H, W)
    else:
        xp = np.pad(x, ((0, 0), (pad, pad), (pad, pad)))
        y = np.zeros((O, H * W), np.float32)
        wk = w.transpose(2, 3, 0, 1)  # k,k,O,C
        for dy in range(k):
            for dx in range(k):
                sl = np.ascontiguousarray(xp[:, dy:dy + H, dx:dx + W]).reshape(C, H * W)
                y += wk[dy, dx] @ sl
        y = y.reshape(O, H, W)
    if b is not None:
        y += b[:, None, None]
    return y


def executer(couches, img):
    blobs = {}
    for c in couches:
        t, p = c["type"], c["p"]
        if t == "Input":
            blobs[c["out"][0]] = img
            continue
        x = [blobs[i] for i in c["in"]]
        if t == "Convolution":
            y = conv(x[0], c["w"], c.get("b"), p.get(4, 0))
            act = p.get(9, 0)
            if act == 1:
                np.maximum(y, 0, out=y)
            elif act == 2:
                s = p[10][0]
                y = np.where(y > 0, y, y * s)
            elif act != 0:
                raise Exception("act %d" % act)
        elif t == "PReLU":
            s = c["slope"]
            s = s[:, None, None] if s.size > 1 else s[0]
            y = np.where(x[0] > 0, x[0], x[0] * s)
        elif t == "Split":
            for o in c["out"]:
                blobs[o] = x[0]
            continue
        elif t == "Concat":
            y = np.concatenate(x, axis=0)
        elif t == "Eltwise":
            coef = p.get(1, None)
            if coef:
                y = sum(ci * xi for ci, xi in zip(coef, x))
            else:
                y = x[0] + x[1]
        elif t == "BinaryOp":
            op = p.get(0, 0)
            if p.get(1, 0):
                b = p.get(2, 0.0)
                y = {0: x[0] + b, 1: x[0] - b, 2: x[0] * b}[op]
            else:
                y = {0: x[0] + x[1], 1: x[0] - x[1], 2: x[0] * x[1]}[op]
        elif t == "Interp":
            sh, sw = p.get(1, 1.0), p.get(2, 1.0)
            if p.get(0, 1) == 1 and sh == int(sh) and sh >= 1:
                y = x[0].repeat(int(sh), axis=1).repeat(int(sw), axis=2)
            else:
                import cv2
                C, H, W = x[0].shape
                hwc = np.ascontiguousarray(x[0].transpose(1, 2, 0))
                y = cv2.resize(hwc, (int(W * sw), int(H * sh)),
                               interpolation=cv2.INTER_CUBIC if p.get(0, 1) == 3 else cv2.INTER_LINEAR)
                y = y.reshape(int(H * sh), int(W * sw), C).transpose(2, 0, 1)
        elif t == "PixelShuffle":
            r = p[0]
            C, H, W = x[0].shape
            y = x[0].reshape(C // (r * r), r, r, H, W).transpose(0, 3, 1, 4, 2).reshape(C // (r * r), H * r, W * r)
        else:
            raise Exception(t)
        blobs[c["out"][0]] = y.astype(np.float32, copy=False)
        # libère les blobs qui ne servent plus
    return blobs["output"] if "output" in blobs else y


def agrandir(couches, rgb, tuile=96, marge=10):
    """rgb: H,W,3 float 0..1 -> image agrandie (par tuiles pour limiter la mémoire)."""
    H, W, _ = rgb.shape
    x = rgb.transpose(2, 0, 1).astype(np.float32)
    out = None
    for y0 in range(0, H, tuile):
        for x0 in range(0, W, tuile):
            ya, yb = max(0, y0 - marge), min(H, y0 + tuile + marge)
            xa, xb = max(0, x0 - marge), min(W, x0 + tuile + marge)
            r = executer(couches, x[:, ya:yb, xa:xb])
            s = r.shape[1] // (yb - ya)
            if out is None:
                out = np.zeros((3, H * s, W * s), np.float32)
            ty, tx = (y0 - ya) * s, (x0 - xa) * s
            hh, ww = min(tuile, H - y0) * s, min(tuile, W - x0) * s
            out[:, y0 * s:y0 * s + hh, x0 * s:x0 * s + ww] = r[:, ty:ty + hh, tx:tx + ww]
    return np.clip(out.transpose(1, 2, 0), 0, 1)


if __name__ == "__main__":
    modele, src, dst, facteur = sys.argv[1], sys.argv[2], sys.argv[3], float(sys.argv[4])
    couches = lire_modele(modele + ".param", modele + ".bin")
    im = Image.open(src).convert("RGBA")
    a = np.asarray(im).astype(np.float32) / 255.0
    rgb, al = a[..., :3], a[..., 3]
    # Couleur des pixels transparents : on étale les couleurs du bord pour éviter les liserés sombres
    t = time.time()
    up = agrandir(couches, rgb)
    print("modele %.1fs" % (time.time() - t))
    W2, H2 = int(round(im.width * facteur)), int(round(im.height * facteur))
    rgb2 = Image.fromarray((up * 255 + 0.5).astype(np.uint8)).resize((W2, H2), Image.LANCZOS)
    a2 = Image.fromarray((al * 255 + 0.5).astype(np.uint8)).resize((W2, H2), Image.LANCZOS)
    rgb2.putalpha(a2)
    rgb2.save(dst)
