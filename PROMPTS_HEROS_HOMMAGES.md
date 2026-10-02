# Prompts ChatGPT : les 8 héros « hommages » (v0.33.0)

Huit héros invocables, chacun inspiré d'un personnage de jeu vidéo **sans le copier** : nom, apparence et
sorts sont originaux, la référence passe par l'esprit du personnage (son rôle, son style de combat, un clin d'œil
dans un nom de sort).

| Fichier | Héros | Rareté | Élément · rôle | Clin d'œil |
|---|---|---|---|---|
| `axolotl_sources` | Axolotl des Sources | SSR | Eau · soutien | création originale (pour ta fille) : un guérisseur qui repousse comme un vrai axolotl |
| `errant_silencieux` | L'Errant Silencieux | SSR | Ténèbres · guerrier | le petit chevalier muet d'un royaume insecte enseveli |
| `chasseresse_soie` | La Chasseresse de Soie | UR | Ténèbres · assassin | la chasseresse à l'aiguille et au fil (« Chant de Soie ») |
| `princesse_sceaux` | La Princesse des Sceaux | SSR | Sacré · soutien | la princesse de la sagesse qui scelle le mal |
| `elu_lame` | L'Élu de la Lame | SSR | Sacré · tank | le jeune héros au bouclier, coup tournoyant et parade parfaite |
| `mercenaire_sans_nom` | Le Mercenaire Sans Nom | UR | Sacré · guerrier | l'ancien soldat d'élite à l'épée démesurée (« Au-delà des Limites ») |
| `combattante_ardente` | La Combattante Ardente | UR | Feu · guerrier | la combattante aux poings, enchaînements et contres |
| `fleuriste_ruines` | La Fleuriste des Ruines | UR | Nature · soutien | la fleuriste qui prie la Terre pour ranimer ses amis |

**Important pour le style** : les couleurs viennent du personnage (tenue, peau, cheveux), **pas de son élément**.
L'élément n'est qu'un rappel discret (une petite lueur). Dans le jeu, c'est le liseré du portrait et le socle de la
figurine qui montrent l'élément.

Ordre des cases : rangée du haut de gauche à droite (1, 2, 3, 4), puis rangée du bas (5, 6, 7, 8).

---

## Planche 39 : les portraits → `planche_39.png`

Joins une planche de portraits déjà réussie (par exemple `planche_07.png`) pour garder le style du jeu.

```
Crée une planche de portraits de personnages pour les cartes d'un jeu mobile dark fantasy, dans le même style que l'image jointe.

FORMAT, À RESPECTER STRICTEMENT :
- image paysage 1536x1024 ;
- grille parfaitement régulière de 4 colonnes et 2 rangées : 8 cases identiques, séparées par un fin trait noir droit ;
- dans chaque case : un seul personnage, cadré à mi-corps, tête dans le tiers haut de la case, bien centré, qui ne dépasse JAMAIS de sa case ;
- fond de chaque case : dégradé sombre neutre (gris-brun), avec seulement une très légère lueur derrière le personnage ;
- les couleurs viennent du personnage lui-même (tenue, peau, cheveux) : pas de flammes, d'eau, de feuillages ou d'effets magiques partout autour de lui ;
- aucun texte, aucun chiffre, aucun nom, aucun logo, aucun cadre de carte ;
- respecte l'ordre : case 1 en haut à gauche, lecture de gauche à droite, rangée par rangée.

STYLE : peinture numérique dark fantasy très détaillée, éclairage dramatique venant du haut à gauche, même style pour les 8 personnages, visages et silhouettes lisibles même en petit. Personnages tous originaux.

Contenu des 8 cases, dans l'ordre :
1. un axolotl humanoïde mignon et courageux, de la taille d'un enfant, peau rose pâle nacrée, branchies plumeuses roses autour de la tête comme une couronne, grands yeux noirs brillants, doux sourire, petite cape de voyage en lin crème, sacoche de guérisseur, petit bâton en bois flotté coiffé d'un coquillage
2. un petit chevalier-insecte silencieux, à peine plus grand qu'un enfant, carapace gris anthracite comme un scarabée, heaume de fer arrondi percé d'une seule fente étroite d'où filtre une faible lueur pâle, cape courte grise usée et déchirée, fine lame en forme d'aiguillon en métal clair
3. une chasseresse-insecte élancée et agile, armure de chitine violet sombre et argent, longue cape à capuche gris ardoise, visage voilé d'un demi-masque lisse en chitine sombre, fine aiguille-lance d'argent reliée à son poignet par un fil de soie brillant qui s'enroule autour d'elle
4. une jeune princesse-mage sage et sereine, longs cheveux auburn tressés, diadème d'argent orné d'une pierre bleu pâle, robe blanche et argent brodée d'un croissant de lune et de trois étoiles, mains jointes autour d'un orbe de cristal qui luit doucement
5. un jeune héros humain au regard déterminé, cheveux châtains attachés en arrière, tenue de voyageur en cuir brun et tissu bleu ardoise, grand bouclier rond en bois cerclé de fer orné d'un soleil levant, épée courte à la lame sombre qui luit faiblement
6. un mercenaire humain balafré au regard las, cheveux courts gris acier, long manteau sombre de soldat usé, épée à deux mains démesurée et ébréchée, plus grande que lui, lame large gravée de runes, posée sur l'épaule
7. une jeune combattante humaine athlétique au sourire confiant, cheveux roux foncé noués en queue courte, tenue d'arts martiaux en cuir et toile sombre, bandages aux avant-bras, gantelets de métal aux jointures rougeoyantes comme des braises, posture de garde
8. une jeune guérisseuse humaine douce et lumineuse, cheveux blond miel ondulés couronnés de petites fleurs blanches, robe longue crème et brun doré, panier de fleurs au bras, bâton de bois clair dont le sommet est un bouton de fleur en cristal
```

