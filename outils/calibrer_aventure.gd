extends SceneTree
## CALIBRAGE DE L'AVENTURE (outil de développement).
## Règle la difficulté de chaque Acte et de chaque type de case sur des ÉQUIPES RÉALISTES : celles des joueurs
## virtuels de simuler_progression.gd (gacha, niveaux, étoiles et Échos réels, au début de chaque chapitre).
##   1) godot --headless --path . --script res://outils/simuler_progression.gd -- --joueurs=24 --profil=occasionnel --sortie=/chemin/occ.json
##   2) godot --headless --path . --script res://outils/calibrer_aventure.gd -- --equipes=/chemin/occ.json
##   3) recopier CALIBRAGE, CALIBRAGE_MIMIC et RENFORT_INVITE dans scripts/rencontres.gd.
## Les taux visés sont PV pleins ; sur le plateau (PV conservés d'une case à l'autre) ils sont un peu plus bas.

const TYPES := ["combat", "elite", "gardien", "boss_chapitre", "boss_acte", "mimic"]
## Taux visés pour un JOUEUR OCCASIONNEL (Échos posés mais pas améliorés, pas de Fusion), PV pleins.
## Sur le plateau, les PV conservés d'une case à l'autre ajoutent environ une défaite par chapitre :
## au total ~1 à 3 défaites par chapitre (surtout sur le boss), moins pour un joueur qui améliore ses Échos.
const CIBLES := {"combat": 0.97, "elite": 0.88, "gardien": 0.82, "boss_chapitre": 0.72, "boss_acte": 0.60, "mimic": 0.78}
## Accueil : l'Acte I est très doux, l'Acte II un peu moins ; l'Acte caché est plus exigeant (évolutions conseillées).
const CIBLES_ACTE := {
	1: {"combat": 0.99, "elite": 0.96, "gardien": 0.95, "boss_chapitre": 0.92, "boss_acte": 0.80, "mimic": 0.88},
	2: {"combat": 0.98, "elite": 0.92, "gardien": 0.88, "boss_chapitre": 0.82, "boss_acte": 0.68, "mimic": 0.82},
	13: {"combat": 0.95, "elite": 0.82, "gardien": 0.75, "boss_chapitre": 0.62, "boss_acte": 0.50, "mimic": 0.72},
}
## Avec Kaël à tes côtés : un peu plus facile que la cible, sans être gratuit.
const AIDE_KAEL := 0.08
const NOEUDS := 2

var T := PlateauGenerateur.Type
var equipes := {}      # "acte-chapitre" -> [équipes]
var rng := RandomNumberGenerator.new()
var actes: Array = range(1, 14)


func _init():
	rng.seed = 77
	var fichiers: Array = []
	for a in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if a.begins_with("--equipes="):
			fichiers = a.split("=")[1].split(",")
		if a.begins_with("--actes="):          # ex. --actes=1-7 (pour lancer deux calibrages en parallèle)
			var b: PackedStringArray = a.split("=")[1].split("-")
			actes = range(int(b[0]), int(b[1]) + 1)
	for f in fichiers:
		var data: Array = JSON.parse_string(FileAccess.get_file_as_string(f))
		for snap in data:
			var cle := "%d-%d" % [int(snap["acte"]), int(snap["chapitre"])]
			var eq: Array = []
			for u in snap["equipe"]:
				eq.append({"id": u["id"], "niveau": int(u["niveau"]), "place": int(u["place"]),
					"etoiles": int(u["etoiles"]), "echos": u["echos"]})
			if not equipes.has(cle):
				equipes[cle] = []
			equipes[cle].append(eq)
	print("Équipes chargées : ", equipes.size(), " chapitres")
	var calib := {}
	var calib_mimic := {}
	var calib_chefs := {}
	var renfort := {}
	for acte: int in actes:
		var ligne := {}
		var avec_kael := acte == 1          # Acte I : Kaël partout, il fait partie du calibrage
		Rencontres.calibrage_test["sans_invite"] = not avec_kael
		for type in TYPES:
			var cible: float = CIBLES_ACTE.get(acte, CIBLES)[type]
			var lots := _lots(acte, type, avec_kael, false)
			var v := _chercher(lots, "%d-%s" % [acte, type], cible)
			Rencontres.calibrage_test["%d-%s" % [acte, type]] = v
			if type == "mimic":
				calib_mimic[acte] = v
			else:
				ligne[type] = v
		calib[acte] = ligne
		# Chefs : correction chapitre par chapitre (chaque chef a ses propres sorts)
		var chefs := {}
		for chap in range(1, 6):
			var l: Array = _lots(acte, "boss_chapitre", avec_kael, false, 3).filter(func(x): return x["chapitre"] == chap)
			chefs[chap] = _chercher(l, "%d-chef%d" % [acte, chap], CIBLES_ACTE.get(acte, CIBLES)["boss_chapitre"])
			Rencontres.calibrage_test["%d-chef%d" % [acte, chap]] = chefs[chap]
		calib_chefs[acte] = chefs
		# Renfort des ennemis quand Kaël est là (Actes X, XII et XIII)
		Rencontres.calibrage_test.erase("sans_invite")
		if acte in [10, 12, 13]:
			var lots: Array = []
			var cible := 0.0
			var n := 0
			for type in ["gardien", "boss_chapitre", "boss_acte"]:
				var l := _lots(acte, type, true, true)
				if l.is_empty():
					continue
				lots.append_array(l)
				cible += (CIBLES_ACTE.get(acte, CIBLES)[type] + AIDE_KAEL) * l.size()
				n += l.size()
			renfort[acte] = _chercher(lots, "invite-%d" % acte, cible / n)
			Rencontres.calibrage_test["invite-%d" % acte] = renfort[acte]
		print("Acte %d : %s  mimic %s  %s" % [acte, ligne, calib_mimic[acte], ("Kaël x%s" % renfort[acte]) if renfort.has(acte) else ""])
	print("\nconst CALIBRAGE := {")
	for acte in calib:
		print("\t%d: %s," % [acte, calib[acte]])
	print("}")
	print("const CALIBRAGE_MIMIC := ", calib_mimic)
	print("const CALIBRAGE_CHEFS := ", calib_chefs)
	print("const RENFORT_INVITE := ", renfort)
	_verifier()
	quit()


