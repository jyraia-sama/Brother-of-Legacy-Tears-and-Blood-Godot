class_name Succes
extends RefCounted
## SUCCÈS : objectifs à long terme, à plusieurs paliers.
## Chaque palier atteint se réclame (gemmes, parfois des objets) ; le dernier palier
## débloque un TITRE, que l'on peut afficher dans « Mon héros ».
## La progression est lue directement dans la sauvegarde (statistiques, collection, records).

const SCENE := "res://scenes/succes.tscn"

## paliers : [seuil, récompense] ; titre : débloqué au dernier palier.
const LISTE := [
	{"id": "combats", "nom": "Vétéran des Batailles", "desc": "Gagne des combats (tous modes).", "titre": "Vétéran",
		"paliers": [[50, {"gemmes": 20}], [250, {"gemmes": 50}], [1000, {"gemmes": 100}], [5000, {"gemmes": 250, "pierre_eveil": 1}]]},
	{"id": "chapitres", "nom": "Le Chemin de la Légende", "desc": "Termine des chapitres de l'histoire.", "titre": "Héritier de la Légende",
		"paliers": [[6, {"gemmes": 30}], [24, {"gemmes": 60}], [48, {"gemmes": 120}], [72, {"gemmes": 300, "eclat_superieur": 5}]]},
	{"id": "bestiaire", "nom": "Érudit du Bestiaire", "desc": "Découvre des unités dans le Bestiaire.", "titre": "Érudit",
		"paliers": [[25, {"gemmes": 20}], [75, {"gemmes": 50}], [150, {"gemmes": 100}], [230, {"gemmes": 250}]]},
	{"id": "invocations", "nom": "Grand Invocateur", "desc": "Invoque des unités à l'Autel d'Invocation.", "titre": "Invocateur",
		"paliers": [[10, {"gemmes": 20}], [100, {"gemmes": 60}], [500, {"gemmes": 150}], [1500, {"gemmes": 300, "eclat_superieur": 5}]]},
	{"id": "rares", "nom": "Collectionneur", "desc": "Possède des unités SSR ou plus rares (différentes).", "titre": "Collectionneur",
		"paliers": [[1, {"gemmes": 30}], [5, {"gemmes": 60}], [15, {"gemmes": 150}], [30, {"gemmes": 300}]]},
	{"id": "enfer", "nom": "Descente aux Enfers", "desc": "Record d'étage dans la Tour de l'Enfer.", "titre": "Seigneur de l'Abîme",
		"paliers": [[10, {"gemmes": 30}], [30, {"gemmes": 60}], [60, {"gemmes": 120}], [100, {"gemmes": 300, "braise_infernale": 100}]]},
	{"id": "paradis", "nom": "Ascension Céleste", "desc": "Record d'étage dans la Tour du Paradis.", "titre": "Élu des Cieux",
		"paliers": [[10, {"gemmes": 30}], [30, {"gemmes": 60}], [60, {"gemmes": 120}], [100, {"gemmes": 300, "plume_celeste": 100}]]},
	{"id": "compte", "nom": "Commandant", "desc": "Monte ton niveau de compte.", "titre": "Commandant",
		"paliers": [[5, {"gemmes": 20}], [10, {"gemmes": 40}], [20, {"gemmes": 80}], [30, {"gemmes": 200}]]},
	{"id": "evolutions", "nom": "Au-delà des Limites", "desc": "Fais évoluer des unités.", "titre": "Éveilleur",
		"paliers": [[1, {"gemmes": 30}], [5, {"gemmes": 60}], [15, {"gemmes": 150}], [40, {"gemmes": 300}]]},
	{"id": "donjons", "nom": "Pilleur de Donjons", "desc": "Termine des expéditions de Donjon.", "titre": "Pilleur de Donjons",
		"paliers": [[5, {"gemmes": 20}], [25, {"gemmes": 50}], [100, {"gemmes": 120}], [300, {"gemmes": 250, "coeur_sang": 5}]]},
	{"id": "titans", "nom": "Tueur de Titans", "desc": "Abats des Boss de Monde.", "titre": "Tueur de Titans",
		"paliers": [[1, {"gemmes": 40}], [7, {"gemmes": 80}], [25, {"gemmes": 150}], [70, {"gemmes": 300, "fragment_colossal": 60}]]},
	{"id": "marches", "nom": "Marcheur Maudit", "desc": "Termine des Marches Maudites (les 3 régions).", "titre": "Marcheur Maudit",
		"paliers": [[1, {"gemmes": 30}], [5, {"gemmes": 60}], [20, {"gemmes": 120}], [50, {"gemmes": 300, "sceau_marche": 200}]]},
	{"id": "compagnie", "nom": "Capitaine de la Compagnie", "desc": "Envoie des missions de la Compagnie.", "titre": "Capitaine",
		"paliers": [[5, {"gemmes": 20}], [25, {"gemmes": 50}], [100, {"gemmes": 120}], [300, {"gemmes": 250}]]},
	{"id": "echos_max", "nom": "Forgeron de Sang", "desc": "Amène des Échos Sanguins au niveau +15.", "titre": "Forgeron de Sang",
		"paliers": [[1, {"gemmes": 40}], [6, {"gemmes": 80}], [12, {"gemmes": 150}], [30, {"gemmes": 300}]]},
	{"id": "fortune", "nom": "Magnat", "desc": "Gagne de l'or (total depuis le début).", "titre": "Magnat",
		"paliers": [[50000, {"gemmes": 20}], [500000, {"gemmes": 60}], [5000000, {"gemmes": 150}], [50000000, {"gemmes": 300}]]},
]