Commande (je m'en occupe) :
`python3 outils/decouper_planche.py planche_39.png axolotl_sources errant_silencieux chasseresse_soie princesse_sceaux elu_lame mercenaire_sans_nom combattante_ardente fleuriste_ruines`

---

## Planche 40 : les figurines de combat (pions) → `planche_40.png`

Les figurines remplacent les portraits ronds pendant les combats : elles respirent doucement, s'élancent pour
frapper et basculent quand elles sont K.O. **Joins deux images** : la figurine du grand frère (`pion_aine.png`) pour le
rendu, et la `planche_39` réussie pour que chaque figurine ressemble à son portrait.

Le fond VERT sert à détourer : je le rends transparent automatiquement. Tous les personnages regardent vers la
**droite** (le jeu retourne les ennemis tout seul).

```
Crée une planche de 8 figurines de jeu de plateau pour un jeu mobile dark fantasy, EXACTEMENT dans le même style que la figurine jointe (même rendu peint, même éclairage dramatique venant du haut à gauche, même petit socle rond en pierre sombre sous les pieds). Les 8 personnages sont ceux de la planche de portraits jointe, dans le même ordre, vus en pied.

FORMAT, À RESPECTER STRICTEMENT :
- image paysage 1536x1024 ;
- grille parfaitement régulière de 4 colonnes et 2 rangées : 8 cases identiques, séparées par un fin trait NOIR droit ;
- le fond de CHAQUE case est un VERT UNI très vif (#00FF00), sans dégradé, sans ombre portée, sans décor ;
- dans chaque case : un seul personnage en pied, de trois quarts, tourné vers la DROITE de l'image, debout sur son petit socle rond en pierre sombre, entier de la tête au socle, centré, qui ne touche pas les bords ;
- proportions légèrement stylisées (tête un peu plus grande), silhouette très lisible même en tout petit ;
- aucun vert dans les personnages eux-mêmes ;
- les couleurs viennent du personnage (tenue, peau, cheveux), pas d'effets magiques autour de lui ;
- aucun texte, aucun chiffre, aucun cadre ;
- ordre : case 1 en haut à gauche, lecture de gauche à droite, rangée par rangée.

Contenu des 8 cases, dans l'ordre :
1. l'axolotl guérisseur à la peau rose nacrée, bâton de bois flotté au coquillage
2. le petit chevalier-insecte gris anthracite au heaume à fente, cape grise, lame-aiguillon
3. la chasseresse-insecte en chitine violet sombre, cape grise, aiguille-lance reliée à un fil de soie
4. la princesse-mage aux cheveux auburn tressés, robe blanche et argent, orbe de cristal
5. le jeune héros au grand bouclier rond orné d'un soleil levant, épée courte à la lame sombre
6. le mercenaire balafré au long manteau sombre, épée démesurée posée sur l'épaule
7. la combattante aux cheveux roux foncé, gantelets rougeoyants, en garde
8. la guérisseuse aux cheveux blond miel couronnés de fleurs blanches, robe crème et brun doré, bâton à bouton de cristal
```

Commande (je m'en occupe) :
`python3 outils/decouper_miniatures.py planche_40.png --figurines axolotl_sources errant_silencieux chasseresse_soie princesse_sceaux elu_lame mercenaire_sans_nom combattante_ardente fleuriste_ruines`

Si ChatGPT rate la grille, demande les figurines **une par une sur fond transparent** et nomme-les avec l'identifiant
(`axolotl_sources.png`…) : je les range dans `assets/figurines/`.

> Plus tard, n'importe quelle unité (héros ou ennemi) pourra avoir sa figurine : il suffit d'ajouter
> `assets/figurines/<identifiant>.png`, le combat l'utilise automatiquement.

---

## Planche 41 (facultative) : les évolutions → `planche_41.png`

Tant qu'elle n'existe pas, une évolution reprend le portrait et la figurine de son héros de base. Même BLOC que la
planche 39 (joins la planche 39 réussie), avec cette liste :

```
Contenu des 8 cases, dans l'ordre (versions plus puissantes et plus majestueuses des 8 personnages de la planche jointe, même visage, même silhouette) :
1. l'axolotl devenu ancien et majestueux, branchies plus longues et lumineuses, petite couronne de corail blanc, bâton de bois flotté orné de perles
2. le petit chevalier-insecte en carapace noire polie aux reflets argentés, cape plus longue, lame-aiguillon plus fine et brillante
3. la chasseresse-insecte souveraine, armure de chitine ornée d'argent, cape royale ardoise, plusieurs fils de soie tendus autour d'elle
4. la princesse devenue reine, diadème plus haut, robe d'apparat blanche et argent, orbe de cristal plus grand
5. le héros en armure légère de chevalier par-dessus sa tenue de voyageur, bouclier au soleil levant doré, lame plus longue et lumineuse
6. le mercenaire en manteau renforcé de plaques, épée démesurée réparée et gravée de runes qui brillent faiblement
7. la combattante en tenue de maîtresse d'arts martiaux, ceinture noire brodée d'or, gantelets incandescents
8. la guérisseuse en robe de prêtresse crème et or, couronne de fleurs plus abondante, bâton fleuri en pleine floraison
```

Commande (je m'en occupe) :
`python3 outils/decouper_planche.py planche_41.png axolotl_sources_evo errant_silencieux_evo chasseresse_soie_evo princesse_sceaux_evo elu_lame_evo mercenaire_sans_nom_evo combattante_ardente_evo fleuriste_ruines_evo`
