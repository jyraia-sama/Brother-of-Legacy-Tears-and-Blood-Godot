# Prompts ChatGPT : la famille du Bélier (Sanctuaire secret, v0.34.1)

Les boss secrets de la famille, **recréés** en personnages du jeu (pas de photo : seulement quelques traits reconnaissables), dans le style des portraits et des figurines :

| Fichier | Personnage | Élément · rôle | Thème |
|---|---|---|---|
| `alysse_etoile` | **Alysse, l'Étoile du Bélier** | Ténèbres · assassin | rapide et espiègle, pluie d'étoiles, constellation du Bélier |
| `loucas_belier` | **Loucas, le Bélier Ardent** | Feu · guerrier | fonce comme un bélier, cornes de braise, « Même pas mal ! » |
| `anais_toison` | **Anaïs, Reine de la Toison d'Or** | Sacré · soutien | la cheffe du foyer, la Toison d'Or qui soigne et protège |
| `laurent_gemeau` | **Laurent, le Gardien Gémeau** | Sacré · tank | le papa, le seul Gémeaux de la famille : il garde la porte d'or avec son Reflet |
| `laurent_reflet` | **Le Reflet de Laurent** | Ténèbres · guerrier | son jumeau d'ombre (boss seulement) : les Gémeaux sont toujours deux |

**Accès secret** : dans le menu principal, touche **3 fois rapidement le blason au centre de la barre du haut**
(ou tape `belier` au clavier). Ordre des épreuves : Alysse → Loucas → Anaïs → Laurent et son Reflet → toute la famille réunie (à quatre).

## Principe : des personnages RECRÉÉS, pas des photos retouchées

Chaque membre de la famille devient un **personnage peint original**, dans le style des portraits du jeu, qui reprend
seulement **quelques traits reconnaissables** (coiffure, couleur des cheveux et des yeux, barbe, lunettes…).
Ce n'est pas une copie du visage : on doit pouvoir dire « tiens, c'est un peu toi », sans que ce soit une photo.

- **Ne joins PAS de photo** à ChatGPT. Joins seulement une planche de portraits du jeu (par exemple `planche_39.png`)
  pour le style.
- Décris la personne **en 3 à 5 traits** dans la ligne « TRAITS » (exemples : « cheveux châtains courts, barbe
  courte poivre et sel, lunettes rectangulaires, regard doux »).
- Une personne par message ; génère 2 ou 3 essais et garde celui qui vous ressemble le plus.
- Les enfants restent à leur âge, en tenue d'aventurier complète : c'est un jeu familial.

---

## 1. Les portraits (un par personne) → `alysse_etoile.png`, `loucas_belier.png`, `anais_toison.png`, `laurent_gemeau.png`, `laurent_reflet.png`

Joins **une planche de portraits du jeu déjà réussie** (par exemple `planche_39.png`), sans photo. Remplace
la ligne « TRAITS » et la ligne « PERSONNAGE » par celles de la personne.

```
Crée un personnage ORIGINAL pour un jeu mobile dark fantasy familial, peint EXACTEMENT dans le même style que la planche de portraits jointe : peinture numérique dark fantasy stylisée, coups de pinceau visibles, éclairage dramatique venant du haut à gauche. Ce n'est PAS une photo et pas un rendu photoréaliste : c'est une illustration de personnage de jeu, comme ceux de la planche.

TRAITS À REPRENDRE (juste ces détails, le reste du visage est inventé) : [3 à 5 traits : coiffure et couleur des cheveux, couleur des yeux, barbe, lunettes, taches de rousseur…]

PERSONNAGE : (colle la ligne correspondante ci-dessous)

FORMAT : image verticale 1024x1536 ; personnage seul, cadré à mi-corps, tête dans le tiers haut, centré ; fond sombre neutre avec une légère lueur derrière lui ; aucun texte, aucun cadre.
```

