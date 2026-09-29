extends SceneTree
## CALIBRAGE DU MIMIC (outil de développement). Cherche pour chaque Acte le réglage qui donne
## ~72 % de victoires à l'équipe de référence (PV pleins). Lancer :
##   godot --headless --path . --script res://outils/calibrer_mimic.gd
## puis recopier « CALIBRAGE_MIMIC := ... » dans scripts/rencontres.gd.
const CIBLE := 0.72
var rng := RandomNumberGenerator.new()
var par_rarete := {}

func _equipe(acte: int, niveau: int) -> Array:
	var e: Array = []
	for r in Rencontres.EQUIPE_REFERENCE[acte]:
		var l: Array = par_rarete[r]
		e.append({"id": l[rng.randi_range(0, l.size() - 1)], "niveau": niveau})
	e.sort_custom(func(a, b): return Rencontres._ordre_place(a["id"]) < Rencontres._ordre_place(b["id"]))
	for i in e.size():
		e[i]["place"] = i
	return e

func _init():
	rng.seed = 11
	for r in ["LEG", "N", "R", "SR", "SSR", "UR"]:
		par_rarete[r] = []
	for id in UnitesData.UNITES:
		var u: Dictionary = UnitesData.UNITES[id]
		if u["invocable"]:
			par_rarete["LEG" if u.get("legende", false) else u["rarete"]].append(id)
	var essais := 200
	var res := {}
	for acte in range(1, 13):
		var chap := 3
		var niv := Rencontres.niveau_attendu(acte, chap)
		var lots: Array = []
		for k in essais:
			lots.append({"equipe": _equipe(acte, niv), "graine": rng.randi(), "noeud": {"id": k, "mimic": true, "type": 0}})
		var bas := 0.2
		var haut := 4.0
		for it in 10:
			var c := sqrt(bas * haut)
			Rencontres.calibrage_test["%d-mimic" % acte] = c
			var ok := 0
			for l in lots:
				var m := CombatMoteur.new(l["equipe"].duplicate(true), Rencontres.generer(acte, chap, l["noeud"]), l["graine"])
				if m.combattre()["victoire"]:
					ok += 1
			if float(ok) / essais > CIBLE:
				bas = c
			else:
				haut = c
		res[acte] = snappedf(sqrt(bas * haut), 0.01)
		print("Acte %d : %s" % [acte, res[acte]])
	print("CALIBRAGE_MIMIC := ", res)
	quit()
