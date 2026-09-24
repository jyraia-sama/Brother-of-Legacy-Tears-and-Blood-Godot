extends Control
## Écran Aventure - Brothers of Legacy : Tears and Blood
## Même principe que le menu principal : image de fond + zones cliquables.
## F1 : affiche / masque les zones cliquables.  Échap : retour au menu principal.

const BG_PATH := "res://assets/ui/aventure_bg.png"

# Positions mesurées sur l'image en 2048x1152
const REF := Vector2(2048, 1152)

# Les 6 modes, de haut-gauche à bas-droite
const MODES := [
	{"id": "histoire",   "titre": "HISTOIRE PRINCIPALE", "rect": Rect2(305, 140, 440, 415)},
	{"id": "tour",       "titre": "TOUR INFINIE",        "rect": Rect2(805, 140, 440, 415)},
	{"id": "expedition", "titre": "EXPÉDITION",          "rect": Rect2(1305, 140, 440, 415)},
	{"id": "boss_monde", "titre": "BOSS DE MONDE",       "rect": Rect2(305, 635, 440, 420)},
	{"id": "donjon",     "titre": "DONJON",              "rect": Rect2(805, 635, 440, 420)},
	{"id": "arene",      "titre": "ARÈNE",               "rect": Rect2(1305, 635, 440, 420)},
]

const RETOUR_RECT := Rect2(35, 20, 128, 130)

var _zones: Array[Button] = []
var _debug := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_creer_fond()

	for m in MODES:
		_creer_zone(m.rect, m.id, m.titre)
		# Titre juste au-dessus du bandeau, dans le bas de l'illustration
		var r: Rect2 = m.rect
		_creer_texte(m.titre, Rect2(r.position.x + 40, r.end.y - 58, r.size.x - 80, 36), 24)

	_creer_zone(RETOUR_RECT, "retour", "Retour")


# ---------- Actions ----------

func _on_bouton(id: String, titre: String) -> void:
	print("Clic : ", id)
	match id:
		"retour":
			_retour_menu()
		"histoire":
			get_tree().change_scene_to_file("res://scenes/histoire.tscn")
		_:
			_message("« %s » : mode pas encore créé." % titre)


func _retour_menu() -> void:
	# Revient à la scène principale du projet (ton menu), quel que soit son nom
	var menu: String = ProjectSettings.get_setting("application/run/main_scene")
	get_tree().change_scene_to_file(menu)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_retour_menu()
		elif event.keycode == KEY_F1:
			_debug = not _debug
			for b in _zones:
				var style: StyleBox = b.get_meta("style_survol") if _debug else StyleBoxEmpty.new()
				b.add_theme_stylebox_override("normal", style)


# ---------- Construction (identique au menu principal) ----------

func _creer_fond() -> void:
	var tex: Texture2D = load(BG_PATH)
	if tex == null:
		push_error("FOND : impossible de charger " + BG_PATH)
		return
	var fond := TextureRect.new()
	fond.texture = tex
	fond.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fond.stretch_mode = TextureRect.STRETCH_SCALE
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fond)
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _placer(ctrl: Control, r: Rect2) -> void:
	ctrl.anchor_left = r.position.x / REF.x
	ctrl.anchor_top = r.position.y / REF.y
	ctrl.anchor_right = r.end.x / REF.x
	ctrl.anchor_bottom = r.end.y / REF.y
	ctrl.offset_left = 0
	ctrl.offset_top = 0
	ctrl.offset_right = 0
	ctrl.offset_bottom = 0


func _creer_zone(r: Rect2, id: String, titre: String) -> void:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = titre
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# Survol violet pour coller à l'ambiance de cet écran
	var survol := StyleBoxFlat.new()
	survol.bg_color = Color(0.6, 0.45, 1.0, 0.12)
	survol.border_color = Color(0.75, 0.6, 1.0, 0.95)
	survol.set_border_width_all(3)
	survol.set_corner_radius_all(8)

	var appui := survol.duplicate() as StyleBoxFlat
	appui.bg_color = Color(0.5, 0.2, 1.0, 0.3)

	b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("hover", survol)
	b.add_theme_stylebox_override("pressed", appui)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.set_meta("style_survol", survol)

	add_child(b)
	_placer(b, r)
	b.pressed.connect(_on_bouton.bind(id, titre))
	_zones.append(b)


func _creer_texte(texte: String, r: Rect2, taille: int) -> Label:
	var l := Label.new()
	l.text = texte
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", taille)
	l.add_theme_color_override("font_color", Color(0.9, 0.85, 1.0))
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 8)
	add_child(l)
	_placer(l, r)
	return l


func _message(texte: String) -> void:
	var d := AcceptDialog.new()
	d.title = "Aventure"
	d.dialog_text = texte
	add_child(d)
	d.confirmed.connect(d.queue_free)
	d.canceled.connect(d.queue_free)
	d.popup_centered()
