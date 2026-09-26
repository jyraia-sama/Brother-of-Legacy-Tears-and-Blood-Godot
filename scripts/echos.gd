class_name Echos
extends RefCounted
## ÉCHOS SANGUINS — règles, création, amélioration et calcul des stats.
## Transposé du système C# (EchoData, EchoSlotRules, EchoSetCatalog, EchoStatsCalculator)
## et complété : étoiles 1-6, chances d'amélioration dégressives, valeurs chiffrées, drops.
##
## Un Écho (dans la sauvegarde) :
##   { uid, set, emplacement (1-6), rarete (0-4), etoiles (1-6), niveau (0-15),
##     principale (type de stat), secondaires: [{stat, valeur}], porteur (uid héros ou -1), verrou }
## La valeur de la stat principale n'est PAS stockée : elle se calcule avec valeur_principale(),
## ce qui permet de rééquilibrer sans casser les sauvegardes.

# ---------------------------------------------------------------------
# Stats possibles ("%" = pourcentage appliqué aux stats de base du héros)
# ---------------------------------------------------------------------
const NOMS_STATS := {
	"pv": "PV", "pv%": "PV %", "atk": "ATK", "atk%": "ATK %", "def": "DEF", "def%": "DEF %",
	"mag": "MAG", "mag%": "MAG %", "agi": "Vitesse", "crit": "Taux crit", "degats_crit": "Dégâts crit",
	"preci": "Précision", "res": "Résistance",
}
const STATS_EN_POURCENT := ["pv%", "atk%", "def%", "mag%", "crit", "degats_crit", "preci", "res"]

# ---------------------------------------------------------------------
# Les 6 emplacements (EchoSlotRules). La MAG n'existe qu'en stat secondaire.
# ---------------------------------------------------------------------
const EMPLACEMENTS := {
	1: {"nom": "Écho du Crâne", "principales": ["atk"]},
	2: {"nom": "Écho de l'Artère", "principales": ["pv", "pv%", "def", "def%", "atk", "atk%", "agi"]},
	3: {"nom": "Écho de la Plaie", "principales": ["def"]},
	4: {"nom": "Écho du Sacrifice", "principales": ["pv", "pv%", "def", "def%", "atk", "atk%", "crit", "degats_crit"]},
	5: {"nom": "Écho de l'Âme", "principales": ["pv"]},
	6: {"nom": "Écho du Serment", "principales": ["pv", "pv%", "def", "def%", "atk", "atk%", "preci", "res"]},
}
const SECONDAIRES_POSSIBLES := ["pv", "pv%", "atk", "atk%", "def", "def%", "mag", "mag%", "agi", "crit", "degats_crit", "preci", "res"]

# ---------------------------------------------------------------------
# Raretés : nombre de stats secondaires au départ (0 à 4)
# ---------------------------------------------------------------------
const RARETES := [
	{"nom": "Normal", "couleur": Color("b8b0a8"), "secondaires": 0},
	{"nom": "Magique", "couleur": Color("5fc06a"), "secondaires": 1},
	{"nom": "Rare", "couleur": Color("4f9fd6"), "secondaires": 2},
	{"nom": "Héroïque", "couleur": Color("a276d6"), "secondaires": 3},
	{"nom": "Légendaire", "couleur": Color("e8a030"), "secondaires": 4},
]

# ---------------------------------------------------------------------
# Les 12 sets (EchoSetCatalog) — un set par Acte
# ---------------------------------------------------------------------
const SETS := {
	"energy": {"nom": "Energy", "pieces": 2},
	"guard": {"nom": "Guard", "pieces": 2},
	"blade": {"nom": "Blade", "pieces": 2},
	"focus": {"nom": "Focus", "pieces": 2},
	"endure": {"nom": "Endure", "pieces": 2},
	"revenge": {"nom": "Revenge", "pieces": 2},
	"will": {"nom": "Will", "pieces": 2},
	"swift": {"nom": "Swift", "pieces": 4},
	"vampire": {"nom": "Vampire", "pieces": 4},
	"fatal": {"nom": "Fatal", "pieces": 4},
	"rage": {"nom": "Rage", "pieces": 4},
	"despair": {"nom": "Despair", "pieces": 4},
}


