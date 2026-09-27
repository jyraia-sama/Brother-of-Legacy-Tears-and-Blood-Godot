class_name ConfigEnLigne
extends RefCounted
## RÉGLAGES DU JEU EN LIGNE (Supabase).
##
## Où trouver ces deux valeurs : Supabase > ton projet > Project Settings > API Keys
##   (ou le bouton « Connect » en haut de la page du projet).
##   URL  : « Project URL », ex. https://abcdefghijklmnop.supabase.co
##   CLE  : la clé PUBLIQUE, « Publishable key » (sb_publishable_...) ou « anon public ».
##
## ⚠ Ne mets JAMAIS ici la clé « secret » / « service_role » : elle donnerait tous les droits
##   à n'importe qui. La clé publique, elle, peut être visible sans danger (c'est prévu pour).
##
## Laisse URL vide pour jouer sans le mode en ligne (le jeu marche comme avant).

const URL := "https://ukfzjhcuiuppatwskiyt.supabase.co"
const CLE := "sb_publishable_WWaLehXAvm04gmggZqdZLA_moALZuNd"

## Les comptes se font avec un pseudo + mot de passe. Supabase exige une adresse e-mail :
## le jeu en fabrique une à partir du pseudo (ex. neo@joueurs.brothers-of-legacy.fr).
## Aucun e-mail n'est jamais envoyé à cette adresse (« Confirm email » doit être désactivé).
## Ne change plus ce nom une fois que des joueurs ont créé un compte !
const DOMAINE_COMPTES := "joueurs.brothers-of-legacy.fr"
