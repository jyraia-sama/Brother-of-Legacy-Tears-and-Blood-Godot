# Langues du jeu (français / anglais)

Le jeu est écrit en français. La version anglaise vient du fichier **`langues/en.po`** :
chaque texte français (`msgid`) y a sa traduction anglaise (`msgstr`).

- Le joueur choisit sa langue dans **Paramètres → LANGUE · LANGUAGE** (Français / English).
  Sans choix enregistré, le jeu est en français.
- Les textes simples des boutons et étiquettes se traduisent tout seuls.
- Les textes « à trous » (avec `%d`, `%s`…) passent par `UiCommun.t("…") % [...]` dans le code.
- Un texte absent du fichier `.po` reste en français : rien ne casse.
- Le jeu ne lit pas le `.po` directement : il est recopié dans `scripts/traduction_en.gd` (chargé par
  `Ecran.appliquer_langue`). **Ne rien régler** dans Projet → Paramètres → Localisation : modifier les réglages
  du projet obligerait tous les joueurs PC/Android à réinstaller le jeu.
- Changer de langue redémarre le jeu (bouton « Redémarrer le jeu » aussi dans les Paramètres).

## Ce qui est traduit
- Étape 1 : les menus, boutons, fenêtres, messages, guides et aides.
- Étape 2 (v0.84) : toutes les données du jeu : noms, races et sorts des 334 unités et évolutions, familiers,
  Actes et chapitres, dialogues de l'histoire, épilogues, événements, objets, Donjons, Tours, quêtes, succès,
  ainsi que les textes assemblés morceau par morceau (environ 5 600 textes au total).
- Seul le journal des mises à jour (Nouveautés) reste en français.

## Comment les données sont traduites
- `UnitesData.get_unite()`, `ActesData.get_acte()`, `DialoguesData.lignes()` et `FamiliersData.get_familier()`
  renvoient une copie traduite quand le jeu est en anglais (en français, la donnée d'origine, sans rien changer).
- Éléments et rôles : `UnitesData.nom_element(e)` et `UnitesData.nom_role(r)`.
- Les textes du code passent par `UiCommun.t("…")` au moment de l'affichage. Ne jamais traduire un texte
  qui sert de clé, d'identifiant ou qui est comparé (`== "…"`) : la traduction ne sert qu'à afficher.

## Ajouter ou corriger une traduction
1. Ouvre `langues/en.po` (avec un éditeur de texte ou Poedit).
2. Cherche le texte français, corrige la ligne `msgstr` juste en dessous.
   Puis lance `python3 outils/traduction/po_vers_gd.py` (ou demande à Claude) pour mettre à jour le jeu.
3. Pour voir les textes du code qui n'ont pas encore de traduction :
   `python3 outils/traduction/textes_a_traduire.py`
