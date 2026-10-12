# Prompts ChatGPT : kit d'interface peint (tous les menus)

Le jeu a maintenant un **thème commun** : tous les boutons, onglets, champs, panneaux, fenêtres et titres utilisent les mêmes images, rangées dans `assets/ui/kit/`.
Une version **dessinée en code** est déjà en place. Ces 3 planches la remplacent par une version **peinte**, dans le style du jeu.

**Joindre** la planche de référence habituelle (style peint). Envoie-moi chaque planche : je la découpe (`outils/decouper_kit_ui.py`) et le thème l'utilise tout seul.
Les boutons survolés, les onglets survolés et le champ actif sont dérivés automatiquement.

## Planche 1 — boutons et onglets

```
Crée une planche d'ÉLÉMENTS D'INTERFACE pour un jeu mobile dark fantasy, dans le même style peint que la planche de référence jointe : peinture numérique réaliste et très détaillée, métal forgé (fer noirci, bronze et or vieilli), cuir bordeaux sombre, petites gemmes rouges, éclairage chaud venant du haut à gauche, rendu net et lisible même en petit.

FORMAT, À RESPECTER STRICTEMENT :
- image paysage 1536x1024, découpée en une GRILLE de 3 colonnes x 2 lignes (6 cases égales), séparées par des traits NOIRS bien droits et épais ;
- dans chaque case, UN seul élément, centré, qui occupe environ 80 % de la largeur de la case ;
- fond : VERT UNI très vif (#00FF00) partout autour des éléments, sans dégradé, sans ombre portée sur le fond ; AUCUN vert sur les éléments eux-mêmes ;
- les éléments sont vus bien DE FACE, parfaitement droits (pas de perspective, pas d'inclinaison), symétriques gauche/droite ;
- aucun texte, aucune lettre, aucun chiffre, aucun logo, aucune icône à l'intérieur.
- TRÈS IMPORTANT pour les boutons et les onglets : toute la décoration est concentrée aux DEUX EXTRÉMITÉS (embouts ornés à gauche et à droite) ; tout le MILIEU est une bande unie et régulière (même matière, même bordure en haut et en bas, sans motif ni gemme au centre), pour qu'on puisse l'étirer en largeur.

Les 6 éléments, dans l'ordre (ligne du haut de gauche à droite, puis ligne du bas) :
1. BOUTON (repos) : plaque horizontale allongée (environ 3 fois plus large que haute), intérieur en cuir bordeaux très sombre légèrement bombé, fine bordure d'or vieilli tout autour, embouts de bronze ouvragés aux deux extrémités avec une petite gemme rouge sertie dans chaque embout.
2. BOUTON (survolé) : EXACTEMENT le même bouton, mais plus lumineux : le cuir est d'un rouge plus chaud, la bordure d'or brille, les gemmes sont éclairées de l'intérieur.
3. BOUTON (appuyé) : EXACTEMENT le même bouton, mais enfoncé : plus sombre, l'ombre est en haut à l'intérieur, la lumière en bas.
4. BOUTON (inactif) : EXACTEMENT le même bouton, mais éteint : pierre et fer gris ternes, sans or, gemmes grises, un peu poussiéreux.
5. ONGLET (actif) : comme le bouton mais plus court (environ 2,5 fois plus large que haut), le bas est DROIT et ouvert (pas de bordure en bas), le haut arrondi ; cuir rouge chaud, bordure d'or brillante.
6. ONGLET (inactif) : EXACTEMENT le même onglet, mais sombre et terne : cuir presque noir, bordure de bronze sombre.
```

## Planche 2 — champ, coin, plaque de titre, séparateur

```
Crée une planche d'ÉLÉMENTS D'INTERFACE pour un jeu mobile dark fantasy, dans le même style peint que la planche de référence jointe : peinture numérique réaliste et très détaillée, métal forgé (fer noirci, bronze et or vieilli), cuir bordeaux sombre, petites gemmes rouges, éclairage chaud venant du haut à gauche, rendu net et lisible même en petit.

FORMAT, À RESPECTER STRICTEMENT :
- image paysage 1536x1024, découpée en une GRILLE de 2 colonnes x 2 lignes (4 cases égales), séparées par des traits NOIRS bien droits et épais ;
- dans chaque case, UN seul élément, centré ;
- fond : VERT UNI très vif (#00FF00) partout autour des éléments, sans dégradé, sans ombre portée sur le fond ; AUCUN vert sur les éléments eux-mêmes ;
- les éléments sont vus bien DE FACE, parfaitement droits (pas de perspective, pas d'inclinaison), symétriques gauche/droite ;
- aucun texte, aucune lettre, aucun chiffre, aucun logo, aucune icône à l'intérieur.

Les 4 éléments, dans l'ordre (ligne du haut de gauche à droite, puis ligne du bas) :
1. CHAMP DE SAISIE : cadre horizontal allongé (environ 3 fois plus large que haut), intérieur creusé noir profond (comme un encrier), fine bordure de bronze, petits rivets aux quatre coins ; la bordure du milieu est unie et régulière (on l'étire en largeur).
2. ORNEMENT DE COIN : ornement d'or vieilli en forme d'équerre (pour le coin HAUT-GAUCHE d'un cadre) : deux branches droites qui partent de l'angle vers la droite et vers le bas, avec un losange ou une petite gemme rouge dans l'angle et de fines volutes ; l'angle est en haut à gauche de la case.
3. PLAQUE DE TITRE : bannière horizontale très allongée (environ 5 fois plus large que haute) : bande de velours bordeaux très sombre, filets d'or fins en haut et en bas, embouts ornés aux deux extrémités (pointes ou losanges dorés) ; le milieu est uni et régulier (le titre du jeu s'écrit dessus).
4. SÉPARATEUR : filet horizontal très fin et très long (environ 20 fois plus large que haut) en or vieilli, qui s'affine et s'efface vers les deux bouts, avec un petit losange orné au centre.
```

## Planche 3 — grand cadre de panneau

```
Crée une planche d'ÉLÉMENTS D'INTERFACE pour un jeu mobile dark fantasy, dans le même style peint que la planche de référence jointe : peinture numérique réaliste et très détaillée, métal forgé (fer noirci, bronze et or vieilli), cuir bordeaux sombre, petites gemmes rouges, éclairage chaud venant du haut à gauche, rendu net et lisible même en petit.

FORMAT, À RESPECTER STRICTEMENT :
- image CARRÉE 1024x1024 contenant UN SEUL élément : un GRAND CADRE DE PANNEAU vu de face, qui remplit toute l'image avec une petite marge de vert autour ;
- le cadre : bordure de fer noirci et d'or vieilli d'épaisseur MODÉRÉE (environ 6 % de la largeur), coins ornés (équerres d'or ciselées, petite gemme rouge dans chaque coin, fines volutes) ;
- TRÈS IMPORTANT : les quatre CÔTÉS du cadre (entre les coins) sont des barres droites unies et régulières, sans motif au milieu, pour pouvoir les étirer ; toute la décoration est dans les quatre coins ;
- l'INTÉRIEUR du cadre est entièrement VERT UNI (#00FF00), comme le fond tout autour ;
- fond : VERT UNI très vif (#00FF00) partout autour des éléments, sans dégradé, sans ombre portée sur le fond ; AUCUN vert sur les éléments eux-mêmes ;
- les éléments sont vus bien DE FACE, parfaitement droits (pas de perspective, pas d'inclinaison), symétriques gauche/droite ;
- aucun texte, aucune lettre, aucun chiffre, aucun logo, aucune icône à l'intérieur.
```
