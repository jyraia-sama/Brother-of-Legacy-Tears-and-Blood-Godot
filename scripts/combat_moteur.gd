class_name CombatMoteur
extends RefCounted
## MOTEUR DE COMBAT (automatique, avec part de hasard).
## Calcule tout le combat d'un coup et renvoie un JOURNAL d'événements
## que l'écran de combat rejoue ensuite avec des animations.
##
##   var m := CombatMoteur.new(equipe_joueur, equipe_ennemie, graine)
##   var resultat := m.combattre()     # {victoire, tours, journal, pv_final}
##
## Équipes : tableaux de { "id", "niveau", ... } dans l'ordre des places.
##   Places 1 et 2 = AVANT, places 3 à 5 = ARRIÈRE (Boss de Monde : 4 escouades de 5,
##   places 0-19 ; dans chaque escouade les 2 premières sont à l'Avant).
##
## RÈGLES PRINCIPALES (modifiables dans les constantes ci-dessous)
## - Ordre d'action : AGI (avec un peu de hasard), recalculé à chaque tour.
## - Corps à corps (Guerrier, Tank, Assassin) : doit viser l'AVANT ennemi tant qu'il reste
##   quelqu'un devant. Bonus de dégâts s'il est à l'Avant, malus s'il est placé à l'Arrière.
## - L'AVANT reçoit plus de dégâts de corps à corps, l'ARRIÈRE en reçoit moins.
## - Distance (Tireur, Mage, Soutien) : peut viser n'importe qui.
## - Dégâts physiques = ATK² / (ATK + DEF). Dégâts de skill = puissance x multiplicateur,
##   réduits par la RES. Puissance de skill = 0,6 ATK + MAG.
## - Éléments : Feu > Nature > Eau > Feu ; Ténèbres <-> Sacré. +25 % / -20 %.

const ROLES_MELEE := ["guerrier", "tank", "assassin"]
const BONUS_MELEE_AVANT := 0.15      # corps à corps placé à l'Avant : +15 % dégâts
const MALUS_MELEE_ARRIERE := 0.30    # corps à corps placé à l'Arrière : -30 % dégâts
const RECU_AVANT := 0.10             # l'Avant reçoit +10 % des coups de corps à corps
const REDUIT_ARRIERE := 0.20         # l'Arrière reçoit -20 % des coups de corps à corps
const RECU_DISTANCE_AVANT := 0.10    # un tireur/mage/soutien exposé à l'Avant prend +10 %

const FORT_CONTRE := {"feu": "nature", "nature": "eau", "eau": "feu", "tenebres": "sacre", "sacre": "tenebres"}
const BONUS_ELEMENT := 0.25
const MALUS_ELEMENT := 0.20

const TOURS_MAX := 30
const ESQUIVE_AVEUGLE := 35          # Aveuglement : -35 de précision
const POISON := 0.06                 # % PV max perdus par tour
const BRULURE := 0.05
const SAIGNEMENT := 0.05
const GEL_PERTE_TOUR := 0.35         # chance de perdre son tour quand gelé
const GEANT_DOT := 0.04              # poison / brûlure / saignement sur un Boss de Monde : x0,04

var journal: Array = []
var unites: Array = []               # tous les combattants (joueur puis ennemis)
var tour := 0
var tours_max := TOURS_MAX
var _rng := RandomNumberGenerator.new()


## `tours` : durée maximale du combat (Boss de Monde : plus court).
func _init(equipe_joueur: Array, equipe_ennemie: Array, graine := 0, tours := TOURS_MAX) -> void:
	tours_max = tours
	_rng.seed = graine if graine != 0 else randi()
	for i in equipe_joueur.size():
		unites.append(_creer(equipe_joueur[i], 0, int(equipe_joueur[i].get("place", i))))
	for i in equipe_ennemie.size():
		unites.append(_creer(equipe_ennemie[i], 1, i))
	_appliquer_passifs_depart()


# =====================================================================
# Création des combattants
# =====================================================================

