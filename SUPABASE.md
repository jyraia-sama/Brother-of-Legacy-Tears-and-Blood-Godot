# Jeu en ligne : installation de Supabase (une seule fois, ~10 minutes)

Supabase est le serveur du jeu : il garde les comptes, les sauvegardes en ligne, les amis et les guildes.
Le jeu, lui, reste sur GitHub Pages. La formule gratuite suffit largement pour commencer.

## 1. Créer le projet Supabase
1. Va sur **supabase.com** → **Start your project** → connecte-toi avec ton compte GitHub.
2. **New project** :
   - Name : `brothers-of-legacy`
   - Database Password : clique sur **Generate** et **garde ce mot de passe** dans un fichier (tu n'en auras presque jamais besoin, mais il ne se récupère pas).
   - Region : **Europe (Paris)** si elle est proposée, sinon la plus proche.
3. Attends 1 à 2 minutes que le projet soit prêt.

## 2. Créer les tables du jeu
1. Menu de gauche : **SQL Editor** → **New query**.
2. Ouvre le fichier `supabase/01_comptes_amis_guildes.sql` de ton projet Godot (avec le Bloc-notes), copie **tout**, colle-le dans Supabase.
3. Clique sur **Run**. Tu dois voir « Success. No rows returned ».
   (Tu peux le relancer sans danger : il ne supprime aucune donnée.)

## 3. Autoriser les comptes « pseudo + mot de passe »
Le jeu fabrique une adresse e-mail à partir du pseudo (personne ne la voit, aucun e-mail n'est envoyé).
Il faut donc dire à Supabase de ne pas demander de confirmation par e-mail :
1. Menu de gauche : **Authentication** → **Sign In / Providers** → **Email**.
2. **Décoche « Confirm email »** → **Save**.
3. Vérifie que **« Allow new users to sign up »** est bien activé.

## 4. Relier le jeu au serveur
1. En haut de la page du projet, clique sur **Connect** (ou **Project Settings** → **API Keys**).
2. Copie :
   - **Project URL** (ex. `https://abcdefghijklmnop.supabase.co`)
   - la clé **Publishable** (`sb_publishable_...`) — si tu ne vois que l'ancien système, prends la clé **anon public**.
3. Dans Godot, ouvre `scripts/config_en_ligne.gd` et colle-les :
   ```gdscript
   const URL := "https://abcdefghijklmnop.supabase.co"
   const CLE := "sb_publishable_xxxxxxxxxxxxxxxx"
   ```
⚠ **Ne colle jamais la clé « secret » ou « service_role »** : elle donne tous les droits sur la base.
La clé publishable, elle, est faite pour être dans le jeu (la sécurité est assurée par les règles du fichier SQL).

## 5. Tester
1. Lance le jeu (F5) : la fenêtre **COMPTE** s'ouvre. Crée un compte (onglet « Créer un compte »).
2. Sur le menu principal, ton pseudo s'affiche en vert en haut à gauche.
3. Dans Supabase → **Table Editor** → `profils` : ton pseudo apparaît. Dans `sauvegardes` : ta partie.
4. Pour tester les amis, crée un 2e compte : dans le jeu, Paramètres → Gérer le compte → Se déconnecter,
   puis crée-en un autre (ou utilise la version web sur un autre navigateur).

## En cas de problème
| Message | Solution |
|---|---|
| « Compte créé, mais Supabase attend une confirmation par e-mail » | Étape 3 : décoche « Confirm email ». Puis dans Authentication → Users, supprime le compte bloqué. |
| « Le serveur refuse les adresses du jeu » | Dans `config_en_ligne.gd`, remplace `DOMAINE_COMPTES` par un autre nom (ex. `joueurs-bol.fr`), **avant** que des joueurs aient créé des comptes. |
| « Erreur du serveur (404) … rpc/… » | Le script SQL n'a pas été lancé (étape 2), ou pas en entier. |
| « Erreur du serveur (401) » | URL ou clé mal copiée (espace en trop, mauvaise clé). |
| Le pseudo reste « Se connecter » en jaune | Le serveur ne répond pas : vérifie ta connexion. La partie sera envoyée dès le retour du réseau. |

## Bon à savoir
- **Projet gratuit en pause** : sur la formule gratuite, Supabase met le projet en pause après ~1 semaine sans aucune connexion. Il suffit de cliquer « Restore » dans le tableau de bord.
- **Mot de passe oublié** : pas encore possible (il faudra l'e-mail, prévu plus tard). En attendant, tu peux supprimer le compte dans Authentication → Users, et le joueur en recrée un.
- **Triche** : la partie est encore calculée sur l'appareil du joueur. Le menu Admin n'existe que quand le jeu est lancé depuis Godot, mais un joueur très motivé pourrait modifier sa sauvegarde. Pour l'Arène classée, les résultats importants devront être vérifiés par le serveur (prévu à l'étape Arène).
