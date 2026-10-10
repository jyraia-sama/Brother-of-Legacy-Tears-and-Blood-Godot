class_name EcranArenaClassee
extends EcranBase
## ARÈNE CLASSÉE EN TEMPS RÉEL : combats MANUELS contre un autre joueur connecté.
##  - Recherche d'un adversaire (file d'attente, même rang d'abord puis élargie) ou défi d'un ami.
##  - Ton équipe = l'équipe du Deck (niveaux, étoiles et Échos réels).
##  - Points de classement (Elo), rangs Bronze -> Légende, saisons de 4 semaines avec récompenses.
## Serveur : supabase/04_arene_classee.sql. Combat : combat_classe.gd.

const SCENE := "res://scenes/arene_classee.tscn"
const PALIERS := {
	"bronze":  {"nom": "Bronze",  "couleur": Color("b07a4a"), "min": 0},
	"argent":  {"nom": "Argent",  "couleur": Color("c8d0d8"), "min": 1100},
	"or":      {"nom": "Or",      "couleur": Color("ffd060"), "min": 1250},
	"platine": {"nom": "Platine", "couleur": Color("7ae0d0"), "min": 1400},
	"diamant": {"nom": "Diamant", "couleur": Color("7ab0ff"), "min": 1550},
	"legende": {"nom": "Légende", "couleur": Color("ff7a5a"), "min": 1700},
}
const ORDRE := ["bronze", "argent", "or", "platine", "diamant", "legende"]
const RECOMPENSES := {"bronze": "40 gemmes", "argent": "80 gemmes", "or": "150 gemmes + titre « Gladiateur d'Or »",
	"platine": "250 gemmes + titre « Gladiateur de Platine »", "diamant": "400 gemmes + titre « Gladiateur de Diamant »",
	"legende": "600 gemmes + titre « Légende de l'Arène »"}
const ERREURS := {"invalide": "Ton équipe du Deck est vide ou invalide.", "pas_ami": "Ce joueur n'est pas ton ami.",
	"expire": "Ce défi a expiré.", "version": "Vous n'avez pas la même version du jeu : mettez-vous à jour tous les deux.",
	"non_connecte": "Tu n'es pas connecté."}

static var scene_retour_classee := ""

var _etat: Dictionary = {}
var _signature := ""
var _recherche := false
var _debut_recherche := 0
var _info_file := ""
var _amis: Array = []
var _classement: Array = []
var _historique: Array = []
var _occupe := false
var _lance := false
var _lbl_recherche: Label
var _minuterie: Timer
var _tic := 0



func _fond_ecran() -> String:
	return "res://assets/fonds/arene.png"

func _titre_ecran() -> String:
	return "ARÈNE CLASSÉE"


func _couleur() -> Color:
	return Color("ffd060")


func _retour() -> void:
	_quitter_file()
	UiCommun.aller(get_tree(), scene_retour_classee if scene_retour_classee != "" else EcranArene.SCENE)


func _preparer() -> void:
	if not EnLigne.est_connecte():
		return
	_minuterie = Timer.new()
	_minuterie.wait_time = 1.0
	_minuterie.autostart = true
	_minuterie.timeout.connect(_seconde)
	add_child(_minuterie)
	_charger_tout()


func _charger_tout() -> void:
	await _charger_etat()
	var a := await EnLigne.appeler("mes_amis")
	if a.ok and a.data is Array:
		_amis = a.data.filter(func(x): return str(x.get("relation", "")) == "ami")
	var c := await EnLigne.appeler("ac_classement", {"p_limite": 20})
	if c.ok and c.data is Array:
		_classement = c.data
	var h := await EnLigne.appeler("ac_historique")
	if h.ok and h.data is Array:
		_historique = h.data
	if is_inside_tree():
		rafraichir()


func _charger_etat() -> void:
	var r := await EnLigne.appeler("ac_etat")
	if not is_inside_tree():
		return
	if r.ok and r.data is Dictionary:
		_etat = r.data
		var d = _etat.get("defi_envoye")
		# Mon défi a été accepté : le combat commence
		if d is Dictionary and str(d.get("etat", "")) == "acceptee" and _etat.get("match") is Dictionary \
				and str(_etat["match"].get("id", "")) == str(d.get("match", "")):
			_lancer_combat(_etat["match"])
			return
		var sig := JSON.stringify([_etat.get("defis_recus"), d, _etat.get("match") != null, _etat.get("recompenses"), _etat.get("points")])
		if sig != _signature:
			_signature = sig
			rafraichir()
	elif _etat.is_empty():
		_etat = {"erreur": r.erreur if not r.ok else "Réponse inattendue du serveur (as-tu lancé supabase/04_arene_classee.sql ?)."}
		rafraichir()


