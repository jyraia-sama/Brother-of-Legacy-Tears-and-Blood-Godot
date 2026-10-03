# Prompts ChatGPT : la famille du Bélier (Sanctuaire secret, v0.34.0)

Trois boss secrets, transformés à partir de **vos photos**, dans le style des portraits et des figurines du jeu :

| Fichier | Personnage | Élément · rôle | Thème |
|---|---|---|---|
| `alysse_etoile` | **Alysse, l'Étoile du Bélier** | Ténèbres · assassin | rapide et espiègle, pluie d'étoiles, constellation du Bélier |
| `loucas_belier` | **Loucas, le Bélier Ardent** | Feu · guerrier | fonce comme un bélier, cornes de braise, « Même pas mal ! » |
| `anais_toison` | **Anaïs, Reine de la Toison d'Or** | Sacré · soutien | la cheffe du foyer, la Toison d'Or qui soigne et protège |

**Accès secret** : dans le menu principal, touche **3 fois rapidement le blason au centre de la barre du haut**
(ou tape `belier` au clavier). Ordre des épreuves : Alysse → Loucas → Anaïs → les trois réunis.

## Conseils pour les photos

- **Une photo par personne**, visage bien visible, de face ou de trois quarts, bien éclairé.
- Fais **chaque personne dans une conversation séparée** (ou un message à la fois) : ChatGPT garde mieux la ressemblance.
- Les enfants restent **à leur âge**, en tenue d'aventurier complète et couvrante : c'est un jeu familial.
- Si ChatGPT refuse de travailler à partir d'une photo, décris la personne en mots (couleur et coupe de cheveux,
  couleur des yeux, lunettes, taches de rousseur…) à la place de « la personne de la photo jointe ».

---

## 1. Les portraits (un par personne) → `alysse_etoile.png`, `loucas_belier.png`, `anais_toison.png`

Joins **la photo de la personne** et **une planche de portraits du jeu déjà réussie** (par exemple `planche_39.png`)
pour le style. Remplace la ligne « PERSONNAGE » par celle de la personne.

```
Transforme la personne de la photo jointe en personnage de jeu mobile dark fantasy, dans EXACTEMENT le même style que la planche de portraits jointe (peinture numérique très détaillée, éclairage dramatique venant du haut à gauche).

IMPORTANT : garde bien la ressemblance du visage (forme du visage, yeux, sourire, cheveux) et son âge réel. C'est un personnage héroïque et bienveillant d'un jeu familial.

FORMAT : image verticale 1024x1536 ; personnage seul, cadré à mi-corps, tête dans le tiers haut, centré ; fond sombre neutre avec une légère lueur derrière lui ; aucun texte, aucun cadre.

PERSONNAGE : (colle la ligne correspondante ci-dessous)
```

- **Alysse** : `une jeune aventurière agile et espiègle, sourire malicieux, tenue de voyageuse légère bleu nuit et violette brodée de petites étoiles argentées, cape courte étoilée, deux petites cornes de bélier argentées dans les cheveux, une dague courbe brillante comme une étoile filante, quelques étoiles qui scintillent autour d'elle`
- **Loucas** : `un jeune guerrier courageux au regard déterminé et au sourire fier, armure légère de cuir et de métal brun-rouge, casque ouvert orné de deux cornes de bélier recourbées aux pointes rougeoyantes comme des braises, gantelets solides, prêt à charger`
- **Anaïs** : `une reine guerrière douce et protectrice, regard bienveillant et assuré, longue cape faite d'une toison dorée lumineuse, armure légère blanche et or, diadème orné de deux petites cornes de bélier dorées, bâton doré surmonté d'une tête de bélier, lumière dorée chaleureuse`

Envoie-moi les trois images : je les recadre et je les mets en place sur les cartes du jeu.

---

## 2. Les figurines (pions de combat) → `figurine_alysse.png`, `figurine_loucas.png`, `figurine_anais.png`

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
Crée un décor de fond en 16:9 (1920x1080) pour un jeu mobile dark fantasy, sans personnage et sans texte : un sanctuaire caché taillé dans la roche, une grande salle chaleureuse éclairée de braseros dorés, au fond une immense tête de bélier sculptée dans la pierre avec des cornes enroulées, une toison d'or suspendue qui brille doucement, la constellation du Bélier qui scintille au plafond, des tapis rouges et des bannières brodées d'un bélier doré. Ambiance de foyer protecteur et majestueux. Style peinture numérique très détaillée, assez sombre au centre pour que des personnages restent lisibles.
```

---

Je m'en occupe ensuite (commandes pour mémoire) :
- portraits : recadrage en carré sur le visage et le buste → `assets/unites/<id>.png`
- figurines : `python3 outils/decouper_miniatures.py figurine_xxx.png --figurines <id>` (une image = une case)
- décor : → `assets/sanctuaire/fond.png`
