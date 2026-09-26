# Guide : versions du jeu et retour en arrière

Tu as deux filets de sécurité, qui se complètent :

1. **GitHub Desktop** : l'historique complet de ton projet sur GitHub. C'est la méthode la plus sûre.
2. **L'onglet « Versions » dans Godot** : une archive `.zip` de chaque version, rangée à côté du projet. C'est la méthode la plus simple, et elle marche même sans Internet.

---

## 1. La routine à chaque nouvelle version (2 minutes)

1. Dans `scripts/version.gd` : change `NUMERO` et `DATE`, puis ajoute la nouvelle version **en haut** de `HISTORIQUE`.
   Le jeu montrera automatiquement les nouveautés au joueur au prochain lancement.
2. Recopie la même entrée dans `CHANGELOG.md`.
3. Dans Godot, onglet **Versions** : clique sur **Sauvegarder cette version**.
4. Dans GitHub Desktop :
   - écris un **Summary** (en bas à gauche), par exemple `v0.11.0 — Stamina et niveau de compte` ;
   - clique sur **Commit to main**, puis sur **Push origin** ;
   - va dans l'onglet **History**, fais un clic droit sur ce commit, choisis **Create Tag…**, tape `v0.11.0`, puis clique à nouveau sur **Push origin**.

La numérotation suit la forme `MAJEUR.MINEUR.CORRECTIF` :

- **0.x.y** : le jeu est en développement. La version **1.0.0** sera la première version complète.
- **MINEUR +1** (par exemple 0.11.0 → 0.12.0) : une nouveauté, comme un nouveau mode ou un nouvel écran.
- **CORRECTIF +1** (par exemple 0.11.0 → 0.11.1) : uniquement des corrections de bugs ou de l'équilibrage.

---

## 2. Activer l'onglet « Versions » dans Godot (une seule fois)

1. Extrais le zip de la mise à jour à la racine du projet. Le dossier `addons/bol_versions/` est ajouté.
2. Menu **Projet → Paramètres du projet…**, onglet **Extensions** (*Plugins*).
3. Sur la ligne **Versions du jeu (BoL)**, coche **Activé**.
4. Un onglet **Versions** apparaît à droite, à côté de l'Inspecteur.

Les boutons de l'onglet :

| Bouton | Ce qu'il fait |
|---|---|
| **Sauvegarder cette version** | Crée `BoL_v0.11.0_2026-09-26_11h45.zip` dans le dossier `<ton projet>_versions`, à côté du projet. Les dossiers `.godot`, `.git` et `docs` (l'export web) ne sont pas inclus. |
| **Ouvrir dans un nouveau dossier (sans risque)** | Extrait la version choisie dans un **nouveau** dossier à côté du projet. Ensuite, dans le Gestionnaire de projets de Godot : **Importer**, puis choisis le fichier `project.godot` de ce dossier. Ton projet actuel n'est pas touché. |
| **Remplacer le projet par cette version** | Retour en arrière réel. L'état actuel est **d'abord sauvegardé automatiquement** (fichier `..._avant_retour.zip`), puis le projet est remplacé et l'éditeur redémarre. Pour annuler, il suffit de remplacer à nouveau avec le fichier `avant_retour`. |
| **Ouvrir le dossier des sauvegardes** | Ouvre le dossier des archives dans l'explorateur Windows. |

---

## 3. GitHub Desktop : installation (une seule fois)

1. Télécharge et installe **GitHub Desktop** depuis https://desktop.github.com, puis connecte-toi avec ton compte GitHub.
2. Deux cas possibles :
   - **Ton dossier Godot est déjà le dépôt GitHub** (il contient un dossier caché `.git`) : menu **File → Add local repository…**, puis choisis le dossier du projet.
   - **Sinon** : menu **File → Clone repository…**, choisis `Brother-of-Legacy-Tears-and-Blood-Godot`, puis copie tous les fichiers de ton projet Godot dans le dossier cloné et ouvre ce dossier dans Godot.
3. Vérifie que le fichier `.gitignore` contient bien la ligne `.godot/`. Ce dossier se recrée tout seul et ne doit pas être envoyé sur GitHub.

---

## 4. GitHub Desktop : revenir en arrière

**Ferme Godot avant ces manipulations**, puis rouvre le projet. Tu peux aussi faire **Projet → Recharger le projet actuel**.

### a) Des modifications ont cassé le jeu, mais tu n'as pas encore fait de commit
Onglet **Changes** : fais un clic droit sur un fichier et choisis **Discard changes…**. Tu peux aussi faire un clic droit en haut de la liste et choisir **Discard all changes…**. Tout revient à ta dernière version enregistrée.

### b) Essayer une ancienne version sans rien perdre
1. Onglet **History** : fais un clic droit sur le commit de la version voulue (par exemple `v0.10.0`).
2. Choisis **Create branch from commit** et nomme la branche `essai-v0.10.0`.
3. Ouvre Godot : tu es sur l'ancienne version.
4. Pour revenir à la dernière version : en haut, **Current branch → main**.

### c) Annuler définitivement une version ratée
1. Onglet **History** : fais un clic droit sur le commit fautif et choisis **Revert changes in commit**.
2. GitHub Desktop crée un nouveau commit qui annule ce changement. Clique ensuite sur **Push origin**.
   L'historique est conservé : tu pourras toujours récupérer ce travail plus tard.

> Rappel : le site GitHub Pages utilise le dossier `docs/`. Après un retour en arrière, refais l'**export Web** depuis Godot, puis fais Commit et Push pour mettre le jeu en ligne à jour.

---

## 5. Et la sauvegarde des joueurs ?

La partie du joueur est enregistrée à part, dans `user://sauvegarde.json`. Elle n'est donc **pas** effacée par un retour à une ancienne version du projet.
Chaque sauvegarde retient la version du jeu qui l'a écrite (`version_jeu`), et le journal des nouveautés s'affiche une seule fois par version.
