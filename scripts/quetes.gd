class_name Quetes
extends RefCounted
## QUÊTES : missions du jour, de la semaine, et récompense de connexion.
##
##  - Chaque jour à minuit : 5 quêtes du jour (tirées au hasard, les mêmes pour tous) ;
##    les terminer toutes ouvre un coffre bonus.
##  - Chaque lundi : 5 quêtes de la semaine, plus un gros coffre bonus.
##  - Connexion : une récompense par jour (cycle de 7 jours ; un jour manqué ne fait
##    pas perdre la progression du cycle).
##  - La progression est notée automatiquement : toute statistique ajoutée avec
##    Sauvegarde.ajouter_stat() / _stat() fait avancer les quêtes qui la suivent.
##  - Les récompenses se réclament à la main (écran Quêtes).

const SCENE := "res://scenes/quetes.tscn"

## Plusieurs statistiques comptent pour une même quête
const ALIAS := {
	"etages_enfer": "etages", "etages_paradis": "etages",
	"eveils": "fusions", "absorptions": "fusions",
}

## Quêtes possibles. objectif : [jour, semaine] ; récompenses : [jour, semaine].
const POOL := {
	"combats_gagnes": {"texte": "Gagne %d combats", "objectif": [8, 60],
		"recompense": [{"or": 1500, "gemmes": 10}, {"or": 12000, "gemmes": 60}]},
	"stamina_depensee": {"texte": "Dépense %d points de stamina", "objectif": [40, 300],
		"recompense": [{"or": 1000, "gemmes": 15}, {"gemmes": 70, "elixir_grand": 1}]},
	"invocations": {"texte": "Fais %d invocations", "objectif": [3, 25],
		"recompense": [{"or": 1200, "gemmes": 10}, {"eclat_superieur": 2, "gemmes": 40}]},
	"ameliorations_echo": {"texte": "Tente %d améliorations d'Échos", "objectif": [4, 30],
		"recompense": [{"poussiere_echo": 15, "gemmes": 10}, {"poussiere_echo": 120, "gemmes": 50}]},
	"etages": {"texte": "Franchis %d étages des Tours", "objectif": [2, 15],
		"recompense": [{"or": 2000, "gemmes": 15}, {"coffre_or": 1, "gemmes": 60}]},
	"donjons_termines": {"texte": "Termine %d donjon(s)", "objectif": [1, 6],
		"recompense": [{"goutte_sang": 5, "gemmes": 15}, {"larme_sang": 6, "gemmes": 60}]},
	"missions_compagnie": {"texte": "Envoie %d missions de la Compagnie", "objectif": [2, 12],
		"recompense": [{"or": 1500, "gemmes": 10}, {"tome_grand": 2, "gemmes": 50}]},
	"marches": {"texte": "Pars %d fois dans la Marche Maudite", "objectif": [1, 4],
		"recompense": [{"sceau_marche": 10, "gemmes": 15}, {"sceau_marche": 60, "gemmes": 60}]},
	"combats_arene": {"texte": "Livre %d combats d'Arène", "objectif": [2, 12],
		"recompense": [{"or": 1500, "gemmes": 15}, {"gemmes": 80}]},
	"fusions": {"texte": "Utilise %d fois l'Autel de Fusion", "objectif": [1, 5],
		"recompense": [{"tome_petit": 1, "gemmes": 10}, {"pierre_eveil": 1, "gemmes": 30}]},
	"coffres_ouverts": {"texte": "Ouvre %d coffre(s) au Reliquaire", "objectif": [1, 8],
		"recompense": [{"or": 1000, "gemmes": 10}, {"coffre_argent": 2, "gemmes": 40}]},
	"boss_monde_tentatives": {"texte": "Attaque %d fois un Boss de Monde", "objectif": [1, 5],
		"recompense": [{"fragment_colossal": 3, "gemmes": 15}, {"fragment_colossal": 20, "gemmes": 60}]},
	"chapitres_termines": {"texte": "Termine %d chapitre(s) de l'histoire", "objectif": [1, 4],
		"recompense": [{"or": 2500, "gemmes": 20}, {"eclat_superieur": 1, "gemmes": 60}]},
}
## Quêtes toujours présentes (les autres sont tirées au hasard)
const TOUJOURS := {"jour": ["combats_gagnes", "stamina_depensee"], "semaine": ["combats_gagnes"]}
const NOMBRE := 5

const BONUS := {
	"jour": {"texte": "Termine toutes les quêtes du jour", "recompense": {"gemmes": 40, "coffre_argent": 1}},
	"semaine": {"texte": "Termine toutes les quêtes de la semaine", "recompense": {"gemmes": 200, "pierre_eveil": 1, "eclat_superieur": 2}},
}

## Récompenses de connexion (cycle de 7 jours)
const CONNEXION := [
	{"or": 2000}, {"gemmes": 20}, {"elixir_petit": 2}, {"or": 5000, "tome_petit": 2},
	{"gemmes": 40}, {"tome_grand": 1, "poussiere_echo": 30}, {"gemmes": 100, "eclat_superieur": 1},
]


# ---------------------------------------------------------------------
# État
# ---------------------------------------------------------------------

