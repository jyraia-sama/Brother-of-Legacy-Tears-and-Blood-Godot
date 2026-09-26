class_name EcranDeck
extends Control
## DECK : gestion de l'équipe et de la collection.
##
## - Équipe de 5 places : places 1-2 = AVANT, places 3-5 = ARRIÈRE.
##   Clique une unité (réserve ou équipe), puis une place pour l'y mettre (échange si occupée).
## - Fiche : niveau, XP, stats, skills ; Retirer de l'équipe, Vendre, Verrouiller.
## - Vente multiple : coche plusieurs unités de la réserve et vends-les d'un coup.
## Les doublons sont autorisés dans l'équipe.

const SCENE := "res://scenes/deck.tscn"
const FOND := "res://assets/ui/menu_bg.png"
const TRIS := [["rarete", "Rareté"], ["niveau", "Niveau"], ["nom", "Nom"], ["element", "Élément"]]
const ORDRE_RARETE := {"UR": 0, "SSR": 1, "SR": 2, "R": 3, "N": 4}

static var scene_retour := ""

var _selection := -1            # uid sélectionné
var _tri := "rarete"
var _vente_multiple := false
var _a_vendre := {}             # uid -> true

var _lbl_or: Label
var _lbl_puissance: Label
var _lbl_aide: Label
var _slots_box: Array = []      # 5 conteneurs de places
var _grille: GridContainer
var _lbl_collection: Label
var _barre_vente: HBoxContainer
var _lbl_vente: Label
var _btn_vente_multiple: Button
var _boutons_tri := {}
var _fiche: VBoxContainer


func _ready() -> void:
	Sauvegarde.charger()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_creer_fond()

	var marge := MarginContainer.new()
	marge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for c in ["left", "right", "top", "bottom"]:
		marge.add_theme_constant_override("margin_" + c, 18)
	add_child(marge)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	marge.add_child(col)

	# En-tête
	var tete := HBoxContainer.new()
	tete.add_theme_constant_override("separation", 16)
	col.add_child(tete)
	var retour := UiCommun.bouton("← Retour")
	retour.pressed.connect(_retour)
	tete.add_child(retour)
	var titre := UiCommun.label("DECK", 32, UiCommun.C_OR)
	tete.add_child(titre)
	_lbl_puissance = UiCommun.label("", 17, UiCommun.C_DOUX)
	_lbl_puissance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tete.add_child(_lbl_puissance)
	_lbl_or = UiCommun.label("", 20, Color("ffd060"))
	tete.add_child(_lbl_or)

	var corps := HBoxContainer.new()
	corps.size_flags_vertical = Control.SIZE_EXPAND_FILL
	corps.add_theme_constant_override("separation", 14)
	col.add_child(corps)

	var gauche := VBoxContainer.new()
	gauche.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gauche.add_theme_constant_override("separation", 10)
	corps.add_child(gauche)
	gauche.add_child(_creer_panneau_equipe())
	gauche.add_child(_creer_panneau_reserve())

	var droite := PanelContainer.new()
	droite.custom_minimum_size = Vector2(440, 0)
	droite.add_theme_stylebox_override("panel", UiCommun.style_panneau())
	corps.add_child(droite)
	var defil := ScrollContainer.new()
	defil.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	droite.add_child(defil)
	_fiche = VBoxContainer.new()
	_fiche.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fiche.add_theme_constant_override("separation", 8)
	defil.add_child(_fiche)

	resized.connect(_ajuster_colonnes)
	_tout_rafraichir()
	_ajuster_colonnes()


# =====================================================================
# Construction
# =====================================================================

func _creer_panneau_equipe() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiCommun.style_panneau())
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	p.add_child(vb)
	var h := HBoxContainer.new()
	vb.add_child(h)
	var t := UiCommun.label("ÉQUIPE", 18, UiCommun.C_OR)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	_lbl_aide = UiCommun.label("", 14, UiCommun.C_DOUX)
	h.add_child(_lbl_aide)

	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 10)
	ligne.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(ligne)
	for groupe in [["AVANT  (corps à corps)", [0, 1]], ["ARRIÈRE  (distance)", [2, 3, 4]]]:
		var g := VBoxContainer.new()
		g.add_theme_constant_override("separation", 4)
		var lg := UiCommun.label(groupe[0], 13, Color(1, 1, 1, 0.5))
		lg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		g.add_child(lg)
		var places := HBoxContainer.new()
		places.add_theme_constant_override("separation", 8)
		g.add_child(places)
		for i in groupe[1]:
			var boite := Control.new()
			boite.custom_minimum_size = Vector2(132, 168)
			places.add_child(boite)
			_slots_box.append(boite)
		ligne.add_child(g)
		if groupe[1][0] == 0:
			var sep := VSeparator.new()
			sep.custom_minimum_size = Vector2(18, 0)
			ligne.add_child(sep)
	return p


