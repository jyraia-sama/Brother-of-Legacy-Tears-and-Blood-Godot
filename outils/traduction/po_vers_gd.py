"""Recopie langues/en.po dans scripts/traduction_en.gd (dictionnaire lu par le jeu).

À relancer après chaque modification de langues/en.po :
    python3 outils/traduction/po_vers_gd.py
(Le jeu ne lit pas le .po directement : un script est toujours exporté avec la mise à jour.)
"""
import re

po = open('langues/en.po', encoding='utf-8').read()
paires = re.findall(r'^msgid "((?:[^"\\]|\\.)*)"\nmsgstr "((?:[^"\\]|\\.)*)"', po, re.M)
lignes = ['class_name TraductionEn', 'extends RefCounted',
          '## TEXTES ANGLAIS (français -> anglais). FICHIER GÉNÉRÉ : ne pas modifier à la main.',
          '## Modifie langues/en.po puis lance : python3 outils/traduction/po_vers_gd.py', '',
          'const TEXTES := {']
n = 0
for fr, en in paires:
    if fr == '' or en == '':
        continue
    lignes.append('\t"%s": "%s",' % (fr, en))
    n += 1
lignes.append('}')
open('scripts/traduction_en.gd', 'w', encoding='utf-8').write('\n'.join(lignes) + '\n')
print(n, 'textes recopiés dans scripts/traduction_en.gd')
