extends SceneTree
## SIMULATION DE PROGRESSION COMPLÈTE (outil de développement).
## Fait jouer des joueurs virtuels de l'Acte I chapitre 1 à la fin de l'Acte XIII, avec les VRAIES règles :
## plateaux, combats (moteur réel), PV conservés entre les cases, Mimics, Kaël invité, XP, or, Échos qui
## tombent, Éclats des boss, quêtes/connexion (estimées au temps passé), invocations, Fusion.
##   godot --headless --path . --script res://outils/simuler_progression.gd
## Options : --joueurs=N (défaut 20) · --profil=regulier|occasionnel|sans_echos · --sortie=fichier.json (équipes).
##
## Modèle du joueur (« joueur régulier », sans achat) :
##  - joue 3 fois par jour (la stamina ne déborde pas plus) et fait ~80 % de ses quêtes ;
##  - chemin sur le plateau : au hasard parmi les chemins les plus courts vers le boss, ouvre la moitié des culs-de-sac ;
##  - équipe : les 5 unités les plus puissantes ; Échos : les meilleurs de chaque emplacement, améliorés avec ~35 % de l'or ;
##  - gemmes -> Éclats au Comptoir (lot de 10 puis à l'unité), Éclats -> Pacte Supérieur, or en trop -> Pacte Doré x10 ;
##  - nouvelles unités montées par Absorption (unités N/R en trop) ;
##  - bloqué (8 défaites de suite sur une case) : il « farme » des combats ordinaires puis réessaie.

const T := PlateauGenerateur.Type
const SESSIONS_PAR_JOUR := 3
const PART_QUETES := 0.8
const LIMITE_ESSAIS := 8
const PART_OR_ECHOS := 0.35

var rng := RandomNumberGenerator.new()
var par_rarete := {}

# --- État d'un joueur ---
var roster: Array = []
var prochain_uid := 1
var echos_sac: Array = []
var or_ := 0
var gemmes := 50
var eclats := 0
var pity := 0
var compte_niv := 1
var compte_xp := 0
var stamina := 30
var jours := 0.0
var semaines_payees := 0
var jours_payes := 0
var deja_termine := {}
var nb_invoc := 0
var nb_victoires := 0
var benediction := false
var graine := 0
var profil := "regulier"   # regulier · occasionnel · sans_echos
var sortie := ""
var instantanes: Array = []   # équipes au début de chaque chapitre (pour calibrer_aventure.gd)
var m_types := {}   # "acte-type" -> [victoires, combats]

# --- Mesures ---
var m_chap := {}      # "a-c" -> {defaites, farm, stamina, or, niv_moy, jours}
var m_mur := {}       # "a-c-type" -> défaites cumulées


func _init():
	var nb := 20
	for a in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if a.begins_with("--joueurs="):
			nb = int(a.split("=")[1])
		if a.begins_with("--graine="):
			graine = int(a.split("=")[1])
		if a.begins_with("--profil="):
			profil = a.split("=")[1]
		if a.begins_with("--sortie="):
			sortie = a.split("=")[1]
	print("Profil : ", {"regulier": "RÉGULIER (tout)", "occasionnel": "OCCASIONNEL (Échos posés sans amélioration, Absorption ; ni Pacte Doré ni Fusion)",
		"sans_echos": "SANS ÉCHOS (Absorption seulement)"}[profil])
	for r in ["LEG", "N", "R", "SR", "SSR", "UR"]:
		par_rarete[r] = []
	for id in UnitesData.UNITES:
		var u: Dictionary = UnitesData.UNITES[id]
		if u["invocable"]:
			par_rarete["LEG" if u.get("legende", false) else u["rarete"]].append(id)
	var resultats: Array = []
	for j in nb:
		rng.seed = 1000 + j * 7919 + graine * 104729
		resultats.append(_jouer())
		printerr("joueur %d/%d terminé" % [j + 1, nb])
	_rapport(resultats)
	if sortie != "":
		var f := FileAccess.open(sortie, FileAccess.WRITE)
		f.store_string(JSON.stringify(instantanes))
		f.close()
		print("Équipes enregistrées : ", sortie, " (", instantanes.size(), ")")
	quit()


