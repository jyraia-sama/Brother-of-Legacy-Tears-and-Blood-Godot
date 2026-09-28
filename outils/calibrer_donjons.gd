extends SceneTree
## CALIBRAGE DES DONJONS (outil de développement, pas utilisé par le jeu).
## Cherche, pour chaque niveau et chaque combat, le réglage qui donne la réussite visée
## (PV conservés d'un combat à l'autre). Lancer en ligne de commande :
##   godot --headless --path . --script res://outils/calibrer_donjons.gd
## puis recopier la ligne "CALIBRAGE := ..." dans scripts/donjons.gd.
var rng := RandomNumberGenerator.new()
var par_rarete := {}
const CIBLES := {
	"normal": [0.97, 0.92, 0.92, 0.85],
	9: [0.95, 0.88, 0.88, 0.75],
	10: [0.93, 0.84, 0.84, 0.66],
}

func _equipe(acte: int, niveau: int) -> Array:
	var e: Array = []
	for r in Rencontres.EQUIPE_REFERENCE[acte]:
		var l: Array = par_rarete[r]
		e.append({"id": l[rng.randi_range(0, l.size() - 1)], "niveau": niveau})
	e.sort_custom(func(a, b): return Rencontres._ordre_place(a["id"]) < Rencontres._ordre_place(b["id"]))
	for i in e.size():
		e[i]["place"] = i
	return e

func _combat(essai: Dictionary, n: int, v: int) -> Dictionary:
	var m := CombatMoteur.new(essai["equipe"], Donjons.generer(essai["donjon"], n, v), essai["graines"][v])
	return m.combattre()

func _init():
	rng.seed = 7
	for r in ["LEG", "N", "R", "SR", "SSR", "UR"]:
		par_rarete[r] = []
	for id in UnitesData.UNITES:
		var u: Dictionary = UnitesData.UNITES[id]
		if u["invocable"]:
			par_rarete["LEG" if u.get("legende", false) else u["rarete"]].append(id)
	var essais := int(OS.get_environment("ESSAIS")) if OS.get_environment("ESSAIS") != "" else 150
	var t0 := Time.get_ticks_msec()
	var resultat: Array = []
	for n in range(1, 11):
		var eq := Donjons.point(n)
		var niv := Rencontres.niveau_attendu(eq.x, eq.y)
		var cibles: Array = CIBLES.get(n, CIBLES["normal"])
		var vivants: Array = []
		for k in essais:
			vivants.append({"donjon": Donjons.ORDRE[k % 6], "equipe": _equipe(eq.x, niv),
				"graines": [rng.randi(), rng.randi(), rng.randi(), rng.randi()]})
		var calibs: Array = []
		var global := 1.0
		for v in 4:
			var bas := 0.15
			var haut := 4.0
			for it in 9:
				var c := sqrt(bas * haut)
				Donjons.calibrage_test["%d-%d" % [n, v]] = c
				var ok := 0
				for e in vivants:
					if _combat(e, n, v)["victoire"]:
						ok += 1
				var taux := float(ok) / maxf(1.0, vivants.size())
				if taux > cibles[v]:
					bas = c
				else:
					haut = c
			var cf := snappedf(sqrt(bas * haut), 0.01)
			Donjons.calibrage_test["%d-%d" % [n, v]] = cf
			calibs.append(cf)
			var suivants: Array = []
			for e in vivants:
				var r := _combat(e, n, v)
				if r["victoire"]:
					var e2: Dictionary = e.duplicate(true)
					for i in e2["equipe"].size():
						e2["equipe"][i]["pv_ratio"] = r["pv_final"][i]
					suivants.append(e2)
			global *= float(suivants.size()) / maxf(1.0, vivants.size())
			vivants = suivants
		resultat.append(calibs)
		print("Niveau %d : calibrage %s   réussite finale %d %%   (%d s)" % [n, str(calibs), int(100.0 * vivants.size() / essais), (Time.get_ticks_msec() - t0) / 1000])
	print("CALIBRAGE := ", resultat)
	quit()