static func _etat() -> Dictionary:
	Sauvegarde.charger()
	if not Sauvegarde.donnees.has("quetes") or not Sauvegarde.donnees["quetes"] is Dictionary:
		Sauvegarde.donnees["quetes"] = {}
	var q: Dictionary = Sauvegarde.donnees["quetes"]
	var jour := Calendrier.jour_absolu()
	var semaine := Calendrier.semaine()
	if int(q.get("jour", -1)) != jour:
		q["jour"] = jour
		q["progres_jour"] = {}
		q["reclames_jour"] = []
	if int(q.get("semaine", -1)) != semaine:
		q["semaine"] = semaine
		q["progres_semaine"] = {}
		q["reclames_semaine"] = []
	for cle in ["connexion_jour", "connexion_index"]:
		if not q.has(cle):
			q[cle] = -1 if cle == "connexion_jour" else 0
	return q


## Appelé à chaque statistique ajoutée (voir Sauvegarde._stat).
static func noter(stat: String, montant := 1) -> void:
	if not Sauvegarde.donnees.has("statistiques"):
		return
	var cle: String = ALIAS.get(stat, stat)
	if not POOL.has(cle):
		return
	var q := _etat()
	for periode in ["jour", "semaine"]:
		var p: Dictionary = q["progres_" + periode]
		p[cle] = int(p.get(cle, 0)) + montant


# ---------------------------------------------------------------------
# Listes du jour et de la semaine
# ---------------------------------------------------------------------

## periode : "jour" ou "semaine". Renvoie [{id, texte, objectif, progres, recompense, fait, reclame}]
static func liste(periode: String) -> Array:
	var q := _etat()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("BoL-quetes-%s-%d" % [periode, int(q[periode])])
	var ids: Array = TOUJOURS[periode].duplicate()
	var reste: Array = POOL.keys().filter(func(k): return not k in ids)
	while ids.size() < NOMBRE and not reste.is_empty():
		ids.append(reste.pop_at(rng.randi_range(0, reste.size() - 1)))
	var i := 0 if periode == "jour" else 1
	var l: Array = []
	for id in ids:
		var d: Dictionary = POOL[id]
		var obj: int = d["objectif"][i]
		var prog := mini(obj, int(q["progres_" + periode].get(id, 0)))
		l.append({"id": id, "texte": str(d["texte"]) % obj, "objectif": obj, "progres": prog,
			"recompense": d["recompense"][i], "fait": prog >= obj, "reclame": id in q["reclames_" + periode]})
	return l


static func bonus_disponible(periode: String) -> bool:
	for x in liste(periode):
		if not x["fait"]:
			return false
	return not ("bonus" in _etat()["reclames_" + periode])


static func bonus_reclame(periode: String) -> bool:
	return "bonus" in _etat()["reclames_" + periode]


## Réclame une quête (id) ou le bonus ("bonus"). Renvoie les lignes de récompense.
static func reclamer(periode: String, id: String) -> Array:
	var q := _etat()
	var deja: Array = q["reclames_" + periode]
	if id in deja:
		return []
	var r: Dictionary = {}
	if id == "bonus":
		if not bonus_disponible(periode):
			return []
		r = BONUS[periode]["recompense"]
	else:
		var trouve := {}
		for x in liste(periode):
			if x["id"] == id:
				trouve = x
		if trouve.is_empty() or not trouve["fait"]:
			return []
		r = trouve["recompense"]
	deja.append(id)
	var lignes := donner(r)
	Sauvegarde.sauvegarder()
	return lignes


# ---------------------------------------------------------------------
# Connexion
# ---------------------------------------------------------------------

static func connexion_disponible() -> bool:
	return int(_etat()["connexion_jour"]) != Calendrier.jour_absolu()


## Index (0 à 6) de la prochaine récompense de connexion.
static func connexion_index() -> int:
	return int(_etat()["connexion_index"]) % CONNEXION.size()


static func reclamer_connexion() -> Array:
	if not connexion_disponible():
		return []
	var q := _etat()
	var i := connexion_index()
	q["connexion_jour"] = Calendrier.jour_absolu()
	q["connexion_index"] = i + 1
	var lignes := donner(CONNEXION[i])
	Sauvegarde.sauvegarder()
	return lignes


# ---------------------------------------------------------------------
# Outils
# ---------------------------------------------------------------------

## Donne une récompense (or, gemmes, objets). Renvoie les lignes à afficher.
static func donner(r: Dictionary) -> Array:
	var l: Array = []
	var reste := {}
	for o in r:
		if o == "gemmes":
			Sauvegarde.ajouter_gemmes(int(r[o]))
			Sauvegarde._stat("gemmes_gagnees", int(r[o]))
			l.append("Gemmes : +%d" % int(r[o]))
		else:
			reste[o] = r[o]
	l.append_array(Reliquaire.donner(reste))
	return l


static func texte_recompense(r: Dictionary) -> String:
	var t: Array = []
	for o in r:
		match o:
			"or": t.append("%d or" % int(r[o]))
			"gemmes": t.append("%d gemmes" % int(r[o]))
			_: t.append("%s x%d" % [Reliquaire.nom(o), int(r[o])])
	return " · ".join(t)


## Nombre de choses à réclamer (pastille du menu principal).
static func a_reclamer() -> int:
	var n := 1 if connexion_disponible() else 0
	for periode in ["jour", "semaine"]:
		for x in liste(periode):
			if x["fait"] and not x["reclame"]:
				n += 1
		if bonus_disponible(periode):
			n += 1
	return n
