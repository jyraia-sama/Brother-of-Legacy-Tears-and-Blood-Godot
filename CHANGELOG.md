# Journal des mises à jour — Brothers of Legacy : Tears and Blood

Version actuelle : **0.57.0** (2026-10-09)

## v0.57.0 — La Guerre des Bannières  (2026-10-09)

- LA GUERRE DES BANNIÈRES (Guilde → Guerre) : une guerre de guildes chaque semaine, en asynchrone, chacun joue quand il veut. Lundi-mardi : préparation (le chef inscrit la guilde une fois pour toutes, chacun prépare sa défense de guerre). Mercredi-samedi : 2 assauts par jour contre la forteresse ennemie. Dimanche : bilan, la guilde qui a pris le plus d'étoiles gagne.
- LA FORTERESSE : un poste par membre, rangés par puissance en Remparts, Tours et Donjon. Une couche s'ouvre quand chaque poste de la précédente a été pris au moins une étoile. ★ victoire · ★★ victoire avec 3 unités debout ou plus · ★★★ aucune perte ; seul le meilleur résultat d'un poste compte.
- STRATÉGIE : la FATIGUE épuise jusqu'au lendemain les unités qui ont attaqué (toute la collection compte), l'ÉCLAIREUR révèle une fois par jour les unités d'un poste ennemi (sinon seuls ses éléments sont visibles), et le JOURNAL de guerre permet de REVOIR chaque assaut.
- LA LÉGION DE LA SOIF : s'il n'y a pas d'autre guilde à votre mesure, la guerre a lieu quand même contre cette armée fantôme faite des reflets de défenses de vrais joueurs ; elle attaque votre forteresse un peu plus chaque jour.
- BUTIN : pour chaque membre qui a attaqué, Sceaux de guilde (selon le résultat et les étoiles gagnées), or, coffres et tome ; XP et trésor pour la guilde. (Serveur : lancer supabase/08_guerre.sql.)

## v0.56.0 — Les applications à jour  (2026-10-09)

