class_name EcranMarche
extends Control
## LA MARCHE MAUDITE : choix de l'équipe, carte à embranchements, choix (bénédictions,
## événements, marchand, feu de camp, autel, recrues), fin de marche et classement du jour.
## Règles : voir marche.gd.

const SCENE := "res://scenes/marche.tscn"
const C_SANG := Color("d04a3a")
const C_OK := Color("8affa0")
const COULEURS_CASE := {
	"combat": Color("c8b8b0"), "elite": Color("ff9a3a"), "boss": Color("ff3a3a"), "evenement": Color("7ab8ff"),
	"feu": Color("ffd060"), "marchand": Color("8affa0"), "tresor": Color("ffe070"), "autel": Color("d02a4a"),
}

static var scene_retour := ""

var _choix: Array = []          # uids choisis avant le départ
var _contenu: Control
var _lbl_haut: Label
var _calque: Control            # fenêtres de choix
var _occupe := false            # appel au serveur en cours


func _ready() -> void:
	Sauvegarde.charger()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var noir := ColorRect.new()
	noir.color = Color("0a0506")
	noir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(noir)
	var region := int(Marche.partie().get("region", 0))
	if not UiCommun.fond_image(self, "res://assets/plateaux/fond_%02d.png" % int(Marche.actes_du_jour()[region]), Color(0.32, 0.26, 0.26)):
		UiCommun.fond_degrade(self, Color("2a0a0a"), Color("050203"))
	UiCommun.particules(self, C_SANG, true, 30)

	var marge := MarginContainer.new()
	marge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for c in ["left", "right", "top", "bottom"]:
		marge.add_theme_constant_override("margin_" + c, 18)
	add_child(marge)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	marge.add_child(col)

	var tete := HBoxContainer.new()
	tete.add_theme_constant_override("separation", 14)
	col.add_child(tete)
	var retour := UiCommun.bouton("← Expéditions")
	retour.pressed.connect(_retour)
	tete.add_child(retour)
	tete.add_child(UiCommun.label("LA MARCHE MAUDITE", 30, C_SANG.lightened(0.25)))
	_lbl_haut = UiCommun.label("", 17, UiCommun.C_TEXTE)
	_lbl_haut.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl_haut.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tete.add_child(_lbl_haut)
	var cl := UiCommun.bouton("Classement du jour", 15)
	cl.pressed.connect(_afficher_classement.bind(0))
	tete.add_child(cl)
	if Marche.en_cours():
		var ab := UiCommun.bouton("Abandonner", 15)
		ab.pressed.connect(_confirmer_abandon)
		tete.add_child(ab)

	_contenu = Control.new()
	_contenu.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_contenu)

	_calque = Control.new()
	_calque.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_calque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_calque)
	_rafraichir()
	# Score d'une marche finie pas encore envoyé au classement
	var p := Marche.partie()
	if p.get("etat", "") == "finie" and p.get("classee", false) and not p["resultat"].get("envoye", false):
		_envoyer_score()


func _rafraichir() -> void:
	for e in _contenu.get_children():
		e.queue_free()
	for e in _calque.get_children():
		e.queue_free()
	var p := Marche.partie()
	if Marche.en_cours():
		_lbl_haut.text = "Région %d / %d : %s   ·   Score %d   ·   Or de marche %d%s" % [int(p["region"]) + 1, Marche.REGIONS,
			Marche.nom_region(int(p["region"])), int(p["score"]), int(p["or"]),
			("   ·   Gloire +%d %%" % int(float(p["gloire"]) * 100)) if float(p["gloire"]) > 0 else ""]
		_ecran_carte()
		_afficher_attente()
	elif p.get("etat", "") == "finie":
		_lbl_haut.text = "Nouvelle marche dans %s" % Calendrier.texte_duree(Calendrier.secondes_avant_demain())
		_ecran_fin()
	else:
		_lbl_haut.text = "Record personnel : %d" % Marche.record()
		_ecran_depart()


func _panneau(taille_min := Vector2.ZERO) -> VBoxContainer:
	var pc := PanelContainer.new()
	pc.custom_minimum_size = taille_min
	pc.add_theme_stylebox_override("panel", UiCommun.style_panneau(C_SANG.darkened(0.35), Color(0.06, 0.02, 0.03, 0.92)))
	var d := ScrollContainer.new()
	d.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pc.add_child(d)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 8)
	d.add_child(vb)
	pc.set_meta("vb", vb)
	return vb


func _envelopper(vb: VBoxContainer) -> PanelContainer:
	return vb.get_parent().get_parent() as PanelContainer


# =====================================================================
# Départ : l'équipe
# =====================================================================

