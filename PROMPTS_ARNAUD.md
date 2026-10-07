# Prompts ChatGPT : Arnaud Riff-de-Sang (v0.49.0)

Héros hommage à Arnaud, l'ami qui a donné l'envie de créer le jeu.

| Fichier | Héros | Rareté | Élément · rôle |
|---|---|---|---|
| `arnaud_riff` | Arnaud Riff-de-Sang | UR | Feu · soutien (arrière) |
| `arnaud_riff_evo` | Arnaud, Roi du Chaos Écarlate (évolution) | UR | Feu · soutien |

**Le personnage** : un barde punk de la lignée du Sang. Il ne se bat pas à l'épée : il galvanise ses alliés et
assourdit ses ennemis avec sa guitare. Grand sourire insolent, crête rouge sang, cuir clouté, guitare électrique
taillée comme une hache de guerre, dont les cordes rougeoient comme des braises.

**Ses sorts**
- Niv. 1, **Riff Incendiaire** : 90 % de puissance à tous les ennemis, 30 % de chance de Brûlure (2 tours).
- Niv. 10, **Crête de Défi** (passif) : toute l'équipe ATK +10 %, AGI +12 %.
- Niv. 20, **Solo Déchaîné** : toute l'équipe ATK +20 % et AGI +15 % (2 tours), retire les afflictions.
- Niv. 30, **Larsen Assourdissant** : 120 % de puissance à tous les ennemis, 35 % de chance de Silence (1 tour).
- Évolution, niv. 40, **Rappel du Public** (passif) : survit une fois à un coup fatal, toute l'équipe AGI +8 %.

Il est invocable (UR) et il est **offert une fois** à qui termine le Donjon d'Arnaud (le secret du menu principal).
Tant que ses images n'existent pas, le jeu affiche un médaillon rouge avec la lettre « A ».

---

## 1. Le portrait → `arnaud_riff.png`

Joins la planche de référence de la D.A. (`planche_39.png`, les 8 hommages).

```
Crée le portrait d'un personnage pour les cartes d'un jeu mobile dark fantasy, EXACTEMENT dans le même style que la planche jointe : peinture numérique réaliste et très détaillée, fond brun sombre texturé façon vieux parchemin, éclairage chaud et dramatique venant du haut à gauche.

FORMAT, À RESPECTER STRICTEMENT :
- image carrée 1024x1024, UN SEUL personnage ;
- cadré à mi-corps, tête dans le tiers haut, bien centré, qui ne dépasse jamais du cadre ;
- aucun texte, aucun chiffre, aucun nom, aucun logo, aucun cadre de carte.

LE PERSONNAGE : un barde punk humain d'une trentaine d'années, dans un monde médiéval dark fantasy. Haute crête iroquoise rouge sang, côtés du crâne rasés, petite barbe de trois jours, sourire insolent et regard plein d'énergie, plusieurs anneaux d'argent à l'oreille. Veste sans manches en cuir noir usé couverte de clous et de petites pointes de métal, épaulette en fer cabossée sur une épaule, avant-bras bandés de cuir, bracelets cloutés, ceinture à boucle en forme de crâne. Il joue d'une guitare électrique de style médiéval taillée comme une hache de guerre, en bois sombre cerclé de fer forgé, dont les cordes rougeoient comme des braises. POSE : il est en plein solo, penché en arrière, une jambe pliée, la tête rejetée en arrière et la bouche ouverte comme s'il criait la dernière note, des étincelles orangées s'échappent des cordes. Les couleurs viennent du personnage (cuir noir, rouge sang, métal) ; le feu n'est qu'une petite lueur discrète autour des cordes.
```

## 2. La figurine de combat → `arnaud_riff_figurine.png`

Joins deux images : le portrait que tu viens d'obtenir, et une figurine réussie (par exemple celle de la Combattante
Ardente) pour le rendu.

```
Crée une figurine de jeu de plateau pour un jeu mobile dark fantasy : le personnage du portrait joint, vu EN PIED, dans le même rendu peint que la figurine jointe (éclairage dramatique venant du haut à gauche, petit socle rond en pierre sombre sous les pieds).

FORMAT, À RESPECTER STRICTEMENT :
- image carrée 1024x1024, UN SEUL personnage ;
- en pied, de trois quarts, tourné vers la DROITE de l'image, debout sur son petit socle rond en pierre sombre, entier de la haute crête jusqu'au socle (la crête ne doit pas être coupée), centré, qui ne touche pas les bords ;
- même visage, même crête rouge sang, même tenue de cuir noir clouté, même guitare-hache aux cordes rougeoyantes que sur le portrait ;
- attitude : jambes écartées, guitare tenue en travers du corps, une main qui gratte les cordes, tête relevée, sourire insolent ;
- proportions légèrement stylisées (tête un peu plus grande), silhouette très lisible même en tout petit ;
- fond VERT UNI très vif (#00FF00), sans dégradé, sans ombre portée, sans décor ; aucun vert sur le personnage, la guitare ou le socle ;
- aucun texte, aucun chiffre, aucun cadre.
```

## 3. (Facultatif) L'évolution → `arnaud_riff_evo.png` et sa figurine

Même texte que le portrait (et que la figurine), en remplaçant le paragraphe du personnage par :

```
LE PERSONNAGE : le même barde punk, devenu une légende : crête rouge sang plus haute et flamboyante, long manteau de cuir noir à col relevé couvert de clous d'argent et de petites chaînes, épaulettes en fer noir ornées de petits crânes, guitare-hache plus grande en fer noir gravé de runes rouges, cordes incandescentes. POSE : debout sur un ampli de pierre gravé, guitare levée au-dessus de la tête d'une main, l'autre poing levé vers le ciel, il hurle de joie. Une petite pluie d'étincelles autour des cordes, rien de plus.
```

---

## Ce que je fais quand tu m'envoies les images

```
python3 outils/decouper_planche.py arnaud_riff.png arnaud_riff
python3 outils/decouper_miniatures.py arnaud_riff_figurine.png --figurines arnaud_riff
```

(et pareil avec `arnaud_riff_evo` pour l'évolution). Le jeu les utilise automatiquement : Deck, invocations, Galerie
d'Art et figurine en combat.
