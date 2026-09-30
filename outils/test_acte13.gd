extends SceneTree
## Compare la réussite de l'équipe de référence entre l'Acte XII et l'Acte XIII (outil de dev).
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
	rng.seed = 5
	for r in ["LEG", "N", "R", "SR", "SSR", "UR"]:
		par_rarete[r] = []
	for id in UnitesData.UNITES:
		var u: Dictionary = UnitesData.UNITES[id]
		if u["invocable"]:
			par_rarete["LEG" if u.get("legende", false) else u["rarete"]].append(id)
	var T := PlateauGenerateur.Type
	for acte in [12, 13]:
		var ligne := "Acte %d :" % acte
		for t in [["combat", T.COMBAT, 3], ["elite", T.ELITE, 3], ["gardien", T.GARDIEN, 3], ["boss_chapitre", T.BOSS, 3], ["boss_acte", T.BOSS, 6]]:
			var ok := 0
			for k in 150:
				var niv := Rencontres.niveau_attendu(acte, t[2])
				var m := CombatMoteur.new(_equipe(acte, niv), Rencontres.generer(acte, t[2], {"id": k, "type": t[1]}), rng.randi())
				if m.combattre()["victoire"]:
					ok += 1
			ligne += "  %s %d%%" % [t[0], int(ok * 100 / 150.0)]
		print(ligne)
	quit()
