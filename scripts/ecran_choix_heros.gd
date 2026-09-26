class_name EcranChoixHeros
extends Control
## CHOIX DU HÉROS DE DÉPART
## S'ouvre automatiquement au tout premier lancement (et après "Nouvelle partie").
## Le joueur choisit 1 des 8 Héros de Légende ; il rejoint sa collection et son équipe.

const SCENE := "res://scenes/choix_heros.tscn"
const FOND := "res://assets/ui/menu_bg.png"
const HEROS := ["brute_noire", "barbe_bleue", "lance_doree", "nymphe",
	"mage_gris", "dague_violette", "samourai_rouge", "chevalier_blanc"]

const C_OR := Color(0.85, 0.65, 0.3)
const C_TEXTE := Color(0.93, 0.88, 0.83)
const C_DOUX := Color(0.66, 0.59, 0.55)
const NOMS_STATS := {"pv": "PV", "atk": "ATK", "def": "DEF", "agi": "AGI", "mag": "MAG"}


func _ready() -> void:
	Sauvegarde.charger()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var noir := ColorRect.new()
	noir.color = Color("130d0f")
	noir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(noir)
	if ResourceLoader.exists(FOND):
		var img := TextureRect.new()
		img.texture = load(FOND)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		img.modulate = Color(0.25, 0.2, 0.2)
		add_child(img)

	var marge := MarginContainer.new()
	marge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for cote in ["left", "right", "top", "bottom"]:
		marge.add_theme_constant_override("margin_" + cote, 24)
	add_child(marge)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	marge.add_child(col)

	var titre := _label("CHOISIS TON HÉROS", 36, C_OR)
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(titre)
	var sous := _label("Huit Héros de Légende. Un seul t'accompagnera dès le début de ton voyage.", 18, C_DOUX)
	sous.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sous)

	var defil := ScrollContainer.new()
	defil.size_flags_vertical = Control.SIZE_EXPAND_FILL
	defil.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(defil)
	var grille := GridContainer.new()
	grille.columns = 4
	grille.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grille.add_theme_constant_override("h_separation", 14)
	grille.add_theme_constant_override("v_separation", 14)
	defil.add_child(grille)
	for id in HEROS:
		grille.add_child(_carte(id))


func _carte(id: String) -> Button:
	var u := UnitesData.get_unite(id)
	var s := UnitesData.stats(id, 1)
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 360)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var elem: Color = EcranBestiaire.COULEURS_ELEMENT[u["element"]]
	b.add_theme_stylebox_override("normal", _style(elem.darkened(0.3), 0.0))
	b.add_theme_stylebox_override("hover", _style(C_OR, 0.07))
	b.add_theme_stylebox_override("pressed", _style(C_OR, 0.12))
	b.pressed.connect(_confirmer.bind(id))

	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 14
	vb.offset_right = -14
	vb.offset_top = 14
	vb.offset_bottom = -12
	vb.add_theme_constant_override("separation", 6)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(vb)

	# Portrait provisoire
	var portrait := Panel.new()
	portrait.custom_minimum_size = Vector2(84, 84)
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sp := StyleBoxFlat.new()
	sp.set_corner_radius_all(42)
	sp.bg_color = Color("#" + u["couleur"]).lerp(Color.BLACK, 0.2)
	sp.border_color = elem
	sp.set_border_width_all(3)
	portrait.add_theme_stylebox_override("panel", sp)
	vb.add_child(portrait)
	var ini := _label(u["nom"].trim_prefix("La ").trim_prefix("Le ").substr(0, 1), 34, Color.WHITE)
	ini.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ini.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ini.add_theme_color_override("font_outline_color", Color.BLACK)
	ini.add_theme_constant_override("outline_size", 6)
	portrait.add_child(ini)

	vb.add_child(_centre(_label(u["nom"], 21, C_OR)))
	vb.add_child(_centre(_label("%s · %s · %s" % [u["race"], UnitesData.ELEMENTS[u["element"]], UnitesData.ROLES[u["role"]]], 14, C_DOUX)))

	# Les 2 stats dominantes en avant
	var dom := HBoxContainer.new()
	dom.alignment = BoxContainer.ALIGNMENT_CENTER
	dom.add_theme_constant_override("separation", 14)
	dom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for cle in u["dominantes"]:
		dom.add_child(_label("%s %d" % [NOMS_STATS[cle], s[cle]], 18, Color("ffd27a")))
	vb.add_child(dom)
	var autres: Array = []
	for cle in ["pv", "atk", "def", "agi", "mag"]:
		if not cle in u["dominantes"]:
			autres.append("%s %d" % [NOMS_STATS[cle], s[cle]])
	vb.add_child(_centre(_label("  ·  ".join(autres), 13, C_DOUX)))

	var sk: Dictionary = u["skills"][0]
	var t := _label(sk["nom"], 16, C_TEXTE)
	vb.add_child(t)
	var d := _label(sk["description"], 13, C_DOUX)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(d)
	return b


func _confirmer(id: String) -> void:
	var u := UnitesData.get_unite(id)
	var d := ConfirmationDialog.new()
	d.title = "Héros de départ"
	d.dialog_text = "Partir à l'aventure avec %s ?\n\nCe choix est définitif (seule une Nouvelle partie permet de rechoisir)." % u["nom"]
	d.ok_button_text = "Je le choisis"
	d.cancel_button_text = "Revenir"
	d.confirmed.connect(func():
		Sauvegarde.choisir_heros_depart(id)
		var menu: String = ProjectSettings.get_setting("application/run/main_scene", "")
		if menu != "":
			get_tree().change_scene_to_file(menu))
	d.canceled.connect(d.queue_free)
	add_child(d)
	d.popup_centered(Vector2i(460, 0))


func _style(bord: Color, eclat: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.1 + eclat, 0.06 + eclat, 0.07 + eclat, 0.95)
	s.border_color = bord
	s.set_border_width_all(2)
	s.border_width_top = 5
	s.set_corner_radius_all(10)
	return s


func _label(texte: String, taille: int, couleur: Color) -> Label:
	var l := Label.new()
	l.text = texte
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", taille)
	l.add_theme_color_override("font_color", couleur)
	return l


func _centre(l: Label) -> Label:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l