func _ecran_depart() -> void:
	var h := HBoxContainer.new()
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.add_theme_constant_override("separation", 14)
	_contenu.add_child(h)

	var g := _panneau(Vector2(600, 0))
	h.add_child(_envelopper(g))
	g.add_child(UiCommun.label("LA MARCHE DU JOUR", 20, UiCommun.C_OR))
	for r in Marche.REGIONS:
		var a: Dictionary = ActesData.get_acte(int(Marche.actes_du_jour()[r]))
		var ligne := HBoxContainer.new()
		ligne.add_theme_constant_override("separation", 10)
		ligne.add_child(UiCommun.portrait(Rencontres.POOLS[int(a["numero"])]["boss"], 56))
		var vb := VBoxContainer.new()
		vb.add_child(UiCommun.label("Région %d — %s" % [r + 1, a["titre"]], 17, UiCommun.C_TEXTE))
		vb.add_child(UiCommun.label("Boss : " + UnitesData.get_unite(Rencontres.POOLS[int(a["numero"])]["boss"])["nom"], 13, UiCommun.C_DOUX))
		ligne.add_child(vb)
		g.add_child(ligne)
	g.add_child(HSeparator.new())
	for t in ["Choisis jusqu'à 5 unités. Leurs PV et leurs K.O. sont conservés pendant toute la marche.",
		"Sur la carte, choisis ta route : ⚔ combat, ☠ élite, ? événement, ✧ feu de camp, $ marchand, ◆ trésor, ✚ autel de sang, ♛ boss.",
		"Après chaque victoire, choisis une Bénédiction. Les élites vaincues proposent parfois de rejoindre ta marche.",
		"Aux autels, les Pactes de Sang offrent une grosse récompense et de la gloire… contre une malédiction.",
		"Les ennemis s'adaptent à la force de l'équipe choisie : ce sont tes choix qui font le score.",
		"Une seule marche par jour, la même pour tous. Score → Sceaux de Marche et classement du jour."]:
		var l := UiCommun.label("•  " + t, 14, UiCommun.C_TEXTE)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		g.add_child(l)

	var d := _panneau()
	_envelopper(d).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(_envelopper(d))
	if Marche.deja_jouee():
		d.add_child(UiCommun.label("Tu as déjà fait la Marche du jour.", 18, UiCommun.C_OR))
		return
	d.add_child(UiCommun.label("TON ÉQUIPE  (%d / %d)" % [_choix.size(), Marche.TAILLE_EQUIPE], 18, UiCommun.C_OR))
	var places := HBoxContainer.new()
	places.add_theme_constant_override("separation", 8)
	d.add_child(places)
	for k in Marche.TAILLE_EQUIPE:
		if k < _choix.size():
			var carte := UiCommun.carte_heros(Sauvegarde.get_heros(int(_choix[k])), 120, 160)
			carte.pressed.connect(_basculer.bind(int(_choix[k])))
			places.add_child(carte)
		else:
			var vide := Button.new()
			vide.custom_minimum_size = Vector2(120, 160)
			vide.text = "+"
			vide.disabled = true
			vide.add_theme_font_size_override("font_size", 30)
			places.add_child(vide)
	var boutons := HBoxContainer.new()
	boutons.add_theme_constant_override("separation", 10)
	d.add_child(boutons)
	var eq := UiCommun.bouton("Prendre mon équipe", 15)
	eq.pressed.connect(func():
		_choix = Sauvegarde.get_equipe().duplicate()
		_rafraichir())
	boutons.add_child(eq)
	var go := UiCommun.bouton("COMMENCER LA MARCHE", 20)
	go.custom_minimum_size = Vector2(0, 50)
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	go.disabled = _choix.is_empty()
	go.pressed.connect(_commencer)
	boutons.add_child(go)
	if not EnLigne.est_connecte():
		d.add_child(UiCommun.label("Tu n'es pas connecté : ta marche ne sera pas classée (mais tu gagnes tes Sceaux).", 13, Color("ffb070")))
	d.add_child(HSeparator.new())
	var grille := GridContainer.new()
	grille.columns = 8
	grille.add_theme_constant_override("h_separation", 8)
	grille.add_theme_constant_override("v_separation", 8)
	d.add_child(grille)
	var liste: Array = Sauvegarde.liste_heros().duplicate()
	liste.sort_custom(func(a, b): return Marche.puissance_unite({"uid": int(a["uid"])}) > Marche.puissance_unite({"uid": int(b["uid"])}))
	for hh in liste:
		var uid := int(hh["uid"])
		var carte := UiCommun.carte_heros(hh, 112, 150)
		if uid in _choix:
			carte.add_theme_stylebox_override("normal", UiCommun.style_carte(C_SANG, 0.08, 4))
			UiCommun.badge(carte, "Choisie", C_SANG)
		if not Sauvegarde.est_occupe(uid):
			carte.pressed.connect(_basculer.bind(uid))
		grille.add_child(carte)


func _basculer(uid: int) -> void:
	if uid in _choix:
		_choix.erase(uid)
	elif _choix.size() < Marche.TAILLE_EQUIPE:
		_choix.append(uid)
	else:
		Audio.son("erreur")
		return
	Audio.son("clic")
	_rafraichir()


