class_name PlateauGenerateur
extends RefCounted
## Génère le plateau de chaque chapitre (72 plateaux au total).
##
## - Toujours le MÊME plateau pour un même chapitre (graine fixe = acte + chapitre).
## - Les embranchements se referment TOUJOURS avant le boss.
## - La complexité augmente avec la progression (voir _parametres()) :
##     Acte I      : 1 à 2 fourches de 2 voies, plateaux courts
##     Actes II-III: culs-de-sac à trésor, cases Mystère, puis Pièges
##     Actes IV-VI : fourches à 3 voies, plus d'Élites et de Gardiens
##     Actes V+    : passerelles entre voies (on peut changer de chemin)
##     Actes VII+  : fourches à 4 voies, voies qui se divisent encore
##
## Pour modifier l'équilibrage, change les valeurs dans _parametres().

enum Type { DEPART, COMBAT, ELITE, GARDIEN, BOSS, COFFRE, SOIN, MYSTERE, PIEGE }

const NOMS := {
	Type.DEPART: "Point de départ",
	Type.COMBAT: "Combat",
	Type.ELITE: "Combat d'Élite",
	Type.GARDIEN: "Gardien",
	Type.BOSS: "Boss",
	Type.COFFRE: "Coffre d'or",
	Type.SOIN: "Autel de soin",
	Type.MYSTERE: "Mystère",
	Type.PIEGE: "Piège",
}

const DESCRIPTIONS := {
	Type.DEPART: "Le point de départ de l'expédition.",
	Type.COMBAT: "Un groupe d'ennemis ordinaires barre la route.",
	Type.ELITE: "Des ennemis redoutables. Plus dangereux, mais mieux récompensés.",
	Type.GARDIEN: "Un gardien veille sur ce carrefour. Il faut le vaincre pour passer.",
	Type.BOSS: "Le maître des lieux. Le vaincre termine le chapitre.",
	Type.COFFRE: "Un coffre rempli d'or.",
	Type.SOIN: "Un autel ancien qui soigne l'équipe.",
	Type.MYSTERE: "Personne ne sait ce qui attend ici : trésor, bénédiction… ou embuscade.",
	Type.PIEGE: "Un piège dissimulé. Il blesse l'équipe au passage.",
}

const COMBATS := [Type.COMBAT, Type.ELITE, Type.GARDIEN, Type.BOSS]

var _rng := RandomNumberGenerator.new()
var _noeuds: Array = []
var _p: Dictionary = {}


## Point d'entrée : renvoie le plateau d'un chapitre.
## {
##   "acte", "chapitre", "depart": id, "boss": id, "longueur": float,
##   "noeuds": [ { "id", "pos": Vector2 (en cases), "type", "voisins": [ids],
##                 "niveau", "cul_de_sac": bool, "voie_risquee": bool } ]
## }
static func generer(acte: int, chapitre: int) -> Dictionary:
	var g := PlateauGenerateur.new()
	return g._generer(acte, chapitre)


static func est_combat(type: int) -> bool:
	return type in COMBATS


# ------------------------------------------------------------------
# Réglages de difficulté / complexité selon la progression
# ------------------------------------------------------------------
func _parametres(acte: int, chapitre: int) -> Dictionary:
	var p := (acte - 1) * 6 + (chapitre - 1)      # 0 (I-1) à 71 (XII-6)
	var t := p / 71.0                             # 0.0 -> 1.0
	var voies := [2, 2, 2, 3, 3, 3, 4, 4, 4, 4, 4, 4]
	return {
		"acte": acte,
		"chapitre": chapitre,
		"t": t,
		"longueur": 7 + int(round(t * 13.0)) + (2 if chapitre == 6 else 0),
		"voies_max": voies[acte - 1],
		"voie_min": 2 + int(t * 1.5),
		"voie_max": 3 + int(t * 2.5),
		"proba_fourche": 0.45 + t * 0.4,
		"fourches_max": 1 if (acte == 1 and chapitre <= 2) else 99,
		"proba_gardien_jonction": 0.10 + t * 0.6,
		"taux_elite": 0.04 + t * 0.15,
		"taux_coffre": 0.14 - t * 0.04,
		"taux_soin": 0.10 - t * 0.05,
		"taux_mystere": 0.0 if acte < 2 else 0.07 + t * 0.06,
		"taux_piege": 0.0 if acte < 3 else 0.05 + t * 0.08,
		"proba_cul_de_sac": 0.0 if acte < 2 else 0.25 + t * 0.35,
		"proba_passerelle": 0.0 if acte < 5 else 0.30 + t * 0.35,
		"proba_sous_fourche": 0.0 if acte < 7 else 0.30 + t * 0.30,
		"voie_risquee": acte >= 2 or chapitre >= 4,
		"niveau_base": 1 + int(t * 27.0),
	}


