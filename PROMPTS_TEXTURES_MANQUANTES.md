# Prompts ChatGPT : textures et images qui manquent encore

> ✅ **Tout est fait** (v0.80.7, 2026-10-23).

J'ai fait le tour des **34 écrans** du jeu (une capture de chacun). Voici tout ce qui manque encore. Tant qu'une image manque, le jeu garde ce qu'il affiche aujourd'hui : rien ne casse.

| Partie | Quoi | Nombre | Où ça sert |
|---|---|---|---|
| 1 | Nouveaux cadres de rareté (N, R, SR, SSR, UR, Légende) | 6 | autour de toutes les cartes (Deck, Invocation, Bestiaire, Galerie…) |
| 2 | Icônes des objets du Reliquaire | 37 (5 planches) | Reliquaire, Boutique, Expéditions, butins, Évolution… (aujourd'hui : une lettre dans un rond) |
| 3 | Fonds de 2 écrans | 2 | Armée du Boss de Monde et Mon Héros (aujourd'hui : fond uni) |

**Total : 13 images.** Une image par message.

---

## Partie 1 — Les cadres de rareté (6)

Les nouveaux cadres sont plus épais, en vrai relief (double moulure), avec des matières plus sombres et plus nobles que les anciens, et chaque rareté bien différente des autres. Fais les six **dans la même conversation** pour qu'ils aient la même patte. Rends-moi `cadre_n.png`, `cadre_r.png`, `cadre_sr.png`, `cadre_ssr.png`, `cadre_ur.png`, `cadre_leg.png` : je les détoure et ils remplacent les anciens partout.

> Le jeu étire les côtés selon la taille de chaque carte : c'est pour ça que les ornements doivent rester dans les coins.

#### ✅ FAIT — Commune (N) → `cadre_n.png`
```
Crée UN SEUL cadre de carte à jouer vide pour un jeu mobile dark fantasy (style cartes de collection gacha haut de gamme), peint de façon réaliste et très détaillée, éclairage chaud et dramatique venant du haut à gauche.

FORMAT, À RESPECTER STRICTEMENT :
- image carrée 1024x1024 ;
- au centre, un cadre VERTICAL (3 de large pour 4 de haut) qui occupe toute la hauteur de l'image avec une petite marge, vu parfaitement de face, parfaitement symétrique gauche-droite et haut-bas ;
- le fond autour du cadre ET tout l'intérieur du cadre sont en VERT UNI très vif (#00FF00), sans dégradé, sans ombre : l'intérieur est vide, c'est là que viendra l'illustration ; aucun vert dans le cadre lui-même ;
- aucun texte, aucun chiffre, aucune plaque de nom, aucun symbole d'élément.

FORME (très important, sinon le cadre se déforme dans le jeu) :
- une vraie BAGUETTE en relief, plus épaisse qu'un simple filet : environ 7 % de la largeur du cadre, avec une double moulure (un listel extérieur et un listel intérieur biseauté qui jette une petite ombre vers l'image) ;
- tous les ornements sont dans les QUATRE COINS (chaque coin occupe au plus un quart de la largeur du cadre) ; ils peuvent dépasser un peu vers l'extérieur, jamais vers l'intérieur ;
- entre les coins, les quatre côtés sont une moulure droite et régulière, de même épaisseur partout, SANS motif unique, SANS pierre, SANS ornement au milieu (seulement une matière régulière : métal martelé, filet gravé continu...).

LE CADRE — Rareté Commune (N) : fer noirci et cuir : baguette de fer sombre martelé bordée d'un fin filet de cuir brun cousu ; coins en équerres de fer forgé avec un gros rivet rond, quelques traces d'usure (pas de rouille orange). Sobre mais solide et soigné.
```

#### ✅ FAIT — Rare (R) → `cadre_r.png`
```
Crée UN SEUL cadre de carte à jouer vide pour un jeu mobile dark fantasy (style cartes de collection gacha haut de gamme), peint de façon réaliste et très détaillée, éclairage chaud et dramatique venant du haut à gauche.

FORMAT, À RESPECTER STRICTEMENT :
- image carrée 1024x1024 ;
- au centre, un cadre VERTICAL (3 de large pour 4 de haut) qui occupe toute la hauteur de l'image avec une petite marge, vu parfaitement de face, parfaitement symétrique gauche-droite et haut-bas ;
- le fond autour du cadre ET tout l'intérieur du cadre sont en VERT UNI très vif (#00FF00), sans dégradé, sans ombre : l'intérieur est vide, c'est là que viendra l'illustration ; aucun vert dans le cadre lui-même ;
- aucun texte, aucun chiffre, aucune plaque de nom, aucun symbole d'élément.

FORME (très important, sinon le cadre se déforme dans le jeu) :
- une vraie BAGUETTE en relief, plus épaisse qu'un simple filet : environ 7 % de la largeur du cadre, avec une double moulure (un listel extérieur et un listel intérieur biseauté qui jette une petite ombre vers l'image) ;
- tous les ornements sont dans les QUATRE COINS (chaque coin occupe au plus un quart de la largeur du cadre) ; ils peuvent dépasser un peu vers l'extérieur, jamais vers l'intérieur ;
- entre les coins, les quatre côtés sont une moulure droite et régulière, de même épaisseur partout, SANS motif unique, SANS pierre, SANS ornement au milieu (seulement une matière régulière : métal martelé, filet gravé continu...).

LE CADRE — Rareté Rare (R) : bronze bleui : baguette de bronze patiné aux reflets bleu-sarcelle profonds, gravée d'une fine frise continue ; coins en volutes de bronze enroulées autour d'une petite perle de turquoise. Élégant et sombre.
```

#### ✅ FAIT — Super Rare (SR) → `cadre_sr.png`
```
Crée UN SEUL cadre de carte à jouer vide pour un jeu mobile dark fantasy (style cartes de collection gacha haut de gamme), peint de façon réaliste et très détaillée, éclairage chaud et dramatique venant du haut à gauche.

FORMAT, À RESPECTER STRICTEMENT :
- image carrée 1024x1024 ;
- au centre, un cadre VERTICAL (3 de large pour 4 de haut) qui occupe toute la hauteur de l'image avec une petite marge, vu parfaitement de face, parfaitement symétrique gauche-droite et haut-bas ;
- le fond autour du cadre ET tout l'intérieur du cadre sont en VERT UNI très vif (#00FF00), sans dégradé, sans ombre : l'intérieur est vide, c'est là que viendra l'illustration ; aucun vert dans le cadre lui-même ;
- aucun texte, aucun chiffre, aucune plaque de nom, aucun symbole d'élément.

FORME (très important, sinon le cadre se déforme dans le jeu) :
- une vraie BAGUETTE en relief, plus épaisse qu'un simple filet : environ 7 % de la largeur du cadre, avec une double moulure (un listel extérieur et un listel intérieur biseauté qui jette une petite ombre vers l'image) ;
- tous les ornements sont dans les QUATRE COINS (chaque coin occupe au plus un quart de la largeur du cadre) ; ils peuvent dépasser un peu vers l'extérieur, jamais vers l'intérieur ;
- entre les coins, les quatre côtés sont une moulure droite et régulière, de même épaisseur partout, SANS motif unique, SANS pierre, SANS ornement au milieu (seulement une matière régulière : métal martelé, filet gravé continu...).

LE CADRE — Rareté Super Rare (SR) : argent noirci et améthyste : baguette d'argent ciselé noircie dans les creux ; coins en arabesques fines et pointues, chacun serti d'une améthyste violette taillée en losange qui accroche la lumière.
```

#### ✅ FAIT — Super Super Rare (SSR) → `cadre_ssr.png`
```
Crée UN SEUL cadre de carte à jouer vide pour un jeu mobile dark fantasy (style cartes de collection gacha haut de gamme), peint de façon réaliste et très détaillée, éclairage chaud et dramatique venant du haut à gauche.

FORMAT, À RESPECTER STRICTEMENT :
- image carrée 1024x1024 ;
- au centre, un cadre VERTICAL (3 de large pour 4 de haut) qui occupe toute la hauteur de l'image avec une petite marge, vu parfaitement de face, parfaitement symétrique gauche-droite et haut-bas ;
- le fond autour du cadre ET tout l'intérieur du cadre sont en VERT UNI très vif (#00FF00), sans dégradé, sans ombre : l'intérieur est vide, c'est là que viendra l'illustration ; aucun vert dans le cadre lui-même ;
- aucun texte, aucun chiffre, aucune plaque de nom, aucun symbole d'élément.

FORME (très important, sinon le cadre se déforme dans le jeu) :
- une vraie BAGUETTE en relief, plus épaisse qu'un simple filet : environ 7 % de la largeur du cadre, avec une double moulure (un listel extérieur et un listel intérieur biseauté qui jette une petite ombre vers l'image) ;
- tous les ornements sont dans les QUATRE COINS (chaque coin occupe au plus un quart de la largeur du cadre) ; ils peuvent dépasser un peu vers l'extérieur, jamais vers l'intérieur ;
- entre les coins, les quatre côtés sont une moulure droite et régulière, de même épaisseur partout, SANS motif unique, SANS pierre, SANS ornement au milieu (seulement une matière régulière : métal martelé, filet gravé continu...).

LE CADRE — Rareté Super Super Rare (SSR) : or ancien et grenat : baguette d'or vieilli au fini satiné (pas jaune vif), gravée d'un filet continu ; coins en feuilles d'acanthe sculptées en relief profond, chacun serti d'un grenat rouge sombre. Riche et noble, sans être clinquant.
```

#### ✅ FAIT — Ultime (UR) → `cadre_ur.png`
```
Crée UN SEUL cadre de carte à jouer vide pour un jeu mobile dark fantasy (style cartes de collection gacha haut de gamme), peint de façon réaliste et très détaillée, éclairage chaud et dramatique venant du haut à gauche.

FORMAT, À RESPECTER STRICTEMENT :
- image carrée 1024x1024 ;
- au centre, un cadre VERTICAL (3 de large pour 4 de haut) qui occupe toute la hauteur de l'image avec une petite marge, vu parfaitement de face, parfaitement symétrique gauche-droite et haut-bas ;
- le fond autour du cadre ET tout l'intérieur du cadre sont en VERT UNI très vif (#00FF00), sans dégradé, sans ombre : l'intérieur est vide, c'est là que viendra l'illustration ; aucun vert dans le cadre lui-même ;
- aucun texte, aucun chiffre, aucune plaque de nom, aucun symbole d'élément.

FORME (très important, sinon le cadre se déforme dans le jeu) :
- une vraie BAGUETTE en relief, plus épaisse qu'un simple filet : environ 7 % de la largeur du cadre, avec une double moulure (un listel extérieur et un listel intérieur biseauté qui jette une petite ombre vers l'image) ;
- tous les ornements sont dans les QUATRE COINS (chaque coin occupe au plus un quart de la largeur du cadre) ; ils peuvent dépasser un peu vers l'extérieur, jamais vers l'intérieur ;
- entre les coins, les quatre côtés sont une moulure droite et régulière, de même épaisseur partout, SANS motif unique, SANS pierre, SANS ornement au milieu (seulement une matière régulière : métal martelé, filet gravé continu...).

LE CADRE — Rareté Ultime (UR) : fer noir et or sanglant : baguette de fer noir poli bordée d'un filet d'or rouge ; coins en griffes de dragon recourbées tenant chacune un rubis rouge sang qui luit faiblement de l'intérieur ; fines veines rougeoyantes dans le métal des coins seulement. Menaçant et précieux.
```

#### ✅ FAIT — Légende → `cadre_leg.png`
```
Crée UN SEUL cadre de carte à jouer vide pour un jeu mobile dark fantasy (style cartes de collection gacha haut de gamme), peint de façon réaliste et très détaillée, éclairage chaud et dramatique venant du haut à gauche.

FORMAT, À RESPECTER STRICTEMENT :
- image carrée 1024x1024 ;
- au centre, un cadre VERTICAL (3 de large pour 4 de haut) qui occupe toute la hauteur de l'image avec une petite marge, vu parfaitement de face, parfaitement symétrique gauche-droite et haut-bas ;
- le fond autour du cadre ET tout l'intérieur du cadre sont en VERT UNI très vif (#00FF00), sans dégradé, sans ombre : l'intérieur est vide, c'est là que viendra l'illustration ; aucun vert dans le cadre lui-même ;
- aucun texte, aucun chiffre, aucune plaque de nom, aucun symbole d'élément.

FORME (très important, sinon le cadre se déforme dans le jeu) :
- une vraie BAGUETTE en relief, plus épaisse qu'un simple filet : environ 7 % de la largeur du cadre, avec une double moulure (un listel extérieur et un listel intérieur biseauté qui jette une petite ombre vers l'image) ;
- tous les ornements sont dans les QUATRE COINS (chaque coin occupe au plus un quart de la largeur du cadre) ; ils peuvent dépasser un peu vers l'extérieur, jamais vers l'intérieur ;
- entre les coins, les quatre côtés sont une moulure droite et régulière, de même épaisseur partout, SANS motif unique, SANS pierre, SANS ornement au milieu (seulement une matière régulière : métal martelé, filet gravé continu...).

LE CADRE — Rareté Légende : or blanc et pierre de lune : baguette d'or blanc lumineux finement gravée ; coins en ailes d'ange déployées sculptées plume par plume, chacun serti d'une pierre de lune nacrée aux reflets bleus et roses ; très léger halo doré pâle autour des coins uniquement. Le plus beau et le plus lumineux des six.
```

---

## Partie 2 — Les icônes des objets (37, en 5 planches)

Une bulle = une planche de 9 objets (la 5e n'en a qu'un). La planche 4 a un fond **magenta** au lieu de vert, parce qu'elle contient les cristaux verts de la Sève. Rends-moi `objets_1.png` … `objets_5.png`.

#### ✅ FAIT — Planche 1 → `objets_1.png`
```
Crée une planche d'ICÔNES D'OBJETS pour l'inventaire d'un jeu mobile dark fantasy, peintes de façon réaliste et très détaillée (style icônes de jeu de rôle haut de gamme), éclairage chaud venant du haut à gauche, même style pour toutes.

FORMAT, À RESPECTER STRICTEMENT :
- image carrée 1024x1024 ;
- grille parfaitement régulière de 3 colonnes et 3 rangées : 9 cases carrées identiques, séparées par un fin trait NOIR droit ;
- dans chaque case : UN SEUL objet, bien centré, vu de trois quarts légèrement d'en haut, entier, qui remplit environ les trois quarts de la case sans toucher ses bords ;
- fond de chaque case : VERT UNI très vif (#00FF00), sans dégradé, sans ombre portée, sans décor ; aucune couleur verte sur les objets ;
- aucun texte, aucun chiffre, aucune lettre, aucun cadre, aucune bordure décorative ;
- respecte l'ordre : case 1 en haut à gauche, lecture de gauche à droite, rangée par rangée ;
- s'il y a moins de 9 objets, laisse les cases restantes entièrement noires ;
- chaque objet doit se reconnaître même tout petit (silhouette nette, couleur dominante claire).

Contenu des cases, dans l'ordre :
1. une braise de lave rouge-orange incandescente et craquelée, posée dans une petite coupe de fer noir
2. une grande plume blanche aux reflets dorés qui brille doucement
3. un gros éclat de roche brune hérissé, arraché à un géant, avec une veine de cristal orangé
4. un petit tas de poussière rouge scintillante dans une coupelle de pierre, quelques grains qui flottent
5. un petit coffre en bois cerclé de bronze, fermé
6. un coffre moyen en bois sombre cerclé d'argent, fermé, avec une serrure ornée
7. un beau coffre cerclé d'or, entrouvert, des pièces d'or qui débordent
8. un grand coffre royal rouge et or, une couronne sculptée sur le couvercle, entrouvert sur des joyaux
9. un sceau de cire rouge sang frappé d'une épée et d'une route, avec un bout de ruban noir
```
Fichiers : 1 = `braise_infernale` (Braise Infernale), 2 = `plume_celeste` (Plume Céleste), 3 = `fragment_colossal` (Fragment Colossal), 4 = `poussiere_echo` (Poussière d'Écho), 5 = `coffre_bronze` (Coffre de Bronze), 6 = `coffre_argent` (Coffre d'Argent), 7 = `coffre_or` (Coffre d'Or), 8 = `coffre_royal` (Coffre Royal), 9 = `sceau_marche` (Sceau de Marche)

#### ✅ FAIT — Planche 2 → `objets_2.png`
```
Crée une planche d'ICÔNES D'OBJETS pour l'inventaire d'un jeu mobile dark fantasy, peintes de façon réaliste et très détaillée (style icônes de jeu de rôle haut de gamme), éclairage chaud venant du haut à gauche, même style pour toutes.

FORMAT, À RESPECTER STRICTEMENT :
- image carrée 1024x1024 ;
- grille parfaitement régulière de 3 colonnes et 3 rangées : 9 cases carrées identiques, séparées par un fin trait NOIR droit ;
- dans chaque case : UN SEUL objet, bien centré, vu de trois quarts légèrement d'en haut, entier, qui remplit environ les trois quarts de la case sans toucher ses bords ;
- fond de chaque case : VERT UNI très vif (#00FF00), sans dégradé, sans ombre portée, sans décor ; aucune couleur verte sur les objets ;
- aucun texte, aucun chiffre, aucune lettre, aucun cadre, aucune bordure décorative ;
- respecte l'ordre : case 1 en haut à gauche, lecture de gauche à droite, rangée par rangée ;
- s'il y a moins de 9 objets, laisse les cases restantes entièrement noires ;
- chaque objet doit se reconnaître même tout petit (silhouette nette, couleur dominante claire).

Contenu des cases, dans l'ordre :
1. une petite fiole ronde de liquide bleu électrique lumineux, bouchon de liège
2. une grande bouteille ouvragée de liquide bleu électrique lumineux, bouchon de cristal
3. un petit livre relié de cuir brun, fermé par une sangle
4. un livre épais relié de cuir rouge aux coins de fer
5. un énorme grimoire ancien relié de cuir noir et d'or, à moitié ouvert, une douce lumière dorée entre les pages
6. une pierre ovale gris clair gravée d'une étoile, qui luit d'une lumière dorée en son centre
7. un éclat de cristal violet et or taillé en pointe, qui flotte au-dessus d'un petit socle de pierre
8. un médaillon de bois et d'os gravé d'une empreinte de patte, lié par des lanières de cuir
9. une page de parchemin arrachée et roussie, couverte de runes violettes qui luisent
```
Fichiers : 1 = `elixir_petit` (Petit Élixir de Stamina), 2 = `elixir_grand` (Grand Élixir de Stamina), 3 = `tome_petit` (Tome d'Apprenti), 4 = `tome_grand` (Tome de Vétéran), 5 = `tome_ancien` (Tome Ancien), 6 = `pierre_eveil` (Pierre d'Éveil), 7 = `eclat_superieur` (Éclat de Pacte Supérieur), 8 = `sceau_sauvage` (Sceau Sauvage), 9 = `page_grimoire` (Page de Grimoire)

#### ✅ FAIT — Planche 3 → `objets_3.png`
```
Crée une planche d'ICÔNES D'OBJETS pour l'inventaire d'un jeu mobile dark fantasy, peintes de façon réaliste et très détaillée (style icônes de jeu de rôle haut de gamme), éclairage chaud venant du haut à gauche, même style pour toutes.

FORMAT, À RESPECTER STRICTEMENT :
- image carrée 1024x1024 ;
- grille parfaitement régulière de 3 colonnes et 3 rangées : 9 cases carrées identiques, séparées par un fin trait NOIR droit ;
- dans chaque case : UN SEUL objet, bien centré, vu de trois quarts légèrement d'en haut, entier, qui remplit environ les trois quarts de la case sans toucher ses bords ;
- fond de chaque case : VERT UNI très vif (#00FF00), sans dégradé, sans ombre portée, sans décor ; aucune couleur verte sur les objets ;
- aucun texte, aucun chiffre, aucune lettre, aucun cadre, aucune bordure décorative ;
- respecte l'ordre : case 1 en haut à gauche, lecture de gauche à droite, rangée par rangée ;
- s'il y a moins de 9 objets, laisse les cases restantes entièrement noires ;
- chaque objet doit se reconnaître même tout petit (silhouette nette, couleur dominante claire).

Contenu des cases, dans l'ordre :
1. une petite goutte de cristal rouge-orange en forme de goutte d'eau, une braise à l'intérieur
2. une larme de cristal rouge-orange plus grande et taillée, entourée d'une petite flamme
3. un gros cristal rouge-orange en forme de cœur, enchâssé de fer noir, qui rougeoie
4. une petite goutte de cristal bleu profond en forme de goutte d'eau
5. une larme de cristal bleu profond plus grande et taillée, entourée de petites bulles
6. un gros cristal bleu profond en forme de cœur, enchâssé d'argent et de coquillage, qui luit
7. une petite goutte de cristal violet sombre en forme de goutte d'eau
8. une larme de cristal violet sombre plus grande et taillée, entourée de fumée violette
9. un gros cristal violet sombre en forme de cœur, enchâssé d'argent noirci, qui luit
```
Fichiers : 1 = `goutte_braise` (Goutte de Braise), 2 = `larme_braise` (Larme de Braise), 3 = `coeur_braise` (Cœur de Braise), 4 = `goutte_abysse` (Goutte d'Abysse), 5 = `larme_abysse` (Larme d'Abysse), 6 = `coeur_abysse` (Cœur d'Abysse), 7 = `goutte_ombre` (Goutte d'Ombre), 8 = `larme_ombre` (Larme d'Ombre), 9 = `coeur_ombre` (Cœur d'Ombre)

#### ✅ FAIT — Planche 4 → `objets_4.png`
```
Crée une planche d'ICÔNES D'OBJETS pour l'inventaire d'un jeu mobile dark fantasy, peintes de façon réaliste et très détaillée (style icônes de jeu de rôle haut de gamme), éclairage chaud venant du haut à gauche, même style pour toutes.

FORMAT, À RESPECTER STRICTEMENT :
- image carrée 1024x1024 ;
- grille parfaitement régulière de 3 colonnes et 3 rangées : 9 cases carrées identiques, séparées par un fin trait NOIR droit ;
- dans chaque case : UN SEUL objet, bien centré, vu de trois quarts légèrement d'en haut, entier, qui remplit environ les trois quarts de la case sans toucher ses bords ;
- fond de chaque case : MAGENTA UNI très vif (#FF00FF), sans dégradé, sans ombre portée, sans décor ; aucune couleur magenta sur les objets ;
- aucun texte, aucun chiffre, aucune lettre, aucun cadre, aucune bordure décorative ;
- respecte l'ordre : case 1 en haut à gauche, lecture de gauche à droite, rangée par rangée ;
- s'il y a moins de 9 objets, laisse les cases restantes entièrement noires ;
- chaque objet doit se reconnaître même tout petit (silhouette nette, couleur dominante claire).

Contenu des cases, dans l'ordre :
1. une petite goutte de cristal or-blanc en forme de goutte d'eau
2. une larme de cristal or-blanc plus grande et taillée, entourée de petits rayons de lumière
3. un gros cristal or-blanc en forme de cœur, enchâssé d'or, qui rayonne
4. une petite goutte de cristal rouge sang en forme de goutte d'eau
5. une larme de cristal rouge sang plus grande et taillée, entourée de fines épines
6. un gros cristal rouge sang en forme de cœur, enchâssé de fer noir et d'épines, qui palpite
7. une petite goutte de cristal vert émeraude en forme de goutte d'eau
8. une larme de cristal vert émeraude plus grande et taillée, entourée d'une petite feuille
9. un gros cristal vert émeraude en forme de cœur, enchâssé de racines et de bois, qui luit
```
Fichiers : 1 = `goutte_aube` (Goutte d'Aube), 2 = `larme_aube` (Larme d'Aube), 3 = `coeur_aube` (Cœur d'Aube), 4 = `goutte_sang` (Goutte de Sang), 5 = `larme_sang` (Larme de Sang), 6 = `coeur_sang` (Cœur de Sang), 7 = `goutte_seve` (Goutte de Sève), 8 = `larme_seve` (Larme de Sève), 9 = `coeur_seve` (Cœur de Sève)

#### ✅ FAIT — Planche 5 → `objets_5.png`
```
Crée une planche d'ICÔNES D'OBJETS pour l'inventaire d'un jeu mobile dark fantasy, peintes de façon réaliste et très détaillée (style icônes de jeu de rôle haut de gamme), éclairage chaud venant du haut à gauche, même style pour toutes.

FORMAT, À RESPECTER STRICTEMENT :
- image carrée 1024x1024 ;
- grille parfaitement régulière de 3 colonnes et 3 rangées : 9 cases carrées identiques, séparées par un fin trait NOIR droit ;
- dans chaque case : UN SEUL objet, bien centré, vu de trois quarts légèrement d'en haut, entier, qui remplit environ les trois quarts de la case sans toucher ses bords ;
- fond de chaque case : VERT UNI très vif (#00FF00), sans dégradé, sans ombre portée, sans décor ; aucune couleur verte sur les objets ;
- aucun texte, aucun chiffre, aucune lettre, aucun cadre, aucune bordure décorative ;
- respecte l'ordre : case 1 en haut à gauche, lecture de gauche à droite, rangée par rangée ;
- s'il y a moins de 9 objets, laisse les cases restantes entièrement noires ;
- chaque objet doit se reconnaître même tout petit (silhouette nette, couleur dominante claire).

Contenu des cases, dans l'ordre :
1. un grimoire noir fermé par des chaînes et un cadenas, un œil violet sculpté sur la couverture, une fumée violette qui s'en échappe
```
Fichiers : 1 = `grimoire_interdit` (Grimoire Interdit)

---

## Partie 4 — Les icônes de la barre du haut (1 planche) — ✅ faite

La stamina, l'or, les gemmes et les boutons Chat / Aide / Nouveautés / Menu n'ont encore qu'un symbole. Les Éclats prennent déjà l'icône de l'Éclat de Pacte Supérieur. Rends-moi `icones_ui.png`.

#### ✅ FAIT — Planche → `icones_ui.png`
```
Crée une planche d'ICÔNES D'INTERFACE pour la barre du haut d'un jeu mobile dark fantasy, peintes de façon réaliste et très détaillée (même style que des icônes d'objets de jeu de rôle haut de gamme), éclairage chaud venant du haut à gauche, même style pour toutes.

FORMAT, À RESPECTER STRICTEMENT :
- image carrée 1024x1024 ;
- grille parfaitement régulière de 3 colonnes et 3 rangées : 9 cases carrées identiques, séparées par un fin trait NOIR droit ;
- dans chaque case : UN SEUL objet, bien centré, vu de face ou très légèrement de trois quarts, entier, qui remplit environ les trois quarts de la case sans toucher ses bords ;
- fond de chaque case : VERT UNI très vif (#00FF00), sans dégradé, sans ombre portée, sans décor ; aucune couleur verte sur les objets ;
- aucun texte, aucun chiffre, aucune lettre, aucun cadre rond autour des objets ;
- respecte l'ordre : case 1 en haut à gauche, lecture de gauche à droite, rangée par rangée ;
- les cases 8 et 9 restent entièrement NOIRES ;
- les icônes seront affichées TOUTES PETITES (environ 36 pixels) : silhouettes très simples et très lisibles, une couleur dominante forte, peu de petits détails.

Contenu des cases, dans l'ordre :
1. STAMINA : un éclair bleu électrique lumineux gravé dans un petit médaillon de fer sombre
2. OR : une petite pile de trois pièces d'or épaisses frappées d'un phénix
3. GEMMES : une gemme violette taillée en losange, brillante, avec un petit éclat de lumière
4. CHAT : une bulle de parchemin enroulé avec un sceau de cire rouge, comme une lettre qu'on envoie
5. AIDE : un vieux livre ouvert avec un point d'interrogation doré lumineux qui flotte au-dessus
6. NOUVEAUTÉS : une plume d'écriture dorée posée sur un parchemin déroulé
7. MENU : trois barres horizontales de fer forgé noir aux bouts dorés, superposées, comme une petite grille de forge
```
Fichiers : 1 = `stamina`, 2 = `or`, 3 = `gemmes`, 4 = `chat`, 5 = `aide`, 6 = `nouveautes`, 7 = `menu`

---

## Partie 3 — Les fonds de 2 écrans (2)

Même style que les autres fonds de menu (groupe LE SANG : salles de la forteresse, rouge et or). Rends-moi `armee.png` et `profil.png`.

#### ✅ FAIT — Armée du Boss de Monde → `armee.png`
```
Illustration de fond pour un écran de menu de jeu vidéo dark fantasy, format paysage 3:2. Peinture numérique détaillée, style art de jeu de cartes gacha dark fantasy, ambiance gothique et mélancolique.

Règles importantes :
- Aucun personnage, aucune silhouette humaine, aucun texte, aucun logo, aucun cadre, aucune interface.
- Luminosité MOYENNE : sombre et dramatique, mais tous les détails restent visibles dans les ombres (pas de noir bouché). L'image sera assombrie par le jeu, elle ne doit pas l'être déjà.
- Le centre de l'image reste calme et peu chargé (sol dégagé, brume légère, profondeur floue) : des panneaux d'interface seront posés par-dessus.
- Les éléments forts du décor sont sur les côtés et dans le lointain.
- Le haut et le bas de l'image (environ 12 % chacun) peuvent être rognés : rien d'important à ces endroits.
Scène : la salle des cartes de guerre de la forteresse. Une immense table de stratégie couverte de figurines de soldats, de cartes et de bannières miniatures ; des râteliers d'armes et des étendards rouge sang brodés d'un phénix doré le long des murs ; au fond, quatre grands boucliers peints accrochés au mur, côte à côte. Lumière chaude de braseros, reflets dorés sur le métal. Le centre et le dessus de la table restent dégagés et calmes.
```

#### ✅ FAIT — Mon Héros → `profil.png`
```
Illustration de fond pour un écran de menu de jeu vidéo dark fantasy, format paysage 3:2. Peinture numérique détaillée, style art de jeu de cartes gacha dark fantasy, ambiance gothique et mélancolique.

Règles importantes :
- Aucun personnage, aucune silhouette humaine, aucun texte, aucun logo, aucun cadre, aucune interface.
- Luminosité MOYENNE : sombre et dramatique, mais tous les détails restent visibles dans les ombres (pas de noir bouché). L'image sera assombrie par le jeu, elle ne doit pas l'être déjà.
- Le centre de l'image reste calme et peu chargé (sol dégagé, brume légère, profondeur floue) : des panneaux d'interface seront posés par-dessus.
- Les éléments forts du décor sont sur les côtés et dans le lointain.
- Le haut et le bas de l'image (environ 12 % chacun) peuvent être rognés : rien d'important à ces endroits.
Scène : la chambre de l'aîné des Valcendre dans la forteresse. Une alcôve de pierre avec un vieux lit à baldaquin rouge sombre, une armure et une épée posées sur un mannequin, le blason de la famille (un phénix doré) brodé sur une grande tapisserie, des trophées et des souvenirs sur des étagères, une bougie sur une table, une fenêtre en ogive ouverte sur les montagnes la nuit. Le centre de l'image reste calme et peu chargé.
```
