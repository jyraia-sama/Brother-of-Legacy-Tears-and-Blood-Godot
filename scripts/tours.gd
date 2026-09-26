class_name Tours
extends RefCounted
## TOURS DE L'ENFER ET DU PARADIS : 100 étages chacune.
##
##  - 1 combat par étage, PV remis à fond à chaque étage.
##  - Tous les 5 étages : une Élite. Tous les 10 étages : un BOSS. Étage 100 : le SUPER BOSS.
##  - La difficulté monte à chaque étage.
##  - Chaque combat coûte de la stamina (voir COUT_STAMINA) ; en cas de défaite on peut réessayer.
##  - Butin spécial (Braises / Plumes, Poussière d'Écho, coffres, élixirs, tomes, Pierres d'Éveil).
##  - Les tours se réinitialisent chaque LUNDI à 00:00 (heure locale) : on repart de l'étage 1
##    et tout le butin peut être regagné. Le record absolu, lui, est conservé.

const ETAGES := 100
const COUT_STAMINA := {"combat": 2, "elite": 3, "boss": 5, "super": 8}

## Réglage global de la difficulté des tours (1.0 = normal).
const DIFFICULTE := 1.0
## Force des ennemis selon le type d'étage (réglé par simulation).
const RATIOS := {"combat": 0.95, "elite": 1.0, "boss": 1.0, "super": 1.0}
const POIDS := {"elite": 1.4, "boss": 2.4, "super": 3.2}
## Réglage fin par type d'étage et par tranche de 10 étages (réglé par simulation, 1.0 = neutre).
## "boss" : index 0 = étage 10, ... index 9 = étage 100 (super boss).
const CALIBRAGE := {
	"enfer": {"combat": [0.91, 0.91, 0.89, 1.04, 1.0, 0.71, 0.82, 0.54, 0.36, 0.39],
		"elite": [0.8, 1.15, 0.87, 1.5, 0.98, 0.74, 0.91, 0.82, 0.39, 0.52],
		"boss": [0.87, 0.71, 0.85, 0.76, 0.85, 0.69, 0.65, 0.6, 0.28, 0.23]},
	"paradis": {"combat": [1.37, 1.35, 1.09, 0.89, 0.93, 0.71, 0.71, 0.69, 0.56, 0.54],
		"elite": [1.35, 1.48, 1.39, 0.98, 1.33, 0.63, 0.91, 0.82, 0.56, 0.43],
		"boss": [1.09, 0.82, 0.67, 0.85, 0.71, 0.8, 0.74, 0.43, 0.69, 0.3]},
}
## Taux de victoire visés avec l'équipe de référence (sans Échos) : combat 85 %, élite 72 %,
## boss 50 %, super boss 35 %. Avec des Échos et des étoiles, c'est nettement plus facile.
static var calibrage_test := {}

const TOURS := {
	"enfer": {
		"nom": "Tour de l'Enfer", "sous_titre": "Descends les cent cercles de l'Abîme",
		"monnaie": "braise_infernale", "couleur": "ff4a2a", "sens": "descente",
		"paliers": [
			{"nom": "Les Portes de Soufre", "jusqua": 25,
				"monstres": ["diablotin_soufre", "ame_damnee", "molosse_enfers", "demon_mineur"]},
			{"nom": "Le Fleuve de Sang", "jusqua": 50,
				"monstres": ["passeur_styx", "bourreau_cornu", "sangsue_abyssale", "molosse_enfers", "demon_flamme"]},
			{"nom": "Les Forges de l'Abîme", "jusqua": 75,
				"monstres": ["forgeron_abime", "succube", "cerbere", "bourreau_cornu", "demon_flamme"]},
			{"nom": "Le Trône du Néant", "jusqua": 100,
				"monstres": ["chevalier_infernal", "archidemon", "tourmenteur_ames", "succube", "cerbere"]},
		],
		"boss": {10: "gardien_soufre", 20: "avarex", 30: "nocher_rouge", 40: "vorhka", 50: "grand_forgeron",
			60: "lilithra", 70: "cerberus", 80: "baalzeth", 90: "archidiable", 100: "abaddor"},
	},
	"paradis": {
		"nom": "Tour du Paradis", "sous_titre": "Gravis les cent cieux jusqu'à la Lumière",
		"monnaie": "plume_celeste", "couleur": "ffe08a", "sens": "montee",
		"paliers": [
			{"nom": "Les Jardins de Nuées", "jusqua": 25,
				"monstres": ["cherubin", "faucon_celeste", "nuee_vivante"]},
			{"nom": "La Citadelle d'Albâtre", "jusqua": 50,
				"monstres": ["gardien_albatre", "archer_cieux", "pretresse_aube", "nuee_vivante"]},
			{"nom": "Le Chœur des Séraphins", "jusqua": 75,
				"monstres": ["seraphin_ardent", "valkyrie_celeste", "dominion", "archer_cieux"]},
			{"nom": "Le Trône de Lumière", "jusqua": 100,
				"monstres": ["trone_vivant", "archange_justicier", "puissance_celeste", "valkyrie_celeste", "seraphin_ardent"]},
		],
		"boss": {10: "gardien_nuees", 20: "aethel", 30: "dame_albatre", 40: "oriel", 50: "choeur_incarne",
			60: "ophanim", 70: "valkaria", 80: "serapheon", 90: "azarel", 100: "aurelys"},
	},
}


