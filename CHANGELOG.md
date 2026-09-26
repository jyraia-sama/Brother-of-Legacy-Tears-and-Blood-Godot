# Journal des mises à jour — Brothers of Legacy : Tears and Blood

Version actuelle : **0.11.1** (2026-09-26)

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
