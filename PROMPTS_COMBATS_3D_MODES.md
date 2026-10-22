# Prompts — Décors 3D des autres modes (Tours, Donjons, Sanctuaire, Arène, Guerre)

Même principe que pour les Actes : pour chaque décor, il faut deux images.
- la **toile de fond** (paysage 16:9), dressée au fond du champ de bataille ;
- le **sol** (carré, raccordable), couché par terre et répété jusqu'à la caméra.

Une bulle = une image : copie-colle la bulle entière dans ChatGPT, une conversation par décor de préférence (toile d'abord, puis sol dans la même conversation pour que les couleurs se répondent).

**Astuce style** : joins `assets/combat3d/acte_01_fond.png` à la première image de chaque décor et ajoute « même style de peinture que l'image jointe ».

Fichiers à me rendre (je les range et je règle la coupe de chaque décor) :

| Mode | Toile | Sol |
|---|---|---|
| Tour de l'Enfer | `tour_enfer_fond.png` | `tour_enfer_sol.png` |
| Tour du Paradis | `tour_paradis_fond.png` | `tour_paradis_sol.png` |
| Donjon de Feu — Le Brasier Éternel | `donjon_feu_fond.png` | `donjon_feu_sol.png` |
| Donjon de Nature — La Sylve Putride | `donjon_nature_fond.png` | `donjon_nature_sol.png` |
| Donjon d'Eau — Les Fosses Englouties | `donjon_eau_fond.png` | `donjon_eau_sol.png` |
| Donjon des Ténèbres — La Crypte sans Lune | `donjon_tenebres_fond.png` | `donjon_tenebres_sol.png` |
| Donjon Sacré — Le Sanctuaire Profané | `donjon_sacre_fond.png` | `donjon_sacre_sol.png` |
| Puits de Sang (donjon neutre) | `donjon_neutre_fond.png` | `donjon_neutre_sol.png` |
| Bibliothèque Interdite | `donjon_savoir_fond.png` | `donjon_savoir_sol.png` |
| Sanctuaire du Bélier | `sanctuaire_fond.png` | `sanctuaire_sol.png` |
| Arène (JcJ et Classé) | `arene_fond.png` | `arene_sol.png` |
| Guerre des Bannières | `guerre_fond.png` | `guerre_sol.png` |

La **Marche Maudite** n'a besoin d'aucune image : elle traverse les régions des Actes et utilise déjà leurs décors 3D.

## En attendant
Tous ces modes sont déjà en 3D (v0.76.0). Tant que leur décor n'est pas peint, chacun emprunte celui d'un Acte proche : Tour de l'Enfer → Acte XII, Tour du Paradis → Acte IX, Feu → V, Nature → VII, Eau → II, Ténèbres → IV, Sacré → IX, Puits de Sang → VIII, Bibliothèque → IV, Sanctuaire → XIII, Arène → III, Guerre → VIII. Dès qu'un décor arrive, il remplace l'emprunt tout seul.

## État
- Aucun décor de mode encore peint.
- Sol du Puits de Sang : le premier prompt était refusé par ChatGPT (« contenus violents ») ; réécrit sans le mot « sang » (nouvelle conversation, sans image jointe si le refus persiste).

---

## 1. Tour de l'Enfer

### tour_enfer_fond
```
Illustration de dark fantasy peinte, très détaillée, style peinture numérique de jeu vidéo.
Format paysage 16:9 (1920x1080).
Décor de fond pour un champ de bataille, vu à hauteur d'homme, SANS AUCUN personnage, aucune créature, aucun démon, aucune silhouette.
Un palier d'une immense tour infernale qui s'enfonce sous la terre : la scène est une large plateforme d'obsidienne suspendue au-dessus d'un gouffre de lave. Au centre, au loin, un grand portail de pierre noire en forme de gueule, entouré de chaînes géantes, qui s'ouvre sur un escalier en spirale descendant vers une lueur rouge (l'étage suivant). Autour, des cascades de lave qui tombent des étages supérieurs, des statues démoniaques brisées, des braseros de fer. Sur les côtés, de grands piliers d'obsidienne fendus, veinés de lave, qui encadrent la scène.
Composition : le portail et l'escalier sont dans la moitié basse de l'image, rien d'important dans le quart supérieur (voûte de roche noire et fumée rouge).
Le sol (obsidienne fissurée, veines de lave) n'occupe que la bande du bas, sous une ligne d'horizon placée à environ 72 % de la hauteur. Tout le bas de l'image est dégagé : aucun objet, aucune chaîne, aucune silhouette au premier plan.
Palette : noir obsidienne, rouge et orange de lave, fumée pourpre.
Lumière : lueur de lave venue d'en bas, braises qui montent. Pas de texte, pas de cadre, pas de logo.
```

### tour_enfer_sol
```
Texture de sol de dark fantasy peinte, vue exactement du dessus (vue zénithale, à plat, sans perspective),
format carré 1024x1024, RACCORDABLE SANS COUTURE sur les quatre bords (seamless tileable texture).
Dalles d'obsidienne noire brillante, fissurées, avec de fines veines de lave orange qui courent dans les fissures, un peu de cendre grise et quelques braises.
Éclairage neutre et uniforme, sans ombre portée marquée et sans point lumineux dominant.
Aucun objet gros, aucun personnage, aucune arme, aucun motif qui se remarque quand on répète l'image (les veines de lave restent fines et réparties partout).
Palette : noir, gris cendre, orange lave, touches de rouge.
Pas de texte, pas de cadre.
```

---

## 2. Tour du Paradis

### tour_paradis_fond
```
Illustration de fantasy sombre et lumineuse, peinte, très détaillée, style peinture numérique de jeu vidéo.
Format paysage 16:9 (1920x1080).
Décor de fond pour un champ de bataille, vu à hauteur d'homme, SANS AUCUN personnage, aucun ange, aucune créature, aucune silhouette.
Un palier d'une immense tour céleste d'ivoire et d'or, au-dessus d'une mer de nuages : la scène est une vaste terrasse de marbre blanc à ciel ouvert. Au centre, au loin, une grande arche dorée ouverte sur un escalier de marbre qui monte vers une lumière éblouissante (l'étage suivant). Autour, des temples flottants, des colonnes d'ivoire, des cloches d'or suspendues, quelques plumes blanches qui volent. Sur les côtés, de grandes colonnes de marbre aux chapiteaux dorés et des statues ailées sans visage qui encadrent la scène.
Composition : l'arche et l'escalier sont dans la moitié basse du ciel, rien d'important dans le quart supérieur de l'image (ciel doré pâle et nuages).
Le sol (marbre blanc veiné d'or) n'occupe que la bande du bas, sous une ligne d'horizon placée à environ 72 % de la hauteur. Tout le bas de l'image est dégagé : aucun objet, aucune colonne, aucune silhouette au premier plan.
Palette : blanc ivoire, or, bleu ciel très pâle, ombres douces bleutées (pas tout blanc : il faut du contraste).
Lumière : lumière divine qui descend en rayons, contre-jour doré. Pas de texte, pas de cadre, pas de logo.
```

### tour_paradis_sol
```
Texture de sol de fantasy peinte, vue exactement du dessus (vue zénithale, à plat, sans perspective),
format carré 1024x1024, RACCORDABLE SANS COUTURE sur les quatre bords (seamless tileable texture).
Dalles de marbre blanc cassé veinées d'or, joints dorés fins, légères traces d'usure, quelques plumes blanches et pétales dorés épars.
Éclairage neutre et uniforme, pas trop clair (un marbre légèrement grisé, pas un blanc éclatant), sans ombre portée marquée et sans point lumineux dominant.
Aucun objet gros, aucun personnage, aucune arme, aucun motif qui se remarque quand on répète l'image (pas de grande rosace).
Palette : blanc cassé, gris perle, or, touches de bleu pâle.
Pas de texte, pas de cadre.
```

---

## 3. Donjon de Feu — Le Brasier Éternel

### donjon_feu_fond
```
Illustration de dark fantasy peinte, très détaillée, style peinture numérique de jeu vidéo.
Format paysage 16:9 (1920x1080).
Décor de fond pour un champ de bataille, vu à hauteur d'homme, SANS AUCUN personnage, aucune créature, aucune silhouette.
Une forge souterraine oubliée, creusée dans un volcan, où la lave ne refroidit jamais : au centre, au loin, une enclume colossale posée sur un autel de pierre, devant un immense fourneau en forme de tête de bête dont la gueule crache une lumière orange. Autour, des rivières de lave qui coulent dans des canaux de pierre, des chaînes et des marteaux géants suspendus, des cuves de métal en fusion. Sur les côtés, de grands soufflets de forge et des piliers de roche volcanique qui encadrent la scène.
Composition : l'enclume et le fourneau sont dans la moitié basse de l'image, rien d'important dans le quart supérieur (voûte de roche noire, fumée).
Le sol (pierre volcanique noire, scories, traces de métal refroidi) n'occupe que la bande du bas, sous une ligne d'horizon placée à environ 72 % de la hauteur. Tout le bas de l'image est dégagé : aucun objet, aucune enclume, aucune silhouette au premier plan.
Palette : noir de suie, orange de lave, rouge braise, reflets cuivrés.
Lumière : lueur ardente du fourneau et de la lave, étincelles qui volent. Pas de texte, pas de cadre, pas de logo.
```

### donjon_feu_sol
```
Texture de sol de dark fantasy peinte, vue exactement du dessus (vue zénithale, à plat, sans perspective),
format carré 1024x1024, RACCORDABLE SANS COUTURE sur les quatre bords (seamless tileable texture).
Sol de forge volcanique : pierre noire, scories, petites coulures de métal refroidi aux reflets cuivrés, fines fissures orange, poussière de suie.
Éclairage neutre et uniforme, sans ombre portée marquée et sans point lumineux dominant.
Aucun objet gros, aucun personnage, aucun outil, aucun motif qui se remarque quand on répète l'image.
Palette : noir, gris anthracite, orange braise, touches de cuivre.
Pas de texte, pas de cadre.
```

---

## 4. Donjon de Nature — La Sylve Putride

### donjon_nature_fond
```
Illustration de dark fantasy peinte, très détaillée, style peinture numérique de jeu vidéo.
Format paysage 16:9 (1920x1080).
Décor de fond pour un champ de bataille, vu à hauteur d'homme, SANS AUCUN personnage, aucune créature, aucune silhouette.
Le cœur d'une forêt malade où chaque racine a faim : au centre, au loin, un arbre-mère colossal et pourrissant, son tronc ouvert comme une bouche d'où suinte une sève verte luminescente, ses racines énormes qui serpentent sur le sol. Autour, des champignons géants phosphorescents, des toiles d'araignée épaisses tendues entre les branches, des spores vertes qui flottent dans l'air. Sur les côtés, de grands arbres tordus couverts de mousse et de lianes qui encadrent la scène.
Composition : l'arbre-mère est dans la moitié basse de l'image, rien d'important dans le quart supérieur (canopée noire).
Le sol (humus noir, racines, feuilles pourries) n'occupe que la bande du bas, sous une ligne d'horizon placée à environ 72 % de la hauteur. Tout le bas de l'image est dégagé : aucun objet, aucune grosse racine, aucune silhouette au premier plan.
Palette : vert poison, noir, brun pourri, touches de violet.
Lumière : pénombre, lueur verte de la sève et des champignons, brume basse. Pas de texte, pas de cadre, pas de logo.
```

### donjon_nature_sol
```
Texture de sol de dark fantasy peinte, vue exactement du dessus (vue zénithale, à plat, sans perspective),
format carré 1024x1024, RACCORDABLE SANS COUTURE sur les quatre bords (seamless tileable texture).
Sol de forêt malade : humus noir humide, feuilles mortes pourrissantes, petites racines, mousse vert sombre, minuscules champignons phosphorescents verts répartis partout.
Éclairage neutre et uniforme, sans ombre portée marquée et sans point lumineux dominant.
Aucun objet gros, aucun personnage, aucune arme, aucun motif qui se remarque quand on répète l'image.
Palette : noir, brun, vert poison, touches de violet.
Pas de texte, pas de cadre.
```

---

## 5. Donjon d'Eau — Les Fosses Englouties

### donjon_eau_fond
```
Illustration de dark fantasy peinte, très détaillée, style peinture numérique de jeu vidéo.
Format paysage 16:9 (1920x1080).
Décor de fond pour un champ de bataille, vu à hauteur d'homme, SANS AUCUN personnage, aucune créature, aucun poisson, aucune silhouette.
Une cité noyée au fond d'un océan noir, dans une immense bulle d'air sous la mer : au centre, au loin, un temple englouti aux colonnes couvertes de corail et de coquillages, son portail baigné d'une lueur turquoise. Autour, des statues de rois marins renversées, des épaves de navires, des algues géantes qui ondulent, des bulles qui montent. Au-dessus, une paroi d'eau sombre où filtrent des rayons bleus. Sur les côtés, des colonnes brisées couvertes de corail qui encadrent la scène.
Composition : le temple est dans la moitié basse de l'image, rien d'important dans le quart supérieur (eau sombre).
Le sol (dalles de pierre couvertes de sable, coquillages, petites flaques) n'occupe que la bande du bas, sous une ligne d'horizon placée à environ 72 % de la hauteur. Tout le bas de l'image est dégagé : aucun objet, aucune épave, aucune silhouette au premier plan.
Palette : bleu abysse, turquoise, vert d'eau, touches de corail rouge.
Lumière : rayons bleus venus d'en haut, lueur turquoise du portail, reflets d'eau qui dansent. Pas de texte, pas de cadre, pas de logo.
```

### donjon_eau_sol
```
Texture de sol de dark fantasy peinte, vue exactement du dessus (vue zénithale, à plat, sans perspective),
format carré 1024x1024, RACCORDABLE SANS COUTURE sur les quatre bords (seamless tileable texture).
Fond marin d'une cité engloutie : vieilles dalles de pierre à moitié recouvertes de sable gris-bleu, petits coquillages, algues fines, flaques d'eau qui reflètent une lueur turquoise.
Éclairage neutre et uniforme, légèrement bleuté, sans ombre portée marquée et sans point lumineux dominant.
Aucun objet gros, aucun personnage, aucune arme, aucun motif qui se remarque quand on répète l'image.
Palette : gris-bleu, sable, turquoise, touches de corail.
Pas de texte, pas de cadre.
```

---

## 6. Donjon des Ténèbres — La Crypte sans Lune

### donjon_tenebres_fond
```
Illustration de dark fantasy peinte, très détaillée, style peinture numérique de jeu vidéo.
Format paysage 16:9 (1920x1080).
Décor de fond pour un champ de bataille, vu à hauteur d'homme, SANS AUCUN personnage, aucune créature, aucun squelette debout, aucune silhouette.
Des catacombes où aucune lumière n'est jamais entrée : au centre, au loin, un autel noir sous une voûte, au-dessus duquel flotte une sphère de ténèbres entourée d'un halo violet. Autour, des murs couverts de crânes encastrés, des niches funéraires, des bougies noires aux flammes violettes, des chaînes qui pendent. Sur les côtés, de lourds piliers gravés de runes violettes qui encadrent la scène.
Composition : l'autel et la sphère sont dans la moitié basse de l'image, rien d'important dans le quart supérieur (voûte noire).
Le sol (dalles noires, poussière d'os, cire noire) n'occupe que la bande du bas, sous une ligne d'horizon placée à environ 72 % de la hauteur. Tout le bas de l'image est dégagé : aucun objet, aucun crâne, aucune silhouette au premier plan.
Palette : noir profond, violet, gris os, touches de vert pâle.
Lumière : seulement les flammes violettes et le halo de la sphère, brume noire au ras du sol. Image sombre mais lisible. Pas de texte, pas de cadre, pas de logo.
```

### donjon_tenebres_sol
```
Texture de sol de dark fantasy peinte, vue exactement du dessus (vue zénithale, à plat, sans perspective),
format carré 1024x1024, RACCORDABLE SANS COUTURE sur les quatre bords (seamless tileable texture).
Dalles de pierre noire usées, poussière d'os grise, coulures de cire noire, fines runes violettes à moitié effacées réparties partout, petits éclats d'os.
Éclairage neutre et uniforme, sans ombre portée marquée et sans point lumineux dominant (pas trop sombre : la texture doit rester lisible).
Aucun objet gros, aucun crâne entier, aucun personnage, aucun motif qui se remarque quand on répète l'image.
Palette : noir, gris os, touches de violet.
Pas de texte, pas de cadre.
```

---

## 7. Donjon Sacré — Le Sanctuaire Profané

### donjon_sacre_fond
```
Illustration de dark fantasy peinte, très détaillée, style peinture numérique de jeu vidéo.
Format paysage 16:9 (1920x1080).
Décor de fond pour un champ de bataille, vu à hauteur d'homme, SANS AUCUN personnage, aucune créature, aucune silhouette.
Un temple céleste souillé par un culte oublié : au centre, au loin, un grand autel de marbre blanc surmonté d'une statue d'ange sans visage, ses ailes brisées, couverte de symboles de culte peints en rouge sombre. Une lumière dorée tombe d'un vitrail brisé au-dessus de l'autel. Autour, des bancs renversés, des chandeliers d'or tordus, des tentures sacrées déchirées et tachées. Sur les côtés, de grandes colonnes blanches fissurées, couvertes de lierre noir, qui encadrent la scène.
Composition : l'autel et la statue sont dans la moitié basse de l'image, rien d'important dans le quart supérieur (voûte et vitraux sombres).
Le sol (marbre blanc fissuré, éclats de vitrail, cire) n'occupe que la bande du bas, sous une ligne d'horizon placée à environ 72 % de la hauteur. Tout le bas de l'image est dégagé : aucun objet, aucun banc, aucune silhouette au premier plan.
Palette : blanc marbre, or, rouge sombre du culte, ombres bleutées.
Lumière : rayon doré du vitrail contre la pénombre, poussière dorée en suspension. Pas de texte, pas de cadre, pas de logo.
```

### donjon_sacre_sol
```
Texture de sol de dark fantasy peinte, vue exactement du dessus (vue zénithale, à plat, sans perspective),
format carré 1024x1024, RACCORDABLE SANS COUTURE sur les quatre bords (seamless tileable texture).
Dalles de marbre blanc cassé, fissurées et salies, joints dorés ternis, petits éclats de vitrail colorés, gouttes de cire, quelques traces rouge sombre très discrètes.
Éclairage neutre et uniforme, marbre légèrement grisé (pas un blanc éclatant), sans ombre portée marquée et sans point lumineux dominant.
Aucun objet gros, aucun personnage, aucune arme, aucun motif qui se remarque quand on répète l'image.
Palette : blanc cassé, gris, or terni, touches de rouge sombre.
Pas de texte, pas de cadre.
```

---

## 8. Puits de Sang (donjon neutre)

### donjon_neutre_fond
```
Illustration de dark fantasy peinte, très détaillée, style peinture numérique de jeu vidéo.
Format paysage 16:9 (1920x1080).
Décor de fond pour un champ de bataille, vu à hauteur d'homme, SANS AUCUN personnage, aucune créature, aucune silhouette.
Un gouffre sans fond où tout le sang du monde finit par couler : la scène est une corniche de pierre au bord d'un abîme circulaire. Au centre, au loin, de l'autre côté du gouffre, une immense cascade de sang qui tombe dans le vide depuis une fissure de la falaise, avec un pont de pierre étroit et à moitié effondré qui la traverse. Autour, des parois de roche rouge sombre, des canaux creusés où coule le sang, de vieilles chaînes et des cages vides suspendues au-dessus du vide. Sur les côtés, des pans de falaise et des stalactites qui encadrent la scène.
Composition : la cascade et le pont sont dans la moitié basse de l'image, rien d'important dans le quart supérieur (roche sombre et brume rouge).
Le sol (roche rouge sombre, flaques de sang séché) n'occupe que la bande du bas, sous une ligne d'horizon placée à environ 72 % de la hauteur. Tout le bas de l'image est dégagé : aucun objet, aucune cage, aucune silhouette au premier plan.
Palette : rouge sang, bordeaux, noir, touches d'or terni.
Lumière : lueur rouge qui monte du gouffre, brume rouge. Pas trop gore : du sang sombre, pas de corps. Pas de texte, pas de cadre, pas de logo.
```

### donjon_neutre_sol
```
Texture de sol de dark fantasy peinte, vue exactement du dessus (vue zénithale, à plat, sans perspective),
format carré 1024x1024, RACCORDABLE SANS COUTURE sur les quatre bords (seamless tileable texture).
Roche volcanique rouge sombre et rugueuse, comme du grès rouge ou du jaspe, avec de petites rigoles et des flaques peu profondes d'eau minérale rouge rubis très foncée, presque noire, à la surface brillante. Gravillons, fines fissures, quelques veines de minerai couleur grenat.
Éclairage neutre et uniforme, sans ombre portée marquée et sans point lumineux dominant.
Aucun objet gros, aucun personnage, aucun motif qui se remarque quand on répète l'image.
Palette : rouge grenat, bordeaux, brun-noir, reflets rubis.
Pas de texte, pas de cadre.
```

---

## 9. Bibliothèque Interdite

### donjon_savoir_fond
```
Illustration de dark fantasy peinte, très détaillée, style peinture numérique de jeu vidéo.
Format paysage 16:9 (1920x1080).
Décor de fond pour un champ de bataille, vu à hauteur d'homme, SANS AUCUN personnage, aucune créature, aucune silhouette.
Une bibliothèque interdite aux rayonnages sans fin, où les sorts oubliés se défendent seuls : au centre, au loin, un grand pupitre de pierre sur lequel repose un grimoire ouvert, enchaîné, d'où s'élève une colonne de lumière bleue et des runes qui flottent. Autour, des étagères gigantesques qui montent à perte de vue, des échelles, des livres et des pages qui volent dans l'air, des chandeliers aux flammes bleues. Sur les côtés, de grands rayonnages de bois sombre sculpté qui encadrent la scène.
Composition : le pupitre et le grimoire sont dans la moitié basse de l'image, rien d'important dans le quart supérieur (rayonnages qui se perdent dans l'ombre).
Le sol (parquet sombre, tapis usé, pages éparses) n'occupe que la bande du bas, sous une ligne d'horizon placée à environ 72 % de la hauteur. Tout le bas de l'image est dégagé : aucun objet, aucune pile de livres, aucune silhouette au premier plan.
Palette : bois sombre, bleu magique, parchemin, touches de violet et d'or.
Lumière : lueur bleue du grimoire, flammes bleues, poussière en suspension. Pas de texte lisible, pas de cadre, pas de logo.
```

### donjon_savoir_sol
```
Texture de sol de dark fantasy peinte, vue exactement du dessus (vue zénithale, à plat, sans perspective),
format carré 1024x1024, RACCORDABLE SANS COUTURE sur les quatre bords (seamless tileable texture).
Parquet de bois sombre ancien, lattes usées, quelques pages de parchemin éparses et froissées, gouttes de cire, fine poussière, petites runes bleues pâles à peine visibles.
Éclairage neutre et uniforme, sans ombre portée marquée et sans point lumineux dominant.
Aucun objet gros, aucun livre entier, aucun personnage, aucun texte lisible, aucun motif qui se remarque quand on répète l'image.
Palette : brun sombre, parchemin, touches de bleu pâle.
Pas de texte, pas de cadre.
```

---

## 10. Sanctuaire du Bélier

### sanctuaire_fond
```
Illustration de dark fantasy peinte, très détaillée, style peinture numérique de jeu vidéo.
Format paysage 16:9 (1920x1080).
Décor de fond pour un champ de bataille, vu à hauteur d'homme, SANS AUCUN personnage, aucune créature, aucune silhouette.
Un sanctuaire secret dédié au signe du Bélier, chaleureux et solennel : au centre, au loin, en haut de quelques marches, une immense tête de bélier dorée sculptée dans le mur, aux cornes enroulées, encadrée de deux statues de gardiens jumeaux (signe des Gémeaux) qui tiennent chacun un bouclier gravé. Autour, des bannières rouges et or au symbole du bélier, des braseros dorés, une constellation du Bélier qui scintille sous la voûte. Sur les côtés, de grandes colonnes de pierre ornées d'or qui encadrent la scène.
Composition : la tête de bélier et les jumeaux sont dans la moitié basse de l'image, rien d'important dans le quart supérieur (voûte sombre étoilée).
Le sol (dalles de pierre polie aux reflets dorés) n'occupe que la bande du bas, sous une ligne d'horizon placée à environ 72 % de la hauteur. Tout le bas de l'image est dégagé : aucun objet, aucun brasero, aucune silhouette au premier plan.
Palette : or, rouge profond, brun chaud, touches de bleu nuit.
Lumière : chaude, lueurs dorées des braseros, reflets sur le sol poli. Pas de texte, pas de cadre, pas de logo.
```

### sanctuaire_sol
```
Texture de sol de dark fantasy peinte, vue exactement du dessus (vue zénithale, à plat, sans perspective),
format carré 1024x1024, RACCORDABLE SANS COUTURE sur les quatre bords (seamless tileable texture).
Dalles de pierre sombre polie aux reflets dorés, joints d'or fins, quelques fissures, très petits motifs d'étoiles dorées incrustés et répartis régulièrement.
Éclairage neutre et uniforme, sans ombre portée marquée et sans point lumineux dominant.
Aucun objet gros, aucun personnage, aucune arme, aucun grand symbole au centre, aucun motif qui se remarque quand on répète l'image.
Palette : brun sombre, or, touches de rouge profond.
Pas de texte, pas de cadre.
```

---

## 11. Arène (JcJ et Classé)

### arene_fond
```
Illustration de dark fantasy peinte, très détaillée, style peinture numérique de jeu vidéo.
Format paysage 16:9 (1920x1080).
Décor de fond pour un champ de bataille, vu à hauteur d'homme, SANS AUCUN personnage, aucune créature, aucun spectateur visible, aucune silhouette.
L'intérieur d'un grand colisée de pierre la nuit, vu depuis le sable de l'arène : au centre, au loin, la loge d'honneur surmontée d'un grand étendard au phénix bleu, sous les gradins sombres. Autour, les gradins en arc de cercle, des arches, des braseros aux flammes bleues et orange, des bannières bleues et rouges qui pendent des murs, une grille de fer levée sous la loge. Une grande lune pâle dans le ciel nocturne. Sur les côtés, de hautes statues de gladiateurs en pierre et des murs de l'arène qui encadrent la scène.
Composition : la loge et les gradins sont dans la moitié basse de l'image, la lune basse ; rien d'important dans le quart supérieur (ciel de nuit).
Le sol (sable d'arène damé, traces de combats) n'occupe que la bande du bas, sous une ligne d'horizon placée à environ 72 % de la hauteur. Tout le bas de l'image est dégagé : aucun objet, aucune arme, aucune silhouette au premier plan.
Palette : pierre grise, bleu nuit, flammes bleues, touches d'or et de rouge.
Lumière : nuit, braseros bleus et orange, clair de lune. Pas de texte, pas de cadre, pas de logo.
```

### arene_sol
```
Texture de sol de dark fantasy peinte, vue exactement du dessus (vue zénithale, à plat, sans perspective),
format carré 1024x1024, RACCORDABLE SANS COUTURE sur les quatre bords (seamless tileable texture).
Sable d'arène damé gris-beige, traces de pas et de glissades, quelques gravillons, petites taches sombres, quelques dalles de pierre affleurantes.
Éclairage neutre et uniforme, sans ombre portée marquée et sans point lumineux dominant.
Aucun objet gros, aucun personnage, aucune arme, aucun motif qui se remarque quand on répète l'image.
Palette : beige-gris, brun clair, touches de bleu nuit dans les ombres.
Pas de texte, pas de cadre.
```

---

## 12. Guerre des Bannières

### guerre_fond
```
Illustration de dark fantasy peinte, très détaillée, style peinture numérique de jeu vidéo.
Format paysage 16:9 (1920x1080).
Décor de fond pour un champ de bataille, vu à hauteur d'homme, SANS AUCUN personnage, aucune créature, aucune silhouette.
Un siège sur les Terres de Valcendre, à l'aube : au centre, au loin, sur une colline, une forteresse ennemie avec ses remparts, ses tours et son donjon, sur lesquels flottent de grandes bannières de guilde de plusieurs couleurs (rouge, bleu, vert, violet, or). Devant les remparts, des palissades de pieux, des tranchées, des tours de siège, des feux de camp et des étendards plantés. Sur les côtés, des tentes de campement militaire et des catapultes qui encadrent la scène.
Composition : la forteresse est dans la moitié basse du ciel, rien d'important dans le quart supérieur (ciel d'aube gris-orangé, fumée).
Le sol (herbe piétinée, terre labourée par les combats, boue) n'occupe que la bande du bas, sous une ligne d'horizon placée à environ 72 % de la hauteur. Tout le bas de l'image est dégagé : aucun objet, aucune arme, aucune silhouette au premier plan.
Palette : gris-vert, brun, ciel orangé, couleurs vives des bannières.
Lumière : aube froide avec lueurs chaudes des feux de camp, fumée qui traîne. Pas de texte, pas de cadre, pas de logo.
```

### guerre_sol
```
Texture de sol de dark fantasy peinte, vue exactement du dessus (vue zénithale, à plat, sans perspective),
format carré 1024x1024, RACCORDABLE SANS COUTURE sur les quatre bords (seamless tileable texture).
Champ de bataille : herbe piétinée et couchée, terre brune labourée, boue, empreintes de sabots et de bottes, quelques lambeaux de tissu de bannière de couleurs variées, éclats de bois.
Éclairage neutre et uniforme, sans ombre portée marquée et sans point lumineux dominant.
Aucun objet gros, aucun personnage, aucune arme entière, aucun motif qui se remarque quand on répète l'image.
Palette : vert-gris, brun, touches de couleurs de bannières.
Pas de texte, pas de cadre.
```
