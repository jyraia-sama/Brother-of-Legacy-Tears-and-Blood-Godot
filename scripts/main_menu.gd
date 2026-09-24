extends Control
## Menu principal - Brothers of Legacy : Tears and Blood
## Le fond est ton image ; par-dessus, on place des zones cliquables invisibles
## (elles s'illuminent au survol) et des textes (ressources, stats, titres).
## Astuce : appuie sur F1 pendant le jeu pour afficher toutes les zones et les recaler.

const BG_PATH := "res://assets/ui/menu_bg.png"

# Toutes les positions sont mesurées sur l'image en 1024x576.
# Elles sont converties en pourcentages : ça marche quelle que soit la résolution réelle.
const REF := Vector2(1024, 576)

# Les 6 grandes cartes (id, titre affiché, zone sur l'image)
const CARTES := [
	{"id": "aventure",   "titre": "AVENTURE",           "rect": Rect2(252, 124, 164, 146)},
	{"id": "deck",       "titre": "DECK",               "rect": Rect2(434, 124, 152, 146)},
	{"id": "echos",      "titre": "ÉCHOS SANGUINS",     "rect": Rect2(604, 124, 154, 146)},
	{"id": "invocation", "titre": "AUTEL D'INVOCATION", "rect": Rect2(252, 294, 164, 146)},
	{"id": "fusion",     "titre": "AUTEL DE FUSION",    "rect": Rect2(434, 294, 152, 146)},
	{"id": "reliquaire", "titre": "LE RELIQUAIRE",      "rect": Rect2(604, 294, 154, 146)},
]

# La barre du bas (5 icônes) - renomme-les comme tu veux
const BAS := [
	{"id": "quetes",    "titre": "Quêtes",      "rect": Rect2(276, 472, 72, 70)},
	{"id": "boutique",  "titre": "Boutique",    "rect": Rect2(374, 472, 72, 70)},
	{"id": "succes",    "titre": "Succès",      "rect": Rect2(474, 466, 72, 76)},
	{"id": "social",    "titre": "Social",      "rect": Rect2(574, 472, 72, 70)},
	{"id": "explorer",  "titre": "Exploration", "rect": Rect2(672, 472, 72, 70)},
]

# Boutons divers
const AUTRES := [
	{"id": "aide",       "titre": "Aide",       "rect": Rect2(10, 12, 50, 50)},
	{"id": "parametres", "titre": "Paramètres", "rect": Rect2(966, 12, 50, 50)},
	{"id": "heros",      "titre": "Mon héros",  "rect": Rect2(68, 110, 122, 120)},
]

# Données de test du joueur (plus tard : chargées depuis la sauvegarde)
var joueur := {
	"stamina": 30, "stamina_max": 30,
	"or": 1250, "gemmes": 50, "niveau": 1,
	"atk": 120, "def": 85, "pv": 950,
}

var _zones: Array[Button] = []
var _debug := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_creer_fond()

	for c in CARTES:
		_creer_zone(c.rect, c.id, c.titre)
		# Titre sur le bandeau rouge en bas de la carte
		var r: Rect2 = c.rect
		_creer_texte(c.titre, Rect2(r.position.x, r.end.y - 16, r.size.x, 14), 20)

	for c in BAS:
		_creer_zone(c.rect, c.id, c.titre)
	for c in AUTRES:
		_creer_zone(c.rect, c.id, c.titre)

	# Barre de ressources en haut
	_creer_texte("%d/%d" % [joueur.stamina, joueur.stamina_max], Rect2(276, 20, 80, 20), 22)
	_creer_texte(str(joueur["or"]), Rect2(404, 20, 68, 20), 22)
	_creer_texte("Niv. %d" % joueur.niveau, Rect2(540, 20, 110, 20), 22)
	_creer_texte(str(joueur.gemmes), Rect2(702, 20, 68, 20), 22)

	# Stats du héros (panneau de gauche)
	_creer_texte("ATK %d" % joueur.atk, Rect2(100, 256, 82, 16), 18)
	_creer_texte("DEF %d" % joueur.def, Rect2(100, 277, 82, 16), 18)
	_creer_texte("PV %d" % joueur.pv, Rect2(100, 297, 82, 16), 18)


# ---------- Construction ----------

func _creer_fond() -> void:
	var tex: Texture2D = load(BG_PATH)
	if tex == null:
		push_error("FOND : impossible de charger " + BG_PATH)
		return
	print("FOND : image chargée, taille = ", tex.get_size())
	var fond := TextureRect.new()
	fond.texture = tex
	fond.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fond.stretch_mode = TextureRect.STRETCH_SCALE
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fond)
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _placer(ctrl: Control, r: Rect2) -> void:
	# Ancre le contrôle en pourcentage de l'écran => il suit le redimensionnement
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

	var survol := StyleBoxFlat.new()
	survol.bg_color = Color(1.0, 0.85, 0.4, 0.12)
	survol.border_color = Color(1.0, 0.8, 0.3, 0.95)
	survol.set_border_width_all(3)
	survol.set_corner_radius_all(6)

	var appui := survol.duplicate() as StyleBoxFlat
	appui.bg_color = Color(1.0, 0.25, 0.15, 0.3)

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
	l.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	add_child(l)
	_placer(l, r)
	return l


# ---------- Actions ----------

func _on_bouton(id: String, titre: String) -> void:
	print("Clic : ", id)
	match id:
		"aventure":
			get_tree().change_scene_to_file("res://scenes/aventure.tscn")
		_:
			_message("« %s » : écran pas encore créé." % titre)


func _message(texte: String) -> void:
	var d := AcceptDialog.new()
	d.title = "Brothers of Legacy"
	d.dialog_text = texte
	add_child(d)
	d.confirmed.connect(d.queue_free)
	d.canceled.connect(d.queue_free)
	d.popup_centered()


# F1 : affiche / masque toutes les zones cliquables (pour les recaler)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		_debug = not _debug
		for b in _zones:
			var style: StyleBox = b.get_meta("style_survol") if _debug else StyleBoxEmpty.new()
			b.add_theme_stylebox_override("normal", style)