func _creer_panneau_reserve() -> PanelContainer:
	var p := PanelContainer.new()
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", UiCommun.style_panneau())
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	p.add_child(vb)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	vb.add_child(h)
	_lbl_collection = UiCommun.label("", 18, UiCommun.C_OR)
	_lbl_collection.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(_lbl_collection)
	h.add_child(UiCommun.label("Trier :", 14, UiCommun.C_DOUX))
	for t in TRIS:
		var b := UiCommun.bouton(t[1], 14)
		b.custom_minimum_size = Vector2(0, 32)
		b.toggle_mode = true
		b.pressed.connect(func():
			_tri = t[0]
			_remplir_reserve())
		h.add_child(b)
		_boutons_tri[t[0]] = b
	_btn_vente_multiple = UiCommun.bouton("Vente multiple", 14)
	_btn_vente_multiple.custom_minimum_size = Vector2(0, 32)
	_btn_vente_multiple.toggle_mode = true
	_btn_vente_multiple.pressed.connect(_basculer_vente_multiple)
	h.add_child(_btn_vente_multiple)

	var defil := ScrollContainer.new()
	defil.size_flags_vertical = Control.SIZE_EXPAND_FILL
	defil.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(defil)
	_grille = GridContainer.new()
	_grille.columns = 6
	_grille.add_theme_constant_override("h_separation", 8)
	_grille.add_theme_constant_override("v_separation", 8)
	defil.add_child(_grille)

	_barre_vente = HBoxContainer.new()
	_barre_vente.add_theme_constant_override("separation", 10)
	_barre_vente.visible = false
	vb.add_child(_barre_vente)
	_lbl_vente = UiCommun.label("", 16, Color("ffd060"))
	_lbl_vente.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_barre_vente.add_child(_lbl_vente)
	var vendre := UiCommun.bouton("Vendre la sélection")
	vendre.pressed.connect(_vendre_selection_multiple)
	_barre_vente.add_child(vendre)
	return p


func _ajuster_colonnes() -> void:
	if _grille:
		_grille.columns = maxi(2, int((size.x - 36 - 440 - 14 - 40) / 140.0))


# =====================================================================
# Rafraîchissement
# =====================================================================

func _tout_rafraichir() -> void:
	_lbl_or.text = "Or : %d" % Sauvegarde.get_or()
	var puissance := 0
	for uid in Sauvegarde.get_equipe():
		var h := Sauvegarde.get_heros(uid)
		var st := Sauvegarde.stats_heros(uid)
		puissance += int(st["pv"] * 0.25 + st["atk"] + st["def"] * 0.8 + st["agi"] * 0.5 + st["mag"] * 0.7)
	_lbl_puissance.text = "Puissance de l'équipe : %d" % puissance
	for cle in _boutons_tri:
		_boutons_tri[cle].button_pressed = (cle == _tri)
	_remplir_equipe()
	_remplir_reserve()
	_maj_fiche()
	_maj_barre_vente()


func _remplir_equipe() -> void:
	var slots := Sauvegarde.get_slots()
	for i in 5:
		var boite: Control = _slots_box[i]
		for e in boite.get_children():
			e.queue_free()
		var uid: int = slots[i]
		var carte: Button
		if uid >= 0:
			carte = UiCommun.carte_heros(Sauvegarde.get_heros(uid))
			if uid == _selection:
				carte.add_theme_stylebox_override("normal", UiCommun.style_carte(Color.WHITE, 0.08, 3))
		else:
			carte = Button.new()
			carte.custom_minimum_size = Vector2(132, 168)
			carte.focus_mode = Control.FOCUS_NONE
			carte.add_theme_stylebox_override("normal", UiCommun.style_carte(Color(1, 1, 1, 0.15)))
			carte.add_theme_stylebox_override("hover", UiCommun.style_carte(UiCommun.C_OR, 0.05))
			carte.text = "+\nPlace %d" % (i + 1)
			carte.add_theme_color_override("font_color", UiCommun.C_DOUX)
		carte.pressed.connect(_clic_place.bind(i))
		boite.add_child(carte)
	_lbl_aide.text = "Clique une unité puis une place pour l'y mettre" if _selection < 0 \
		else "Clique une place pour y mettre l'unité choisie"


