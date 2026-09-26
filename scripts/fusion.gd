class_name Fusion
extends RefCounted
## AUTEL DE FUSION : règles (sans interface).
##
## 1) ÉVEIL (étoiles) : on sacrifie des DOUBLONS (même unité) pour faire monter
##    les étoiles du héros principal, de ★1 à ★6 (★6 = « Éveillé »).
##    Chaque étoile augmente PV / ATK / DEF / AGI / MAG.
## 2) ABSORPTION (XP) : on sacrifie n'importe quelles unités pour donner de l'XP
##    au héros principal.
##
## Règles communes :
##  - le héros principal peut être dans l'équipe ;
##  - un sacrifice ne peut JAMAIS être dans l'équipe, ni être le héros de départ,
##    ni être verrouillé ;
##  - les Échos Sanguins portés par un sacrifice retournent dans l'inventaire.

const ETOILES_MAX := 6
## Pierre d'Éveil (Reliquaire) : remplace un doublon
const PIERRE := "pierre_eveil"
const MAX_SACRIFICES := 10

## Bonus de stats par étoile au-dessus de ★1 (0.06 = +6 %), plus un bonus d'Éveil à ★6.
const BONUS_PAR_ETOILE := 0.06
const BONUS_EVEIL := 0.10

## Doublons nécessaires pour passer de ★n à ★n+1 (index = étoiles actuelles).
const DOUBLONS_REQUIS := {1: 1, 2: 1, 3: 2, 4: 2, 5: 3}
## Niveau minimum du héros principal pour passer de ★n à ★n+1.
const NIVEAU_REQUIS := {1: 1, 2: 10, 3: 15, 4: 20, 5: 30}
## Coût en or de l'Éveil : prix de base selon la rareté × étoiles actuelles.
const OR_EVEIL := {"N": 300, "R": 800, "SR": 2000, "SSR": 5000, "UR": 10000, "LEG": 12000}

## XP donnée par un sacrifice (niveau 1), selon sa rareté.
const XP_SACRIFICE := {"N": 100, "R": 250, "SR": 600, "SSR": 1500, "UR": 3500, "LEG": 3500}
## Bonus d'XP si le sacrifice est la même unité que le principal.
const BONUS_MEME_UNITE := 1.5
## Or dépensé par point d'XP absorbé.
const OR_PAR_XP := 0.5


# ---------------------------------------------------------------------
# Étoiles
# ---------------------------------------------------------------------

static func etoiles(h: Dictionary) -> int:
	return clampi(int(h.get("etoiles", 1)), 1, ETOILES_MAX)


static func est_eveille(h: Dictionary) -> bool:
	return etoiles(h) >= ETOILES_MAX


static func multiplicateur(nb_etoiles: int) -> float:
	var e := clampi(nb_etoiles, 1, ETOILES_MAX)
	return 1.0 + BONUS_PAR_ETOILE * (e - 1) + (BONUS_EVEIL if e >= ETOILES_MAX else 0.0)


## Applique le bonus d'étoiles à des stats (de UnitesData.stats).
static func appliquer_etoiles(stats: Dictionary, nb_etoiles: int) -> Dictionary:
	var s := stats.duplicate()
	var m := multiplicateur(nb_etoiles)
	for st in ["pv", "atk", "def", "agi", "mag"]:
		if s.has(st):
			s[st] = int(round(float(s[st]) * m))
	return s


## Texte ★★★☆☆☆
static func texte_etoiles(nb_etoiles: int, vides := true) -> String:
	var e := clampi(nb_etoiles, 1, ETOILES_MAX)
	return "★".repeat(e) + ("☆".repeat(ETOILES_MAX - e) if vides else "")


static func cle_rarete(id_unite: String) -> String:
	var u := UnitesData.get_unite(id_unite)
	return "LEG" if u.get("legende", false) else str(u["rarete"])


static func doublons_requis(h: Dictionary) -> int:
	return int(DOUBLONS_REQUIS.get(etoiles(h), 0))


static func niveau_requis(h: Dictionary) -> int:
	return int(NIVEAU_REQUIS.get(etoiles(h), 0))


static func cout_eveil(h: Dictionary) -> int:
	return int(OR_EVEIL[cle_rarete(h["id"])]) * etoiles(h)


# ---------------------------------------------------------------------
# Sacrifices
# ---------------------------------------------------------------------

## Raison pour laquelle cette unité ne peut pas être sacrifiée ("" = possible).
static func raison_non_sacrifiable(uid: int, uid_principal: int) -> String:
	var h := Sauvegarde.get_heros(uid)
	if h.is_empty():
		return "Introuvable."
	if uid == uid_principal:
		return "C'est le héros principal."
	if h.get("depart", false):
		return "Ton héros de départ ne peut pas être sacrifié."
	if h.get("verrou", false):
		return "Cette unité est verrouillée."
	if Sauvegarde.place_de(uid) >= 0:
		return "Une unité de l'équipe ne peut pas être sacrifiée."
	return ""