# =====================================================================
# Un joueur complet
# =====================================================================
func _jouer() -> Dictionary:
	roster.clear(); echos_sac.clear(); deja_termine.clear()
	prochain_uid = 1; or_ = 0; gemmes = 50; eclats = 0; pity = 0
	compte_niv = 1; compte_xp = 0; stamina = 30; jours = 0.0
	semaines_payees = 0; jours_payes = 0; nb_invoc = 0; nb_victoires = 0; benediction = false
	_stamina_cumul = 0; m_types.clear()
	var leg: Array = par_rarete["LEG"]
	_ajouter(leg[rng.randi_range(0, leg.size() - 1)])
	for id in Sauvegarde.UNITES_DE_DEPART:
		_ajouter(id)
	var parcours := {}
	for acte in range(1, 14):
		for chap in range(1, 7):
			var st0 := _stamina_totale()
			var force_eq := 0.0
			for h in _equipe():
				force_eq += _force(h)
			var ratio := force_eq / Rencontres.puissance_reference(acte, chap)
			var snap: Array = []
			for h in _equipe():
				snap.append({"id": h["id"], "niveau": h["niveau"], "place": h["place"], "etoiles": h["etoiles"],
					"echos": Echos.bonus(h["echos"].values())})
			instantanes.append({"acte": acte, "chapitre": chap, "equipe": snap})
			var avant := {"or": or_, "def": 0}
			var r := _chapitre(acte, chap)
			# Temps passé : la stamina dépensée au-delà des recharges de niveau
			_gestion()
			var eq := _equipe()
			var niv := 0.0
			var rar: Array = []
			for h in eq:
				niv += h["niveau"]
				rar.append(_rarete(h["id"]))
			parcours["%d-%d" % [acte, chap]] = {
				"defaites": r["defaites"], "farm": r["farm"], "stamina": _stamina_totale() - st0,
				"niv": niv / maxf(1, eq.size()), "attendu": Rencontres.niveau_attendu(acte, chap),
				"jours": jours, "or": or_, "eclats_gagnes": r["eclats"], "raretes": rar,
				"echos": _echos_moyens(), "compte": compte_niv, "murs": r["murs"],
				"etoiles": _etoiles_moy(), "types": m_types.duplicate(true), "ratio": ratio,
			}
	return parcours


var _stamina_cumul := 0
func _stamina_totale() -> int:
	return _stamina_cumul


func _depenser(n: int) -> void:
	_stamina_cumul += n
	var mx := Sauvegarde.stamina_max_niveau(compte_niv)
	if stamina < n:
		# Plus de stamina : on attend la prochaine séance (3 par jour), stamina pleine
		jours += 1.0 / SESSIONS_PAR_JOUR
		stamina = mx
		_revenus()
	stamina -= n


# =====================================================================
# Un chapitre : le plateau case par case
# =====================================================================
func _chapitre(acte: int, chap: int) -> Dictionary:
	var pl := PlateauGenerateur.generer(acte, chap)
	var noeuds: Array = pl["noeuds"]
	var boss: int = pl["boss"]
	# distance au boss (BFS)
	var dist := {boss: 0}
	var file := [boss]
	while not file.is_empty():
		var x: int = file.pop_front()
		for v in noeuds[x]["voisins"]:
			if not dist.has(v):
				dist[v] = dist[x] + 1
				file.append(v)
	var res := {"defaites": 0, "farm": 0, "eclats": 0, "murs": []}
	var pv := {}
	benediction = false
	var cur: int = pl["depart"]
	var mimics := {}
	while cur != boss:
		# culs-de-sac voisins (coffres) : on en ouvre la moitié
		for v in noeuds[cur]["voisins"]:
			if noeuds[v]["cul_de_sac"] and dist.get(v, 999) > dist[cur] and rng.randf() < 0.5:
				_evenement(acte, chap, noeuds[v], pv, res, mimics)
		var choix: Array = []
		for v in noeuds[cur]["voisins"]:
			if dist.get(v, 999) == dist[cur] - 1:
				choix.append(v)
		cur = choix[rng.randi_range(0, choix.size() - 1)]
		_evenement(acte, chap, noeuds[cur], pv, res, mimics)
	return res


func _evenement(acte: int, chap: int, n: Dictionary, pv: Dictionary, res: Dictionary, mimics: Dictionary) -> void:
	var type: int = n["type"]
	if PlateauGenerateur.est_combat(type):
		_combat_case(acte, chap, n, pv, res, false)
		return
	match type:
		T.COFFRE:
			if rng.randf() < Rencontres.CHANCE_MIMIC:
				var m := n.duplicate()
				m["mimic"] = true
				_combat_case(acte, chap, m, pv, res, true)
				return
			_or(_or_coffre(n))
		T.SOIN:
			pv.clear()
		T.PIEGE:
			for uid in pv.keys():
				pv[uid] = maxf(0.05, pv[uid] - 0.15)
			for h in _equipe():
				if not pv.has(h["uid"]):
					pv[h["uid"]] = 0.85
		T.MYSTERE:
			var r := rng.randf()
			if r < 0.35:
				_or(60 + int(n["niveau"]) * 20)
			elif r < 0.6:
				benediction = true
			else:
				var m := n.duplicate()
				m["type"] = T.COMBAT
				_combat_case(acte, chap, m, pv, res, true)


