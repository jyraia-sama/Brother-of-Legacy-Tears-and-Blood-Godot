# Prompt ChatGPT — fond du menu principal : « La Crypte des Valcendre » (v0.38.0)

Direction artistique : la nuit de l'Acte I, dans la crypte des ancêtres, au moment où le Sceau des Frères se brise.
Tout le titre du jeu est dans l'image : la **Larme** (bleu, le grand frère) à gauche, le **Sang** (rouge, Kaël) à droite,
le médaillon brisé entre les deux, la tombe du père à leurs pieds, la lune rouge au-dessus.

## Comment l'utiliser

1. Colle le prompt ci-dessous dans ChatGPT. Il rend des images **3:2 (1536 x 1024)** : c'est prévu, le jeu rogne un peu le haut et le bas.
2. Enregistre l'image en **`assets/ui/menu_freres.png`** : le menu l'utilise tout seul (le fond dessiné, le grand frère, Kaël, la lune et l'emblème dessinés disparaissent).
3. Le jeu assombrit tout seul les côtés gauche et droit derrière les boutons : pas besoin que l'image soit parfaite à cet endroit.
4. Appuie sur **F1** dans le menu : deux cadres dorés montrent les zones secrètes (lune et médaillon). ChatGPT ne place jamais les choses au pixel près : envoie-moi une capture et je recale `RECT_LUNE` / `RECT_EMBLEME` dans `scripts/main_menu.gd`.

## Ce qui compte dans l'image (le reste est libre)

| Élément | Où (dans l'image 3:2) | Pourquoi |
|---|---|---|
| Médaillon brisé | au centre exact | secret du Bélier (3 touches) |
| Lune rouge | tiers haut, un peu à gauche du centre | secret d'Arnaud (5 touches) |
| Grand frère / Kaël | vers 1/3 et 2/3 de la largeur | visibles entre les deux colonnes de boutons |
| Bords gauche et droit (1/5 chacun) | sombres, sans détail | colonnes de la Larme et du Sang |
| Haut et bas (15 % chacun) | sombres, calmes | barre du compte, barre du Royaume (et rognage) |
| Sous le médaillon | calme | le guide Premiers pas s'y affiche |

## Prompt (à coller dans ChatGPT)

```
Illustration de fond pour le menu principal d'un jeu vidéo dark fantasy, image paysage au format 3:2. Peinture numérique très détaillée, style art de jeu de cartes gacha dark fantasy, éclairage dramatique en clair-obscur, palette très sombre. Aucun texte, aucun titre, aucun logo, aucun cadre, aucune interface.

Scène : la crypte ancestrale d'une lignée de seigneurs, une grande salle gothique en ruine, la nuit où leur domaine a brûlé. Voûtes effondrées, colonnes brisées, tombeaux des ancêtres alignés dans l'ombre, poussière et cendres en suspension.

Au centre exact de l'image, au-dessus d'un autel de pierre, flotte un médaillon rond entouré de deux ailes de phénix dorées. Il est brisé en deux par une fissure verticale : la moitié gauche est une gemme bleue lumineuse, la moitié droite une gemme rouge sang lumineuse. Le médaillon est de taille moyenne (environ un cinquième de la hauteur de l'image) et éclaire la salle en bleu d'un côté et en rouge de l'autre. Au pied de l'autel, une stèle avec une épée plantée devant : la tombe du père.

Moitié gauche, la Larme : lumière froide bleu nuit et argent, un rayon de lune tombe d'un vitrail brisé, de fines gouttes de lumière bleue tombent comme des larmes. Vers le tiers gauche de l'image, le frère aîné, debout, de trois quarts, tourné vers le médaillon : jeune homme aux cheveux sombres, armure noire ciselée, long manteau bleu nuit brodé d'un phénix argenté, une pierre bleue au cou, épée longue pointée vers le sol.

Moitié droite, le Sang : lueur rouge de l'incendie qui passe par une porte éventrée, braises et cendres qui montent. Vers le tiers droit de l'image, son petit frère, debout, tourné vers le médaillon : jeune homme aux cheveux noirs en bataille, armure sombre aux reflets rouges, une pierre rouge au cou, une flamme noire qui s'enroule autour de sa main.

En haut, par une haute fenêtre en ogive située un peu à gauche du centre, on voit une petite lune rouge sang, bien visible.

Composition : les bandes de gauche et de droite (le premier et le dernier cinquième de la largeur) restent sombres, sans personnage ni détail important, seulement des colonnes dans l'ombre. Le haut et le bas de l'image restent sombres et calmes. La zone juste sous le médaillon reste calme.
```

---

# Prompt ChatGPT — carte du monde « Les Terres des Valcendre » (v0.38.0)

**En service depuis la v0.39.0** : l'image est dans `assets/ui/carte_monde.png` (3:2, 1536 x 1024). Les lieux sont calés à la main dans `POS_IMAGE` (`scripts/ecran_carte.gd`) : si tu changes l'image, envoie-la-moi pour que je recale les 13 positions.

## Emplacements des lieux (en % de l'image)

| Acte | Lieu | Gauche → droite | Haut → bas |
|---|---|---|---|
| I | Domaine Valcendre | 9 % | 89 % |
| II | La Cité en Deuil | 19 % | 81 % |
| III | Camps du Drapeau Noir | 30 % | 88 % |
| IV | Sépulcre des Rois | 39 % | 76 % |
| V | Terres Brûlées | 27 % | 65 % |
| VI | Forêt Pétrifiée | 14 % | 55 % |
| VII | Marais aux Murmures | 23 % | 42 % |
| VIII | Bastion de l'Éclipse | 36 % | 50 % |
| IX | Val des Héros Déchus | 45 % | 37 % |
| X | Citadelle des Supplices | 55 % | 46 % |
| XI | Champs du Jugement | 62 % | 32 % |
| XII | Trône de Cendres | 63 % | 18 % |
| XIII | Le Sceau des Frères (caché) | 50 % | 16 % |

La colonne de droite (de 70 % à 100 % de la largeur) et la bande du haut (0 à 9 %) sont recouvertes par la fiche et la barre du jeu : décor simple et sombre à ces endroits.

## Prompt (à coller dans ChatGPT)

```
Carte du monde illustrée pour un jeu vidéo dark fantasy, format paysage 16:9 (1920x1080), style carte ancienne peinte à la main, vue de dessus légèrement inclinée, tons sombres (sépia, brun, rouge sang, gris cendre), sans aucun texte ni étiquette.

Le voyage va du sud-ouest (en bas à gauche) vers le nord (en haut). Une mer sombre longe tout le bord gauche. Un fleuve descend des montagnes du nord jusqu'à la mer.
- Tiers du bas (sud) : terres d'ocre et de cendres. En bas à gauche, un domaine seigneurial en ruine qui fume encore ; un peu plus haut, une cité grise endeuillée aux lanternes ; à droite, des camps de mercenaires aux drapeaux noirs ; plus à droite et plus haut, l'entrée d'anciennes catacombes royales dans une colline.
- Centre : terres rougeâtres. Une plaine brûlée et calcinée au milieu ; à gauche, une forêt pétrifiée aux arbres de pierre grise près d'un petit lac de verre noir ; au-dessus, des marais brumeux aux eaux vertes ; au centre droit, un bastion fortifié sous un ciel d'éclipse rouge.
- Tiers du haut (nord) : montagnes noires et cendres. Une vallée de tombeaux de héros ; une citadelle de torture hérissée de pointes ; une grande plaine de bataille ; et tout en haut à droite, au sommet des montagnes, un trône de pierre noire entouré d'une lueur rouge.
- Juste à gauche du trône, dans le ciel, un médaillon de pierre fendu, une moitié bleue et une moitié rouge, à peine visible derrière un voile violet.

Positions approximatives à respecter (en % depuis le bord gauche, puis depuis le haut) : domaine 9/89, cité 19/81, camps 30/88, catacombes 39/76, plaine brûlée 27/65, forêt pétrifiée 14/55, marais 23/42, bastion 36/50, vallée des héros 45/37, citadelle 55/46, plaine de bataille 62/32, trône 63/18, médaillon 50/16.

Laisse la partie droite de l'image (de 70 % à 100 % de la largeur) et la bande du haut (9 %) simples et sombres, sans élément important. Aucun texte, aucun nom, aucune icône d'interface.
```