func _seconde() -> void:
	_tic += 1
	if _occupe or _lance:
		return
	if _recherche:
		if _lbl_recherche != null:
			_lbl_recherche.text = UiCommun.t("Recherche d'un adversaire… %d s%s") % [int((Time.get_ticks_msec() - _debut_recherche) / 1000.0), _info_file]
		if _tic % 2 == 0:
			_chercher()
	elif _tic % 3 == 0:
		_charger_etat()


# =====================================================================
# Affichage
# =====================================================================

func _remplir() -> void:
	_lbl_recherche = null
	if not EnLigne.est_connecte():
		_texte("L'Arène classée se joue en ligne contre d'autres joueurs : connecte-toi à ton compte (Paramètres → Gérer le compte).", 18, UiCommun.C_TEXTE)
		return
	if _etat.is_empty():
		_texte("Chargement…", 18)
		return
	if _etat.has("erreur"):
		_texte(str(_etat["erreur"]), 17, Color("ff7a6a"))
		return
	_bandeau()
	# Récompenses de saison
	var rec: Array = _etat.get("recompenses", [])
	if not rec.is_empty():
		var h := _ligne(Color("ffd060"))
		var t := UiCommun.label("Récompenses de saison à réclamer : " + ", ".join(rec.map(func(x): return UiCommun.t("saison %d (%s)") % [int(x["saison"]), _nom_palier(str(x["palier"]))])), 17, Color("ffd060"))
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		h.add_child(t)
		var b := UiCommun.bouton("Réclamer", 17)
		UiCommun.bouton_vif(b)
		b.pressed.connect(_reclamer)
		h.add_child(b)
	# Combat en cours
	var m = _etat.get("match")
	if m is Dictionary:
		var h2 := _ligne(Color("ff7a5a"))
		var adv: Dictionary = m["j2"] if int(m["mon_camp"]) == 0 else m["j1"]
		var t2 := UiCommun.label(UiCommun.t("Combat en cours contre %s !") % EnLigne.nom_complet(str(adv.get("pseudo", "?"))), 18, Color("ffb070"))
		t2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h2.add_child(t2)
		var b2 := UiCommun.bouton("Reprendre le combat", 17)
		b2.pressed.connect(_lancer_combat.bind(m))
		h2.add_child(b2)
	_zone_recherche()
	_zone_defis()
	var bas := HBoxContainer.new()
	bas.add_theme_constant_override("separation", 14)
	_contenu.add_child(bas)
	bas.add_child(_zone_classement())
	bas.add_child(_zone_regles())


func _bandeau() -> void:
	var pal := str(_etat.get("palier", "bronze"))
	var h := _ligne(PALIERS[pal]["couleur"])
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(vb)
	vb.add_child(UiCommun.label(UiCommun.t("%s  ·  %d points") % [_nom_palier(pal).to_upper(), int(_etat.get("points", 1000))], 28, PALIERS[pal]["couleur"]))
	var suivant := ""
	var i := ORDRE.find(pal)
	if i >= 0 and i < ORDRE.size() - 1:
		suivant = UiCommun.t("   ·   %s à %d points") % [_nom_palier(ORDRE[i + 1]), int(PALIERS[ORDRE[i + 1]]["min"])]
	vb.add_child(UiCommun.label(UiCommun.t("Rang %d   ·   %d victoire(s), %d défaite(s), %d égalité(s)%s") % [int(_etat.get("rang", 0)),
		int(_etat.get("victoires", 0)), int(_etat.get("defaites", 0)), int(_etat.get("egalites", 0)), suivant], 16, UiCommun.C_TEXTE))
	var fin := EnLigne.date_vers_unix(str(_etat.get("fin_saison", ""))) - int(Time.get_unix_time_from_system())
	vb.add_child(UiCommun.label(UiCommun.t("Saison %d — se termine dans %s. Récompense actuelle : %s") % [int(_etat.get("saison", 1)),
		Calendrier.texte_duree(maxi(0, fin)), RECOMPENSES.get(pal, "")], 15, UiCommun.C_DOUX))