func _commencer() -> void:
	if _occupe:
		return
	var classee := false
	if EnLigne.est_connecte() and not Sauvegarde.admin("marche_illimitee"):
		_occupe = true
		var r: Dictionary = await EnLigne.appeler("marche_commencer")
		_occupe = false
		if r.ok and r.data is Dictionary and r.data.get("ok", false):
			classee = true
		elif r.ok and r.data is Dictionary and r.data.get("erreur", "") == "deja_jouee":
			_message("Marche du jour", "Tu as déjà commencé la Marche du jour (sur ce compte).\nReviens demain !")
			return
		else:
			_message("Marche non classée", "Le serveur ne répond pas : ta marche ne sera pas classée aujourd'hui.")
	var raison := Marche.commencer(_choix, classee)
	if raison != "":
		_message("Impossible", raison)
		return
	Audio.son("cercle")
	get_tree().reload_current_scene()


# =====================================================================
# En cours : la carte
# =====================================================================

func _ecran_carte() -> void:
	var p := Marche.partie()
	var h := HBoxContainer.new()
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.add_theme_constant_override("separation", 14)
	_contenu.add_child(h)

	var pc := PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pc.add_theme_stylebox_override("panel", UiCommun.style_panneau(C_SANG.darkened(0.35), Color(0.04, 0.01, 0.02, 0.8)))
	h.add_child(pc)
	var carte := CarteMarche.new()
	carte.ecran = self
	pc.add_child(carte)

	var d := _panneau(Vector2(560, 0))
	h.add_child(_envelopper(d))
	d.add_child(UiCommun.label("ÉQUIPE", 17, UiCommun.C_OR))
	for m in p["equipe"]:
		d.add_child(_ligne_membre(m))
	d.add_child(HSeparator.new())
	d.add_child(UiCommun.label("BÉNÉDICTIONS  (%d)" % p["benedictions"].size(), 17, UiCommun.C_OR))
	if p["benedictions"].is_empty():
		d.add_child(UiCommun.label("Aucune pour l'instant.", 13, UiCommun.C_DOUX))
	var flux := HFlowContainer.new()
	flux.add_theme_constant_override("h_separation", 6)
	flux.add_theme_constant_override("v_separation", 6)
	d.add_child(flux)
	for id in p["benedictions"]:
		var b: Dictionary = Marche.BENEDICTIONS[id]
		flux.add_child(_pastille(b["nom"], Color("#" + Marche.COULEURS_RARETE[b["rarete"]]), b["desc"]))
	if not p["maledictions"].is_empty():
		d.add_child(UiCommun.label("MALÉDICTIONS", 17, C_SANG))
		var fm := HFlowContainer.new()
		fm.add_theme_constant_override("h_separation", 6)
		d.add_child(fm)
		for id in p["maledictions"]:
			var m: Dictionary = Marche.MALEDICTIONS[id]
			fm.add_child(_pastille(m["nom"], C_SANG, m["desc"]))
	d.add_child(HSeparator.new())
	d.add_child(UiCommun.label("JOURNAL", 15, UiCommun.C_OR))
	var j: Array = p["journal"]
	for k in range(maxi(0, j.size() - 7), j.size()):
		var l := UiCommun.label("•  " + str(j[k]), 13, UiCommun.C_DOUX)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.add_child(l)


func _ligne_membre(m: Dictionary) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var pt := UiCommun.portrait(m["id"], 50)
	var ko := float(m["pv"]) <= 0.0
	if ko:
		pt.modulate = Color(0.4, 0.4, 0.4)
	h.add_child(pt)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(vb)
	var u := UnitesData.get_unite(m["id"])
	vb.add_child(UiCommun.label("%s  Nv %d%s" % [u["nom"], int(m["niveau"]), "   (recrue)" if m.get("recrue", false) else ""], 15,
		UiCommun.C_DOUX if ko else UiCommun.C_TEXTE))
	var barre := UiCommun.barre(Color("5ad06a") if float(m["pv"]) > 0.5 else (Color("e0c040") if float(m["pv"]) > 0.25 else C_SANG), 300, 9)
	barre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	barre.max_value = 100
	barre.value = float(m["pv"]) * 100
	vb.add_child(barre)
	var t := UiCommun.label("K.O." if ko else "%d %% PV" % int(round(float(m["pv"]) * 100)), 13, C_SANG if ko else UiCommun.C_DOUX)
	h.add_child(t)
	return h


func _pastille(texte: String, c: Color, info: String) -> Label:
	var l := UiCommun.label(texte, 13, Color.BLACK)
	l.mouse_filter = Control.MOUSE_FILTER_STOP
	l.tooltip_text = info
	var st := StyleBoxFlat.new()
	st.bg_color = c
	st.set_corner_radius_all(5)
	st.content_margin_left = 7
	st.content_margin_right = 7
	st.content_margin_top = 2
	st.content_margin_bottom = 2
	l.add_theme_stylebox_override("normal", st)
	return l


## Clic sur une case atteignable de la carte.
func aller_sur(index: int) -> void:
	var t := Marche.avancer(index)
	if t == "":
		return
	Audio.son("clic")
	_rafraichir()


# =====================================================================
# Fenêtres de choix
# =====================================================================