# ---------------------------------------------------------------------
# Progression (avec remise à zéro hebdomadaire)
# ---------------------------------------------------------------------

static func etat(tour: String) -> Dictionary:
	Sauvegarde.charger()
	var e: Dictionary = Sauvegarde.donnees["tours"][tour]
	if int(e["semaine"]) != Calendrier.semaine():
		e["semaine"] = Calendrier.semaine()
		e["etage"] = 0
		Sauvegarde.sauvegarder()
	return e


## Dernier étage vaincu cette semaine (0 = aucun).
static func etage_atteint(tour: String) -> int:
	return int(etat(tour)["etage"])


static func record(tour: String) -> int:
	return int(etat(tour)["record"])


static func prochain_etage(tour: String) -> int:
	return mini(ETAGES, etage_atteint(tour) + 1)


static func tour_terminee(tour: String) -> bool:
	return etage_atteint(tour) >= ETAGES


static func type_etage(n: int) -> String:
	if n >= ETAGES:
		return "super"
	if n % 10 == 0:
		return "boss"
	if n % 5 == 0:
		return "elite"
	return "combat"


static func palier(tour: String, n: int) -> Dictionary:
	for p in TOURS[tour]["paliers"]:
		if n <= int(p["jusqua"]):
			return p
	return TOURS[tour]["paliers"][-1]


# ---------------------------------------------------------------------
# Difficulté
# ---------------------------------------------------------------------

## Étage -> point équivalent de l'aventure (Acte, Chapitre).
## L'étage 80 correspond à la fin de l'Acte XII ; au-delà, tout devient plus fort.
static func equivalent(n: int) -> Vector2i:
	var p := clampi(int(round((n - 1) * 71.0 / 79.0)), 0, 71)
	return Vector2i(int(p / 6.0) + 1, p % 6 + 1)


static func niveau_ennemis(n: int) -> int:
	var eq := equivalent(n)
	var bonus: int = {"combat": 0, "elite": 1, "boss": 2, "super": 3}[type_etage(n)]
	return clampi(Rencontres.niveau_attendu(eq.x, eq.y) + bonus, 1, UnitesData.NIVEAU_MAX)


## Au-delà de l'étage 80 : +1,5 % par étage (x1,30 à l'étage 100).
static func _tranche(n: int) -> int:
	return clampi(int((n - 1) / 10.0), 0, 9)


static func surplus(n: int) -> float:
	return 1.0 + maxf(0.0, n - 80) * 0.015