func _generer(acte: int, chapitre: int) -> Dictionary:
	_rng.seed = hash("BoL-plateau-%d-%d" % [acte, chapitre])
	_p = _parametres(acte, chapitre)
	_noeuds.clear()

	var fin: float = _p["longueur"] - 2.0
	var depart := _ajouter(Vector2(0, 0), Type.DEPART)
	var courant := depart
	var x := 0.0
	var nb_fourches := 0
	var depuis_fourche := 99

	while x < fin - 1.0:
		var reste := fin - 1.0 - x
		var veut_fourche: bool = _rng.randf() < _p["proba_fourche"] or depuis_fourche >= 3
		if reste >= 3.0 and veut_fourche and nb_fourches < _p["fourches_max"] and depuis_fourche >= 1:
			var res := _fourche(x, courant, reste)
			x = res[0]
			courant = res[1]
			nb_fourches += 1
			depuis_fourche = 0
		else:
			x += 1.0
			var n := _ajouter(Vector2(x, _rng.randf_range(-0.12, 0.12)), _tirer_type(1.0))
			_lier(courant, n)
			courant = n
			depuis_fourche += 1

	# Dernière ligne droite : tous les chemins se sont refermés -> Gardien -> Boss
	x += 1.0
	var type_garde := Type.GARDIEN if (acte > 1 or chapitre >= 3) else Type.COMBAT
	var garde := _ajouter(Vector2(x, 0), type_garde)
	_lier(courant, garde)
	courant = garde
	if chapitre == 6 or acte >= 6:
		x += 1.0
		var repos := _ajouter(Vector2(x, 0), Type.SOIN)
		_lier(courant, repos)
		courant = repos
	x += 1.3
	var boss := _ajouter(Vector2(x, 0), Type.BOSS)
	_lier(courant, boss)

	_attribuer_niveaux(x)
	return {
		"acte": acte,
		"chapitre": chapitre,
		"depart": depart,
		"boss": boss,
		"longueur": x,
		"noeuds": _noeuds,
	}


