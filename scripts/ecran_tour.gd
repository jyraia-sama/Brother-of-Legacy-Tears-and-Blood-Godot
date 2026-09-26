class_name EcranTour
extends Control
## UNE TOUR (Enfer ou Paradis) : les 100 étages, l'étage choisi et le bouton Combattre.
##  - Enfer : on DESCEND (étage 1 en haut, étage 100 tout en bas, dans les profondeurs).
##  - Paradis : on MONTE (étage 1 en bas, étage 100 tout en haut, dans la lumière).

const SCENE := "res://scenes/tour.tscn"

static var tour_courante := "enfer"
static var scene_retour := ""

var _tour := "enfer"
var _enfer := true
var _selection := 1
var _accent: Color
var _c_texte: Color

var _lbl_decompte: Label
var _lbl_stamina: Label
var _lbl_monnaie: Label
var _liste: VBoxContainer
var _defil: ScrollContainer
var _fiche: VBoxContainer
var _boutons := {}          # étage -> Button


func _ready() -> void:
	Sauvegarde.charger()
	_tour = tour_courante
	_enfer = _tour == "enfer"
	_accent = Color("ff5a3a") if _enfer else Color("c89a20")
	_c_texte = Color("f0e0d8") if _enfer else Color("2a2440")
	_selection = Tours.prochain_etage(_tour)
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

	var tete := PanelContainer.new()
	tete.add_theme_stylebox_override("panel", _style_panneau())
	col.add_child(tete)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	tete.add_child(h)
	var retour := UiCommun.bouton("← Tours")
	_styler(retour, false)
	retour.pressed.connect(_retour)
	h.add_child(retour)
	var titre := UiCommun.label(str(Tours.TOURS[_tour]["nom"]).to_upper(), 30, _accent)
	h.add_child(titre)
	_lbl_decompte = UiCommun.label("", 17, Color("ffb070") if _enfer else Color("7a5a10"))
	_lbl_decompte.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl_decompte.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_child(_lbl_decompte)
	_lbl_monnaie = UiCommun.label("", 18, _accent)
	h.add_child(_lbl_monnaie)
	_lbl_stamina = UiCommun.label("", 18, Color("7ad0ff") if _enfer else Color("2a6ab0"))
	h.add_child(_lbl_stamina)

	var corps := HBoxContainer.new()
	corps.size_flags_vertical = Control.SIZE_EXPAND_FILL
	corps.add_theme_constant_override("separation", 16)
	col.add_child(corps)

	_defil = ScrollContainer.new()
	_defil.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_defil.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	corps.add_child(_defil)
	_liste = VBoxContainer.new()
	_liste.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_liste.add_theme_constant_override("separation", 6)
	_defil.add_child(_liste)

	var droite := PanelContainer.new()
	droite.custom_minimum_size = Vector2(560, 0)
	droite.add_theme_stylebox_override("panel", _style_panneau())
	corps.add_child(droite)
	var d2 := ScrollContainer.new()
	d2.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	droite.add_child(d2)
	_fiche = VBoxContainer.new()
	_fiche.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fiche.add_theme_constant_override("separation", 8)
	d2.add_child(_fiche)

	_construire_etages()
	_maj_fiche()
	var t := Timer.new()
	t.wait_time = 1.0
	t.autostart = true
	t.timeout.connect(_maj_haut)
	add_child(t)
	_maj_haut()
	await get_tree().process_frame
	await get_tree().process_frame
	_centrer_sur(_selection)


func _creer_fond() -> void:
	var noir := ColorRect.new()
	noir.color = Color("080203") if _enfer else Color("dfe6f5")
	noir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(noir)
	if not UiCommun.fond_image(self, "res://assets/tours/%s_bg.png" % _tour, Color(0.6, 0.6, 0.6) if _enfer else Color(0.95, 0.95, 0.95)):
		if _enfer:
			UiCommun.fond_degrade(self, Color("4a0a04"), Color("050001"))
		else:
			UiCommun.fond_degrade(self, Color("fff6d8"), Color("7a8ac0"))
	UiCommun.particules(self, Color("ff7a2a") if _enfer else Color("fffae0"), _enfer, 50)


func _style_panneau() -> StyleBoxFlat:
	return UiCommun.style_panneau(_accent.darkened(0.2), Color(0.06, 0.01, 0.01, 0.9) if _enfer else Color(1, 1, 1, 0.82))


# =====================================================================
# Les 100 étages
# =====================================================================