## Description d'un set avec ses valeurs actuelles.
static func description_set(set_id: String) -> String:
	var f := facteur_sets
	var t := {
		"energy": "PV max +%s %% par set actif." % _n(15 * f),
		"guard": "DEF +%s %% par set actif." % _n(15 * f),
		"blade": "Taux critique +%s par set actif." % _n(12 * f),
		"focus": "Précision +%s par set actif." % _n(20 * f),
		"endure": "Résistance +%s par set actif." % _n(20 * f),
		"revenge": "%s %% de chance de contre-attaquer (75 %% des dégâts) quand touché, par set actif." % _n(15 * f),
		"will": "Immunité aux afflictions pendant le 1er tour du combat.",
		"swift": "Vitesse +%s %%." % _n(25 * f),
		"vampire": "%s %% des dégâts infligés récupérés en PV." % _n(35 * f),
		"fatal": "ATK +%s %%." % _n(35 * f),
		"rage": "Dégâts critiques +%s %%." % _n(40 * f),
		"despair": "%s %% de chance d'étourdir la cible quand un skill inflige des dégâts." % _n(25 * f),
	}
	return "%s (%d pièces) : %s" % [SETS[set_id]["nom"], SETS[set_id]["pieces"], t[set_id]]


static func _n(x: float) -> String:
	return str(int(x)) if is_equal_approx(x, round(x)) else str(snappedf(x, 0.5))


## Set obtenu dans chaque Acte (le chapitre N donne toujours l'emplacement N).
const SET_PAR_ACTE := {
	1: "energy", 2: "endure", 3: "fatal", 4: "guard", 5: "revenge", 6: "focus",
	7: "despair", 8: "vampire", 9: "blade", 10: "rage", 11: "swift", 12: "will",
}

# ---------------------------------------------------------------------
# Valeurs (équilibrage) — modifiables
# ---------------------------------------------------------------------
## Puissance globale des Échos (stats principales et secondaires). Réglée par simulation.
static var puissance := 0.4
## Force des bonus de sets (1.0 = valeurs d'origine du C#). Réduite de moitié car, avec 6 emplacements,
## un set à 2 pièces peut s'activer 3 fois (ex : Energy x3 = +45 % PV avec les valeurs d'origine).
static var facteur_sets := 0.5
const NIVEAU_MAX := 15
const PALIERS := [3, 6, 9, 12, 15]            # nouvelle stat secondaire ou renforcement

## Valeur de la stat principale d'un Écho 6 étoiles au niveau +15.
const PRINCIPALE_MAX := {
	"pv": 900, "pv%": 40, "atk": 110, "atk%": 40, "def": 90, "def%": 40,
	"agi": 32, "crit": 30, "degats_crit": 50, "preci": 40, "res": 40,
}
## Tirage d'une stat secondaire pour un Écho 6 étoiles (min, max).
const SECONDAIRE_TIRAGE := {
	"pv": [60, 150], "pv%": [3, 8], "atk": [8, 20], "atk%": [3, 8], "def": [8, 20], "def%": [3, 8],
	"mag": [8, 20], "mag%": [3, 8], "agi": [3, 6], "crit": [2, 6], "degats_crit": [3, 7],
	"preci": [3, 8], "res": [3, 8],
}
## Chance de réussite pour passer au niveau N (index = niveau visé). En cas d'échec l'or est perdu,
## l'Écho reste intact.
const CHANCES_AMELIORATION := [1.0, 1.0, 1.0, 1.0, 0.9, 0.85, 0.8, 0.7, 0.6, 0.5, 0.4, 0.35, 0.3, 0.25, 0.2, 0.15]


static func facteur_etoiles(etoiles: int) -> float:
	return 0.5 + 0.1 * etoiles                    # 1★ = 0,6 ... 6★ = 1,1


## Valeur actuelle de la stat principale (dépend des étoiles et du niveau).
static func valeur_principale(e: Dictionary) -> float:
	var maxi_: float = PRINCIPALE_MAX[e["principale"]]
	var et := int(e["etoiles"])
	var depart := maxi_ * (0.08 + 0.05 * (et - 1))       # niveau +0
	var fin := maxi_ * (0.35 + 0.13 * (et - 1))          # niveau +15 (6★ = 100 %)
	var v := lerpf(depart, fin, float(e["niveau"]) / NIVEAU_MAX) * puissance
	return round(v) if not e["principale"] in STATS_EN_POURCENT else snappedf(v, 0.1)


static func nom(e: Dictionary) -> String:
	return "%s %s" % [EMPLACEMENTS[int(e["emplacement"])]["nom"], SETS[e["set"]]["nom"]]


static func texte_stat(stat: String, valeur: float) -> String:
	var v := str(int(round(valeur))) if not stat in STATS_EN_POURCENT else str(snappedf(valeur, 0.1))
	var suffixe := " %" if stat.ends_with("%") or stat in ["degats_crit"] else ""
	return "%s +%s%s" % [NOMS_STATS[stat].trim_suffix(" %"), v, suffixe]


# ---------------------------------------------------------------------
# Création (EchoData.CreerNouveau)
# ---------------------------------------------------------------------