func _or_coffre(n: Dictionary) -> int:
	var g := 40 + int(n["niveau"]) * 15 + rng.randi_range(0, 30)
	return int(g * 1.8) if n["cul_de_sac"] else g


## Combat d'une case, avec les retraites et les nouvelles tentatives.
func _combat_case(acte: int, chap: int, n: Dictionary, pv: Dictionary, res: Dictionary, gratuit: bool) -> void:
	var type := Rencontres.type_rencontre(n, chap)
	var essais := 0
	while true:
		if not gratuit:
			_depenser(int(Sauvegarde.COUT_STAMINA_AVENTURE[type]))
		var r := _combat(acte, chap, n, type, pv)
		var ct := "%d-%s" % [acte, type]
		if not m_types.has(ct):
			m_types[ct] = [0, 0]
		m_types[ct][1] += 1
		if r["victoire"]:
			m_types[ct][0] += 1
			return
		res["defaites"] += 1
		essais += 1
		pv.clear()                      # défaite : retraite d'une case, PV rendus
		var cle := "%s" % type
		if not cle in res["murs"]:
			res["murs"].append(cle)
		if essais >= LIMITE_ESSAIS:
			# Bloqué : il farme des combats ordinaires de ce chapitre pour progresser
			for k in 6:
				_depenser(1)
				_combat(acte, chap, {"id": 900 + k, "type": T.COMBAT, "niveau": n["niveau"], "cul_de_sac": false}, "combat", {})
				res["farm"] += 1
			_gestion()
			essais = 0
			if res["farm"] > 300:
				return                       # abandon (mur infranchissable pour ce joueur)


func _combat(acte: int, chap: int, n: Dictionary, type: String, pv: Dictionary) -> Dictionary:
	var eq := _equipe()
	var equipe: Array = []
	for h in eq:
		var portes: Array = h["echos"].values()
		equipe.append({"id": h["id"], "niveau": h["niveau"], "uid": h["uid"], "place": h["place"],
			"etoiles": h["etoiles"], "echos": Echos.bonus(portes), "pv_ratio": pv.get(h["uid"], 1.0),
			"bonus_atk": 0.10 if benediction else 0.0})
	var inv: Array = FinHistoire.CHAPITRES_INVITE.get(acte, [])
	if chap in inv:
		equipe.append({"id": "kael_jeune" if acte == 1 else "kael_valcendre", "niveau": Rencontres.niveau_attendu(acte, chap),
			"place": 5, "etoiles": 1 if acte == 1 else 3, "invite": true})
	benediction = false
	var ennemis := Rencontres.generer(acte, chap, n)
	var m := CombatMoteur.new(equipe, ennemis, rng.randi())
	var r := m.combattre()
	if not r["victoire"]:
		return r
	nb_victoires += 1
	var niv_e := int(ennemis[0]["niveau"])
	_or(Rencontres.or_victoire(type, niv_e))
	_xp_compte(int(Sauvegarde.XP_COMPTE_VICTOIRE.get(type, 10)))
	var e := Echos.tirer_drop(acte, chap, type, rng)
	if not e.is_empty():
		echos_sac.append(e)
	if type in ["boss_chapitre", "boss_acte"]:
		var cle := "%d-%d" % [acte, chap]
		if not deja_termine.has(cle):
			deja_termine[cle] = true
			eclats += 1 if type == "boss_chapitre" else 3
			_xp_compte(20 + ((acte - 1) * 6 + chap) * 3)
	if type == "mimic":
		_or(_or_coffre(n) * 2)
	var pf: Array = r["pv_final"]
	for i in eq.size():
		var h: Dictionary = eq[i]
		var xp := Rencontres.xp_victoire(type, h["niveau"], acte, chap)
		if pf[i] <= 0.0:
			xp = int(xp * 0.5)
		_xp_heros(h, xp)
		pv[h["uid"]] = clampf(maxf(pf[i], 0.0) + 0.30, 0.0, 1.0)
	return r


