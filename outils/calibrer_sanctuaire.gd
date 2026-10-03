extends SceneTree
## Calibrage du Sanctuaire du Bélier (outil de dev) : cherche la « force » de chaque épreuve pour que des
## équipes réalistes (fichiers de simuler_progression.gd, profil occasionnel) gagnent le taux visé.
##   godot --headless --path . --script res://outils/calibrer_sanctuaire.gd -- --equipes=occ.json
const CIBLES := {"alysse": 0.70, "loucas": 0.62, "anais": 0.55, "famille": 0.45}
var equipes: Array = []

func _init():
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--equipes="):
			for f in a.split("=")[1].split(","):
				for snap in JSON.parse_string(FileAccess.get_file_as_string(f)):
					if int(snap["acte"]) >= 3 and int(snap["chapitre"]) in [1, 4]:
						var eq: Array = []
						for u in snap["equipe"]:
							eq.append({"id": u["id"], "niveau": int(u["niveau"]), "place": int(u["place"]), "etoiles": int(u["etoiles"]), "echos": u["echos"]})
						equipes.append({"eq": eq, "g": rng.randi()})
	print("équipes : ", equipes.size())
	for ep in Sanctuaire.ORDRE:
		var bas := 0.1
		var haut := 3.0
		for it in 10:
			var c := sqrt(bas * haut)
			Sanctuaire.calibrage_test[ep] = c
			if _taux(ep) > CIBLES[ep]:
				bas = c
			else:
				haut = c
		Sanctuaire.calibrage_test[ep] = snappedf(sqrt(bas * haut), 0.01)
		print("%s : force %.2f -> victoires %d%%" % [ep, Sanctuaire.calibrage_test[ep], int(_taux(ep) * 100)])
	quit()

func _taux(ep: String) -> float:
	var ok := 0
	for t in equipes:
		var eq: Array = t["eq"].duplicate(true)
		if CombatMoteur.new(eq, Sanctuaire.generer(ep, eq), t["g"]).combattre()["victoire"]:
			ok += 1
	return float(ok) / equipes.size()
