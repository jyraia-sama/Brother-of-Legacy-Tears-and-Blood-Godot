# Prompts ChatGPT : personnages de l'histoire et Acte XIII

Portraits des personnages des **dialogues** (planches 36 et 37) et images définitives de l'**Acte XIII caché**
(écran des chapitres et fond du plateau). Tu me donnes les planches / images, je les découpe et je les range.

**Tant qu'une image n'existe pas, le jeu affiche un médaillon coloré avec l'initiale** : rien ne casse.

## Mode d'emploi

1. Pour les planches : colle le **BLOC COMMUN PORTRAITS** puis la liste de la planche. **Une planche par message.**
   Joins si possible une ancienne planche réussie (ex. planche_01) pour garder le même style.
2. Enregistre sous le nom indiqué (`planche_36.png`...), sans recadrer, et envoie-la-moi.
3. Pour l'Acte XIII : suis les consignes de la section « Écran de l'Acte XIII » (même méthode que les autres Actes).

**Repères du scénario** (voir HISTOIRE.md) : la maison **Valcendre**, l'aîné porte la pierre **bleue** (la Larme),
le cadet **Kaël** porte la pierre **rouge** (le Sang). Le Mal, **Morvaël, la Soif Première**, est une faim ancienne liée à leur sang.

---

## BLOC COMMUN PORTRAITS (à coller à chaque fois)

```
Crée une planche de portraits de personnages pour les dialogues d'un jeu mobile dark fantasy.

FORMAT, À RESPECTER STRICTEMENT :
- image carrée 1024x1024 ;
- grille parfaitement régulière de 3 colonnes et 3 rangées : 9 cases carrées de taille identique, séparées par un fin trait noir droit ;
- dans chaque case : un seul personnage, cadré en buste (tête et épaules bien visibles), centré, qui ne dépasse JAMAIS de sa case ;
- fond de chaque case : dégradé sombre uni avec une aura colorée lumineuse derrière le personnage (couleur indiquée entre parenthèses) ;
- aucun texte, aucun chiffre, aucun nom, aucun cadre de carte, aucune bordure décorative ;
- respecte l'ordre : case 1 en haut à gauche, lecture de gauche à droite, rangée par rangée ;
- s'il y a moins de 9 personnages, laisse les cases restantes entièrement noires.

STYLE : peinture numérique dark fantasy très détaillée, éclairage dramatique, même style pour tous, visages expressifs et lisibles même en petit.

Contenu des cases, dans l'ordre :
```

---

## Planche 36 → `planche_36.png` (les personnages principaux)

```
1. Kaël, jeune homme de 18 ans aux cheveux noirs en bataille, sourire insolent, armure de cuir d'un jeune noble, un médaillon à pierre rouge autour du cou (aura rouge chaude)
2. Kaël corrompu : le même jeune homme, visage creusé, veines noires qui remontent sur le cou et les joues, yeux rouges brillants, larmes sur les joues, flamme noire autour de lui (aura violette)
3. Kaël libéré, en héros : le même jeune homme adulte, armure noire et rouge ornée, cape déchirée, flamme noire maîtrisée dans une main, regard serein et déterminé, médaillon rouge et bleu (aura rouge et bleue)
4. Aldric Valcendre, seigneur d'une cinquantaine d'années, barbe grise courte, armure de noble usée, manteau aux armoiries d'un phénix de cendres, regard grave et bienveillant (aura dorée)
5. Othmar, le Premier Roi : spectre d'un roi très ancien, couronne de fer rouillée, visage fantomatique rongé de remords, chaînes spectrales autour des poignets (aura bleu pâle)
6. Corvin le mercenaire : homme de 35 ans au sourire charmeur, cicatrice sur le sourcil, cape de voyage, dagues à la ceinture, un regard qui cache quelque chose (aura orange, avec une ombre violette discrète)
7. Morvaël, la Soif Première : entité monstrueuse faite d'ombres et de bouches, silhouette féminine immense, couronne d'épines noires, yeux rouges innombrables, sang qui coule comme des larmes (aura rouge sang)
8. Le Frère Masqué : guerrier en armure noire intégrale, masque de métal lisse sans expression fendu d'une fissure rouge, flamme noire dans la main (aura violette)
9. le blason de la maison Valcendre : un médaillon ancien brisé en deux, une moitié avec une pierre bleue, l'autre avec une pierre rouge, sur un écu noir orné d'un phénix de cendres (aura rouge et bleue)
```

Fichiers : 1 = `kael`, 2 = `kael_sombre`, 3 = `kael_valcendre` (aussi l'image de l'unité Kaël), 4 = `aldric`, 5 = `othmar`,
6 = `compagnon`, 7 = `morvael` (aussi l'image du boss), 8 = `frere_masque` (aussi l'image du boss), 9 = `aine` (le joueur)

Commande :
`python3 outils/decouper_planche.py planche_36.png kael kael_sombre kael_valcendre+unite:kael_valcendre aldric othmar compagnon morvael+unite:morvael frere_masque+unite:frere_masque aine --personnages`

## Planche 37 → `planche_37.png` (personnages secondaires, facultatif)

```
1. l'Ermite de Pierre : vieil homme dont la peau est devenue roche grise veinée de cristal, longue barbe de lichen, yeux blancs (aura gris-vert)
2. le moine mourant : vieux moine amaigri en robe brune, capuche, chapelet, sur une paillasse d'hôpital (aura ocre)
3. la veuve : femme en voile noir, visage digne et triste, une lanterne à la main (aura bleu-gris)
4. le commandant Hervald : officier grisonnant en armure cabossée, cape bleue déchirée, épée levée (aura argent)
5. une résistante : jeune femme au visage couvert de suie, capuche, arbalète à l'épaule (aura brun-rouge)
6. le Seigneur des Cendres : mage en armure calcinée, corps fait de braises, couronne de fumée (aura orange)
7. l'Héritier Maudit : monstre humanoïde fait de dizaines de visages de jeunes hommes fondus ensemble, armure noire, épée de sang (aura rouge sombre)
8. l'Empereur Déchu : roi-guerrier squelettique en armure impériale ternie, couronne brisée (aura violet sombre)
```