- APPLICATION ANDROID : nouvelle application à installer (page des téléchargements du jeu). L'ancienne (v0.36) ne pouvait plus se mettre à jour toute seule à cause d'un bug de sa fenêtre de mise à jour : elle restait bloquée sur le vieux menu. La nouvelle repart à jour, avec la nouvelle icône, et se mettra de nouveau à jour automatiquement. La partie n'est pas perdue (elle est sur le téléphone et sur le compte).
- ORDINATEUR : la fenêtre du jeu et la barre des tâches affichent la nouvelle icône des deux frères. Pour l'icône du fichier .exe et du raccourci du bureau, une nouvelle installation complète est disponible (facultative).
- JEU WEB SUR TÉLÉPHONE : l'appli ajoutée à l'écran d'accueil s'ouvre maintenant en plein écran, sans la barre du navigateur (Android : « Installer l'application » ; iPhone : « Sur l'écran d'accueil »), avec la nouvelle icône. Une nouvelle version publiée s'installe toute seule au lancement suivant au lieu de rester bloquée sur l'ancienne.

## v0.55.0 — Plein écran  (2026-10-08)

- ÉCRAN DE CHARGEMENT : les larmes et les gouttes de sang tombent maintenant verticalement du haut de l'écran, comme une pluie, jusque dans les deux moitiés du Sceau (dans le jeu et sur la page web).
- PLEIN ÉCRAN PAR DÉFAUT : les applications Windows et Mac s'ouvrent en plein écran (toujours réglable dans le Menu, ou touche F11). Sur le jeu web, ordinateur compris, le plein écran s'active au premier clic ou appui (réglable dans le Menu).
- MENU : les boutons du bas restent toujours visibles, même quand on fait défiler la fenêtre sur un petit écran. Nouveau bouton « Quitter le jeu » à côté de « Fermer » (applications Windows, Mac et Android), avec confirmation ; la partie est sauvegardée avant de fermer.

## v0.54.1 — Le Sceau peint  (2026-10-08)

- ÉCRAN DE CHARGEMENT : le Sceau des Frères est maintenant un vrai médaillon peint, or ciselé et ailes de phénix. Ses deux moitiés de cristal, éteintes au départ, se remplissent réellement de larmes bleues et de sang au fil du chargement, avec une surface qui ondule et un liseré de lumière, avant de se ressouder. Même animation sur la page de chargement du jeu web.

## v0.54.0 — Le Sceau des Frères  (2026-10-08)

- NOUVELLE ICÔNE : les deux frères face à face, l'aîné avec une larme bleutée, Kaël avec une larme de sang. Sur le jeu web dès cette version (onglet du navigateur, appli installée sur l'écran d'accueil) ; sur Windows, Mac et Android à la prochaine installation complète.
- NOUVEL ÉCRAN DE CHARGEMENT : « le Sceau des Frères se reforme ». Entre les deux frères, les larmes bleues de l'aîné et les gouttes de sang de Kaël coulent de leurs yeux et remplissent chacune une moitié du médaillon brisé, au rythme du chargement. À 100 %, les deux moitiés se ressoudent dans un éclair, une onde de lumière balaie l'écran et le titre apparaît. Une phrase de l'histoire s'affiche en bas, différente à chaque lancement. Toucher l'écran accélère l'animation.
- JEU WEB : la page de téléchargement du jeu (avant son lancement, la plus longue attente sur téléphone) joue la même animation à la place de la barre grise, avec le pourcentage réel du téléchargement ; le jeu enchaîne ensuite directement sur le Sceau qui se ressoude.

## v0.53.0 — Les yeux du créateur  (2026-10-08)

- STATISTIQUES DU JEU (réservé au créateur) : dans le menu Admin, un bouton « 📊 Statistiques du jeu » apparaît uniquement sur le compte jyraia (c'est le serveur qui vérifie). Vue d'ensemble (comptes, joueurs en ligne et actifs sur 24 h / 7 j / 30 j, nouveaux comptes, appareils, lancements, téléchargements, courbe d'activité des 30 derniers jours, guildes, Arène, Arène classée, Marche Maudite), liste des joueurs (pseudo, statut, inscription, niveau, chapitres, puissance, guilde, version, plateformes) avec recherche et tri, appareils par plateforme et versions utilisées, téléchargements des applications par version. (Serveur : lancer supabase/07_statistiques.sql.)
- COMPTEUR D'APPAREILS : au lancement, le jeu signale anonymement la plateforme (web ordinateur, web Android, iPhone/iPad, Windows, Mac, Android) et la version, avec un identifiant tiré au hasard. Rien de personnel n'est envoyé.
- ANDROID : l'application se télécharge désormais depuis la page des Releases GitHub, comme Windows et Mac, ce qui permet de compter ses téléchargements.

## v0.52.0 — Le Guide des Échos  (2026-10-08)

- ÉCHOS SANGUINS — GUIDE COMPLET : un bouton « ? » doré et lumineux, en haut de l'écran des Échos, ouvre un guide pas à pas en 7 parties : la marche à suivre, les emplacements et raretés, l'amélioration (chances et coûts de +1 à +15), tous les sets avec leur bonus et l'Acte où les trouver, l'optimisation (stats fixes en début de partie, % ensuite, avec le point de bascule chiffré et un conseil personnalisé pour le héros choisi), où trouver des Échos et comment en obtenir des plus rares (tableau des drops, étoiles par Acte, Atelier du Reliquaire). Il s'ouvre tout seul à la première visite.
- ÉCHOS SANGUINS — MODE ESSAI : sur chaque héros, essaie plusieurs Échos à la fois (jusqu'à un set complet) parmi ceux que tu possèdes et compare ses stats actuelles et en essai (gains en vert, pertes en rouge, sets gagnés ou perdus, puissance des sorts). Rien ne change tant que tu n'appuies pas sur « Équiper l'essai » ; le jeu prévient si un Écho est pris à un autre héros.

## v0.51.0 — Visages et détails  (2026-10-08)

- PROFIL DES AUTRES JOUEURS : la fiche ouverte depuis Social ou Guilde est maintenant complète, comme ton propre écran « Mon héros » : titre, niveau, guilde, héros principal (stats et Échos), son équipe avec ses cartes, ses résultats d'Arène, d'Arène classée et de Marche Maudite, ses statistiques (chapitres, Tours, Donjons, Boss de Monde, Succès...) et sa collection par rareté. (Serveur : lancer supabase/06_profil_public.sql.)
- ÉCHOS SANGUINS : l'inventaire a deux onglets. « Sac » ne montre que les Échos libres ; « Équipés sur les héros » range les Échos portés, héros par héros (le héros choisi en premier). Cliquer un emplacement du héros ramène au Sac, filtré sur cet emplacement.
- QUÊTES : les boutons « Réclamer » (quêtes, récompense de connexion, Succès, guide du menu, Arène classée) deviennent vert vif et lumineux quand une récompense t'attend ; le coffre bonus brille en doré.
- PARAMÈTRES ET MENU ADMIN : cases à cocher bien plus visibles (grande case dorée, cochée en vert avec une coche blanche, texte doré quand l'option est active).

## v0.50.1 — Des cadres dignes des héros  (2026-10-08)

- Les cadres de rareté sont arrivés : fer pour N, bronze pour R, argent et améthystes pour SR, or et ambre pour SSR, fer noir et rubis pour UR, or blanc et pierres de lune pour les Légendes. Les coins ornés débordent légèrement de la carte, comme de vraies cartes de collection.

## v0.50.0 — Les cadres de rareté  (2026-10-08)

- CADRES DE RARETÉ : les cartes des héros, monstres et familiers peuvent maintenant porter un cadre orné propre à leur rareté (fer pour N, bronze pour R, argent et améthystes pour SR, or pour SSR, fer noir et rubis pour UR, or blanc pour les Légendes), partout où elles apparaissent : Deck, Fusion, Évolution, Invocations, Bestiaire, Galerie d'Art, Arène, Armée, Compagnie, Marche Maudite, Reliquaire, Ménagerie et grandes fiches. Les cadres s'affichent dès que leurs images sont ajoutées (prompts dans PROMPTS_CADRES.md).

## v0.49.1 — Arnaud monte sur scène  (2026-10-07)

- Arnaud Riff-de-Sang a enfin son portrait et sa figurine de combat (Deck, invocations, Galerie d'Art et combats).

## v0.49.0 — Le Riff de Sang  (2026-10-07)

- ARÈNE CLASSÉE — SORTS PLUS LISIBLES : à ton tour, chaque action est une grande carte qui dit clairement ce qu'elle fait (dégâts, effets, chances), qui elle touche (« Tu choisis la cible », « Touche tous les ennemis », « Sur toute l'équipe »…) et sa recharge (« Prêt dans 2 tours »). Plus besoin de survoler les boutons, ce qui marche aussi sur téléphone.
- ARÈNE CLASSÉE — PRÉPARER SON ÉQUIPE : un bouton « Préparer mon équipe » ouvre le Deck directement depuis l'Arène classée, et on y revient ensuite.
- NOUVEAU HÉROS UR : Arnaud Riff-de-Sang (Feu · soutien), guitariste punk à la crête écarlate, en hommage à Arnaud. Riff Incendiaire, Crête de Défi, Solo Déchaîné et Larsen Assourdissant ; son évolution : Arnaud, Roi du Chaos Écarlate. Invocable, et offert une fois à qui termine le Donjon d'Arnaud (le secret du menu principal).

## v0.48.0 — Le prix de la gloire  (2026-10-07)

- INVOCATIONS PLUS EXIGEANTES : les héros rares se méritent. Pacte Supérieur : SSR 17 %, UR 1,6 %, Légende 0,2 % (au lieu de 22 %, 2,5 % et 0,3 %), SSR garanti toutes les 25 invocations (au lieu de 20). Pacte Doré : SR 6 % (au lieu de 10 %). Invocations d'événement : SSR 19,5 %, UR 2,7 %, Légende 0,3 %.
- AVENTURE PLUS DIFFICILE : les ennemis se renforcent davantage d'Acte en Acte (jusqu'à environ +24 % de puissance à la fin de l'histoire). Il faudra davantage améliorer ses Échos, fusionner et éveiller ses héros pour venir à bout des derniers Actes.
- Équilibrage vérifié par simulation : un joueur régulier perd en moyenne 1 à 5 combats par chapitre, et ne reste presque jamais bloqué.
- MODES DÉBLOQUÉS AU FIL DE L'HISTOIRE : pour ne pas tout découvrir d'un coup, les menus s'ouvrent en avançant. Échos Sanguins au chapitre 3 de l'Acte I ; Fusion et Reliquaire à la fin de l'Acte I ; Arène et Donjons à la fin de l'Acte II ; Boss de Monde, Tours et Guilde à la fin de l'Acte III ; Expédition et Ménagerie à la fin de l'Acte IV. Une fenêtre annonce chaque nouveauté. Les joueurs déjà avancés gardent tout ce qu'ils ont débloqué.
- PLACES D'ÉQUIPE : l'aventure commence avec 3 héros ; la 4e place s'ouvre à la fin de l'Acte I, la 5e à la fin de l'Acte III. Les premiers Actes ont été rééquilibrés en conséquence.
- Les quêtes du jour et de la semaine ne proposent plus de missions dans des modes encore fermés.

## v0.47.0 — La vie de guilde  (2026-10-07)

- LA GUILDE PREND VIE : niveau et XP de guilde, trésor commun, et un don par jour (gratuit, en or ou en gemmes) qui fait grandir la guilde et te rapporte des Sceaux de guilde.
- DISCUSSION DE GUILDE : un chat pour parler avec tous les membres, directement dans l'écran de guilde.
- BOSS DE GUILDE : chaque semaine, toute la guilde affronte le même titan avec ses armées (2 assauts par jour). Les dégâts s'additionnent ; paliers à 25, 50, 75 et 100 % avec Sceaux, or, coffres et Éclats pour tous les participants.
- BÉNÉDICTIONS : Force, Vitalité, Rempart, Fortune et Savoir, 5 rangs chacune, achetées par le chef ou les officiers avec le trésor. Elles renforcent les héros (ATK, PV, DEF) et augmentent l'or et l'XP gagnés en combat, pour tous les membres.
- BOUTIQUE DE GUILDE : élixirs, tomes, coffres d'or, Pierre d'Éveil, Éclats… contre des Sceaux de guilde (limites par semaine).
- Mot du chef et journal de la guilde (dons, niveaux, bénédictions, titan abattu).

## v0.46.0 — La Galerie d'Art  (2026-10-07)

- NOUVEAU : LA GALERIE D'ART (colonne du Sang, menu principal). Toutes les illustrations du jeu, rangées par onglets : Créatures, Figurines, Familiers, Boss de Monde, Histoire, Décors et Plateau.
- Toucher une créature ouvre sa fiche : portrait et figurine côte à côte, rareté, élément, rôle, où la trouver (Invocation, Actes, Donjons, Tours, Boss de Monde) et toutes ses compétences. Les images s'ouvrent en grand, avec Précédent / Suivant (ou les flèches du clavier).
- Ce que tu n'as pas encore découvert reste caché derrière un « ? » : les créatures pas encore rencontrées, les Actes pas encore ouverts et les personnages qui dévoileraient la suite de l'histoire.
- NOUVELLE DIRECTION ARTISTIQUE (2/3) : 24 héros et monstres de plus sont repeints, avec leur figurine de combat. Archange Noir, Titan des Abysses, Reine des Liches, Chat des Abysses, Phénix Immortel, Cheval Céleste, les ennemis de l'Acte I et des terres sombres…

## v0.45.0 — Un nouveau visage (1/3)  (2026-10-07)

- NOUVELLE DIRECTION ARTISTIQUE (1/3) : 56 héros et monstres sont repeints dans le style des héros hommages. Les huit Légendes, les premiers compagnons, les créatures des bas-fonds, les sauvages, les guerriers des terres, les créatures des ruines et les puissants.
- Chacun a désormais sa figurine de combat en pied, avec sa propre attitude : le Mage Gris jongle avec ses boules de feu, la Dague Violette guette accroupie, le Brigand Ivre lève sa chope, l'Esprit Frappeur fait voler la vaisselle…
- Le Lapin Pyromane a trouvé sa vraie nature : un petit artificier fou, carotte-dynamite allumée à la main.

## v0.44.0 — Les Titans de la semaine  (2026-10-07)

- LES BOSS DE MONDE ONT UN VISAGE : les 7 titans de la semaine ont leur illustration. Le Béhémoth des Cendres, le Léviathan des Abysses Noires, Yggdravor l'Arbre-Monde, Golgoth le Colosse de Pierre-Sang, Solgard le Soleil Vivant, Nidhögr le Dévoreur d'Étoiles et l'Avatar du Sang Originel.
- En combat, le boss se dresse désormais en figurine géante sur son socle de ruines, face aux 20 petites unités de ton armée, avec son illustration en fond.
- Les cartes des 7 jours montrent le visage de chaque boss, et leurs portraits apparaissent aussi au Bestiaire.

## v0.43.0 — Le Royaume du refuge  (2026-10-06)

- NOUVEAUX DÉCORS DU ROYAUME : la place du refuge et son panneau des contrats (Quêtes), la galerie des trophées (Succès), l'échoppe du marchand (Boutique), la grande salle aux bannières (Guilde), la taverne sous la neige (Social) et la tour des corbeaux (Courrier).
- Le choix du héros de départ se fait désormais dans la cour du domaine Valcendre en flammes, sous la lune rouge, entre deux statues de chevaliers.
- Tous les menus du jeu ont maintenant leur propre décor peint.

## v0.42.2 — Les 13 Actes illustrés  (2026-10-06)

- NOUVELLES ILLUSTRATIONS : les Actes V à XIII ont à leur tour leur vraie scène peinte. Les bûchers de l'Inquisiteur, le lac de verre noir de la Forêt Pétrifiée, le trône de ronces de la Dame, le siège sous l'Éclipse du Sang, le Val des Héros Déchus, la Citadelle des Supplices, le duel des deux frères, le Trône de Cendres et la Soif Première au cœur du Sceau.
- Fiche d'un chapitre : le niveau des ennemis s'affiche « Niv. 30 » au lieu de « Niv. 30 à 30 » quand le plafond est atteint.

## v0.42.1 — Les premiers Actes illustrés  (2026-10-06)

- NOUVELLES ILLUSTRATIONS : les Actes I à IV ont leur vraie scène peinte. Le domaine Valcendre en flammes, la Cité en Deuil et sa Veuve aux Lanternes, les camps du Drapeau Noir, et le Sépulcre des Rois avec son gardien couronné. On les retrouve en fond de la fiche de chaque chapitre et dans la fiche de l'Acte.
- La fiche d'un chapitre laisse mieux voir l'illustration de l'Acte : l'image est plus lumineuse, et les encadrés de droite sont plus transparents.

## v0.42.0 — Des décors qui respirent  (2026-10-06)

- DÉCORS BIEN PLUS VISIBLES : les fonds peints sont nettement moins assombris et les panneaux plus transparents. On voit enfin la salle ou le lieu derrière chaque menu, et les textes restent lisibles.
- STAMINA DÉTAILLÉE : sur la carte des Actes, le plateau, les Donjons, les Tours (choix et étages) et le Reliquaire, la stamina s'affiche comme sur le menu principal, avec la jauge, « Pleine » ou le compte à rebours avant le prochain point (« +1 dans 3 min 12 s »).
- Tour du Paradis : les panneaux clairs restent bien blancs pour que le texte reste lisible sur le décor lumineux.

## v0.41.0 — Les lieux de la Larme  (2026-10-06)

- NOUVEAUX DÉCORS : les lieux de la Larme ont chacun leur fond peint. L'arène en ruine sous la lune (Arène et Arène classée), le champ de bataille et l'ombre du titan (Boss de Monde), la vallée aux six donjons, la caravane des Expéditions, le campement de la Compagnie et les enclos de la Ménagerie.
- TOURS INFINIES : les deux tours se dressent face à face sur l'écran de choix. Chaque carte montre l'intérieur de sa tour, et on retrouve ces mêmes décors en montant les étages : les escaliers de lave de l'Enfer, et les escaliers de marbre du Paradis.

## v0.40.0 — Les salles du Sang  (2026-10-06)

- NOUVEAUX DÉCORS : les six salles du Sang ont chacune leur fond peint. La salle d'armes pour le Deck, le cercle runique pour l'Autel d'Invocation, le laboratoire d'alchimie pour la Fusion et l'Évolution, la crypte-reliquaire des Échos Sanguins, la forge et le trésor du Reliquaire, la bibliothèque du chasseur pour le Bestiaire.
- Les décors sont bien plus visibles : ils sont moins assombris, et les grands panneaux deviennent légèrement transparents pour laisser voir la salle derrière, sans gêner la lecture.

## v0.39.1 — Un menu plus clair  (2026-10-06)

- Le fond du menu principal est bien plus lumineux : le grand frère, Kaël, le médaillon et la crypte se distinguent enfin, même sur un téléphone ou un écran peu lumineux.
- Correction : un réglage d'affichage assombrissait par erreur les illustrations du menu et de la carte du monde (leurs couleurs étaient « appliquées deux fois »). La carte des Valcendre retrouve elle aussi ses vraies couleurs.

## v0.39.0 — La carte des Valcendre  (2026-10-05)

- NOUVELLE CARTE PEINTE : les Terres des Valcendre s'étendent désormais sur une vraie carte illustrée, du domaine en flammes jusqu'au Trône de Cendres. Les 13 lieux, la route et la brume se posent directement sur le décor.
- FICHE D'UN CHAPITRE : touche un chapitre (ou « Continuer ») pour ouvrir sa fenêtre, sur l'illustration de l'Acte : récit, niveau conseillé, niveau des ennemis, stamina minimum, cases du plateau, chef ou boss, butin d'Échos et renfort de Kaël. Les créatures que tu n'as pas encore croisées restent cachées derrière un « ? ».
- Un chapitre terminé peut être revu et rejoué depuis sa fiche ; un chapitre verrouillé indique ce qu'il faut faire pour l'ouvrir.
- L'ancien écran des Actes et l'ancienne liste de l'Histoire disparaissent : tout passe par la carte. En quittant un plateau, tu reviens sur la carte, sur l'Acte que tu jouais.

## v0.38.4 — Le décor du sanctuaire  (2026-10-05)

- Le sanctuaire secret a enfin son décor : une grande salle taillée dans la roche, veillée par une immense tête de bélier, la toison d'or et deux gardiens jumeaux. Les combats de la famille s'y déroulent désormais.

## v0.38.3 — Les figurines du sanctuaire  (2026-10-05)

- Les gardiens du sanctuaire secret descendent de leur portrait : ils combattent désormais en pied, sur leur socle de pierre, comme les héros de légende. Et une fois recrutés, ils gardent leur figurine dans ton équipe…

## v0.38.2 — Portraits du sanctuaire (2)  (2026-10-05)

- Le sanctuaire secret a deux nouveaux portraits… Le Bélier Ardent et un certain reflet dans le miroir n'attendent plus que toi.

## v0.38.1 — La Crypte des Valcendre  (2026-10-05)

- NOUVEAU FOND DU MENU : la crypte des Valcendre, la nuit où le Sceau des Frères se brise. Le grand frère et la Larme d'un côté, Kaël et le Sang de l'autre, le médaillon brisé entre eux et la tombe de leur père à leurs pieds.
- Les boutons de la Larme et du Sang restent bien lisibles grâce à une ombre douce sur les côtés de l'écran ; le guide Premiers pas descend un peu pour laisser voir le médaillon.
- Le sanctuaire secret a un nouveau portrait…

## v0.38.0 — La carte des Terres des Valcendre  (2026-10-04)

- LA CARTE DU MONDE : le bouton Aventure ouvre maintenant « Les Terres des Valcendre ». Les 12 Actes de l'Histoire sont des lieux de la carte, du sud au nord : le Domaine Valcendre, la Cité en Deuil, les Camps du Drapeau Noir, le Sépulcre des Rois, les Terres Brûlées, la Forêt Pétrifiée, les Marais aux Murmures, le Bastion de l'Éclipse, le Val des Héros Déchus, la Citadelle des Supplices, les Champs du Jugement et le Trône de Cendres.
- La route parcourue est dorée, la suite en pointillés ; la figurine du grand frère se tient sur l'Acte en cours et les terres inconnues restent dans la brume, qui se lève au fil de l'aventure.
- Toucher un Acte ouvre sa fiche : partie, lieu, boss, set d'Échos et les 6 chapitres. « Continuer » lance directement le chapitre en cours, un chapitre déjà ouvert se relance d'un toucher, et « Voir l'Acte illustré » ouvre l'écran de l'Acte comme avant. Le Journal de l'histoire est en haut de la carte.
- Une fois l'Acte XII terminé, le Sceau des Frères apparaît au-dessus du Trône de Cendres…
- CORRECTION (application ordinateur et Android) : « Rechercher une mise à jour » et la fenêtre de mise à jour ne fonctionnaient plus depuis la v0.36.0 (le jeu pouvait se fermer). La fenêtre s'ouvre de nouveau normalement.
- Menu principal : la colonne de gauche s'appelle désormais LA LARME, comme la moitié du Sceau que porte le grand frère, face au SANG de Kaël. Les couleurs suivent le Sceau : la Larme en bleu, le Sang en rouge.

## v0.37.0 — Le nouveau menu : les Deux Frères  (2026-10-04)

- NOUVEAU MENU PRINCIPAL : l'écran est coupé en deux par une fente dorée. À gauche LA LAME pour combattre (Aventure, Arène, Boss de Monde, Tours, Donjons, Expédition, Ménagerie), à droite LE SANG pour ton armée (Deck, Invocation, Fusion, Échos, Reliquaire, Bestiaire). Chaque bouton affiche une info utile : chapitre à reprendre, boss du jour et essais restants, reset des Tours, taille de l'équipe…
- Arène, Boss de Monde, Tours, Donjons, Expédition et Ménagerie s'ouvrent maintenant directement depuis le menu (ils restent aussi dans l'écran Aventure) ; le bouton retour ramène au menu.
- BARRE DU HAUT : ton blason et ton niveau (Mon héros), ton nom (Compte), ton titre et une vraie barre d'XP de compte. Ressources refaites : stamina avec sa jauge et le temps avant le prochain point, or, gemmes et Éclats, avec un bouton « + » vers la Boutique. En haut à droite : Aide, Nouveautés et Menu.
- LE ROYAUME en bas de l'écran : Quêtes, Succès, Boutique, Guilde (enfin un vrai bouton !), Social et le nouveau Courrier. Les pastilles signalent les récompenses à réclamer, les missions terminées, les chasses à récolter et le Boss de Monde du jour.
- LE COURRIER : tes lettres, cadeaux et compensations arrivent ici, avec « Tout récupérer ». Une première lettre t'attend avec un petit présent.
- Le guide PREMIERS PAS passe au centre, sous l'emblème. Les stats ATK / DEF / PV du héros quittent le menu (elles restent dans Mon héros).
- Les secrets du menu sont toujours là… pour ceux qui savent où chercher.

## v0.36.1 — Bouton Muet  (2026-10-04)

- Paramètres : nouvelle case « Muet » pour couper d'un coup la musique et les bruitages. Les réglages de volume sont conservés et reviennent dès qu'on la décoche.

## v0.36.0 — Le jeu sur Android  (2026-10-04)

- L'APPLICATION ANDROID : Brothers of Legacy s'installe maintenant comme une vraie application sur les téléphones et tablettes Android, en plein écran et en paysage (dans un sens ou dans l'autre). Ta partie te suit grâce à ton compte.
- Elle se met à jour toute seule, comme sur ordinateur : au lancement, une fenêtre présente les nouveautés et le bouton « Mettre à jour » télécharge la nouvelle version. Il suffit ensuite de rouvrir le jeu.
- Sur iPhone, la version web ajoutée à l'écran d'accueil reste la meilleure solution : elle est toujours à jour.

## v0.35.0 — Le jeu s'installe sur ordinateur  (2026-10-04)

- LE JEU SUR ORDINATEUR : Brothers of Legacy existe maintenant en vraie application pour Windows et pour Mac, à installer sur ton ordinateur. Ta partie te suit grâce à ton compte.
- MISES À JOUR AUTOMATIQUES : à chaque lancement, l'application regarde s'il existe une nouvelle version. Une fenêtre présente les nouveautés avec un bouton « Mettre à jour » : le téléchargement se fait dans le jeu, puis il redémarre tout seul sur la nouvelle version.
- Paramètres → « Rechercher une mise à jour » pour vérifier à tout moment, et option « Plein écran » (ou touche F11) sur ordinateur.

## v0.34.2 — Portraits du sanctuaire  (2026-10-03)

- Deux gardiens du sanctuaire secret ont maintenant leur portrait…

## v0.34.1 — Le gardien du sanctuaire  (2026-10-03)

- Le sanctuaire secret accueille un nouveau gardien… Il n'est pas né sous le même signe que les autres, et il n'est jamais vraiment seul. L'épreuve finale se joue désormais à quatre.

## v0.34.0 — Le secret du Bélier  (2026-10-03)

- UN NOUVEAU SECRET se cache dans le menu principal… Quelque part, un sanctuaire caché où veille une famille née sous le signe du Bélier. Ses membres ne se laissent pas approcher facilement, mais ceux qui les vainquent gagnent de précieux alliés. À toi de le trouver !
- Les combats de ce sanctuaire s'adaptent à la puissance de ton équipe : on peut les tenter à n'importe quel moment de l'aventure, sans stamina.

## v0.33.3 — Plateau fluide et chargement allégé  (2026-10-03)

- PLATEAU FLUIDE : le décor du plateau (chemins pavés, socles, cases, miniatures) n'est plus redessiné à chaque image. Il est dessiné une fois, puis seulement quand il change (case atteinte, brouillard levé). Pendant que le pion avance, seuls la figurine, le halo de la Larme, la pénombre et les anneaux bougent : environ 3 fois moins de calcul par image.
- La pénombre autour du grand frère est maintenant un seul voile sombre qui le suit, au lieu d'assombrir chaque case et chaque pavé un par un (rendu quasi identique).
- Chargement du jeu web encore allégé : 66 Mo -> 25 Mo (portraits, familiers, personnages et figurines aussi compressés en WebP).

## v0.33.2 — Version web plus fluide et plus légère  (2026-10-02)

- VERSION WEB PLUS FLUIDE : la sauvegarde n'est plus réécrite à chaque gain (or, XP de chaque héros, Écho, objet...). Elle est écrite une seule fois, une demi-seconde après, et tout de suite quand le jeu passe en arrière-plan. Une fin de combat réécrivait une quinzaine de fois un fichier de ~190 Ko : c'était la principale cause des saccades.
- Synchronisation en ligne : le jeu ne recalcule plus toutes les 15 secondes l'empreinte complète de la partie quand rien n'a changé (petit gel régulier sur téléphone).
- Téléchargement presque deux fois plus léger (66 Mo -> 36 Mo) : les grandes illustrations (fonds, Actes, cercle d'invocation...) sont compressées en WebP et les musiques réencodées, sans différence visible.

## v0.33.1 — Portraits, figurines et miniatures du plateau  (2026-10-02)

- Images des 8 héros hommages : portraits (planche 39) et figurines de combat (planche 40). Les héros apparaissent désormais en pied sur leur socle pendant les combats.
- Miniatures des cases du plateau (planche 38) : départ, combat, élite, gardien, boss, coffre, soin, mystère et piège sont posés sur des socles de pierre.

## v0.33.0 — Huit héros hommages et figurines de combat  (2026-10-02)

- 8 NOUVEAUX HÉROS INVOCABLES, inspirés de personnages de jeux vidéo sans les copier (noms, apparences et sorts originaux) : l'Axolotl des Sources (SSR Eau, soutien qui se régénère), l'Errant Silencieux (SSR Ténèbres, guerrier), la Chasseresse de Soie (UR Ténèbres, assassin), la Princesse des Sceaux (SSR Sacré, soutien), l'Élu de la Lame (SSR Sacré, tank), le Mercenaire Sans Nom (UR Sacré, guerrier), la Combattante Ardente (UR Feu, guerrier) et la Fleuriste des Ruines (UR Nature, soutien).
- Chacun a 4 sorts (niveaux 1, 10, 20, 30) et sa version évoluée à l'Autel d'Évolution (niveau max 40, un sort amélioré et un sort de niveau 40) : 72 évolutions au total.
- Équilibrés sur les héros de même rareté. Le Pacte Supérieur compte désormais 10 SSR et 8 UR.
- FIGURINES DE COMBAT : une unité qui a sa figurine (assets/figurines/<identifiant>.png) apparaît en pied sur un socle à la place de son portrait rond. Elle respire doucement, s'élance pour frapper et bascule quand elle est K.O. ; les ennemis regardent vers la gauche. Marche pour tous les héros et ennemis dès qu'on ajoute leur image.
- Prompts ChatGPT : PROMPTS_HEROS_HOMMAGES.md (planche 39 : portraits, planche 40 : figurines, planche 41 : évolutions). Les outils de découpe gèrent les planches 4 x 2 et les figurines sur fond vert.

## v0.32.0 — Équilibrage de l'Aventure  (2026-10-01)

- L'AVENTURE RÉSISTE ENFIN : des joueurs virtuels ont rejoué toute l'histoire (Actes I à XIII) avec les vraies règles. Résultat : le jeu était beaucoup trop facile (aucune défaite de tout le jeu pour un joueur qui s'équipe), car les Éclats des boss donnent ~3 SSR dès l'Acte II alors que la difficulté était réglée pour une équipe de SR.
- Nouvelle difficulté réglée sur des équipes réalistes : environ 1 défaite par chapitre si tu améliores tes Échos, 2 si tu les poses sans les améliorer, surtout sur les boss. L'Acte I reste très doux, l'Acte XIII plus exigeant.
- Chaque chef de chapitre est réglé un par un (certains étaient bien plus coriaces que les autres) et il n'y a plus de pic de difficulté au premier chapitre de chaque Acte.
- KAËL INVITÉ : les ennemis sont un peu plus forts dans ses chapitres. Il aide toujours, mais ne gagne plus le combat à ta place (il faisait passer le boss final de l'Acte XII de 35 % à 78 % de victoires).
- Mimics réglés sur la même base (environ 3 victoires sur 4).
- Conseil après deux défaites sur une même case : le jeu signale si ton équipe porte peu d'Échos Sanguins (le moyen le plus rapide de devenir plus fort), sinon il propose d'améliorer les Échos ou l'Absorption.
- Outils d'équilibrage pour Godot : simuler_progression.gd, calibrer_aventure.gd, effet_echos.gd. Bilan complet : EQUILIBRAGE.md.

## v0.31.0 — Le plateau aux couleurs de la figurine  (2026-09-30)

- CASES EN SOCLES DE PIERRE : chaque case du plateau est un socle de pierre en relief (tranche, biseau, fissures) avec le médaillon coloré incrusté, dans le style du socle de la figurine.
- CHEMINS PAVÉS : les chemins sont faits de pierres plates sur un sentier de terre ; ceux déjà parcourus sont clairs et teintés de la couleur de l'Acte, les autres restent dans la pénombre.
- LA LUMIÈRE DE LA LARME : un halo bleu suit le grand frère et éclaire les cases proches ; les cases lointaines s'assombrissent.
- MARCHE PLUS VIVANTE : la figurine se penche pendant le saut, se tasse à la réception et soulève un petit nuage de poussière.
- Correction : le plateau de l'Acte XIII pouvait planter (couleur d'ambiance manquante).

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
