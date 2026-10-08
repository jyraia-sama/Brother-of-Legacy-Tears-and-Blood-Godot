# Prompts ChatGPT : les cadres de cartes par rareté (v0.50.0)

Six cadres ornés, un par rareté, posés **par-dessus** les cartes des héros, des monstres et des familiers.

| Case | Fichier | Rareté | Matière | Couleur dans le jeu |
|---|---|---|---|---|
| 1 | `n.png` | N | fer brut martelé | gris |
| 2 | `r.png` | R | bronze patiné bleu-sarcelle | sarcelle |
| 3 | `sr.png` | SR | argent ciselé et améthystes | violet |
| 4 | `ssr.png` | SSR | or ouvragé et ambre | or |
| 5 | `ur.png` | UR | fer noir et or rouge, rubis | rouge sang |
| 6 | `leg.png` | Légende | or blanc lumineux, pierres de lune | or pâle |

**Où ils apparaissent** (automatiquement, dès que les images sont là) :
- Deck (collection, équipe, grande fiche) ;
- Fusion et Évolution ;
- révélation des Invocations ;
- Bestiaire (cartes et fiche) et Galerie d'Art ;
- Arène, Armée du Boss de Monde, Compagnie, Marche Maudite, Reliquaire et Ménagerie (familiers) ;
- fiche d'un héros et Sanctuaire.

Tant qu'une image manque, la carte garde son simple contour coloré.

**Important pour que ça marche** : les cartes n'ont pas toutes la même taille. Le jeu garde les **coins** tels quels
et **étire les côtés**. Il faut donc que tous les ornements soient dans les quatre coins, et que les côtés entre
les coins soient une simple bordure régulière, sans motif au milieu.

---

## La planche des 6 cadres → `planche_cadres.png`

Joins la planche de référence de la D.A. (`planche_39.png`) pour le rendu des matières.

```
Crée une planche de 6 CADRES DE CARTES À JOUER vides pour un jeu mobile dark fantasy, dans le même rendu peint que l'image jointe : métal et pierres précieuses peints de façon réaliste et très détaillée, éclairage chaud et dramatique venant du haut à gauche.

FORMAT, À RESPECTER STRICTEMENT :
- image paysage 1536x1024 ;
- grille parfaitement régulière de 3 colonnes et 2 rangées : 6 cases identiques, séparées par un fin trait NOIR droit ;
- dans chaque case : UN SEUL cadre de carte VERTICAL (proportions 3 de large pour 4 de haut), vu parfaitement de face, centré, parfaitement symétrique gauche-droite et haut-bas, qui ne touche pas les bords de la case ;
- le fond de chaque case ET l'intérieur de chaque cadre sont en VERT UNI très vif (#00FF00), sans dégradé, sans ombre, sans décor : l'intérieur est vide, c'est là que viendra l'illustration ;
- aucun vert dans les cadres eux-mêmes ;
- aucun texte, aucun chiffre, aucune plaque de nom, aucun symbole d'élément.

FORME DES CADRES (très important) :
- la bordure est FINE et RÉGULIÈRE : environ 6 % de la largeur du cadre ;
- tous les ornements sont regroupés dans les QUATRE COINS (chaque coin orné occupe au plus un quart de la largeur du cadre) ;
- entre les coins, les quatre côtés sont une simple moulure droite et régulière, SANS motif, SANS joyau, SANS ornement au milieu ;
- rien ne déborde vers l'intérieur au-delà des coins ;
- plus la rareté est haute, plus les coins sont riches et précieux, mais la bordure garde la même finesse.

Les 6 cadres, dans l'ordre (case 1 en haut à gauche, lecture de gauche à droite, rangée par rangée) :
1. Rareté commune : fer brut martelé gris sombre, coins renforcés par de simples équerres rivetées, quelques éraflures et traces de rouille.
2. Rareté rare : bronze patiné aux reflets bleu-sarcelle, coins en volutes simples avec un petit clou de bronze rond.
3. Rareté super rare : argent ciselé, coins en arabesques fines sertis chacun d'une petite améthyste violette taillée.
4. Rareté épique : or ouvragé en filigrane, coins en feuilles d'acanthe dorées sertis chacun d'une pierre d'ambre, léger éclat doré.
5. Rareté ultime : fer noir bordé d'or rouge, coins en griffes et cornes recourbées sertis chacun d'un gros rubis rouge sang qui luit faiblement, petites gouttes de sang stylisées en métal.
6. Rareté légendaire : or blanc lumineux, coins en ailes déployées finement gravées sertis chacun d'une pierre de lune nacrée, très léger halo doré pâle autour des coins.
```

---

## Ce que je fais quand tu m'envoies la planche

```
python3 outils/decouper_miniatures.py planche_cadres.png --dossier=assets/cadres --hauteur=400 n r sr ssr ur leg
```

Le vert (fond et centre) devient transparent, chaque cadre est rangé dans `assets/cadres/`, et toutes les cartes du
jeu les prennent aussitôt.

Si ChatGPT rate la grille, demande les cadres **un par un** (image carrée 1024x1024, même texte, un seul cadre) et
nomme-les `n.png`, `r.png`, `sr.png`, `ssr.png`, `ur.png`, `leg.png`.
