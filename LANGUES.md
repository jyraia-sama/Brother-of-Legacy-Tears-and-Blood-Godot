# Langues du jeu (français / anglais)

Le jeu est écrit en français. La version anglaise vient du fichier **`langues/en.po`** :
chaque texte français (`msgid`) y a sa traduction anglaise (`msgstr`).

- Le joueur choisit sa langue dans **Paramètres → LANGUE · LANGUAGE** (Français / English).
  Sans choix enregistré, le jeu se met en anglais si l'appareil est en anglais, sinon en français.
- Les textes simples des boutons et étiquettes se traduisent tout seuls.
- Les textes « à trous » (avec `%d`, `%s`…) passent par `UiCommun.t("…") % [...]` dans le code.
- Un texte absent du fichier `.po` reste en français : rien ne casse.

## Ce qui est traduit (étape 1)
Les menus, boutons, fenêtres, messages, guides et aides (environ 2 600 textes).

## Ce qui reste en français (étape 2, à venir)
Les données du jeu : noms et compétences des unités, évolutions, familiers, Actes et chapitres,
dialogues de l'histoire, journal des mises à jour, ainsi que quelques textes assemblés morceau par morceau.

## Ajouter ou corriger une traduction
1. Ouvre `langues/en.po` (avec un éditeur de texte ou Poedit).
2. Cherche le texte français, corrige la ligne `msgstr` juste en dessous.
3. Pour voir les textes du code qui n'ont pas encore de traduction :
   `python3 outils/traduction/textes_a_traduire.py`
