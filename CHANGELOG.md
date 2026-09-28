# Journal des mises à jour — Brothers of Legacy : Tears and Blood

Version actuelle : **0.20.2** (2026-09-28)

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