# =====================================================================
# Ressources
# =====================================================================
func _or(n: int) -> void:
	or_ += n


func _xp_heros(h: Dictionary, xp: int) -> void:
	h["xp"] += xp
	var mx := UnitesData.niveau_max(h["id"])
	while h["niveau"] < mx and h["xp"] >= Sauvegarde.xp_heros_pour_niveau(h["niveau"]):
		h["xp"] -= Sauvegarde.xp_heros_pour_niveau(h["niveau"])
		h["niveau"] += 1
	if h["niveau"] >= mx:
		h["xp"] = 0


func _xp_compte(xp: int) -> void:
	if compte_niv >= Sauvegarde.NIVEAU_COMPTE_MAX:
		return
	compte_xp += xp
	while compte_niv < Sauvegarde.NIVEAU_COMPTE_MAX and compte_xp >= Sauvegarde.xp_pour_niveau(compte_niv):
		compte_xp -= Sauvegarde.xp_pour_niveau(compte_niv)
		compte_niv += 1
		stamina = maxi(stamina, Sauvegarde.stamina_max_niveau(compte_niv))   # stamina rechargée


## Revenus quotidiens et hebdomadaires gagnés pendant le temps écoulé.
func _revenus() -> void:
	while jours_payes < int(jours):
		jours_payes += 1
		gemmes += int((5 * 13 + 40) * PART_QUETES)           # quêtes du jour + coffre bonus
		or_ += int(4500 * PART_QUETES)
		var c: Dictionary = Quetes.CONNEXION[(jours_payes - 1) % 7]
		gemmes += int(c.get("gemmes", 0))
		or_ += int(c.get("or", 0))
		eclats += int(c.get("eclat_superieur", 0))
	while semaines_payees < int(jours / 7.0):
		semaines_payees += 1
		gemmes += int((5 * 55 + 200) * PART_QUETES)
		eclats += int(round(4 * PART_QUETES))                 # quêtes de la semaine (Éclats) + coffre bonus
		# Comptoir : lot de 10 Éclats puis à l'unité
		if gemmes >= 1000:
			gemmes -= 1000
			eclats += 10
		var n := 0
		while gemmes >= 120 and n < 10:
			gemmes -= 120
			eclats += 1
			n += 1


# =====================================================================
# Gestion entre deux chapitres : invocations, absorption, Échos, Fusion
# =====================================================================
func _gestion() -> void:
	# Récompenses de tutoriel (Premiers pas), une fois
	if nb_victoires > 5 and not deja_termine.has("tuto"):
		deja_termine["tuto"] = true
		gemmes += 180
		eclats += 3
		or_ += 7000
	# Pacte Supérieur
	while eclats >= 1:
		eclats -= 1
		_invoquer_superieur()
	if profil != "regulier":
		_absorption()
		if profil == "occasionnel":
			_equiper_echos()
		else:
			for h in roster:
				h["echos"] = {}
			echos_sac.clear()
		return
	# Pacte Doré (en gardant de quoi absorber et améliorer)
	while or_ >= 4500 + 3000:
		or_ -= 4500
		var tirages: Array = []
		for k in 10:
			var x := rng.randf()
			tirages.append("N" if x < 0.6 else ("R" if x < 0.9 else "SR"))
		if not "SR" in tirages:
			tirages[0] = "SR"
		for r in tirages:
			_ajouter(_tirer(r))
		nb_invoc += 10
	_fusion()
	_absorption()
	_equiper_echos()
	_ameliorer_echos()


func _invoquer_superieur() -> void:
	nb_invoc += 1
	var x := rng.randf()
	var r := "SR"
	if x < 0.003: r = "LEG"
	elif x < 0.028: r = "UR"
	elif x < 0.248: r = "SSR"
	if r == "SR":
		pity += 1
		if pity >= Invocation.GARANTIE_SUPERIEUR:
			r = "SSR"
	if r != "SR":
		pity = 0
	_ajouter(_tirer(r))


func _tirer(r: String) -> String:
	var l: Array = par_rarete[r]
	return l[rng.randi_range(0, l.size() - 1)]


func _ajouter(id: String) -> void:
	roster.append({"uid": prochain_uid, "id": id, "niveau": 1, "xp": 0, "etoiles": 1, "echos": {}, "place": 0})
	prochain_uid += 1


func _rarete(id: String) -> String:
	return Fusion.cle_rarete(id)


func _force(h: Dictionary) -> float:
	return UnitesData.puissance(h["id"], h["niveau"]) * Fusion.multiplicateur(h["etoiles"])