static func creer(set_id: String, emplacement: int, rarete: int, etoiles: int, principale: String, rng: RandomNumberGenerator) -> Dictionary:
	assert(principale in EMPLACEMENTS[emplacement]["principales"], "Stat principale invalide pour cet emplacement")
	var e := {"uid": 0, "set": set_id, "emplacement": emplacement, "rarete": rarete, "etoiles": etoiles,
		"niveau": 0, "principale": principale, "secondaires": [], "porteur": -1, "verrou": false}
	var pool := SECONDAIRES_POSSIBLES.filter(func(s): return s != principale)
	_melanger(pool, rng)
	for i in mini(RARETES[rarete]["secondaires"], pool.size()):
		e["secondaires"].append({"stat": pool[i], "valeur": _tirage(pool[i], etoiles, rng)})
	return e


static func _tirage(stat: String, etoiles: int, rng: RandomNumberGenerator) -> float:
	var t: Array = SECONDAIRE_TIRAGE[stat]
	var v := rng.randf_range(t[0], t[1]) * facteur_etoiles(etoiles) * puissance
	return snappedf(v, 0.1) if stat in STATS_EN_POURCENT else round(v)


static func _melanger(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp


# ---------------------------------------------------------------------
# Amélioration (EchoData.AmeliorerNiveau) + chances dégressives et coût
# ---------------------------------------------------------------------

static func cout_amelioration(e: Dictionary) -> int:
	return int(50 * int(e["etoiles"]) * (1.0 + int(e["niveau"]) * 0.6))


static func chance_amelioration(e: Dictionary) -> float:
	var n := int(e["niveau"]) + 1
	return CHANCES_AMELIORATION[mini(n, CHANCES_AMELIORATION.size() - 1)]


## Tente +1. Renvoie {"reussi": bool, "texte": ...}. Ne gère pas le paiement.
static func ameliorer(e: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	if int(e["niveau"]) >= NIVEAU_MAX:
		return {"reussi": false, "texte": "Niveau maximum atteint."}
	if rng.randf() >= chance_amelioration(e):
		return {"reussi": false, "texte": "Échec de l'amélioration… l'Écho reste intact."}
	e["niveau"] = int(e["niveau"]) + 1
	var texte := "Réussite : +%d !" % int(e["niveau"])
	if int(e["niveau"]) in PALIERS:
		var secs: Array = e["secondaires"]
		if secs.size() < 4:
			var deja := secs.map(func(s): return s["stat"])
			var pool := SECONDAIRES_POSSIBLES.filter(func(s): return s != e["principale"] and not s in deja)
			if not pool.is_empty():
				var st: String = pool[rng.randi_range(0, pool.size() - 1)]
				secs.append({"stat": st, "valeur": _tirage(st, int(e["etoiles"]), rng)})
				texte += "\nNouvelle stat : " + texte_stat(st, secs[-1]["valeur"])
				return {"reussi": true, "texte": texte}
		if not secs.is_empty():
			# 4 stats déjà présentes : l'une d'elles est renforcée d'un nouveau tirage
			var s: Dictionary = secs[rng.randi_range(0, secs.size() - 1)]
			s["valeur"] = s["valeur"] + _tirage(s["stat"], int(e["etoiles"]), rng)
			texte += "\nRenforcée : " + texte_stat(s["stat"], s["valeur"])
	return {"reussi": true, "texte": texte}


static func prix_vente(e: Dictionary) -> int:
	return int(20 * int(e["etoiles"]) * (int(e["rarete"]) + 1) * (1.0 + int(e["niveau"]) * 0.1))


# ---------------------------------------------------------------------
# Calcul (EchoStatsCalculator) : bonus totaux des Échos d'un héros
# ---------------------------------------------------------------------

## Renvoie {"fixe": {stat: v}, "pourcent": {stat: v}, "points": {crit/degats_crit/preci/res: v},
##          "sets": [noms actifs], "vol_vie", "contre_chance", "etourdir_skill", "immunite_debut"}
static func bonus(echos_portes: Array) -> Dictionary:
	var b := {"fixe": {}, "pourcent": {}, "points": {}, "sets": [],
		"vol_vie": 0.0, "contre_chance": 0.0, "etourdir_skill": 0.0, "immunite_debut": false}
	for e in echos_portes:
		_ajouter(b, e["principale"], valeur_principale(e))
		for s in e["secondaires"]:
			_ajouter(b, s["stat"], s["valeur"])
	# Sets : un set à 2 pièces peut s'activer jusqu'à 3 fois, un set à 4 pièces une fois
	var compte := {}
	for e in echos_portes:
		compte[e["set"]] = int(compte.get(e["set"], 0)) + 1
	for set_id in compte:
		var info: Dictionary = SETS[set_id]
		var n: int = compte[set_id] / int(info["pieces"])
		if n <= 0:
			continue
		for k in n:
			b["sets"].append(info["nom"])
		match set_id:
			"energy": _ajouter(b, "pv%", 15.0 * n * facteur_sets)
			"guard": _ajouter(b, "def%", 15.0 * n * facteur_sets)
			"blade": _ajouter(b, "crit", 12.0 * n * facteur_sets)
			"focus": _ajouter(b, "preci", 20.0 * n * facteur_sets)
			"endure": _ajouter(b, "res", 20.0 * n * facteur_sets)
			"swift": b["pourcent"]["agi"] = b["pourcent"].get("agi", 0.0) + 25.0 * n * facteur_sets
			"fatal": _ajouter(b, "atk%", 35.0 * n * facteur_sets)
			"rage": _ajouter(b, "degats_crit", 40.0 * n * facteur_sets)
			"vampire": b["vol_vie"] += 0.35 * n * facteur_sets
			"despair": b["etourdir_skill"] += 0.25 * n * facteur_sets
			"revenge": b["contre_chance"] += 0.15 * n * facteur_sets
			"will": b["immunite_debut"] = true
	return b


static func _ajouter(b: Dictionary, stat: String, v: float) -> void:
	if stat in ["crit", "degats_crit", "preci", "res"]:
		b["points"][stat] = b["points"].get(stat, 0.0) + v
	elif stat.ends_with("%"):
		var s := stat.trim_suffix("%")
		b["pourcent"][s] = b["pourcent"].get(s, 0.0) + v
	else:
		b["fixe"][stat] = b["fixe"].get(stat, 0.0) + v


## Applique les bonus sur des stats (de UnitesData.stats). Les % s'appliquent aux stats de base.
static func appliquer(stats: Dictionary, b: Dictionary) -> Dictionary:
	var s := stats.duplicate()
	for st in ["pv", "atk", "def", "agi", "mag"]:
		var base: float = stats[st]
		s[st] = int(round(base + b["fixe"].get(st, 0.0) + base * b["pourcent"].get(st, 0.0) / 100.0))
	for st in ["crit", "degats_crit", "preci", "res"]:
		s[st] = int(round(stats[st] + b["points"].get(st, 0.0)))
	return s


# ---------------------------------------------------------------------
# Drops : quel Écho tombe d'un combat gagné ?
# ---------------------------------------------------------------------
## Chance qu'un Écho tombe après une victoire, selon le type de combat.
const CHANCE_DROP := {"combat": 0.35, "elite": 0.55, "gardien": 0.70, "boss_chapitre": 1.0, "boss_acte": 1.0}
## Poids des raretés (Normal, Magique, Rare, Héroïque, Légendaire) selon le type de combat :
## les monstres normaux donnent surtout des Échos de mauvaise qualité, les boss les meilleurs.
const POIDS_RARETE := {
	"combat": [70, 25, 5, 0, 0], "elite": [35, 40, 20, 5, 0], "gardien": [20, 40, 30, 9, 1],
	"boss_chapitre": [5, 25, 40, 25, 5], "boss_acte": [0, 15, 40, 33, 12],
}
## Étoiles en plus (ou en moins) selon le type de combat
const BONUS_ETOILES := {"combat": -1, "elite": 0, "gardien": 0, "boss_chapitre": 1, "boss_acte": 1}


## Ce qu'on peut trouver dans un chapitre (texte pour l'interface).
static func texte_loot(acte: int, chapitre: int) -> String:
	var emp := clampi(chapitre, 1, 6)
	return "Échos : set %s · %s (emplacement %d)" % [SETS[SET_PAR_ACTE[acte]]["nom"], EMPLACEMENTS[emp]["nom"], emp]


## Renvoie un nouvel Écho (non enregistré) ou {} si rien ne tombe.
static func tirer_drop(acte: int, chapitre: int, type: String, rng: RandomNumberGenerator) -> Dictionary:
	if rng.randf() >= float(CHANCE_DROP.get(type, 0.0)):
		return {}
	var p := (acte - 1) * 6 + (chapitre - 1)
	var etoiles := 1 + int(p / 14.0) + (1 if rng.randf() < 0.35 else 0) + int(BONUS_ETOILES.get(type, 0))
	etoiles = clampi(etoiles, 1, 6)
	var poids: Array = POIDS_RARETE[type]
	var total := 0
	for w in poids:
		total += w
	var r := rng.randi_range(1, total)
	var rarete := 0
	for i in poids.size():
		r -= poids[i]
		if r <= 0:
			rarete = i
			break
	var emplacement := clampi(chapitre, 1, 6)
	var principales: Array = EMPLACEMENTS[emplacement]["principales"]
	var principale: String = principales[rng.randi_range(0, principales.size() - 1)]
	return creer(SET_PAR_ACTE[acte], emplacement, rarete, etoiles, principale, rng)