func _creer(e: Dictionary, camp: int, place: int) -> Dictionary:
	var u := UnitesData.get_unite(e["id"])
	var niveau := int(e.get("niveau", 1))
	var s := UnitesData.stats(e["id"], niveau)
	# Étoiles (Autel de Fusion) : héros du joueur uniquement
	if e.has("etoiles"):
		s = Fusion.appliquer_etoiles(s, int(e["etoiles"]))
	# Renfort des ennemis (élite, gardien, boss, difficulté) : surtout en PV,
	# un peu en attaque, peu en défense (sinon les coups physiques deviennent inutiles).
	var mult: float = e.get("mult", 1.0)
	s["pv"] = s["pv"] * mult
	for cle in ["atk", "mag"]:
		s[cle] = s[cle] * (1.0 + (mult - 1.0) * 0.5)
	s["def"] = s["def"] * (1.0 + (mult - 1.0) * 0.25)
	s["agi"] = s["agi"] * (1.0 + (mult - 1.0) * 0.15)
	# Boss de Monde : multiplicateurs de stats démesurés, stat par stat
	var ms: Dictionary = e.get("mult_stats", {})
	for cle in ms:
		s[cle] = s[cle] * float(ms[cle])
	# Échos Sanguins portés (joueur)
	var echos: Dictionary = e.get("echos", {})
	if not echos.is_empty():
		s = Echos.appliquer(s, echos)
	var c := {
		"idx": unites.size(), "camp": camp, "place": place, "id": e["id"],
		"nom": e.get("nom", u["nom"]), "niveau": niveau, "role": u["role"], "element": u["element"],
		"melee": u["role"] in ROLES_MELEE, "avant": (place % 5) < 2,
		"actions": maxi(1, int(e.get("actions", 1))), "geant": bool(e.get("geant", false)),
		"base": s, "pv_max": float(s["pv"]), "pv": 0.0, "bouclier": 0.0, "vivant": true,
		"actifs": [], "p": _passifs_vides(), "buffs": [], "afflictions": {}, "provocation": 0,
		"regen_temp": [], "survie": 0, "renaissance": 0.0, "accum": 0, "bonus_atk": float(e.get("bonus_atk", 0.0)),
		"boss": bool(e.get("boss", false)), "elite": bool(e.get("elite", false)),
		"phase2": u.get("phase2", {}) if e.get("boss", false) else {}, "phase_faite": false,
	}
	for sk in UnitesData.skills_debloques(e["id"], niveau):
		if sk["type"] == "actif":
			c["actifs"].append(sk)
		else:
			_ajouter_passif(c, sk)
	c["actifs"].sort_custom(func(a, b): return a["niveau"] > b["niveau"])
	c["pv"] = c["pv_max"] * clampf(float(e.get("pv_ratio", 1.0)), 0.0, 1.0)
	if c["pv"] <= 0.0:
		c["vivant"] = false
	c["survie"] = c["p"]["survie"]
	c["renaissance"] = c["p"]["renaissance"]
	# Effets des sets d'Échos
	c["etourdir_skill"] = 0.0
	c["immunite_debut"] = false
	if not echos.is_empty():
		c["p"]["vol_vie"] += echos["vol_vie"]
		if echos["contre_chance"] > 0.0:
			if c["p"]["contre_chance"] <= 0.0:
				c["p"]["contre_mult"] = 0.75
			c["p"]["contre_chance"] += echos["contre_chance"]
		c["etourdir_skill"] = echos["etourdir_skill"]
		c["immunite_debut"] = echos["immunite_debut"]
	return c


func _passifs_vides() -> Dictionary:
	return {"stats": {}, "auras": [], "auras_ennemis": [], "vol_vie": 0.0, "epines": 0.0,
		"contre_chance": 0.0, "contre_mult": 1.0, "regen": 0.0, "survie": 0, "renaissance": 0.0,
		"immunites": [], "soin_bonus": 0.0, "double": 0.0, "bonus_arriere": 0.0, "execution": 0.0,
		"premier": false, "accum_stat": "", "accum_val": 0.0, "accum_max": 0, "rage_stat": "", "rage_val": 0.0}