## L'équipe : les 5 plus forts, placés comme dans le jeu (corps à corps devant).
func _equipe() -> Array:
	var tri := roster.duplicate()
	tri.sort_custom(func(a, b): return _force(a) > _force(b))
	var eq := tri.slice(0, 5)
	eq.sort_custom(func(a, b): return Rencontres._ordre_place(a["id"]) < Rencontres._ordre_place(b["id"]))
	for i in eq.size():
		eq[i]["place"] = i
	return eq


## Potentiel d'une unité (niveau 30) : sert à choisir qui monter.
func _potentiel(h: Dictionary) -> float:
	return UnitesData.puissance(h["id"], 30) * Fusion.multiplicateur(h["etoiles"])


## Absorption : les unités N/R (et les SR en trop) nourrissent les meilleures unités en retard.
func _absorption() -> void:
	var tri := roster.duplicate()
	tri.sort_custom(func(a, b): return _potentiel(a) > _potentiel(b))
	var cibles := tri.slice(0, 5)
	var meilleur := 0
	for h in cibles:
		meilleur = maxi(meilleur, h["niveau"])
	var gardes := {}
	for h in cibles:
		gardes[h["uid"]] = true
	for h in cibles:
		while h["niveau"] < meilleur:
			var fodder := -1
			for k in roster.size():
				var f: Dictionary = roster[k]
				if gardes.has(f["uid"]) or not f["echos"].is_empty():
					continue
				var rr := _rarete(f["id"])
				if rr in ["N", "R"] or (rr == "SR" and _potentiel(f) < _potentiel(cibles[-1]) * 0.8):
					fodder = k
					break
			if fodder < 0:
				return
			var f: Dictionary = roster[fodder]
			var xp := int(Fusion.XP_SACRIFICE[_rarete(f["id"])] * (Fusion.BONUS_MEME_UNITE if f["id"] == h["id"] else 1.0))
			var cout := int(xp * Fusion.OR_PAR_XP)
			if or_ < cout:
				return
			or_ -= cout
			roster.remove_at(fodder)
			_xp_heros(h, xp)


## Fusion : les doublons des unités de l'équipe donnent des étoiles.
func _fusion() -> void:
	for h in _equipe():
		while h["etoiles"] < Fusion.ETOILES_MAX:
			var req := int(Fusion.DOUBLONS_REQUIS.get(h["etoiles"], 99))
			if h["niveau"] < int(Fusion.NIVEAU_REQUIS.get(h["etoiles"], 99)):
				break
			var dbl: Array = []
			for f in roster:
				if f["uid"] != h["uid"] and f["id"] == h["id"] and f["echos"].is_empty():
					dbl.append(f)
			var cout: int = int(Fusion.OR_EVEIL[_rarete(h["id"])]) * int(h["etoiles"])
			if dbl.size() < req or or_ < cout:
				break
			or_ -= cout
			for k in req:
				roster.erase(dbl[k])
			h["etoiles"] += 1


func _score_echo(e: Dictionary) -> float:
	return (int(e["rarete"]) + 1.5) * int(e["etoiles"]) * (1.0 + int(e["niveau"]) * 0.12)


func _equiper_echos() -> void:
	var tous: Array = echos_sac.duplicate()
	for h in roster:
		for e in h["echos"].values():
			tous.append(e)
		h["echos"] = {}
	tous.sort_custom(func(a, b): return _score_echo(a) > _score_echo(b))
	var eq := _equipe()
	eq.sort_custom(func(a, b): return _force(a) > _force(b))
	var restants: Array = []
	for e in tous:
		var place := false
		for h in eq:
			if not h["echos"].has(int(e["emplacement"])):
				h["echos"][int(e["emplacement"])] = e
				place = true
				break
		if not place:
			restants.append(e)
	# On garde 30 Échos d'avance au maximum (les autres sont vendus)
	echos_sac = restants.slice(0, 30)
	for e in restants.slice(30):
		or_ += Echos.prix_vente(e)


func _ameliorer_echos() -> void:
	var budget := int(or_ * PART_OR_ECHOS)
	var portes: Array = []
	for h in _equipe():
		portes.append_array(h["echos"].values())
	portes.sort_custom(func(a, b): return _score_echo(a) > _score_echo(b))
	var cible := 12
	var tentatives := 0
	for e in portes:
		while int(e["niveau"]) < cible and tentatives < 400:
			var c := Echos.cout_amelioration(e)
			if c > budget:
				return
			budget -= c
			or_ -= c
			tentatives += 1
			Echos.ameliorer(e, rng)