func _zone_recherche() -> void:
	var h := _ligne(UiCommun.C_OR)
	var equipe := _equipe()
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 6)
	h.add_child(vb)
	vb.add_child(UiCommun.label(UiCommun.t("TON ÉQUIPE (celle du Deck)  ·  Puissance %s") % _nombre(Arene.puissance(equipe)), 16, UiCommun.C_OR))
	var portraits := HBoxContainer.new()
	portraits.add_theme_constant_override("separation", 8)
	vb.add_child(portraits)
	for u in equipe:
		portraits.add_child(UiCommun.portrait(u["id"], 58))
	var prep := UiCommun.bouton("✎ Préparer mon équipe", 17)
	prep.custom_minimum_size = Vector2(0, 52)
	prep.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	prep.tooltip_text = "Ouvre le Deck pour choisir tes héros et leurs places ; tu reviens ensuite ici."
	prep.disabled = _recherche
	prep.pressed.connect(_preparer_equipe)
	portraits.add_child(prep)
	if equipe.is_empty():
		vb.add_child(UiCommun.label("Ton équipe est vide : prépare-la dans le Deck.", 15, Color("ff7a6a")))
	var droite := VBoxContainer.new()
	droite.add_theme_constant_override("separation", 6)
	h.add_child(droite)
	if _recherche:
		_lbl_recherche = UiCommun.label("Recherche d'un adversaire…", 17, Color("ffd060"))
		droite.add_child(_lbl_recherche)
		var an := UiCommun.bouton("Annuler la recherche", 17)
		an.pressed.connect(func():
			_quitter_file()
			rafraichir())
		droite.add_child(an)
	else:
		var b := UiCommun.bouton("RECHERCHER UN ADVERSAIRE", 20)
		b.custom_minimum_size = Vector2(360, 60)
		b.disabled = equipe.is_empty() or _etat.get("match") is Dictionary
		b.pressed.connect(_demarrer_recherche)
		droite.add_child(b)
		droite.add_child(UiCommun.label(UiCommun.t("Joueurs dans la file : %d") % int(_etat.get("dans_la_file", 0)), 14, UiCommun.C_DOUX))


func _zone_defis() -> void:
	for d in _etat.get("defis_recus", []):
		var h := _ligne(Color("ff7a5a"))
		var t := UiCommun.label(UiCommun.t("%s (%s, %d points) te défie !") % [EnLigne.nom_complet(str(d["de"].get("pseudo", "?"))), _nom_palier(str(d["de"].get("palier", "bronze"))), int(d["de"].get("points", 0))], 18, Color("ffb070"))
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(t)
		var ok := UiCommun.bouton("Accepter", 17)
		ok.pressed.connect(_repondre.bind(str(d["id"]), true))
		h.add_child(ok)
		var non := UiCommun.bouton("Refuser", 15)
		non.pressed.connect(_repondre.bind(str(d["id"]), false))
		h.add_child(non)
	var env = _etat.get("defi_envoye")
	if env is Dictionary and str(env.get("etat", "")) == "attente":
		var h2 := _ligne(Color("ffd060"))
		var t2 := UiCommun.label(UiCommun.t("Défi envoyé à %s… en attente de sa réponse (2 min).") % EnLigne.nom_complet(str(env["a"].get("pseudo", "?"))), 17, Color("ffd060"))
		t2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h2.add_child(t2)
		var an := UiCommun.bouton("Annuler", 15)
		an.pressed.connect(func():
			await EnLigne.appeler("ac_annuler_defi")
			_charger_etat())
		h2.add_child(an)
	elif env is Dictionary and str(env.get("etat", "")) == "refusee":
		_texte(UiCommun.t("%s a refusé ton défi.") % EnLigne.nom_complet(str(env["a"].get("pseudo", "?"))), 15, Color("ff7a6a"))
	# Amis
	_titre("DÉFIER UN AMI (compte pour le classement)", UiCommun.C_OR)
	if _amis.is_empty():
		_texte("Ajoute des amis dans l'écran Social pour les défier.")
		return
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 8)
	_contenu.add_child(g)
	var tries := _amis.duplicate()
	tries.sort_custom(func(a, b): return EnLigne.date_vers_unix(str(a.get("vu_le", ""))) > EnLigne.date_vers_unix(str(b.get("vu_le", ""))))
	for a in tries:
		var en_ligne := EnLigne.est_en_ligne(str(a.get("vu_le", "")))
		var p := PanelContainer.new()
		p.custom_minimum_size = Vector2(380, 0)
		var st := UiCommun.style_panneau(Color("8fe07a") if en_ligne else Color(0.35, 0.3, 0.3), Color(0.07, 0.03, 0.04, 0.92))
		st.set_content_margin_all(8)
		p.add_theme_stylebox_override("panel", st)
		g.add_child(p)
		var hh := HBoxContainer.new()
		hh.add_theme_constant_override("separation", 8)
		p.add_child(hh)
		var t := UiCommun.label("%s\n%s" % [EnLigne.nom_complet(str(a.get("pseudo", "?"))), EnLigne.texte_presence(str(a.get("vu_le", "")))], 15,
			Color("8fe07a") if en_ligne else UiCommun.C_DOUX)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hh.add_child(t)
		var b := UiCommun.bouton("Défier", 15)
		b.disabled = not en_ligne or _recherche or _equipe().is_empty()
		b.tooltip_text = "" if en_ligne else "Ton ami doit être connecté au jeu."
		b.pressed.connect(_defier.bind(str(a["id"]), str(a.get("pseudo", ""))))
		hh.add_child(b)