func _remplir_reserve() -> void:
	for e in _grille.get_children():
		e.queue_free()
	var liste: Array = Sauvegarde.liste_heros().duplicate()
	liste.sort_custom(_comparer)
	var equipe := Sauvegarde.get_equipe()
	_lbl_collection.text = "COLLECTION  (%d unités)" % liste.size()
	for h in liste:
		var uid := int(h["uid"])
		var carte := UiCommun.carte_heros(h)
		if uid == _selection:
			carte.add_theme_stylebox_override("normal", UiCommun.style_carte(Color.WHITE, 0.08, 3))
		if _a_vendre.has(uid):
			carte.add_theme_stylebox_override("normal", UiCommun.style_carte(Color("ff6a5a"), 0.1, 3))
		if uid in equipe:
			UiCommun.badge(carte, "Équipe", UiCommun.C_OR)
		elif h.get("verrou", false) or h.get("depart", false):
			UiCommun.badge(carte, "Protégé" if h.get("depart", false) else "Verrouillé", Color("8ab0d0"))
		if _a_vendre.has(uid):
			UiCommun.badge(carte, "À vendre", Color("ff8a7a"), false)
		carte.pressed.connect(_clic_reserve.bind(uid))
		_grille.add_child(carte)


func _comparer(a: Dictionary, b: Dictionary) -> bool:
	var ua := UnitesData.get_unite(a["id"])
	var ub := UnitesData.get_unite(b["id"])
	match _tri:
		"niveau":
			if int(a["niveau"]) != int(b["niveau"]):
				return int(a["niveau"]) > int(b["niveau"])
		"nom":
			if ua["nom"] != ub["nom"]:
				return ua["nom"] < ub["nom"]
		"element":
			if ua["element"] != ub["element"]:
				return ua["element"] < ub["element"]
	var ra: int = -1 if ua.get("legende", false) else ORDRE_RARETE[ua["rarete"]]
	var rb: int = -1 if ub.get("legende", false) else ORDRE_RARETE[ub["rarete"]]
	if ra != rb:
		return ra < rb
	if int(a["niveau"]) != int(b["niveau"]):
		return int(a["niveau"]) > int(b["niveau"])
	return int(a["uid"]) < int(b["uid"])


# =====================================================================
# Actions
# =====================================================================

func _clic_reserve(uid: int) -> void:
	if _vente_multiple:
		var raison := Sauvegarde.raison_invendable(uid)
		if raison != "":
			_message("Impossible de vendre", raison)
			return
		if _a_vendre.has(uid):
			_a_vendre.erase(uid)
		else:
			_a_vendre[uid] = true
		_remplir_reserve()
		_maj_barre_vente()
		return
	_selection = -1 if _selection == uid else uid
	_remplir_equipe()
	_remplir_reserve()
	_maj_fiche()


func _clic_place(place: int) -> void:
	var slots := Sauvegarde.get_slots()
	if _selection >= 0 and slots[place] != _selection:
		Sauvegarde.placer(_selection, place)
		_selection = -1
		_tout_rafraichir()
		return
	# Pas de sélection : on sélectionne l'unité de cette place
	_selection = slots[place] if slots[place] != _selection else -1
	_remplir_equipe()
	_remplir_reserve()
	_maj_fiche()


func _retirer() -> void:
	if not Sauvegarde.retirer_de_equipe(_selection):
		_message("Impossible", "L'équipe doit garder au moins une unité.")
		return
	_tout_rafraichir()


func _vendre_une() -> void:
	var uid := _selection
	var raison := Sauvegarde.raison_invendable(uid)
	if raison != "":
		_message("Impossible de vendre", raison)
		return
	var h := Sauvegarde.get_heros(uid)
	_confirmer("Vendre %s (Nv %d) pour %d or ?" % [UnitesData.get_unite(h["id"])["nom"], int(h["niveau"]), Sauvegarde.prix_vente(uid)],
		func():
			Sauvegarde.vendre([uid])
			_selection = -1
			_tout_rafraichir())