## Ce qui empêche l'Éveil ("" = possible). `sacrifices` = uids choisis,
## `pierres` = Pierres d'Éveil utilisées (chacune remplace un doublon).
static func raison_eveil_impossible(uid_principal: int, sacrifices: Array, pierres := 0) -> String:
	var h := Sauvegarde.get_heros(uid_principal)
	if h.is_empty():
		return "Choisis d'abord un héros principal."
	if est_eveille(h):
		return "Ce héros est déjà Éveillé (★6) : étoiles au maximum."
	if int(h["niveau"]) < niveau_requis(h):
		return "Niveau %d requis pour passer ★%d (actuellement Nv %d)." % [niveau_requis(h), etoiles(h) + 1, int(h["niveau"])]
	var besoin := doublons_requis(h)
	if pierres > Sauvegarde.get_objet(PIERRE):
		return "Pas assez de Pierres d'Éveil."
	if sacrifices.size() + pierres < besoin:
		return "Il faut %d doublon(s) de %s ou Pierre(s) d'Éveil (sélectionnés : %d)." % [besoin, UnitesData.get_unite(h["id"])["nom"], sacrifices.size() + pierres]
	for uid in sacrifices:
		var s := Sauvegarde.get_heros(int(uid))
		if s.is_empty() or s["id"] != h["id"]:
			return "Seuls des doublons de la même unité peuvent servir à l'Éveil."
		var r := raison_non_sacrifiable(int(uid), uid_principal)
		if r != "":
			return r
	if Sauvegarde.get_or() < cout_eveil(h):
		return "Pas assez d'or (%d requis)." % cout_eveil(h)
	return ""


## Fait monter le héros d'une étoile. Renvoie true si réussi.
static func eveiller(uid_principal: int, sacrifices: Array, pierres := 0) -> bool:
	var besoin := doublons_requis(Sauvegarde.get_heros(uid_principal))
	pierres = mini(pierres, besoin)
	var sac := sacrifices.slice(0, besoin - pierres)
	if raison_eveil_impossible(uid_principal, sac, pierres) != "":
		return false
	var h := Sauvegarde.get_heros(uid_principal)
	if not Sauvegarde.depenser_or(cout_eveil(h)):
		return false
	if pierres > 0:
		Sauvegarde.retirer_objet(PIERRE, pierres)
	Sauvegarde.supprimer_heros(sac)
	h = Sauvegarde.get_heros(uid_principal)
	h["etoiles"] = etoiles(h) + 1
	Sauvegarde.ajouter_stat("eveils")
	Sauvegarde.sauvegarder()
	return true


## XP que donne un sacrifice au héros principal.
static func xp_sacrifice(uid: int, uid_principal: int) -> int:
	var s := Sauvegarde.get_heros(uid)
	var p := Sauvegarde.get_heros(uid_principal)
	if s.is_empty():
		return 0
	var xp := float(XP_SACRIFICE[cle_rarete(s["id"])])
	xp *= 1.0 + (int(s["niveau"]) - 1) * 0.10
	xp *= 1.0 + (etoiles(s) - 1) * 0.25
	if not p.is_empty() and s["id"] == p["id"]:
		xp *= BONUS_MEME_UNITE
	return int(round(xp))


static func xp_totale(uid_principal: int, sacrifices: Array) -> int:
	var t := 0
	for uid in sacrifices:
		t += xp_sacrifice(int(uid), uid_principal)
	return t


static func cout_absorption(uid_principal: int, sacrifices: Array) -> int:
	return int(ceil(xp_totale(uid_principal, sacrifices) * OR_PAR_XP))


## Simule l'ajout d'XP : renvoie {"niveau", "xp", "perdue"} sans rien modifier.
static func apercu_xp(uid_principal: int, xp_gagnee: int) -> Dictionary:
	var h := Sauvegarde.get_heros(uid_principal)
	var niv := int(h.get("niveau", 1))
	var xp := int(h.get("xp", 0)) + xp_gagnee
	while niv < UnitesData.NIVEAU_MAX and xp >= Sauvegarde.xp_heros_pour_niveau(niv):
		xp -= Sauvegarde.xp_heros_pour_niveau(niv)
		niv += 1
	var perdue := 0
	if niv >= UnitesData.NIVEAU_MAX:
		perdue = xp
		xp = 0
	return {"niveau": niv, "xp": xp, "perdue": perdue}


static func raison_absorption_impossible(uid_principal: int, sacrifices: Array) -> String:
	var h := Sauvegarde.get_heros(uid_principal)
	if h.is_empty():
		return "Choisis d'abord un héros principal."
	if int(h["niveau"]) >= UnitesData.NIVEAU_MAX:
		return "Ce héros est déjà au niveau maximum (%d)." % UnitesData.NIVEAU_MAX
	if sacrifices.is_empty():
		return "Choisis au moins une unité à sacrifier."
	if sacrifices.size() > MAX_SACRIFICES:
		return "%d sacrifices maximum à la fois." % MAX_SACRIFICES
	for uid in sacrifices:
		var r := raison_non_sacrifiable(int(uid), uid_principal)
		if r != "":
			return r
	if Sauvegarde.get_or() < cout_absorption(uid_principal, sacrifices):
		return "Pas assez d'or (%d requis)." % cout_absorption(uid_principal, sacrifices)
	return ""


## Absorbe les sacrifices. Renvoie le nombre de niveaux gagnés (-1 si impossible).
static func absorber(uid_principal: int, sacrifices: Array) -> int:
	if raison_absorption_impossible(uid_principal, sacrifices) != "":
		return -1
	var xp := xp_totale(uid_principal, sacrifices)
	if not Sauvegarde.depenser_or(cout_absorption(uid_principal, sacrifices)):
		return -1
	Sauvegarde.supprimer_heros(sacrifices)
	Sauvegarde.ajouter_stat("absorptions")
	return Sauvegarde.ajouter_xp_heros(uid_principal, xp)