func _fenetre(titre: String, couleur := UiCommun.C_OR, largeur := 900.0) -> VBoxContainer:
	var voile := ColorRect.new()
	voile.color = Color(0, 0, 0, 0.6)
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_calque.add_child(voile)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_calque.add_child(centre)
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(largeur, 0)
	p.add_theme_stylebox_override("panel", UiCommun.style_panneau(couleur, Color(0.07, 0.02, 0.03, 0.97)))
	centre.add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	p.add_child(vb)
	var t := UiCommun.label(titre, 28, couleur)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	return vb


func _texte(vb: VBoxContainer, texte: String, taille := 16, c := UiCommun.C_TEXTE) -> void:
	var l := UiCommun.label(texte, taille, c)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(l)


func _bouton_choix(vb: Control, texte: String, action: Callable, actif := true) -> Button:
	var b := UiCommun.bouton(texte, 17)
	b.custom_minimum_size = Vector2(0, 46)
	b.disabled = not actif
	b.pressed.connect(func():
		Audio.son("clic")
		action.call())
	vb.add_child(b)
	return b


func _afficher_attente() -> void:
	var a: Dictionary = Marche.partie()["attente"]
	match str(a.get("type", "")):
		"combat":
			_fenetre_combat(a)
		"benediction":
			_fenetre_benedictions(a)
		"recrue":
			_fenetre_recrue(a)
		"evenement":
			_fenetre_evenement(a)
		"feu":
			_fenetre_feu()
		"marchand":
			_fenetre_marchand(a)
		"autel":
			_fenetre_autel(a)


func _fenetre_combat(a: Dictionary) -> void:
	var type: String = a.get("combat", "combat")
	var vb := _fenetre({"combat": "COMBAT", "elite": "COMBAT D'ÉLITE", "boss": "BOSS DE LA RÉGION"}[type],
		COULEURS_CASE[type])
	var ennemis := Marche.ennemis(type)
	var ligne := HBoxContainer.new()
	ligne.alignment = BoxContainer.ALIGNMENT_CENTER
	ligne.add_theme_constant_override("separation", 16)
	vb.add_child(ligne)
	for e in ennemis:
		var c := VBoxContainer.new()
		c.add_child(UiCommun.portrait(e["id"], 84 if (e.get("boss", false) or e.get("elite", false)) else 64))
		var n := UiCommun.label(str(e.get("nom", UnitesData.get_unite(e["id"])["nom"])), 13, UiCommun.C_TEXTE)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.custom_minimum_size = Vector2(120, 0)
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		c.add_child(n)
		ligne.add_child(c)
	_texte(vb, "Niveau %d   ·   Les PV de ton équipe sont conservés après le combat." % int(ennemis[0]["niveau"]), 14, UiCommun.C_DOUX)
	if "saignee" in Marche.partie()["maledictions"]:
		_texte(vb, "Saignée : ton équipe perdra 8 % de ses PV au début du combat.", 14, C_SANG)
	_bouton_choix(vb, "⚔  COMBATTRE", func():
		EcranCombat.demande = Marche.demande_combat()
		Sauvegarde.sauvegarder()
		get_tree().change_scene_to_file(EcranCombat.SCENE))


func _fenetre_benedictions(a: Dictionary) -> void:
	var titre := "CHOISIS UNE BÉNÉDICTION" if int(a.get("restants", 1)) <= 1 else "CHOISIS %d BÉNÉDICTIONS" % int(a["restants"])
	var vb := _fenetre(titre, Color("#" + Marche.COULEURS_RARETE[a["rarete"]]), 1100)
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 14)
	vb.add_child(ligne)
	for i in a["offres"].size():
		var b: Dictionary = Marche.BENEDICTIONS[a["offres"][i]]
		var c := Color("#" + Marche.COULEURS_RARETE[b["rarete"]])
		var bt := Button.new()
		bt.focus_mode = Control.FOCUS_NONE
		bt.custom_minimum_size = Vector2(340, 220)
		bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var st := UiCommun.style_carte(c, 0.0, 3)
		st.bg_color = c.darkened(0.82)
		var sh := st.duplicate() as StyleBoxFlat
		sh.bg_color = c.darkened(0.65)
		sh.shadow_color = Color(c, 0.5)
		sh.shadow_size = 12
		bt.add_theme_stylebox_override("normal", st)
		bt.add_theme_stylebox_override("hover", sh)
		bt.add_theme_stylebox_override("pressed", sh)
		var v := VBoxContainer.new()
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.offset_left = 14
		v.offset_right = -14
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_theme_constant_override("separation", 10)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bt.add_child(v)
		var rar := UiCommun.label({"commune": "Commune", "rare": "Rare", "epique": "Épique"}[b["rarete"]].to_upper(), 13, c)
		rar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(rar)
		var n := UiCommun.label(b["nom"], 22, c.lightened(0.3))
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(n)
		var d := UiCommun.label(b["desc"], 15, UiCommun.C_TEXTE)
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(d)
		bt.pressed.connect(func():
			Audio.son("carte")
			Marche.choisir_benediction(i)
			_rafraichir())
		ligne.add_child(bt)
	var passer := UiCommun.bouton("Ne rien prendre", 14)
	passer.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	passer.pressed.connect(func():
		Marche.choisir_benediction(-1)
		_rafraichir())
	vb.add_child(passer)


