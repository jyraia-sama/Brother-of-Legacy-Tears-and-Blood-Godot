class_name Calendrier
extends RefCounted
## Dates du jeu (heure locale du joueur) : jour de la semaine, semaine, comptes à rebours.
## La semaine commence le LUNDI à 00:00 (heure locale) : c'est le moment où les Tours
## se réinitialisent. Chaque jour à 00:00 change le Boss de Monde disponible.

const JOURS := ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"]

## Pour les tests : décale l'horloge du jeu (en secondes).
static var decalage_test := 0


## Secondes « locales » depuis le 1er janvier 1970.
static func maintenant_local() -> int:
	var bias := int(Time.get_time_zone_from_system().get("bias", 0))    # minutes
	return int(Time.get_unix_time_from_system()) + bias * 60 + decalage_test


## Numéro du jour (compte depuis 1970, heure locale).
static func jour_absolu() -> int:
	return int(floor(maintenant_local() / 86400.0))


## 0 = lundi ... 6 = dimanche   (le 1er janvier 1970 était un jeudi)
static func jour_semaine() -> int:
	return (jour_absolu() + 3) % 7


## Numéro de la semaine (change chaque lundi à 00:00).
static func semaine() -> int:
	return int(floor((jour_absolu() + 3) / 7.0))


static func secondes_avant_semaine() -> int:
	var debut_prochaine := ((semaine() + 1) * 7 - 3) * 86400
	return maxi(0, debut_prochaine - maintenant_local())


static func secondes_avant_demain() -> int:
	return maxi(0, (jour_absolu() + 1) * 86400 - maintenant_local())


## 273600 -> "3 j 04 h 00 min"
static func texte_duree(s: int) -> String:
	var j := int(s / 86400.0)
	var h := int((s % 86400) / 3600.0)
	var m := int((s % 3600) / 60.0)
	if j > 0:
		return "%d j %02d h %02d min" % [j, h, m]
	if h > 0:
		return "%d h %02d min %02d s" % [h, m, s % 60]
	return "%d min %02d s" % [m, s % 60]