static func generer(tour: String, n: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("BoL-tour-%s-%d-%d" % [tour, n, Calendrier.semaine()])
	var t := type_etage(n)
	var eq := equivalent(n)
	var niveau := niveau_ennemis(n)
	var pool: Array = palier(tour, n)["monstres"]
	var nb := 2 if n < 6 else (3 if n < 40 else (4 if n < 75 else 5))
	var membres: Array = []     # [id, poids, nom, boss, elite]
	match t:
		"combat":
			for i in nb:
				membres.append([pool[rng.randi_range(0, pool.size() - 1)], 1.0, "", false, false])
		"elite":
			var chef: String = pool[rng.randi_range(0, pool.size() - 1)]
			membres.append([chef, POIDS["elite"], "Élite : " + UnitesData.get_unite(chef)["nom"], false, true])
			for i in maxi(2, nb - 1):
				membres.append([pool[rng.randi_range(0, pool.size() - 1)], 1.0, "", false, false])
		"boss":
			membres.append([TOURS[tour]["boss"][n], POIDS["boss"], "", true, false])
			for i in (2 if n < 50 else 3):
				membres.append([pool[rng.randi_range(0, pool.size() - 1)], 1.0, "", false, false])
		"super":
			membres.append([TOURS[tour]["boss"][100], POIDS["super"], "", true, false])
			for etage in [80, 90]:
				var b: String = TOURS[tour]["boss"][etage]
				membres.append([b, 1.2, "Garde : " + UnitesData.get_unite(b)["nom"], false, true])
			membres.append([pool[rng.randi_range(0, pool.size() - 1)], 1.0, "", false, false])

	var famille := "boss" if t == "super" else t
	var calib: float = calibrage_test.get("%s-%s-%d" % [tour, famille, _tranche(n)], CALIBRAGE[tour][famille][_tranche(n)])
	var cible: float = Rencontres.puissance_reference(eq.x, eq.y) * RATIOS[t] * calib * DIFFICULTE \
		* Rencontres.pente(eq.x, eq.y) * Rencontres.ECHOS_ATTENDUS[eq.x - 1] * surplus(n)
	var brut := 0.0
	for m in membres:
		brut += UnitesData.puissance(m[0], niveau) * m[1]
	var facteur: float = cible / maxf(1.0, brut)
	membres.sort_custom(func(a, b): return Rencontres._ordre_place(a[0]) < Rencontres._ordre_place(b[0]))
	var equipe: Array = []
	for m in membres:
		var e := {"id": m[0], "niveau": niveau, "mult": facteur * m[1], "boss": m[3], "elite": m[4]}
		if m[2] != "":
			e["nom"] = m[2]
		equipe.append(e)
	return equipe


# ---------------------------------------------------------------------
# Butin (première victoire de la semaine sur cet étage)
# ---------------------------------------------------------------------

static func butin(tour: String, n: int) -> Dictionary:
	var t := type_etage(n)
	var monnaie: String = TOURS[tour]["monnaie"]
	var b := {}
	match t:
		"combat":
			b["or"] = 40 + 8 * n
			b[monnaie] = 1 + int(n / 40.0)
			b["poussiere_echo"] = 2 + int(n / 20.0)
			if n % 3 == 0:
				b["coffre_bronze"] = 1
		"elite":
			b["or"] = 2 * (40 + 8 * n)
			b[monnaie] = 3 + int(n / 25.0)
			b["poussiere_echo"] = 5 + int(n / 10.0)
			b["elixir_petit" if n % 10 == 5 and int(n / 10.0) % 2 == 0 else "tome_petit"] = 1
		"boss":
			b["or"] = 4 * (40 + 8 * n)
			b[monnaie] = 10 + int(n / 5.0)
			b["poussiere_echo"] = 15 + int(n / 4.0)
			b["coffre_argent" if n <= 40 else "coffre_or"] = 1
			b["eclat_superieur"] = 1
			if n in [20, 40, 60, 80]:
				b["tome_grand"] = 1
			if n in [30, 70]:
				b["elixir_grand"] = 1
			if n in [50, 90]:
				b["pierre_eveil"] = 1
		"super":
			b["or"] = 15000
			b[monnaie] = 60
			b["poussiere_echo"] = 60
			b["coffre_royal"] = 1
			b["pierre_eveil"] = 2
			b["eclat_superieur"] = 3
			b["tome_ancien"] = 1
	return b


## Enregistre la victoire à l'étage n. Renvoie les lignes de récompense.
static func valider_victoire(tour: String, n: int) -> Array:
	var e := etat(tour)
	var lignes: Array = []
	if n != int(e["etage"]) + 1:
		return lignes
	e["etage"] = n
	var nouveau_record := n > int(e["record"])
	if nouveau_record:
		e["record"] = n
	Sauvegarde.sauvegarder()
	lignes.append_array(Reliquaire.donner(butin(tour, n)))
	if nouveau_record:
		lignes.append("Nouveau record : étage %d !" % n)
	return lignes


## XP gagnée par un héros à cet étage (comme dans l'aventure au point équivalent).
static func xp(n: int, niveau_heros: int) -> int:
	var eq := equivalent(n)
	var t: String = {"combat": "combat", "elite": "elite", "boss": "boss_chapitre", "super": "boss_acte"}[type_etage(n)]
	return Rencontres.xp_victoire(t, niveau_heros, eq.x, eq.y)
