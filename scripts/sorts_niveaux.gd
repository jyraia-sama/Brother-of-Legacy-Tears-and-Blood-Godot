class_name SortsNiveaux
extends RefCounted
## NIVEAUX DE SORTS (v0.65) : chaque sort d'un héros monte du niveau 1 au niveau 10.
##
##  - Par niveau : +4 % de la puissance du sort (dégâts, soins, boucliers, bonus, chances
##    d'altération...). Niveau 10 = +36 % (ex. un sort à 200 % passe à 272 %).
##  - Recharge (sorts actifs) : -1 tour selon la recharge de base du sort :
##      2 tours -> -1 au niveau 10 ; 3 tours -> -1 au niveau 7 ; 4 tours et plus -> -1 au niveau 5 et au niveau 10.
##    En combat automatique, la chance de lancer le sort augmente d'autant.
##  - Niveau maximum selon les étoiles (Éveil) : 3 + étoiles (★1 -> 4 ... ★5 -> 8), 10 à ★6 Éveillé.
##  - Coût : Pages de Grimoire (+ Grimoires Interdits à partir du niveau 7) et de l'or ;
##    on les gagne dans la Bibliothèque Interdite (Donjons).
##  - Arène et Guerre des Bannières : les sorts comptent au plus pour le niveau 7 (PLAFOND_JCJ).
##
## Les niveaux sont rangés dans le héros : h["sorts"] = {"<index du sort dans la fiche>": niveau}.
## L'index (et non le nom) survit à l'évolution, qui renomme parfois le sort.

const NIVEAU_MAX := 10
const BONUS_PAR_NIVEAU := 0.04
const PLAFOND_JCJ := 7
const PAGE := "page_grimoire"
const GRIMOIRE := "grimoire_interdit"

## Coût pour passer du niveau n au niveau n+1 (index = n - 1).
const PAGES := [3, 5, 8, 12, 16, 20, 25, 30, 40]
const GRIMOIRES := [0, 0, 0, 0, 0, 1, 2, 3, 5]
const OR_PAR_NIVEAU := 1000

## Effets dont la valeur grandit avec le niveau du sort (clé de la valeur dans l'effet).
const EFFETS_MULT := {"degats": "mult", "soin": "mult"}
const EFFETS_VALEUR := ["bouclier", "drain", "buff", "debuff", "regen_temp", "ressusciter", "stat", "aura",
	"aura_ennemis", "vol_vie", "epines", "regen", "execution", "renaissance", "soin_bonus", "bonus_arriere",
	"rage", "accumulation"]
const EFFETS_CHANCE := ["affliction", "contre", "double_attaque"]


static func multiplicateur(n: int) -> float:
	return 1.0 + BONUS_PAR_NIVEAU * (clampi(n, 1, NIVEAU_MAX) - 1)


## Niveau maximum d'un sort selon les étoiles du héros.
static func max_pour_etoiles(etoiles: int) -> int:
	return NIVEAU_MAX if etoiles >= Fusion.ETOILES_MAX else clampi(3 + etoiles, 1, NIVEAU_MAX)


## Tours de recharge gagnés au niveau n pour un sort de recharge de base r.
static func reduction_recharge(r: int, n: int) -> int:
	if r <= 2:
		return 1 if n >= 10 else 0
	if r == 3:
		return 1 if n >= 7 else 0
	return (1 if n >= 5 else 0) + (1 if n >= 10 else 0)


## Recharge d'un sort actif au niveau n (jamais moins d'un tour).
static func recharge(sk: Dictionary, n: int) -> int:
	var r := CombatMoteur.recharge_sort(sk)
	return maxi(1, r - reduction_recharge(r, n))


## Copie du sort avec les valeurs du niveau n (n = 1 : le sort est rendu tel quel).
static func appliquer(sk: Dictionary, n: int) -> Dictionary:
	n = clampi(n, 1, NIVEAU_MAX)
	if n <= 1:
		return sk
	var k := multiplicateur(n)
	var s := sk.duplicate(true)
	s["niveau_sort"] = n
	for e in s.get("effets", []):
		var t := str(e.get("effet", ""))
		if EFFETS_MULT.has(t) and e.has(EFFETS_MULT[t]):
			e[EFFETS_MULT[t]] = float(e[EFFETS_MULT[t]]) * k
		elif t in EFFETS_VALEUR and e.has("valeur"):
			e["valeur"] = float(e["valeur"]) * k
		elif t in EFFETS_CHANCE and e.has("chance"):
			e["chance"] = minf(1.0, float(e["chance"]) * k)
	# Recharge plus courte : on remonte la chance de lancement (c'est elle qui fixe la recharge)
	if str(sk.get("type", "")) == "actif" and sk.has("chance"):
		var r0 := CombatMoteur.recharge_sort(sk)
		var r1 := maxi(1, r0 - reduction_recharge(r0, n))
		if r1 < r0:
			s["chance"] = maxf(float(sk["chance"]), 1.0 / (r1 + 1) + 0.001)
	return s


