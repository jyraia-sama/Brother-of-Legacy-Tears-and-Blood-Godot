# Images pour les effets d'invocation (à demander à ChatGPT)

Les effets d'invocation **fonctionnent déjà sans aucune image** : le jeu dessine lui-même le cercle, les rayons, le halo, les éclairs et les étincelles.
Chaque image que tu ajoutes remplace le dessin correspondant et rend l'effet plus beau.

**Règles importantes**
- Dossier : `assets/invocation/`. Les noms de fichiers doivent être **exactement** ceux indiqués ci-dessous.
- Les effets (cercle, rayons, halo, éclair, étincelle) doivent avoir un **fond transparent**. Demande-le bien à ChatGPT.
  Si l'image arrive avec un fond noir ou blanc, ne l'utilise pas : un carré apparaîtrait autour de l'effet.
- Les rayons, l'éclair et l'étincelle doivent être **blancs** : le jeu les colore lui-même selon la rareté (violet SR, or SSR, rouge UR, blanc doré pour une Légende).
- Après avoir ajouté les images, Godot les importe tout seul. Relance le jeu (F5).

---

## 1. Dos de carte — `dos_carte.png`
Format portrait (1024 x 1536)
> Crée le dos d'une carte de jeu dark fantasy, format portrait, sans texte. Cadre ornementé en or vieilli avec des épines, fond rouge sang très sombre, au centre un sceau circulaire gravé d'une goutte de sang et de deux épées croisées, motifs gothiques symétriques, légère lueur dorée sur les bords. La carte remplit toute l'image, fond transparent autour des coins arrondis. Style peint, haute qualité.

## 2. Cercle d'invocation — `cercle_invocation.png`
Format carré (1024 x 1024), fond transparent
> Crée un cercle d'invocation magique vu de dessus, parfaitement centré et circulaire, sur fond transparent (PNG). Plusieurs anneaux concentriques de runes anciennes, une étoile à six branches, symboles gothiques, lignes lumineuses dorées et rouge sang qui brillent. Rien en dehors du cercle, pas de texte, pas de personnage.

## 3. Rayons de lumière — `rayons.png`
Format carré (1024 x 1024), fond transparent, **en blanc**
> Crée des rayons de lumière divine blancs qui partent du centre de l'image vers l'extérieur, en éventail tout autour (environ 16 rayons de largeurs variées), très lumineux au centre et qui s'estompent en transparence vers les bords. Fond entièrement transparent (PNG), couleur blanche uniquement, pas d'autre élément.

## 4. Halo divin — `halo.png`
Format paysage (1536 x 1024), fond transparent
> Crée un halo d'ange doré vu légèrement en perspective (anneau ovale horizontal), lumineux, avec une douce lueur blanc doré et quelques petites particules scintillantes autour. Centré, fond entièrement transparent (PNG), aucun autre élément.

## 5. Éclair — `eclair.png`
Format portrait (1024 x 1536), fond transparent, **en blanc**
> Crée un éclair vertical blanc très lumineux qui descend du haut de l'image jusqu'en bas, avec quelques ramifications fines et une lueur autour. Fond entièrement transparent (PNG), couleur blanche uniquement.

## 6. Étincelle — `etincelle.png`
Format carré (1024 x 1024, le jeu la réduit), fond transparent, **en blanc**
> Crée une petite étoile scintillante blanche à 4 branches avec un cœur très lumineux et une douce lueur ronde, centrée, sur fond entièrement transparent (PNG). Uniquement blanc, rien d'autre.

---

## 7. Bandeaux des événements d'invocation — `evenements/<id>.png`
Dossier : `assets/invocation/evenements/`. Le nom est l'`id` de l'événement dans `scripts/evenements.gd`.
Format paysage (1536 x 1024). Le jeu n'affiche qu'une **bande horizontale au milieu** de l'image : garde donc l'essentiel au centre.
Le **titre est écrit par le jeu** : demande une image **sans texte**, avec la partie gauche plus sombre pour que le texte reste lisible.

`lune_de_sang.png`
> Illustration dark fantasy très large, format paysage, sans texte : une immense lune de sang rouge au-dessus d'un champ de bataille gothique, silhouettes d'un empereur déchu en armure noire, d'un dragon d'ombre et d'un archange aux ailes noires sur la droite, brume rouge. La moitié gauche est plus sombre et plus vide (pour y écrire un titre). Tout l'important se trouve dans la bande horizontale centrale de l'image.

`aube_celeste.png`
> Illustration fantasy lumineuse très large, format paysage, sans texte : lever de soleil doré au-dessus des nuages, un cheval céleste ailé, un phénix de feu et un chien sylvestre majestueux sur la droite, rayons de lumière divine. La moitié gauche est plus sombre et plus simple (pour y écrire un titre). Tout l'important se trouve dans la bande horizontale centrale de l'image.

Pour un **nouvel événement** : reprends un des prompts ci-dessus, change l'ambiance et les créatures mises en avant, et enregistre l'image sous le nom `<id>.png`.