func _basculer_verrou() -> void:
	Sauvegarde.basculer_verrou(_selection)
	_tout_rafraichir()


func _basculer_vente_multiple() -> void:
	_vente_multiple = _btn_vente_multiple.button_pressed
	_a_vendre.clear()
	_selection = -1
	_tout_rafraichir()


func _maj_barre_vente() -> void:
	_barre_vente.visible = _vente_multiple
	var total := 0
	for uid in _a_vendre:
		total += Sauvegarde.prix_vente(uid)
	_lbl_vente.text = "%d unité(s) sélectionnée(s)  ·  Total : %d or" % [_a_vendre.size(), total] if not _a_vendre.is_empty() \
		else "Clique les unités à vendre (l'équipe et les unités protégées ne peuvent pas être vendues)."


func _vendre_selection_multiple() -> void:
	if _a_vendre.is_empty():
		return
	var total := 0
	for uid in _a_vendre:
		total += Sauvegarde.prix_vente(uid)
	_confirmer("Vendre %d unités pour %d or ?" % [_a_vendre.size(), total], func():
		Sauvegarde.vendre(_a_vendre.keys())
		_a_vendre.clear()
		_tout_rafraichir())


# =====================================================================
# Fiche détaillée
# =====================================================================

func _maj_fiche() -> void:
	for e in _fiche.get_children():
		e.queue_free()
	var h := Sauvegarde.get_heros(_selection)
	if h.is_empty():
		var vide := UiCommun.label("Choisis une unité pour voir sa fiche.\n\nPlaces 1-2 : AVANT (corps à corps : Guerrier, Tank, Assassin).\nPlaces 3-5 : ARRIÈRE (Tireur, Mage, Soutien).\n\nLe corps à corps fait plus de dégâts à l'Avant, mais l'Avant reçoit aussi plus de coups.", 16, UiCommun.C_DOUX)
		vide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_fiche.add_child(vide)
		return
	var id: String = h["id"]
	var u := UnitesData.get_unite(id)
	var niv := int(h["niveau"])
	var s := Sauvegarde.stats_heros(_selection)      # niveau + étoiles + Échos Sanguins

	var tete := HBoxContainer.new()
	tete.add_theme_constant_override("separation", 12)
	tete.add_child(UiCommun.portrait(id, 72))
	var infos := VBoxContainer.new()
	infos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nom := UiCommun.label(u["nom"], 24, UiCommun.couleur_rarete(id))
	nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	infos.add_child(nom)
	var nb_et := Fusion.etoiles(h)
	infos.add_child(UiCommun.label(Fusion.texte_etoiles(nb_et) + ("  ÉVEILLÉ" if nb_et >= Fusion.ETOILES_MAX else "") \
		+ ("   (+%d %% stats)" % int(round((Fusion.multiplicateur(nb_et) - 1.0) * 100)) if nb_et > 1 else ""), 16, Color("ffd060")))
	var desc := UiCommun.label("%s · %s · %s · %s" % [UiCommun.texte_rarete(id), UnitesData.ELEMENTS[u["element"]],
		UnitesData.ROLES[u["role"]], "Avant conseillé" if u["position"] == "avant" else "Arrière conseillé"], 14, UiCommun.C_DOUX)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	infos.add_child(desc)
	tete.add_child(infos)
	_fiche.add_child(tete)

	# Niveau et XP
	var besoin := Sauvegarde.xp_heros_pour_niveau(niv)
	_fiche.add_child(UiCommun.label("Niveau %d / %d" % [niv, UnitesData.NIVEAU_MAX] + ("" if niv >= UnitesData.NIVEAU_MAX else "   ·   XP %d / %d" % [int(h["xp"]), besoin]), 17))
	var xp := UiCommun.barre(Color("7ab8ff"), 400, 8)
	xp.max_value = besoin
	xp.value = besoin if niv >= UnitesData.NIVEAU_MAX else int(h["xp"])
	_fiche.add_child(xp)

	var grille := GridContainer.new()
	grille.columns = 5
	grille.add_theme_constant_override("h_separation", 6)
	for paire in [["pv", "PV"], ["atk", "ATK"], ["def", "DEF"], ["agi", "AGI"], ["mag", "MAG"]]:
		var c := VBoxContainer.new()
		c.custom_minimum_size = Vector2(76, 0)
		var dom: bool = paire[0] in u.get("dominantes", [])
		var v := UiCommun.label(str(s[paire[0]]), 19, UiCommun.C_LEGENDE if dom else UiCommun.C_TEXTE)
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var n := UiCommun.label(paire[1], 12, UiCommun.C_DOUX)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		c.add_child(v)
		c.add_child(n)
		grille.add_child(c)
	_fiche.add_child(grille)
	_fiche.add_child(UiCommun.label("Crit %d %%  ·  Dégâts crit %d %%  ·  RES %d  ·  Précision %d %%" % [s["crit"], s["degats_crit"], s["res"], s["preci"]], 14, UiCommun.C_DOUX))
	var nb_echos := Sauvegarde.echos_de(_selection).size()
	_fiche.add_child(UiCommun.label("Échos Sanguins équipés : %d / 6 (stats incluses)" % nb_echos, 13, Color("d0453a") if nb_echos > 0 else UiCommun.C_DOUX))

	# Actions
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	_fiche.add_child(actions)
	var place := Sauvegarde.place_de(_selection)
	if place >= 0:
		var r := UiCommun.bouton("Retirer de l'équipe", 15)
		r.pressed.connect(_retirer)
		actions.add_child(r)
	var raison := Sauvegarde.raison_invendable(_selection)
	var v := UiCommun.bouton("Vendre (%d or)" % Sauvegarde.prix_vente(_selection), 15)
	v.disabled = raison != ""
	v.tooltip_text = raison
	v.pressed.connect(_vendre_une)
	actions.add_child(v)
	if not h.get("depart", false):
		var ver := UiCommun.bouton("Déverrouiller" if h.get("verrou", false) else "Verrouiller", 15)
		ver.pressed.connect(_basculer_verrou)
		actions.add_child(ver)
	if place >= 0:
		_fiche.add_child(UiCommun.label("Dans l'équipe : place %d (%s)" % [place + 1, "Avant" if place < 2 else "Arrière"], 14, UiCommun.C_OR))

	_fiche.add_child(HSeparator.new())
	_fiche.add_child(UiCommun.label("SKILLS", 16, UiCommun.C_OR))
	for sk in u["skills"]:
		var ok: bool = sk["niveau"] <= niv
		var t := UiCommun.label("Niv. %d · %s (%s)%s" % [sk["niveau"], sk["nom"], sk["type"], "" if ok else "  — verrouillé"], 16, UiCommun.C_OR if ok else UiCommun.C_DOUX)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_fiche.add_child(t)
		var d := UiCommun.label(sk["description"], 14, UiCommun.C_TEXTE if ok else UiCommun.C_DOUX)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_fiche.add_child(d)


