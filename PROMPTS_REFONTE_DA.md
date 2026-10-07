# Refonte de la direction artistique : portraits et figurines (v0.45+)

**La nouvelle D.A.** est celle de la planche des 8 héros hommages (`planche_39`) : peinture réaliste dark fantasy, fond brun sombre texturé façon vieux parchemin, lumière chaude et dramatique, fin trait noir entre les cases, cadrage à mi-corps. **Joins cette planche à chaque demande de portraits.**

On refait **188 unités** (héros, monstres, boss d'Actes, Tours, Donjons), soit **24 planches**.
On garde tel quel :
- la famille du Bélier (Anaïs, Loucas, Alysse, Laurent, et le Reflet de Laurent) ;
- les 8 héros hommages de la planche de référence ;
- les 7 Boss de Monde (déjà faits dans cette D.A.) ;
- Kaël et Morvaël, liés aux illustrations de l'histoire (à refaire plus tard si tu veux).

Les évolutions (`_evo`) reprennent l'image de leur unité de base : on les fera dans un second temps.

## Comment faire

Pour chaque planche, **deux demandes** à ChatGPT, dans la même conversation :
1. **Portraits** : bloc commun PORTRAITS + le bloc de la planche. Joins la planche de référence (les 8 hommages).
2. **Figurines** : bloc commun FIGURINES + le même bloc de la planche. Joins la planche de portraits que tu viens d'obtenir, et une figurine réussie (par exemple celle de la Combattante Ardente) pour le rendu.

Envoie-moi les planches au fur et à mesure (portraits + figurines). Je les découpe, je détoure les figurines et je les mets en jeu.

**Variété des poses** : chaque personnage a une attitude qui lui est propre (accroupi, assis, en plein vol, qui rit, qui se retourne…). C'est voulu : ne laisse pas ChatGPT les remettre tous de face et droits.

---

## BLOC COMMUN — PORTRAITS (à coller en premier)

```
Crée une planche de portraits de personnages pour les cartes d'un jeu mobile dark fantasy, EXACTEMENT dans le même style que la planche jointe : peinture numérique réaliste et très détaillée, fond brun sombre texturé façon vieux parchemin dans chaque case, éclairage chaud et dramatique venant du haut à gauche, fin trait noir droit entre les cases.

FORMAT, À RESPECTER STRICTEMENT :
- image paysage 1536x1024 ;
- grille parfaitement régulière de 4 colonnes et 2 rangées : 8 cases identiques ;
- dans chaque case : un seul personnage, cadré à mi-corps ou en buste, tête dans le tiers haut, qui ne dépasse jamais de sa case ;
- chaque personnage a SA PROPRE POSE et SON ATTITUDE (indiquées ci-dessous) : pas tous de face, pas tous immobiles ;
- les couleurs viennent du personnage (peau, fourrure, tenue) ; l'élément n'est qu'une petite lueur discrète ;
- aucun texte, aucun chiffre, aucun nom, aucun logo, aucun cadre de carte ;
- ordre : case 1 en haut à gauche, lecture de gauche à droite, rangée par rangée.

Contenu des 8 cases, dans l'ordre :
```

## BLOC COMMUN — FIGURINES (à coller en premier)

```
Crée une planche de figurines de jeu de plateau pour un jeu mobile dark fantasy : les personnages de la planche de portraits jointe, dans le même ordre, vus EN PIED, dans le même rendu peint que la figurine jointe (éclairage dramatique venant du haut à gauche, petit socle rond en pierre sombre sous les pieds).

FORMAT, À RESPECTER STRICTEMENT :
- image paysage 1536x1024 ;
- grille parfaitement régulière de 4 colonnes et 2 rangées, cases séparées par un fin trait noir ;
- dans chaque case : un seul personnage en pied, de trois quarts, tourné vers la DROITE de l'image, debout (ou posé) sur son petit socle rond, entier de la tête au socle, centré, qui ne touche pas les bords ;
- même visage, même tenue, mêmes couleurs que son portrait ; garde l'attitude du portrait ;
- silhouette très lisible même en tout petit ;
- fond VERT UNI très vif (#00FF00) dans chaque case, sans dégradé, sans ombre portée, sans décor ; aucun vert sur les personnages ni sur les socles ;
- aucun texte, aucun chiffre.

Les personnages, dans l'ordre :
```

**Planche 24** n'a que 4 personnages : remplace « 4 colonnes et 2 rangées : 8 cases » par « 2 colonnes et 2 rangées : 4 cases », et le format par « image carrée 1024x1024 ».

---

## Planche DA-01 — Les huit Légendes

| Case | Unité | Rareté | Élément · rôle |
|---|---|---|---|
| 1 | La Brute Noire (`brute_noire`) | SSR | Ténèbres · guerrier |
| 2 | Barbe Bleue (`barbe_bleue`) | SSR | Eau · tank |
| 3 | La Lance Dorée (`lance_doree`) | SSR | Sacré · guerrier |
| 4 | La Nymphe (`nymphe`) | SSR | Sacré · soutien |
| 5 | Le Mage Gris (`mage_gris`) | SSR | Feu · mage |
| 6 | La Dague Violette (`dague_violette`) | SSR | Ténèbres · assassin |
| 7 | Le Samouraï Rouge (`samourai_rouge`) | SSR | Feu · guerrier |
| 8 | Le Chevalier Blanc (`chevalier_blanc`) | SSR | Sacré · tank |

```
1. un gorille colossal au pelage noir de jais, armure de plaques sombres rivetée sur les épaules et les avant-bras, cicatrices sur le museau, il frappe sa poitrine d'un poing ganté de fer, regard furieux
2. un nain trapu à la longue barbe bleu nuit tressée d'anneaux d'argent, armure épaisse de capitaine de navire, grand bouclier rond orné d'une ancre posé devant lui, une main levée qui fait naître une bulle d'eau protectrice
3. un homme-lézard élancé aux écailles vert bronze, armure légère de cuir et d'or, longue lance dorée tenue à deux mains en position de charge, langue fourchue sortie, regard de prédateur
4. une elfe aux longs cheveux argentés et aux oreilles pointues, robe de voiles blanc et or, pieds nus, assise sur une racine, elle souffle doucement sur une poignée de lumière dorée dans sa paume
5. un petit gobelin malicieux aux grandes oreilles, longue robe de mage grise rapiécée trop grande pour lui, chapeau pointu qui lui tombe sur les yeux, il jongle avec trois petites boules de feu en ricanant
6. une elfe sombre à la peau gris-bleu et aux cheveux blancs courts, tenue de cuir noir et violet, accroupie sur une poutre, deux dagues courbes à lame violette croisées devant son visage masqué
7. un samouraï humain en armure laquée rouge sang, casque à cornes, katana à moitié dégainé, regard concentré sous un masque menpo, pétales de cerisier qui tombent
8. un chevalier humain massif en armure de plates blanche et dorée, cape blanche, grand pavois frappé d'un soleil planté devant lui, il se tient droit comme un rempart, visière relevée sur un regard calme
```

Commandes (je m'en occupe) :
`python3 outils/decouper_planche.py da_01_portraits.png brute_noire barbe_bleue lance_doree nymphe mage_gris dague_violette samourai_rouge chevalier_blanc`
`python3 outils/decouper_miniatures.py da_01_figurines.png --figurines brute_noire barbe_bleue lance_doree nymphe mage_gris dague_violette samourai_rouge chevalier_blanc`

---

## Planche DA-02 — Les premiers compagnons

| Case | Unité | Rareté | Élément · rôle |
|---|---|---|---|
| 1 | Chevalier Noir (`chevalier`) | R | Ténèbres · guerrier |
| 2 | Elf Sylvestre (`archer`) | R | Nature · tireur |
| 3 | Sorcier Sombre (`mage`) | SR | Ténèbres · mage |
| 4 | Clerc Sacré (`clerc`) | SR | Sacré · soutien |
| 5 | Guerrier Squelette (`squelette`) | N | Ténèbres · guerrier |
| 6 | Gardiens d'Ombre (`demon_inf`) | SR | Feu · tank |
| 7 | Seigneur Démon (`boss`) | SSR | Ténèbres · guerrier |
| 8 | Rat Géant (`rat_geant`) | N | Nature · guerrier |

```
1. un chevalier humain en armure noire usée et cabossée, cape rouge déchirée, épée longue tenue basse, casque sous le bras, visage fatigué mais fier
2. une jeune elfe des bois aux cheveux châtains tressés de feuilles, tenue de cuir vert mousse et capuche, arc long bandé, une flèche encochée, un œil fermé pour viser
3. un sorcier humain maigre au visage creusé, longue robe noire à col haut, grimoire ouvert flottant devant lui, des volutes d'ombre qui s'échappent des pages
4. une prêtresse humaine au visage doux, tunique blanche et étole bleue, cheveux courts bruns, un encensoir d'argent qui fume doucement, elle prie les yeux fermés
5. un squelette guerrier à l'armure rouillée dépareillée, bouclier fendu, épée ébréchée, la mâchoire de travers comme s'il souriait bêtement, petites lueurs bleues dans les orbites
6. un démon trapu à la peau rouge brique et aux petites cornes, armure de fonte noire, il porte sur l'épaule un énorme bouclier-porte en fer brûlant, l'air bougon
7. un seigneur démon immense à la peau noire craquelée de rouge, grandes cornes recourbées, armure d'os et de fer, couronne de flammes noires, assis sur un trône de crânes, menton posé sur son poing
8. un rat énorme de la taille d'un chien, pelage gris sale, incisives jaunes, dressé sur ses pattes arrière en reniflant l'air, une vieille pièce d'or dans la patte
```

Commandes (je m'en occupe) :
`python3 outils/decouper_planche.py da_02_portraits.png chevalier archer mage clerc squelette demon_inf boss rat_geant`
`python3 outils/decouper_miniatures.py da_02_figurines.png --figurines chevalier archer mage clerc squelette demon_inf boss rat_geant`

---

## Planche DA-03 — Les bas-fonds

| Case | Unité | Rareté | Élément · rôle |
|---|---|---|---|
| 1 | Gobelin Pillard (`gobelin`) | N | Nature · assassin |
| 2 | Loup Gris (`loup_gris`) | N | Nature · guerrier |
| 3 | Zombie Errant (`zombie`) | N | Ténèbres · tank |
| 4 | Bandit des Routes (`bandit`) | N | Nature · assassin |
| 5 | Araignée Venimeuse (`araignee_venin`) | N | Nature · mage |
| 6 | Chauve-Souris Nocturne (`chauve_souris_vampire`) | N | Ténèbres · assassin |
| 7 | Limace Acide (`limace_acide`) | N | Eau · tank |
| 8 | Corbeau Maudit (`corbeau_maudit`) | N | Ténèbres · tireur |

```
1. un gobelin pillard vert olive, maigre et nerveux, sac de butin sur l'épaule, couteau rouillé entre les dents, en train de s'enfuir en courant sur la pointe des pieds
2. un grand loup gris au pelage hirsute, crocs découverts, oreilles couchées, tête basse prête à bondir, souffle visible dans l'air froid
3. un zombie errant au visage gris et aux vêtements de paysan en lambeaux, un bras tendu en avant, la tête penchée sur le côté, démarche traînante
4. un bandit des routes humain au foulard rouge sur le bas du visage, chapeau à large bord, cape brune, il fait tourner un poignard entre ses doigts avec un clin d'œil
5. une araignée venimeuse de la taille d'un loup, abdomen noir à motifs verts brillants, crochets dégoulinants de venin vert, suspendue à un fil la tête en bas
6. une chauve-souris géante aux ailes déployées, fourrure noire et membranes pourpres, petits crocs, grandes oreilles, suspendue la tête en bas, regard rouge malicieux
7. une grosse limace translucide bleu-vert, de la taille d'un tonneau, deux yeux au bout des antennes, on voit des os et une vieille épée flotter dans son corps
8. un grand corbeau noir aux plumes ébouriffées, trois yeux rouges, perché sur un crâne, bec ouvert en train de croasser, plumes qui tombent comme de la cendre
```

Commandes (je m'en occupe) :
`python3 outils/decouper_planche.py da_03_portraits.png gobelin loup_gris zombie bandit araignee_venin chauve_souris_vampire limace_acide corbeau_maudit`
`python3 outils/decouper_miniatures.py da_03_figurines.png --figurines gobelin loup_gris zombie bandit araignee_venin chauve_souris_vampire limace_acide corbeau_maudit`

---

## Planche DA-04 — Les sauvages

| Case | Unité | Rareté | Élément · rôle |
|---|---|---|---|
| 1 | Sanglier Sauvage (`sanglier_sauvage`) | N | Feu · guerrier |
| 2 | Brigand Ivre (`brigand`) | N | Nature · guerrier |
| 3 | Slime Gélatineux (`slime`) | N | Eau · soutien |
| 4 | Hyène des Sables (`hyene_des_sables`) | N | Feu · assassin |
| 5 | Serpent Cracheur (`serpent_crache`) | N | Eau · tireur |
| 6 | Moine Déchu (`moine_dechu`) | N | Ténèbres · soutien |
| 7 | Vautour Charognard (`vautour_charognard`) | N | Nature · tireur |
| 8 | Esprit Frappeur (`esprit_frappeur`) | N | Ténèbres · mage |

```
1. un sanglier massif au poil roux hérissé, défenses énormes, sabots qui grattent le sol, braises qui couvent dans sa crinière, prêt à charger
2. un brigand humain ventru et hilare, joues rouges, chope de bière dans une main et gourdin clouté dans l'autre, ceinture débordante, il titube
3. une créature gélatineuse bleu turquoise toute ronde et brillante, deux grands yeux naïfs et un petit sourire, des bulles à l'intérieur, une petite fleur posée sur sa tête
4. une hyène au pelage sable tacheté, rictus moqueur plein de dents, foulard rouge noué au cou, en train de rire la tête renversée
5. un grand serpent aux écailles bleu nuit et turquoise, capuchon déployé comme un cobra, gueule ouverte qui crache un jet d'eau acide
6. un moine humain chauve à la robe brune déchirée, chapelet de crânes, yeux cernés de noir, il récite une prière interdite d'un livre attaché par une chaîne
7. un vautour énorme au cou déplumé, plumes brunes miteuses, perché sur une épée plantée dans le sol, ailes à moitié ouvertes, regard patient
8. un petit fantôme blanc translucide et espiègle, forme de drap flottant, deux yeux noirs ronds, il fait voler des assiettes et des chandeliers autour de lui en riant
```

Commandes (je m'en occupe) :
`python3 outils/decouper_planche.py da_04_portraits.png sanglier_sauvage brigand slime hyene_des_sables serpent_crache moine_dechu vautour_charognard esprit_frappeur`
`python3 outils/decouper_miniatures.py da_04_figurines.png --figurines sanglier_sauvage brigand slime hyene_des_sables serpent_crache moine_dechu vautour_charognard esprit_frappeur`

---

## Planche DA-05 — Les guerriers des terres

| Case | Unité | Rareté | Élément · rôle |
|---|---|---|---|
| 1 | Orc Guerrier (`orc_guerrier`) | R | Feu · guerrier |
| 2 | Loup-Garou (`loup_garou`) | R | Feu · assassin |
| 3 | Spectre Glacial (`spectre_glacial`) | R | Eau · mage |
| 4 | Golem de Pierre (`golem_pierre`) | R | Sacré · tank |
| 5 | Harpie Hurlante (`harpie`) | R | Nature · tireur |
| 6 | Chevalier Rouillé (`chevalier_rouille`) | R | Ténèbres · tank |
| 7 | Sorcière des Bois (`sorciere_bois`) | R | Nature · soutien |
| 8 | Troll des Marais (`troll_marais`) | R | Eau · tank |

```
1. un orc massif à la peau vert-gris, défenses inférieures, armure de cuir et de fer, hache double sur l'épaule, peintures de guerre rouges, il hurle un cri de guerre
2. un loup-garou dressé sur ses pattes arrière, fourrure noire et rousse, lambeaux de chemise sur le dos, griffes tendues, il hurle à la lune
3. un spectre féminin de glace aux longs cheveux blancs flottants, robe en lambeaux de givre, visage triste, ses mains tendues font naître des cristaux de glace
4. un golem de pierre claire couvert de runes dorées gravées, bras massifs, mousse sur les épaules, un petit oiseau posé sur sa tête qu'il regarde avec douceur
5. une harpie aux ailes de plumes grises et aux serres d'aigle, cheveux sauvages noirs, bouche grande ouverte en un hurlement strident, en plein vol
6. un chevalier hanté dans une armure entièrement rouillée et percée, une faible lueur verte à l'intérieur du heaume vide, bouclier couvert de lierre, il grince en levant son arme
7. une vieille sorcière des bois au nez crochu et au sourire édenté, châle de feuilles mortes, chapeau tordu orné de champignons, elle touille une petite marmite fumante
8. un troll des marais énorme et voûté, peau verdâtre couverte d'algues, gros nez, bras qui touchent le sol, massue faite d'un tronc d'arbre, un poisson qui dépasse de sa bouche
```

Commandes (je m'en occupe) :
`python3 outils/decouper_planche.py da_05_portraits.png orc_guerrier loup_garou spectre_glacial golem_pierre harpie chevalier_rouille sorciere_bois troll_marais`
`python3 outils/decouper_miniatures.py da_05_figurines.png --figurines orc_guerrier loup_garou spectre_glacial golem_pierre harpie chevalier_rouille sorciere_bois troll_marais`

---

## Planche DA-06 — Les créatures des ruines

| Case | Unité | Rareté | Élément · rôle |
|---|---|---|---|
| 1 | Gargouille Ailée (`gargouille`) | R | Eau · tank |
| 2 | Assassin de l'Ombre (`assassin_ombre`) | R | Ténèbres · assassin |
| 3 | Cyclope Borgne (`cyclope`) | R | Feu · guerrier |
| 4 | Jeune Minotaure (`minotaure_jeune`) | R | Feu · guerrier |
| 5 | Banshee Pleureuse (`banshee`) | R | Eau · mage |
| 6 | Centaure Guerrier (`centaure_guerrier`) | R | Feu · tireur |
| 7 | Golem d'Obsidienne (`golem_obsidienne`) | SR | Ténèbres · tank |
| 8 | Liche Mineure (`liche_mineure`) | SR | Ténèbres · mage |

```
1. une gargouille de pierre grise aux ailes de chauve-souris, accroupie sur une corniche, langue tirée en grimace, des gouttes d'eau qui coulent de sa gueule
2. un assassin humain tout en noir, capuche profonde et masque de tissu, seuls ses yeux sont visibles, il sort d'un nuage de fumée, deux lames courtes à la main
3. un cyclope géant au crâne rasé, un seul grand œil, pagne de peau, énorme marteau de pierre, il plisse son œil unique pour viser
4. un jeune minotaure aux cornes encore courtes, pelage brun, anneau dans le museau, hache trop grande pour lui, regard fier et un peu maladroit
5. une banshee éthérée bleu pâle aux cheveux qui flottent comme sous l'eau, robe déchirée, bouche ouverte en un cri déchirant, larmes lumineuses qui coulent
6. un centaure guerrier au torse puissant et à la robe de cheval baie, armure de cuir, cheveux attachés, il bande un grand arc en se cabrant
7. un golem d'obsidienne noire et luisante aux arêtes tranchantes, fissures violettes qui pulsent, poings en forme de masses, posture de garde immobile
8. une liche décharnée en robe pourpre délavée, couronne de fer tordue, phylactère vert qui brille sur sa poitrine, elle lit un parchemin qui se consume
```

Commandes (je m'en occupe) :
`python3 outils/decouper_planche.py da_06_portraits.png gargouille assassin_ombre cyclope minotaure_jeune banshee centaure_guerrier golem_obsidienne liche_mineure`
`python3 outils/decouper_miniatures.py da_06_figurines.png --figurines gargouille assassin_ombre cyclope minotaure_jeune banshee centaure_guerrier golem_obsidienne liche_mineure`

---

## Planche DA-07 — Les puissants

| Case | Unité | Rareté | Élément · rôle |
|---|---|---|---|
| 1 | Chimère Enragée (`chimere`) | SR | Nature · guerrier |
| 2 | Séraphin Déchu (`seraphin_dechu`) | SR | Ténèbres · mage |
| 3 | Jeune Hydre (`hydre_jeune`) | SR | Eau · tank |
| 4 | Démon de Flamme (`demon_flamme`) | SR | Feu · mage |
| 5 | Reine Araignée (`reine_araignee`) | SR | Nature · assassin |
| 6 | Wyverne Sauvage (`wyverne`) | SR | Nature · tireur |
| 7 | Lapin Pyromane (`lapin_pyromane`) | SR | Feu · assassin |
| 8 | Dragon d'Ombre (`dragon_ombre`) | SSR | Ténèbres · mage |

```
1. une chimère féroce à tête de lion, une tête de chèvre sur le dos et une queue de serpent, crinière fauve, rugissement, griffes plantées dans le sol
2. un séraphin déchu aux six ailes noires effilochées, armure blanche ternie et fendue, auréole brisée qui flotte de travers, regard triste et sombre
3. une jeune hydre aux trois têtes curieuses et chamailleuses, écailles bleu-vert, l'une mord la corne de l'autre pendant que la troisième regarde le spectateur
4. un démon entièrement fait de flammes orange et de charbon, silhouette humanoïde, yeux blancs, il tient une boule de feu au-dessus de sa tête
5. une reine araignée au buste de femme pâle et au corps d'araignée noire géante, couronne d'os, longs cheveux noirs, toiles derrière elle, sourire cruel
6. une wyverne sauvage aux écailles vert forêt et ventre crème, ailes membraneuses déchirées, queue à dard, perchée sur un rocher, gueule ouverte
7. UN PERSONNAGE FUN : un petit lapin artificier complètement fou, fourrure blanche roussie et ébouriffée, grosses lunettes d'aviateur sur le front, une oreille à moitié brûlée, sourire jusqu'aux oreilles et yeux pétillants, il brandit une énorme carotte-dynamite à la mèche allumée, bandoulière de pétards et de fusées, de petites étincelles et confettis de feu autour de lui, expression d'une joie destructrice irrésistible
8. un dragon d'ombre noir aux écailles qui se dissolvent en fumée, ailes repliées, yeux violets, il regarde par-dessus son épaule, un souffle de ténèbres entre ses crocs
```

Commandes (je m'en occupe) :
`python3 outils/decouper_planche.py da_07_portraits.png chimere seraphin_dechu hydre_jeune demon_flamme reine_araignee wyverne lapin_pyromane dragon_ombre`
`python3 outils/decouper_miniatures.py da_07_figurines.png --figurines chimere seraphin_dechu hydre_jeune demon_flamme reine_araignee wyverne lapin_pyromane dragon_ombre`

---

## Planche DA-08 — Les héros majeurs

| Case | Unité | Rareté | Élément · rôle |
|---|---|---|---|
| 1 | Archange Noir (`archange_noir`) | SSR | Ténèbres · guerrier |
| 2 | Titan des Abysses (`titan_abysses`) | SSR | Eau · tank |
| 3 | Reine des Liches (`reine_liches`) | SSR | Ténèbres · soutien |
| 4 | Chat des Abysses (`chat_des_abysses`) | SSR | Eau · assassin |
| 5 | Chien Sylvestre (`chien_sylvestre`) | SSR | Nature · soutien |
| 6 | Phénix Immortel (`phenix_immortel`) | UR | Feu · soutien |
| 7 | Léviathan Abyssal (`leviathan_abyssal`) | UR | Eau · tank |
| 8 | Empereur Déchu (`empereur_dechu`) | UR | Ténèbres · guerrier |

```
1. un archange noir en armure d'obsidienne et d'argent, grandes ailes noires déployées, épée flamboyante d'une lumière sombre pointée vers le bas, regard implacable
2. un titan des abysses à la peau bleu sombre couverte de coquillages et de coraux, casque fait d'un crâne de requin, énorme ancre en guise d'arme, posture de rempart
3. une reine des liches élégante et squelettique, robe noire et argent à haut col, couronne d'os et de cristaux bleus, sceptre surmonté d'un crâne, elle tend une main gracieuse
4. un grand chat noir aux reflets bleu nuit, yeux turquoise lumineux, nageoires et branchies sur les flancs, il s'étire paresseusement en sortant ses griffes
5. un grand chien loyal au pelage vert mousse et brun, fleurs et lierre qui poussent sur son dos, collier de racines, assis fièrement, regard bienveillant
6. un phénix immortel majestueux, plumes de feu rouge, or et blanc, longue queue de flammes, ailes grandes ouvertes, il renaît de ses cendres
7. un léviathan abyssal en buste, tête de serpent de mer bleu nuit à crête de nageoires, yeux blancs, il émerge d'une vague sombre, écailles comme une armure
8. un empereur déchu humain d'âge mûr, armure noire et or abîmée, cape pourpre en lambeaux, couronne fendue, assis sur un trône brisé, épée en travers des genoux
```

Commandes (je m'en occupe) :
`python3 outils/decouper_planche.py da_08_portraits.png archange_noir titan_abysses reine_liches chat_des_abysses chien_sylvestre phenix_immortel leviathan_abyssal empereur_dechu`
`python3 outils/decouper_miniatures.py da_08_figurines.png --figurines archange_noir titan_abysses reine_liches chat_des_abysses chien_sylvestre phenix_immortel leviathan_abyssal empereur_dechu`

---

## Planche DA-09 — Le galop et l'Acte I

| Case | Unité | Rareté | Élément · rôle |
|---|---|---|---|
| 1 | Cheval Céleste (`cheval_sacre`) | UR | Sacré · guerrier |
| 2 | Gobelin Maraudeur (`gobelin_maraudeur`) | N | Nature · assassin |
| 3 | Loup Affamé (`loup_affame`) | N | Nature · guerrier |
| 4 | Rat Corrompu (`rat_corrompu`) | N | Ténèbres · mage |
| 5 | Zombie Enragé (`zombie_enrage`) | R | Ténèbres · guerrier |
| 6 | Brigand Cagoulé (`brigand_cagoule`) | R | Nature · assassin |
| 7 | Araignée Géante (`araignee_geante`) | R | Nature · tireur |
| 8 | Golem Fissuré (`golem_fissure`) | SR | Nature · tank |

```
1. un cheval céleste blanc à la crinière d'or lumineuse, caparaçon doré, petites ailes de lumière aux sabots, il se cabre
2. un gobelin maraudeur vert foncé, casque en marmite trop grand, bouclier fait d'un couvercle de tonneau, torche à la main, sourire plein de dents pointues
3. un loup affamé maigre au pelage noir pelé, côtes visibles, bave aux lèvres, yeux jaunes fous, il rôde la tête basse
4. un rat corrompu aux yeux violets lumineux, pelage noir galeux, veines violettes qui pulsent, il tient une petite fiole de poison
5. un zombie enragé au corps musclé et déchiqueté, mâchoire grande ouverte, chaînes brisées aux poignets, il court vers le spectateur
6. un brigand cagoulé tout de gris, cagoule de toile percée de deux trous, arbalète de poing, couteau à la ceinture, accroupi derrière une caisse
7. une araignée géante au corps velu brun-roux, huit yeux rouges, elle tisse une toile entre ses pattes avant, des cocons pendent autour
8. un golem de terre et de roche fissuré, mousse et petites plantes qui poussent dans les fentes, un bras à moitié écroulé, il ramasse une pierre pour se réparer
```

Commandes (je m'en occupe) :
`python3 outils/decouper_planche.py da_09_portraits.png cheval_sacre gobelin_maraudeur loup_affame rat_corrompu zombie_enrage brigand_cagoule araignee_geante golem_fissure`
`python3 outils/decouper_miniatures.py da_09_figurines.png --figurines cheval_sacre gobelin_maraudeur loup_affame rat_corrompu zombie_enrage brigand_cagoule araignee_geante golem_fissure`

---

## Planche DA-10 — Les ennemis des terres sombres

| Case | Unité | Rareté | Élément · rôle |
|---|---|---|---|
| 1 | Harpie Sanglante (`harpie_sanglante`) | SR | Ténèbres · tireur |
| 2 | Ombre Rampante (`ombre_rampante`) | SR | Ténèbres · mage |
| 3 | Spectre Vengeur (`spectre_vengeur`) | SR | Ténèbres · assassin |
| 4 | Troll des Cavernes (`troll_cavernes`) | SR | Eau · tank |
| 5 | Cyclope Furieux (`cyclope_furieux`) | SR | Feu · guerrier |
| 6 | Démon Mineur (`demon_mineur`) | SSR | Feu · mage |
| 7 | Liche Novice (`liche_novice`) | SSR | Ténèbres · soutien |
| 8 | Gargouille de Jade (`gargouille_jade`) | SSR | Sacré · tank |

```
1. une harpie sanglante aux plumes noires et rouges, serres maculées de sang, visage cruel, elle plonge en piqué ailes repliées
2. une ombre rampante sans visage, masse de ténèbres humanoïde qui rampe au sol, longs doigts griffus, deux yeux blancs, elle se détache d'un mur
3. un spectre vengeur en armure fantôme bleu pâle, visage hurlant, chaînes spectrales, épée fantomatique levée pour frapper
4. un troll des cavernes à la peau grise de pierre, stalactites sur le dos, petits yeux plissés, il porte une énorme stalagmite comme massue
5. un cyclope furieux couvert de peintures de guerre rouges, œil injecté de sang, chaînes aux poignets, il arrache un rocher du sol
6. un démon mineur aux ailes de chauve-souris, peau rouge sombre, queue fourchue, il ricane en lançant une boule de feu d'une main
7. un jeune nécromancien squelettique en robe noire trop neuve, livre de magie noire ouvert, il hésite en lisant un sort, des os s'assemblent maladroitement à ses pieds
8. une gargouille de jade vert sculpté, ailes déployées, posture de gardien sur un socle de temple, yeux dorés, petites fissures
```

Commandes (je m'en occupe) :
`python3 outils/decouper_planche.py da_10_portraits.png harpie_sanglante ombre_rampante spectre_vengeur troll_cavernes cyclope_furieux demon_mineur liche_novice gargouille_jade`
`python3 outils/decouper_miniatures.py da_10_figurines.png --figurines harpie_sanglante ombre_rampante spectre_vengeur troll_cavernes cyclope_furieux demon_mineur liche_novice gargouille_jade`

---

## Planche DA-11 — Les seigneurs de l'Acte I à IV

| Case | Unité | Rareté | Élément · rôle |
|---|---|---|---|
| 1 | Chevalier Déchu (`chevalier_dechu`) | SSR | Ténèbres · guerrier |
| 2 | Hydre Bicéphale (`hydre_bicephale`) | SSR | Eau · tank |
| 3 | Vouivre Écarlate (`vouivre_ecarlate`) | SSR | Feu · mage |
| 4 | Gardien de la Forêt Maudite (`gardien_foret`) | SR | Sacré · tank |
| 5 | Seigneur du Donjon Maudit (`seigneur_donjon`) | SSR | Ténèbres · guerrier |
| 6 | Seigneur des Cendres (`seigneur_des_cendres`) | SSR | Ténèbres · mage |
| 7 | Pillard Incendiaire (`pillard_incendiaire`) | N | Feu · guerrier |
| 8 | Patrouilleur Vautour (`patrouilleur_vautour`) | N | Nature · tireur |

```
1. un chevalier déchu en armure noire et violette cabossée, cape déchirée, épée brisée à moitié, il se relève un genou à terre, regard plein de rancune
2. une hydre à deux têtes aux écailles bleu nuit, les deux gueules ouvertes dans des directions opposées, eau qui ruisselle de ses crocs
3. une vouivre écarlate, dragon serpentin aux écailles rouge vif et dorées, une gemme rouge sur le front, elle s'enroule sur elle-même en crachant des braises
4. le gardien de la forêt maudite, un ent massif au tronc noueux et noir, yeux verts, ronces et champignons sur les épaules, il bloque le passage les bras écartés
5. le seigneur du donjon maudit, un roi-squelette géant couronné dans une armure antique rouillée, lueur verte spectrale, grande épée plantée devant lui sur son trône
6. le seigneur des cendres, un seigneur en armure noire calcinée couronnée de flammes, cape de fumée, visage caché par un heaume fendu d'où sortent des braises
7. un pillard humain hirsute avec une torche dans chaque main, visage noirci de suie, vêtements roussis, rire dément
8. un éclaireur humain au masque de bec de vautour, plumes noires sur les épaules, arbalète, il scrute l'horizon accroupi sur un rocher
```

Commandes (je m'en occupe) :
`python3 outils/decouper_planche.py da_11_portraits.png chevalier_dechu hydre_bicephale vouivre_ecarlate gardien_foret seigneur_donjon seigneur_des_cendres pillard_incendiaire patrouilleur_vautour`
`python3 outils/decouper_miniatures.py da_11_figurines.png --figurines chevalier_dechu hydre_bicephale vouivre_ecarlate gardien_foret seigneur_donjon seigneur_des_cendres pillard_incendiaire patrouilleur_vautour`

---

## Planche DA-12 — La Cité en Deuil

| Case | Unité | Rareté | Élément · rôle |
|---|---|---|---|
| 1 | Profanateur de Tombes (`profanateur_tombes`) | N | Ténèbres · mage |
| 2 | Pestiféré Errant (`pestifere_errant`) | N | Nature · tank |
| 3 | Porteur de Lanterne Noire (`porteur_lanterne`) | R | Ténèbres · mage |
| 4 | Souvenir Spectral (`souvenir_spectral`) | R | Eau · assassin |
| 5 | La Veuve aux Lanternes (`veuve_lanternes`) | SR | Eau · mage |
| 6 | Mercenaire Balafré (`mercenaire_balafre`) | R | Feu · guerrier |
| 7 | Arbalétrier Noir (`arbaletrier_noir`) | R | Ténèbres · tireur |
| 8 | Receleur de l'Ombre (`receleur_ombre`) | R | Nature · assassin |

```
1. un profanateur de tombes humain voûté, pelle sur l'épaule, lanterne à la ceinture, sac rempli de bijoux volés, sourire avide
2. un pestiféré errant enveloppé de bandages sales, masque de médecin de peste à long bec, canne, mouches autour de lui
3. un porteur de lanterne noire, grande silhouette encapuchonnée sans visage, une lanterne de fer à flamme bleu pâle tenue devant lui
4. un souvenir spectral, enfant fantôme translucide aux contours flous, tenant un jouet de bois, regard perdu, bord du corps qui s'effiloche en brume bleue
5. la Veuve aux Lanternes, grande femme voilée de dentelle noire, robe de deuil, une dizaine de lanternes funéraires bleu pâle qui flottent autour d'elle
6. un mercenaire humain balafré à la barbe rousse, armure de cuir dépareillée, épée bâtarde sur l'épaule, il compte des pièces d'or dans sa paume
7. un arbalétrier en armure noire, casque à visière fermée, lourde arbalète de siège appuyée contre l'épaule, carreaux à la ceinture
8. un receleur humain louche au long manteau garni de poches, il ouvre un pan de manteau pour montrer des dagues et des bijoux volés, sourire en coin
```

Commandes (je m'en occupe) :
`python3 outils/decouper_planche.py da_12_portraits.png profanateur_tombes pestifere_errant porteur_lanterne souvenir_spectral veuve_lanternes mercenaire_balafre arbaletrier_noir receleur_ombre`
`python3 outils/decouper_miniatures.py da_12_figurines.png --figurines profanateur_tombes pestifere_errant porteur_lanterne souvenir_spectral veuve_lanternes mercenaire_balafre arbaletrier_noir receleur_ombre`

---

## Planche DA-13 — Le Drapeau Noir et le Sépulcre

| Case | Unité | Rareté | Élément · rôle |
|---|---|---|---|
| 1 | Capitaine au Drapeau Noir (`capitaine_drapeau_noir`) | SR | Feu · guerrier |
| 2 | Garde d'Os (`garde_os`) | R | Ténèbres · tank |
| 3 | Prêtre de l'Autel (`pretre_autel`) | SR | Ténèbres · soutien |
| 4 | Mirage des Vaincus (`mirage_vaincu`) | SR | Sacré · mage |
| 5 | Zélote Fanatique (`fanatique_zelote`) | R | Sacré · guerrier |
| 6 | L'Inquisiteur Implacable (`inquisiteur_implacable`) | SSR | Sacré · guerrier |
| 7 | Statue Hurlante (`statue_hurlante`) | SR | Sacré · tank |
| 8 | Aberration Cristalline (`aberration_cristal`) | SR | Eau · assassin |

```
1. le Capitaine au Drapeau Noir, un capitaine mercenaire massif en armure lourde, cape noire, hache de guerre levée, un drapeau noir déchiré planté derrière lui
2. un garde d'os, squelette massif en armure de fer antique, hallebarde, bouclier gravé d'une couronne, il monte la garde immobile
3. un prêtre de l'autel des sacrifices, robe rouge sombre, masque doré sans expression, dague rituelle levée au-dessus d'un autel
4. un mirage des vaincus, silhouette de soldat faite de lumière dorée tremblante comme une chaleur de désert, à moitié transparente, il tend la main
5. un zélote fanatique au crâne rasé, robe blanche tachée, fouet dans une main et livre sacré dans l'autre, regard exalté
6. l'Inquisiteur Implacable, en robe pourpre et masque de fer, étendard sacré dans une main et lanterne dans l'autre, des bûchers derrière lui
7. une statue hurlante, un voyageur figé dans la pierre grise, bouche grande ouverte et mains sur le visage, des fissures lumineuses qui s'ouvrent
8. une aberration cristalline, créature à quatre pattes faite de cristaux violets et bleus tranchants, sans visage, lueur intérieure qui pulse
```

Commandes (je m'en occupe) :
`python3 outils/decouper_planche.py da_13_portraits.png capitaine_drapeau_noir garde_os pretre_autel mirage_vaincu fanatique_zelote inquisiteur_implacable statue_hurlante aberration_cristal`
`python3 outils/decouper_miniatures.py da_13_figurines.png --figurines capitaine_drapeau_noir garde_os pretre_autel mirage_vaincu fanatique_zelote inquisiteur_implacable statue_hurlante aberration_cristal`

---

## Planche DA-14 — Les marais et l'Éclipse

| Case | Unité | Rareté | Élément · rôle |
|---|---|---|---|
| 1 | Le Reflet de l'Âme (`reflet_ame`) | SSR | Ténèbres · assassin |
| 2 | Liane Vénéneuse (`liane_venimeuse`) | SR | Nature · mage |
| 3 | Bête des Tourbières (`bete_tourbieres`) | SR | Eau · tank |
| 4 | La Dame des Ronciers (`dame_ronciers`) | SSR | Nature · mage |
| 5 | Rôdeur de l'Éclipse (`rodeur_eclipse`) | SSR | Ténèbres · assassin |
| 6 | Démon de Siège (`demon_siege`) | SSR | Feu · tank |
| 7 | Avatar de l'Éclipse (`avatar_eclipse`) | SSR | Ténèbres · mage |
| 8 | Champion Déchu (`champion_dechu`) | SSR | Sacré · guerrier |

```
1. le Reflet de l'Âme, une silhouette sombre et inversée faite d'eau noire comme un miroir, yeux luisants, elle sort d'un lac de verre noir et imite la pose du spectateur
2. une liane vénéneuse, plante carnivore géante avec une grande fleur violette à crocs et des lianes épineuses qui se tordent
3. une bête des tourbières, masse de boue, de racines et de mousse en forme d'ours, deux yeux jaunes, des grenouilles sur son dos
4. la Dame des Ronciers, une sorcière-reine couronnée d'épines et de roses noires, robe faite de ronces, assise sur un trône de ronces au-dessus de l'eau
5. un rôdeur de l'éclipse, assassin à la cape noire bordée de rouge, masque en forme de soleil noir, deux faucilles, lumière rouge derrière lui
6. un démon de siège colossal à quatre bras, armure de plaques soudées, un bélier de fer accroché à son dos, il défonce une porte de château
7. l'Avatar de l'Éclipse, créature ailée faite d'ombre et de lumière rouge, un soleil noir couronné de rouge à la place du visage
8. un champion déchu en armure dorée ternie et fendue, cape de héros en lambeaux, lance brisée, regard perdu d'un héros oublié
```

Commandes (je m'en occupe) :
`python3 outils/decouper_planche.py da_14_portraits.png reflet_ame liane_venimeuse bete_tourbieres dame_ronciers rodeur_eclipse demon_siege avatar_eclipse champion_dechu`
`python3 outils/decouper_miniatures.py da_14_figurines.png --figurines reflet_ame liane_venimeuse bete_tourbieres dame_ronciers rodeur_eclipse demon_siege avatar_eclipse champion_dechu`

---

## Planche DA-15 — Le Val et la Citadelle

| Case | Unité | Rareté | Élément · rôle |
|---|---|---|---|
| 1 | Pilleur de Tombes Royales (`pilleur_royal`) | SR | Ténèbres · assassin |
| 2 | L'Ombre du Premier Roi (`ombre_premier_roi`) | SSR | Ténèbres · tank |
| 3 | Tortionnaire (`tortionnaire`) | SSR | Ténèbres · guerrier |
| 4 | Abomination de Laboratoire (`abomination`) | SSR | Nature · tank |
| 5 | Le Maître des Supplices (`maitre_supplices`) | SSR | Feu · mage |
| 6 | Garde Fratricide (`garde_fratricide`) | SSR | Ténèbres · tank |
| 7 | Compagnon Traître (`compagnon_traitre`) | SSR | Feu · assassin |
| 8 | Le Frère Masqué (`frere_masque`) | SSR | Ténèbres · guerrier |

```
1. un pilleur de tombes royales, voleur agile à la capuche et à la cape couleur sable, il soulève une couronne d'or ancienne avec un sourire triomphant
2. l'Ombre du Premier Roi, un roi antique spectral géant fait d'ombre et de lumière dorée pâle, couronne et cape déchirée, il pose une main sur son épée
3. un tortionnaire massif au tablier de cuir taché, cagoule de bourreau, pince et chaîne à la main, crochets à la ceinture
4. une abomination de laboratoire, créature cousue de morceaux de chair et de métal, tubes et bocaux attachés au dos, un œil mécanique
5. le Maître des Supplices, bourreau colossal masqué de fer, longues chaînes qui pendent de ses bras, il tient une cage suspendue
6. un garde fratricide en armure noire et rouge, casque à double visage (un qui rit, un qui pleure), grand bouclier fendu en deux
7. un compagnon traître, jeune homme souriant en tenue d'aventurier, une main tendue amicale et l'autre cachant une dague brûlante dans son dos
8. le Frère Masqué, guerrier en armure sombre aux reflets rouges, masque noir lisse, flamme noire qui s'enroule autour de son épée
```

Commandes (je m'en occupe) :
`python3 outils/decouper_planche.py da_15_portraits.png pilleur_royal ombre_premier_roi tortionnaire abomination maitre_supplices garde_fratricide compagnon_traitre frere_masque`
`python3 outils/decouper_miniatures.py da_15_figurines.png --figurines pilleur_royal ombre_premier_roi tortionnaire abomination maitre_supplices garde_fratricide compagnon_traitre frere_masque`

---

## Planche DA-16 — Le Trône de Cendres et les Enfers

| Case | Unité | Rareté | Élément · rôle |
|---|---|---|---|
| 1 | Garde des Cendres Éternelles (`garde_cendres`) | SSR | Sacré · tank |
| 2 | Héraut de l'Apocalypse (`heraut_apocalypse`) | SSR | Feu · mage |
| 3 | L'Héritier Maudit (`heritier_maudit`) | UR | Ténèbres · guerrier |
| 4 | Diablotin de Soufre (`diablotin_soufre`) | N | Feu · assassin |
| 5 | Âme Damnée (`ame_damnee`) | N | Ténèbres · mage |
| 6 | Molosse des Enfers (`molosse_enfers`) | R | Feu · guerrier |
| 7 | Passeur du Fleuve Rouge (`passeur_styx`) | R | Eau · soutien |
| 8 | Bourreau Cornu (`bourreau_cornu`) | SR | Feu · guerrier |

```
1. un garde des cendres éternelles, armure dorée recouverte de cendres grises, hallebarde, cape qui se désagrège en cendres
2. un héraut de l'apocalypse, cavalier spectral sans monture, trompe d'os dans une main, robe noire et rouge qui brûle par le bas
3. l'Héritier Maudit, jeune roi couronné au visage pâle et déformé, armure noire et or, une ombre monstrueuse qui grandit derrière lui
4. un petit diablotin de soufre jaune et orange, grosses cornes, ailes minuscules, il souffle sur une allumette géante en ricanant
5. une âme damnée, silhouette translucide grise qui tend les bras vers le haut, chaînes de feu aux poignets, visage implorant
6. un molosse des enfers, chien noir massif à la peau craquelée de lave, collier à pointes, gueule pleine de braises
7. le passeur du fleuve rouge, silhouette encapuchonnée squelettique debout dans une barque, longue rame, lanterne verte à la proue
8. un bourreau cornu, démon musclé aux grandes cornes de bélier, cagoule noire, énorme hache à deux mains posée sur l'épaule
```

Commandes (je m'en occupe) :
`python3 outils/decouper_planche.py da_16_portraits.png garde_cendres heraut_apocalypse heritier_maudit diablotin_soufre ame_damnee molosse_enfers passeur_styx bourreau_cornu`
`python3 outils/decouper_miniatures.py da_16_figurines.png --figurines garde_cendres heraut_apocalypse heritier_maudit diablotin_soufre ame_damnee molosse_enfers passeur_styx bourreau_cornu`

---

## Planche DA-17 — La Tour de l'Enfer (1)

| Case | Unité | Rareté | Élément · rôle |
|---|---|---|---|
| 1 | Sangsue Abyssale (`sangsue_abyssale`) | SR | Eau · tank |
| 2 | Forgeron de l'Abîme (`forgeron_abime`) | SR | Feu · tank |
| 3 | Succube Tentatrice (`succube`) | SSR | Ténèbres · mage |
| 4 | Cerbère (`cerbere`) | SSR | Feu · assassin |
| 5 | Chevalier Infernal (`chevalier_infernal`) | SSR | Ténèbres · guerrier |
| 6 | Archidémon du Néant (`archidemon`) | UR | Feu · mage |
| 7 | Tourmenteur des Âmes (`tourmenteur_ames`) | UR | Ténèbres · assassin |
| 8 | Gardien des Portes de Soufre (`gardien_soufre`) | SR | Feu · tank |

```
1. une sangsue abyssale géante, corps annelé noir et rouge, bouche ronde pleine de dents en cercle, elle se dresse comme un serpent
2. un forgeron de l'abîme, démon trapu aux bras énormes, tablier de cuir, marteau rougeoyant, il frappe une lame sur une enclume de lave
3. une succube tentatrice aux cheveux noirs, cornes fines, ailes de chauve-souris, robe pourpre élégante et couverte, sourire charmeur, un doigt sur les lèvres
4. un cerbère, chien des enfers à trois têtes au pelage noir, chaque tête avec une expression différente (furieuse, rieuse, endormie), collier de chaînes
5. un chevalier infernal en armure noire hérissée de pointes, heaume à cornes, épée de flammes noires, monture absente, il marche à travers les flammes
6. un archidémon du néant immense, silhouette ailée faite de vide étoilé et de flammes rouges, plusieurs paires d'yeux, couronne de cornes
7. un tourmenteur des âmes, démon maigre aux longs doigts griffus, il tire des chaînes au bout desquelles flottent des âmes grises
8. le gardien des portes de soufre, colosse de roche jaune soufre et de lave, deux portes de fer incrustées dans ses bras comme des boucliers
```

Commandes (je m'en occupe) :
`python3 outils/decouper_planche.py da_17_portraits.png sangsue_abyssale forgeron_abime succube cerbere chevalier_infernal archidemon tourmenteur_ames gardien_soufre`
`python3 outils/decouper_miniatures.py da_17_figurines.png --figurines sangsue_abyssale forgeron_abime succube cerbere chevalier_infernal archidemon tourmenteur_ames gardien_soufre`

---

## Planche DA-18 — La Tour de l'Enfer (2)

| Case | Unité | Rareté | Élément · rôle |
|---|---|---|---|
| 1 | Avarex, Prince de l'Avidité (`avarex`) | SR | Ténèbres · mage |
| 2 | Nautre, Nocher du Fleuve Rouge (`nocher_rouge`) | SSR | Eau · guerrier |
| 3 | Vorhka, Mère des Tourments (`vorhka`) | SSR | Nature · assassin |
| 4 | Le Grand Forgeron Infernal (`grand_forgeron`) | SSR | Feu · tank |
| 5 | Lilithra, Reine des Succubes (`lilithra`) | SSR | Ténèbres · mage |
| 6 | Cerbérus Tricéphale (`cerberus`) | UR | Feu · assassin |
| 7 | Baal'Zeth, Général des Légions (`baalzeth`) | UR | Ténèbres · guerrier |
| 8 | L'Archidiable Écarlate (`archidiable`) | UR | Feu · mage |

```
1. Avarex, démon de l'avarice, gros démon couvert de bijoux et de chaînes en or, il est assis sur un tas de pièces maudites qui fument
2. Nautre, le nocher du fleuve rouge, grand guerrier squelettique en armure de givre, rame-hallebarde à la lame de glace
3. Vorhka, reine-insecte pestilentielle, corps de guêpe géante noire et verte, dards dégoulinants, essaim de larves autour d'elle
4. le Grand Forgeron Infernal, colosse de métal noir et de lave, un marteau-enclume immense, des chaînes rougeoyantes autour du corps
5. Lilithra, reine des succubes, longue robe noire et rouge à traîne, couronne de cornes d'argent, grandes ailes, regard envoûtant, assise avec grâce
6. Cerbérus Tricéphale, gigantesque chien des enfers à trois têtes enflammées, armure de fer, chaînes brisées, les trois gueules hurlent ensemble
7. Baal'Zeth, général démon en armure de commandant noire et rouge, cape de flammes, épée du néant, il pointe ses légions du doigt
8. l'Archidiable Écarlate, démon élégant au visage aristocratique, peau rouge, cornes recourbées, costume de noble en écailles, il sourit en faisant apparaître des flammes dans sa paume
```

Commandes (je m'en occupe) :
`python3 outils/decouper_planche.py da_18_portraits.png avarex nocher_rouge vorhka grand_forgeron lilithra cerberus baalzeth archidiable`
`python3 outils/decouper_miniatures.py da_18_figurines.png --figurines avarex nocher_rouge vorhka grand_forgeron lilithra cerberus baalzeth archidiable`

---

## Planche DA-19 — Les Neuf Cercles et le Ciel

| Case | Unité | Rareté | Élément · rôle |
|---|---|---|---|
| 1 | Abaddor, le Diable Primordial (`abaddor`) | UR | Ténèbres · guerrier |
| 2 | Chérubin Espiègle (`cherubin`) | N | Sacré · soutien |
| 3 | Faucon Céleste (`faucon_celeste`) | N | Sacré · tireur |
| 4 | Nuée Vivante (`nuee_vivante`) | R | Eau · mage |
| 5 | Gardien d'Albâtre (`gardien_albatre`) | R | Sacré · tank |
| 6 | Archer des Cieux (`archer_cieux`) | SR | Sacré · tireur |
| 7 | Prêtresse de l'Aube (`pretresse_aube`) | SR | Sacré · soutien |
| 8 | Séraphin Ardent (`seraphin_ardent`) | SSR | Feu · mage |

```
1. Abaddor, seigneur des neuf cercles, roi-démon colossal assis sur un trône de chaînes, couronne de cornes, regard éternel et las
2. un chérubin espiègle, petit ange joufflu aux ailes blanches duveteuses, boucles dorées, arc miniature, il tire la langue en visant
3. un faucon céleste au plumage blanc et or, ailes déployées en plein vol, serres dorées, petites étoiles dans le sillage de ses ailes
4. une nuée vivante, nuage gris-bleu avec un visage boudeur, des gouttes de pluie et des flocons qui tombent, de petits éclairs dans ses joues
5. un gardien d'albâtre, statue vivante de marbre blanc veiné d'or, bouclier rond et lance, visage serein sans pupilles
6. un archer des cieux, ange guerrier aux ailes blanches, armure légère dorée, il décoche une flèche de lumière vers le haut
7. une prêtresse de l'aube, longue robe blanche et rose pâle, voile léger, elle lève un bâton surmonté d'un soleil levant
8. un séraphin ardent aux six ailes de flammes dorées, visage voilé de lumière, armure blanche, il tient une épée de feu
```

Commandes (je m'en occupe) :
`python3 outils/decouper_planche.py da_19_portraits.png abaddor cherubin faucon_celeste nuee_vivante gardien_albatre archer_cieux pretresse_aube seraphin_ardent`
`python3 outils/decouper_miniatures.py da_19_figurines.png --figurines abaddor cherubin faucon_celeste nuee_vivante gardien_albatre archer_cieux pretresse_aube seraphin_ardent`

---

## Planche DA-20 — La Tour du Paradis (1)

| Case | Unité | Rareté | Élément · rôle |
|---|---|---|---|
| 1 | Valkyrie Céleste (`valkyrie_celeste`) | SSR | Sacré · guerrier |
| 2 | Dominion Couronné (`dominion`) | SSR | Eau · soutien |
| 3 | Trône Vivant (`trone_vivant`) | SSR | Sacré · tank |
| 4 | Archange Justicier (`archange_justicier`) | UR | Sacré · assassin |
| 5 | Puissance Céleste (`puissance_celeste`) | UR | Nature · guerrier |
| 6 | Gardien des Nuées (`gardien_nuees`) | SR | Eau · tank |
| 7 | Aethel, Héraut Doré (`aethel`) | SR | Sacré · tireur |
| 8 | La Dame d'Albâtre (`dame_albatre`) | SSR | Sacré · mage |

```
1. une valkyrie céleste, guerrière aux tresses blondes, armure argentée ailée, lance et bouclier, elle descend du ciel les ailes ouvertes
2. un dominion couronné, ange majestueux aux ailes bleu pâle, couronne de lumière, sceptre et orbe d'eau qui tourne lentement
3. un trône vivant, roue céleste dorée couverte d'yeux bienveillants, entourée d'anneaux de lumière tournant les uns dans les autres
4. un archange justicier, guerrier ailé en armure blanche et or, balance dans une main et glaive de lumière dans l'autre, regard sévère
5. une puissance céleste, ange robuste à l'armure de feuillages dorés, ailes vert pâle, glaive végétal, couronne de laurier
6. le gardien des nuées, géant de nuages et de pluie, armure de grêle, deux tornades à la place des bras
7. Aethel, archère de l'aube, ange aux cheveux roux lumineux, trompe de chasse à la ceinture, elle tend un long arc de lumière
8. la Dame d'Albâtre, magicienne céleste à la peau de marbre blanc, longue robe immaculée, couronne de cristal, elle prie les mains jointes
```

Commandes (je m'en occupe) :
`python3 outils/decouper_planche.py da_20_portraits.png valkyrie_celeste dominion trone_vivant archange_justicier puissance_celeste gardien_nuees aethel dame_albatre`
`python3 outils/decouper_miniatures.py da_20_figurines.png --figurines valkyrie_celeste dominion trone_vivant archange_justicier puissance_celeste gardien_nuees aethel dame_albatre`

---

## Planche DA-21 — La Tour du Paradis (2)

| Case | Unité | Rareté | Élément · rôle |
|---|---|---|---|
| 1 | Oriel, Lame de l'Aube (`oriel`) | SSR | Sacré · guerrier |
| 2 | Le Chœur Incarné (`choeur_incarne`) | SSR | Eau · mage |
| 3 | Ophanim, la Roue Ardente (`ophanim`) | SSR | Feu · tank |
| 4 | Valkaria, Reine des Valkyries (`valkaria`) | UR | Sacré · guerrier |
| 5 | Sérapheon, Flamme Divine (`serapheon`) | UR | Feu · mage |
| 6 | Azarel, Archange du Jugement (`azarel`) | UR | Sacré · assassin |
| 7 | Aurelys, la Lumière Primordiale (`aurelys`) | UR | Sacré · mage |
| 8 | Belzaroth, Prince des Braises (`belzaroth`) | SSR | Feu · guerrier |

```
1. Oriel, chevalier de l'aube, armure dorée étincelante, ailes orangées, lance de lumière levée au-dessus de sa tête
2. le Chœur Incarné, trois visages d'anges fondus en une seule silhouette lumineuse bleu pâle, bouches ouvertes en train de chanter
3. Ophanim, être céleste fait de roues de feu imbriquées les unes dans les autres, couvertes d'yeux, flammes dorées
4. Valkaria, reine des valkyries, armure d'argent et d'or, cheval ailé blanc derrière elle, lance dressée, cri de charge
5. Sérapheon, séraphin solaire aux six ailes de feu blanc, visage d'or sans expression, un petit soleil entre ses mains
6. Azarel, ange du jugement aux ailes noires et blanches, bandeau sur les yeux, glaive et balance, il juge en silence
7. Aurelys, déesse de la genèse, longue chevelure de lumière, robe d'étoiles, elle fait naître une fleur de lumière dans sa main
8. Belzaroth, prince démon en armure de braise, couronne de flammes, épée rougeoyante sur l'épaule, sourire arrogant
```

Commandes (je m'en occupe) :
`python3 outils/decouper_planche.py da_21_portraits.png oriel choeur_incarne ophanim valkaria serapheon azarel aurelys belzaroth`
`python3 outils/decouper_miniatures.py da_21_figurines.png --figurines oriel choeur_incarne ophanim valkaria serapheon azarel aurelys belzaroth`

---

## Planche DA-22 — Les héros des Tours et des Boss

| Case | Unité | Rareté | Élément · rôle |
|---|---|---|---|
| 1 | Nyxara la Succube (`nyxara`) | SSR | Ténèbres · assassin |
| 2 | Méphistar, Seigneur de l'Abîme (`mephistar`) | UR | Ténèbres · mage |
| 3 | Séraphine d'Aube (`seraphine_aube`) | SSR | Sacré · soutien |
| 4 | Solarius, l'Archange Solaire (`solarius`) | SSR | Sacré · guerrier |
| 5 | Aurelion, Premier Séraphin (`aurelion`) | UR | Sacré · mage |
| 6 | Rejeton du Béhémoth (`rejeton_behemoth`) | SSR | Feu · tank |
| 7 | Enfant de Nidhögr (`enfant_nidhogr`) | UR | Ténèbres · assassin |
| 8 | Gardien du Brasier (`gardien_brasier`) | SR | Feu · tank |

```
1. Nyxara la succube, guerrière agile aux ailes noires repliées, tenue de cuir sombre couvrante, deux dagues incurvées, elle se retourne avec un clin d'œil
2. Méphistar, mage démoniaque à la longue robe noire brodée d'or, cornes de bouc, livre de pactes ouvert dans une main et plume dans l'autre
3. Séraphine d'Aube, jeune ange guérisseuse aux ailes blanches, cheveux roux, robe blanche et or, elle soigne une colombe dans ses mains
4. Solarius, chevalier solaire en armure dorée, aile de feu unique sur le dos, épée large qui brille comme le soleil de midi
5. Aurelion, grand mage céleste à la barbe blanche, robe blanche et or, auréole de runes qui tourne autour de sa tête, bâton de lumière
6. le Rejeton du Béhémoth, petit béhémoth trapu de la taille d'un taureau, peau de roche noire craquelée de lave, petites cornes qui fument, air têtu et adorable
7. l'Enfant de Nidhögr, jeune dragon cosmique, écailles noires étoilées et ailes violettes encore petites, il mord une petite étoile comme un os
8. le gardien du brasier, golem de roche volcanique, un brasier ouvert dans la poitrine, poings fumants, posture de défense
```

Commandes (je m'en occupe) :
`python3 outils/decouper_planche.py da_22_portraits.png nyxara mephistar seraphine_aube solarius aurelion rejeton_behemoth enfant_nidhogr gardien_brasier`
`python3 outils/decouper_miniatures.py da_22_figurines.png --figurines nyxara mephistar seraphine_aube solarius aurelion rejeton_behemoth enfant_nidhogr gardien_brasier`

---

## Planche DA-23 — Les seigneurs des Donjons

| Case | Unité | Rareté | Élément · rôle |
|---|---|---|---|
| 1 | Ignaar, Cœur du Brasier (`ignaar`) | SSR | Feu · mage |
| 2 | Chasseuse de la Sylve (`chasseuse_sylve`) | SR | Nature · tireur |
| 3 | La Mère-Racine Putride (`mere_racine`) | SSR | Nature · soutien |
| 4 | Sentinelle de Corail (`sentinelle_corail`) | SR | Eau · tank |
| 5 | Le Kraken des Fosses (`kraken_fosses`) | SSR | Eau · guerrier |
| 6 | Geôlier de la Crypte (`geolier_crypte`) | SR | Ténèbres · guerrier |
| 7 | Morvena, Liche sans Lune (`morvena`) | SSR | Ténèbres · mage |
| 8 | Templier Profané (`templier_profane`) | SR | Sacré · tank |

```
1. Ignaar, élémentaire de magma en robe de lave, visage de feu, il fait pleuvoir des gouttes de lave de ses mains levées
2. la chasseuse de la sylve, archère elfe corrompue aux cheveux noirs pleins de feuilles mortes, tatouages verts, arc fait d'une racine
3. la Mère-Racine Putride, femme-arbre immense aux racines qui lui servent de cheveux, sève verte toxique, champignons lumineux
4. une sentinelle de corail, guerrier fait de coraux rouges et blancs, bouclier en carapace de tortue, trident
5. le Kraken des Fosses, pieuvre géante aux tentacules noirs et violets, un œil énorme, il serre une épave de navire
6. le geôlier de la crypte, squelette massif au trousseau de clés géant, lanterne sans lumière, manteau de toiles d'araignée
7. Morvena, nécromancienne à la peau grise et aux yeux noirs, robe de voiles funéraires, des âmes bleues tournent autour d'elle
8. un templier profané, chevalier en armure blanche souillée de noir, tabard déchiré, épée sacrée fissurée qui suinte une lumière noire
```

Commandes (je m'en occupe) :
`python3 outils/decouper_planche.py da_23_portraits.png ignaar chasseuse_sylve mere_racine sentinelle_corail kraken_fosses geolier_crypte morvena templier_profane`
`python3 outils/decouper_miniatures.py da_23_figurines.png --figurines ignaar chasseuse_sylve mere_racine sentinelle_corail kraken_fosses geolier_crypte morvena templier_profane`

---

## Planche DA-24 — Le Puits et le Mimic

| Case | Unité | Rareté | Élément · rôle |
|---|---|---|---|
| 1 | L'Oracle Profané (`oracle_profane`) | SSR | Sacré · mage |
| 2 | Le Boucher du Puits (`boucher_puits`) | SR | Neutre · guerrier |
| 3 | Hémoragos, le Puits Vivant (`hemoragos`) | SSR | Neutre · tank |
| 4 | Mimic (`mimic`) | SR | Neutre · guerrier |

```
1. l'Oracle Profané, prêtresse aveugle aux yeux bandés de rouge, robe dorée ternie, un troisième œil noir ouvert sur le front
2. le Boucher du Puits, colosse au tablier sanglant, crochet de boucher et couperet géant, gros rire, chaînes au cou
3. Hémoragos, créature de sang vivant en forme de géant, corps translucide rouge où l'on voit tourbillonner des rivières de sang
4. un mimic, coffre au trésor en bois cerclé de fer qui s'ouvre sur une grande gueule pleine de dents et une longue langue, des pièces d'or qui tombent, regard malin
```

Commandes (je m'en occupe) :
`python3 outils/decouper_planche.py da_24_portraits.png oracle_profane boucher_puits hemoragos mimic`
`python3 outils/decouper_miniatures.py da_24_figurines.png --figurines oracle_profane boucher_puits hemoragos mimic`

---