func _construire_etages() -> void:
	for e in _liste.get_children():
		e.queue_free()
	_boutons.clear()
	var ordre: Array = range(1, Tours.ETAGES + 1)
	if not _enfer:
		ordre.reverse()        # Paradis : on monte, l'étage 1 est en bas
	var atteint := Tours.etage_atteint(_tour)
	var palier_prec := ""
	for n: int in ordre:
		var p: Dictionary = Tours.palier(_tour, n)
		if p["nom"] != palier_prec and _enfer:
			_liste.add_child(_titre_palier(p))
		palier_prec = p["nom"]
		_liste.add_child(_ligne_etage(n, atteint))
		# Paradis : le titre du palier se place au-dessus de son premier étage (vu du bas)
		if not _enfer:
			var suivant := n - 1
			if suivant < 1 or Tours.palier(_tour, suivant)["nom"] != p["nom"]:
				_liste.add_child(_titre_palier(p))


func _titre_palier(p: Dictionary) -> Label:
	var l := UiCommun.label("—  %s  —" % str(p["nom"]).to_upper(), 20, _accent)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_outline_color", Color.BLACK if _enfer else Color.WHITE)
	l.add_theme_constant_override("outline_size", 6)
	return l


func _ligne_etage(n: int, atteint: int) -> Control:
	var type := Tours.type_etage(n)
	var ligne := HBoxContainer.new()
	# Chemin sinueux : décalage horizontal qui ondule
	var esp := Control.new()
	esp.custom_minimum_size = Vector2(40 + 120 * (1.0 + sin(n * 0.55)), 0)
	ligne.add_child(esp)
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var grand := type in ["boss", "super"]
	b.custom_minimum_size = Vector2(480 if grand else 360, 64 if grand else 44)
	var fait := n <= atteint
	var prochain := n == atteint + 1
	var nom_type: String = {"combat": "", "elite": "  ·  Élite", "boss": "  ·  BOSS", "super": "  ·  SUPER BOSS"}[type]
	var txt := "Étage %d%s" % [n, nom_type]
	if grand:
		txt += "\n" + UnitesData.get_unite(Tours.TOURS[_tour]["boss"][n])["nom"]
	if fait:
		txt = "✔  " + txt
	b.text = txt
	b.add_theme_font_size_override("font_size", 19 if grand else 16)
	var bord := _accent
	if type == "elite":
		bord = Color("ffd060")
	elif grand:
		bord = Color("ff2a2a") if _enfer else Color("ffffff")
	var fond := Color(0.12, 0.02, 0.02, 0.92) if _enfer else Color(1, 1, 1, 0.85)
	if fait:
		fond = fond.darkened(0.35) if _enfer else Color(0.85, 0.87, 0.9, 0.75)
	var st := StyleBoxFlat.new()
	st.bg_color = fond
	st.border_color = bord if (prochain or grand or type == "elite") else bord.darkened(0.5)
	st.set_border_width_all(4 if prochain else 2)
	st.set_corner_radius_all(22 if grand else 10)
	if prochain:
		st.shadow_color = Color(bord, 0.7)
		st.shadow_size = 12
	var st_h := st.duplicate() as StyleBoxFlat
	st_h.bg_color = fond.lightened(0.12)
	st_h.border_color = bord
	b.add_theme_stylebox_override("normal", st)
	b.add_theme_stylebox_override("hover", st_h)
	b.add_theme_stylebox_override("pressed", st_h)
	var c := _c_texte
	if n > atteint + 1:
		c = Color(c, 0.45)
	if grand and _enfer:
		c = Color("ff9a8a") if n > atteint + 1 else Color("ffd0c0")
	b.add_theme_color_override("font_color", c)
	b.add_theme_color_override("font_hover_color", c)
	b.pressed.connect(_choisir.bind(n))
	ligne.add_child(b)
	_boutons[n] = b
	return ligne


func _choisir(n: int) -> void:
	_selection = n
	_maj_fiche()


func _centrer_sur(n: int) -> void:
	if not _boutons.has(n):
		return
	var b: Button = _boutons[n]
	var y: float = b.get_parent().position.y
	_defil.scroll_vertical = int(maxf(0.0, y - _defil.size.y / 2.0))


# =====================================================================
# Fiche de l'étage choisi
# =====================================================================