func _fenetre_recrue(a: Dictionary) -> void:
	var u: Dictionary = a["unite"]
	var info := UnitesData.get_unite(u["id"])
	var vb := _fenetre("UNE RECRUE", Color("ff9a3a"))
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 16)
	vb.add_child(h)
	h.add_child(UiCommun.portrait(u["id"], 110))
	var v := VBoxContainer.new()
	v.add_child(UiCommun.label(info["nom"], 24, Color("ffb070")))
	v.add_child(UiCommun.label("%s · %s · %s · Niveau %d" % [info["rarete"], UnitesData.ELEMENTS[info["element"]], UnitesData.ROLES[info["role"]], int(u["niveau"])], 15, UiCommun.C_DOUX))
	v.add_child(UiCommun.label("Puissance : %d" % int(Marche.puissance_unite(u)), 15, UiCommun.C_TEXTE))
	h.add_child(v)
	_texte(vb, "Cette unité propose de rejoindre ta marche (jusqu'à la fin de la marche seulement).\nChoisis l'unité qu'elle remplace :", 15)
	var grille := GridContainer.new()
	grille.columns = 5
	grille.add_theme_constant_override("h_separation", 8)
	vb.add_child(grille)
	var p := Marche.partie()
	for i in p["equipe"].size():
		var m: Dictionary = p["equipe"][i]
		var ko := float(m["pv"]) <= 0.0
		var b := UiCommun.bouton("%s\n%s" % [UnitesData.get_unite(m["id"])["nom"], "K.O." if ko else "%d %% PV" % int(float(m["pv"]) * 100)], 13)
		b.custom_minimum_size = Vector2(160, 60)
		b.pressed.connect(func():
			Marche.recruter(i)
			_rafraichir())
		grille.add_child(b)
	var non := UiCommun.bouton("Refuser", 15)
	non.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	non.pressed.connect(func():
		Marche.recruter(-1)
		_rafraichir())
	vb.add_child(non)


func _fenetre_evenement(a: Dictionary) -> void:
	var evt: Dictionary = Marche.EVENEMENTS[a["id"]]
	var vb := _fenetre(str(evt["titre"]).to_upper(), Color("7ab8ff"))
	_texte(vb, evt["texte"], 17)
	var p := Marche.partie()
	for i in evt["choix"].size():
		var c: Dictionary = evt["choix"][i]
		var possible := int(c.get("cout_or", 0)) <= int(p["or"])
		_bouton_choix(vb, c["texte"], func():
			var lignes := Marche.choisir_evenement(i)
			_resultat_puis_suite(lignes), possible)


func _fenetre_feu() -> void:
	var vb := _fenetre("FEU DE CAMP", Color("ffd060"))
	_texte(vb, "Les flammes crépitent. Ton équipe peut souffler un instant… ou se préparer à ce qui l'attend.", 16)
	var repos := 17 if "sans_repos" in Marche.partie()["maledictions"] else 35
	_bouton_choix(vb, "Se reposer : l'équipe récupère %d %% de ses PV" % repos, func():
		_resultat_puis_suite(Marche.feu_de_camp("repos")))
	_bouton_choix(vb, "S'entraîner : choisis une Bénédiction commune", func():
		Marche.feu_de_camp("entrainement")
		_rafraichir())
	_bouton_choix(vb, "Rite de sang : −20 % PV à toute l'équipe, Bénédiction rare", func():
		Marche.feu_de_camp("rite")
		_rafraichir())


func _fenetre_marchand(a: Dictionary) -> void:
	var vb := _fenetre("LE MARCHAND AMBULANT", Color("8affa0"), 1000)
	var p := Marche.partie()
	_texte(vb, "« Tout se vend, voyageur. Même l'espoir. »   —   Or de marche : %d" % int(p["or"]), 16)
	for i in a["offres"].size():
		var o: Dictionary = a["offres"][i]
		var ligne := HBoxContainer.new()
		ligne.add_theme_constant_override("separation", 10)
		vb.add_child(ligne)
		var l := UiCommun.label(Marche.texte_offre(o), 15, UiCommun.C_TEXTE)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ligne.add_child(l)
		var deja: bool = i in a["achetes"]
		var b := UiCommun.bouton("Acheté" if deja else "%d or" % int(o["prix"]), 15)
		b.custom_minimum_size = Vector2(120, 40)
		b.disabled = deja or int(p["or"]) < int(o["prix"])
		b.pressed.connect(func():
			var r := Marche.acheter(i)
			if r != "":
				Audio.son("erreur")
				_message("Marchand", r)
			else:
				Audio.son("or")
			_rafraichir())
		ligne.add_child(b)
	_bouton_choix(vb, "Reprendre la route", func():
		Marche.quitter_lieu()
		_rafraichir())


