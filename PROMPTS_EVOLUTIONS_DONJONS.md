# Prompts ChatGPT : portraits des évolutions et des boss de Donjon

76 portraits à créer : les **64 unités évoluées** (planches 22 à 29) et les **12 boss de Donjon** (planches 29 et 30).
Même méthode que pour les portraits des unités (voir `PROMPTS_PORTRAITS_UNITES.md`) : tu me donnes les planches, je les découpe
et je range chaque portrait dans `assets/unites/`.

**Tant qu'un portrait évolué n'existe pas, le jeu affiche celui de l'unité de base** : rien ne casse.

## Mode d'emploi

1. Reste dans la conversation ChatGPT des portraits (ou joins la planche 01 réussie pour garder le même style).
2. Colle le **BLOC COMMUN** puis la liste de la planche. **Une planche par message.**
3. Enregistre sous le nom indiqué (`planche_22.png`...), sans recadrer.
4. Envoie-moi les planches : je découpe et je branche les portraits.

Pour une évolution, l'idée est : **la même créature, reconnaissable, mais plus grande, plus ornée, plus menaçante**,
avec une aura plus intense. Si tu as le portrait de base sous la main, tu peux le joindre pour que ChatGPT garde la ressemblance.

**Couleurs d'aura** : Feu = rouge-orange, Nature = vert, Eau = bleu, Ténèbres = violet, Sacré = or-blanc, Sang = rouge sang profond.

---

## BLOC COMMUN (à coller à chaque fois)

```
Crée une planche de portraits de personnages pour les cartes d'un jeu mobile dark fantasy.
Ce sont des versions ÉVOLUÉES et des BOSS : plus imposants, plus détaillés, plus menaçants, avec une aura plus intense et des ornements plus riches.

FORMAT, À RESPECTER STRICTEMENT :
- image carrée 1024x1024 ;
- grille parfaitement régulière de 3 colonnes et 3 rangées : 9 cases carrées de taille identique, séparées par un fin trait noir droit ;
- dans chaque case : un seul personnage, cadré buste ou en pied selon sa taille, bien centré, qui ne dépasse JAMAIS de sa case ;
- fond de chaque case : dégradé sombre uni avec une aura colorée lumineuse derrière le personnage (couleur indiquée entre parenthèses) ;
- aucun texte, aucun chiffre, aucun nom, aucun cadre de carte, aucune bordure décorative ;
- respecte l'ordre : case 1 en haut à gauche, lecture de gauche à droite, rangée par rangée.

STYLE : peinture numérique dark fantasy très détaillée, éclairage dramatique, même style pour les 9 personnages, visages et silhouettes lisibles même en petit.

Contenu des 9 cases, dans l'ordre :
```

---

## Planche 22 → `planche_22.png`

```
1. gorille titanesque à la fourrure noire striée de veines violettes lumineuses, armure d'obsidienne hérissée de pointes, poings cerclés de fer (aura Ténèbres)
2. vieux roi nain à la barbe bleue tressée de runes lumineuses, couronne de corail, bouclier runique géant et marteau d'où coule de l'eau (aura Eau)
3. homme-lézard aux écailles dorées étincelantes, armure solaire, lance entourée d'une couronne de lumière (aura Sacré)
4. elfe majestueuse à la peau veinée de lumière dorée, robe de feuillages et de fleurs blanches, couronne de branches, bâton-arbre lumineux (aura Sacré)
5. vieux gobelin archimage en robe grise brodée de runes de feu, chapeau pointu, orbe de braises flottant au-dessus de sa main (aura Feu)
6. elfe sombre en armure de cuir violet et noir, capuche ornée d'argent, deux longues dagues d'améthyste enveloppées de fumée (aura Ténèbres)
7. shogun en armure laquée rouge et or, casque à grandes cornes démoniaques, katana entouré de flammes (aura Feu)
8. paladin en armure blanche et or rayonnante, ailes de lumière dans le dos, grand bouclier gravé d'un soleil (aura Sacré)
9. chevalier en armure noire fendue de lueurs violettes, cape en lambeaux d'ombre, épée longue dévorée par le vide (aura Ténèbres)
```

