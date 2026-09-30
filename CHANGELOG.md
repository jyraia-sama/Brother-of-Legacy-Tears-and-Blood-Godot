# Journal des mises à jour — Brothers of Legacy : Tears and Blood

Version actuelle : **0.30.1** (2026-09-30)

## v0.30.1 — La figurine du grand frère  (2026-09-30)

- Le PION DU PLATEAU devient une figurine du grand frère Valcendre (armure sombre, manteau bleu au phénix, médaillon de la Larme) : il saute de case en case et se tourne dans le sens de la marche.

## v0.30.0 — Portraits de l'histoire, Kaël invité et Journal  (2026-09-30)

- PORTRAITS DE L'HISTOIRE (planches 36 et 37) : Kaël (jeune, corrompu, libéré), Aldric, Othmar, Corvin, Morvaël, le Frère Masqué, le blason des Valcendre (ton portrait dans les dialogues), l'Ermite, le moine, la veuve, le commandant, la résistante. Ils apparaissent dans les dialogues.
- Nouveaux portraits d'unités : Kaël Valcendre (Légende), les boss Morvaël, le Frère Masqué, le Seigneur des Cendres, l'Héritier Maudit et l'Empereur Déchu.
- KAËL À TES CÔTÉS : dans les chapitres où il est avec toi (tout l'Acte I, la fin de l'Acte X, l'Acte XII après le duel, la fin de l'Acte XIII), Kaël combat en unité invitée, en plus de ton équipe (6e place, entre l'Avant et l'Arrière). Jeune et impulsif dans l'Acte I (Flamme Noire Incontrôlée), puis libéré à la fin de l'histoire.
- JOURNAL DE L'HISTOIRE (bouton en bas à gauche de l'Histoire principale) : revois toutes les scènes déjà vues, Acte par Acte.

## v0.29.0 — Les dialogues de l'histoire et le nom Valcendre  (2026-09-30)

- DIALOGUES DE L'HISTOIRE : une scène s'affiche au début de chaque chapitre (et à la fin des chapitres importants), pour les 13 Actes, selon le scénario : la séparation des frères, le Frère Masqué, la réunion, le duel, la vraie fin… Portrait, nom et texte qui s'écrit lettre par lettre ; clic ou Espace pour continuer, « Passer » pour sauter la scène. Chaque scène ne s'affiche qu'une fois.
- NOM DE FAMILLE : chaque joueur appartient à la lignée des Valcendre. Le pseudo devient le prénom : « Neo » s'affiche « Neo Valcendre » (menu, Mon héros, Social, Guilde, Arène, Arène classée, Marche). Le pseudo seul sert toujours pour se connecter et ajouter un ami.
- Prompts ChatGPT des portraits des personnages (Kaël, Kaël corrompu, Kaël libéré, Aldric, Othmar, Corvin, Morvaël, le Frère Masqué, le blason des Valcendre…) et des images définitives de l'Acte XIII : PROMPTS_PERSONNAGES.md.

## v0.28.0 — L'Acte caché et la vraie fin  (2026-09-30)

- ACTE XIII CACHÉ — « Le Sang et la Larme » : il apparaît (bouton rouge et bleu en bas de l'Histoire principale) une fois l'Acte XII terminé. 6 chapitres, plus difficiles que l'Acte XII, dans le Sceau des Frères, contre les souvenirs des Héritiers dévorés. Boss final : Morvaël, la Soif Première (UR, deux phases).
- FIN DE L'ACTE XII : épilogue de la fin douce-amère et titre « Gardien du Sceau » (donné aussi aux joueurs qui avaient déjà terminé l'Acte XII).
- VRAIE FIN (Acte XIII terminé) : épilogue « Les Frères Réunis » et toutes les récompenses : Kaël Valcendre, Héros de Légende UR jouable et unique (Flamme Noire Maîtrisée, Lames Jumelles, Le Rire Retrouvé…) ; le titre « Les Frères Réunis » ; les deux Échos uniques du Sceau des Frères (la Larme et le Sang, Légendaires 6★, set à 2 pièces : ATK +15 % et PV +15 %) ; 1 000 gemmes et 3 Coffres Royaux.
- Le set des Frères ne s'obtient qu'avec la vraie fin (ni en combat, ni à l'Atelier). Scénario complet : HISTOIRE.md.
- Images provisoires de l'Acte XIII (écran des chapitres et plateau), à remplacer par des versions ChatGPT.

## v0.27.1 — Donjons en continu  (2026-09-30)

- DONJONS : les 4 combats s'enchaînent maintenant sans interruption. Entre deux vagues, un court message « Combat 1 / 4 gagné ! Prochain : … » s'affiche puis le combat suivant démarre tout seul (les PV restants sont toujours conservés). Le bilan ne s'affiche qu'à la fin de l'expédition (ou en cas d'échec).