func _fenetre_autel(a: Dictionary) -> void:
	var vb := _fenetre("AUTEL DE SANG", C_SANG, 1000)
	_texte(vb, "Le sang séché sur la pierre murmure des promesses. Chaque pacte apporte une malédiction… et de la gloire (+%d %% de score)." % int(Marche.GLOIRE_PACTE * 100), 16)
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 14)
	vb.add_child(ligne)
	for i in a["pactes"].size():
		var pa: Dictionary = a["pactes"][i]
		var m: Dictionary = Marche.MALEDICTIONS[pa["malediction"]]
		var bt := Button.new()
		bt.focus_mode = Control.FOCUS_NONE
		bt.custom_minimum_size = Vector2(0, 200)
		bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var st := UiCommun.style_carte(C_SANG, 0.0, 3)
		st.bg_color = C_SANG.darkened(0.85)
		var sh := st.duplicate() as StyleBoxFlat
		sh.bg_color = C_SANG.darkened(0.7)
		bt.add_theme_stylebox_override("normal", st)
		bt.add_theme_stylebox_override("hover", sh)
		bt.add_theme_stylebox_override("pressed", sh)
		var v := VBoxContainer.new()
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.offset_left = 14
		v.offset_right = -14
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_theme_constant_override("separation", 8)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bt.add_child(v)
		for t in [["PACTE DE %s" % str(m["nom"]).to_upper(), 20, C_SANG.lightened(0.35)],
			["Malédiction : " + m["desc"], 15, Color("ff9a8a")],
			["Récompense : " + Marche.RECOMPENSES_PACTE[pa["recompense"]], 15, C_OK]]:
			var l := UiCommun.label(t[0], t[1], t[2])
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			v.add_child(l)
		bt.pressed.connect(func():
			Audio.son("boss_rugit")
			_resultat_puis_suite(Marche.pacte(i)))
		ligne.add_child(bt)
	_bouton_choix(vb, "Refuser tout pacte", func():
		_resultat_puis_suite(Marche.pacte(-1)))


## Affiche le résultat d'un choix, puis la suite (nouveau choix ou retour à la carte).
func _resultat_puis_suite(lignes: Array) -> void:
	for e in _calque.get_children():
		e.queue_free()
	if lignes.is_empty():
		_rafraichir()
		return
	var vb := _fenetre("RÉSULTAT", UiCommun.C_OR, 700)
	for l in lignes:
		_texte(vb, str(l), 17)
	_bouton_choix(vb, "Continuer", func(): _rafraichir())


# =====================================================================
# Fin de marche et classement
# =====================================================================

func _ecran_fin() -> void:
	var p := Marche.partie()
	var r: Dictionary = p["resultat"]
	var h := HBoxContainer.new()
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.add_theme_constant_override("separation", 14)
	_contenu.add_child(h)
	var g := _panneau(Vector2(760, 0))
	h.add_child(_envelopper(g))
	g.add_child(UiCommun.label("MARCHE ACCOMPLIE !" if r.get("complete", false) else "LA MARCHE S'ACHÈVE", 30, UiCommun.C_OR if r.get("complete", false) else C_SANG))
	g.add_child(UiCommun.label("Score : %d" % int(r.get("score", 0)), 40, UiCommun.C_TEXTE))
	g.add_child(UiCommun.label("Sceaux de Marche gagnés : %d" % int(r.get("sceaux", 0)), 20, C_SANG.lightened(0.3)))
	if r.has("rang"):
		g.add_child(UiCommun.label("Rang du jour : %d / %d" % [int(r["rang"]), int(r.get("total", 0))], 20, UiCommun.C_OR))
	elif not p.get("classee", false):
		g.add_child(UiCommun.label("Marche non classée (hors ligne).", 15, UiCommun.C_DOUX))
	g.add_child(UiCommun.label("Région atteinte : %d / %d   ·   Combats %d · Élites %d · Boss %d · Pactes %d" % [int(p["region"]) + 1, Marche.REGIONS,
		int(p["combats"]), int(p["elites"]), int(p["boss"]), int(p["pactes"])], 15, UiCommun.C_DOUX))
	g.add_child(UiCommun.label("Record personnel : %d" % Marche.record(), 15, UiCommun.C_DOUX))
	g.add_child(HSeparator.new())
	g.add_child(UiCommun.label("ÉQUIPE FINALE", 16, UiCommun.C_OR))
	for m in p["equipe"]:
		g.add_child(_ligne_membre(m))
	if not p["benedictions"].is_empty():
		g.add_child(UiCommun.label("BÉNÉDICTIONS", 16, UiCommun.C_OR))
		var flux := HFlowContainer.new()
		flux.add_theme_constant_override("h_separation", 6)
		flux.add_theme_constant_override("v_separation", 6)
		g.add_child(flux)
		for id in p["benedictions"]:
			var b: Dictionary = Marche.BENEDICTIONS[id]
			flux.add_child(_pastille(b["nom"], Color("#" + Marche.COULEURS_RARETE[b["rarete"]]), b["desc"]))
	if Sauvegarde.admin("marche_illimitee"):
		_bouton_choix(g, "Rejouer (Admin : Marche illimitée)", func():
			Marche._donnees()["partie"] = {}
			Sauvegarde.sauvegarder()
			get_tree().reload_current_scene())
	var d := _panneau()
	_envelopper(d).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(_envelopper(d))
	d.name = "Classement"
	_remplir_classement(d, 0)