static func _etat() -> Dictionary:
	Sauvegarde.charger()
	if not Sauvegarde.donnees.has("succes") or not Sauvegarde.donnees["succes"] is Dictionary:
		Sauvegarde.donnees["succes"] = {}
	var s: Dictionary = Sauvegarde.donnees["succes"]
	if not s.has("reclames"):
		s["reclames"] = {}
	if not s.has("titre"):
		s["titre"] = ""
	return s


## Valeur actuelle de la progression d'un succès.
static func valeur(id: String) -> int:
	match id:
		"combats": return Sauvegarde.get_stat("combats_gagnes")
		"chapitres": return Sauvegarde.nombre_chapitres_termines()
		"bestiaire": return Sauvegarde.donnees["bestiaire"].size()
		"invocations":
			var inv: Dictionary = Sauvegarde.donnees["invocation"]
			return int(inv.get("total_dore", 0)) + int(inv.get("total_superieur", 0)) + int(inv.get("total_evenement", 0))
		"rares":
			var ids := {}
			for h in Sauvegarde.liste_heros():
				var u := UnitesData.get_unite(h["id"])
				if u.get("legende", false) or u["rarete"] in ["SSR", "UR"]:
					ids[UnitesData.lignee(h["id"])] = true
			return ids.size()
		"enfer": return Tours.record("enfer")
		"paradis": return Tours.record("paradis")
		"compte": return Sauvegarde.get_niveau_compte()
		"evolutions": return Sauvegarde.get_stat("evolutions")
		"donjons": return Sauvegarde.get_stat("donjons_termines")
		"titans": return Sauvegarde.get_stat("boss_monde_abattus")
		"marches": return Sauvegarde.get_stat("marches_terminees")
		"compagnie": return Sauvegarde.get_stat("missions_compagnie")
		"echos_max":
			var n := 0
			for e in Sauvegarde.liste_echos():
				if int(e["niveau"]) >= Echos.NIVEAU_MAX:
					n += 1
			return maxi(n, Sauvegarde.get_stat("echos_max"))
		"fortune": return Sauvegarde.get_stat("or_total_gagne")
	return 0


static func get_def(id: String) -> Dictionary:
	for s in LISTE:
		if s["id"] == id:
			return s
	return {}


## Nombre de paliers déjà réclamés.
static func reclames(id: String) -> int:
	return int(_etat()["reclames"].get(id, 0))


## Nombre de paliers atteints.
static func atteints(id: String) -> int:
	var v := valeur(id)
	var n := 0
	for p in get_def(id)["paliers"]:
		if v >= int(p[0]):
			n += 1
	return n


static func peut_reclamer(id: String) -> bool:
	return atteints(id) > reclames(id)


## Réclame le prochain palier atteint. Renvoie les lignes de récompense.
static func reclamer(id: String) -> Array:
	if not peut_reclamer(id):
		return []
	var s := _etat()
	var d := get_def(id)
	var i := reclames(id)
	s["reclames"][id] = i + 1
	var lignes := Quetes.donner(d["paliers"][i][1])
	if i + 1 >= d["paliers"].size():
		lignes.append("Titre débloqué : « %s »" % d["titre"])
	Sauvegarde.sauvegarder()
	return lignes


## Titres débloqués (dernier palier réclamé).
static func titres() -> Array:
	var t: Array = []
	for d in LISTE:
		if reclames(d["id"]) >= d["paliers"].size():
			t.append(d["titre"])
	return t


static func titre_actuel() -> String:
	var t := str(_etat()["titre"])
	return t if t in titres() else ""


static func choisir_titre(t: String) -> void:
	_etat()["titre"] = t if (t == "" or t in titres()) else ""
	Sauvegarde.sauvegarder()


static func a_reclamer() -> int:
	var n := 0
	for d in LISTE:
		if peut_reclamer(d["id"]):
			n += 1
	return n