func _ajouter_passif(c: Dictionary, sk: Dictionary) -> void:
	var p: Dictionary = c["p"]
	for e in sk["effets"]:
		match e["effet"]:
			"stat": p["stats"][e["stat"]] = p["stats"].get(e["stat"], 0.0) + float(e["valeur"])
			"aura": p["auras"].append(e)
			"aura_ennemis": p["auras_ennemis"].append(e)
			"vol_vie": p["vol_vie"] += e["valeur"]
			"epines": p["epines"] += e["valeur"]
			"contre":
				p["contre_chance"] += e["chance"]
				p["contre_mult"] = e["mult"]
			"regen": p["regen"] += e["valeur"]
			"survie": p["survie"] += int(e["charges"])
			"renaissance": p["renaissance"] = e["valeur"]
			"immunite": p["immunites"].append_array(e["afflictions"])
			"soin_bonus": p["soin_bonus"] += e["valeur"]
			"double_attaque": p["double"] += e["chance"]
			"bonus_arriere": p["bonus_arriere"] += e["valeur"]
			"execution": p["execution"] += e["valeur"]
			"premier": p["premier"] = true
			"accumulation":
				p["accum_stat"] = e["stat"]
				p["accum_val"] = e["valeur"]
				p["accum_max"] = int(e["max"])
			"rage":
				p["rage_stat"] = e["stat"]
				p["rage_val"] = e["valeur"]


func _appliquer_passifs_depart() -> void:
	# Bonus de stats personnels (crit, précision, dégâts crit en points ; le reste en %)
	for c in unites:
		for st in c["p"]["stats"]:
			var v: float = c["p"]["stats"][st]
			if st in ["crit", "preci", "degats_crit"]:
				c["base"][st] = c["base"][st] + v
			else:
				c["base"][st] = c["base"][st] * (1.0 + v)
		if c["p"]["stats"].has("pv"):
			var ratio: float = c["pv"] / c["pv_max"]
			c["pv_max"] = float(c["base"]["pv"])
			c["pv"] = c["pv_max"] * ratio
	# Auras (sur les alliés) et auras sur les ennemis
	for c in unites:
		for a in c["p"]["auras"]:
			for allie in _equipe(c["camp"]):
				_modifier_base(allie, a["stat"], a["valeur"])
		for a in c["p"]["auras_ennemis"]:
			for ennemi in _equipe(1 - c["camp"]):
				_modifier_base(ennemi, a["stat"], -a["valeur"])


func _modifier_base(c: Dictionary, st: String, v: float) -> void:
	c["base"][st] = c["base"][st] * (1.0 + v)
	if st == "pv":
		var ratio: float = c["pv"] / c["pv_max"]
		c["pv_max"] = float(c["base"]["pv"])
		c["pv"] = c["pv_max"] * ratio


# =====================================================================
# Boucle de combat
# =====================================================================

func combattre() -> Dictionary:
	_log({"t": "debut"})
	while tour < tours_max:
		tour += 1
		_log({"t": "tour", "n": tour})
		for c in _ordre_du_tour():
			if not c["vivant"]:
				continue
			_agir(c)
			if _fini():
				return _resultat()
	_log({"t": "temps_ecoule"})
	return _resultat()


func _ordre_du_tour() -> Array:
	var liste: Array = []
	for c in unites:
		if c["vivant"]:
			var vitesse := _stat(c, "agi") * _rng.randf_range(0.9, 1.1)
			if tour == 1 and c["p"]["premier"]:
				vitesse += 100000.0
			liste.append([vitesse, c])
			# Les géants agissent plusieurs fois par tour
			for k in range(1, int(c["actions"])):
				liste.append([vitesse * _rng.randf_range(0.2, 0.8), c])
	liste.sort_custom(func(a, b): return a[0] > b[0])
	return liste.map(func(x): return x[1])


