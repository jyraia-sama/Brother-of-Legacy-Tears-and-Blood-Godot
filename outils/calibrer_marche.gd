extends SceneTree
## SIMULATION DE LA MARCHE MAUDITE (outil de développement, pas utilisé par le jeu).
## Joue des marches entières avec des choix au hasard et affiche jusqu'où l'équipe arrive.
##   godot --headless --path . --script res://outils/calibrer_marche.gd
## ATTENTION : utilise (et remet à zéro) la sauvegarde locale de la machine.
var rng := RandomNumberGenerator.new()

func _choisir_tout(p: Dictionary) -> void:
	# Résout les attentes hors combat au hasard
	for garde in 20:
		var a: Dictionary = p["attente"]
		match str(a.get("type", "")):
			"benediction":
				Marche.choisir_benediction(rng.randi_range(0, a["offres"].size() - 1))
			"recrue":
				var ko := -1
				for i in p["equipe"].size():
					if float(p["equipe"][i]["pv"]) <= 0.0:
						ko = i
				Marche.recruter(ko)
			"evenement":
				var n: int = Marche.EVENEMENTS[a["id"]]["choix"].size()
				Marche.choisir_evenement(rng.randi_range(0, n - 1))
			"feu":
				var faible := 0.0
				for m in p["equipe"]:
					faible += float(m["pv"])
				Marche.feu_de_camp("repos" if faible / p["equipe"].size() < 0.7 else "entrainement")
			"marchand":
				for k in 3:
					Marche.acheter(rng.randi_range(0, 5))
				Marche.quitter_lieu()
			"autel":
				Marche.pacte(rng.randi_range(-1, 0))
			_:
				return

func _init():
	rng.seed = int(OS.get_environment("GRAINE")) if OS.get_environment("GRAINE") != "" else 3
	var essais := int(OS.get_environment("ESSAIS")) if OS.get_environment("ESSAIS") != "" else 60
	var acte := int(OS.get_environment("ACTE")) if OS.get_environment("ACTE") != "" else 6
	var par_rarete := {}
	for r in ["LEG", "N", "R", "SR", "SSR", "UR"]:
		par_rarete[r] = []
	for id in UnitesData.UNITES:
		var u: Dictionary = UnitesData.UNITES[id]
		if u["invocable"]:
			par_rarete["LEG" if u.get("legende", false) else u["rarete"]].append(id)
	var atteint := {}          # "région-ligne" max
	var regions_finies := [0, 0, 0]
	var scores: Array = []
	var morts := {}
	for t in ["combat", "elite", "boss"]:
		if OS.get_environment("F_" + t.to_upper()) != "":
			Marche.force_test[t] = float(OS.get_environment("F_" + t.to_upper()))
	for k in essais:
		Sauvegarde.charger()
		Sauvegarde.reinitialiser()
		Sauvegarde.definir_admin("marche_illimitee", true)
		var niv := Rencontres.niveau_attendu(acte, 1)
		var uids: Array = []
		for r in Rencontres.EQUIPE_REFERENCE[acte]:
			var l: Array = par_rarete[r]
			var uid := Sauvegarde.ajouter_heros(l[rng.randi_range(0, l.size() - 1)])
			Sauvegarde.get_heros(uid)["niveau"] = niv
			uids.append(uid)
		Marche._donnees()["partie"] = {}
		Marche.commencer(uids, false)
		var p := Marche.partie()
		for pas in 60:
			_choisir_tout(p)
			if not Marche.en_cours():
				break
			var att: Dictionary = p["attente"]
			if att.get("type", "") == "combat":
				var d := Marche.demande_combat()
				var m := CombatMoteur.new(d["equipe"], d["ennemis"], rng.randi())
				var res := m.combattre()
				var region := int(p["region"])
				var t: String = d["type"]
				Marche.apres_combat(res)
				if not res["victoire"]:
					var cle := "%s-R%d" % [t, region + 1]
					morts[cle] = int(morts.get(cle, 0)) + 1
				if res["victoire"] and t == "boss":
					regions_finies[region] += 1
				continue
			var cases := Marche.cases_atteignables()
			if cases.is_empty():
				break
			Marche.avancer(cases[rng.randi_range(0, cases.size() - 1)])
		if Marche.en_cours():
			Marche.abandonner()
		scores.append(int(Marche.partie()["resultat"]["score"]))
	scores.sort()
	var somme := 0
	for s in scores:
		somme += s
	print("Acte %d, %d marches : boss région 1 = %d %%, région 2 = %d %%, région 3 (fin) = %d %%   score moyen %d, médian %d" % [
		acte, essais, 100 * regions_finies[0] / essais, 100 * regions_finies[1] / essais, 100 * regions_finies[2] / essais,
		somme / essais, scores[scores.size() / 2]])
	print("  défaites : ", morts)
	Sauvegarde.reinitialiser()
	quit()
