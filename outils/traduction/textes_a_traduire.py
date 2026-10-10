"""Liste les textes français du jeu qui n'ont pas encore de traduction dans langues/en.po.

Usage (depuis la racine du projet) :  python3 outils/traduction/textes_a_traduire.py
Les fichiers de données (unités, histoire, dialogues…) sont ignorés pour l'instant (étape 2).
"""
import glob, re

DATA = {'unites_data', 'evolutions_data', 'dialogues_data', 'actes_data', 'familiers_data', 'rencontres', 'histoire_data', 'version'}
lit = re.compile(r'"((?:[^"\\]|\\.)*)"')

connus = set()
for m in re.finditer(r'^msgid "((?:[^"\\]|\\.)*)"', open('langues/en.po', encoding='utf-8').read(), re.M):
    connus.add(m.group(1).replace('\\"', '"'))

manquants = {}
for f in sorted(glob.glob('scripts/*.gd')):
    nom = f.split('/')[-1][:-3]
    if nom in DATA:
        continue
    for n, ln in enumerate(open(f, encoding='utf-8'), 1):
        if ln.strip().startswith('#'):
            continue
        for m in lit.finditer(ln):
            v = m.group(1)
            if not re.search(r'[A-Za-zÀ-ÿ]{2}', v) or re.fullmatch(r'[a-z0-9_./:\-#%]+', v):
                continue
            if v.startswith(('res://', 'user://', 'http', '/rest')) or v in connus:
                continue
            manquants.setdefault(v, '%s:%d' % (f, n))
for v, ou in manquants.items():
    print('%s\t%s' % (ou, v))
print('\n%d texte(s) sans traduction' % len(manquants))