func _fini() -> bool:
	return _vivants(0).is_empty() or _vivants(1).is_empty()


func _resultat() -> Dictionary:
	var victoire := _vivants(1).is_empty() and not _vivants(0).is_empty()
	_log({"t": "fin", "victoire": victoire})
	var pv_final: Array = []
	for c in _equipe(0):
		pv_final.append(c["pv"] / c["pv_max"] if c["vivant"] else 0.0)
	var degats := 0.0
	var pv_total := 0.0
	for c in _equipe(1):
		pv_total += c["pv_max"]
		degats += c["pv_max"] - maxf(0.0, c["pv"])
	return {"victoire": victoire, "tours": tour, "journal": journal, "pv_final": pv_final,
		"degats_ennemis": degats, "pv_max_ennemis": pv_total}


# =====================================================================
# Tour d'une unité
# =====================================================================

func _agir(c: Dictionary) -> void:
	# Début de tour (poisons, durées...) une seule fois par tour, même pour un géant
	if int(c.get("dernier_tour", -1)) != tour:
		c["dernier_tour"] = tour
		_debut_de_tour(c)
	if not c["vivant"] or _fini():
		return
	var aff: Dictionary = c["afflictions"]
	if aff.has("etourdi"):
		aff.erase("etourdi")
		_log({"t": "passe", "a": c["idx"], "raison": "Étourdi"})
		return
	if aff.has("gel") and _rng.randf() < GEL_PERTE_TOUR:
		_log({"t": "passe", "a": c["idx"], "raison": "Gelé"})
		return

	var skill := _choisir_skill(c)
	if not skill.is_empty():
		_lancer_skill(c, skill)
	else:
		_attaque_normale(c)
		if c["vivant"] and _rng.randf() < c["p"]["double"] and not _fini():
			_log({"t": "info", "a": c["idx"], "texte": "Double attaque !"})
			_attaque_normale(c)


func _debut_de_tour(c: Dictionary) -> void:
	var aff: Dictionary = c["afflictions"]
	# Dégâts sur la durée
	for nom in [["poison", POISON], ["brulure", BRULURE], ["saignement", SAIGNEMENT]]:
		if aff.has(nom[0]):
			# Un géant ne perd qu'une infime part de ses PV (sinon le poison suffirait à le tuer)
			_perdre_pv(c, c["pv_max"] * nom[1] * (GEANT_DOT if c["geant"] else 1.0), nom[0])
			if not c["vivant"]:
				return
	# Régénération
	var regen: float = c["p"]["regen"]
	for r in c["regen_temp"]:
		regen += r["valeur"]
	if regen > 0.0:
		_soigner(c, c, c["pv_max"] * regen, false)
	# Durées
	for nom in aff.keys():
		if nom == "etourdi":
			continue
		aff[nom] -= 1
		if aff[nom] <= 0:
			aff.erase(nom)
	for b in c["buffs"]:
		b["duree"] -= 1
	c["buffs"] = c["buffs"].filter(func(b): return b["duree"] > 0)
	for r in c["regen_temp"]:
		r["duree"] -= 1
	c["regen_temp"] = c["regen_temp"].filter(func(r): return r["duree"] > 0)
	if c["provocation"] > 0:
		c["provocation"] -= 1


func _choisir_skill(c: Dictionary) -> Dictionary:
	if c["afflictions"].has("silence"):
		return {}
	for sk in c["actifs"]:
		if _rng.randf() < float(sk["chance"]) and _skill_utile(c, sk):
			return sk
	return {}


func _skill_utile(c: Dictionary, sk: Dictionary) -> bool:
	for e in sk["effets"]:
		if e["effet"] == "ressusciter" and _ko(c["camp"]).is_empty():
			# un skill de réanimation reste utile s'il fait autre chose
			if sk["effets"].size() == 1:
				return false
		if e["effet"] == "soin" and sk["effets"].size() == 1:
			var blesse := false
			for a in _vivants(c["camp"]):
				if a["pv"] < a["pv_max"] * 0.85:
					blesse = true
			if not blesse:
				return false
	return true


