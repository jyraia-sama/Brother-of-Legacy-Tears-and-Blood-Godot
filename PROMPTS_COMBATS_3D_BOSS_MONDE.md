# Prompts — Décors 3D des Boss de Monde

Même principe que pour les Actes et les modes : pour chaque géant, deux images.
- la **toile de fond** (paysage 16:9), dressée au fond du champ de bataille ;
- le **sol** (carré, raccordable), couché par terre et répété jusqu'à la caméra.

Une bulle = une image : copie-colle la bulle entière dans ChatGPT, une conversation par géant (toile d'abord, puis sol dans la même conversation).

**Important** : le géant est une figurine posée DEVANT la toile. La toile ne doit donc contenir AUCUNE créature, sinon il y aurait deux monstres. Le décor doit seulement donner l'échelle : un paysage immense, dévasté par son passage.

**Astuce style** : joins `assets/combat3d/acte_01_fond.png` à la première image et ajoute « même style de peinture que l'image jointe ».
**Si ChatGPT refuse** (« contenus violents ») : nouvelle conversation, sans image jointe.

Fichiers à me rendre :

| Géant | Toile | Sol |
|---|---|---|
| Le Béhémoth des Cendres | `boss_behemoth_cendres_fond.png` | `boss_behemoth_cendres_sol.png` |
| Le Léviathan des Abysses Noires | `boss_leviathan_noir_fond.png` | `boss_leviathan_noir_sol.png` |
| Yggdravor, l'Arbre-Monde Corrompu | `boss_yggdravor_fond.png` | `boss_yggdravor_sol.png` |
| Golgoth, Colosse de Pierre-Sang | `boss_golgoth_fond.png` | `boss_golgoth_sol.png` |
| Solgard, le Soleil Vivant | `boss_solgard_fond.png` | `boss_solgard_sol.png` |
| Nidhögr, Dévoreur d'Étoiles | `boss_nidhogr_fond.png` | `boss_nidhogr_sol.png` |
| L'Avatar du Sang Originel | `boss_avatar_sang_fond.png` | `boss_avatar_sang_sol.png` |

## En attendant
Le Boss de Monde est en 3D depuis la v0.77.0 ; chaque géant emprunte un décor proche (Béhémoth → Terres Brûlées, Léviathan → Fosses Englouties, Yggdravor → Sylve Putride, Golgoth → Puits de Sang, Solgard → Paradis, Nidhögr → Sceau des Frères, Avatar → Bastion de l'éclipse). Dès qu'un décor arrive, il remplace l'emprunt tout seul.

## État
- Les 7 décors sont faits en v0.77.1 (coupes : Avatar 0.69, Béhémoth 0.69, Golgoth 0.68, Léviathan 0.68, Nidhögr 0.69, Solgard 0.68, Yggdravor 0.67).

---

## 1. Le Béhémoth des Cendres

### boss_behemoth_cendres_fond
```
Illustration de dark fantasy peinte, très détaillée, style peinture numérique de jeu vidéo.
Format paysage 16:9 (1920x1080).
Décor de fond pour un champ de bataille, vu à hauteur d'homme, SANS AUCUN personnage, aucune créature, aucun monstre, aucune silhouette.
Une plaine volcanique immense dévastée par le passage d'un titan : au loin, une chaîne de volcans en éruption sous un ciel noir de cendres, des coulées de lave qui descendent les pentes. À mi-distance, les ruines d'une cité fortifiée écrasée, ses remparts effondrés et marqués d'empreintes de sabots gigantesques, des tours renversées qui fument. Sur les côtés, des pans de remparts écroulés et des arbres calcinés qui encadrent la scène.
Composition : le centre et la droite de l'image sont dégagés et ouverts (un géant se tiendra là) ; rien d'important dans le quart supérieur (ciel de cendres).
Le sol (basalte noir, cendres, fissures de lave) n'occupe que la bande du bas, sous une ligne d'horizon placée à environ 72 % de la hauteur. Tout le bas de l'image est dégagé : aucun objet, aucune silhouette au premier plan.
Palette : noir de basalte, orange de lave, gris de cendre.
Lumière : lueurs de lave au loin, ciel sombre, braises qui volent. Pas de texte, pas de cadre, pas de logo.
```

### boss_behemoth_cendres_sol
```
Texture de sol de dark fantasy peinte, vue exactement du dessus (vue zénithale, à plat, sans perspective),
format carré 1024x1024, RACCORDABLE SANS COUTURE sur les quatre bords (seamless tileable texture).
Basalte noir fissuré couvert d'une couche de cendres grises, fines veines de lave orange dans les fissures, petits éclats de roche volcanique, quelques braises.
Éclairage neutre et uniforme, sans ombre portée marquée et sans point lumineux dominant.
Aucun objet gros, aucun personnage, aucun motif qui se remarque quand on répète l'image.
Palette : noir, gris cendre, orange lave.
Pas de texte, pas de cadre.
```

---

## 2. Le Léviathan des Abysses Noires

### boss_leviathan_noir_fond
```
Illustration de dark fantasy peinte, très détaillée, style peinture numérique de jeu vidéo.
Format paysage 16:9 (1920x1080).
Décor de fond pour un champ de bataille, vu à hauteur d'homme, SANS AUCUN personnage, aucune créature, aucun serpent, aucune silhouette.
Un rivage glacé battu par la tempête, au bord d'un océan noir : au loin, d'immenses vagues sombres sous un ciel d'orage, des éclairs, des épaves de navires brisées en deux et des icebergs. À mi-distance, un port en ruine à moitié englouti, ses phares effondrés, ses quais arrachés. Sur les côtés, des falaises couvertes de givre et des mâts brisés qui encadrent la scène.
Composition : le centre et la droite de l'image sont dégagés et ouverts (un géant se tiendra là) ; rien d'important dans le quart supérieur (ciel d'orage).
Le sol (rochers mouillés, givre, flaques d'eau de mer) n'occupe que la bande du bas, sous une ligne d'horizon placée à environ 72 % de la hauteur. Tout le bas de l'image est dégagé : aucun objet, aucune silhouette au premier plan.
Palette : noir océan, bleu nuit, bleu glace, écume blanche.
Lumière : tempête nocturne, éclairs, reflets bleu pâle sur l'eau. Pas de texte, pas de cadre, pas de logo.
```

### boss_leviathan_noir_sol
```
Texture de sol de dark fantasy peinte, vue exactement du dessus (vue zénithale, à plat, sans perspective),
format carré 1024x1024, RACCORDABLE SANS COUTURE sur les quatre bords (seamless tileable texture).
Rochers noirs mouillés d'un rivage glacé, plaques de givre, petites flaques d'eau de mer, coquillages et algues noires éparses, écume.
Éclairage neutre et uniforme, légèrement bleuté, sans ombre portée marquée et sans point lumineux dominant.
Aucun objet gros, aucun personnage, aucun motif qui se remarque quand on répète l'image.
Palette : noir, bleu nuit, blanc givre.
Pas de texte, pas de cadre.
```

---

## 3. Yggdravor, l'Arbre-Monde Corrompu

### boss_yggdravor_fond
```
Illustration de dark fantasy peinte, très détaillée, style peinture numérique de jeu vidéo.
Format paysage 16:9 (1920x1080).
Décor de fond pour un champ de bataille, vu à hauteur d'homme, SANS AUCUN personnage, aucune créature, aucun arbre vivant à visage, aucune silhouette.
Un royaume englouti par des racines géantes : au loin, les ruines d'un château et de tours de pierre enserrées et soulevées par des racines colossales et tordues, sous un ciel vert sombre chargé de spores. À mi-distance, des champs morts envahis de ronces noires, des fleurs violettes empoisonnées et des flaques de sève verte luminescente. Sur les côtés, de grosses racines noueuses qui sortent du sol et encadrent la scène.
Composition : le centre et la droite de l'image sont dégagés et ouverts (un géant se tiendra là) ; rien d'important dans le quart supérieur (ciel et spores).
Le sol (terre noire, racines fines, mousse) n'occupe que la bande du bas, sous une ligne d'horizon placée à environ 72 % de la hauteur. Tout le bas de l'image est dégagé : aucun objet, aucune grosse racine, aucune silhouette au premier plan.
Palette : brun d'écorce, vert poison, violet, noir.
Lumière : pénombre verdâtre, lueurs de sève, spores en suspension. Pas de texte, pas de cadre, pas de logo.
```

### boss_yggdravor_sol
```
Texture de sol de dark fantasy peinte, vue exactement du dessus (vue zénithale, à plat, sans perspective),
format carré 1024x1024, RACCORDABLE SANS COUTURE sur les quatre bords (seamless tileable texture).
Terre noire humide parcourue de fines racines entremêlées, mousse vert sombre, feuilles mortes violettes, petites gouttes de sève verte luminescente.
Éclairage neutre et uniforme, sans ombre portée marquée et sans point lumineux dominant.
Aucun objet gros, aucun personnage, aucun motif qui se remarque quand on répète l'image.
Palette : noir, brun, vert poison, touches de violet.
Pas de texte, pas de cadre.
```

---

## 4. Golgoth, Colosse de Pierre-Sang

### boss_golgoth_fond
```
Illustration de dark fantasy peinte, très détaillée, style peinture numérique de jeu vidéo.
Format paysage 16:9 (1920x1080).
Décor de fond pour un champ de bataille, vu à hauteur d'homme, SANS AUCUN personnage, aucune créature, aucun géant de pierre, aucune silhouette.
Un canyon de pierre grise gigantesque, aux falaises veinées de cristaux rouge rubis qui brillent : au loin, d'anciennes statues colossales effondrées, des arches naturelles et des ruines d'une civilisation de bâtisseurs, de grosses chaînes de fer brisées qui pendent des falaises. À mi-distance, des blocs de roche énormes éparpillés comme jetés par une main géante. Sur les côtés, des falaises couvertes de mousse et de cristaux rouges qui encadrent la scène.
Composition : le centre et la droite de l'image sont dégagés et ouverts (un géant se tiendra là) ; rien d'important dans le quart supérieur (ciel crépusculaire poussiéreux).
Le sol (dalles de roche grise fendues, éclats de cristal rouge) n'occupe que la bande du bas, sous une ligne d'horizon placée à environ 72 % de la hauteur. Tout le bas de l'image est dégagé : aucun objet, aucun rocher, aucune silhouette au premier plan.
Palette : gris pierre, rouge rubis, vert mousse, ciel orangé.
Lumière : crépuscule poussiéreux, lueur rouge des cristaux. Pas de texte, pas de cadre, pas de logo.
```

### boss_golgoth_sol
```
Texture de sol de dark fantasy peinte, vue exactement du dessus (vue zénithale, à plat, sans perspective),
format carré 1024x1024, RACCORDABLE SANS COUTURE sur les quatre bords (seamless tileable texture).
Roche grise dure et fendue, gravillons, poussière, petits éclats de cristal rouge rubis dans les fissures, quelques touffes de mousse.
Éclairage neutre et uniforme, sans ombre portée marquée et sans point lumineux dominant.
Aucun objet gros, aucun personnage, aucun motif qui se remarque quand on répète l'image.
Palette : gris pierre, rouge rubis, vert mousse.
Pas de texte, pas de cadre.
```

---

## 5. Solgard, le Soleil Vivant

### boss_solgard_fond
```
Illustration de fantasy peinte, très détaillée, style peinture numérique de jeu vidéo.
Format paysage 16:9 (1920x1080).
Décor de fond pour un champ de bataille, vu à hauteur d'homme, SANS AUCUN personnage, aucune créature, aucune silhouette.
Un désert de sable doré brûlé par un astre tombé du ciel : au loin, un immense cratère fumant dont le bord est vitrifié et brille comme du verre doré, les ruines d'un temple solaire aux colonnes fondues, des obélisques penchés. Le ciel est blanc-doré, écrasé de chaleur, avec un halo lumineux. Sur les côtés, des colonnes fondues et des dunes qui encadrent la scène.
Composition : le centre et la droite de l'image sont dégagés et ouverts (un géant se tiendra là) ; rien d'important dans le quart supérieur.
Le sol (sable doré vitrifié par endroits, craquelé) n'occupe que la bande du bas, sous une ligne d'horizon placée à environ 72 % de la hauteur. Tout le bas de l'image est dégagé : aucun objet, aucune silhouette au premier plan.
Palette : or, ocre, blanc chaud, ombres orangées (PAS tout blanc : il faut du contraste et des ombres).
Lumière : chaleur écrasante, brume de chaleur, reflets dorés sur le verre. Pas de texte, pas de cadre, pas de logo.
```

### boss_solgard_sol
```
Texture de sol de fantasy peinte, vue exactement du dessus (vue zénithale, à plat, sans perspective),
format carré 1024x1024, RACCORDABLE SANS COUTURE sur les quatre bords (seamless tileable texture).
Sable doré brûlé et craquelé, plaques de sable fondu changé en verre ambré, petites fissures, éclats de verre doré.
Éclairage neutre et uniforme, pas trop clair (un sable ocre doré, pas blanc), sans ombre portée marquée et sans point lumineux dominant.
Aucun objet gros, aucun personnage, aucun motif qui se remarque quand on répète l'image.
Palette : ocre, or, ambre, touches de brun.
Pas de texte, pas de cadre.
```

---

## 6. Nidhögr, Dévoreur d'Étoiles

### boss_nidhogr_fond
```
Illustration de dark fantasy cosmique peinte, très détaillée, style peinture numérique de jeu vidéo.
Format paysage 16:9 (1920x1080).
Décor de fond pour un champ de bataille, vu à hauteur d'homme, SANS AUCUN personnage, aucune créature, aucun dragon, aucune silhouette.
Le sommet d'une montagne au bord du ciel, sous une nuit cosmique : au loin, un ciel noir et violet rempli de nébuleuses et d'étoiles, dont certaines se brisent et tombent en traînées lumineuses ; les racines d'un arbre céleste gigantesque descendent du ciel, rongées et brisées. À mi-distance, un observatoire en ruine et des cercles de pierres gravées de constellations. Sur les côtés, des rochers couverts de cristaux bleus qui encadrent la scène.
Composition : le centre et la droite de l'image sont dégagés et ouverts (un géant se tiendra là) ; rien d'important dans le quart supérieur.
Le sol (roche sombre et cristaux d'étoiles) n'occupe que la bande du bas, sous une ligne d'horizon placée à environ 72 % de la hauteur. Tout le bas de l'image est dégagé : aucun objet, aucune silhouette au premier plan.
Palette : noir, violet cosmique, bleu étoilé, éclats blancs.
Lumière : lumière des étoiles et des nébuleuses, étoiles filantes. Pas de texte, pas de cadre, pas de logo.
```

### boss_nidhogr_sol
```
Texture de sol de dark fantasy peinte, vue exactement du dessus (vue zénithale, à plat, sans perspective),
format carré 1024x1024, RACCORDABLE SANS COUTURE sur les quatre bords (seamless tileable texture).
Roche sombre d'un sommet montagneux, fines fissures, petits éclats de cristal bleu et violet qui scintillent comme des étoiles, poussière d'étoile argentée répartie partout.
Éclairage neutre et uniforme, sans ombre portée marquée et sans point lumineux dominant.
Aucun objet gros, aucun personnage, aucun motif qui se remarque quand on répète l'image.
Palette : noir, violet, bleu étoilé, paillettes blanches.
Pas de texte, pas de cadre.
```

---

## 7. L'Avatar du Sang Originel

### boss_avatar_sang_fond
```
Illustration de dark fantasy peinte, très détaillée, style peinture numérique de jeu vidéo.
Format paysage 16:9 (1920x1080).
Décor de fond pour un champ de bataille, vu à hauteur d'homme, SANS AUCUN personnage, aucune créature, aucune silhouette.
Un sanctuaire antique en ruine au bord d'un lac rouge rubis parfaitement lisse, sous une lune rouge immense posée bas sur l'horizon : au loin, des temples à degrés et des autels de pierre noire couverts d'épines de cristal grenat. À mi-distance, des cascades d'eau rouge rubis qui tombent de falaises noires dans le lac. Sur les côtés, de grandes colonnes de pierre noire couronnées d'épines de cristal rouge qui encadrent la scène.
Composition : le centre et la droite de l'image sont dégagés et ouverts (un géant se tiendra là), la lune juste au-dessus de l'horizon ; rien d'important dans le quart supérieur (ciel nocturne pourpre).
Le sol (pierre noire polie, cristaux grenat) n'occupe que la bande du bas, sous une ligne d'horizon placée à environ 72 % de la hauteur. Tout le bas de l'image est dégagé : aucun objet, aucune silhouette au premier plan.
Palette : rouge rubis, grenat, noir, pourpre.
Lumière : nuit, lueur rouge de la lune et du lac. Pas de texte, pas de cadre, pas de logo.
```

### boss_avatar_sang_sol
```
Texture de sol de fantasy peinte, vue exactement du dessus (vue zénithale, à plat, sans perspective),
format carré 1024x1024, RACCORDABLE SANS COUTURE sur les quatre bords (seamless tileable texture).
Pierre noire polie et fissurée, petits cristaux grenat et rubis qui affleurent dans les fissures, fine poussière rouge sombre, quelques reflets pourpres.
Éclairage neutre et uniforme, sans ombre portée marquée et sans point lumineux dominant.
Aucun objet gros, aucun personnage, aucun motif qui se remarque quand on répète l'image.
Palette : noir, grenat, rubis, pourpre.
Pas de texte, pas de cadre.
```
