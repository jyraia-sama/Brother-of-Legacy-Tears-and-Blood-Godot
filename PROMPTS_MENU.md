# Prompt ChatGPT — fond du menu principal « Les Deux Frères » (v0.37.0)

Le menu fonctionne déjà sans image (fond dessiné par le jeu). Quand l'illustration est prête :

1. Enregistre-la en **`assets/ui/menu_freres.png`** (format 16:9, idéalement 1920 x 1080 ou plus).
2. Lance le jeu : le menu l'utilise tout seul et cache le fond dessiné (le grand frère, Kaël, la lune et l'emblème dessinés disparaissent, c'est l'image qui les remplace).
3. Appuie sur **F1** dans le menu : deux cadres dorés montrent où sont les zones secrètes (lune et emblème). Si elles ne tombent pas sur la lune et le blason de l'image, donne-moi une capture et je recale `RECT_LUNE` / `RECT_EMBLEME` dans `scripts/main_menu.gd`.

## Zones à respecter (en % de l'image)

| Zone | Où | Contenu attendu |
|---|---|---|
| Barre du haut | 0–10 % de la hauteur | ciel sombre, rien d'important (le jeu y pose le compte et les ressources) |
| Barre du bas | 90–100 % de la hauteur | sol sombre, rien d'important (boutons du Royaume) |
| Colonne gauche | 0–23 % de la largeur | décor simple et sombre (boutons de la Lame) |
| Colonne droite | 77–100 % de la largeur | décor simple et sombre (boutons du Sang) |
| Grand frère | 24–43 % de la largeur, 20–82 % de la hauteur | en pied, tourné vers la droite |
| Kaël | 57–79 % de la largeur, 22–65 % de la hauteur | tourné vers la gauche |
| **Lune rouge (secret)** | 37–41 % de la largeur, 12–19 % de la hauteur | petite lune rouge sang |
| **Blason (secret)** | 44–56 % de la largeur, 36–57 % de la hauteur | médaillon rond au centre |
| Sous le blason | 39–61 % de la largeur, 59–80 % de la hauteur | zone calme (le guide Premiers pas s'y affiche) |

## Prompt (à coller dans ChatGPT)

```
Illustration de fond pour le menu principal d'un jeu vidéo dark fantasy, format paysage 16:9 (1920x1080), style peinture numérique détaillée et sombre, cohérent avec un jeu de cartes gacha gothique.

Composition : l'image est coupée en deux par une fine fente de lumière dorée en diagonale, qui part du haut à environ 58 % de la largeur et descend jusqu'en bas à environ 42 % de la largeur.

- Moitié gauche (la Lame) : tons rouge sang et braises, cendres qui montent. Au centre de cette moitié (entre 24 % et 43 % de la largeur), le grand frère en pied : jeune homme aux cheveux sombres, armure noire ciselée, long manteau bleu nuit brodé d'un phénix argenté, médaillon bleu sur la poitrine, épée longue tenue vers le bas, tourné vers la droite (vers la fente).
- Moitié droite (le Sang) : tons bleu nuit et violet, brume, lueurs bleues qui tombent. Entre 57 % et 79 % de la largeur, son petit frère Kaël, buste et taille : cheveux noirs en bataille, armure sombre aux reflets rouges, un pendentif mi-bleu mi-rouge, une goutte de sang lumineuse flottant au-dessus de sa main ouverte, tourné vers la gauche (vers son frère).
- Exactement au centre de l'image (entre 44 % et 56 % de la largeur, 36 % à 57 % de la hauteur) : un grand blason rond flottant sur la fente, deux ailes de phénix dorées encadrant une gemme brisée en deux, une moitié bleue et une moitié rouge.
- En haut, côté gauche, vers 37 à 41 % de la largeur et 12 à 19 % de la hauteur : une petite lune rouge sang dans le ciel.

Contraintes : les bandes du haut (10 %) et du bas (10 %) restent sombres et calmes ; les colonnes de gauche (0 à 23 %) et de droite (77 à 100 %) restent sombres, sans personnage ni détail important, car des boutons s'y superposent. La zone juste sous le blason reste calme. Aucun texte, aucun logo, aucun bouton, aucune interface dans l'image.
```