# =====================================================================
# Attaque normale
# =====================================================================

func _attaque_normale(c: Dictionary) -> void:
	var cible := _cible_attaque(c)
	if cible.is_empty():
		return
	_log({"t": "attaque", "a": c["idx"], "c": cible["idx"]})
	var preci: float = _stat(c, "preci") - (ESQUIVE_AVEUGLE if c["afflictions"].has("aveugle") else 0.0)
	if _rng.randf() * 100.0 >= preci:
		_log({"t": "rate", "a": c["idx"], "c": cible["idx"]})
		return
	var atk := _stat(c, "atk")
	var brut := atk * atk / (atk + _stat(cible, "def"))
	var dmg := _modifier_degats(c, cible, brut, true)
	var crit := _rng.randf() * 100.0 < _stat(c, "crit")
	if crit:
		dmg *= _stat(c, "degats_crit") / 100.0
	var inflige := _infliger(c, cible, dmg, crit, true)
	_apres_coup(c, cible, inflige, true)


func _cible_attaque(c: Dictionary) -> Dictionary:
	var ennemis := _vivants(1 - c["camp"])
	if ennemis.is_empty():
		return {}
	var provoc := ennemis.filter(func(x): return x["provocation"] > 0)
	if not provoc.is_empty():
		return provoc[_rng.randi_range(0, provoc.size() - 1)]
	if c["melee"]:
		var devant := ennemis.filter(func(x): return x["avant"])
		if not devant.is_empty():
			return devant[_rng.randi_range(0, devant.size() - 1)]
		return ennemis[_rng.randi_range(0, ennemis.size() - 1)]
	# Distance : n'importe qui, l'Avant est un peu plus exposé
	var total := 0.0
	for x in ennemis:
		total += 1.5 if x["avant"] else 1.0
	var r := _rng.randf() * total
	for x in ennemis:
		r -= 1.5 if x["avant"] else 1.0
		if r <= 0.0:
			return x
	return ennemis[-1]


# Modificateurs communs : position, élément, bonus passifs, variance
func _modifier_degats(att: Dictionary, cible: Dictionary, valeur: float, corps_a_corps: bool) -> float:
	var m := 1.0
	if corps_a_corps and att["melee"]:
		m *= (1.0 + BONUS_MELEE_AVANT) if att["avant"] else (1.0 - MALUS_MELEE_ARRIERE)
		m *= (1.0 + RECU_AVANT) if cible["avant"] else (1.0 - REDUIT_ARRIERE)
	if cible["avant"] and not cible["melee"]:
		m *= 1.0 + RECU_DISTANCE_AVANT
	if FORT_CONTRE.get(att["element"], "") == cible["element"]:
		m *= 1.0 + BONUS_ELEMENT
	elif FORT_CONTRE.get(cible["element"], "") == att["element"]:
		m *= 1.0 - MALUS_ELEMENT
	if not cible["avant"]:
		m *= 1.0 + att["p"]["bonus_arriere"]
	if cible["pv"] < cible["pv_max"] * 0.5:
		m *= 1.0 + att["p"]["execution"]
	return valeur * m * _rng.randf_range(0.92, 1.08)


# =====================================================================
# Skills
# =====================================================================