func _maj_fiche() -> void:
	for e in _fiche.get_children():
		e.queue_free()
	var n := _selection
	var type := Tours.type_etage(n)
	var atteint := Tours.etage_atteint(_tour)
	var p: Dictionary = Tours.palier(_tour, n)
	_fiche.add_child(UiCommun.label("ÉTAGE %d" % n, 30, _accent))
	_fiche.add_child(UiCommun.label("%s  ·  %s" % [p["nom"], {"combat": "Combat", "elite": "Combat d'Élite",
		"boss": "BOSS", "super": "SUPER BOSS"}[type]], 17, _c_texte))

	if type in ["boss", "super"]:
		var id_boss: String = Tours.TOURS[_tour]["boss"][n]
		var ub := UnitesData.get_unite(id_boss)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 12)
		hb.add_child(UiCommun.portrait(id_boss, 84))
		var vb := VBoxContainer.new()
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var nb := UiCommun.label(ub["nom"], 22, Color("ff6a4a") if _enfer else Color("a07a00"))
		nb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vb.add_child(nb)
		if not ub["phase2"].is_empty():
			var ph := UiCommun.label("Phase 2 : " + str(ub["phase2"]["nom"]), 14, _c_texte)
			vb.add_child(ph)
		hb.add_child(vb)
		_fiche.add_child(hb)

	_fiche.add_child(HSeparator.new())
	var ennemis := Tours.generer(_tour, n)
	_fiche.add_child(UiCommun.label("ENNEMIS  (niveau %d)" % int(ennemis[0]["niveau"]), 16, _accent))
	var puissance_ennemis := 0.0
	for e in ennemis:
		var u := UnitesData.get_unite(e["id"])
		var connu := Sauvegarde.est_decouvert(e["id"])
		var nom: String = e.get("nom", u["nom"]) if (connu or n <= atteint + 1) else "???"
		var l := UiCommun.label("•  %s  —  %s, %s" % [nom, UnitesData.ROLES[u["role"]], UnitesData.ELEMENTS[u["element"]]], 15,
			Color("ffb0a0") if e.get("boss", false) else _c_texte)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_fiche.add_child(l)
		puissance_ennemis += UnitesData.puissance(e["id"], int(e["niveau"])) * float(e["mult"])
	var puissance_equipe := _puissance_equipe()
	var rapport := puissance_equipe / maxf(1.0, puissance_ennemis)
	var diff := "Très difficile" if rapport < 0.85 else ("Difficile" if rapport < 1.05 else ("Équilibré" if rapport < 1.3 else "Facile"))
	var couleur_diff := Color("ff5a4a") if rapport < 0.85 else (Color("ffa040") if rapport < 1.05 else (Color("e0d060") if rapport < 1.3 else Color("6ad06a")))
	_fiche.add_child(UiCommun.label("Puissance ennemie : %d   ·   Ton équipe : %d" % [int(puissance_ennemis), int(puissance_equipe)], 15, _c_texte))
	_fiche.add_child(UiCommun.label("Estimation : " + diff, 17, couleur_diff))

	_fiche.add_child(HSeparator.new())
	var deja := n <= atteint
	_fiche.add_child(UiCommun.label("BUTIN" + ("  (déjà obtenu cette semaine)" if deja else "  (1re victoire de la semaine)"), 16, _accent))
	var butin := Tours.butin(_tour, n)
	var grille := GridContainer.new()
	grille.columns = 2
	grille.add_theme_constant_override("h_separation", 18)
	for o in butin:
		var ligne := HBoxContainer.new()
		ligne.add_theme_constant_override("separation", 6)
		if o != "or":
			ligne.add_child(UiCommun.icone_objet(o, 26))
		ligne.add_child(UiCommun.label(("%d or" % int(butin[o])) if o == "or" else "%s x%d" % [Reliquaire.nom(o), int(butin[o])], 15,
			Color(_c_texte, 0.45) if deja else _c_texte))
		grille.add_child(ligne)
	_fiche.add_child(grille)

	_fiche.add_child(HSeparator.new())
	var equipe_txt: Array = []
	for uid in Sauvegarde.get_equipe():
		var h := Sauvegarde.get_heros(uid)
		equipe_txt.append("%s Nv %d" % [UnitesData.get_unite(h["id"])["nom"], int(h["niveau"])])
	var eq := UiCommun.label("Équipe : " + ", ".join(equipe_txt), 14, _c_texte)
	eq.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fiche.add_child(eq)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	_fiche.add_child(actions)
	var deck := UiCommun.bouton("Modifier l'équipe", 15)
	_styler(deck, false)
	deck.pressed.connect(func():
		EcranDeck.scene_retour = SCENE
		get_tree().change_scene_to_file(EcranDeck.SCENE))
	actions.add_child(deck)
	var cout: int = Tours.COUT_STAMINA[type]
	var go := UiCommun.bouton("COMBATTRE  (%d stamina)" % cout, 20)
	go.custom_minimum_size = Vector2(0, 54)
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if deja:
		go.disabled = true
		go.text = "Étage déjà vaincu cette semaine"
	elif n > atteint + 1:
		go.disabled = true
		go.text = "Termine d'abord l'étage %d" % (atteint + 1)
	_styler(go, true)
	go.pressed.connect(_combattre.bind(n))
	actions.add_child(go)


