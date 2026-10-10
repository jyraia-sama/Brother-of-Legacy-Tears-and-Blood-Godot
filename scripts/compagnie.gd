class_name Compagnie
extends RefCounted
## EXPÉDITIONS DE LA COMPAGNIE : des missions en temps réel pour les unités hors de l'équipe.
##
##  - Chaque jour, un tableau de 6 missions (de 1 h à 12 h), le même pour tout le monde.
##  - 3 escouades peuvent partir en même temps (1 à 5 unités chacune selon la mission).
##  - Chaque mission a des CONDITIONS (rôle, élément, niveau, rareté) à remplir pour partir,
##    et un OBJECTIF BONUS facultatif qui augmente le butin de 50 %.
##  - Une unité en mission est OCCUPÉE : elle quitte l'équipe et ne peut ni combattre,
##    ni être vendue, sacrifiée ou évoluée avant son retour.
##  - Le temps passe même jeu fermé. Au retour, on récupère le butin.
##  - Une mission non lancée disparaît au changement de jour ; une mission en cours continue.

const SCENE := "res://scenes/compagnie.tscn"
const ESCOUADES_MAX := 3
const MISSIONS_PAR_JOUR := 6

## Durées proposées chaque jour (heures), de la plus courte à la plus longue.
const DUREES := [1, 2, 4, 6, 8, 12]
## Taille d'escouade selon la durée
const TAILLES := {1: [1, 2], 2: [2, 2], 4: [2, 3], 6: [3, 3], 8: [3, 4], 12: [4, 5]}

const LIEUX := [
	["Escorte vers Cendrebourg", "Protéger un convoi de réfugiés sur la route des cendres."],
	["Les Puits Asséchés", "Retrouver l'eau des villages avant la prochaine lune."],
	["La Tour du Guet", "Tenir la tour pendant que la garnison se repose."],
	["Chasse au Wyvernier", "Traquer un braconnier de wyvernes dans les falaises."],
	["Le Monastère Muet", "Découvrir pourquoi les moines ont cessé de parler."],
	["Reliques du Marais", "Fouiller une chapelle engloutie par la tourbe."],
	["Le Marché Noir", "Infiltrer un marché de reliques volées."],
	["Les Mines Hurlantes", "Faire taire ce qui gronde au fond des galeries."],
	["Pèlerinage d'Aube", "Accompagner des pèlerins jusqu'au sanctuaire."],
	["La Forêt des Pendus", "Rapporter les noms gravés sur les arbres maudits."],
	["Le Gué des Morts", "Aider le passeur à chasser les noyés du fleuve."],
	["Ruines de Valmort", "Cartographier une citadelle tombée sans survivants."],
	["La Foire aux Monstres", "Libérer les créatures d'un dompteur cruel."],
	["Les Archives Brûlées", "Sauver ce qui reste d'une bibliothèque en flammes."],
	["Le Col des Bannières", "Récupérer les étendards d'une armée disparue."],
	["Le Jardin de Verre", "Cueillir les fleurs de cristal d'une serre enchantée."],
	["Les Catacombes Royales", "Replacer les couronnes volées dans leurs tombeaux."],
	["La Fonderie Abandonnée", "Rallumer la forge des nains pour le village."],
]
const ROLES_COND := ["guerrier", "tank", "assassin", "tireur", "mage", "soutien"]
const ELEMENTS_COND := ["feu", "nature", "eau", "tenebres", "sacre"]
const RARETES := ["N", "R", "SR", "SSR", "UR"]


# ---------------------------------------------------------------------
# État dans la sauvegarde
# ---------------------------------------------------------------------

static func _etat() -> Dictionary:
	Sauvegarde.charger()
	if not Sauvegarde.donnees.has("compagnie"):
		Sauvegarde.donnees["compagnie"] = {"jour": -1, "lancees": [], "en_cours": []}
	var c: Dictionary = Sauvegarde.donnees["compagnie"]
	if int(c["jour"]) != Calendrier.jour_absolu():
		c["jour"] = Calendrier.jour_absolu()
		c["lancees"] = []           # index des missions du jour déjà lancées
		Sauvegarde.sauvegarder()
	return c


static func maintenant() -> int:
	return int(Time.get_unix_time_from_system())


## Missions en cours : [{mission, uids, debut, fin}]
static func en_cours() -> Array:
	return _etat()["en_cours"]


## L'unité est-elle partie en mission ?
static func unite_en_mission(uid: int) -> bool:
	Sauvegarde.charger()
	if not Sauvegarde.donnees.has("compagnie"):
		return false
	for m in Sauvegarde.donnees["compagnie"]["en_cours"]:
		if uid in m["uids"].map(func(x): return int(x)):
			return true
	return false


static func escouades_libres() -> int:
	return ESCOUADES_MAX - en_cours().size()


# ---------------------------------------------------------------------
# Tableau du jour
# ---------------------------------------------------------------------