func _lancer_skill(c: Dictionary, sk: Dictionary) -> void:
	var cibles := _cibles_skill(c, sk["cible"])
	_log({"t": "skill", "a": c["idx"], "nom": sk["nom"], "cibles": cibles.map(func(x): return x["idx"])})
	var total_degats := 0.0
	for e in sk["effets"]:
		match e["effet"]:
			"degats":
				var coups := int(e.get("coups", 1))
				for k in coups:
					var liste := cibles
					if coups > 1:
						var v := _vivants(1 - c["camp"])
						if v.is_empty():
							break
						liste = [v[_rng.randi_range(0, v.size() - 1)]]
					for cible in liste:
						if cible["vivant"]:
							total_degats += _degats_skill(c, cible, e, sk["cible"] == "ennemi")
			"soin":
				for cible in cibles:
					if cible["vivant"]:
						_soigner(c, cible, _puissance(c) * e["mult"], true)
			"drain":
				if total_degats > 0.0:
					_soigner(c, c, total_degats * e["valeur"], false)
			"affliction":
				for cible in cibles:
					if cible["vivant"] and cible["camp"] != c["camp"]:
						_tenter_affliction(c, cible, e["nom"], e["chance"], int(e["duree"]))
			"buff":
				for cible in (cibles if e.get("cible", "") == "" else _cibles_skill(c, e["cible"])):
					if cible["vivant"]:
						cible["buffs"].append({"stat": e["stat"], "valeur": e["valeur"], "duree": int(e["duree"]) + 1})
						_log({"t": "buff", "c": cible["idx"], "stat": e["stat"], "valeur": e["valeur"]})
			"debuff":
				for cible in (cibles if e.get("cible", "") == "" else _cibles_skill(c, e["cible"])):
					if cible["vivant"] and cible["camp"] != c["camp"]:
						cible["buffs"].append({"stat": e["stat"], "valeur": -e["valeur"], "duree": int(e["duree"]) + 1})
						_log({"t": "buff", "c": cible["idx"], "stat": e["stat"], "valeur": -e["valeur"]})
			"bouclier":
				for cible in ([c] if e.get("cible", "") == "soi" else cibles):
					if cible["vivant"] and cible["camp"] == c["camp"]:
						cible["bouclier"] += cible["pv_max"] * e["valeur"]
						_log({"t": "bouclier", "c": cible["idx"], "v": int(cible["bouclier"])})
			"provocation":
				c["provocation"] = int(e["duree"]) + 1
				_log({"t": "info", "a": c["idx"], "texte": "Provocation"})
			"purification":
				for cible in cibles:
					if cible["camp"] == c["camp"] and not cible["afflictions"].is_empty():
						cible["afflictions"].clear()
						_log({"t": "purification", "c": cible["idx"]})
			"cout_pv":
				_perdre_pv(c, c["pv"] * e["valeur"], "cout")
			"ressusciter":
				var morts := _ko(c["camp"])
				if not morts.is_empty():
					var m: Dictionary = morts[_rng.randi_range(0, morts.size() - 1)]
					m["vivant"] = true
					m["pv"] = m["pv_max"] * e["valeur"]
					m["afflictions"].clear()
					_log({"t": "reanimation", "c": m["idx"], "pv": int(m["pv"])})
			"regen_temp":
				for cible in cibles:
					if cible["vivant"] and cible["camp"] == c["camp"]:
						cible["regen_temp"].append({"valeur": e["valeur"], "duree": int(e["duree"]) + 1})


func _cibles_skill(c: Dictionary, type: String) -> Array:
	var ennemis := _vivants(1 - c["camp"])
	var allies := _vivants(c["camp"])
	match type:
		"ennemi":
			var t := _cible_attaque_skill(c, ennemis)
			return [] if t.is_empty() else [t]
		"ennemis", "aleatoire":
			return ennemis
		"avant":
			var d := ennemis.filter(func(x): return x["avant"])
			return d if not d.is_empty() else ennemis
		"arriere":
			var a := ennemis.filter(func(x): return not x["avant"])
			return a if not a.is_empty() else ennemis
		"allies":
			return allies
		"allie_faible":
			var pire: Dictionary = {}
			for a in allies:
				if pire.is_empty() or a["pv"] / a["pv_max"] < pire["pv"] / pire["pv_max"]:
					pire = a
			return [] if pire.is_empty() else [pire]
		"soi":
			return [c]
	return []


func _cible_attaque_skill(c: Dictionary, ennemis: Array) -> Dictionary:
	if ennemis.is_empty():
		return {}
	var provoc := ennemis.filter(func(x): return x["provocation"] > 0)
	if not provoc.is_empty():
		return provoc[_rng.randi_range(0, provoc.size() - 1)]
	return ennemis[_rng.randi_range(0, ennemis.size() - 1)]


