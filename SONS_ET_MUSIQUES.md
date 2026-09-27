# Sons et musiques — Brothers of Legacy : Tears and Blood

Tous les fichiers sont lus par `scripts/audio.gd`. Pour **remplacer** un son, dépose un fichier
**du même nom** (.ogg, .mp3 ou .wav) dans le bon dossier et supprime l'ancien. Un fichier absent est ignoré.

## Musiques — `assets/audio/musique/`
| Fichier | Quand |
|---|---|
| menu | Menu principal, Deck, Échos, Fusion, Reliquaire, Bestiaire, choix des Tours… (par défaut) |
| aventure | Écran Aventure, Histoire, écrans d'Acte, plateaux |
| combat | Combats normaux, élites, gardiens |
| boss | Boss de chapitre / d'Acte, boss des Tours — **manquant : boss_monde est joué à la place** |
| boss_monde | Écran et combats des Boss de Monde |
| invocation | Autel d'Invocation |
| tour_enfer / tour_paradis | Étages et combats normaux des Tours |
| victoire / defaite | Écran de résultat (joués une seule fois) |

## Bruitages — `assets/audio/sons/`
| Fichier | Quand |
|---|---|
| clic / retour | Tous les boutons (« retour » pour Retour / Fermer) — *provisoire, créé par programme* |
| erreur | Pas assez d'or, de gemmes ou de stamina — *provisoire* |
| or, coffre, niveau | Or gagné, coffre ouvert, montée de niveau (héros ou compte) |
| coup, coup_critique, magie, soin, bouclier, ko | Actions de combat (soin aussi : case Soin, élixirs) |
| boss_rugit | Skill d'un géant (Boss de Monde), changement de phase d'un boss |
| cercle, carte | Invocation : cercle magique (*provisoire*), cartes distribuées / retournées |
| rare_sr, rare_ssr, rare_ur, legende | Révélation d'une carte rare — *provisoires, créés par programme* |

Les fichiers ont été convertis en .ogg et leur volume égalisé. Les réglages fins (volume de chaque son,
musique de chaque écran, remplacements) sont en haut de `scripts/audio.gd`.
