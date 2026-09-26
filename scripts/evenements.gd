class_name Evenements
extends RefCounted
## ÉVÉNEMENTS D'INVOCATION : invocations spéciales à durée limitée.
## Elles s'affichent dans le bandeau en bas de l'Autel d'Invocation.
##
## POUR AJOUTER UN ÉVÉNEMENT : copie un bloc de EVENEMENTS et change :
##   id          : nom unique (sert aussi pour l'image du bandeau)
##   debut / fin : dates au format "AAAA-MM-JJ" (inclus, heure locale du joueur)
##   vedettes    : unités mises en avant (invocables ou non !)
##   chance_vedette : quand la rareté tirée est celle d'une vedette, chance d'obtenir la vedette
##   taux, prix_x1, prix_x10 : comme les autres pactes (payés en Éclats de Pacte Supérieur)
## Image du bandeau (facultative) : res://assets/invocation/evenements/<id>.png  (1600 x 220 conseillé)

const EVENEMENTS := [
	{
		"id": "lune_de_sang",
		"titre": "LUNE DE SANG",
		"sous_titre": "Sous l'astre écarlate, les seigneurs des ténèbres répondent à ton appel.",
		"debut": "2026-09-26", "fin": "2026-10-10",
		"couleur": "d02030",
		"vedettes": ["empereur_dechu", "dragon_ombre", "archange_noir"],
		"chance_vedette": 0.5,
		"taux": [["SR", 0.70], ["SSR", 0.25], ["UR", 0.045], ["LEG", 0.005]],
		"prix_x1": 1, "prix_x10": 10,
	},
	{
		"id": "aube_celeste",
		"titre": "AUBE CÉLESTE",
		"sous_titre": "Les créatures de lumière descendent des cieux pour quelques jours seulement.",
		"debut": "2026-10-11", "fin": "2026-10-25",
		"couleur": "e8c050",
		"vedettes": ["cheval_sacre", "phenix_immortel", "chien_sylvestre"],
		"chance_vedette": 0.5,
		"taux": [["SR", 0.70], ["SSR", 0.25], ["UR", 0.045], ["LEG", 0.005]],
		"prix_x1": 1, "prix_x10": 10,
	},
]


## Date du jour "AAAA-MM-JJ" (heure locale, suit Calendrier pour les tests).
static func aujourdhui() -> String:
	var d := Time.get_date_dict_from_unix_time(Calendrier.jour_absolu() * 86400)
	return "%04d-%02d-%02d" % [d.year, d.month, d.day]


## L'événement en cours ({} s'il n'y en a pas).
static func actif() -> Dictionary:
	var j := aujourdhui()
	for e in EVENEMENTS:
		if j >= str(e["debut"]) and j <= str(e["fin"]):
			return e
	return {}


## Le prochain événement à venir ({} s'il n'y en a pas).
static func prochain() -> Dictionary:
	var j := aujourdhui()
	var meilleur: Dictionary = {}
	for e in EVENEMENTS:
		if str(e["debut"]) > j and (meilleur.is_empty() or str(e["debut"]) < str(meilleur["debut"])):
			meilleur = e
	return meilleur


## Secondes restantes avant la fin de l'événement (le jour de fin est inclus, jusqu'à minuit).
## (dates lues comme heure locale, comparées à Calendrier.maintenant_local)
static func secondes_restantes(e: Dictionary) -> int:
	var fin := int(Time.get_unix_time_from_datetime_string(str(e["fin"]) + "T00:00:00")) + 86400
	return maxi(0, fin - Calendrier.maintenant_local())


static func secondes_avant_debut(e: Dictionary) -> int:
	var debut := int(Time.get_unix_time_from_datetime_string(str(e["debut"]) + "T00:00:00"))
	return maxi(0, debut - Calendrier.maintenant_local())


## Vedettes d'une rareté donnée ("LEG" = légende).
static func vedettes_de(e: Dictionary, rarete: String) -> Array:
	var l: Array = []
	for id in e.get("vedettes", []):
		var u := UnitesData.get_unite(id)
		if u.is_empty():
			continue
		var r: String = "LEG" if u.get("legende", false) else str(u["rarete"])
		if r == rarete:
			l.append(id)
	return l