# =====================================================================
# Outils
# =====================================================================

func _creer_fond() -> void:
	var noir := ColorRect.new()
	noir.color = UiCommun.C_FOND
	noir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(noir)
	if ResourceLoader.exists(FOND):
		var img := TextureRect.new()
		img.texture = load(FOND)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		img.modulate = Color(0.2, 0.17, 0.17)
		add_child(img)


func _message(titre: String, texte: String) -> void:
	var d := AcceptDialog.new()
	d.title = titre
	d.dialog_text = texte
	d.confirmed.connect(d.queue_free)
	d.canceled.connect(d.queue_free)
	add_child(d)
	d.popup_centered(Vector2i(420, 0))


func _confirmer(texte: String, action: Callable) -> void:
	var d := ConfirmationDialog.new()
	d.title = "Confirmation"
	d.dialog_text = texte
	d.ok_button_text = "Oui"
	d.cancel_button_text = "Annuler"
	d.confirmed.connect(func():
		d.queue_free()
		action.call())
	d.canceled.connect(d.queue_free)
	add_child(d)
	d.popup_centered(Vector2i(420, 0))


func _retour() -> void:
	var cible := scene_retour
	if cible == "":
		cible = ProjectSettings.get_setting("application/run/main_scene", "")
	if cible != "":
		get_tree().change_scene_to_file(cible)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_retour()
