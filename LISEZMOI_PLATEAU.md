# Plateaux de jeu : installation

Décompresse à la racine du projet (là où se trouve project.godot) et réponds OUI pour tout remplacer.
Tes images d'Actes (assets/actes/) ne sont PAS dans ce pack : elles ne seront pas écrasées.

## Contenu
- scripts/plateau_generateur.gd : crée les 72 plateaux (toujours les mêmes pour un chapitre donné)
- scripts/plateau.gd            : le plateau jouable (pion, cases, événements)
- scenes/plateau.tscn           : la scène du plateau
- scripts/ecran_acte.gd         : un clic sur un chapitre ouvre maintenant son plateau (+ ✓ si terminé)
- scripts/actes_data.gd         : ajoute chapitre en cours, or et chapitres terminés
- assets/plateaux/fond_01.png à fond_12.png : fond du plateau pour chaque Acte (à remplacer quand tu veux, même nom)

## Commandes sur le plateau
- Clic sur une case qui brille : avancer
- Glisser la souris : regarder le plateau · Molette : zoom · Espace : recentrer · Échap : retour

## Cases
Combat, Élite (couronne), Gardien (bouclier, garde les carrefours), Boss (fin du chapitre),
Coffre d'or, Autel de soin, Mystère (trésor, bénédiction ou embuscade), Piège.

## Régler la difficulté
Tout se trouve dans _parametres() de plateau_generateur.gd (longueur, nombre de voies, taux d'Élites...).

## Brancher le vrai combat plus tard
Dans plateau.gd, fonction _lancer_combat() : ouvrir la scène de combat, puis appeler
_victoire(id) ou _defaite(id) selon le résultat.

## Provisoire (en attendant la sauvegarde)
L'or et les chapitres terminés sont gardés tant que le jeu est ouvert, mais pas encore sauvegardés.