func _zone_classement() -> Control:
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 3)
	vb.add_child(UiCommun.label("CLASSEMENT DE LA SAISON", 18, UiCommun.C_OR))
	if _classement.is_empty():
		vb.add_child(UiCommun.label("Personne n'a encore combattu cette saison.", 14, UiCommun.C_DOUX))
	for i in _classement.size():
		var x: Dictionary = _classement[i]
		var moi := str(x.get("pseudo", "")) == EnLigne.pseudo()
		vb.add_child(UiCommun.label(UiCommun.t("%d.  %s — %d pts (%s)  ·  %dV / %dD") % [i + 1, EnLigne.nom_complet(str(x.get("pseudo", "?"))), int(x.get("points", 0)),
			_nom_palier(str(x.get("palier", "bronze"))), int(x.get("victoires", 0)), int(x.get("defaites", 0))], 15,
			Color("ffd060") if moi else PALIERS.get(str(x.get("palier", "bronze")), PALIERS["bronze"])["couleur"]))
	if not _historique.is_empty():
		vb.add_child(HSeparator.new())
		vb.add_child(UiCommun.label("TES DERNIERS COMBATS", 18, UiCommun.C_OR))
		for x in _historique.slice(0, 8):
			var res := str(x.get("resultat", ""))
			var dl = x.get("delta")
			vb.add_child(UiCommun.label(UiCommun.t("%s contre %s  (%s)%s") % [{"victoire": "Victoire", "defaite": "Défaite", "egalite": "Égalité"}.get(res, res),
				EnLigne.nom_complet(str(x.get("adversaire", "?"))), ("+" if dl != null and int(dl) >= 0 else "") + str(dl if dl != null else "?"),
				"  · forfait" if x.get("forfait", false) else ""], 14,
				Color("8fe07a") if res == "victoire" else (Color("ff7a6a") if res == "defaite" else UiCommun.C_DOUX)))
	return vb


func _zone_regles() -> Control:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(520, 0)
	var st := UiCommun.style_panneau(UiCommun.C_OR.darkened(0.4), Color(0.06, 0.03, 0.03, 0.9))
	st.set_content_margin_all(12)
	p.add_theme_stylebox_override("panel", st)
	var t := UiCommun.label("""RÈGLES
• Combat MANUEL : quand c'est au tour d'une de tes unités (ordre de Vitesse), choisis Attaque ou un sort, puis la cible. 15 secondes, sinon l'unité agit toute seule.
• Les sorts ne se déclenchent plus au hasard : après usage, ils se rechargent quelques tours (le chiffre entre parenthèses).
• Les corps à corps visent l'Avant tant qu'il reste quelqu'un devant ; la Provocation force la cible.
• 20 tours maximum : ensuite, celui qui a gardé le plus de PV (en pourcentage) gagne.
• Points : +16 environ contre un adversaire de même niveau, plus contre un plus fort. Quitter le combat = défaite par forfait au bout d'une minute.
• Saison de 4 semaines ; au changement de saison, tu gagnes la récompense de ton rang et tes points se rapprochent de 1000.
• Les deux joueurs doivent avoir la même version du jeu.""", 14, UiCommun.C_TEXTE)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.add_child(t)
	return p


