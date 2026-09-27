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


## Adresse du jeu web : les liens des e-mails (confirmation du compte, mot de passe oublié)
## ramènent ici. Dans Supabase, mets la même adresse dans
## Authentication > URL Configuration > Site URL (et Redirect URLs).
const ADRESSE_JEU_WEB := "https://jyraia-sama.github.io/Brother-of-Legacy-Tears-and-Blood-Godot/"