## v0.27.0 — Arène classée en temps réel  (2026-09-30)

- ARÈNE CLASSÉE EN TEMPS RÉEL (bouton « Arène classée » dans l'Arène) : combats MANUELS contre un autre joueur connecté, avec ton équipe du Deck (niveaux, étoiles et Échos réels).
- Combat unité par unité, dans l'ordre de Vitesse : quand c'est au tour d'une de tes unités, choisis Attaque ou un sort, puis la cible (les corps à corps visent l'Avant, la Provocation force la cible). Minuteur de 15 s : sinon l'unité agit toute seule. Les sorts se rechargent quelques tours après usage. 20 tours maximum, puis victoire au pourcentage de PV restants.
- Trouver un adversaire : file d'attente (même rang d'abord, puis élargie avec l'attente) ou défi direct d'un ami connecté (compte aussi pour le classement). Les deux joueurs doivent avoir la même version du jeu.
- Classement Elo (1000 points au départ), rangs Bronze, Argent (1100), Or (1250), Platine (1400), Diamant (1550) et Légende (1700). Saisons de 4 semaines : récompense de 40 à 600 gemmes, et un titre à partir de l'Or (Gladiateur d'Or / de Platine / de Diamant, Légende de l'Arène).
- Joueur absent : l'IA joue à sa place au bout de 40 s, et s'il a quitté le jeu depuis 1 minute, victoire par forfait. On peut aussi abandonner (défaite). Un combat interrompu (jeu fermé) peut être repris.
- À FAIRE UNE FOIS : lancer supabase/04_arene_classee.sql dans Supabase (voir SUPABASE.md).

## v0.26.3 — Familiers illustrés au Bestiaire  (2026-09-30)

- BESTIAIRE : les familiers qui ont un portrait s'affichent comme les héros : illustration sur toute la carte (nom et rareté en bas, pastille d'élément) et grande illustration dans la fiche. Les autres gardent leur médaillon en attendant leur portrait.

## v0.26.2 — Corrections Bestiaire et Invocation  (2026-09-30)

- MENU ADMIN : l'option « Bestiaire entièrement débloqué » révèle aussi les 40 familiers dans l'onglet Familiers du Bestiaire.
- AUTEL D'INVOCATION : le nombre de Sceaux Sauvages s'affiche maintenant en haut à droite, à côté de l'or et des Éclats (et plus dans le panneau du Pacte Sauvage).

## v0.26.1 — Portraits des familiers (1/2)  (2026-09-29)

- Portraits des 18 premiers familiers (planches 31 et 32 : du Rat des Cryptes au Blaireau Fouisseur), avec un anneau à la couleur de leur rareté. Les autres gardent leur médaillon en attendant leurs planches.
- Les portraits des familiers sont compressés (environ 35 Ko chacun) pour ne pas alourdir la version web.

## v0.26.0 — La Ménagerie : familiers et terrains de chasse  (2026-09-29)

