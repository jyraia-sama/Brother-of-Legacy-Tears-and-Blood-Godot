#!/usr/bin/env python3
"""SIGNE UNE APPLICATION ANDROID (.apk) avec le schéma de signature APK v2 (Android 7 et plus).

Remplace « apksigner » du kit Android quand celui-ci n'est pas disponible :
  1. exporter l'APK NON SIGNÉ depuis Godot (préréglage Android, package/signed = false) ;
  2. python3 outils/signer_apk.py entree.apk sortie.apk brothersoflegacy.keystore MOT_DE_PASSE

La clé (brothersoflegacy.keystore, format PKCS12) et son mot de passe sont dans les documents
du Projet Claude (CLE_ANDROID.md). Ne jamais les mettre dans le dépôt.
Il faut le module Python « cryptography ».
"""
import hashlib
import struct
import sys

from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives.serialization import pkcs12

ID_BLOC_V2 = 0x7109871A
ALGO_RSA_SHA256 = 0x0103          # RSASSA-PKCS1-v1_5 avec SHA2-256
MAGIE = b"APK Sig Block 42"
MORCEAU = 1024 * 1024


def lp(donnees: bytes) -> bytes:
    """Préfixe de longueur (uint32, petit-boutiste)."""
    return struct.pack("<I", len(donnees)) + donnees


def trouver_eocd(apk: bytes) -> int:
    for i in range(len(apk) - 22, max(-1, len(apk) - 22 - 65536), -1):
        if apk[i:i + 4] == b"PK\x05\x06":
            return i
    raise SystemExit("Fin de répertoire ZIP introuvable : ce n'est pas un APK valide.")


def empreinte_sections(sections) -> bytes:
    morceaux = []
    for s in sections:
        for i in range(0, len(s), MORCEAU):
            m = s[i:i + MORCEAU]
            morceaux.append(hashlib.sha256(b"\xa5" + struct.pack("<I", len(m)) + m).digest())
    return hashlib.sha256(b"\x5a" + struct.pack("<I", len(morceaux)) + b"".join(morceaux)).digest()


def signer(entree: str, sortie: str, magasin: str, mot_de_passe: str) -> None:
    apk = open(entree, "rb").read()
    eocd = trouver_eocd(apk)
    taille_cd, debut_cd = struct.unpack("<II", apk[eocd + 12:eocd + 20])
    if apk[debut_cd - 16:debut_cd] == MAGIE:
        raise SystemExit("Cet APK est déjà signé (v2) : exporte-le non signé.")
    contenu, cd, fin = apk[:debut_cd], apk[debut_cd:debut_cd + taille_cd], apk[eocd:]

    cle, cert, _ = pkcs12.load_key_and_certificates(open(magasin, "rb").read(), mot_de_passe.encode())
    cert_der = cert.public_bytes(serialization.Encoding.DER)
    cle_pub = cle.public_key().public_bytes(serialization.Encoding.DER,
                                            serialization.PublicFormat.SubjectPublicKeyInfo)

    # Empreinte du contenu, du répertoire central et de la fin de répertoire (non modifiée :
    # son décalage pointe déjà vers l'endroit où sera inséré le bloc de signature).
    emp = empreinte_sections([contenu, cd, fin])
    donnees_signees = (lp(lp(struct.pack("<I", ALGO_RSA_SHA256) + lp(emp)))
                       + lp(lp(cert_der))
                       + lp(b""))
    signature = cle.sign(donnees_signees, padding.PKCS1v15(), hashes.SHA256())
    signataire = (lp(donnees_signees)
                  + lp(lp(struct.pack("<I", ALGO_RSA_SHA256) + lp(signature)))
                  + lp(cle_pub))
    valeur = lp(lp(signataire))

    paire = struct.pack("<QI", 4 + len(valeur), ID_BLOC_V2) + valeur
    taille_bloc = len(paire) + 8 + 16
    bloc = struct.pack("<Q", taille_bloc) + paire + struct.pack("<Q", taille_bloc) + MAGIE

    nouvelle_fin = fin[:16] + struct.pack("<I", debut_cd + len(bloc)) + fin[20:]
    with open(sortie, "wb") as f:
        f.write(contenu + bloc + cd + nouvelle_fin)
    print("APK signé : %s (%d octets)" % (sortie, len(contenu) + len(bloc) + len(cd) + len(nouvelle_fin)))


if __name__ == "__main__":
    if len(sys.argv) != 5:
        raise SystemExit(__doc__)
    signer(*sys.argv[1:])