Fichiers : `ermite`, `moine`, `veuve`, `commandant`, `resistante`, `seigneur_des_cendres+unite:seigneur_des_cendres`,
`heritier_maudit+unite:heritier_maudit`, `empereur_dechu+unite:empereur_dechu`

Commande :
`python3 outils/decouper_planche.py planche_37.png ermite moine veuve commandant resistante seigneur_des_cendres+unite:seigneur_des_cendres heritier_maudit+unite:heritier_maudit empereur_dechu+unite:empereur_dechu --personnages`

---

## Écran de l'Acte XIII → `acte_13.png`

Même méthode que les autres Actes (voir PROMPTS_CHATGPT.md) : joins l'image de l'Acte I, colle le **BLOC COMMUN** de
PROMPTS_CHATGPT.md, puis ce bloc. Enregistre en `acte_13.png` (16:9) dans `assets/actes/`.

```
Palette : moitié gauche rouge sang, moitié droite bleu glacé, qui se rejoignent au centre dans une lumière blanche.
Fond : l'intérieur d'un immense médaillon de verre brisé, un monde de cristal rouge et bleu flottant dans le vide, des silhouettes de jeunes hommes enchaînés figés dans le verre.
Vignettes :
I - un médaillon brisé posé sur une tombe, la pierre bleue couverte de rosée, un vieil ermite de pierre à côté ;
II - un marais brumeux où des roses noires mortes renferment une petite lumière dorée ;
III - un héros qui tombe dans un monde de verre rouge et bleu, entouré de souvenirs déformés ;
IV - des silhouettes enchaînées de jeunes hommes qui se relèvent, leurs chaînes devenant de la lumière ;
V - deux frères face à face, l'un enchaîné au cœur d'un cristal rouge, l'autre qui lui tend la main ;
VI - deux frères côte à côte face à une entité d'ombres couronnée d'épines, et le spectre d'un vieux roi derrière eux.
```

## Fond du plateau de l'Acte XIII → `fond_13.png`

À faire sans image jointe. Enregistre en `fond_13.png` (16:9, 1920×1080 si possible) dans `assets/plateaux/`.

```
Crée un décor de fond en 16:9 pour le plateau de jeu d'un jeu mobile dark fantasy, vu de loin, sans personnage, sans texte :
l'intérieur d'un immense médaillon de verre, un paysage de cristal où la moitié gauche est rouge sang et la moitié droite bleu glacé,
des îles de verre flottantes reliées par des ponts de lumière, des silhouettes enchaînées figées dans le cristal à l'horizon,
ciel noir étoilé, lumière mystérieuse. Style peinture numérique dark fantasy très détaillée, assez sombre au centre pour que des icônes restent lisibles.
```

---

## Pion du plateau : le grand frère → `pion_aine.png`

La figurine qui avance de case en case sur le plateau de l'Aventure. Enregistre-la en `pion_aine.png`
et envoie-la-moi : je détoure le fond si besoin et je la range dans `assets/plateaux/`.
Tant qu'elle n'existe pas, le jeu garde l'ancien pion d'échecs.

Conseils : joins l'image de Kaël (planche 36, case 1) pour la ressemblance de famille, demande **fond transparent**,
et génère 3-4 essais pour garder le meilleur. Le personnage doit **regarder vers la droite** (le jeu le retourne tout seul
quand il marche vers la gauche).

```
Crée une figurine de jeu de plateau pour un jeu mobile dark fantasy : le héros vu en pied, de trois quarts, debout sur un petit socle rond en pierre sombre gravé d'un phénix.

Le personnage : l'aîné de la maison Valcendre, homme d'environ 25 ans, grand frère protecteur de Kaël (même famille : cheveux noirs, mais plus courts et coiffés en arrière, courte barbe, regard grave et déterminé, une fine cicatrice sur la joue).
Armure de chevalier noble sombre (acier bruni et cuir noir), épaulières ornées, long manteau bleu nuit déchiré aux armoiries d'un phénix de cendres argenté.
Autour du cou, un médaillon avec une pierre BLEUE lumineuse (la Larme) qui brille doucement.
Une épée longue tenue basse dans la main droite, pose héroïque et stable, le corps tourné vers la DROITE de l'image.

FORMAT, À RESPECTER STRICTEMENT :
- image verticale 1024x1536 (portrait) ;
- FOND TRANSPARENT (PNG), sinon fond uni noir sans aucun décor ;
- la figurine entière est visible de la tête au socle, centrée, avec un peu de marge, rien n'est coupé ;
- proportions légèrement stylisées (tête un peu plus grande, silhouette très lisible même en tout petit) ;
- contour net et lumineux, légère lueur bleue autour du médaillon ;
- aucun texte, aucun chiffre, aucune ombre au sol en dehors du socle.

STYLE : même style que les portraits du jeu, peinture numérique dark fantasy très détaillée, éclairage dramatique venant du haut à gauche.
```

Variante « figurine peinte » (façon miniature de jeu de société) : remplace la ligne STYLE par
`STYLE : miniature de jeu de société en résine peinte à la main, rendu 3D réaliste, lumière douce de studio, couleurs sombres et or.`