# Une fourche : k voies qui partent de `origine` et se rejoignent sur un nœud de jonction.
# Renvoie [nouvelle position x, id de la jonction].
func _fourche(x0: float, origine: int, reste: float) -> Array:
	var k := _rng.randi_range(2, _p["voies_max"])
	var lmax := mini(_p["voie_max"], int(reste) - 1)
	var lmin := mini(_p["voie_min"], lmax)
	var longueur_max := 0
	var longueurs: Array[int] = []
	for i in k:
		var l := _rng.randi_range(maxi(1, lmin), maxi(1, lmax))
		longueurs.append(l)
		longueur_max = maxi(longueur_max, l)
	var etendue := float(longueur_max + 1)
	var x_jonction := x0 + etendue

	# Nœud de jonction (les voies s'y referment)
	var type_j := Type.GARDIEN if _rng.randf() < _p["proba_gardien_jonction"] else _tirer_type(1.0)
	if type_j in [Type.PIEGE, Type.MYSTERE]:
		type_j = Type.COMBAT
	var jonction := _ajouter(Vector2(x_jonction, 0), type_j)

	var risquee := _rng.randi_range(0, k - 1) if _p["voie_risquee"] else -1
	var voies: Array = []   # chaque voie = liste d'ids (voie principale seulement)

	# Place verticale de chaque voie : une voie qui se divise prend plus de place
	var sous_voies: Array[bool] = []
	var hauteurs: Array[float] = []
	var total := 0.0
	for i in k:
		var sv: bool = longueurs[i] >= 3 and _rng.randf() < _p["proba_sous_fourche"]
		sous_voies.append(sv)
		hauteurs.append(1.9 if sv else 1.15)
		total += hauteurs[i]
	var centres: Array[float] = []
	var curseur := -total / 2.0
	for i in k:
		centres.append(curseur + hauteurs[i] / 2.0)
		curseur += hauteurs[i]

	for i in k:
		var y: float = centres[i]
		var l: int = longueurs[i]
		var bonus_elite := 2.5 if i == risquee else 1.0
		var ids: Array = []
		var sous: bool = sous_voies[i]
		var precedent := origine

		if sous:
			# La voie se divise encore en deux petites voies, qui rejoignent la jonction
			var tete := _ajouter(_pos_voie(x0, etendue, 0, l, y), _tirer_type(bonus_elite))
			_lier(precedent, tete)
			ids.append(tete)
			for s in [-1, 1]:
				var prec_s := tete
				var ls := l - 1 - (_rng.randi_range(0, 1) if l > 3 else 0)
				for j in ls:
					var pos := _pos_voie(x0 + etendue / (l + 1), etendue - etendue / (l + 1), j, ls, y + s * 0.45)
					var n := _ajouter(pos, _tirer_type(bonus_elite))
					_lier(prec_s, n)
					prec_s = n
				_lier(prec_s, jonction)
		else:
			for j in l:
				var n := _ajouter(_pos_voie(x0, etendue, j, l, y), _tirer_type(bonus_elite))
				_lier(precedent, n)
				ids.append(n)
				precedent = n
			_lier(precedent, jonction)
			# La voie risquée garde un coffre au bout
			if i == risquee and l >= 2:
				_noeuds[ids[-1]]["type"] = Type.COFFRE
		for id in ids:
			_noeuds[id]["voie_risquee"] = (i == risquee)
		voies.append(ids)

		# Cul-de-sac à trésor sur les voies extérieures
		var exterieure := (i == 0 or i == k - 1)
		if exterieure and not ids.is_empty() and _rng.randf() < _p["proba_cul_de_sac"]:
			var base_id: int = ids[_rng.randi_range(0, ids.size() - 1)]
			var sens := -1.0 if y < 0 else 1.0
			var bp: Vector2 = _noeuds[base_id]["pos"]
			var prec_c := base_id
			if _p["t"] > 0.3 and _rng.randf() < 0.5:
				var gardien_tresor := _ajouter(bp + Vector2(0.15, sens * 0.95), Type.ELITE)
				_noeuds[gardien_tresor]["cul_de_sac"] = true
				_lier(prec_c, gardien_tresor)
				prec_c = gardien_tresor
				bp = _noeuds[gardien_tresor]["pos"]
			var tresor := _ajouter(bp + Vector2(0.1, sens * 0.95), Type.COFFRE)
			_noeuds[tresor]["cul_de_sac"] = true
			_lier(prec_c, tresor)

	# Passerelles entre voies voisines (on peut changer de chemin en route)
	for i in k - 1:
		var a: Array = voies[i]
		var b: Array = voies[i + 1]
		if a.size() >= 2 and b.size() >= 2 and _rng.randf() < _p["proba_passerelle"]:
			var na: int = a[_rng.randi_range(0, a.size() - 1)]
			var nb: int = b[0]
			var meilleur := INF
			for id in b:
				var d: float = absf(_noeuds[id]["pos"].x - _noeuds[na]["pos"].x)
				if d < meilleur:
					meilleur = d
					nb = id
			_lier(na, nb)

	return [x_jonction, jonction]


func _pos_voie(x0: float, etendue: float, j: int, l: int, y: float) -> Vector2:
	var x := x0 + (j + 1) * etendue / (l + 1)
	return Vector2(x + _rng.randf_range(-0.08, 0.08), y + _rng.randf_range(-0.14, 0.14))


func _tirer_type(bonus_elite: float) -> int:
	var poids := {
		Type.ELITE: _p["taux_elite"] * bonus_elite,
		Type.COFFRE: _p["taux_coffre"],
		Type.SOIN: _p["taux_soin"],
		Type.MYSTERE: _p["taux_mystere"],
		Type.PIEGE: _p["taux_piege"],
	}
	var r := _rng.randf()
	var cumul := 0.0
	for type in poids:
		cumul += poids[type]
		if r < cumul:
			return type
	return Type.COMBAT


func _ajouter(pos: Vector2, type: int) -> int:
	var id := _noeuds.size()
	_noeuds.append({
		"id": id,
		"pos": pos,
		"type": type,
		"voisins": [],
		"niveau": 0,
		"cul_de_sac": false,
		"voie_risquee": false,
	})
	return id


func _lier(a: int, b: int) -> void:
	if a == b:
		return
	if not b in _noeuds[a]["voisins"]:
		_noeuds[a]["voisins"].append(b)
	if not a in _noeuds[b]["voisins"]:
		_noeuds[b]["voisins"].append(a)


func _attribuer_niveaux(longueur: float) -> void:
	var base: int = _p["niveau_base"]
	for n in _noeuds:
		var avance := int(round(n["pos"].x / maxf(longueur, 1.0) * 2.0))
		var bonus := 0
		match n["type"]:
			Type.ELITE: bonus = 2
			Type.GARDIEN: bonus = 3
			Type.BOSS: bonus = 5
		n["niveau"] = base + avance + bonus
