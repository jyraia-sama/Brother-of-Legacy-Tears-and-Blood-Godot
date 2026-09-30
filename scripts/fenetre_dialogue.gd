class_name FenetreDialogue
extends CanvasLayer
## Scène de dialogue de l'histoire : un bandeau en bas de l'écran avec le portrait,
## le nom et le texte (qui s'écrit lettre par lettre). Clic / Espace / Entrée = suite,
## « Passer » = fin de la scène.
##
##   await FenetreDialogue.jouer(self, acte, chapitre, "debut")
## Ne fait rien si la scène n'existe pas ou a déjà été vue (sauf revoir = true).

signal termine

const VITESSE_TEXTE := 55.0          # lettres par seconde
const DOSSIER_PORTRAITS := "res://assets/personnages/"

var repliques: Array = []
var _i := -1
var _texte: RichTextLabel
var _nom: Label
var _cadre_portrait: Control
var _ecrit := 0.0
var _fini := false


static func jouer(parent: Node, acte: int, chapitre: int, moment: String, revoir := false) -> void:
	if not DialoguesData.a_dialogue(acte, chapitre, moment):
		return
	if not revoir and DialoguesData.vu(acte, chapitre, moment):
		return
	var f := FenetreDialogue.new()
	f.repliques = DialoguesData.lignes(acte, chapitre, moment)
	parent.add_child(f)
	await f.termine
	DialoguesData.marquer_vu(acte, chapitre, moment)


func _ready() -> void:
	layer = 54
	var voile := ColorRect.new()
	voile.color = Color(0, 0, 0, 0.45)
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	voile.mouse_filter = Control.MOUSE_FILTER_STOP
	voile.gui_input.connect(_clic)
	add_child(voile)
	var p := PanelContainer.new()
	var st := UiCommun.style_panneau(UiCommun.C_OR, Color(0.05, 0.02, 0.03, 0.96))
	st.set_content_margin_all(18)
	p.add_theme_stylebox_override("panel", st)
	p.anchor_left = 0.06
	p.anchor_right = 0.94
	p.anchor_top = 1.0
	p.anchor_bottom = 1.0
	p.offset_top = -250
	p.offset_bottom = -20
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	p.gui_input.connect(_clic)
	add_child(p)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 20)
	p.add_child(h)
	_cadre_portrait = CenterContainer.new()
	_cadre_portrait.custom_minimum_size = Vector2(170, 170)
	h.add_child(_cadre_portrait)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 8)
	h.add_child(vb)
	var tete := HBoxContainer.new()
	vb.add_child(tete)
	_nom = UiCommun.label("", 24, UiCommun.C_OR)
	_nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tete.add_child(_nom)
	var passer := UiCommun.bouton("Passer ▶▶", 15)
	passer.pressed.connect(_terminer)
	tete.add_child(passer)
	_texte = RichTextLabel.new()
	_texte.bbcode_enabled = true
	_texte.fit_content = true
	_texte.scroll_active = false
	_texte.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_texte.add_theme_font_size_override("normal_font_size", 21)
	_texte.add_theme_font_size_override("italics_font_size", 21)
	_texte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(_texte)
	var suite := UiCommun.label("Clique pour continuer", 13, UiCommun.C_DOUX)
	suite.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vb.add_child(suite)
	_suivante()


func _process(delta: float) -> void:
	if _texte == null or _texte.visible_characters < 0:
		return
	_ecrit += delta * VITESSE_TEXTE
	_texte.visible_characters = int(_ecrit)
	if _texte.visible_characters >= _texte.get_total_character_count():
		_texte.visible_characters = -1


func _clic(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		_avancer()
	elif e is InputEventScreenTouch and e.pressed:
		_avancer()


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		if e.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			_avancer()
			get_viewport().set_input_as_handled()
		elif e.keycode == KEY_ESCAPE:
			_terminer()
			get_viewport().set_input_as_handled()


func _avancer() -> void:
	# Texte encore en cours d'écriture : on l'affiche en entier
	if _texte.visible_characters >= 0:
		_texte.visible_characters = -1
		return
	_suivante()


func _suivante() -> void:
	_i += 1
	if _i >= repliques.size():
		_terminer()
		return
	var r: Array = repliques[_i]
	var perso: String = r[0]
	var infos: Dictionary = DialoguesData.PERSONNAGES.get(perso, {})
	var couleur := Color("#" + str(infos.get("couleur", "e0d0c0")))
	_nom.text = DialoguesData.nom(perso)
	_nom.add_theme_color_override("font_color", couleur)
	_texte.text = ("[i]%s[/i]" % r[1]) if perso == "narr" else str(r[1])
	_texte.add_theme_color_override("default_color", Color(0.85, 0.8, 0.75) if perso == "narr" else UiCommun.C_TEXTE)
	_ecrit = 0.0
	_texte.visible_characters = 0
	for c in _cadre_portrait.get_children():
		c.queue_free()
	_cadre_portrait.visible = perso != "narr"
	if perso != "narr":
		_cadre_portrait.add_child(_portrait(perso, couleur))


## Image du personnage (assets/personnages/<id>.png), sinon portrait d'unité, sinon médaillon.
func _portrait(perso: String, couleur: Color) -> Control:
	var id := perso
	if perso == "toi":
		# Le joueur : l'aîné n'a pas de visage imposé -> blason de la maison
		id = "aine"
	var chemin := DOSSIER_PORTRAITS + id + ".png"
	var p := Panel.new()
	p.custom_minimum_size = Vector2(160, 160)
	var st := StyleBoxFlat.new()
	st.set_corner_radius_all(80)
	st.bg_color = couleur.darkened(0.7)
	st.border_color = couleur
	st.set_border_width_all(4)
	p.add_theme_stylebox_override("panel", st)
	if ResourceLoader.exists(chemin):
		p.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
		var img := TextureRect.new()
		img.texture = load(chemin)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		p.add_child(img)
		var anneau := Panel.new()
		var sa := st.duplicate() as StyleBoxFlat
		sa.draw_center = false
		anneau.add_theme_stylebox_override("panel", sa)
		anneau.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		p.add_child(anneau)
		return p
	if UnitesData.existe(id) and UiCommun.chemin_portrait(id) != "":
		return UiCommun.portrait(id, 160)
	var nom_court := DialoguesData.nom(perso).trim_prefix("Le ").trim_prefix("La ").trim_prefix("L'")
	var l := UiCommun.label("V" if perso == "toi" else nom_court.substr(0, 1), 70, Color.WHITE)
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 8)
	p.add_child(l)
	return p


func _terminer() -> void:
	if _fini:
		return
	_fini = true
	termine.emit()
	queue_free()
