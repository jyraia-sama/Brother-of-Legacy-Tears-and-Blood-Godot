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
4. Toujours dans l'onglet **Versions** : clique sur **Publier cette version**.
   L'outil exporte le jeu web (`docs/`) **et** la mise à jour pour ordinateur (`docs/maj/`). Compte une à trois minutes.
   - Coche **Mise à jour obligatoire** si l'Arène ou le serveur ont changé : les joueurs ne pourront pas cliquer « Plus tard ».
   - Si le cadre affiche **INSTALLATION COMPLÈTE CRÉÉE**, suis aussi la partie 1 bis ci-dessous.
5. Dans GitHub Desktop :
   - écris un **Summary** (en bas à gauche), par exemple `v0.11.0 — Stamina et niveau de compte` ;
   - clique sur **Commit to main**, puis sur **Push origin** ;
   - va dans l'onglet **History**, fais un clic droit sur ce commit, choisis **Create Tag…**, tape `v0.11.0`, puis clique à nouveau sur **Push origin**.

Au prochain lancement, l'application Windows / Mac de chaque joueur affiche « Mise à jour disponible » avec les nouveautés. Un clic sur **Mettre à jour** télécharge la version, puis le jeu redémarre dessus. La version web, elle, est à jour dès le Push (comme avant).

La numérotation suit la forme `MAJEUR.MINEUR.CORRECTIF` :

- **0.x.y** : le jeu est en développement. La version **1.0.0** sera la première version complète.
- **MINEUR +1** (par exemple 0.11.0 → 0.12.0) : une nouveauté, comme un nouveau mode ou un nouvel écran.
- **CORRECTIF +1** (par exemple 0.11.0 → 0.11.1) : uniquement des corrections de bugs ou de l'équilibrage.

---

## 1 bis. Installation complète (rare)

Une simple mise à jour ne suffit pas quand **Godot** change de version (4.7 → 4.8…), quand les **réglages du projet** changent (Projet → Paramètres du projet, nouvel Autoload…) ou quand le système de mise à jour lui-même change. L'outil le détecte tout seul et crée alors, dans le dossier `build/` du projet (il s'ouvre automatiquement) :

- `BrothersOfLegacy-Windows.zip`
- `BrothersOfLegacy-Mac.zip`

Ces fichiers sont trop gros pour le dépôt : on les dépose dans une **Release** GitHub.

1. Fais d'abord le Commit, le Push et le tag (étape 5 ci-dessus).
2. Sur github.com, ouvre ton dépôt, puis **Releases** (colonne de droite) → **Draft a new release**.
3. **Choose a tag** : choisis le tag de la version (par exemple `v0.40.0`). Titre : le même.
4. Glisse les deux fichiers `.zip` dans la zone « Attach binaries », puis clique sur **Publish release**.

Les joueurs verront « Nouvelle version : réinstallation nécessaire » avec un bouton qui télécharge directement le bon fichier. Leur partie n'est pas perdue (elle est sur leur ordinateur et sur leur compte).

---

## 1 ter. Installer le jeu (famille et amis)

Lien à envoyer : **https://github.com/jyraia-sama/Brother-of-Legacy-Tears-and-Blood-Godot/releases/latest**

- **Windows** : télécharger `BrothersOfLegacy-Windows.zip`, clic droit → **Extraire tout**, puis lancer `BrothersOfLegacy.exe` dans le dossier « Brothers of Legacy ». Au premier lancement, Windows affiche « Windows a protégé votre ordinateur » : cliquer **Informations complémentaires** → **Exécuter quand même**. Pour plus de confort : clic droit sur l'exe → **Afficher d'autres options** → **Envoyer vers → Bureau (créer un raccourci)**.
- **Mac** : télécharger `BrothersOfLegacy-Mac.zip` (le Mac le décompresse tout seul), glisser l'application dans **Applications** puis l'ouvrir. Le Mac la bloque la première fois : **Réglages Système → Confidentialité et sécurité**, tout en bas, **Ouvrir quand même**. Si le Mac dit que l'application est « endommagée », ouvrir le Terminal et taper :
  `xattr -cr "/Applications/Brother of Legacy - Tears and Blood.app"`
  puis relancer. Ces manipulations ne sont à faire qu'une fois.

- **Android** : ouvrir sur le téléphone le lien
  **https://jyraia-sama.github.io/Brother-of-Legacy-Tears-and-Blood-Godot/telecharger/BrothersOfLegacy-Android.apk**
  puis ouvrir le fichier téléchargé et choisir **Installer**. La première fois, le téléphone demande d'autoriser le navigateur (Chrome…) à installer des applications : **Paramètres → Autoriser cette source**, puis revenir et **Installer**. Si Play Protect affiche un avertissement : **Plus de détails → Installer quand même**.
- **iPhone / iPad** : pas d'application (Apple ne le permet pas sans l'App Store). Ouvrir le jeu web dans **Safari**, bouton **Partager → Sur l'écran d'accueil** : il s'ouvre ensuite comme une appli et il est toujours à jour.

Ensuite, plus rien à faire : le jeu se met à jour tout seul.

### L'application Android (APK)

L'APK est fabriqué par Claude, qui a le kit Android et la **clé de signature** de l'application. Il est rangé dans `docs/telecharger/` et publié avec le site : pas de Release à faire pour Android.
Sur ton PC, quand l'outil de publication refait les installations complètes, il saute l'APK (message « APK Android non refait ») : demande alors à Claude de le refaire.
La clé de signature (fichier `brothersoflegacy.keystore` + son mot de passe) est conservée dans les documents du Projet Claude. **Ne la perds pas et ne la partage pas** : sans elle, une nouvelle application ne pourrait pas remplacer l'ancienne sur les téléphones (il faudrait désinstaller puis réinstaller).

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
