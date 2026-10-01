extends SceneTree
## Mesure l'effet des Échos : mêmes équipes réalistes avec et sans leurs Échos (outil de dev).
##   godot --headless --path . --script res://outils/effet_echos.gd -- --equipes=/chemin/reg.json
var T := PlateauGenerateur.Type
var rng := RandomNumberGenerator.new()

func _init():
	rng.seed = 5
	var fichier := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--equipes="):
			fichier = a.split("=")[1]
	var data: Array = JSON.parse_string(FileAccess.get_file_as_string(fichier))
	Rencontres.calibrage_test["sans_invite"] = true
	var par_acte := {}
	for snap in data:
		var a := int(snap["acte"])
		if not par_acte.has(a):
			par_acte[a] = []
		par_acte[a].append(snap)
	for acte in [2, 4, 6, 8, 10, 12, 13]:
		var avec := 0
		var sans := 0
		var n := 0
		for snap in par_acte[acte]:
			for type in [T.ELITE, T.GARDIEN, T.BOSS]:
				var chap := int(snap["chapitre"])
				var eq_a: Array = []
				var eq_s: Array = []
				for u in snap["equipe"]:
					var e := {"id": u["id"], "niveau": int(u["niveau"]), "place": int(u["place"]), "etoiles": int(u["etoiles"])}
					eq_s.append(e.duplicate())
					e["echos"] = u["echos"]
					eq_a.append(e)
				var g := rng.randi()
				var noeud := {"id": n, "type": type}
				if CombatMoteur.new(eq_a, Rencontres.generer(acte, chap, noeud), g).combattre()["victoire"]:
					avec += 1
				if CombatMoteur.new(eq_s, Rencontres.generer(acte, chap, noeud), g).combattre()["victoire"]:
					sans += 1
				n += 1
		print("Acte %d : avec Échos %d%%  ·  sans %d%%" % [acte, int(100.0 * avec / n), int(100.0 * sans / n)])
	quit()
