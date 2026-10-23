# Prompts ChatGPT : refaire les 18 premiers familiers (planches 31 et 32)

Les familiers des planches 31 et 32 ont été faits avant l'abonnement : on les refait pour qu'ils aient la même qualité que les planches 33 à 35.

**Pour chaque planche :** nouvelle conversation, joins **ta `planche_33.png`** (une des nouvelles planches, pour que les 40 familiers aient la même patte), puis colle la bulle entière. Rends-moi `planche_31.png` et `planche_32.png` : je les découpe et je remplace les anciens portraits.

Mêmes créatures, mêmes places dans la grille qu'avant : rien ne change dans le jeu à part l'image.

---

## Planche 31 → `planche_31.png`
> Joins `planche_33.png`.
```
Crée une planche de portraits d'ANIMAUX FAMILIERS pour les cartes d'un jeu mobile dark fantasy.
Ce sont des compagnons de chasse : des créatures attachantes mais sombres, plus ou moins rares et magiques.

FORMAT, À RESPECTER STRICTEMENT :
- image carrée 1024x1024 ;
- grille parfaitement régulière de 3 colonnes et 3 rangées : 9 cases carrées de taille identique, séparées par un fin trait noir droit ;
- dans chaque case : une seule créature, bien centrée, cadrée en entier, qui ne dépasse JAMAIS de sa case ;
- fond de chaque case : dégradé sombre uni avec une aura colorée lumineuse derrière la créature (couleur indiquée entre parenthèses) ;
- aucun texte, aucun chiffre, aucun nom, aucun cadre de carte, aucune bordure décorative ;
- respecte l'ordre : case 1 en haut à gauche, lecture de gauche à droite, rangée par rangée ;
- s'il y a moins de 9 créatures, laisse les cases restantes entièrement noires.

STYLE : exactement le même style et la même qualité que la planche jointe (même lumière, même finition, même aura) ; peinture numérique dark fantasy très détaillée, éclairage dramatique, même style pour toutes les créatures, silhouettes lisibles même en petit. Plus la créature est rare (indiqué entre crochets), plus elle est majestueuse et lumineuse.

Contenu des cases, dans l'ordre :
1. [N] gros rat gris aux yeux rouges, assis sur un crâne, os dans la gueule (aura Ténèbres)
2. [N] corbeau noir ébouriffé perché sur un casque rouillé, une pièce d'or dans le bec (aura Ténèbres)
3. [N] crapaud vert-brun couvert de mousse, assis dans une flaque d'eau claire, gouttes lumineuses (aura Nature)
4. [N] chauve-souris grise aux ailes brûlées aux bords rougeoyants, braises flottantes (aura Feu)
5. [N] furet brun malicieux portant un petit sac de pièces volées, masque sombre autour des yeux (aura Nature)
6. [N] scarabée à carapace d'or brillant sur un éclat de minerai (aura Sacré)
7. [N] limace translucide bleu-vert qui brille doucement, sur la page d'un vieux livre (aura Eau)
8. [N] chat noir maigre aux yeux jaunes, queue en point d'interrogation, collier de clochette cassée (aura Ténèbres)
9. [N] hibou brun borgne avec une cicatrice, petites lunettes rondes, sur une pile de livres (aura Sacré)
```
Fichiers : 1 = `rat_cryptes` (Rat des Cryptes), 2 = `corbeau_charognard` (Corbeau Charognard), 3 = `crapaud_tourbes` (Crapaud des Tourbes), 4 = `chauve_souris_cendree` (Chauve-souris Cendrée), 5 = `furet_voleur` (Furet Voleur), 6 = `scarabee_dore` (Scarabée Doré), 7 = `limace_luisante` (Limace Luisante), 8 = `chat_noir_errant` (Chat Noir Errant), 9 = `hibou_borgne` (Hibou Borgne)

Commande : `python3 outils/decouper_planche.py planche_31.png rat_cryptes corbeau_charognard crapaud_tourbes chauve_souris_cendree furet_voleur scarabee_dore limace_luisante chat_noir_errant hibou_borgne --familiers`

---

## Planche 32 → `planche_32.png`
> Joins `planche_33.png`.
```
Crée une planche de portraits d'ANIMAUX FAMILIERS pour les cartes d'un jeu mobile dark fantasy.
Ce sont des compagnons de chasse : des créatures attachantes mais sombres, plus ou moins rares et magiques.

FORMAT, À RESPECTER STRICTEMENT :
- image carrée 1024x1024 ;
- grille parfaitement régulière de 3 colonnes et 3 rangées : 9 cases carrées de taille identique, séparées par un fin trait noir droit ;
- dans chaque case : une seule créature, bien centrée, cadrée en entier, qui ne dépasse JAMAIS de sa case ;
- fond de chaque case : dégradé sombre uni avec une aura colorée lumineuse derrière la créature (couleur indiquée entre parenthèses) ;
- aucun texte, aucun chiffre, aucun nom, aucun cadre de carte, aucune bordure décorative ;
- respecte l'ordre : case 1 en haut à gauche, lecture de gauche à droite, rangée par rangée ;
- s'il y a moins de 9 créatures, laisse les cases restantes entièrement noires.

STYLE : exactement le même style et la même qualité que la planche jointe (même lumière, même finition, même aura) ; peinture numérique dark fantasy très détaillée, éclairage dramatique, même style pour toutes les créatures, silhouettes lisibles même en petit. Plus la créature est rare (indiqué entre crochets), plus elle est majestueuse et lumineuse.

Contenu des cases, dans l'ordre :
1. [N] petit lézard rouge-orange aux écailles incandescentes sur une roche fumante (aura Feu)
2. [N] araignée noire et violette sur une toile scintillante de rosée (aura Ténèbres)
3. [N] chien bâtard maigre au pelage pelé, oreille déchirée, regard fidèle, collier de corde (aura grise argentée)
4. [R] loup au pelage gris cendre, braises dans la fourrure, yeux orange (aura Feu)
5. [R] renard blanc translucide et spectral, trois queues vaporeuses (aura Ténèbres)
6. [R] serpent noir à écailles d'onyx polies, veines de minerai brillant sur le corps (aura Ténèbres)
7. [R] faucon aux plumes rouge sang, serres acérées, en plein cri (aura Feu)
8. [R] sanglier massif couvert de cicatrices, défenses cerclées de fer, groin dans la terre (aura Nature)
9. [R] blaireau trapu aux griffes énormes couvertes de terre et de pépites (aura Nature)
```
Fichiers : 1 = `lezard_braises` (Lézard des Braises), 2 = `araignee_tisseuse` (Araignée Tisseuse), 3 = `chien_galeux` (Chien Galeux), 4 = `loup_cendres` (Loup des Cendres), 5 = `renard_fantome` (Renard Fantôme), 6 = `serpent_onyx` (Serpent d'Onyx), 7 = `faucon_sanglant` (Faucon Sanglant), 8 = `sanglier_balafre` (Sanglier Balafré), 9 = `blaireau_fouisseur` (Blaireau Fouisseur)

Commande : `python3 outils/decouper_planche.py planche_32.png lezard_braises araignee_tisseuse chien_galeux loup_cendres renard_fantome serpent_onyx faucon_sanglant sanglier_balafre blaireau_fouisseur --familiers`