func _nom_palier(p: String) -> String:
	return PALIERS.get(p, PALIERS["bronze"])["nom"]


# =====================================================================
# Actions
# =====================================================================

func _equipe() -> Array:
	var e: Array = []
	for u in Arene.equipe_attaque():
		var c: Dictionary = u.duplicate()
		c.erase("uid")
		e.append(c)
	return e


## Va préparer l'équipe dans le Deck, puis revient dans l'Arène classée.
func _preparer_equipe() -> void:
	_quitter_file()
	EcranDeck.scene_retour = SCENE
	get_tree().change_scene_to_file(EcranDeck.SCENE)


func _demarrer_recherche() -> void:
	if _equipe().is_empty():
		return
	_recherche = true
	_debut_recherche = Time.get_ticks_msec()
	_info_file = ""
	rafraichir()
	_chercher()


func _chercher() -> void:
	if _occupe or not _recherche:
		return
	_occupe = true
	var r := await EnLigne.appeler("ac_chercher", {"p_equipe": _equipe(), "p_version": Version.NUMERO})
	_occupe = false
	if not is_inside_tree() or not _recherche:
		return
	if r.ok and r.data is Dictionary:
		var d: Dictionary = r.data
		if not d.get("ok", false):
			_recherche = false
			_erreur(ERREURS.get(str(d.get("erreur", "")), str(d.get("erreur", ""))))
			rafraichir()
			return
		if d.get("match") is Dictionary:
			_recherche = false
			_lancer_combat(d["match"])
			return
		var n := int(d.get("dans_la_file", 1)) - 1
		_info_file = UiCommun.t("  ·  %d autre(s) joueur(s) cherche(nt)") % n if n > 0 else "  ·  personne d'autre pour l'instant"


func _quitter_file() -> void:
	if _recherche:
		_recherche = false
		EnLigne.appeler("ac_quitter_file")


func _defier(id_ami: String, pseudo: String) -> void:
	var r := await EnLigne.appeler("ac_defier", {"p_ami": id_ami, "p_equipe": _equipe(), "p_version": Version.NUMERO})
	if r.ok and str(r.data) == "ok":
		_annoncer([UiCommun.t("Défi envoyé à %s !") % EnLigne.nom_complet(pseudo)])
		_charger_etat()
	else:
		_erreur(ERREURS.get(str(r.data), r.erreur if not r.ok else str(r.data)))


func _repondre(id_defi: String, accepter: bool) -> void:
	var r := await EnLigne.appeler("ac_repondre_defi", {"p_defi": id_defi, "p_accepter": accepter,
		"p_equipe": _equipe(), "p_version": Version.NUMERO})
	if r.ok and r.data is Dictionary and r.data.get("ok", false):
		if r.data.get("match") is Dictionary:
			_lancer_combat(r.data["match"])
			return
		_charger_etat()
	else:
		_erreur(ERREURS.get(str(r.data.get("erreur", "")) if r.data is Dictionary else "", r.erreur if not r.ok else "Défi impossible."))
		_charger_etat()


func _reclamer() -> void:
	var r := await EnLigne.appeler("ac_reclamer")
	if r.ok and r.data is Array:
		var l: Array = []
		for x in r.data:
			var g := int(x.get("gemmes", 0))
			Sauvegarde.ajouter_gemmes(g)
			l.append(UiCommun.t("Saison %d (%s) : +%d gemmes") % [int(x["saison"]), _nom_palier(str(x["palier"])), g])
			if str(x.get("titre", "")) != "":
				Succes.ajouter_titre(str(x["titre"]))
				l.append(UiCommun.t("Nouveau titre : « %s »") % x["titre"])
		Sauvegarde.sauvegarder()
		_annoncer(l)
	_signature = ""
	_charger_etat()


func _lancer_combat(m: Dictionary) -> void:
	if _lance:
		return
	if str(m.get("version", Version.NUMERO)) != Version.NUMERO:
		_erreur(ERREURS["version"])
		return
	_lance = true
	EcranCombat.demande = {
		"mode": "classee", "match": m, "mon_camp": int(m["mon_camp"]),
		"equipe": Arene.nettoyer(m["equipe1"]), "ennemis": Arene.nettoyer(m["equipe2"]),
		"graine": int(m["graine"]), "tours_max": 20, "acte": 12, "retour": SCENE,
	}
	get_tree().change_scene_to_file(EcranCombat.SCENE)