func _envoyer_score() -> void:
	var p := Marche.partie()
	var r: Dictionary = p["resultat"]
	var detail := {"region": int(p["region"]) + 1, "complete": r.get("complete", false),
		"benedictions": p["benedictions"].size(), "pactes": int(p["pactes"]),
		"equipe": p["equipe"].map(func(m): return m["id"])}
	var rep: Dictionary = await EnLigne.appeler("marche_terminer", {"p_score": int(r["score"]), "p_detail": detail})
	if rep.ok and rep.data is Dictionary and (rep.data.get("ok", false) or rep.data.get("erreur", "") == "deja_envoye"):
		r["envoye"] = true
		if rep.data.get("ok", false):
			r["rang"] = int(rep.data["rang"])
			r["total"] = int(rep.data["total"])
		Sauvegarde.sauvegarder()
		if is_inside_tree():
			_rafraichir()


func _afficher_classement(decalage: int) -> void:
	for e in _calque.get_children():
		e.queue_free()
	var vb := _fenetre("CLASSEMENT " + ("DU JOUR" if decalage == 0 else "D'HIER"), UiCommun.C_OR, 900)
	var zone := VBoxContainer.new()
	zone.add_theme_constant_override("separation", 6)
	vb.add_child(zone)
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 10)
	vb.add_child(h)
	_bouton_choix(h, "Aujourd'hui" if decalage == 1 else "Hier", func(): _afficher_classement(1 - decalage))
	_bouton_choix(h, "Fermer", func(): _rafraichir())
	_remplir_classement(zone, decalage)


func _remplir_classement(zone: VBoxContainer, decalage: int) -> void:
	zone.add_child(UiCommun.label("CLASSEMENT " + ("DU JOUR" if decalage == 0 else "D'HIER"), 18, UiCommun.C_OR))
	if not EnLigne.est_connecte():
		zone.add_child(UiCommun.label("Connecte-toi (Paramètres → Gérer le compte) pour voir le classement.", 15, UiCommun.C_DOUX))
		return
	var attente := UiCommun.label("Chargement…", 15, UiCommun.C_DOUX)
	zone.add_child(attente)
	var r: Dictionary = await EnLigne.appeler("marche_classement", {"p_limite": 50, "p_decalage": decalage})
	if not is_instance_valid(zone):
		return
	attente.queue_free()
	if not r.ok or not r.data is Dictionary:
		zone.add_child(UiCommun.label("Classement indisponible : %s" % str(r.get("erreur", "?")), 14, C_SANG))
		return
	var d: Dictionary = r.data
	if d.get("moi") is Dictionary:
		zone.add_child(UiCommun.label("Ton rang : %d / %d   (score %d)" % [int(d["moi"]["rang"]), int(d["total"]), int(d["moi"]["score"])], 16, C_OK))
	if d["liste"].is_empty():
		zone.add_child(UiCommun.label("Personne n'a encore terminé cette marche.", 15, UiCommun.C_DOUX))
	for e in d["liste"]:
		var ligne := HBoxContainer.new()
		ligne.add_theme_constant_override("separation", 10)
		var rang := UiCommun.label("%d." % int(e["rang"]), 18, UiCommun.C_OR if int(e["rang"]) <= 3 else UiCommun.C_TEXTE)
		rang.custom_minimum_size = Vector2(46, 0)
		ligne.add_child(rang)
		ligne.add_child(UiCommun.avatar(str(e.get("heros_vitrine", "")), str(e["pseudo"]), 34))
		var n := UiCommun.label("%s  (Nv %d)" % [e["pseudo"], int(e.get("niveau", 1))], 16,
			C_OK if str(e["id"]) == EnLigne.id_joueur() else UiCommun.C_TEXTE)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ligne.add_child(n)
		var det: Dictionary = e.get("detail", {}) if e.get("detail") is Dictionary else {}
		ligne.add_child(UiCommun.label("Région %d%s" % [int(det.get("region", 1)), " ✔" if det.get("complete", false) else ""], 13, UiCommun.C_DOUX))
		ligne.add_child(UiCommun.label(str(int(e["score"])), 18, UiCommun.C_OR))
		zone.add_child(ligne)


func _confirmer_abandon() -> void:
	var d := ConfirmationDialog.new()
	d.title = "Abandonner la marche"
	d.dialog_text = "Abandonner la Marche du jour ?\nTon score actuel sera gardé, mais tu ne pourras pas recommencer avant demain."
	d.ok_button_text = "Abandonner"
	d.cancel_button_text = "Continuer la marche"
	d.confirmed.connect(func():
		d.queue_free()
		Marche.abandonner()
		get_tree().reload_current_scene())
	d.canceled.connect(d.queue_free)
	add_child(d)
	d.popup_centered(Vector2i(480, 0))


func _message(titre: String, texte: String) -> void:
	var d := AcceptDialog.new()
	d.title = titre
	d.dialog_text = texte
	d.confirmed.connect(d.queue_free)
	d.canceled.connect(d.queue_free)
	add_child(d)
	d.popup_centered(Vector2i(480, 0))