- **Alysse** : `une jeune aventurière d'environ [âge] ans, agile et espiègle, sourire malicieux, tenue de voyageuse légère bleu nuit et violette brodée de petites étoiles argentées, cape courte étoilée, deux petites cornes de bélier argentées dans les cheveux, une dague courbe brillante comme une étoile filante, quelques étoiles qui scintillent autour d'elle`
- **Loucas** : `un jeune guerrier d'environ [âge] ans, courageux, au regard déterminé et au sourire fier, armure légère de cuir et de métal brun-rouge, casque ouvert orné de deux cornes de bélier recourbées aux pointes rougeoyantes comme des braises, gantelets solides, prêt à charger`
- **Anaïs** : `une reine guerrière douce et protectrice, regard bienveillant et assuré, longue cape faite d'une toison dorée lumineuse, armure légère blanche et or, diadème orné de deux petites cornes de bélier dorées, bâton doré surmonté d'une tête de bélier, lumière dorée chaleureuse`
- **Laurent** : `un gardien protecteur et calme, regard assuré et un léger sourire complice, armure de chevalier bleu acier et argent, grand bouclier rond orné du symbole des Gémeaux (deux silhouettes jumelles côte à côte), épée longue, cape bleu nuit, une douce lumière argentée d'un côté de son visage et une ombre bleutée de l'autre`
- **Le Reflet de Laurent** (joins le portrait de Laurent réussi à la place de la planche, et laisse la ligne TRAITS vide) : `le double du personnage du portrait joint, même silhouette et même allure, mais fait d'ombre : armure noire aux reflets bleu sombre, yeux d'un bleu pâle lumineux, contours qui se dissolvent en fumée, sourire malicieux, comme un reflet dans un miroir sombre`

Envoie-moi les cinq images : je les recadre et je les mets en place sur les cartes du jeu.

---

## 2. Les figurines (pions de combat) → `figurine_alysse.png`, `figurine_loucas.png`, `figurine_anais.png`, `figurine_laurent.png`, `figurine_reflet.png`

Joins **le portrait réussi de la personne** et la **figurine du grand frère** (`pion_aine.png`) pour le rendu.
Une figurine par message. Le fond vert sert à détourer : je le rends transparent automatiquement.

```
Crée la figurine de jeu de plateau de ce personnage (portrait joint), EXACTEMENT dans le même style que la figurine jointe : même rendu peint, même éclairage dramatique venant du haut à gauche, même petit socle rond en pierre sombre sous les pieds.

FORMAT, À RESPECTER STRICTEMENT :
- image verticale 1024x1536 ;
- le personnage en pied, de trois quarts, tourné vers la DROITE de l'image, debout sur son petit socle, entier de la tête au socle, centré, avec de la marge ;
- même visage, même tenue et mêmes couleurs que le portrait joint ;
- fond VERT UNI très vif (#00FF00), sans dégradé, sans ombre portée, sans décor ; aucun vert sur le personnage ;
- aucun texte, aucun chiffre, aucun cadre.
```

---

## 3. Le décor du Sanctuaire (facultatif) → `sanctuaire_fond.png`

Utilisé pour l'écran du Sanctuaire et ses combats. Sans image jointe.

```
Crée un décor de fond en 16:9 (1920x1080) pour un jeu mobile dark fantasy, sans personnage et sans texte : un sanctuaire caché taillé dans la roche, une grande salle chaleureuse éclairée de braseros dorés, au fond une immense tête de bélier sculptée dans la pierre avec des cornes enroulées, une toison d'or suspendue qui brille doucement, de chaque côté de la porte deux statues de gardiens jumeaux, la constellation du Bélier qui scintille au plafond, des tapis rouges et des bannières brodées d'un bélier doré. Ambiance de foyer protecteur et majestueux. Style peinture numérique très détaillée, assez sombre au centre pour que des personnages restent lisibles.
```

---

Je m'en occupe ensuite (commandes pour mémoire) :
- portraits : recadrage en carré sur le visage et le buste → `assets/unites/<id>.png`
- figurines : `python3 outils/decouper_miniatures.py figurine_xxx.png --figurines <id>` (une image = une case)
- décor : → `assets/sanctuaire/fond.png`