## Combats à jouer pour un Acte et un type : chaque équipe réaliste de l'Acte contre quelques cases.
## `kael_seulement` : ne garder que les chapitres où Kaël est là (et l'ajouter à l'équipe).
func _lots(acte: int, type: String, avec_kael: bool, kael_seulement: bool, noeuds := NOEUDS) -> Array:
	var chapitres := [1, 2, 3, 4, 5, 6]
	if type == "boss_chapitre":
		chapitres = [1, 2, 3, 4, 5]
	elif type == "boss_acte":
		chapitres = [6]
	var invites: Array = FinHistoire.CHAPITRES_INVITE.get(acte, [])
	var lots: Array = []
	for chap in chapitres:
		if kael_seulement and not chap in invites:
			continue
		var t := T.COMBAT
		match type:
			"elite": t = T.ELITE
			"gardien": t = T.GARDIEN
			"boss_chapitre", "boss_acte": t = T.BOSS
			"mimic": t = T.COFFRE
		for eq in equipes.get("%d-%d" % [acte, chap], []):
			for k in noeuds:
				var e: Array = eq.duplicate(true)
				if (avec_kael or kael_seulement) and chap in invites:
					e.append({"id": "kael_jeune" if acte == 1 else "kael_valcendre", "niveau": Rencontres.niveau_attendu(acte, chap),
						"place": 5, "etoiles": 1 if acte == 1 else 3})
				var noeud := {"id": k * 37 + chap, "type": t}
				if type == "mimic":
					noeud["mimic"] = true
				lots.append({"acte": acte, "chapitre": chap, "equipe": e, "noeud": noeud, "graine": rng.randi()})
	return lots


func _taux(lots: Array) -> float:
	var ok := 0
	for l in lots:
		var m := CombatMoteur.new(l["equipe"].duplicate(true), Rencontres.generer(l["acte"], l["chapitre"], l["noeud"]), l["graine"])
		if m.combattre()["victoire"]:
			ok += 1
	return float(ok) / maxf(1, lots.size())


func _chercher(lots: Array, cle: String, cible: float) -> float:
	var bas := 0.25
	var haut := 6.0
	for it in 9:
		var c := sqrt(bas * haut)
		Rencontres.calibrage_test[cle] = c
		if _taux(lots) > cible:
			bas = c
		else:
			haut = c
	return snappedf(sqrt(bas * haut), 0.01)


## Contrôle final : taux obtenus avec le calibrage trouvé.
func _verifier() -> void:
	print("\nContrôle (PV pleins, équipes réalistes) :")
	for acte: int in actes:
		Rencontres.calibrage_test["sans_invite"] = acte != 1
		var l := "Acte %2d :" % acte
		for type in TYPES:
			l += "  %s %d%%" % [type, int(round(_taux(_lots(acte, type, acte == 1, false)) * 100))]
		Rencontres.calibrage_test.erase("sans_invite")
		if acte in [10, 12, 13]:
			var lots: Array = []
			for type in ["gardien", "boss_chapitre", "boss_acte"]:
				lots.append_array(_lots(acte, type, true, true))
			l += "  | avec Kaël %d%%" % int(round(_taux(lots) * 100))
		print(l)