func _degats_skill(c: Dictionary, cible: Dictionary, e: Dictionary, cible_unique: bool) -> float:
	var res := _stat(cible, "res") * (1.0 - float(e.get("ignore_res", 0.0)))
	var brut := _puissance(c) * float(e["mult"]) * 100.0 / (100.0 + res * 2.0)
	var dmg := _modifier_degats(c, cible, brut, cible_unique)
	var crit := _rng.randf() * 100.0 < _stat(c, "crit")
	if crit:
		dmg *= _stat(c, "degats_crit") / 100.0
	var inflige := _infliger(c, cible, dmg, crit, false)
	_apres_coup(c, cible, inflige, false)
	# Set Despair : chance d'étourdir quand un skill inflige des dégâts
	if c["etourdir_skill"] > 0.0 and cible["vivant"] and cible["camp"] != c["camp"]:
		_tenter_affliction(c, cible, "etourdi", c["etourdir_skill"], 1)
	return inflige


func _puissance(c: Dictionary) -> float:
	return 0.6 * _stat(c, "atk") + _stat(c, "mag")


func _tenter_affliction(src: Dictionary, cible: Dictionary, nom: String, chance: float, duree: int) -> void:
	if nom in cible["p"]["immunites"] or (cible["immunite_debut"] and tour <= 1):
		_log({"t": "info", "a": cible["idx"], "texte": "Immunisé"})
		return
	var reussite := chance * (1.0 - clampf(_stat(cible, "res") / 150.0, 0.0, 0.6))
	if _rng.randf() < reussite:
		cible["afflictions"][nom] = maxi(int(cible["afflictions"].get(nom, 0)), duree + (0 if nom == "etourdi" else 1))
		_log({"t": "affliction", "c": cible["idx"], "nom": nom})


# =====================================================================
# Dégâts, soins, K.O.
# =====================================================================

## Applique des dégâts (bouclier d'abord). Renvoie les dégâts réellement infligés.
func _infliger(att: Dictionary, cible: Dictionary, dmg: float, crit: bool, physique: bool) -> float:
	dmg = maxf(1.0, dmg)
	var absorbe := minf(cible["bouclier"], dmg)
	cible["bouclier"] -= absorbe
	var reste := dmg - absorbe
	cible["pv"] -= reste
	_log({"t": "degats", "a": att["idx"], "c": cible["idx"], "v": int(dmg), "crit": crit,
		"pv": int(maxf(0.0, cible["pv"])), "bouclier": int(cible["bouclier"]), "physique": physique})
	_verifier_ko(cible, att)
	return dmg


func _apres_coup(att: Dictionary, cible: Dictionary, inflige: float, physique: bool) -> void:
	# Vol de vie
	if att["vivant"] and att["p"]["vol_vie"] > 0.0:
		_soigner(att, att, inflige * att["p"]["vol_vie"], false)
	# Épines et contre-attaque (seulement contre le corps à corps physique)
	if physique and att["melee"] and cible["vivant"]:
		if cible["p"]["epines"] > 0.0 and att["vivant"]:
			_perdre_pv(att, inflige * cible["p"]["epines"], "epines")
		if att["vivant"] and _rng.randf() < cible["p"]["contre_chance"]:
			_log({"t": "info", "a": cible["idx"], "texte": "Contre-attaque !"})
			var atk: float = _stat(cible, "atk") * cible["p"]["contre_mult"]
			var d: float = atk * atk / (atk + _stat(att, "def"))
			_infliger(cible, att, _modifier_degats(cible, att, d, false), false, true)
	# Phase 2 des boss
	if cible["vivant"] and cible["boss"] and not cible["phase_faite"] and not cible["phase2"].is_empty() \
			and cible["pv"] <= cible["pv_max"] * 0.5:
		cible["phase_faite"] = true
		for st in ["atk", "mag"]:
			cible["base"][st] *= 1.3
		cible["base"]["agi"] *= 1.2
		cible["afflictions"].clear()
		_log({"t": "phase", "c": cible["idx"], "nom": cible["phase2"]["nom"], "texte": cible["phase2"]["texte"]})