func _etoiles_moy() -> float:
	var t := 0.0
	var eq := _equipe()
	for h in eq:
		t += h["etoiles"]
	return t / maxf(1, eq.size())


func _echos_moyens() -> String:
	var n := 0
	var niv := 0.0
	var et := 0.0
	for h in _equipe():
		for e in h["echos"].values():
			n += 1
			niv += int(e["niveau"])
			et += int(e["etoiles"])
	if n == 0:
		return "0"
	return "%d portés, ★%.1f, +%.1f" % [n, et / n, niv / n]


# =====================================================================
# Rapport
# =====================================================================
func _rapport(res: Array) -> void:
	var nb := res.size()
	print("\n=== PROGRESSION SIMULÉE (%d joueurs) ===" % nb)
	print("chap. | défaites moy. | max | bloqués(farm) | stamina | niv équipe / attendu | jours | compte | Échos (1er joueur)")
	for acte in range(1, 14):
		for chap in range(1, 7):
			var cle := "%d-%d" % [acte, chap]
			var d := 0.0
			var dmax := 0
			var farm := 0
			var st := 0.0
			var niv := 0.0
			var j := 0.0
			var cpt := 0.0
			for r in res:
				var c: Dictionary = r[cle]
				d += c["defaites"]
				dmax = maxi(dmax, c["defaites"])
				if c["farm"] > 0:
					farm += 1
				st += c["stamina"]
				niv += c["niv"]
				j += c["jours"]
				cpt += c["compte"]
			print("%5s | %6.1f | %3d | %2d/%d | %5.0f | %5.1f / %2d | %5.1f | %4.1f | %s" % [cle, d / nb, dmax, farm, nb,
				st / nb, niv / nb, res[0][cle]["attendu"], j / nb, cpt / nb, res[0][cle]["echos"]])
	# Taux de victoire par type de case (toutes tentatives, PV réels du plateau)
	print("\nTaux de victoire réels par tentative (PV conservés sur le plateau) :")
	print("Acte | combat | élite | gardien | boss chap. | boss Acte | Mimic")
	for acte in range(1, 14):
		var ligne := "%2d  " % acte
		for ty in ["combat", "elite", "gardien", "boss_chapitre", "boss_acte", "mimic"]:
			var v := 0
			var c := 0
			for r in res:
				var t: Dictionary = r["13-6"]["types"]
				var k := "%d-%s" % [acte, ty]
				if t.has(k):
					v += t[k][0]
					c += t[k][1]
			ligne += " | %4s" % ("%d%%" % int(round(100.0 * v / c)) if c > 0 else "-")
		print(ligne)
	var et := ""
	for acte in [3, 6, 9, 12]:
		var s := 0.0
		for r in res:
			s += r["%d-6" % acte]["etoiles"]
		et += "  Acte %d : %.1f" % [acte, s / nb]
	print("\nÉtoiles moyennes de l'équipe (fin d'Acte) :" + et)
	var orl := ""
	for acte in [3, 6, 9, 12, 13]:
		var s := 0.0
		for r in res:
			s += r["%d-6" % acte]["or"]
		orl += "  Acte %d : %d" % [acte, int(s / nb)]
	print("Or en réserve (fin d'Acte) :" + orl)
	print("\nForce de l'équipe / force de l'équipe de référence (chapitre 3 de chaque Acte) : min · 25 % · médiane · max")
	for acte in range(1, 14):
		var l: Array = []
		for r in res:
			l.append(r["%d-3" % acte]["ratio"])
		l.sort()
		print("Acte %2d : %.2f · %.2f · %.2f · %.2f" % [acte, l[0], l[int(l.size() * 0.25)], l[l.size() / 2], l[-1]])
	# Raretés de l'équipe aux Actes clés
	print("\nComposition de l'équipe (début de chaque Acte, % de joueurs ayant au moins N unités de cette rareté)")
	for acte in range(1, 14):
		var cle := "%d-1" % acte
		var ssr := 0.0
		var ur := 0.0
		for r in res:
			for x in r[cle]["raretes"]:
				if x in ["SSR"]:
					ssr += 1
				if x in ["UR", "LEG"]:
					ur += 1
		print("Acte %2d : SSR moy. %.1f · UR/Légende moy. %.1f (référence : %s)" % [acte, ssr / nb, ur / nb, str(Rencontres.EQUIPE_REFERENCE[acte])])
