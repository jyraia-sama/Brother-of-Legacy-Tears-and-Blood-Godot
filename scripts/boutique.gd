class_name Boutique
extends RefCounted
## BOUTIQUE : trois rayons.
##  - MARCHÉ DU JOUR (or) : 6 offres qui changent chaque jour (les mêmes pour tous), 1 achat chacune.
##  - COMPTOIR DES GEMMES : offres permanentes payées en gemmes, avec une limite par jour ou par semaine.
##  - GEMMES : packs de gemmes en argent réel — PAS ENCORE ACTIF (affiché « bientôt »).
##    Pour l'activer plus tard, il faudra un système de paiement (ex. Stripe) relié au serveur :
##    c'est le serveur, jamais le jeu, qui doit créditer les gemmes après un paiement confirmé.

const SCENE := "res://scenes/boutique.tscn"

## Offres possibles du Marché du jour (prix en or). Chaque jour, 6 sont tirées au hasard.
const MARCHE := [
	{"id": "poussiere_echo", "quantite": 25, "prix": 3000},
	{"id": "sceau_sauvage", "quantite": 3, "prix": 4000},
	{"id": "elixir_petit", "quantite": 2, "prix": 2500},
	{"id": "tome_petit", "quantite": 3, "prix": 3500},
	{"id": "tome_grand", "quantite": 1, "prix": 6000},
	{"id": "coffre_argent", "quantite": 1, "prix": 3500},
	{"id": "goutte_braise", "quantite": 5, "prix": 4000},
	{"id": "goutte_seve", "quantite": 5, "prix": 4000},
	{"id": "goutte_abysse", "quantite": 5, "prix": 4000},
	{"id": "goutte_ombre", "quantite": 5, "prix": 4000},
	{"id": "goutte_aube", "quantite": 5, "prix": 4000},
	{"id": "goutte_sang", "quantite": 5, "prix": 4500},
	{"id": "larme_sang", "quantite": 2, "prix": 12000},
	{"id": "braise_infernale", "quantite": 5, "prix": 5000},
	{"id": "plume_celeste", "quantite": 5, "prix": 5000},
	{"id": "fragment_colossal", "quantite": 3, "prix": 6000},
	{"id": "eclat_superieur", "quantite": 1, "prix": 30000},
]
const OFFRES_MARCHE := 6

## Comptoir des gemmes. limite : nombre d'achats par "jour" ou par "semaine".
const COMPTOIR := [
	{"id": "stamina_pleine", "nom": "Recharge complète de stamina", "prix": 60, "limite": 3, "periode": "jour",
		"desc": "Remplit toute ta stamina."},
	{"id": "elixir_grand", "quantite": 1, "prix": 40, "limite": 5, "periode": "jour"},
	{"id": "eclat_superieur", "quantite": 1, "prix": 120, "limite": 10, "periode": "semaine"},
	{"id": "eclat_superieur", "quantite": 10, "prix": 1000, "limite": 1, "periode": "semaine", "cle": "eclats_x10",
		"desc": "Lot de 10 Éclats de Pacte Supérieur, moins cher qu'à l'unité."},
	{"id": "coffre_or", "quantite": 1, "prix": 100, "limite": 3, "periode": "semaine"},
	{"id": "tome_ancien", "quantite": 1, "prix": 180, "limite": 2, "periode": "semaine"},
	{"id": "coeur_sang", "quantite": 1, "prix": 150, "limite": 3, "periode": "semaine"},
	{"id": "pierre_eveil", "quantite": 1, "prix": 500, "limite": 1, "periode": "semaine"},
]

## Packs de gemmes en argent réel (affichés, pas encore achetables).
const PACKS := [
	{"gemmes": 100, "bonus": 0, "prix": "0,99 €"},
	{"gemmes": 550, "bonus": 50, "prix": "4,99 €"},
	{"gemmes": 1200, "bonus": 150, "prix": "9,99 €"},
	{"gemmes": 2600, "bonus": 400, "prix": "19,99 €"},
	{"gemmes": 7000, "bonus": 1500, "prix": "49,99 €"},
]
const PACKS_ACTIFS := false


static func _etat() -> Dictionary:
	Sauvegarde.charger()
	if not Sauvegarde.donnees.has("boutique") or not Sauvegarde.donnees["boutique"] is Dictionary:
		Sauvegarde.donnees["boutique"] = {}
	var b: Dictionary = Sauvegarde.donnees["boutique"]
	if int(b.get("jour", -1)) != Calendrier.jour_absolu():
		b["jour"] = Calendrier.jour_absolu()
		b["achats_jour"] = {}
	if int(b.get("semaine", -1)) != Calendrier.semaine():
		b["semaine"] = Calendrier.semaine()
		b["achats_semaine"] = {}
	return b


# ---------------------------------------------------------------------
# Marché du jour
# ---------------------------------------------------------------------

static func marche_du_jour() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("BoL-boutique-%d" % Calendrier.jour_absolu())
	var idx := range(MARCHE.size())
	var l: Array = []
	while l.size() < OFFRES_MARCHE and not idx.is_empty():
		var i: int = idx.pop_at(rng.randi_range(0, idx.size() - 1))
		var o: Dictionary = MARCHE[i].duplicate()
		o["cle"] = "marche_%d" % i
		l.append(o)
	l.sort_custom(func(a, b): return int(a["prix"]) < int(b["prix"]))
	return l


static func deja_achete_marche(o: Dictionary) -> bool:
	return int(_etat()["achats_jour"].get(o["cle"], 0)) > 0


static func acheter_marche(o: Dictionary) -> String:
	if deja_achete_marche(o):
		return "Déjà acheté aujourd'hui."
	if not Sauvegarde.depenser_or(int(o["prix"])):
		return "Pas assez d'or."
	_etat()["achats_jour"][o["cle"]] = 1
	Sauvegarde.ajouter_objet(o["id"], int(o["quantite"]))
	Sauvegarde.ajouter_stat("achats_boutique")
	return ""


# ---------------------------------------------------------------------
# Comptoir des gemmes
# ---------------------------------------------------------------------

static func cle(o: Dictionary) -> String:
	return str(o.get("cle", o["id"]))


static func restants(o: Dictionary) -> int:
	var b := _etat()
	var achats: Dictionary = b["achats_" + str(o["periode"])]
	return int(o["limite"]) - int(achats.get(cle(o), 0))


static func nom_offre(o: Dictionary) -> String:
	if o.has("nom"):
		return o["nom"]
	return "%s x%d" % [Reliquaire.nom(o["id"]), int(o["quantite"])]


static func acheter_comptoir(o: Dictionary) -> String:
	if restants(o) <= 0:
		return "Limite atteinte (%s)." % ("aujourd'hui" if o["periode"] == "jour" else "cette semaine")
	if o["id"] == "stamina_pleine" and Sauvegarde.get_stamina() >= Sauvegarde.get_stamina_max():
		return "Ta stamina est déjà pleine."
	if not Sauvegarde.depenser_gemmes(int(o["prix"])):
		return "Pas assez de gemmes."
	var achats: Dictionary = _etat()["achats_" + str(o["periode"])]
	achats[cle(o)] = int(achats.get(cle(o), 0)) + 1
	if o["id"] == "stamina_pleine":
		Sauvegarde.ajouter_stamina(Sauvegarde.get_stamina_max() - Sauvegarde.get_stamina())
	else:
		Sauvegarde.ajouter_objet(o["id"], int(o["quantite"]))
	Sauvegarde.ajouter_stat("achats_boutique")
	Sauvegarde.ajouter_stat("gemmes_depensees", int(o["prix"]))
	return ""