## Les 6 missions du jour (identiques pour tous les joueurs).
static func missions_du_jour() -> Array:
	var jour := Calendrier.jour_absolu()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("BoL-compagnie-%d" % jour)
	var lieux := range(LIEUX.size())
	for i in range(lieux.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = lieux[i]
		lieux[i] = lieux[j]
		lieux[j] = t
	var epique := rng.randi_range(2, 5)      # une mission épique par jour (parmi les longues)
	var l: Array = []
	for i in MISSIONS_PAR_JOUR:
		var heures: int = DUREES[i]
		var t: Array = TAILLES[heures]
		var m := {
			"index": i, "nom": LIEUX[lieux[i]][0], "texte": LIEUX[lieux[i]][1], "heures": heures,
			"taille": rng.randi_range(int(t[0]), int(t[1])), "epique": i == epique,
			"conditions": [], "bonus": {},
		}
		m["conditions"] = _tirer_conditions(rng, m)
		m["bonus"] = _tirer_bonus(rng, m["conditions"])
		l.append(m)
	return l


## Niveau demandé : suit le niveau du compte (plus facile au début).
static func niveau_demande(heures: int) -> int:
	var base := 3 + Sauvegarde.get_niveau_compte() - (6 if heures <= 2 else 3 if heures <= 6 else 0)
	return clampi(base, 1, UnitesData.NIVEAU_MAX)


static func _tirer_conditions(rng: RandomNumberGenerator, m: Dictionary) -> Array:
	var c: Array = []
	var heures: int = m["heures"]
	c.append({"type": "niveau", "valeur": niveau_demande(heures)})
	var types := ["role", "element"]
	if heures >= 4:
		types.append("rarete")
	var nb := 1 if heures <= 2 else 2
	for k in nb:
		var t: String = types.pop_at(rng.randi_range(0, types.size() - 1))
		match t:
			"role":
				c.append({"type": "role", "valeur": ROLES_COND[rng.randi_range(0, ROLES_COND.size() - 1)], "nombre": 1})
			"element":
				var n := 1 if int(m["taille"]) <= 2 else rng.randi_range(1, 2)
				c.append({"type": "element", "valeur": ELEMENTS_COND[rng.randi_range(0, ELEMENTS_COND.size() - 1)], "nombre": n})
			"rarete":
				c.append({"type": "rarete", "valeur": "SR" if heures < 8 else "SSR", "nombre": 1})
	return c


static func _tirer_bonus(rng: RandomNumberGenerator, conditions: Array) -> Dictionary:
	for essai in 10:
		var b: Dictionary
		if rng.randf() < 0.5:
			b = {"type": "role", "valeur": ROLES_COND[rng.randi_range(0, ROLES_COND.size() - 1)], "nombre": 1}
		else:
			b = {"type": "element", "valeur": ELEMENTS_COND[rng.randi_range(0, ELEMENTS_COND.size() - 1)], "nombre": 1}
		var doublon := false
		for c in conditions:
			if c["type"] == b["type"] and c["valeur"] == b["valeur"]:
				doublon = true
		if not doublon:
			return b
	return {}


static func texte_condition(c: Dictionary) -> String:
	match str(c["type"]):
		"niveau":
			return UiCommun.t("Toutes les unités niveau %d ou plus") % int(c["valeur"])
		"role":
			return UiCommun.t("%d %s ou plus") % [int(c["nombre"]), UnitesData.ROLES[c["valeur"]]]
		"element":
			return UiCommun.t("%d unité%s %s ou plus") % [int(c["nombre"]), "s" if int(c["nombre"]) > 1 else "",
				"d'" + UnitesData.ELEMENTS[c["valeur"]] if c["valeur"] == "eau" else "de " + UnitesData.ELEMENTS[c["valeur"]]]
		"rarete":
			return UiCommun.t("1 unité %s ou plus rare") % str(c["valeur"])
	return ""


static func condition_remplie(c: Dictionary, uids: Array) -> bool:
	var compte := 0
	for uid in uids:
		var h := Sauvegarde.get_heros(int(uid))
		if h.is_empty():
			continue
		var u := UnitesData.get_unite(h["id"])
		match str(c["type"]):
			"niveau":
				if int(h["niveau"]) < int(c["valeur"]) and not UnitesData.est_evolue(h["id"]):
					return false
			"role":
				if u["role"] == c["valeur"]:
					compte += 1
			"element":
				if u["element"] == c["valeur"]:
					compte += 1
			"rarete":
				if u.get("legende", false) or RARETES.find(u["rarete"]) >= RARETES.find(str(c["valeur"])):
					compte += 1
	if str(c["type"]) == "niveau":
		return not uids.is_empty()
	return compte >= int(c.get("nombre", 1))


# ---------------------------------------------------------------------
# Butin
# ---------------------------------------------------------------------

## Butin de base d'une mission (sans le bonus).
static func butin(m: Dictionary) -> Dictionary:
	var h: int = m["heures"]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("BoL-compagnie-butin-%d-%d" % [Calendrier.jour_absolu(), int(m["index"])])
	var el: String = Evolution.ESSENCES.keys()[rng.randi_range(0, Evolution.ESSENCES.size() - 1)]
	var b := {"or": 300 * h}
	match h:
		1:
			b["poussiere_echo"] = 5
		2:
			b["poussiere_echo"] = 8
			b[Evolution.ressource(el, "goutte")] = 3
		4:
			b["tome_petit"] = 1
			b[Evolution.ressource(el, "goutte")] = 6
		6:
			b["elixir_petit"] = 1
			b[Evolution.ressource(el, "larme")] = 2
			b["poussiere_echo"] = 12
		8:
			b["coffre_argent"] = 1
			b[Evolution.ressource(el, "larme")] = 3
		12:
			b["tome_grand"] = 1
			b[Evolution.ressource(el, "coeur")] = 1
			b["coffre_or"] = 1
	if m.get("epique", false):
		b["eclat_superieur"] = 1
		b["sceau_marche"] = 20
	return b


## Butin final (bonus rempli : +50 %, arrondi au-dessus).
static func butin_final(m: Dictionary, bonus_ok: bool) -> Dictionary:
	var b := butin(m)
	if not bonus_ok:
		return b
	var r := {}
	for o in b:
		r[o] = int(ceil(int(b[o]) * 1.5))
	return r


# ---------------------------------------------------------------------
# Départ, retour, rappel
# ---------------------------------------------------------------------

## Ce qui empêche le départ ("" = possible).
static func raison_depart(m: Dictionary, uids: Array) -> String:
	if int(m["index"]) in _etat()["lancees"].map(func(x): return int(x)):
		return "Cette mission a déjà été lancée aujourd'hui."
	if escouades_libres() <= 0:
		return UiCommun.t("Les %d escouades sont déjà en mission.") % ESCOUADES_MAX
	if uids.size() != int(m["taille"]):
		return UiCommun.t("Il faut exactement %d unité%s.") % [int(m["taille"]), "s" if int(m["taille"]) > 1 else ""]
	for uid in uids:
		if unite_en_mission(int(uid)):
			return "Une des unités est déjà en mission."
	for c in m["conditions"]:
		if not condition_remplie(c, uids):
			return "Condition non remplie : " + texte_condition(c)
	return ""


static func partir(m: Dictionary, uids: Array) -> String:
	var raison := raison_depart(m, uids)
	if raison != "":
		return raison
	var e := _etat()
	# Les unités quittent l'équipe et l'armée du Boss de Monde
	for uid in uids:
		var s := Sauvegarde.get_slots()
		var i := s.find(int(uid))
		if i >= 0:
			s[i] = -1
			Sauvegarde.donnees["equipe"] = s
	var debut := maintenant()
	var bonus_ok: bool = not m["bonus"].is_empty() and condition_remplie(m["bonus"], uids)
	e["en_cours"].append({"mission": m.duplicate(true), "uids": uids.duplicate(), "debut": debut,
		"fin": debut + int(m["heures"]) * 3600, "bonus": bonus_ok, "butin": butin_final(m, bonus_ok)})
	e["lancees"].append(int(m["index"]))
	Sauvegarde.ajouter_stat("missions_compagnie")
	Sauvegarde.sauvegarder()
	return ""


static func secondes_restantes(mission_en_cours: Dictionary) -> int:
	return maxi(0, int(mission_en_cours["fin"]) - maintenant())


static func terminee(mission_en_cours: Dictionary) -> bool:
	return secondes_restantes(mission_en_cours) <= 0 or Sauvegarde.admin("compagnie_instantanee")


## Récupère le butin d'une mission terminée. Renvoie les lignes de récompense.
static func recuperer(index_en_cours: int) -> Array:
	var e := _etat()
	if index_en_cours < 0 or index_en_cours >= e["en_cours"].size():
		return []
	var m: Dictionary = e["en_cours"][index_en_cours]
	if not terminee(m):
		return []
	e["en_cours"].remove_at(index_en_cours)
	var lignes := Reliquaire.donner(m["butin"])
	Sauvegarde.sauvegarder()
	return lignes


## Rappelle une escouade avant la fin : les unités reviennent, sans butin.
static func rappeler(index_en_cours: int) -> void:
	var e := _etat()
	if index_en_cours >= 0 and index_en_cours < e["en_cours"].size():
		e["en_cours"].remove_at(index_en_cours)
		Sauvegarde.sauvegarder()


## Nombre de missions terminées qui attendent d'être récupérées (pastille de notification).
static func nombre_a_recuperer() -> int:
	var n := 0
	for m in en_cours():
		if terminee(m):
			n += 1
	return n