Fichiers : 1 = `brute_noire_evo` (La Brute Primordiale), 2 = `barbe_bleue_evo` (Barbe-Abysse, Roi Runique), 3 = `lance_doree_evo` (La Lance Solaire), 4 = `nymphe_evo` (La Dryade Éternelle), 5 = `mage_gris_evo` (L'Archimage Cendré), 6 = `dague_violette_evo` (La Dague Crépusculaire), 7 = `samourai_rouge_evo` (Le Shogun Écarlate), 8 = `chevalier_blanc_evo` (Le Paladin Immaculé), 9 = `chevalier_evo` (Chevalier du Néant)

---

## Planche 23 → `planche_23.png`

```
1. elfe archère en cape de mousse et d'écorce, arc vivant fait de branches fleuries, flèches aux pointes d'épines (aura Nature)
2. sorcier en robe noire et violette ornée de crânes, visage caché sous la capuche, deux orbes de ténèbres flottants (aura Ténèbres)
3. grand prêtre en robe blanche et or, mitre dorée, halo lumineux, masse sacrée rayonnante (aura Sacré)
4. squelette colosse en armure d'os et de fer noir, épée à deux mains dentelée, yeux de flammes violettes (aura Ténèbres)
5. rat monstrueux couronné d'os, fourrure galeuse verdâtre, nuage de peste autour de lui (aura Nature)
6. chef gobelin couvert de butin et de bijoux volés, dague courbe et cape de fourrure (aura Nature)
7. grand loup gris argenté couvert de cicatrices, crinière épaisse, yeux dorés (aura Nature)
8. zombie géant boursouflé, chair verdâtre cousue, chaînes rouillées autour des bras (aura Ténèbres)
9. bandit en long manteau noir et foulard rouge, deux couteaux, sourire cruel (aura Nature)
```

Fichiers : 1 = `archer_evo` (Archère des Bois Anciens), 2 = `mage_evo` (Archisorcier des Ombres), 3 = `clerc_evo` (Hiérophante Sacré), 4 = `squelette_evo` (Champion Squelette), 5 = `rat_geant_evo` (Rat-Roi Pestilent), 6 = `gobelin_evo` (Chef Pillard Gobelin), 7 = `loup_gris_evo` (Loup Alpha), 8 = `zombie_evo` (Colosse Putride), 9 = `bandit_evo` (Seigneur des Routes)

---

## Planche 24 → `planche_24.png`

```
1. araignée géante noire et verte phosphorescente, crochets qui suintent un venin lumineux (aura Nature)
2. chauve-souris vampire géante aux ailes immenses déchirées, crocs sanglants, yeux rouges (aura Ténèbres)
3. limace colossale translucide bleue remplie d'os, bave acide fumante (aura Eau)
4. corbeau géant aux plumes de fumée noire, trois yeux luisants, bec d'argent (aura Ténèbres)
5. sanglier monstrueux au dos de lave refroidie, défenses incandescentes, braises dans la fourrure (aura Feu)
6. brigand colossal et bedonnant, gros gourdin clouté, chope de bière à la ceinture (aura Nature)
7. grand slime bleu translucide et brillant portant une petite couronne dorée, bulles de lumière à l'intérieur (aura Eau)
8. hyène au pelage tacheté de braises, crinière de flammes, crocs incandescents (aura Feu)
9. femme-serpent aux écailles bleu glacé, capuchon de cobra, crache un jet d'eau gelée (aura Eau)
```

Fichiers : 1 = `araignee_venin_evo` (Araignée Nécrotoxique), 2 = `chauve_souris_vampire_evo` (Seigneur Chiroptère), 3 = `limace_acide_evo` (Limace Dévoreuse), 4 = `corbeau_maudit_evo` (Corbeau Funeste), 5 = `sanglier_sauvage_evo` (Sanglier des Braises), 6 = `brigand_evo` (Cogneur des Tavernes), 7 = `slime_evo` (Slime Royal), 8 = `hyene_des_sables_evo` (Hyène Ardente), 9 = `serpent_crache_evo` (Naga Cracheuse)

---

## Planche 25 → `planche_25.png`

```
1. moine en robe noire et rouge, chapelet de crânes, livre de prières ensanglanté (aura Ténèbres)
2. vautour géant au cou décharné, plumes noires et os apparents, bec crochu ensanglanté (aura Nature)
3. grand esprit violet déchaîné au visage hurlant, tourbillon d'objets et de meubles autour de lui (aura Ténèbres)
4. chef orc massif à la peau vert sombre, armure de fer et de crânes, grande hache de guerre (aura Feu)
5. loup-garou géant au pelage noir et rouge, yeux rouges, lune de sang derrière lui, griffes immenses (aura Feu)
6. spectre royal de glace bleue, couronne de stalactites, voile de neige tourbillonnante (aura Eau)
7. golem de pierre blanche gravée de runes dorées rayonnantes, halo au-dessus de la tête (aura Sacré)
8. harpie couronnée aux grandes ailes vert émeraude, serres dorées, vent qui tourbillonne (aura Nature)
9. chevalier en armure rouillée fendue d'où s'échappe une fumée noire, lance brisée reforgée d'ombre (aura Ténèbres)
```

Fichiers : 1 = `moine_dechu_evo` (Abbé Maudit), 2 = `vautour_charognard_evo` (Vautour Nécrophage), 3 = `esprit_frappeur_evo` (Poltergeist Furieux), 4 = `orc_guerrier_evo` (Chef de Guerre Orc), 5 = `loup_garou_evo` (Lycan de la Lune Rouge), 6 = `spectre_glacial_evo` (Spectre de l'Hiver Éternel), 7 = `golem_pierre_evo` (Golem Sanctifié), 8 = `harpie_evo` (Harpie Reine des Vents), 9 = `chevalier_rouille_evo` (Chevalier de Fer Maudit)

---

## Planche 26 → `planche_26.png`

```
1. druidesse aux cheveux de lierre fleuri, cornes de bois de cerf, bâton de racines lumineuses (aura Nature)
2. troll gigantesque couvert de mousse, d'algues et de champignons, massue en tronc d'arbre (aura Eau)
3. gargouille de pierre bleu nuit aux ailes déployées, éclairs qui courent sur sa peau (aura Eau)
4. assassin en armure noire à capuche, masque d'argent, lames jumelles d'ombre (aura Ténèbres)
5. cyclope gigantesque en armure de bronze, œil flamboyant, massue de pierre (aura Feu)
6. minotaure adulte massif aux cornes immenses, armure de guerre, hache à double tranchant enflammée (aura Feu)
7. banshee couronnée en robe bleue spectrale déchirée, longs cheveux flottants, cri glacé (aura Eau)
8. centaure en armure dorée et rouge, arc long enflammé, crinière de feu (aura Feu)
9. démon gardien colossal aux cornes de lave, bouclier-tour de flammes, armure noire (aura Feu)
```

Fichiers : 1 = `sorciere_bois_evo` (Grande Druidesse des Bois), 2 = `troll_marais_evo` (Troll Ancestral des Marais), 3 = `gargouille_evo` (Gargouille des Tempêtes), 4 = `assassin_ombre_evo` (Maître Assassin), 5 = `cyclope_evo` (Cyclope Titan), 6 = `minotaure_jeune_evo` (Seigneur Minotaure), 7 = `banshee_evo` (Reine des Lamentations), 8 = `centaure_guerrier_evo` (Centaure Seigneur de Guerre), 9 = `demon_inf_evo` (Gardiens de l'Abîme)

---

## Planche 27 → `planche_27.png`

```
1. titan d'obsidienne noire aux fissures de lave violette, poings en cristal tranchant (aura Ténèbres)
2. liche en robe royale noire et verte, couronne d'os, grimoire flottant, âmes qui tourbillonnent (aura Ténèbres)
3. chimère immense à quatre têtes (lion, chèvre, dragon, serpent), ailes membraneuses (aura Nature)
4. séraphin aux six ailes noires, auréole brisée qui brûle de flammes violettes, lance d'ombre (aura Ténèbres)
5. hydre adulte aux cinq têtes, écailles bleu profond, crocs venimeux (aura Eau)
6. seigneur démon fait de feu blanc et orange, couronne de flammes, bras en fusion (aura Feu)
7. impératrice mi-femme mi-araignée, couronne de chitine, huit pattes noires et or, toiles dorées (aura Nature)
8. wyverne immense aux écailles vert émeraude et or, cornes recourbées, dard venimeux (aura Nature)
9. lapin en armure de fortune avec lance-flammes et ceinture d'explosifs, lunettes d'artificier, feux d'artifice derrière (aura Feu)
```

Fichiers : 1 = `golem_obsidienne_evo` (Titan d'Obsidienne), 2 = `liche_mineure_evo` (Liche Majeure), 3 = `chimere_evo` (Chimère Primordiale), 4 = `seraphin_dechu_evo` (Séraphin des Ténèbres), 5 = `hydre_jeune_evo` (Hydre des Abysses), 6 = `demon_flamme_evo` (Seigneur des Flammes), 7 = `reine_araignee_evo` (Impératrice Arachnide), 8 = `wyverne_evo` (Wyverne Ancestrale), 9 = `lapin_pyromane_evo` (Lapin Apocalyptique)

---

## Planche 28 → `planche_28.png`

```
1. dragon colossal aux écailles de néant étoilé, ailes de fumée noire, souffle violet et noir (aura Ténèbres)
2. archange en armure noire et or crépusculaire, quatre ailes noires aux plumes dorées, épée flamboyante (aura Ténèbres)
3. titan des abysses colossal couvert de coraux lumineux, chaînes brisées, trident géant (aura Eau)
4. impératrice liche en robe royale pourpre, grande couronne d'os, sceptre à l'orbe vert, armée d'âmes (aura Ténèbres)
5. grand félin noir aux yeux bleus brûlants, fourrure parcourue de courants d'eau lumineux, neuf queues (aura Eau)
6. chien géant majestueux fait de mousse, de bois et de fleurs lumineuses, bois de cerf sur la tête (aura Nature)
7. phénix gigantesque au plumage de flammes blanches et dorées, couronne solaire, ailes immenses (aura Feu)
8. serpent de mer primordial gigantesque, écailles noires et bleues lumineuses, gueule béante de tourbillon (aura Eau)
9. empereur en armure noire et or reforgée, couronne restaurée brûlant de flammes pourpres, cape royale (aura Ténèbres)
```

Fichiers : 1 = `dragon_ombre_evo` (Dragon du Néant), 2 = `archange_noir_evo` (Archange du Crépuscule), 3 = `titan_abysses_evo` (Titan des Fosses), 4 = `reine_liches_evo` (Impératrice des Liches), 5 = `chat_des_abysses_evo` (Félin du Gouffre), 6 = `chien_sylvestre_evo` (Grand Chien des Bois Sacrés), 7 = `phenix_immortel_evo` (Phénix Solaire Éternel), 8 = `leviathan_abyssal_evo` (Léviathan Primordial), 9 = `empereur_dechu_evo` (L'Empereur Ressuscité)

---

## Planche 29 → `planche_29.png`

```
1. destrier céleste blanc aux six ailes lumineuses, armure dorée, crinière de lumière pure (aura Sacré)
2. colosse en armure de fonte noire fendue de lave, marteau-enclume incandescent, bouclier de magma (aura Feu)
3. élémentaire de feu géant au cœur de magma visible dans la poitrine, couronne de flammes, bras de lave (aura Feu)
4. chasseresse encapuchonnée de mousse et de ronces, arc d'os et de branches, flèches suintant de poison vert (aura Nature)
5. immense femme-arbre pourrissante, visage dans l'écorce, racines noires et champignons luminescents (aura Nature)
6. guerrier-poisson en armure de corail et de coquillages, trident, bouclier de nacre (aura Eau)
7. kraken colossal aux tentacules couverts d'yeux, bec noir, abysses bleu sombre (aura Eau)
8. géant squelettique cagoulé portant des chaînes et un trousseau de clés rouillées, lanterne violette (aura Ténèbres)
9. liche féminine en robe de deuil noire, couronne de lune brisée, mains squelettiques entourées d'âmes (aura Ténèbres)
```

Fichiers : 1 = `cheval_sacre_evo` (Destrier Divin), 2 = `gardien_brasier` (Gardien du Brasier), 3 = `ignaar` (Ignaar, Cœur du Brasier), 4 = `chasseuse_sylve` (Chasseuse de la Sylve), 5 = `mere_racine` (La Mère-Racine Putride), 6 = `sentinelle_corail` (Sentinelle de Corail), 7 = `kraken_fosses` (Le Kraken des Fosses), 8 = `geolier_crypte` (Geôlier de la Crypte), 9 = `morvena` (Morvena, Liche sans Lune)

---

## Planche 30 → `planche_30.png`

```
ATTENTION : pour cette planche seulement, grille de 4 cases seulement (2 colonnes et 2 rangées), format carré 1024x1024.
1. templier en armure blanche souillée de suie, heaume fendu, épée sacrée ternie, cape déchirée (aura Sacré)
2. prophétesse aux yeux bandés d'or, auréole fissurée, vitraux brisés qui flottent autour d'elle (aura Sacré)
3. boucher monstrueux masqué, tablier ensanglanté, énorme couperet, chaînes à crochets (aura Sang)
4. masse vivante de sang coagulé surgissant d'un puits, gueule immense, cœurs qui battent sous la surface (aura Sang)
```

Fichiers : 1 = `templier_profane` (Templier Profané), 2 = `oracle_profane` (L'Oracle Profané), 3 = `boucher_puits` (Le Boucher du Puits), 4 = `hemoragos` (Hémoragos, le Puits Vivant)

---

## Images de décor (facultatives)

Format conseillé **1672 x 941** (16:9), PNG, **sans texte ni personnage**. Dépose-les dans `assets/donjons/` avec exactement ces noms :

| Fichier | Où | Prompt |
|---|---|---|
| `donjons_bg.png` | Écran de choix des Donjons | Dark fantasy painting, 16:9: six dungeon entrances carved into a colossal cliff at night, each glowing a different color (orange lava, green rot, deep blue water, violet shadow, golden light, blood red), mist, no text, no characters |
| `feu.png` | Combats du Brasier Éternel | 16:9 battle arena inside an ancient volcanic forge, rivers of lava, giant anvils, falling embers, wide empty floor, no characters, no text |
| `nature.png` | Combats de la Sylve Putride | 16:9 battle arena in a rotting cursed forest, black roots, glowing toxic mushrooms, green fog, wide empty floor, no characters, no text |
| `eau.png` | Combats des Fosses Englouties | 16:9 battle arena in a sunken city at the bottom of a dark ocean, coral-covered ruins, bioluminescent light, wide empty floor, no characters, no text |
| `tenebres.png` | Combats de la Crypte sans Lune | 16:9 battle arena in pitch-black catacombs, skull niches, violet candle light, chains, wide empty floor, no characters, no text |
| `sacre.png` | Combats du Sanctuaire Profané | 16:9 battle arena in a desecrated celestial temple, broken stained glass, tarnished gold statues, dusty light rays, wide empty floor, no characters, no text |
| `neutre.png` | Combats du Puits de Sang | 16:9 battle arena at the edge of a bottomless well of blood, crimson mist, bone pillars, red glow from below, wide empty floor, no characters, no text |
