# Équilibrage de l'Aventure (v0.32.0)

## Ce qui a été mesuré

Des joueurs virtuels jouent toute l'histoire, de l'Acte I chapitre 1 à la fin de l'Acte XIII, avec les vraies règles :
plateaux, moteur de combat, PV conservés d'une case à l'autre, Mimics, Kaël invité, XP, or, Échos qui tombent,
Éclats des boss, invocations, Absorption, Fusion. Trois profils :

| Profil | Ce qu'il fait |
|---|---|
| **Régulier** | équipe ses Échos et les améliore, Pacte Doré avec l'or en trop, Fusion, Absorption |
| **Occasionnel** | pose les Échos qu'il gagne sans les améliorer, Absorption ; ni Pacte Doré ni Fusion |
| **Sans Échos** | n'équipe aucun Écho, Absorption seulement |

## Ce qu'on a trouvé (avant la v0.32.0)

1. **L'Aventure était beaucoup trop facile.** Le joueur régulier gagnait ~100 % de ses combats, du premier au dernier
   chapitre (0 défaite sur toute l'histoire). Même sans Échos, presque aucune défaite avant l'Acte VII.
2. **La cause : les Éclats arrivent tôt.** Boss de chapitre (1), boss d'Acte (3) et Premiers pas (3) donnent ~11 Éclats
   dès la fin de l'Acte I : un joueur a en moyenne **3 SSR dès l'Acte II**. La difficulté était réglée sur une équipe
   « de référence » qui n'avait son premier SSR qu'à l'Acte VI : les vrais joueurs étaient 1,4 à 2 fois plus forts.
3. **Kaël invité rendait ses chapitres triviaux** : boss final de l'Acte XII 35 % → 78 % de victoires, Acte X ch. 6
   39 % → 83 %, Acte XIII ch. 6 44 % → 83 %.
4. **Les Échos comptent énormément** : mêmes équipes, avec / sans leurs Échos = +15 à +30 points de victoire.
5. **Pics en début d'Acte** : l'équipe de référence changeait d'un coup au chapitre 1 de chaque Acte.
6. Chaque chef de chapitre a ses propres sorts : certains étaient nettement plus coriaces que les autres.

## Ce qui a changé

- Difficulté de chaque Acte et type de case réglée **sur les équipes des joueurs virtuels** (profil occasionnel),
  et plus sur l'équipe de référence théorique (`CALIBRAGE` dans `scripts/rencontres.gd`).
- Taux visés, PV pleins, joueur occasionnel : combat 97 % · élite 88 % · gardien 82 % · chef 72 % · boss d'Acte 60 % ·
  Mimic 78 %. Actes I et II plus doux, Acte XIII plus exigeant. Puis **difficulté globale 0,94** car les PV conservés
  sur le plateau rendent chaque chapitre plus dur que ses combats pris un par un.
- Correction **chef par chef** (`CALIBRAGE_CHEFS`).
- **Kaël** : les ennemis sont renforcés dans ses chapitres (`RENFORT_INVITE`) ; il aide (~+8 points) sans tout écraser.
- **Premiers chapitres** encore plus doux (x0,80 au tout premier, l'équipe n'a que 4 héros).
- La force de référence **glisse** d'un Acte à l'autre au fil des chapitres (plus de pic au chapitre 1).
- **Conseil après défaites** sur le plateau : si l'équipe porte peu d'Échos, le jeu le dit ; sinon il propose
  d'améliorer les Échos ou d'utiliser l'Absorption.

## Résultat (défaites moyennes par chapitre, 16 joueurs par profil)

| Acte | I | II | III | IV | V | VI | VII | VIII | IX | X | XI | XII | XIII |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Régulier | 0,2 | 1,3 | 1,8 | 2,9 | 1,7 | 1,1 | 0,8 | 0,9 | 0,6 | 1,1 | 1,0 | 0,8 | 1,2 |
| Occasionnel | 0,3 | 1,4 | 1,8 | 1,8 | 1,6 | 1,7 | 1,6 | 2,1 | 2,1 | 3,0 | 2,3 | 1,7 | 3,2 |
| Sans Échos | 0,2 | 5,6 | 4,1 | 4,5 | 4,4 | 5,6 | 4,4 | 5,4 | 8,0 | 11,2 | 9,0 | 4,8 | 18,6 |

Une défaite coûte peu (on recule d'une case, PV rendus, on retente). Les combats perdus sont surtout les boss.

## Économie (observations, rien n'a été changé)

- **Or : abondant.** Un joueur qui ne dépense pas finit l'histoire avec ~290 000 or. Les Plaines Cendrées de la Ménagerie
  donnent jusqu'à ~13 000 or par équipe et par 12 h au niveau de compte 30 (bonus +5 % par niveau). L'or manque surtout
  de débouchés intéressants (le Pacte Doré ne donne que du N/R/SR).
- **Stamina : jamais bloquante dans l'histoire.** Chaque niveau de compte recharge la stamina ; toute l'histoire tient
  en 1 à 3 « journées » de stamina. Ce qui limite, c'est le temps de jeu.
- **Éclats : généreux tôt** (voir plus haut). C'est voulu côté plaisir ; la difficulté en tient compte maintenant.
- **Nids Sauvages** (niveau 20) : ~0,5 Éclat par jour et par équipe ; avec 5 équipes, à peu près autant que les quêtes.

## Refaire le réglage (après avoir ajouté des unités, changé des sorts…)

```
godot --headless --path . --script res://outils/simuler_progression.gd -- --joueurs=24 --profil=occasionnel --sortie=occ.json
godot --headless --path . --script res://outils/calibrer_aventure.gd -- --equipes=occ.json            (--actes=1-7 / 8-13 pour 2 moitiés)
```
Recopier `CALIBRAGE`, `CALIBRAGE_CHEFS`, `CALIBRAGE_MIMIC` et `RENFORT_INVITE` dans `scripts/rencontres.gd`, puis vérifier :
`simuler_progression.gd -- --profil=regulier` (et `occasionnel`, `sans_echos`). `outils/effet_echos.gd` mesure l'apport des Échos.