func _perdre_pv(c: Dictionary, montant: float, source: String) -> void:
	if not c["vivant"]:
		return
	c["pv"] -= montant
	_log({"t": "perte", "c": c["idx"], "v": int(montant), "source": source, "pv": int(maxf(0.0, c["pv"]))})
	_verifier_ko(c, {})


func _soigner(src: Dictionary, cible: Dictionary, montant: float, skill: bool) -> void:
	if not cible["vivant"]:
		return
	if skill:
		montant *= 1.0 + src["p"]["soin_bonus"]
	if cible["afflictions"].has("brulure"):
		montant *= 0.5
	var avant := float(cible["pv"])
	cible["pv"] = minf(cible["pv_max"], cible["pv"] + montant)
	var gain := int(cible["pv"] - avant)
	if gain > 0:
		_log({"t": "soin", "c": cible["idx"], "v": gain, "pv": int(cible["pv"])})


func _verifier_ko(c: Dictionary, tueur: Dictionary) -> void:
	if c["pv"] > 0.0:
		return
	if c["survie"] > 0:
		c["survie"] -= 1
		c["pv"] = 1.0
		_log({"t": "survie", "c": c["idx"]})
		return
	if c["renaissance"] > 0.0:
		c["pv"] = c["pv_max"] * c["renaissance"]
		c["renaissance"] = 0.0
		c["afflictions"].clear()
		_log({"t": "renaissance", "c": c["idx"], "pv": int(c["pv"])})
		return
	c["pv"] = 0.0
	c["vivant"] = false
	c["bouclier"] = 0.0
	c["provocation"] = 0
	_log({"t": "ko", "c": c["idx"]})
	if not tueur.is_empty() and tueur["vivant"] and tueur["p"]["accum_max"] > 0 and tueur["accum"] < tueur["p"]["accum_max"]:
		tueur["accum"] += 1
		_log({"t": "info", "a": tueur["idx"], "texte": "Puissance accrue"})


# =====================================================================
# Stats effectives
# =====================================================================

func _stat(c: Dictionary, st: String) -> float:
	var v: float = c["base"][st]
	var mult := 1.0
	for b in c["buffs"]:
		if b["stat"] == st:
			mult += b["valeur"]
	if st == "atk":
		mult += c["bonus_atk"]
	if c["p"]["rage_stat"] == st and c["pv"] < c["pv_max"] * 0.5:
		mult += c["p"]["rage_val"]
	if c["p"]["accum_stat"] == st:
		mult += c["accum"] * c["p"]["accum_val"]
	v *= maxf(0.2, mult)
	var aff: Dictionary = c["afflictions"]
	if st == "agi" and aff.has("gel"):
		v *= 0.5
	if st == "res" and aff.has("malediction"):
		v *= 0.5
	return v


# =====================================================================
# Outils
# =====================================================================

func _equipe(camp: int) -> Array:
	return unites.filter(func(x): return x["camp"] == camp)


func _vivants(camp: int) -> Array:
	return unites.filter(func(x): return x["camp"] == camp and x["vivant"])


func _ko(camp: int) -> Array:
	return unites.filter(func(x): return x["camp"] == camp and not x["vivant"])


func _log(ev: Dictionary) -> void:
	journal.append(ev)


## Infos de départ des combattants (pour l'écran de combat).
func descriptif() -> Array:
	var l: Array = []
	for c in unites:
		l.append({"idx": c["idx"], "camp": c["camp"], "place": c["place"], "id": c["id"], "nom": c["nom"],
			"niveau": c["niveau"], "pv": int(c["pv"]), "pv_max": int(c["pv_max"]), "element": c["element"],
			"avant": c["avant"], "boss": c["boss"], "elite": c["elite"], "vivant": c["vivant"], "geant": c["geant"]})
	return l