## Ligne courte qui résume le niveau : « Niv 4/10 · effets +12 % · recharge 2 tours ».
static func resume(sk: Dictionary, n: int, maxi_n: int) -> String:
	var t := UiCommun.t("Niv %d / %d") % [n, maxi_n]
	if n > 1:
		t += UiCommun.t("  ·  effets +%d %%") % int(round((multiplicateur(n) - 1.0) * 100))
	if str(sk.get("type", "")) == "actif" and sk.has("chance"):
		var r0 := CombatMoteur.recharge_sort(sk)
		var r1 := recharge(sk, n)
		t += UiCommun.t("  ·  recharge %d tour%s") % [r1, "s" if r1 > 1 else ""]
		if r1 < r0:
			t += UiCommun.t(" (au lieu de %d)") % r0
	return t


# ---------------------------------------------------------------------
# Héros du joueur
# ---------------------------------------------------------------------

## Niveaux des sorts d'un héros : {"index": niveau} (copie, prête pour le combat).
## Clé "appris" : plus haut niveau atteint par le héros, s'il est au-dessus de son niveau actuel
## (après un Éveil, il garde les sorts qu'il avait déjà appris).
static func niveaux(uid: int) -> Dictionary:
	var h := Sauvegarde.get_heros(uid)
	if h.is_empty():
		return {}
	var d := (h.get("sorts", {}) as Dictionary).duplicate()
	if Fusion.niveau_record(h) > int(h["niveau"]):
		d["appris"] = Fusion.niveau_record(h)
	return d


## Le héros connaît-il ce sort ? (appris à son niveau actuel ou avant un Éveil)
static func est_appris(h: Dictionary, sk: Dictionary) -> bool:
	return int(sk["niveau"]) <= Fusion.niveau_record(h)


static func niveau(h: Dictionary, index: int) -> int:
	return clampi(int((h.get("sorts", {}) as Dictionary).get(str(index), 1)), 1, NIVEAU_MAX)


static func niveau_max(h: Dictionary) -> int:
	return max_pour_etoiles(Fusion.etoiles(h))


## Coût du prochain niveau : {objet: quantité} et l'or à part (clé "or").
static func cout(n: int) -> Dictionary:
	if n < 1 or n >= NIVEAU_MAX:
		return {}
	var c := {PAGE: int(PAGES[n - 1])}
	if int(GRIMOIRES[n - 1]) > 0:
		c[GRIMOIRE] = int(GRIMOIRES[n - 1])
	return c


static func cout_or(n: int) -> int:
	return OR_PAR_NIVEAU * n


## Ce qui empêche d'améliorer ce sort ("" = possible).
static func raison_impossible(uid: int, index: int) -> String:
	var h := Sauvegarde.get_heros(uid)
	if h.is_empty():
		return "Unité introuvable."
	var skills: Array = UnitesData.get_unite(h["id"]).get("skills", [])
	if index < 0 or index >= skills.size():
		return "Sort introuvable."
	if not est_appris(h, skills[index]):
		return UiCommun.t("Sort pas encore appris (niveau %d du héros).") % int(skills[index]["niveau"])
	var n := niveau(h, index)
	if n >= NIVEAU_MAX:
		return "Niveau maximum atteint."
	if n >= niveau_max(h):
		return UiCommun.t("Niveau %d maximum à %s : fais gagner une étoile au héros (Autel de Fusion).") % [n, Fusion.texte_etoiles(Fusion.etoiles(h))]
	if not Reliquaire.peut_payer(cout(n), cout_or(n)):
		return "Il manque des ressources : " + Reliquaire.texte_cout(cout(n), cout_or(n)) + "."
	return ""


## Monte le sort d'un niveau. Renvoie le nouveau niveau (0 = impossible).
static func ameliorer(uid: int, index: int) -> int:
	if raison_impossible(uid, index) != "":
		return 0
	var h := Sauvegarde.get_heros(uid)
	var n := niveau(h, index)
	if not Reliquaire.payer(cout(n), cout_or(n)):
		return 0
	if not h.has("sorts") or not (h["sorts"] is Dictionary):
		h["sorts"] = {}
	h["sorts"][str(index)] = n + 1
	Sauvegarde.ajouter_stat("sorts_ameliores")
	Sauvegarde.sauvegarder()
	return n + 1
