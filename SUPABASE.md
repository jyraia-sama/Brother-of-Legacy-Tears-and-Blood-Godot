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

### 2 bis. Tables de l'Arène
Même chose avec le fichier `supabase/02_arene.sql` : **New query** → colle tout → **Run** → « Success ».
(À faire une fois, après le fichier 01. Pour changer un réglage de l'Arène — essais par jour, durée des saisons, prix de la boutique — modifie le début du fichier et relance-le.)

### 2 ter. Classement de la Marche Maudite
Même chose avec le fichier `supabase/03_marche.sql` : **New query** → colle tout → **Run** → « Success ».
(À faire une fois, après les fichiers 01 et 02. Sans ce fichier, la Marche marche quand même, mais n'est pas classée.)

### 2 quater. Arène classée en temps réel
Même chose avec le fichier `supabase/04_arene_classee.sql` : **New query** → colle tout → **Run** → « Success ».
(À faire une fois, après les fichiers 01 et 02. Sans ce fichier, l'écran « Arène classée » affiche une erreur.
Réglages — points de départ, force de l'Elo, durée des saisons, délais d'absence — au début du fichier.)

### 2 quinquies. Vie de guilde (v0.47)
Même chose avec le fichier `supabase/05_guildes_vie.sql` : **New query** → colle tout → **Run** → « Success ».
(À faire une fois, après le fichier 01. Ajoute : niveau et trésor de guilde, dons quotidiens, Sceaux de guilde,
mot du chef, journal, bénédictions, boutique, Boss de guilde et discussion. Sans ce fichier, la guilde n'affiche
que Membres / Candidatures / Réglages. Réglages — dons, bénédictions, PV du boss, boutique — au début du fichier.)

### 2 sexies. Profil public détaillé (v0.51)
Même chose avec le fichier `supabase/06_profil_public.sql` : **New query** → colle tout → **Run** → « Success ».
(À faire une fois, après les fichiers 01 à 05. Ajoute la « vitrine » de chaque joueur — titre, héros principal,
équipe, statistiques, collection — et ses résultats d'Arène, d'Arène classée et de Marche Maudite dans la fiche
qu'on ouvre depuis Social ou Guilde. Sans ce fichier, la fiche reste la version courte.)

## 3. Comptes par e-mail
Les joueurs créent leur compte avec **un pseudo, leur adresse e-mail et un mot de passe**, et se connectent avec **e-mail + mot de passe**.

**a) Adresse du jeu** (pour que les liens des e-mails ramènent sur le jeu)
1. **Authentication** → **URL Configuration**.
2. **Site URL** : `https://jyraia-sama.github.io/Brother-of-Legacy-Tears-and-Blood-Godot/` → **Save**.
3. **Redirect URLs** → **Add URL** : la même adresse → **Save**.

**b) Confirmation de l'e-mail : à toi de choisir**
Dans **Authentication** → **Sign In / Providers** → **Email** :
- **« Confirm email » décoché (conseillé pour l'instant)** : le compte marche tout de suite.
- **« Confirm email » coché** : le joueur reçoit un e-mail et doit cliquer sur le lien avant de se connecter.
  ⚠ Le service d'e-mails gratuit de Supabase n'envoie qu'aux **membres de ton équipe Supabase** (donc toi) et seulement **2 e-mails par heure**.
  Pour les autres joueurs, il faudra brancher un service d'e-mails (ex. Resend, gratuit) dans **Project Settings** → **Authentication** → **SMTP Settings**.
  Ça vaut aussi pour « Mot de passe oublié ».

Vérifie enfin que **« Allow new users to sign up »** est activé.

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
   puis crée-en un autre avec une autre adresse e-mail (ou utilise la version web sur un autre navigateur).

## En cas de problème
| Message | Solution |
|---|---|
| « Compte créé, mais Supabase attend une confirmation par e-mail » | Étape 3 : décoche « Confirm email ». Puis dans Authentication → Users, supprime le compte bloqué. |
| « Adresse e-mail pas encore confirmée » | Clique sur le lien de l'e-mail reçu (regarde les spams), ou décoche « Confirm email » (étape 3b). |
| L'e-mail n'arrive jamais | Service gratuit : seulement pour les membres de ton équipe, 2 par heure. Décoche « Confirm email » ou branche un SMTP (étape 3b). Dans Authentication → Users, tu peux aussi confirmer un compte à la main. |
| « Erreur du serveur (404) … rpc/… » | Le script SQL n'a pas été lancé (étape 2), ou pas en entier. |
| « Erreur du serveur (401) » | URL ou clé mal copiée (espace en trop, mauvaise clé). |
| Le pseudo reste « Se connecter » en jaune | Le serveur ne répond pas : vérifie ta connexion. La partie sera envoyée dès le retour du réseau. |

## Bon à savoir
- **Projet gratuit en pause** : sur la formule gratuite, Supabase met le projet en pause après ~1 semaine sans aucune connexion. Il suffit de cliquer « Restore » dans le tableau de bord.
- **Mot de passe oublié** : bouton dans la fenêtre de connexion. Le lien reçu par e-mail ouvre le jeu web, qui demande le nouveau mot de passe (nécessite que les e-mails partent : voir étape 3b).
- **Triche** : la partie est encore calculée sur l'appareil du joueur. Le menu Admin n'existe que quand le jeu est lancé depuis Godot, mais un joueur très motivé pourrait modifier sa sauvegarde. Pour l'Arène classée, les résultats importants devront être vérifiés par le serveur (prévu à l'étape Arène).
