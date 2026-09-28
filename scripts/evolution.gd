class_name Evolution
extends RefCounted
## AUTEL D'ÉVOLUTION : règles (sans interface).
##
## Une unité invocable niveau 30 peut devenir sa version ÉVOLUÉE (evolutions_data.gd) :
##  - on paie des ressources de SON élément (Donjon de l'élément) + des ressources de Sang
##    (Donjon neutre : le Puits de Sang) ; plus l'unité est rare, plus les ressources sont grosses ;
##  - l'unité garde ses étoiles, ses Échos Sanguins, son verrou et sa place dans l'équipe ;
##  - elle repart au NIVEAU 1, avec un niveau maximum de 40.
## Les évolutions ne sont jamais invocables.

const NIVEAU_REQUIS := 30

## Ressources des Donjons : 3 tailles par élément (Goutte < Larme < Cœur).
const TAILLES := ["goutte", "larme", "coeur"]
const NOMS_TAILLE := {"goutte": "Goutte", "larme": "Larme", "coeur": "Cœur"}
## Élément -> nom de la ressource ("de Braise", "d'Abysse"...)
const ESSENCES := {
	"feu": {"id": "braise", "nom": "de Braise", "couleur": "ff6a2a"},
	"nature": {"id": "seve", "nom": "de Sève", "couleur": "6ad04a"},
	"eau": {"id": "abysse", "nom": "d'Abysse", "couleur": "4aa8ff"},
	"tenebres": {"id": "ombre", "nom": "d'Ombre", "couleur": "a06ae0"},
	"sacre": {"id": "aube", "nom": "d'Aube", "couleur": "ffe070"},
	"neutre": {"id": "sang", "nom": "de Sang", "couleur": "d02a2a"},
}

## Coût d'une évolution selon la rareté : [goutte, larme, cœur] de l'élément, puis de Sang.
const COUTS := {
	"N": {"element": [20, 0, 0], "sang": [10, 0, 0]},
	"R": {"element": [40, 10, 0], "sang": [20, 5, 0]},
	"SR": {"element": [0, 30, 5], "sang": [0, 15, 2]},
	"SSR": {"element": [0, 60, 15], "sang": [0, 30, 6]},
	"UR": {"element": [0, 0, 40], "sang": [0, 0, 20]},
	"LEG": {"element": [0, 0, 80], "sang": [0, 0, 40]},
}


## Identifiant d'une ressource : ex. ressource("eau", "larme") -> "larme_abysse".
static func ressource(element: String, taille: String) -> String:
	return "%s_%s" % [taille, ESSENCES[element]["id"]]


## Toutes les ressources des Donjons (pour le Reliquaire et le menu Admin).
static func toutes_ressources() -> Array:
	var l: Array = []
	for el in ESSENCES:
		for t in TAILLES:
			l.append(ressource(el, t))
	return l


static func nom_ressource(element: String, taille: String) -> String:
	return "%s %s" % [NOMS_TAILLE[taille], ESSENCES[element]["nom"]]


## Coût complet pour faire évoluer cette unité : {id_ressource: quantité}.
static func cout(id_unite: String) -> Dictionary:
	var u := UnitesData.get_unite(id_unite)
	var c: Dictionary = COUTS[Fusion.cle_rarete(id_unite)]
	var total := {}
	for i in TAILLES.size():
		if int(c["element"][i]) > 0:
			total[ressource(u["element"], TAILLES[i])] = int(c["element"][i])
		if int(c["sang"][i]) > 0:
			var r := ressource("neutre", TAILLES[i])
			total[r] = int(total.get(r, 0)) + int(c["sang"][i])
	return total


static func peut_evoluer(id_unite: String) -> bool:
	return UnitesData.id_evolution(id_unite) != ""


## Ce qui empêche l'évolution ("" = possible).
static func raison_impossible(uid: int) -> String:
	var h := Sauvegarde.get_heros(uid)
	if h.is_empty():
		return "Choisis une unité."
	if UnitesData.est_evolue(h["id"]):
		return "Cette unité a déjà évolué."
	if not peut_evoluer(h["id"]):
		return "Cette unité n'a pas d'évolution."
	if Sauvegarde.est_occupe(uid):
		return "Cette unité est partie en mission (Compagnie)."
	if int(h["niveau"]) < NIVEAU_REQUIS:
		return "Niveau %d requis (actuellement Nv %d)." % [NIVEAU_REQUIS, int(h["niveau"])]
	var c := cout(h["id"])
	for r in c:
		if Sauvegarde.get_objet(r) < int(c[r]):
			return "Pas assez de %s (%d / %d)." % [Reliquaire.nom(r), Sauvegarde.get_objet(r), int(c[r])]
	return ""


## Fait évoluer l'unité. Renvoie l'identifiant de l'évolution ("" si impossible).
static func evoluer(uid: int) -> String:
	if raison_impossible(uid) != "":
		return ""
	var h := Sauvegarde.get_heros(uid)
	var c := cout(h["id"])
	for r in c:
		Sauvegarde.retirer_objet(r, int(c[r]))
	var evo := UnitesData.id_evolution(h["id"])
	h["id"] = evo
	h["niveau"] = 1
	h["xp"] = 0
	Sauvegarde.decouvrir(evo)
	Sauvegarde.ajouter_stat("evolutions")
	Sauvegarde.sauvegarder()
	return evo