## Boutons aux couleurs de la tour (sombres en Enfer, clairs au Paradis).
func _styler(b: Button, principal: bool) -> void:
	var fond := Color(0.25, 0.04, 0.02, 0.95) if _enfer else Color(1.0, 0.97, 0.88, 0.95)
	if principal:
		fond = Color("6a1004") if _enfer else Color("fff0b8")
	for etat in ["normal", "hover", "pressed", "disabled"]:
		var st := StyleBoxFlat.new()
		st.bg_color = fond.lightened(0.1) if etat == "hover" else (Color(fond, 0.4) if etat == "disabled" else fond)
		st.border_color = _accent if etat != "disabled" else Color(_accent, 0.3)
		st.set_border_width_all(2)
		st.set_corner_radius_all(8)
		st.set_content_margin_all(8)
		b.add_theme_stylebox_override(etat, st)
	var c := Color("ffd8c8") if _enfer else Color("5a4000")
	b.add_theme_color_override("font_color", c)
	b.add_theme_color_override("font_hover_color", c)
	b.add_theme_color_override("font_disabled_color", Color(c, 0.4))


func _puissance_equipe() -> float:
	var t := 0.0
	for uid in Sauvegarde.get_equipe():
		var st := Sauvegarde.stats_heros(uid)
		t += st["pv"] * 0.25 + st["atk"] + st["def"] * 0.8 + st["agi"] * 0.5 + st["mag"] * 0.7
	return t


func _combattre(n: int) -> void:
	var equipe: Array = []
	for uid in Sauvegarde.get_equipe():
		var h := Sauvegarde.get_heros(uid)
		equipe.append({"id": h["id"], "niveau": int(h["niveau"]), "uid": uid, "place": Sauvegarde.place_de(uid),
			"etoiles": Fusion.etoiles(h), "echos": Sauvegarde.bonus_echos(uid)})
	if equipe.is_empty():
		_message("Ton équipe est vide : ajoute des héros dans le Deck.")
		return
	var cout: int = Tours.COUT_STAMINA[Tours.type_etage(n)]
	if not Sauvegarde.depenser_stamina(cout):
		var attente := Sauvegarde.secondes_avant_stamina()
		_message("Pas assez de stamina (%d requis, tu en as %d).\nProchain point dans %s.\nTu peux utiliser un Élixir au Reliquaire." % [
			cout, Sauvegarde.get_stamina(), Calendrier.texte_duree(attente)])
		return
	EcranCombat.demande = {"mode": "tour", "tour": _tour, "etage": n, "type": Tours.type_etage(n),
		"equipe": equipe, "ennemis": Tours.generer(_tour, n), "retour": SCENE}
	get_tree().change_scene_to_file(EcranCombat.SCENE)


func _maj_haut() -> void:
	_lbl_decompte.text = "Réinitialisation dans %s" % Calendrier.texte_duree(Calendrier.secondes_avant_semaine())
	_lbl_stamina.text = "Stamina %d/%d" % [Sauvegarde.get_stamina(), Sauvegarde.get_stamina_max()]
	var m: String = Tours.TOURS[_tour]["monnaie"]
	_lbl_monnaie.text = "%s : %d" % [Reliquaire.nom(m), Sauvegarde.get_objet(m)]


func _message(texte: String) -> void:
	var d := AcceptDialog.new()
	d.title = Tours.TOURS[_tour]["nom"]
	d.dialog_text = texte
	d.confirmed.connect(d.queue_free)
	d.canceled.connect(d.queue_free)
	add_child(d)
	d.popup_centered(Vector2i(460, 0))


func _retour() -> void:
	UiCommun.aller(get_tree(), scene_retour if scene_retour != "" else EcranTours.SCENE)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_retour()
