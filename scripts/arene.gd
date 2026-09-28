class_name Arene
extends RefCounted
## ARÈNE JcJ : outils partagés (équipe de défense, puissance, paliers, boutique).
## Les points, essais, Insignes et achats sont gérés par le serveur (supabase/02_arene.sql).

const PALIERS := {
	"bronze":  {"nom": "Bronze",  "couleur": Color("b07a4a"), "min": 0},
	"argent":  {"nom": "Argent",  "couleur": Color("c8d0d8"), "min": 1100},
	"or":      {"nom": "Or",      "couleur": Color("ffd060"), "min": 1300},
	"platine": {"nom": "Platine", "couleur": Color("7ae0d0"), "min": 1500},
	"diamant": {"nom": "Diamant", "couleur": Color("7ab0ff"), "min": 1800},
	"legende": {"nom": "Légende", "couleur": Color("ff7a5a"), "min": 1800},
}
const ORDRE_PALIERS := ["bronze", "argent", "or", "platine", "diamant", "legende"]

## Textes des erreurs renvoyées par le serveur
const ERREURS := {
	"pas_de_defense": "Prépare d'abord ton équipe de défense (onglet Défense).",
	"soi_meme": "Tu ne peux pas t'attaquer toi-même.",
	"introuvable": "Ce joueur n'a plus d'équipe de défense.",
	"trop_contre_lui": "Tu as déjà attaqué ce joueur 3 fois aujourd'hui.",
	"plus_d_essais": "Plus aucun combat possible aujourd'hui. Reviens demain !",
	"plus_d_essais_gratuits": "Plus de combat gratuit aujourd'hui.",
	"pas_assez": "Pas assez d'Insignes d'Arène.",
	"limite": "Limite d'achats atteinte pour cette saison.",
	"vide": "L'équipe de défense est vide.",
	"invalide": "Équipe de défense refusée par le serveur.",
	"non_connecte": "Tu n'es pas connecté.",
	"deja_termine": "Ce combat a déjà été compté.",
}


static func nom_palier(id: String) -> String:
	return PALIERS.get(id, PALIERS["bronze"])["nom"]


static func couleur_palier(id: String) -> Color:
	return PALIERS.get(id, PALIERS["bronze"])["couleur"]


static func texte_erreur(code: String) -> String:
	return ERREURS.get(code, code)


# ------------------------------------------------------------------
# Équipe de défense (enregistrée dans la sauvegarde, envoyée au serveur)
# ------------------------------------------------------------------

## Les 5 places de la défense : uid du héros, ou -1.
static func slots_defense() -> Array:
	Sauvegarde.charger()
	var a: Dictionary = Sauvegarde.donnees.get("arene", {})
	var brut: Array = a.get("defense", [])
	var s: Array = []
	for i in 5:
		var uid := int(brut[i]) if i < brut.size() else -1
		s.append(uid if uid >= 0 and not Sauvegarde.get_heros(uid).is_empty() and not uid in s else -1)
	return s


static func definir_slots_defense(slots: Array) -> void:
	Sauvegarde.charger()
	if not Sauvegarde.donnees.has("arene"):
		Sauvegarde.donnees["arene"] = {}
	Sauvegarde.donnees["arene"]["defense"] = slots.duplicate()
	Sauvegarde.sauvegarder()


## Une unité du joueur, prête pour le combat / le serveur.
static func combattant(uid: int, place: int) -> Dictionary:
	var h := Sauvegarde.get_heros(uid)
	return {"id": h["id"], "niveau": int(h["niveau"]), "place": place,
		"etoiles": Fusion.etoiles(h), "echos": Sauvegarde.bonus_echos(uid)}


## Équipe (tableau de combattants) à partir de 5 places.
static func equipe_depuis_slots(slots: Array) -> Array:
	var e: Array = []
	for i in slots.size():
		if int(slots[i]) >= 0:
			e.append(combattant(int(slots[i]), i))
	return e


## Équipe d'attaque = l'équipe du Deck.
static func equipe_attaque() -> Array:
	var e := equipe_depuis_slots(Sauvegarde.get_slots())
	for i in e.size():
		e[i]["uid"] = Sauvegarde.get_slots()[int(e[i]["place"])]
	return e


## Retire les unités inconnues de cette version du jeu (défense venue d'une version plus récente).
static func nettoyer(equipe) -> Array:
	var res: Array = []
	if equipe is Array:
		for u in equipe:
			if u is Dictionary and UnitesData.existe(str(u.get("id", ""))):
				res.append(u)
	return res


## Puissance d'une équipe (sert à comparer les adversaires).
static func puissance(equipe: Array) -> int:
	var t := 0.0
	for u in nettoyer(equipe):
		var s := UnitesData.stats(u["id"], int(u.get("niveau", 1)))
		s = Fusion.appliquer_etoiles(s, int(u.get("etoiles", 0)))
		var ech = u.get("echos", {})
		if ech is Dictionary and not ech.is_empty():
			s = Echos.appliquer(s, ech)
		t += s["pv"] * 0.25 + s["atk"] + s["def"] * 0.8 + s["agi"] * 0.5 + s["mag"] * 0.7
	return int(t)


## Gardien de l'Arène (quand il n'y a pas assez de vrais joueurs) :
## le reflet de ta propre défense, 2 niveaux plus bas et sans Échos.
static func equipe_gardien() -> Array:
	var e: Array = []
	for u in equipe_depuis_slots(slots_defense()):
		e.append({"id": u["id"], "niveau": maxi(1, int(u["niveau"]) - 2), "place": u["place"],
			"etoiles": u["etoiles"], "echos": {}})
	return e


# ------------------------------------------------------------------
# Boutique (prix et limites viennent du serveur)
# ------------------------------------------------------------------

static func nom_objet(id: String) -> String:
	return str(Reliquaire.OBJETS.get(id, {}).get("nom", id))


static func couleur_objet(id: String) -> Color:
	return Color("#" + str(Reliquaire.OBJETS.get(id, {}).get("couleur", "cccccc")))