func _retour() -> void:
	UiCommun.aller(get_tree(), scene_retour if scene_retour != "" else EcranExpedition.SCENE)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if _calque.get_child_count() > 0 and Marche.partie().get("attente", {}).is_empty():
			_rafraichir()
			return
		_retour()


# =====================================================================
# La carte de la région (lignes dessinées + cases cliquables)
# =====================================================================

class CarteMarche extends Control:
	var ecran: EcranMarche
	var _pos := {}          # "ligne-case" -> position (centre)

	func _init() -> void:
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		size_flags_vertical = Control.SIZE_EXPAND_FILL
		resized.connect(_construire)

	func _position(ligne: int, x: float) -> Vector2:
		var h := size.y - 90.0
		return Vector2(60.0 + x * (size.x - 120.0), size.y - 50.0 - h * ligne / (Marche.LIGNES - 1))

	func _construire() -> void:
		for e in get_children():
			e.queue_free()
		_pos.clear()
		var p := Marche.partie()
		if p.is_empty():
			return
		var region := int(p["region"])
		var c := Marche.carte(region)
		var atteignables := Marche.cases_atteignables()
		var faites := {}
		for ch in p["chemin"]:
			if int(ch[0]) == region:
				faites["%d-%d" % [int(ch[1]), int(ch[2])]] = true
		for k in c.size():
			for i in c[k].size():
				var n: Dictionary = c[k][i]
				var centre := _position(k, n["x"])
				_pos["%d-%d" % [k, i]] = centre
				var t: String = n["type"]
				var boss := t == "boss"
				var taille := 96.0 if boss else 58.0
				var b := Button.new()
				b.focus_mode = Control.FOCUS_NONE
				b.text = Marche.TYPES[t]["icone"]
				b.tooltip_text = Marche.TYPES[t]["nom"]
				b.add_theme_font_size_override("font_size", 40 if boss else 26)
				b.size = Vector2(taille, taille)
				b.position = centre - b.size / 2.0
				var col: Color = EcranMarche.COULEURS_CASE[t]
				var cle := "%d-%d" % [k, i]
				var ici: bool = k == int(p["ligne"]) and i == int(p["case"])
				var ouverte: bool = (k == int(p["ligne"]) + 1) and i in atteignables
				var st := StyleBoxFlat.new()
				st.set_corner_radius_all(int(taille / 2))
				st.bg_color = col.darkened(0.55) if (ouverte or ici) else Color(0.08, 0.05, 0.06, 0.95)
				st.border_color = Color.WHITE if ici else (col if ouverte else (col.darkened(0.3) if faites.has(cle) else col.darkened(0.65)))
				st.set_border_width_all(4 if (ici or ouverte) else 2)
				if ouverte:
					st.shadow_color = Color(col, 0.6)
					st.shadow_size = 12
				var sh := st.duplicate() as StyleBoxFlat
				sh.bg_color = col.darkened(0.3)
				b.add_theme_stylebox_override("normal", st)
				b.add_theme_stylebox_override("hover", sh if ouverte else st)
				b.add_theme_stylebox_override("pressed", sh if ouverte else st)
				b.add_theme_stylebox_override("disabled", st)
				b.add_theme_color_override("font_color", col.lightened(0.3) if (ouverte or ici or faites.has(cle)) else col.darkened(0.4))
				b.add_theme_color_override("font_disabled_color", col.lightened(0.2) if (ici or faites.has(cle)) else col.darkened(0.4))
				b.disabled = not ouverte
				if ouverte:
					b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
					b.pressed.connect(ecran.aller_sur.bind(i))
					# petite pulsation
					var tw := b.create_tween().set_loops()
					tw.tween_property(b, "modulate", Color(1.25, 1.25, 1.25), 0.6)
					tw.tween_property(b, "modulate", Color.WHITE, 0.6)
				add_child(b)
		var titre := UiCommun.label("Région %d — %s" % [region + 1, Marche.nom_region(region)], 20, UiCommun.C_OR)
		titre.position = Vector2(16, 8)
		add_child(titre)
		queue_redraw()

	func _draw() -> void:
		var p := Marche.partie()
		if p.is_empty():
			return
		var region := int(p["region"])
		var c := Marche.carte(region)
		var faits := {}
		var chemin: Array = p["chemin"].filter(func(x): return int(x[0]) == region)
		for idx in range(1, chemin.size()):
			faits["%d-%d>%d" % [int(chemin[idx - 1][1]), int(chemin[idx - 1][2]), int(chemin[idx][2])]] = true
		for k in c.size() - 1:
			for i in c[k].size():
				for j in c[k][i]["liens"]:
					var a: Vector2 = _pos.get("%d-%d" % [k, i], Vector2.ZERO)
					var b: Vector2 = _pos.get("%d-%d" % [k + 1, int(j)], Vector2.ZERO)
					var fait := faits.has("%d-%d>%d" % [k, i, int(j)])
					draw_line(a, b, Color(1, 0.85, 0.6, 0.85) if fait else Color(0.7, 0.55, 0.5, 0.28), 5.0 if fait else 2.5, true)
