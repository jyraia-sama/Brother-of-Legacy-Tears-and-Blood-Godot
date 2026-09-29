# Prompts ChatGPT : portraits des familiers (Ménagerie)

40 portraits à créer, en **5 planches** (31 à 35). Tu me donnes les planches, je les découpe et je range chaque image dans `assets/familiers/`.

**Tant qu'une image n'existe pas, le jeu affiche un médaillon coloré avec l'initiale** : rien ne casse.

## Mode d'emploi

1. Colle le **BLOC COMMUN** puis la liste de la planche. **Une planche par message.**
2. Enregistre sous le nom indiqué (`planche_31.png`...), sans recadrer.
3. Envoie-moi les planches : je lance `python3 outils/decouper_planche.py planche_31.png <ids...> --familiers`.

**Couleurs d'aura** : Feu = rouge-orange, Nature = vert, Eau = bleu, Ténèbres = violet, Sacré = or-blanc, Neutre = gris argenté.

---

## BLOC COMMUN (à coller à chaque fois)

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

STYLE : peinture numérique dark fantasy très détaillée, éclairage dramatique, même style pour toutes les créatures, silhouettes lisibles même en petit. Plus la créature est rare (indiqué entre crochets), plus elle est majestueuse et lumineuse.

Contenu des cases, dans l'ordre :
```

---

## Planche 31 → `planche_31.png`

```
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

```
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

---

## Planche 33 → `planche_33.png`

```
1. [R] lynx au pelage gris-bleu sombre, flocons noirs tourbillonnant, yeux glacés (aura Eau)
2. [R] vieille tortue à carapace couverte de mousse et de petites fleurs, regard sage (aura Eau)
3. [R] mouette blanche fantomatique aux ailes translucides, gouttes d'eau lumineuses (aura Eau)
4. [R] belette rouge sombre, fine et vive, une bague volée dans la gueule (aura Ténèbres)
5. [R] bouc noir aux cornes torsadées, yeux violets, page de grimoire dans la bouche (aura Ténèbres)
6. [SR] grande chouette grise aux plumes de pierre tombale, yeux violets lumineux, parchemin dans les serres (aura Ténèbres)
7. [SR] salamandre de lave rouge-orange au corps en fusion, gouttes de magma (aura Feu)
8. [SR] petit golem de pierre rose et grise haut comme un chat, runes lumineuses sur le torse (aura grise argentée)
9. [SR] feu follet bleu-blanc en forme de petite flamme avec des yeux, flottant au-dessus d'un tertre (aura Sacré)
```

Fichiers : 1 = `lynx_neiges_noires` (Lynx des Neiges Noires), 2 = `tortue_moussue` (Tortue Moussue), 3 = `mouette_spectrale` (Mouette Spectrale), 4 = `belette_sang` (Belette de Sang), 5 = `bouc_maudit` (Bouc Maudit), 6 = `chouette_sepulcrale` (Chouette Sépulcrale), 7 = `salamandre_ardente` (Salamandre Ardente), 8 = `golem_poche` (Golem de Poche), 9 = `feu_follet` (Feu Follet)

Commande : `python3 outils/decouper_planche.py planche_33.png lynx_neiges_noires tortue_moussue mouette_spectrale belette_sang bouc_maudit chouette_sepulcrale salamandre_ardente golem_poche feu_follet --familiers`

---

## Planche 34 → `planche_34.png`

```
1. [SR] poulain-cheval d'eau à la crinière d'algues et au corps d'eau sombre (aura Eau)
2. [SR] corneille noire aux trois yeux violets, plumes ornées de perles et d'os (aura Ténèbres)
3. [SR] petit coffre au trésor vivant avec des dents et une langue pendante, pièces d'or qui débordent, air espiègle (aura grise argentée)
4. [SR] chat sans poils doré aux bijoux égyptiens, coiffe de pharaon, regard mystérieux (aura Sacré)
5. [SR] ours brun zombie à moitié décharné, os visibles, yeux verdâtres (aura Ténèbres)
6. [SSR] jeune wyverne écarlate aux ailes membraneuses déployées, crachant une petite flamme (aura Feu)
7. [SSR] licorne noire à la crinière violette, corne d'ébène fendue qui brille encore (aura Ténèbres)
8. [SSR] petit chien infernal à trois têtes au pelage noir et rouge, crocs enflammés (aura Feu)
9. [SSR] phénix aux plumes gris cendre qui s'embrasent en orange au bout des ailes (aura Feu)
```

Fichiers : 1 = `kelpie_marais` (Kelpie des Marais), 2 = `corneille_prophetesse` (Corneille Prophétesse), 3 = `mimic_apprivoise` (Mimic Apprivoisé), 4 = `chat_sphinx` (Chat-Sphinx), 5 = `ours_mort_vivant` (Ours Mort-Vivant), 6 = `wyverneau_ecarlate` (Wyverneau Écarlate), 7 = `licorne_dechue` (Licorne Déchue), 8 = `cerbere_nain` (Cerbère Nain), 9 = `phenix_cendre` (Phénix Cendré)

Commande : `python3 outils/decouper_planche.py planche_34.png kelpie_marais corneille_prophetesse mimic_apprivoise chat_sphinx ours_mort_vivant wyverneau_ecarlate licorne_dechue cerbere_nain phenix_cendre --familiers`

---

## Planche 35 → `planche_35.png`

```
1. [SSR] basilic serpent-coq aux écailles de cristal translucide, crête de diamant (aura Sacré)
2. [UR] bébé dragon doré aux écailles anciennes, endormi en boule sur un tas d'or, petite couronne (aura Feu)
3. [UR] kirin majestueux à la crinière de flammes dorées et roses, sabots de lumière (aura Sacré)
4. [UR] serpent de mer colossal bleu nuit sortant des flots en spirale, yeux lumineux (aura Eau)
```

Fichiers : 1 = `basilic_cristal` (Basilic de Cristal), 2 = `dragonnet_primordial` (Dragonnet Primordial), 3 = `kirin_crepuscule` (Kirin du Crépuscule), 4 = `ombre_leviathan` (Ombre de Léviathan)

Commande : `python3 outils/decouper_planche.py planche_35.png basilic_cristal dragonnet_primordial kirin_crepuscule ombre_leviathan --familiers`

---