- LA MÉNAGERIE (bouton en bas de l'écran Aventure) : les héros N et R ont enfin un vrai rôle ! Une équipe de chasse = un héros N ou R (hors équipe de combat) + un familier, envoyés sur un terrain de chasse. Le butin s'accumule en temps réel, même jeu fermé, jusqu'à 12 h de stock : viens le récolter.
- 6 TERRAINS DE CHASSE débloqués avec le niveau de compte : Plaines Cendrées (or et coffres), Bibliothèque Engloutie (tomes d'XP), Sources Vives (élixirs de stamina), Cimetière des Échos (Poussière d'Écho), Veines Élémentaires (ressources d'évolution de l'élément du familier), Nids Sauvages (Sceaux Sauvages et parfois un Éclat). Butin commun, rare ou épique.
- 2 équipes de chasse au départ, puis une de plus aux niveaux de compte 10, 20 et 30 (5 au maximum). Le héros part en chasse et gagne de l'XP ; il est « En chasse » (hors équipe) jusqu'à son rappel.
- 40 FAMILIERS (12 N, 11 R, 9 SR, 5 SSR, 3 UR) avec leurs stats de farming : Récolte (quantité), Célérité (temps entre deux butins), Fortune (butins rares et épiques), terrain préféré (+25 %) et un talent (Double prise, Flair sauvage, Pie voleuse, Porte-bonheur, Pas léger, Mentor, Nomade). Ils gagnent des niveaux en chassant et s'éveillent jusqu'à 5 étoiles avec un doublon ; un familier inutile peut être libéré contre de l'or.
- Le héros compte aussi : rareté R (+10 %), niveau, étoiles et rôle favori de la zone (+20 %). Avant de partir, la fenêtre « Nouvelle chasse » montre une estimation du butin en 12 h.
- PACTE SAUVAGE à l'Autel d'Invocation : invocation de familiers avec des Sceaux Sauvages (x1 / x10 avec un SR garanti, SSR garanti au plus tard toutes les 40 invocations). Les Sceaux Sauvages se trouvent dans les coffres (35 %) et sur les Mimics (2) de l'Aventure, aux Nids Sauvages, au Marché du jour et dans la récompense de connexion du 3e jour. Premier passage à la Ménagerie : un familier et 5 Sceaux offerts.
- BESTIAIRE : nouvel onglet « Familiers » (40 fiches, découvertes en les obtenant). L'Aide et une astuce de première visite expliquent la Ménagerie.
- Prompts ChatGPT des 40 portraits de familiers : PROMPTS_FAMILIERS.md (planches 31 à 35). En attendant, un médaillon coloré avec l'initiale s'affiche.

## v0.25.0 — Mimics, Échos 1-3-5 en % et triche remise à zéro  (2026-09-29)

- MENU ADMIN : les options de triche ne sont plus jamais enregistrées (ni dans la sauvegarde, ni en ligne). Elles sont toutes désactivées à chaque lancement du jeu, et les anciennes triches restées dans une sauvegarde sont effacées.
- MIMICS : dans l'Aventure principale (tous les Actes et chapitres), chaque coffre a 25 % de chance d'être un Mimic ! Un coffre vivant, seul mais bien plus coriace qu'un monstre ordinaire. Le combat ne coûte pas de stamina ; une fois vaincu, il rend le double du trésor d'un coffre, plus d'or et d'XP, et 90 % de chance de lâcher un Écho. Un coffre reste Mimic tant qu'il n'est pas vaincu.
- Le Mimic est un monstre non invocable, qu'on ne rencontre que dans les coffres (visible au Bestiaire une fois affronté).
- ÉCHOS SANGUINS : la stat principale des emplacements 1 (Crâne), 3 (Plaie) et 5 (Âme) peut maintenant être en valeur fixe OU en % (ATK / ATK %, DEF / DEF %, PV / PV %), tirée au hasard. Les Échos déjà obtenus ne changent pas. L'Atelier du Reliquaire permet aussi de choisir la version %.

## v0.24.0 — Un secret  (2026-09-29)

- Un secret se cache désormais dans le menu principal… Un petit hommage à celui qui a donné l'envie de créer ce jeu. À toi de le trouver !

## v0.23.0 — Guide des premiers pas  (2026-09-29)

- PREMIERS PAS : un guide de 9 étapes pour les nouveaux joueurs, affiché à gauche du menu principal (découvrir le Deck, premier combat, chapitre 1, première invocation, équipe complète, équiper un Écho, l'améliorer, réclamer une quête, terminer l'Acte I).
- Le bouton du menu concerné par l'étape brille, « Y aller » y mène directement, et chaque étape rapporte une récompense (or, gemmes, tome, Éclats…). Un Écho est offert pour l'étape « Équipe un Écho ».
- Les étapes se valident toutes seules d'après la partie : un joueur déjà avancé n'a plus qu'à réclamer.
- ASTUCES : une courte explication s'affiche à la première visite du Deck, de l'Invocation, des Échos, de la Fusion, du Reliquaire, de l'Aventure et du plateau.
- Message d'accueil au tout premier passage sur le menu. Le guide peut être masqué (×) ; Paramètres → « Réafficher » remet le guide et les astuces.

## v0.22.0 — Quêtes, Succès, Boutique, Mon héros et Aide  (2026-09-29)

- QUÊTES (icône en bas du menu) : récompense de connexion quotidienne (cycle de 7 jours, jusqu'à 100 gemmes et un Éclat), 5 quêtes du jour et 5 quêtes de la semaine (les mêmes pour tous) avec or, gemmes et objets, et un coffre bonus quand toutes sont terminées. La progression se note toute seule en jouant.
- SUCCÈS : 15 objectifs à long terme à 4 paliers (combats, chapitres, Bestiaire, invocations, Tours, Donjons, Boss de Monde, Marche, Échos +15…). Chaque palier donne des gemmes ; le dernier débloque un titre.
- BOUTIQUE : Marché du jour (6 offres en or qui changent chaque jour), Comptoir des gemmes (recharge de stamina, élixirs, Éclats, coffres, tomes, Cœurs de Sang, Pierre d'Éveil, avec limites par jour ou par semaine) et onglet des packs de gemmes (argent réel : bientôt).
- MON HÉROS (portrait du menu) : fiche complète du héros de départ, profil (niveau de compte, titre à afficher), statistiques de la partie et résumé de la collection.
- AIDE (bouton « ? ») : guide du jeu en 8 sections (premiers pas, ressources, combat, unités, Échos, modes, en ligne, téléphone).
- Pastilles sur les icônes Quêtes et Succès quand une récompense attend.

## v0.21.2 — Vitesse de combat, e-mail mémorisé, Arène  (2026-09-29)

- Combat : la vitesse choisie (x1, x2, x4) est gardée pour les combats suivants (le Boss de Monde garde la sienne).
- Compte : l'adresse e-mail de la dernière connexion reste remplie après une déconnexion ; il ne reste que le mot de passe à taper.
- Arène : un joueur sans équipe de défense n'apparaissait jamais comme adversaire. En ouvrant l'Arène, la défense est maintenant enregistrée automatiquement (défense préparée, sinon l'équipe du Deck).
- Arène : les unités évoluées (niveau jusqu'à 40) sont acceptées dans la défense (relancer supabase/02_arene.sql dans Supabase).

## v0.21.1 — Portraits évolués : planche 22  (2026-09-29)

- 9 premiers portraits des unités évoluées : La Brute Primordiale, Barbe-Abysse, La Lance Solaire, La Dryade Éternelle, L'Archimage Cendré, La Dague Crépusculaire, Le Shogun Écarlate, Le Paladin Immaculé, Le Chevalier du Néant.

## v0.21.0 — Version mobile  (2026-09-28)

- Jeu jouable sur téléphone et tablette : l'interface est agrandie automatiquement sur mobile (+50 %). Nouveau réglage « Taille de l'interface » dans les Paramètres (Automatique, Normale, Grande, Très grande).
- Défilement au doigt dans toutes les listes (Deck, Bestiaire, Échos, Reliquaire…), avec de l'élan. Un glissement n'appuie plus sur la carte ou le bouton de départ.
- Les écrans trop larges pour la taille choisie se réduisent juste assez pour tenir entièrement (rien n'est coupé sur les bords).
- Le jeu s'installe comme une appli (Android et iPhone, écran d'accueil) : icône, plein écran et paysage. Sur navigateur mobile, plein écran automatique au premier appui (désactivable).
- En portrait, un message demande de tourner le téléphone. Clavier virtuel activé pour les champs de texte (compte, sauvegarde).
- Guide : MOBILE.md.

## v0.20.4 — Jeu en ligne réparé sur la version web  (2026-09-28)

- Correction : sur la version web, l'Arène, le Social, le Compte et la sauvegarde en ligne affichaient « Connexion au serveur impossible ». Le navigateur décompressait déjà les réponses du serveur et le jeu essayait de le refaire, ce qui faisait échouer les requêtes.
- Le message d'erreur réseau indique maintenant un numéro d'erreur, pour faciliter le diagnostic.

## v0.20.3 — Récapitulatif des améliorations d'Échos  (2026-09-28)

- Fenêtre d'amélioration des Échos : le bouton « +1 » affiche son coût en or.
- Récapitulatif après chaque amélioration : niveaux gagnés, tentatives et or dépensé, stat principale avant → après, stats secondaires nouvelles ou renforcées (avec le gain).
- Écran des Échos : le bouton s'appelle simplement « Améliorer ».

## v0.20.2 — Amélioration des Échos jusqu'au +9  (2026-09-28)

- Échos Sanguins : nouveau bouton « Jusqu'à +9 » dans la fenêtre d'amélioration (avec +3, +6, +12 et +15).

## v0.20.1 — Symboles corrigés et fenêtre d'amélioration des Échos  (2026-09-28)

- Correction : les symboles (★ ⚔ ☠ ✦ ← → ✔…) s'affichaient en petits carrés sur certains ordinateurs et sur la version web, dans beaucoup de menus. Le jeu embarque maintenant une police de symboles (DejaVu Sans).
- Échos Sanguins : le bouton « Améliorer » ouvre une fenêtre d'amélioration : stat principale actuelle → au niveau suivant, prochain palier, chance de réussite et coût.
- Bouton « +1 » pour une tentative, et « Jusqu'à +3 / +6 / +12 / +15 » pour enchaîner les tentatives jusqu'à réussir (arrêt possible à tout moment, ou quand l'or manque), avec le coût moyen estimé.
- Une barre de chargement se remplit avant chaque résultat (option « Rapide ») et l'historique des tentatives s'affiche dans la fenêtre.

## v0.20.0 — Expéditions : la Marche Maudite et la Compagnie  (2026-09-28)

- Nouveau menu Expéditions (Aventure → Expédition) avec deux modes et une boutique.
- La Marche Maudite : une expédition roguelike par jour, la même pour tous. On choisit jusqu'à 5 unités et on traverse 3 régions (tirées des Actes) sur une carte à embranchements : combats, élites, événements, feux de camp, marchands, trésors, autels de sang et boss.
- Les PV et les K.O. sont conservés toute la marche. Après chaque victoire, on choisit 1 Bénédiction parmi 3 (29 bénédictions communes, rares et épiques).
- Pactes de Sang : aux autels, accepter une malédiction contre une grosse récompense et +15 % de score. 12 événements écrits avec des choix, un marchand ambulant et des élites qui proposent parfois de rejoindre la marche.
- Score final → Sceaux de Marche, record personnel et classement du jour en ligne (fichier supabase/03_marche.sql à lancer une fois dans Supabase).
- La Compagnie : chaque jour, 6 missions de 1 h à 12 h (dont une épique). 3 escouades en même temps, conditions à remplir (rôle, élément, niveau, rareté) et objectif bonus (+50 % de butin). Le temps passe même jeu fermé.
- Les unités en mission sont occupées : elles quittent l'équipe et l'armée, et ne peuvent pas être vendues, sacrifiées ou évoluées avant leur retour (carte grisée « En mission »).
- Boutique des Expéditions : Poussière d'Écho, élixirs, tomes, ressources de Sang, coffres, Éclats et Pierre d'Éveil contre des Sceaux de Marche (limites par semaine).
- Menu Admin : missions de la Compagnie instantanées, Marche illimitée (non classée).
- Difficulté de la Marche réglée par simulation (outils/calibrer_marche.gd).

## v0.19.0 — Donjons et évolutions  (2026-09-28)

- Nouveau mode Donjon (Aventure → Donjon) : 6 donjons de 10 niveaux — le Brasier Éternel (Feu), la Sylve Putride (Nature), les Fosses Englouties (Eau), la Crypte sans Lune (Ténèbres), le Sanctuaire Profané (Sacré) et le Puits de Sang (neutre).
- Une expédition = 4 combats d'affilée sans soin entre deux : vague de 5 monstres, mini-boss et ses 2 gardes, vague de 5 monstres, puis le boss du donjon. Stamina payée au départ (4 à 10), abandon possible entre deux combats.
- 12 nouveaux ennemis : un mini-boss et un boss (avec phase 2) par donjon. Nouvel élément Neutre pour le Puits de Sang.
- 18 ressources d'évolution : Goutte, Larme et Cœur de Braise, de Sève, d'Abysse, d'Ombre, d'Aube et de Sang ; les Larmes arrivent au niveau 4, les Cœurs au niveau 8. Le niveau suivant s'ouvre en terminant le précédent.
- Nouvel Autel d'Évolution (depuis les Donjons, l'Autel de Fusion ou la fiche d'une unité du Deck) : les 64 unités invocables ont une version évoluée, jamais invocable.
- Évolution : unité niveau 30 + ressources de son élément + Sang (plus l'unité est rare, plus les ressources sont grosses). Elle garde ses étoiles et ses Échos, repart au niveau 1 et monte jusqu'au niveau 40.
- Chaque évolution : nouveau nom, stats +25 à +40 % selon la rareté, un sort amélioré et parfois un nouveau sort au niveau 40. L'apparence évoluée viendra plus tard (en attendant, le portrait de base est utilisé).
- Bestiaire : filtre « Évolutions ». Autel de Fusion : une unité et son évolution comptent comme doublons pour l'Éveil.
- Difficulté des donjons réglée par simulation (réussite ~70 % avec l'équipe conseillée, plus dur aux niveaux 9 et 10).

## v0.18.2 — Bestiaire illustré  (2026-09-28)

- Bestiaire : les unités découvertes qui ont un portrait s'affichent en cartes illustrées (comme dans le Deck), en 150×200.
- Bestiaire : grande illustration carrée en haut de la fiche de l'unité, calée en haut pour ne pas couper la tête.
- Les unités non découvertes restent cachées (« ? ») ; les unités sans portrait gardent l'ancienne carte.

## v0.18.1 — Illustrations sans têtes coupées  (2026-09-28)

- Correction : les illustrations restent calées en haut de l'image, la tête des unités n'est plus coupée (fiche du Deck et cartes).
- Fiche du Deck : l'illustration est maintenant carrée et montre l'image en entier.

## v0.18.0 — Cartes illustrées  (2026-09-28)

- Nouvelles cartes illustrées : l'image de l'unité remplit toute la carte, avec le nom, le niveau, les étoiles et l'XP sur un voile sombre en bas, et une pastille de couleur pour l'élément.
- Deck : cartes plus grandes (150×200) pour mieux voir les illustrations.
- Fiche d'une unité dans le Deck : grande illustration en haut de la fiche.
- Les cartes illustrées apparaissent aussi dans l'Autel de Fusion, l'Armée, l'Arène, le Reliquaire et la révélation des invocations.
- 18 nouveaux portraits : Chevalier Noir, Elf Sylvestre, Sorcier Sombre, Clerc Sacré, Guerrier Squelette, Gardiens d'Ombre, Rat Géant, Gobelin Pillard, Loup Gris, Zombie Errant, Bandit des Routes, Araignée Venimeuse, Chauve-Souris Nocturne, Limace Acide, Corbeau Maudit, Sanglier Sauvage, Brigand Ivre, Slime Gélatineux.

## v0.17.0 — Portraits des unités  (2026-09-28)

- Les cartes affichent maintenant le portrait illustré de l'unité (découpé en cercle, contour de la couleur de l'élément), partout : Deck, combat, Bestiaire, choix du héros, invocation, Échos, Reliquaire, Tours, Boss de Monde.
- Premiers portraits : les 8 héros de légende et le Seigneur Démon.
- Les unités sans portrait gardent leur initiale en attendant leur image ; les unités non découvertes du Bestiaire restent cachées (« ? »).
- Nouvel outil outils/decouper_planche.py : découpe une planche ChatGPT 3×3 en un portrait par unité dans assets/unites/.

## v0.16.2 — Correction du son sur la version web  (2026-09-27)

- Correction : la musique et les bruitages fonctionnent maintenant sur la version web (navigateur).
- Sur navigateur, le son démarre au premier clic (règle des navigateurs).

## v0.14.0 — Musique et bruitages  (2026-09-27)

- Musique pour chaque écran avec fondu enchaîné : menus, Aventure, combats, boss, Autel d'Invocation, Tour de l'Enfer, Tour du Paradis, Boss de Monde, victoire et défaite.
- Bruitages en combat : coups, coups critiques, magie, soins, boucliers, K.O. et rugissement des boss (géants et changement de phase).
- Invocation sonore : cercle magique, cartes qui se retournent, et un son de plus en plus impressionnant selon la rareté (SR, SSR, UR, Légende).
- Sons du quotidien : clic des boutons, retour, erreur (pas assez d'or ou de stamina), or gagné, coffres, montée de niveau.
- Réglage du volume de la musique et des bruitages dans les Paramètres (enregistré avec la partie, conservé après une nouvelle partie).

## v0.13.0 — Menu Admin (tests)  (2026-09-26)

- Menu Admin dans les Paramètres (visible seulement quand le jeu est lancé depuis Godot).
- Options à cocher : or, gemmes, stamina, Éclats et objets du Reliquaire infinis ; Bestiaire complet ; tous les chapitres débloqués ; tous les étages des Tours ; Boss de Monde tous disponibles et illimités ; héros invincibles ; ennemis affaiblis ; XP x10 ; amélioration d'Échos garantie.
- Décocher une option remet exactement la situation d'avant : la vraie progression n'est jamais modifiée.
- « MODE ADMIN ACTIF » s'affiche sur le menu principal quand une option est cochée.

## v0.12.0 — Effets d'invocation et événements  (2026-09-26)

- Nouvel effet d'invocation : cercle magique, cartes face cachée qui se retournent une à une.
- Plus la carte est rare, plus l'effet est impressionnant : lueur (R), aura (SR), rayons dorés et tremblement (SSR), éclairs et onde de choc (UR), halo divin (Légende).
- Le cercle change de couleur avant la révélation quand une carte rare arrive ; bouton « Tout révéler » pour aller plus vite.
- Bandeau d'événement en bas de l'Autel d'Invocation : invocations spéciales à durée limitée avec unités vedettes et compte à rebours.
- Premier événement : « Lune de Sang » (Empereur Déchu, Dragon d'Ombre, Archange Noir), puis « Aube Céleste ».

## v0.11.1 — Équilibrage de la stamina  (2026-09-26)

- Stamina max : +2 par niveau de compte (30 au niveau 1, 88 au niveau 30).
- Coûts dans l'Aventure réduits : combat 1, élite ou gardien 2, boss 3. Coffres, soins, mystères et embuscades restent gratuits.

## v0.11.0 — Stamina, niveau de compte et versions  (2026-09-26)

- Niveau de compte : niveau maximum 30, XP gagnée à chaque combat gagné (Aventure, Tours, Boss de Monde) + bonus au premier passage d'un chapitre.
- Chaque niveau augmente la stamina max (+1,5 par niveau : 30 au niveau 1, 73 au niveau 30) et recharge entièrement la stamina.
- Stamina : 1 point toutes les 5 minutes, même jeu fermé. Les combats de l'Aventure coûtent de la stamina (combat 2, élite/gardien 3, boss 5).
- Affichage de la stamina (avec le temps avant le prochain point) et du niveau de compte sur le menu et les plateaux.
- Journal des mises à jour dans le jeu (ouvert automatiquement après une mise à jour) et numéro de version affiché.
- Outil « Versions » dans l'éditeur Godot : sauvegarde .zip de chaque version et restauration d'une ancienne version.

## v0.10.0 — Modes rejouables : Tours, Boss de Monde, Reliquaire  (2026-09-26)

- Tour de l'Enfer (on descend) et Tour du Paradis (on monte) : 100 étages, élite tous les 5 étages, boss tous les 10, super boss à l'étage 100.
- Butin spécial des tours (Braises, Plumes, Poussière d'Écho, coffres, élixirs, tomes, Pierres d'Éveil) ; réinitialisation chaque lundi avec compte à rebours.
- Boss de Monde : 7 boss géants, un par jour de la semaine ; armée de 20 unités en 4 escouades ; 3 essais par jour ; récompenses selon les dégâts.
- Le Reliquaire : coffres d'or, élixirs de stamina, tomes d'XP, Forge de 8 héros exclusifs, échanges, Atelier d'Échos (fabrication et démantèlement).
- Pierres d'Éveil utilisables à l'Autel de Fusion à la place d'un doublon.
- 46 nouvelles unités (monstres et boss des tours, boss de monde, héros de forge) ; filtre « Boss de Monde » dans le Bestiaire.
- Correction : le retour de l'écran Aventure ramène bien au menu principal.

## v0.9.0 — Autel de Fusion  (2026-09-26)

- Éveil : sacrifier des doublons pour gagner des étoiles (★1 à ★6 « Éveillé »), +6 % de stats par étoile, +10 % à l'Éveil.
- Absorption : sacrifier des unités pour donner de l'XP au héros principal.
- Les unités de l'équipe, le héros de départ et les unités verrouillées ne peuvent pas être sacrifiés.
- Étoiles visibles sur les cartes, dans le Deck et prises en compte en combat.

## v0.8.1 — Équilibrage des Échos et du début de partie  (2026-09-26)

- Les monstres normaux peuvent donner des Échos (surtout de faible qualité) ; élites, gardiens et boss en donnent plus et de meilleurs.
- Début de l'aventure adouci (jusqu'à la fin de l'Acte II).
- Le set et l'emplacement d'Écho de chaque Acte et chapitre sont affichés (Histoire, écran d'Acte, plateau).

## v0.8.0 — Échos Sanguins  (2026-09-26)

- 6 emplacements, 12 sets, 5 raretés, étoiles 1 à 6, amélioration jusqu'à +15 avec chances dégressives.
- Écran des Échos : équiper, retirer, améliorer, vendre, verrouiller, filtres et tri.
- Chaque Acte donne un set, le chapitre N donne l'emplacement N.

## v0.7.0 — Deck et Autel d'Invocation  (2026-09-25)

- Deck : équipe de 5 places (Avant / Arrière), doublons autorisés, fiche détaillée, vente simple et multiple, verrouillage.
- Autel d'Invocation : Pacte Doré (or, x1/x10, N/R/SR) et Pacte Supérieur (Éclats des boss, x1/x10, SR/SSR/UR) avec garantie.
- Niveaux des unités (max 30) et XP gagnée en combat.

## v0.6.0 — Système de combat  (2026-09-25)

- Combat automatique : ordre par AGI, Avant/Arrière, éléments, skills, passifs, afflictions, boss à 2 phases.
- Écran de combat animé (vitesse x1/x2/x4, Passer) et récompenses.
- Rencontres par Acte, élites et gardiens plus forts, difficulté croissante réglée par simulation.

## v0.5.0 — Héros, monstres et Bestiaire  (2026-09-25)

- 123 unités : stats principales (PV, ATK, DEF, AGI, MAG) et secondaires, skills aux niveaux 1/10/20/30.
- 8 héros de légende : choix du héros de départ (à nouveau après une nouvelle partie).
- Bestiaire (codex) accessible depuis le menu principal.

## v0.4.0 — Sauvegarde  (2026-09-25)

- Sauvegarde automatique avec copie de secours, ressources, stamina et compte.
- Fenêtre Paramètres : code de sauvegarde (copier / importer) et nouvelle partie.

## v0.3.1 — Progression  (2026-09-25)

- Pas de retour en arrière sur les plateaux.
- Chapitres et Actes débloqués un par un.
- Correction du bouton retour des écrans.

## v0.3.0 — Plateaux de jeu  (2026-09-25)

- 72 plateaux case par case : combats, élites, gardiens, boss, coffres, soins, mystères, pièges.
- Embranchements qui se referment avant le boss, plateaux de plus en plus grands au fil des Actes.

## v0.2.0 — Histoire principale  (2026-09-25)

- 12 Actes et 72 chapitres, un écran illustré par Acte avec ses 6 chapitres.
- Bulles d'information sur les Actes et les chapitres.

## v0.1.0 — Premiers pas sur Godot  (2026-09-24)

- Menu principal et écran Aventure (image de fond + zones cliquables).
- Publication web sur GitHub Pages.
